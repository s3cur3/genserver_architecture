defmodule VirtualPowerPlant.Server do
  @moduledoc """
  A stateful wrapper around a VirtualPowerPlant struct
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
    {:ok, %VirtualPowerPlant{}}
  end

  def handle_call({:add_battery, battery}, _from, state) do
    {:reply, :ok, VirtualPowerPlant.add_battery(state, battery)}
  end

  def handle_call(:batteries, _from, state) do
    {:reply, VirtualPowerPlant.batteries(state), state}
  end

  def handle_call(:total_power, _from, state) do
    {:reply, VirtualPowerPlant.current_power(state), state}
  end

  def handle_call({:set_power, needed_watts}, _from, state) do
    {:reply, :ok, VirtualPowerPlant.set_power(state, needed_watts)}
  end
end
