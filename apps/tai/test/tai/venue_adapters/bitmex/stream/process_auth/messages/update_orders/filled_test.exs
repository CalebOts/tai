defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdateOrders.FilledTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Assertions.Event
  alias Tai.VenueAdapters.Bitmex.ClientId
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth
  alias Tai.Trading.OrderStore
  alias Tai.Events

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tzdata)
    end)

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
    assert {:ok, order} = enqueue()

    action =
      struct(Tai.Trading.OrderStore.Actions.Open,
        client_id: order.client_id,
        cumulative_qty: Decimal.new(0),
        leaves_qty: Decimal.new(20)
      )

    assert {:ok, {old, updated}} = OrderStore.update(action)

    msg =
      struct(ProcessAuth.Messages.UpdateOrders.Filled,
        cl_ord_id: order.client_id |> ClientId.to_venue(:gtc),
        timestamp: @timestamp,
        cum_qty: 20
      )

    ProcessAuth.Message.process(msg, @received_at, @state)

    assert_receive {:order_updated, _, %Tai.Trading.Order{status: :filled} = filled_order}
    assert filled_order.client_id == order.client_id
    assert filled_order.venue_id == :my_venue
    assert filled_order.cumulative_qty == Decimal.new(20)
    assert filled_order.leaves_qty == Decimal.new(0)
    assert filled_order.qty == Decimal.new(20)
    assert %DateTime{} = filled_order.last_received_at
    assert %DateTime{} = filled_order.last_venue_timestamp
  end

  test ".process/3 broadcasts an invalid status warning" do
    Events.firehose_subscribe()

    assert {:ok, order} = enqueue()

    action = struct(Tai.Trading.OrderStore.Actions.Skip, client_id: order.client_id)
    assert {:ok, {old, updated}} = OrderStore.update(action)

    msg =
      struct(ProcessAuth.Messages.UpdateOrders.Filled,
        cl_ord_id: order.client_id |> ClientId.to_venue(:gtc),
        timestamp: @timestamp,
        cum_qty: 20
      )

    ProcessAuth.Message.process(msg, @received_at, @state)

    assert_event(%Events.OrderUpdateInvalidStatus{} = invalid_status_event)
    assert invalid_status_event.action == Tai.Trading.OrderStore.Actions.PassiveFill
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
      struct(ProcessAuth.Messages.UpdateOrders.Filled,
        cl_ord_id: @venue_client_id,
        timestamp: @timestamp,
        cum_qty: 20
      )

    ProcessAuth.Message.process(msg, @received_at, @state)

    assert_event(%Events.OrderUpdateNotFound{} = not_found_event)
    assert not_found_event.client_id != @venue_client_id
    assert not_found_event.action == Tai.Trading.OrderStore.Actions.PassiveFill
  end

  defp enqueue, do: build_submission() |> OrderStore.enqueue()

  defp build_submission do
    struct(Tai.Trading.OrderSubmissions.BuyLimitGtc,
      venue_id: :my_venue,
      account_id: :main,
      product_symbol: :btc_usd,
      price: Decimal.new("100.1"),
      qty: Decimal.new("1.1"),
      order_updated_callback: self()
    )
  end
end
