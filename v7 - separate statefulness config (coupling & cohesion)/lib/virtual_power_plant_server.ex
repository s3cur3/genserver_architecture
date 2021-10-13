defmodule VirtualPowerPlant.Server do
  @moduledoc """
  A stateful wrapper around a VirtualPowerPlant struct
  """
  use GenServer

  @default_update_ms 60_000
  @default_update_batch_size 10

  @type option :: {:name, atom} | {:remote_update_ms, integer} | {:remote_update_batch_size, integer}
  @spec start_link([option]) :: GenServer.on_start()
  def start_link(opts \\ []) do
    config = %{
      remote_update_ms: Access.get(opts, :remote_update_ms, @default_update_ms),
      remote_update_batch_size: Access.get(opts, :remote_update_batch_size, @default_update_batch_size)
    }

    server_name = Access.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, config, name: server_name)
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
  def init(config) do
    Process.send_after(self(), :fetch_remote_state, config.remote_update_ms)
    {:ok, {%VirtualPowerPlant{}, config}}
  end

  # Nobody ever said the first element of your tuple has to be an atom...
  @impl GenServer
  def handle_call({impl_function, args}, _from, {state, config}) when is_function(impl_function) do
    {:reply, return, updated_state} = GenImpl.apply_call(impl_function, state, args)
    {:reply, return, {updated_state, config}}
  end

  @impl GenServer
  def handle_info(:fetch_remote_state, {state, config}) do
    updated_state = VirtualPowerPlant.update_batteries_from_remote(state, config.remote_update_batch_size)
    Process.send_after(self(), :fetch_remote_state, config.remote_update_ms)
    {:noreply, {updated_state, config}}
  end
end
