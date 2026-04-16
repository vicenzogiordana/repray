defmodule PrayerApp.Repo.Migrations.CreateUpdates do
  use Ecto.Migration

  def change do
    create table(:updates) do
      add :content, :text, null: false
      add :prayer_request_id, references(:prayer_requests, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:updates, [:prayer_request_id])
  end
end
