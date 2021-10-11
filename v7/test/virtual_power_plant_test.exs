defmodule VirtualPowerPlantTest do
  use ExUnit.Case, async: true

  test "aggregates batteries" do
    battery_1 = Battery.new(id: "battery_1", max_power_watts: 100)
    battery_2 = Battery.new(id: "battery_2", max_power_watts: 100)

    vpp =
      %VirtualPowerPlant{}
      |> VirtualPowerPlant.add_battery(battery_1)
      |> VirtualPowerPlant.add_battery(battery_2)

    batteries = VirtualPowerPlant.batteries(vpp)
    assert MapSet.new(batteries) == MapSet.new([battery_1, battery_2])
  end

  test "current_power returns the sum of all asset's current_power" do
    battery_1 = Battery.new(id: "battery_1", max_power_watts: 100, current_power_watts: 8)
    battery_2 = Battery.new(id: "battery_2", max_power_watts: 50, current_power_watts: 3)

    vpp =
      %VirtualPowerPlant{}
      |> VirtualPowerPlant.add_battery(battery_1)
      |> VirtualPowerPlant.add_battery(battery_2)

    assert VirtualPowerPlant.current_power(vpp) == 11
  end

  test "exports and absorbs power to the grid to meet a demand" do
    battery_1 = Battery.new(id: "battery_1", max_power_watts: 100)
    vpp = VirtualPowerPlant.add_battery(%VirtualPowerPlant{}, battery_1)

    for requested_power <- [5, -5, 100, -100] do
      updated_vpp = VirtualPowerPlant.set_power(vpp, requested_power)
      assert VirtualPowerPlant.current_power(updated_vpp) == requested_power
    end
  end

  test "export and absorb respect max power" do
    battery_1 = Battery.new(id: "battery_1", max_power_watts: 100)
    battery_2 = Battery.new(id: "battery_2", max_power_watts: 50)

    vpp =
      %VirtualPowerPlant{}
      |> VirtualPowerPlant.add_battery(battery_1)
      |> VirtualPowerPlant.add_battery(battery_2)

    for {requested_power, expected_power} <- [{1_000, 150}, {-1_000, -150}] do
      updated_vpp = VirtualPowerPlant.set_power(vpp, requested_power)
      assert VirtualPowerPlant.current_power(updated_vpp) == expected_power
    end
  end

  test "updates batteries in batches" do
    battery_1 = Battery.new(id: "battery_1", max_power_watts: 100, current_power_watts: 50)
    battery_2 = Battery.new(id: "battery_2", max_power_watts: 50, current_power_watts: 40)

    vpp =
      %VirtualPowerPlant{}
      |> VirtualPowerPlant.add_battery(battery_1)
      |> VirtualPowerPlant.add_battery(battery_2)
      |> VirtualPowerPlant.update_batteries_from_remote(1)

    initial_batteries = [battery_1, battery_2]
    updated_batteries = VirtualPowerPlant.batteries(vpp)
    assert TestUtils.count_changed(initial_batteries, updated_batteries) == 1
  end
end
