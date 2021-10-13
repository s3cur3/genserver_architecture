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
end
