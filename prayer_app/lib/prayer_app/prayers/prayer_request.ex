defmodule PrayerApp.Prayers.PrayerRequest do
  use Ecto.Schema
  import Ecto.Changeset

  schema "prayer_requests" do
    field :content, :string
    field :is_anonymous, :boolean, default: false
    field :status, :string, default: "active"
    field :prays_count, :integer, default: 0

    belongs_to :user, PrayerApp.Accounts.User
    has_many :updates, PrayerApp.Prayers.Update
    has_one :testimony, PrayerApp.Prayers.Testimony
    has_many :prays, PrayerApp.Interactions.Pray
    has_many :re_prays, PrayerApp.Interactions.RePray

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(prayer_request, attrs) do
    prayer_request
    |> cast(attrs, [:content, :is_anonymous, :status, :prays_count, :user_id])
    |> validate_required([:content, :status, :user_id])
    |> assoc_constraint(:user)
  end
end
