defmodule VirtualPowerPlantTest do
  use ExUnit.Case, async: true

  test "aggregates batteries" do
    {:ok, vpp} = VirtualPowerPlant.start_link(name: :test1)
    VirtualPowerPlant.add_battery(vpp, "battery_1", 100)
    VirtualPowerPlant.add_battery(vpp, "battery_2", 100)

    battery_ids =
      vpp
      |> VirtualPowerPlant.batteries()
      |> Enum.map(& &1.id)

    assert Enum.sort(battery_ids) == ["battery_1", "battery_2"]
  end

  test "current_power returns the sum of all asset's current_power" do
    {:ok, vpp} = VirtualPowerPlant.start_link(name: :test1)
    VirtualPowerPlant.add_battery(vpp, "battery_1", 100, 8)
    VirtualPowerPlant.add_battery(vpp, "battery_2", 100, 3)

    assert VirtualPowerPlant.current_power(vpp) == 11
  end

  test "exports power to the grid to meet a demand" do
    {:ok, vpp} = VirtualPowerPlant.start_link(name: :test1)
    VirtualPowerPlant.add_battery(vpp, "battery_1", 100)

    VirtualPowerPlant.export(vpp, 5)

    assert VirtualPowerPlant.current_power(vpp) == 5
  end

  test "absorbs power to the grid to meet a demand" do
    {:ok, vpp} = VirtualPowerPlant.start_link(name: :test1)
    VirtualPowerPlant.add_battery(vpp, "battery_1", 100)

    VirtualPowerPlant.absorb(vpp, 5)

    assert VirtualPowerPlant.current_power(vpp) == -5
  end

  test "export and absorb respect max power" do
    {:ok, vpp} = VirtualPowerPlant.start_link(name: :test1)
    VirtualPowerPlant.add_battery(vpp, "battery_1", 100)
    VirtualPowerPlant.add_battery(vpp, "battery_2", 50)

    VirtualPowerPlant.absorb(vpp, 1_000)
    assert VirtualPowerPlant.current_power(vpp) == -150

    VirtualPowerPlant.export(vpp, 1_000)
    assert VirtualPowerPlant.current_power(vpp) == 150
  end
end
