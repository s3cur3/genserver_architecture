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
  def add_battery(server \\ __MODULE__, %Battery{} = battery),
      do: GenServer.call(server, {&VirtualPowerPlant.add_battery/2, [battery]})

  @doc "The collection of battery structs we control"
  def batteries(server \\ __MODULE__),
      do: GenServer.call(server, {&VirtualPowerPlant.batteries/1, []})

  @doc """
  The total wattage our virtual power plant is contributing to the grid
  (positive values) or absorbing off the grid (negative values).
  """
  def current_power(server \\ __MODULE__),
      do: GenServer.call(server, {&VirtualPowerPlant.current_power/1, []})

  @doc """
  Attempt to change our batteries' state to contribute this many watts to the grid.
  Overrides any previous requests.
  """
  def export(server \\ __MODULE__, watts),
      do: GenServer.call(server, {&VirtualPowerPlant.set_power/2, [watts]})

  @doc """
  Attempt to change our batteries' state to absorb this many watts to the grid.
  Overrides any previous requests.
  """
  def absorb(server \\ __MODULE__, watts),
      do: GenServer.call(server, {&VirtualPowerPlant.set_power/2, [-watts]})

  @impl GenServer
  def init(_) do
    {:ok, %VirtualPowerPlant{}}
  end

  # Nobody ever said the first element of your tuple has to be an atom...
  @impl GenServer
  def handle_call({implementation_function, args}, _from, state) when is_function(implementation_function) do
    GenImpl.apply_call(implementation_function, state, args)
  end
end
