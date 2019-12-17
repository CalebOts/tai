defmodule Tai.VenueAdapters.Bitmex.AssetBalances do
  def asset_balances(venue_id, account_id, credentials) do
    with {:ok, wallet, _rate_limit} <-
           ExBitmex.Rest.HTTPClient.auth_get("/user/wallet", credentials, %{currency: "XBt"}) do
      balance = build(wallet, venue_id, account_id)
      {:ok, [balance]}
    end
  end

  def build(
        %{"currency" => "XBt", "amount" => amount},
        venue_id,
        account_id
      ) do
    %Tai.Venues.AssetBalance{
      venue_id: venue_id,
      account_id: account_id,
      asset: :btc,
      type: "default",
      free: amount |> Decimal.new() |> Decimal.reduce(),
      locked: Decimal.new(0)
    }
  end
end
