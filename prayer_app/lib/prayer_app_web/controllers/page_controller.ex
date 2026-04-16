defmodule PrayerAppWeb.PageController do
  use PrayerAppWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
