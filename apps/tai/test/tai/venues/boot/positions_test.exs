defmodule Tai.Venues.Boot.PositionsTest do
  use ExUnit.Case, async: false
  doctest Tai.Venues.Boot.Positions

  defmodule MyAdapter do
    def positions(_, _, _) do
      positions = [
        struct(Tai.Trading.Position, %{product_symbol: :btc_usd}),
        struct(Tai.Trading.Position, %{product_symbol: :eth_usd})
      ]

      {:ok, positions}
    end
  end

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  test ".hydrate broadcasts a summary event" do
    config =
      Tai.Config.parse(
        venues: %{
          my_venue: [
            enabled: true,
            adapter: MyAdapter,
            accounts: %{main: %{}},
            products: "btc_usd"
          ]
        }
      )

    %{my_venue: adapter} = Tai.Venues.Config.parse_adapters(config)
    Tai.Events.firehose_subscribe()

    Tai.Venues.Boot.Positions.hydrate(adapter)

    assert_receive {Tai.Event, %Tai.Events.HydratePositions{} = event, _}
    assert event.venue_id == :my_venue
    assert event.total == 2
  end
end
