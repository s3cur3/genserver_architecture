defmodule VirtualPowerPlantTest do
  use ExUnit.Case

  setup do
    Application.put_env(:energy_application, :vpp_name, random_atom())
    VirtualPowerPlant.start_link([])
    :ok
  end

  defp random_atom do
    random_string = for _ <- 1..10, into: "", do: <<Enum.random('0123456789abcdef')>>
    String.to_atom(random_string)
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
    assert sum_of_power(["battery_1", "battery_2"]) == -150

    VirtualPowerPlant.export(1_000)
    assert sum_of_power(["battery_1", "battery_2"]) == 150
  end

  defp sum_of_power(battery_ids) do
    battery_ids
    |> Enum.map(&Battery.current_power/1)
    |> Enum.sum()
  end

  #defp sum_of_power(battery_ids) do
  #  :sys.get_state(VirtualPowerPlant)
  #
  #  battery_ids
  #  |> Enum.map(fn id ->
  #    BatteryRegistry.whereis_name({Battery, id})
  #  end)
  #  |> Enum.each(&:sys.get_state/1)
  #
  #  :sys.get_state(VirtualPowerPlant)
  #
  #  battery_ids
  #  |> Enum.map(&Battery.current_power/1)
  #  |> Enum.sum()
  #end
end
