defmodule VirtualPowerPlant do
  @moduledoc """
  A "virtual power plant" is a collection of grid-connected batteries
  that we can control remotely.

  We ask these batteries to either pump power onto to the grid to meet
  increased demand, or we ask them to absorb and store power that was
  generated in excess of demand (e.g., by solar installations).
  """
  use GenServer

  def start_link(opts) do
    server_name = Access.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, [], name: server_name)
  end

  @doc """
  Associates this battery with our virtual power plant, allowing us to
  control it to meet grid needs.
  """
  def add_battery(server \\ __MODULE__, %Battery{} = battery) do
    GenServer.call(server, {:add_battery, battery})
  end

  @doc "The collection of battery structs we control"
  def batteries(server \\ __MODULE__) do
    GenServer.call(server, :batteries)
  end

  @doc """
  The total wattage our virtual power plant is contributing to the grid
  (positive values) or absorbing off the grid (negative values).
  """
  def current_power(server \\ __MODULE__) do
    GenServer.call(server, :total_power)
  end

  @doc """
  Attempt to change our batteries' state to contribute this many watts to the grid.
  Overrides any previous requests.
  """
  def export(server \\ __MODULE__, watts) do
    GenServer.call(server, {:set_power, watts})
  end

  @doc """
  Attempt to change our batteries' state to absorb this many watts to the grid.
  Overrides any previous requests.
  """
  def absorb(server \\ __MODULE__, watts) do
    GenServer.call(server, {:set_power, -watts})
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
      |> Enum.map(& &1.current_power_watts)
      |> Enum.sum()

    {:reply, total_power, battery_collection}
  end

  def handle_call({:set_power, needed_watts}, _from, battery_collection) do
    {updated_batteries, _unmet_need} =
      Enum.reduce(battery_collection, {[], needed_watts}, fn battery, {updated_batteries, need} ->
        updated_battery = Battery.update_current_power(battery, need)
        updated_need = need - updated_battery.current_power_watts
        {[updated_battery | updated_batteries], updated_need}
      end)

    {:reply, :ok, updated_batteries}
  end
end
