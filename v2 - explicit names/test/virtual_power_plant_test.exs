defmodule VirtualPowerPlantTest do
  use ExUnit.Case, async: true

  defp setup_vpp(name) do
    {:ok, vpp} = VirtualPowerPlant.start_link(name: name)

    {:ok, _pid1} = Battery.create("battery_1", 100, 80)
    {:ok, _pid2} = Battery.create("battery_2", 50, 30)

    VirtualPowerPlant.add_battery(vpp, "battery_1")
    VirtualPowerPlant.add_battery(vpp, "battery_2")

    %{vpp_pid: vpp, battery_ids: ["battery_1", "battery_2"], max_power: 150}
  end

  test "aggregates batteries" do
    %{vpp_pid: vpp, battery_ids: battery_ids} = setup_vpp(:aggregate_batteries)
    batteries = VirtualPowerPlant.batteries(vpp)
    assert Enum.sort(batteries) == battery_ids
  end

  test "current_power returns the sum of all asset's current_power" do
    %{vpp_pid: vpp, battery_ids: batteries} = setup_vpp(:current_power)
    assert VirtualPowerPlant.current_power(vpp) == sum_of_power(batteries)
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
    %{vpp_pid: vpp, battery_ids: batteries, max_power: max_power} = setup_vpp(:respect_max_power)
    VirtualPowerPlant.absorb(vpp, 10 * max_power)
    assert sum_of_power(batteries) == -max_power

    VirtualPowerPlant.export(vpp, 10 * max_power)
    assert sum_of_power(batteries) == max_power
  end

  defp sum_of_power(battery_ids) do
    battery_ids
    |> Enum.map(&Battery.current_power/1)
    |> Enum.sum()
  end

  #defp sum_of_power(battery_ids) do
  #  sync_batteries = fn ->
  #    battery_ids
  #    |> Enum.map(fn id ->
  #      BatteryRegistry.whereis_name({Battery, id})
  #    end)
  #    |> Enum.each(&:sys.get_state/1)
  #  end
  #
  #  :sys.get_state(VirtualPowerPlant)
  #  sync_batteries.()
  #  :sys.get_state(VirtualPowerPlant)
  #  sync_batteries.()
  #
  #  battery_ids
  #  |> Enum.map(&Battery.current_power/1)
  #  |> Enum.sum()
  #end
end
