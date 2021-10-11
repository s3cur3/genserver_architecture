defmodule TestUtils do
  @moduledoc false

  # Given two collections of the same batteries, returns how many have changed.
  def count_changed(initial_batteries, updated_batteries) do
    sort_by_id = &Enum.sort_by(&1, fn %Battery{id: id} -> id end)

    initial = sort_by_id.(initial_batteries)
    updated = sort_by_id.(updated_batteries)

    Enum.count(
      Enum.zip(initial, updated),
      fn {initial, updated} -> initial != updated end
    )
  end
end
