defmodule VirtualPowerPlantTest do
  use ExUnit.Case, async: true

  setup do
    battery_1 = Battery.new(id: "battery_1", max_power_watts: 100, current_power_watts: 80)
    battery_2 = Battery.new(id: "battery_2", max_power_watts: 50, current_power_watts: 30)

    vpp =
      %VirtualPowerPlant{}
      |> VirtualPowerPlant.add_battery(battery_1)
      |> VirtualPowerPlant.add_battery(battery_2)

    %{vpp: vpp, batteries: [battery_1, battery_2], max_power: 150, initial_power: 110}
  end

  test "aggregates batteries", %{vpp: vpp, batteries: initial_batteries} do
    batteries = VirtualPowerPlant.batteries(vpp)
    assert TestUtils.count_changed(batteries, initial_batteries) == 0
  end

  test "current_power returns the sum of all asset's current_power", %{vpp: vpp, initial_power: power} do
    assert VirtualPowerPlant.current_power(vpp) == power
  end

  test "exports and absorbs power to the grid to meet a demand", %{vpp: vpp, max_power: max_power} do
    for requested_power <- [round(max_power / 5), -round(max_power / 5), max_power, -max_power] do
      updated_vpp = VirtualPowerPlant.set_power(vpp, round(requested_power))
      assert VirtualPowerPlant.current_power(updated_vpp) == requested_power
    end
  end

  test "export and absorb respect max power", %{vpp: vpp, max_power: max_power} do
    for sign <- [1, -1] do
      updated_vpp = VirtualPowerPlant.set_power(vpp, sign * 10 * max_power)
      assert VirtualPowerPlant.current_power(updated_vpp) == sign * max_power
    end
  end

  test "updates batteries in batches", %{vpp: vpp, batteries: initial_batteries} do
    updated_batteries =
      vpp
      |> VirtualPowerPlant.update_batteries_from_remote(1)
      |> VirtualPowerPlant.batteries()

    assert TestUtils.count_changed(initial_batteries, updated_batteries) == 1
  end
end
