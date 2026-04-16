defmodule PrayerApp.Repo.Migrations.CreatePrays do
  use Ecto.Migration

  def change do
    create table(:prays) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :prayer_request_id, references(:prayer_requests, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:prays, [:user_id])
    create index(:prays, [:prayer_request_id])
    create unique_index(:prays, [:user_id, :prayer_request_id])
  end
end
