defmodule Battery do
  @moduledoc """
  Represents a physical, remotely controllable, grid-connected battery.
  Batteries are useful for balancing energy grids, because they can
  either contribute power to the grid (when demand outpaces production),
  or absorb and store power (when production outpaces demand).
  """
  @enforce_keys [:id, :max_power_watts]
  defstruct @enforce_keys ++ [current_power_watts: 0]

  def new(fields) do
    naive_battery = struct(__MODULE__, fields)
    limited_power = limit_power(naive_battery.current_power_watts, naive_battery.max_power_watts)
    %{naive_battery | current_power_watts: limited_power}
  end

  @doc """
  Attempts to set our current power to the new value.
  Returns the actual value set (limited by max power).
  """
  def update_current_power(%Battery{max_power_watts: max_power} = battery, watts) do
    %{battery | current_power_watts: limit_power(watts, max_power)}
  end

  defp limit_power(watts, max_watts) do
    if watts >= 0 do
      min(max_watts, watts)
    else
      max(-max_watts, watts)
    end
  end
end
