defmodule Tai.Commands.Positions do
  @moduledoc """
  Display the list of positions and their details
  """

  import Tai.Commands.Table, only: [render!: 2]

  @header [
    "Venue",
    "Account",
    "Product",
    "Side",
    "Qty",
    "Entry Price",
    "Leverage",
    "Margin Mode"
  ]

  @spec positions :: no_return
  def positions do
    Tai.Trading.PositionStore.all()
    |> Enum.sort(&(&1.venue_id < &2.venue_id))
    |> Enum.map(fn position ->
      [
        position.venue_id,
        position.account_id,
        position.product_symbol,
        position.side,
        position.qty,
        position.entry_price,
        position.leverage,
        position.margin_mode
      ]
    end)
    |> render!(@header)
  end
end
