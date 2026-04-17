defmodule PrayerApp.Prayers do
  @moduledoc """
  The Prayers context.
  """

  import Ecto.Query, warn: false
  alias PrayerApp.Repo

  alias PrayerApp.Prayers.PrayerRequest

  @doc """
  Returns the list of prayer_requests.

  ## Examples

      iex> list_prayer_requests()
      [%PrayerRequest{}, ...]

  """
  def list_prayer_requests do
    Repo.all(
      from p in PrayerRequest,
        order_by: [desc: p.inserted_at],
        preload: [:user, :re_prays, :updates, :testimony]
    )
  end

  @doc """
  Gets a single prayer_request.

  Raises `Ecto.NoResultsError` if the Prayer request does not exist.

  ## Examples

      iex> get_prayer_request!(123)
      %PrayerRequest{}

      iex> get_prayer_request!(456)
      ** (Ecto.NoResultsError)

  """
  def get_prayer_request!(id), do: Repo.get!(PrayerRequest, id)

  @doc """
  Creates a prayer_request.

  ## Examples

      iex> create_prayer_request(%{field: value})
      {:ok, %PrayerRequest{}}

      iex> create_prayer_request(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_prayer_request(attrs \\ %{}) do
    %PrayerRequest{}
    |> PrayerRequest.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a prayer_request.

  ## Examples

      iex> update_prayer_request(prayer_request, %{field: new_value})
      {:ok, %PrayerRequest{}}

      iex> update_prayer_request(prayer_request, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_prayer_request(%PrayerRequest{} = prayer_request, attrs) do
    prayer_request
    |> PrayerRequest.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a prayer_request.

  ## Examples

      iex> delete_prayer_request(prayer_request)
      {:ok, %PrayerRequest{}}

      iex> delete_prayer_request(prayer_request)
      {:error, %Ecto.Changeset{}}

  """
  def delete_prayer_request(%PrayerRequest{} = prayer_request) do
    Repo.delete(prayer_request)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking prayer_request changes.

  ## Examples

      iex> change_prayer_request(prayer_request)
      %Ecto.Changeset{data: %PrayerRequest{}}

  """
  def change_prayer_request(%PrayerRequest{} = prayer_request, attrs \\ %{}) do
    PrayerRequest.changeset(prayer_request, attrs)
  end

  alias PrayerApp.Prayers.Update

  @doc """
  Returns the list of updates.

  ## Examples

      iex> list_updates()
      [%Update{}, ...]

  """
  def list_updates do
    Repo.all(Update)
  end

  @doc """
  Gets a single update.

  Raises `Ecto.NoResultsError` if the Update does not exist.

  ## Examples

      iex> get_update!(123)
      %Update{}

      iex> get_update!(456)
      ** (Ecto.NoResultsError)

  """
  def get_update!(id), do: Repo.get!(Update, id)

  @doc """
  Creates a update.

  ## Examples

      iex> create_update(%{field: value})
      {:ok, %Update{}}

      iex> create_update(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_update(attrs) do
    %Update{}
    |> Update.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a update.

  ## Examples

      iex> update_update(update, %{field: new_value})
      {:ok, %Update{}}

      iex> update_update(update, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_update(%Update{} = update, attrs) do
    update
    |> Update.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a update.

  ## Examples

      iex> delete_update(update)
      {:ok, %Update{}}

      iex> delete_update(update)
      {:error, %Ecto.Changeset{}}

  """
  def delete_update(%Update{} = update) do
    Repo.delete(update)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking update changes.

  ## Examples

      iex> change_update(update)
      %Ecto.Changeset{data: %Update{}}

  """
  def change_update(%Update{} = update, attrs \\ %{}) do
    Update.changeset(update, attrs)
  end

  alias PrayerApp.Prayers.Testimony

  @doc """
  Returns the list of testimonies.

  ## Examples

      iex> list_testimonies()
      [%Testimony{}, ...]

  """
  def list_testimonies do
    Repo.all(Testimony)
  end

  @doc """
  Gets a single testimony.

  Raises `Ecto.NoResultsError` if the Testimony does not exist.

  ## Examples

      iex> get_testimony!(123)
      %Testimony{}

      iex> get_testimony!(456)
      ** (Ecto.NoResultsError)

  """
  def get_testimony!(id), do: Repo.get!(Testimony, id)

  @doc """
  Creates a testimony.

  ## Examples

      iex> create_testimony(%{field: value})
      {:ok, %Testimony{}}

      iex> create_testimony(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_testimony(attrs) do
    %Testimony{}
    |> Testimony.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a testimony.

  ## Examples

      iex> update_testimony(testimony, %{field: new_value})
      {:ok, %Testimony{}}

      iex> update_testimony(testimony, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_testimony(%Testimony{} = testimony, attrs) do
    testimony
    |> Testimony.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a testimony.

  ## Examples

      iex> delete_testimony(testimony)
      {:ok, %Testimony{}}

      iex> delete_testimony(testimony)
      {:error, %Ecto.Changeset{}}

  """
  def delete_testimony(%Testimony{} = testimony) do
    Repo.delete(testimony)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking testimony changes.

  ## Examples

      iex> change_testimony(testimony)
      %Ecto.Changeset{data: %Testimony{}}

  """
  def change_testimony(%Testimony{} = testimony, attrs \\ %{}) do
    Testimony.changeset(testimony, attrs)
  end

  def list_following_feed(current_user) do
    followed_ids_query =
      from f in PrayerApp.Social.Follow,
        where: f.follower_id == ^current_user.id,
        select: f.followed_id

    reprayed_request_ids_query =
      from rp in PrayerApp.Interactions.RePray,
        where: rp.user_id in subquery(followed_ids_query),
        select: rp.prayer_request_id

    feed_query =
      from pr in PrayerApp.Prayers.PrayerRequest,
        where:
          pr.user_id in subquery(followed_ids_query) or
            pr.id in subquery(reprayed_request_ids_query),
        distinct: true,
        order_by: [desc: pr.inserted_at],
        preload: [:user, :updates, :testimony]

    requests = PrayerApp.Repo.all(feed_query)

    PrayerApp.Repo.preload(
      requests,
      [
        :updates,
        :testimony,
        re_prays:
          from(rp in PrayerApp.Interactions.RePray,
            where: rp.user_id in subquery(followed_ids_query),
            order_by: [desc: rp.inserted_at],
            preload: [:user])
      ]
    )
  end
end
