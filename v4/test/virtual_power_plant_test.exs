defmodule VirtualPowerPlantTest do
  use ExUnit.Case, async: true

  defp setup_vpp(name) do
    {:ok, vpp} = VirtualPowerPlant.start_link(name: name)

    battery_1 = Battery.new(id: "battery_1", max_power_watts: 100, current_power_watts: 80)
    battery_2 = Battery.new(id: "battery_2", max_power_watts: 50, current_power_watts: 30)

    VirtualPowerPlant.add_battery(vpp, battery_1)
    VirtualPowerPlant.add_battery(vpp, battery_2)

    %{vpp_pid: vpp, battery_ids: ["battery_1", "battery_2"], max_power: 150, initial_power: 110}
  end

  test "aggregates batteries" do
    %{vpp_pid: vpp, battery_ids: batteries} = setup_vpp(:aggregate_batteries)

    battery_ids =
      vpp
      |> VirtualPowerPlant.batteries()
      |> Enum.map(& &1.id)
      |> Enum.sort()

    assert battery_ids == batteries
  end

  test "current_power returns the sum of all asset's current_power" do
    %{vpp_pid: vpp, initial_power: initial_power} = setup_vpp(:current_power)
    assert VirtualPowerPlant.current_power(vpp) == initial_power
  end

  test "exports power to the grid to meet a demand" do
    %{vpp_pid: vpp} = setup_vpp(:export)
    VirtualPowerPlant.export(vpp, 5)
    assert VirtualPowerPlant.current_power(vpp) == 5
  end

  test "absorbs power to the grid to meet a demand" do
    %{vpp_pid: vpp} = setup_vpp(:absorb)
    VirtualPowerPlant.absorb(vpp, 5)
    assert VirtualPowerPlant.current_power(vpp) == -5
  end

  test "export and absorb respect max power" do
    %{vpp_pid: vpp, max_power: max_power} = setup_vpp(:respect_max_power)
    VirtualPowerPlant.absorb(vpp, 10 * max_power)
    assert VirtualPowerPlant.current_power(vpp) == -max_power

    VirtualPowerPlant.export(vpp, 10 * max_power)
    assert VirtualPowerPlant.current_power(vpp) == max_power
  end
end
