defmodule BatteryTest do
  use ExUnit.Case

  test "prevents current power from exceeding max power" do
    battery = Battery.new(id: "battery_1", max_power_watts: 100, current_power_watts: 101)
    assert battery.current_power_watts == 100

    updated_positive = Battery.update_current_power(battery, 1_000)
    assert updated_positive.current_power_watts == 100

    updated_negative = Battery.update_current_power(battery, -1_000)
    assert updated_negative.current_power_watts == -100
  end
end
