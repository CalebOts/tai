defmodule Tai.VenueAdapters.OkEx do
  alias Tai.VenueAdapters.OkEx.{
    StreamSupervisor,
    Products,
    AssetBalances,
    Positions,
    MakerTakerFees,
    CreateOrder,
    CancelOrder
  }

  @behaviour Tai.Venues.Adapter

  def stream_supervisor, do: StreamSupervisor
  defdelegate products(venue_id), to: Products
  defdelegate asset_balances(venue_id, account_id, credentials), to: AssetBalances
  defdelegate maker_taker_fees(venue_id, account_id, credentials), to: MakerTakerFees
  defdelegate positions(venue_id, account_id, credentials), to: Positions
  defdelegate create_order(order, credentials), to: CreateOrder
  def amend_order(_order, _attrs, _credentials), do: {:error, :not_supported}
  def amend_bulk_orders(_orders_with_attrs, _credentials), do: {:error, :not_supported}
  defdelegate cancel_order(order, credentials), to: CancelOrder
end
