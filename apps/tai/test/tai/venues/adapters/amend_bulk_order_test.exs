defmodule Tai.Venues.Adapters.AmendBulkOrderTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    start_supervised!(Tai.TestSupport.Mocks.Server)
    HTTPoison.start()
  end

  @test_adapters Tai.TestSupport.Helpers.test_venue_adapters_amend_bulk_order()

  @test_adapters
  |> Enum.map(fn {_, adapter} ->
    @adapter adapter

    test "#{adapter.id} can change price and qty" do
      enqueued_order = build_enqueued_order(@adapter.id, :buy)
      amend_price = amend_price(@adapter.id, enqueued_order.side)
      amend_qty = amend_qty(@adapter.id, enqueued_order.side)
      attrs = amend_attrs(@adapter.id, price: amend_price, qty: amend_qty)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/amend_bulk_price_and_qty_ok" do
        assert {:ok, create_response} = Tai.Venue.create_order(enqueued_order, @test_adapters)

        open_order = build_open_order(enqueued_order, create_response)

        assert {:ok, amend_bulk_response} =
                 Tai.Venue.amend_bulk_orders([{open_order, attrs}], @test_adapters)

        assert Enum.count(amend_bulk_response.orders) == 1

        amend_response = Enum.at(amend_bulk_response.orders, 0)
        assert amend_response.id == open_order.venue_order_id
        assert amend_response.status == :open
        assert amend_response.price == amend_price
        assert amend_response.leaves_qty == amend_qty
        assert amend_response.cumulative_qty == enqueued_order.cumulative_qty
        assert %DateTime{} = amend_response.received_at
        assert %DateTime{} = amend_response.venue_timestamp
      end
    end
  end)

  defp build_enqueued_order(venue_id, side) do
    struct(Tai.Trading.Order, %{
      client_id: Ecto.UUID.generate(),
      venue_id: venue_id,
      account_id: :main,
      product_symbol: venue_id |> product_symbol,
      side: side,
      price: venue_id |> price(side),
      qty: venue_id |> qty(side),
      cumulative_qty: Decimal.new(0),
      time_in_force: :gtc,
      post_only: true
    })
  end

  defp build_open_order(order, amend_response) do
    struct(Tai.Trading.Order, %{
      venue_order_id: amend_response.id,
      venue_id: order.venue_id,
      account_id: :main,
      symbol: order.venue_id |> product_symbol,
      side: order.side,
      price: order.venue_id |> price(order.side),
      qty: order.venue_id |> qty(order.side),
      cumulative_qty: Decimal.new(0),
      time_in_force: :gtc,
      post_only: true
    })
  end

  defp product_symbol(:bitmex), do: :xbtusd
  defp product_symbol(_), do: :btc_usd

  defp price(:bitmex, :buy), do: Decimal.new("2001.5")

  defp amend_price(:bitmex, :buy), do: Decimal.new("2300.5")

  defp qty(:bitmex, _), do: Decimal.new(2)

  defp amend_qty(:bitmex, :buy), do: Decimal.new(10)

  defp amend_attrs(:bitmex, price: price, qty: qty), do: %{price: price, qty: qty}
  defp amend_attrs(:bitmex, price: price), do: %{price: price}
  defp amend_attrs(:bitmex, qty: qty), do: %{qty: qty}
end
