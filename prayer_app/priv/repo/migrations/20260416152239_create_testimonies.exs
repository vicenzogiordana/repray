defmodule PrayerApp.Repo.Migrations.CreateTestimonies do
  use Ecto.Migration

  def change do
    create table(:testimonies) do
      add :content, :text, null: false
      add :prayer_request_id, references(:prayer_requests, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:testimonies, [:prayer_request_id])
  end
end
