defmodule PrayerApp.Social.Follow do
  use Ecto.Schema
  import Ecto.Changeset

  schema "follows" do
    belongs_to :follower, PrayerApp.Accounts.User, foreign_key: :follower_id
    belongs_to :followed, PrayerApp.Accounts.User, foreign_key: :followed_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(follow, attrs) do
    changeset =
      follow
      |> cast(attrs, [:follower_id, :followed_id])
      |> validate_required([:follower_id, :followed_id])

    changeset =
      case {get_field(changeset, :follower_id), get_field(changeset, :followed_id)} do
        {id, id} when not is_nil(id) ->
          add_error(changeset, :followed_id, "no puedes seguirte a ti mismo")

        _ ->
          changeset
      end

    changeset
    |> unique_constraint(:follower_id, name: :follows_follower_id_followed_id_index)
    |> assoc_constraint(:follower)
    |> assoc_constraint(:followed)
  end
end
