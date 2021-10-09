defmodule VirtualPowerPlant do
  @moduledoc """
  A "virtual power plant" is a collection of grid-connected batteries
  that we can control remotely.

  We ask these batteries to either pump power onto to the grid to meet
  increased demand, or we ask them to absorb and store power that was
  generated in excess of demand (e.g., by solar installations).
  """
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Associates this battery with our virtual power plant, allowing us to
  control it to meet grid needs.
  """
  def add_battery(battery) do
    GenServer.cast(__MODULE__, {:add_battery, battery})
  end

  @doc "Collection of IDs for the batteries we control"
  def batteries do
    GenServer.call(__MODULE__, :batteries)
  end

  @doc """
  The total wattage our virtual power plant is contributing to the grid
  (positive values) or absorbing off the grid (negative values).
  """
  def current_power do
    GenServer.call(__MODULE__, :total_power)
  end

  @doc """
  Attempt to change our batteries' state to contribute this many watts to the grid.
  Overrides any previous requests.
  """
  def export(watts) do
    GenServer.cast(__MODULE__, {:set_power, watts})
  end

  @doc """
  Attempt to change our batteries' state to absorb this many watts to the grid.
  Overrides any previous requests.
  """
  def absorb(watts) do
    GenServer.cast(__MODULE__, {:set_power, -watts})
  end

  # Server implementation
  def init(_) do
    {:ok, []}
  end

  def handle_call(:batteries, _from, battery_collection) do
    {:reply, battery_collection, battery_collection}
  end

  def handle_call(:total_power, _from, battery_collection) do
    total_power =
      battery_collection
      |> Enum.map(&Battery.current_power/1)
      |> Enum.sum()

    {:reply, total_power, battery_collection}
  end

  def handle_cast({:add_battery, battery}, battery_collection) do
    updated_state = [battery | battery_collection]
    {:noreply, updated_state}
  end

  def handle_cast({:set_power, needed_watts}, battery_collection) do
    _unmet_need =
      Enum.reduce(battery_collection, needed_watts, fn battery, remaining_need ->
        requested_watts =
          if remaining_need >= 0 do
            min(Battery.max_power(battery), remaining_need)
          else
            max(-Battery.max_power(battery), remaining_need)
          end

        Battery.update_current_power(battery, requested_watts)
        needed_watts - requested_watts
      end)

    {:noreply, battery_collection}
  end

end
