defmodule Tai.Events.VenueBootErrorTest do
  use ExUnit.Case, async: true

  test ".to_data/1 transforms reason to a string" do
    event = %Tai.Events.VenueBootError{
      venue: :my_venue,
      reason: [asset_balances: :mock_not_found]
    }

    assert Tai.LogEvent.to_data(event) == %{
             venue: :my_venue,
             reason: "[asset_balances: :mock_not_found]"
           }
  end
end
