defmodule PrayerApp.Repo.Migrations.CreateRePrays do
  use Ecto.Migration

  def change do
    create table(:re_prays) do
      add :comment, :text, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :prayer_request_id, references(:prayer_requests, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:re_prays, [:user_id])
    create index(:re_prays, [:prayer_request_id])
    create unique_index(:re_prays, [:user_id, :prayer_request_id])
  end
end
