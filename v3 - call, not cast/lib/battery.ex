defmodule Battery do
  @moduledoc """
  Represents a physical, remotely controllable, grid-connected battery.
  Batteries are useful for balancing energy grids, because they can
  either contribute power to the grid (when demand outpaces production),
  or absorb and store power (when production outpaces demand).
  """
  use GenServer

  def create(id, max_power_watts, current_power_watts \\ 0) do
    initial_state = {id, max_power_watts, current_power_watts}
    GenServer.start_link(__MODULE__, initial_state, name: via_tuple(id))
  end

  @doc """
  Attempts to set our current power to the new value.
  Returns the actual value set (limited by max power).
  """
  def update_current_power(id, watts) do
    GenServer.call(via_tuple(id), {:update_power, watts})
  end

  def current_power(id) do
    GenServer.call(via_tuple(id), :current_power)
  end

  # Server implementation
  def init({id, max_power_watts, current_power_watts}) do
    starting_power = limit_power(current_power_watts, max_power_watts)
    {:ok, {id, max_power_watts, starting_power}}
  end

  def handle_call({:update_power, watts}, _from, {id, max_power_watts, _prev_power}) do
    updated_power = limit_power(watts, max_power_watts)
    updated_state = {id, max_power_watts, updated_power}
    {:reply, updated_power, updated_state}
  end

  def handle_call(:current_power, _from, {_id, _max_power, current_power} = state) do
    {:reply, current_power, state}
  end

  defp limit_power(watts, max_watts) do
    if watts >= 0 do
      min(max_watts, watts)
    else
      max(-max_watts, watts)
    end
  end

  defp via_tuple(id) do
    BatteryRegistry.via_tuple({__MODULE__, id})
  end
end
