defmodule VirtualPowerPlant do
  @moduledoc """
  A "virtual power plant" is a collection of grid-connected batteries
  that we can control remotely.

  We ask these batteries to either pump power onto to the grid to meet
  increased demand, or we ask them to absorb and store power that was
  generated in excess of demand (e.g., by solar installations).
  """
  defstruct batteries: []

  @doc """
  Associates this battery with our virtual power plant, allowing us to
  control it to meet grid needs.
  """
  def add_battery(%__MODULE__{} = vpp, %Battery{} = battery) do
    %{vpp | batteries: [battery | vpp.batteries]}
  end

  @doc "The collection of battery structs we control"
  def batteries(%__MODULE__{} = vpp) do
    vpp.batteries
  end

  @doc """
  The total wattage our virtual power plant is contributing to the grid
  (positive values) or absorbing off the grid (negative values).
  """
  def current_power(%__MODULE__{batteries: battery_collection}) do
    battery_collection
    |> Enum.map(& &1.current_power_watts)
    |> Enum.sum()
  end

  @doc """
  Attempt to change our batteries' state to contribute or absorb this many watts to the grid.
  Overrides any previous requests.
  """
  def set_power(%__MODULE__{batteries: battery_collection} = vpp, needed_watts) do
    {updated_batteries, _unmet_need} =
      Enum.reduce(battery_collection, {[], needed_watts}, fn battery, {updated_batteries, need} ->
        updated_battery = Battery.update_current_power(battery, need)
        updated_need = need - updated_battery.current_power_watts
        {[updated_battery | updated_batteries], updated_need}
      end)

    %{vpp | batteries: updated_batteries}
  end

  @doc """
  Updates the n least recently updated batteries.
  """
  def update_batteries_from_remote(%__MODULE__{batteries: battery_collection} = vpp, batch_size) do
    {to_update, remainder} = Enum.split(battery_collection, batch_size)
    updated = Enum.map(to_update, &Battery.fetch_remote_state/1)
    %{vpp | batteries: remainder ++ updated}
  end
end
