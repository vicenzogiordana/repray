defmodule PrayerApp.Repo.Migrations.CreatePrayerRequests do
  use Ecto.Migration

  def change do
    create table(:prayer_requests) do
      add :content, :text, null: false
      add :is_anonymous, :boolean, default: false, null: false
      add :status, :string, default: "active", null: false
      add :prays_count, :integer, default: 0, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:prayer_requests, [:user_id])
    create index(:prayer_requests, [:status])
    create index(:prayer_requests, [:inserted_at])
  end
end
