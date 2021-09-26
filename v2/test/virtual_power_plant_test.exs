defmodule VirtualPowerPlantTest do
  use ExUnit.Case

  setup do
    # Haaaaack!
    :sys.replace_state(VirtualPowerPlant, fn _ -> [] end)
  end

  test "aggregates batteries" do
    {:ok, _pid1} = Battery.create("battery_1", 100)
    {:ok, _pid2} = Battery.create("battery_2", 100)

    {:ok, vpp} = VirtualPowerPlant.start_link(name: :test1)
    VirtualPowerPlant.add_battery(vpp, "battery_1")
    VirtualPowerPlant.add_battery(vpp, "battery_2")

    batteries = VirtualPowerPlant.batteries(vpp)
    assert Enum.sort(batteries) == ["battery_1", "battery_2"]
  end

  test "current_power returns the sum of all asset's current_power" do
    {:ok, _pid1} = Battery.create("battery_1", 100, 8)
    {:ok, _pid2} = Battery.create("battery_2", 100, 3)

    {:ok, vpp} = VirtualPowerPlant.start_link(name: :test1)
    VirtualPowerPlant.add_battery(vpp, "battery_1")
    VirtualPowerPlant.add_battery(vpp, "battery_2")

    assert VirtualPowerPlant.current_power(vpp) == 11
  end

  test "exports power to the grid to meet a demand" do
    {:ok, _pid1} = Battery.create("battery_1", 100)

    {:ok, vpp} = VirtualPowerPlant.start_link(name: :test1)
    VirtualPowerPlant.add_battery(vpp, "battery_1")

    VirtualPowerPlant.export(vpp, 5)

    assert VirtualPowerPlant.current_power(vpp) == 5
  end

  test "absorbs power to the grid to meet a demand" do
    {:ok, _pid1} = Battery.create("battery_1", 100)

    {:ok, vpp} = VirtualPowerPlant.start_link(name: :test1)
    VirtualPowerPlant.add_battery(vpp, "battery_1")

    VirtualPowerPlant.absorb(vpp, 5)

    assert VirtualPowerPlant.current_power(vpp) == -5
  end

  test "export and absorb respect max power" do
    {:ok, _pid1} = Battery.create("battery_1", 100)
    {:ok, _pid2} = Battery.create("battery_2", 50)

    {:ok, vpp} = VirtualPowerPlant.start_link(name: :test1)
    VirtualPowerPlant.add_battery(vpp, "battery_1")
    VirtualPowerPlant.add_battery(vpp, "battery_2")

    VirtualPowerPlant.absorb(vpp, 1_000)
    assert VirtualPowerPlant.current_power(vpp) == -150

    VirtualPowerPlant.export(vpp, 1_000)
    assert VirtualPowerPlant.current_power(vpp) == 150
  end
end
