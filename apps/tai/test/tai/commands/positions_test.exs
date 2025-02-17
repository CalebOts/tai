defmodule Tai.Commands.PositionsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  test "shows positions ordered by venue & account" do
    {:ok, _} =
      Tai.Trading.Position
      |> struct(
        venue_id: :venue_a,
        account_id: :account_a,
        product_symbol: :btc_usd,
        side: :long,
        qty: Decimal.new(5),
        entry_price: Decimal.new("3066.45"),
        leverage: Decimal.new("20.1"),
        margin_mode: :crossed
      )
      |> Tai.Trading.PositionStore.add()

    {:ok, _} =
      Tai.Trading.Position
      |> struct(
        venue_id: :venue_b,
        account_id: :account_b,
        product_symbol: :ltc_usd,
        side: :short,
        qty: Decimal.new(1),
        entry_price: Decimal.new("24.66"),
        leverage: Decimal.new("11.5"),
        margin_mode: :fixed
      )
      |> Tai.Trading.PositionStore.add()

    assert capture_io(&Tai.CommandsHelper.positions/0) == """
           +---------+-----------+---------+-------+-----+-------------+----------+-------------+
           |   Venue |   Account | Product |  Side | Qty | Entry Price | Leverage | Margin Mode |
           +---------+-----------+---------+-------+-----+-------------+----------+-------------+
           | venue_a | account_a | btc_usd |  long |   5 |     3066.45 |     20.1 |     crossed |
           | venue_b | account_b | ltc_usd | short |   1 |       24.66 |     11.5 |       fixed |
           +---------+-----------+---------+-------+-----+-------------+----------+-------------+\n
           """
  end

  test "shows an empty table when there are no positions" do
    assert capture_io(&Tai.CommandsHelper.positions/0) == """
           +-------+---------+---------+------+-----+-------------+----------+-------------+
           | Venue | Account | Product | Side | Qty | Entry Price | Leverage | Margin Mode |
           +-------+---------+---------+------+-----+-------------+----------+-------------+
           |     - |       - |       - |    - |   - |           - |        - |           - |
           +-------+---------+---------+------+-----+-------------+----------+-------------+\n
           """
  end
end
