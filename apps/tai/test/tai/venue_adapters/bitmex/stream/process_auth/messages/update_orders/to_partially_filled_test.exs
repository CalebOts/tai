defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdateOrders.ToPartiallyFilledTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Assertions.Event
  alias Tai.VenueAdapters.Bitmex.ClientId
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth
  alias Tai.Trading.OrderStore
  alias Tai.Events

  setup do
    {:ok, _} = Application.ensure_all_started(:tzdata)
    start_supervised!({Tai.Events, 1})
    start_supervised!(Tai.Trading.OrderStore)

    :ok
  end

  @venue_client_id "gtc-TCRG7aPSQsmj1Z8jXfbovg=="
  @received_at Timex.now()
  @timestamp "2019-09-07T06:00:04.808Z"
  @state struct(ProcessAuth.State, venue_id: :my_venue)

  test ".process/3 passively fills the order" do
    Events.firehose_subscribe()

    assert {:ok, order} = enqueue()

    action =
      struct(Tai.Trading.OrderStore.Actions.Open,
        client_id: order.client_id,
        cumulative_qty: Decimal.new(0),
        leaves_qty: Decimal.new(20)
      )

    assert {:ok, {old, updated}} = OrderStore.update(action)

    msg =
      struct(ProcessAuth.Messages.UpdateOrders.ToPartiallyFilled,
        cl_ord_id: order.client_id |> ClientId.to_venue(:gtc),
        timestamp: @timestamp,
        cum_qty: 15,
        leaves_qty: 5
      )

    ProcessAuth.Message.process(msg, @received_at, @state)

    assert_event(%Events.OrderUpdated{status: :partially_filled} = partially_filled_event)
    assert partially_filled_event.client_id == order.client_id
    assert partially_filled_event.venue_id == :my_venue
    assert partially_filled_event.cumulative_qty == Decimal.new(15)
    assert partially_filled_event.leaves_qty == Decimal.new(5)
    assert partially_filled_event.qty == Decimal.new(20)
    assert %DateTime{} = partially_filled_event.last_received_at
    assert %DateTime{} = partially_filled_event.last_venue_timestamp
  end

  test ".process/3 broadcasts an invalid status warning" do
    Events.firehose_subscribe()

    assert {:ok, order} = enqueue()

    action = struct(Tai.Trading.OrderStore.Actions.Skip, client_id: order.client_id)
    assert {:ok, {old, updated}} = OrderStore.update(action)

    msg =
      struct(ProcessAuth.Messages.UpdateOrders.ToPartiallyFilled,
        cl_ord_id: order.client_id |> ClientId.to_venue(:gtc),
        timestamp: @timestamp,
        cum_qty: 15,
        leaves_qty: 5
      )

    ProcessAuth.Message.process(msg, @received_at, @state)

    assert_event(%Events.OrderUpdateInvalidStatus{} = invalid_status_event)
    assert invalid_status_event.action == Tai.Trading.OrderStore.Actions.PassivePartialFill
    assert invalid_status_event.was == :skip

    assert invalid_status_event.required == [
             :open,
             :partially_filled,
             :pending_amend,
             :pending_cancel,
             :amend_error,
             :cancel_accepted,
             :cancel_error
           ]
  end

  test ".process/3 broadcasts a not found warning" do
    Events.firehose_subscribe()

    msg =
      struct(ProcessAuth.Messages.UpdateOrders.ToPartiallyFilled,
        cl_ord_id: @venue_client_id,
        timestamp: @timestamp,
        cum_qty: 15,
        leaves_qty: 5
      )

    ProcessAuth.Message.process(msg, @received_at, @state)

    assert_event(%Events.OrderUpdateNotFound{} = not_found_event)
    assert not_found_event.client_id != @venue_client_id
    assert not_found_event.action == Tai.Trading.OrderStore.Actions.PassivePartialFill
  end

  defp enqueue, do: build_submission() |> OrderStore.enqueue()

  defp build_submission do
    struct(Tai.Trading.OrderSubmissions.BuyLimitGtc,
      venue_id: :my_venue,
      account_id: :main,
      product_symbol: :btc_usd,
      price: Decimal.new("100.1"),
      qty: Decimal.new(20)
    )
  end
end
