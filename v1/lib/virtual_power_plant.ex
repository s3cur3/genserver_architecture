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
    GenServer.call(__MODULE__, {:add_battery, battery})
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
    GenServer.call(__MODULE__, {:set_power, watts})
  end

  @doc """
  Attempt to change our batteries' state to absorb this many watts to the grid.
  Overrides any previous requests.
  """
  def absorb(watts) do
    GenServer.call(__MODULE__, {:set_power, -watts})
  end

  # Server implementation
  def init(_) do
    {:ok, []}
  end

  def handle_call({:add_battery, battery}, _from, battery_collection) do
    updated_state = [battery | battery_collection]
    {:reply, :ok, updated_state}
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

  def handle_call({:set_power, needed_watts}, _from, battery_collection) do
    _unmet_need =
      Enum.reduce(battery_collection, needed_watts, fn battery, remaining_need ->
        actual_setpoint = Battery.update_current_power(battery, remaining_need)
        needed_watts - actual_setpoint
      end)

    {:reply, :ok, battery_collection}
  end

end
