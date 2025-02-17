defmodule Tai.Events.AddFreeAssetBalance do
  @type t :: %Tai.Events.AddFreeAssetBalance{
          venue_id: atom,
          account_id: atom,
          asset: atom,
          val: Decimal.t(),
          free: Decimal.t(),
          locked: Decimal.t()
        }

  @enforce_keys [
    :venue_id,
    :account_id,
    :asset,
    :val,
    :free,
    :locked
  ]
  defstruct [
    :venue_id,
    :account_id,
    :asset,
    :val,
    :free,
    :locked
  ]
end

defimpl Tai.LogEvent, for: Tai.Events.AddFreeAssetBalance do
  def to_data(event) do
    keys =
      event
      |> Map.keys()
      |> Enum.filter(&(&1 != :__struct__))

    event
    |> Map.take(keys)
    |> Map.put(:val, event.val |> Decimal.to_string(:normal))
    |> Map.put(:free, event.free |> Decimal.to_string(:normal))
    |> Map.put(:locked, event.locked |> Decimal.to_string(:normal))
  end
end
