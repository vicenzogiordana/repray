defmodule PrayerApp.SocialFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PrayerApp.Social` context.
  """

  @doc """
  Generate a follow.
  """
  def follow_fixture(attrs \\ %{}) do
    {:ok, follow} =
      attrs
      |> Enum.into(%{

      })
      |> PrayerApp.Social.create_follow()

    follow
  end
end
