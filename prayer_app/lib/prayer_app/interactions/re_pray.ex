defmodule PrayerApp.Interactions.RePray do
  use Ecto.Schema
  import Ecto.Changeset

  schema "re_prays" do
    field :comment, :string

    belongs_to :user, PrayerApp.Accounts.User
    belongs_to :prayer_request, PrayerApp.Prayers.PrayerRequest

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(re_pray, attrs) do
    re_pray
    |> cast(attrs, [:comment, :user_id, :prayer_request_id])
    |> validate_required([:comment, :user_id, :prayer_request_id])
    |> validate_change(:comment, &validate_comment_word_count/2)
    |> unique_constraint(:user_id, name: :re_prays_user_id_prayer_request_id_index)
    |> assoc_constraint(:user)
    |> assoc_constraint(:prayer_request)
  end

  defp validate_comment_word_count(_field, comment) when is_binary(comment) do
    words =
      comment
      |> String.trim()
      |> String.split(~r/\s+/, trim: true)
      |> length()

    if words > 50 do
      [comment: "debe tener como maximo 50 palabras"]
    else
      []
    end
  end

  defp validate_comment_word_count(_field, _), do: []
end
