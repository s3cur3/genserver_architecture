defmodule VirtualPowerPlantTest do
  use ExUnit.Case

  setup do
    :global.register_name(:vpp, self())
    on_exit(fn -> :global.unregister_name(:vpp) end)
    :ok
  end

  test "aggregates batteries" do
    {:ok, _pid1} = Battery.create("battery_1", 100)
    {:ok, _pid2} = Battery.create("battery_2", 100)

    {:ok, task_pid} =
      Task.start(fn ->
        VirtualPowerPlant.add_battery({:global, :vpp}, "battery_1")
      end)

    assert_receive {:"$gen_call", {^task_pid, _}, {:add_battery, "battery_1"}}, 500
  end

  test "adds batteries" do
    {:ok, _pid1} = Battery.create("battery_1", 100)
    {:ok, _pid2} = Battery.create("battery_2", 100)

    {:ok, task_pid} =
      Task.start(fn ->
        VirtualPowerPlant.add_battery({:global, :vpp}, "battery_1")
      end)

    assert_receive {:"$gen_call", {^task_pid, _}, {:add_battery, "battery_1"}}, 500
  end
end
