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
end
