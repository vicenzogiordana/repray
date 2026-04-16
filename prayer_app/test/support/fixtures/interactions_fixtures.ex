defmodule PrayerApp.InteractionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PrayerApp.Interactions` context.
  """

  @doc """
  Generate a pray.
  """
  def pray_fixture(attrs \\ %{}) do
    {:ok, pray} =
      attrs
      |> Enum.into(%{

      })
      |> PrayerApp.Interactions.create_pray()

    pray
  end

  @doc """
  Generate a re_pray.
  """
  def re_pray_fixture(attrs \\ %{}) do
    {:ok, re_pray} =
      attrs
      |> Enum.into(%{
        comment: "some comment"
      })
      |> PrayerApp.Interactions.create_re_pray()

    re_pray
  end
end
