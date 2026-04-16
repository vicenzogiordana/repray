defmodule PrayerApp.Interactions.Pray do
  use Ecto.Schema
  import Ecto.Changeset

  schema "prays" do
    belongs_to :user, PrayerApp.Accounts.User
    belongs_to :prayer_request, PrayerApp.Prayers.PrayerRequest

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(pray, attrs) do
    pray
    |> cast(attrs, [:user_id, :prayer_request_id])
    |> validate_required([:user_id, :prayer_request_id])
    |> unique_constraint(:user_id, name: :prays_user_id_prayer_request_id_index)
    |> assoc_constraint(:user)
    |> assoc_constraint(:prayer_request)
  end
end
