defmodule PrayerApp.PrayersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PrayerApp.Prayers` context.
  """

  @doc """
  Generate a prayer_request.
  """
  def prayer_request_fixture(attrs \\ %{}) do
    {:ok, prayer_request} =
      attrs
      |> Enum.into(%{
        content: "some content",
        is_anonymous: true,
        prays_count: 42,
        status: "some status"
      })
      |> PrayerApp.Prayers.create_prayer_request()

    prayer_request
  end

  @doc """
  Generate a update.
  """
  def update_fixture(attrs \\ %{}) do
    {:ok, update} =
      attrs
      |> Enum.into(%{
        content: "some content"
      })
      |> PrayerApp.Prayers.create_update()

    update
  end

  @doc """
  Generate a testimony.
  """
  def testimony_fixture(attrs \\ %{}) do
    {:ok, testimony} =
      attrs
      |> Enum.into(%{
        content: "some content"
      })
      |> PrayerApp.Prayers.create_testimony()

    testimony
  end
end
