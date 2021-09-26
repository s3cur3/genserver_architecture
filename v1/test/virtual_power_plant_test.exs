defmodule VirtualPowerPlantTest do
  use ExUnit.Case

  setup do
    # Haaaaack!
    :sys.replace_state(VirtualPowerPlant, fn _ -> [] end)
  end

  test "aggregates batteries" do
    {:ok, _pid1} = Battery.create("battery_1", 100)
    {:ok, _pid2} = Battery.create("battery_2", 100)

    VirtualPowerPlant.add_battery("battery_1")
    VirtualPowerPlant.add_battery("battery_2")

    batteries = VirtualPowerPlant.batteries()
    assert Enum.sort(batteries) == ["battery_1", "battery_2"]
  end

  test "current_power returns the sum of all asset's current_power" do
    {:ok, _pid1} = Battery.create("battery_1", 100, 8)
    {:ok, _pid2} = Battery.create("battery_2", 100, 3)

    VirtualPowerPlant.add_battery("battery_1")
    VirtualPowerPlant.add_battery("battery_2")

    assert VirtualPowerPlant.current_power() == 11
  end

  test "exports power to the grid to meet a demand" do
    {:ok, _pid1} = Battery.create("battery_1", 100)
    VirtualPowerPlant.add_battery("battery_1")

    VirtualPowerPlant.export(5)

    assert VirtualPowerPlant.current_power() == 5
  end

  test "absorbs power to the grid to meet a demand" do
    {:ok, _pid1} = Battery.create("battery_1", 100)
    VirtualPowerPlant.add_battery("battery_1")

    VirtualPowerPlant.absorb(5)

    assert VirtualPowerPlant.current_power() == -5
  end

  test "export and absorb respect max power" do
    {:ok, _pid1} = Battery.create("battery_1", 100)
    {:ok, _pid2} = Battery.create("battery_2", 50)

    VirtualPowerPlant.add_battery("battery_1")
    VirtualPowerPlant.add_battery("battery_2")

    VirtualPowerPlant.absorb(1_000)
    assert VirtualPowerPlant.current_power() == -150

    VirtualPowerPlant.export(1_000)
    assert VirtualPowerPlant.current_power() == 150
  end
end
