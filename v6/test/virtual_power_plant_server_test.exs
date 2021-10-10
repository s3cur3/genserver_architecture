defmodule VirtualPowerPlant.ServerTest do
  use ExUnit.Case, async: true

  test "smoke test: aggregates, exports, absorbs" do
    battery_1 = Battery.new(id: "battery_1", max_power_watts: 75)
    battery_2 = Battery.new(id: "battery_2", max_power_watts: 50)

    {:ok, vpp} = VirtualPowerPlant.Server.start_link(name: :test1)
    VirtualPowerPlant.Server.add_battery(vpp, battery_1)
    VirtualPowerPlant.Server.add_battery(vpp, battery_2)

    VirtualPowerPlant.Server.absorb(vpp, 1_000)
    assert VirtualPowerPlant.Server.current_power(vpp) == -125

    VirtualPowerPlant.Server.export(vpp, 1_000)
    assert VirtualPowerPlant.Server.current_power(vpp) == 125

    batteries = VirtualPowerPlant.Server.batteries(vpp)

    expected_batteries = [
      %{battery_1 | current_power_watts: 75},
      %{battery_2 | current_power_watts: 50}
    ]

    assert MapSet.new(batteries) == MapSet.new(expected_batteries)
  end
end
