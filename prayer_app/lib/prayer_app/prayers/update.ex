defmodule PrayerApp.Prayers.Update do
  use Ecto.Schema
  import Ecto.Changeset

  schema "updates" do
    field :content, :string
    belongs_to :prayer_request, PrayerApp.Prayers.PrayerRequest

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(update, attrs) do
    update
    |> cast(attrs, [:content, :prayer_request_id])
    |> validate_required([:content, :prayer_request_id])
    |> assoc_constraint(:prayer_request)
  end
end
