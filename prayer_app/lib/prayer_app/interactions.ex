defmodule PrayerApp.Interactions do
  @moduledoc """
  The Interactions context.
  """

  import Ecto.Query, warn: false
  alias PrayerApp.Repo

  alias PrayerApp.Interactions.Pray

  @doc """
  Returns the list of prays.

  ## Examples

      iex> list_prays()
      [%Pray{}, ...]

  """
  def list_prays do
    Repo.all(Pray)
  end

  @doc """
  Gets a single pray.

  Raises `Ecto.NoResultsError` if the Pray does not exist.

  ## Examples

      iex> get_pray!(123)
      %Pray{}

      iex> get_pray!(456)
      ** (Ecto.NoResultsError)

  """
  def get_pray!(id), do: Repo.get!(Pray, id)

  @doc """
  Creates a pray.

  ## Examples

      iex> create_pray(%{field: value})
      {:ok, %Pray{}}

      iex> create_pray(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_pray(attrs) do
    %Pray{}
    |> Pray.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a pray.

  ## Examples

      iex> update_pray(pray, %{field: new_value})
      {:ok, %Pray{}}

      iex> update_pray(pray, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_pray(%Pray{} = pray, attrs) do
    pray
    |> Pray.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a pray.

  ## Examples

      iex> delete_pray(pray)
      {:ok, %Pray{}}

      iex> delete_pray(pray)
      {:error, %Ecto.Changeset{}}

  """
  def delete_pray(%Pray{} = pray) do
    Repo.delete(pray)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking pray changes.

  ## Examples

      iex> change_pray(pray)
      %Ecto.Changeset{data: %Pray{}}

  """
  def change_pray(%Pray{} = pray, attrs \\ %{}) do
    Pray.changeset(pray, attrs)
  end

  alias PrayerApp.Interactions.RePray

  @doc """
  Returns the list of re_prays.

  ## Examples

      iex> list_re_prays()
      [%RePray{}, ...]

  """
  def list_re_prays do
    Repo.all(RePray)
  end

  def list_user_re_prays(user_id) do
    Repo.all(
      from rp in RePray,
        where: rp.user_id == ^user_id,
        order_by: [desc: rp.inserted_at],
        preload: [prayer_request: [:user, :re_prays, :updates, :testimony]]
    )
  end

  def list_user_re_pray_ids(user_id) do
    Repo.all(
      from rp in RePray,
        where: rp.user_id == ^user_id,
        select: rp.prayer_request_id
    )
  end

  def get_user_re_pray(user_id, prayer_request_id) do
    Repo.get_by(RePray, user_id: user_id, prayer_request_id: prayer_request_id)
  end

  def toggle_re_pray(user_id, prayer_request_id, comment \\ "Re-pray") do
    case get_user_re_pray(user_id, prayer_request_id) do
      %RePray{} = re_pray ->
        case delete_re_pray(re_pray) do
          {:ok, _} -> {:removed, re_pray}
          {:error, changeset} -> {:error, changeset}
        end

      nil ->
        case create_re_pray(%{
               user_id: user_id,
               prayer_request_id: prayer_request_id,
               comment: comment
             }) do
          {:ok, re_pray} -> {:added, re_pray}
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  @doc """
  Gets a single re_pray.

  Raises `Ecto.NoResultsError` if the Re pray does not exist.

  ## Examples

      iex> get_re_pray!(123)
      %RePray{}

      iex> get_re_pray!(456)
      ** (Ecto.NoResultsError)

  """
  def get_re_pray!(id), do: Repo.get!(RePray, id)

  @doc """
  Creates a re_pray.

  ## Examples

      iex> create_re_pray(%{field: value})
      {:ok, %RePray{}}

      iex> create_re_pray(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_re_pray(attrs) do
    %RePray{}
    |> RePray.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a re_pray.

  ## Examples

      iex> update_re_pray(re_pray, %{field: new_value})
      {:ok, %RePray{}}

      iex> update_re_pray(re_pray, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_re_pray(%RePray{} = re_pray, attrs) do
    re_pray
    |> RePray.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a re_pray.

  ## Examples

      iex> delete_re_pray(re_pray)
      {:ok, %RePray{}}

      iex> delete_re_pray(re_pray)
      {:error, %Ecto.Changeset{}}

  """
  def delete_re_pray(%RePray{} = re_pray) do
    Repo.delete(re_pray)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking re_pray changes.

  ## Examples

      iex> change_re_pray(re_pray)
      %Ecto.Changeset{data: %RePray{}}

  """
  def change_re_pray(%RePray{} = re_pray, attrs \\ %{}) do
    RePray.changeset(re_pray, attrs)
  end
end
