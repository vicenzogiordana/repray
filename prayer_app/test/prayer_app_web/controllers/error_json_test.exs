defmodule PrayerAppWeb.ErrorJSONTest do
  use PrayerAppWeb.ConnCase, async: true

  test "renders 404" do
    assert PrayerAppWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert PrayerAppWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
