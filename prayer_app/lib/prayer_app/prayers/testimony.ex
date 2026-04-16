defmodule PrayerApp.Prayers.Testimony do
  use Ecto.Schema
  import Ecto.Changeset

  schema "testimonies" do
    field :content, :string
    belongs_to :prayer_request, PrayerApp.Prayers.PrayerRequest

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(testimony, attrs) do
    testimony
    |> cast(attrs, [:content, :prayer_request_id])
    |> validate_required([:content, :prayer_request_id])
    |> assoc_constraint(:prayer_request)
    |> unique_constraint(:prayer_request_id)
  end
end
