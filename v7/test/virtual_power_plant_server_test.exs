defmodule VirtualPowerPlant.ServerTest do
  use ExUnit.Case, async: true


  describe "smoke test" do
    setup do
      total_max_power = 1_000
      battery_count = 20
      per_battery_power = total_max_power / battery_count

      batteries =
        for battery_idx <- 1..battery_count do
          Battery.new(id: "battery_#{battery_idx}", max_power_watts: per_battery_power, current_power_watts: per_battery_power * :rand.uniform())
        end

      {:ok, vpp} = VirtualPowerPlant.Server.start_link(name: :smoke_test)
      Enum.each(batteries, &VirtualPowerPlant.Server.add_battery(vpp, &1))

      %{vpp_pid: vpp, batteries: batteries, max_power: total_max_power}
    end

    test "aggregates batteries", %{vpp_pid: vpp_pid, batteries: initial_batteries} do
      server_batteries = VirtualPowerPlant.Server.batteries(vpp_pid)
      assert TestUtils.count_changed(server_batteries, initial_batteries) == 0
    end

    test "exports power", %{vpp_pid: vpp_pid, max_power: total_max_power} do
      VirtualPowerPlant.Server.export(vpp_pid, 2 * total_max_power)
      assert VirtualPowerPlant.Server.current_power(vpp_pid) == total_max_power
    end

    test "absorbs power", %{vpp_pid: vpp_pid, max_power: total_max_power} do
      VirtualPowerPlant.Server.absorb(vpp_pid, 2 * total_max_power)
      assert VirtualPowerPlant.Server.current_power(vpp_pid) == -total_max_power
    end
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
