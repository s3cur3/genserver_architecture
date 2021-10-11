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

  test "fetches remote states on a timer" do
    batch_size = 2
    update_ms = 5

    batteries =
      for idx <- 1..(10 * batch_size) do
        Battery.new(id: "battery_#{idx}", max_power_watts: 75, current_power_watts: 30)
      end

    {:ok, vpp} =
      VirtualPowerPlant.Server.start_link(
        name: :remote_fetch,
        remote_update_ms: update_ms,
        remote_update_batch_size: batch_size
      )

    for battery <- batteries do
      VirtualPowerPlant.Server.add_battery(vpp, battery)
    end

    :timer.sleep(4 * update_ms)

    updated_batteries = VirtualPowerPlant.Server.batteries(vpp)
    num_changed = TestUtils.count_changed(batteries, updated_batteries)

    # Very loose limits since schedule timing in CI can be... messy
    assert num_changed >= 2 * batch_size
    assert num_changed <= 6 * batch_size
  end
end
