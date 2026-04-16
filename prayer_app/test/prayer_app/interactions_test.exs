defmodule PrayerApp.InteractionsTest do
  use PrayerApp.DataCase

  alias PrayerApp.Interactions

  describe "prays" do
    alias PrayerApp.Interactions.Pray

    import PrayerApp.InteractionsFixtures

    @invalid_attrs %{}

    test "list_prays/0 returns all prays" do
      pray = pray_fixture()
      assert Interactions.list_prays() == [pray]
    end

    test "get_pray!/1 returns the pray with given id" do
      pray = pray_fixture()
      assert Interactions.get_pray!(pray.id) == pray
    end

    test "create_pray/1 with valid data creates a pray" do
      valid_attrs = %{}

      assert {:ok, %Pray{} = pray} = Interactions.create_pray(valid_attrs)
    end

    test "create_pray/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Interactions.create_pray(@invalid_attrs)
    end

    test "update_pray/2 with valid data updates the pray" do
      pray = pray_fixture()
      update_attrs = %{}

      assert {:ok, %Pray{} = pray} = Interactions.update_pray(pray, update_attrs)
    end

    test "update_pray/2 with invalid data returns error changeset" do
      pray = pray_fixture()
      assert {:error, %Ecto.Changeset{}} = Interactions.update_pray(pray, @invalid_attrs)
      assert pray == Interactions.get_pray!(pray.id)
    end

    test "delete_pray/1 deletes the pray" do
      pray = pray_fixture()
      assert {:ok, %Pray{}} = Interactions.delete_pray(pray)
      assert_raise Ecto.NoResultsError, fn -> Interactions.get_pray!(pray.id) end
    end

    test "change_pray/1 returns a pray changeset" do
      pray = pray_fixture()
      assert %Ecto.Changeset{} = Interactions.change_pray(pray)
    end
  end

  describe "re_prays" do
    alias PrayerApp.Interactions.RePray

    import PrayerApp.InteractionsFixtures

    @invalid_attrs %{comment: nil}

    test "list_re_prays/0 returns all re_prays" do
      re_pray = re_pray_fixture()
      assert Interactions.list_re_prays() == [re_pray]
    end

    test "get_re_pray!/1 returns the re_pray with given id" do
      re_pray = re_pray_fixture()
      assert Interactions.get_re_pray!(re_pray.id) == re_pray
    end

    test "create_re_pray/1 with valid data creates a re_pray" do
      valid_attrs = %{comment: "some comment"}

      assert {:ok, %RePray{} = re_pray} = Interactions.create_re_pray(valid_attrs)
      assert re_pray.comment == "some comment"
    end

    test "create_re_pray/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Interactions.create_re_pray(@invalid_attrs)
    end

    test "update_re_pray/2 with valid data updates the re_pray" do
      re_pray = re_pray_fixture()
      update_attrs = %{comment: "some updated comment"}

      assert {:ok, %RePray{} = re_pray} = Interactions.update_re_pray(re_pray, update_attrs)
      assert re_pray.comment == "some updated comment"
    end

    test "update_re_pray/2 with invalid data returns error changeset" do
      re_pray = re_pray_fixture()
      assert {:error, %Ecto.Changeset{}} = Interactions.update_re_pray(re_pray, @invalid_attrs)
      assert re_pray == Interactions.get_re_pray!(re_pray.id)
    end

    test "delete_re_pray/1 deletes the re_pray" do
      re_pray = re_pray_fixture()
      assert {:ok, %RePray{}} = Interactions.delete_re_pray(re_pray)
      assert_raise Ecto.NoResultsError, fn -> Interactions.get_re_pray!(re_pray.id) end
    end

    test "change_re_pray/1 returns a re_pray changeset" do
      re_pray = re_pray_fixture()
      assert %Ecto.Changeset{} = Interactions.change_re_pray(re_pray)
    end
  end
end
