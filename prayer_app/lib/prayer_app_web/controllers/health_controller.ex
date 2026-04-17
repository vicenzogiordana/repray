defmodule PrayerAppWeb.HealthController do
  use PrayerAppWeb, :controller

  def index(conn, _params) do
    text(conn, "ok")
  end
end
