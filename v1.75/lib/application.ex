defmodule EnergyApplication do
  @moduledoc "Entry point for the application at launch"
  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      # TODO: Add supervision trees, registry, etc. here
      BatteryRegistry,
      VirtualPowerPlant
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: EnergySupervisor)
  end
end
