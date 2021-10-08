defmodule BatteryTest do
  use ExUnit.Case

  test "creates & registers a battery for later lookup" do
    {:ok, pid} = Battery.create("battery_1", 1_000, 100)
    assert is_pid(pid)
    assert Battery.current_power("battery_1") == 100
  end

  test "prevents current power from exceeding max power" do
    {:ok, _pid} = Battery.create("battery_1", 100)

    Battery.update_current_power("battery_1", 1_000)
    assert Battery.current_power("battery_1") == 100

    Battery.update_current_power("battery_1", -1_000)
    assert Battery.current_power("battery_1") == -100
  end
end
