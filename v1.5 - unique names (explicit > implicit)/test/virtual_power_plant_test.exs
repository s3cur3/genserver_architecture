defmodule VirtualPowerPlantTest do
  use ExUnit.Case

  setup do
    Application.put_env(:energy_application, :vpp_name, random_atom())
    VirtualPowerPlant.start_link([])

    {:ok, _pid1} = Battery.create("battery_1", 100, 80)
    {:ok, _pid2} = Battery.create("battery_2", 50, 30)

    VirtualPowerPlant.add_battery("battery_1")
    VirtualPowerPlant.add_battery("battery_2")

    %{battery_ids: ["battery_1", "battery_2"], max_power: 150}
  end

  defp random_atom do
    random_string = for _ <- 1..10, into: "", do: <<Enum.random('0123456789abcdef')>>
    String.to_atom(random_string)
  end

  test "aggregates batteries", %{battery_ids: battery_ids} do
    batteries = VirtualPowerPlant.batteries()
    assert Enum.sort(batteries) == battery_ids
  end

  test "current_power returns the sum of all asset's current_power", %{battery_ids: batteries} do
    assert VirtualPowerPlant.current_power() == sum_of_power(batteries)
  end

  test "exports power to the grid to meet a demand" do
    VirtualPowerPlant.export(5)
    assert VirtualPowerPlant.current_power() == 5
  end

  test "absorbs power to the grid to meet a demand" do
    VirtualPowerPlant.absorb(5)
    assert VirtualPowerPlant.current_power() == -5
  end

  defp sum_of_power(battery_ids) do
    battery_ids
    |> Enum.map(&Battery.current_power/1)
    |> Enum.sum()
  end
end
