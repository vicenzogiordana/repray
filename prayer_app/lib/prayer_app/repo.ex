defmodule PrayerApp.Repo do
  use Ecto.Repo,
    otp_app: :prayer_app,
    adapter: Ecto.Adapters.Postgres
end
