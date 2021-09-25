defmodule BatteryRegistry do
  @moduledoc "Boilerplate for registering Battery processes by ID string"

  def via_tuple(key) do
    {:via, Registry, {__MODULE__, key}}
  end

  def whereis_name(key) do
    Registry.whereis_name({__MODULE__, key})
  end

  def start_link(_) do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end
end
