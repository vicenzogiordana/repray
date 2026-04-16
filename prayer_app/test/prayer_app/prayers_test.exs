defmodule PrayerApp.PrayersTest do
  use PrayerApp.DataCase

  alias PrayerApp.Prayers

  describe "prayer_requests" do
    alias PrayerApp.Prayers.PrayerRequest

    import PrayerApp.PrayersFixtures

    @invalid_attrs %{status: nil, content: nil, is_anonymous: nil, prays_count: nil}

    test "list_prayer_requests/0 returns all prayer_requests" do
      prayer_request = prayer_request_fixture()
      assert Prayers.list_prayer_requests() == [prayer_request]
    end

    test "get_prayer_request!/1 returns the prayer_request with given id" do
      prayer_request = prayer_request_fixture()
      assert Prayers.get_prayer_request!(prayer_request.id) == prayer_request
    end

    test "create_prayer_request/1 with valid data creates a prayer_request" do
      valid_attrs = %{status: "some status", content: "some content", is_anonymous: true, prays_count: 42}

      assert {:ok, %PrayerRequest{} = prayer_request} = Prayers.create_prayer_request(valid_attrs)
      assert prayer_request.status == "some status"
      assert prayer_request.content == "some content"
      assert prayer_request.is_anonymous == true
      assert prayer_request.prays_count == 42
    end

    test "create_prayer_request/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Prayers.create_prayer_request(@invalid_attrs)
    end

    test "update_prayer_request/2 with valid data updates the prayer_request" do
      prayer_request = prayer_request_fixture()
      update_attrs = %{status: "some updated status", content: "some updated content", is_anonymous: false, prays_count: 43}

      assert {:ok, %PrayerRequest{} = prayer_request} = Prayers.update_prayer_request(prayer_request, update_attrs)
      assert prayer_request.status == "some updated status"
      assert prayer_request.content == "some updated content"
      assert prayer_request.is_anonymous == false
      assert prayer_request.prays_count == 43
    end

    test "update_prayer_request/2 with invalid data returns error changeset" do
      prayer_request = prayer_request_fixture()
      assert {:error, %Ecto.Changeset{}} = Prayers.update_prayer_request(prayer_request, @invalid_attrs)
      assert prayer_request == Prayers.get_prayer_request!(prayer_request.id)
    end

    test "delete_prayer_request/1 deletes the prayer_request" do
      prayer_request = prayer_request_fixture()
      assert {:ok, %PrayerRequest{}} = Prayers.delete_prayer_request(prayer_request)
      assert_raise Ecto.NoResultsError, fn -> Prayers.get_prayer_request!(prayer_request.id) end
    end

    test "change_prayer_request/1 returns a prayer_request changeset" do
      prayer_request = prayer_request_fixture()
      assert %Ecto.Changeset{} = Prayers.change_prayer_request(prayer_request)
    end
  end

  describe "updates" do
    alias PrayerApp.Prayers.Update

    import PrayerApp.PrayersFixtures

    @invalid_attrs %{content: nil}

    test "list_updates/0 returns all updates" do
      update = update_fixture()
      assert Prayers.list_updates() == [update]
    end

    test "get_update!/1 returns the update with given id" do
      update = update_fixture()
      assert Prayers.get_update!(update.id) == update
    end

    test "create_update/1 with valid data creates a update" do
      valid_attrs = %{content: "some content"}

      assert {:ok, %Update{} = update} = Prayers.create_update(valid_attrs)
      assert update.content == "some content"
    end

    test "create_update/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Prayers.create_update(@invalid_attrs)
    end

    test "update_update/2 with valid data updates the update" do
      update = update_fixture()
      update_attrs = %{content: "some updated content"}

      assert {:ok, %Update{} = update} = Prayers.update_update(update, update_attrs)
      assert update.content == "some updated content"
    end

    test "update_update/2 with invalid data returns error changeset" do
      update = update_fixture()
      assert {:error, %Ecto.Changeset{}} = Prayers.update_update(update, @invalid_attrs)
      assert update == Prayers.get_update!(update.id)
    end

    test "delete_update/1 deletes the update" do
      update = update_fixture()
      assert {:ok, %Update{}} = Prayers.delete_update(update)
      assert_raise Ecto.NoResultsError, fn -> Prayers.get_update!(update.id) end
    end

    test "change_update/1 returns a update changeset" do
      update = update_fixture()
      assert %Ecto.Changeset{} = Prayers.change_update(update)
    end
  end

  describe "testimonies" do
    alias PrayerApp.Prayers.Testimony

    import PrayerApp.PrayersFixtures

    @invalid_attrs %{content: nil}

    test "list_testimonies/0 returns all testimonies" do
      testimony = testimony_fixture()
      assert Prayers.list_testimonies() == [testimony]
    end

    test "get_testimony!/1 returns the testimony with given id" do
      testimony = testimony_fixture()
      assert Prayers.get_testimony!(testimony.id) == testimony
    end

    test "create_testimony/1 with valid data creates a testimony" do
      valid_attrs = %{content: "some content"}

      assert {:ok, %Testimony{} = testimony} = Prayers.create_testimony(valid_attrs)
      assert testimony.content == "some content"
    end

    test "create_testimony/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Prayers.create_testimony(@invalid_attrs)
    end

    test "update_testimony/2 with valid data updates the testimony" do
      testimony = testimony_fixture()
      update_attrs = %{content: "some updated content"}

      assert {:ok, %Testimony{} = testimony} = Prayers.update_testimony(testimony, update_attrs)
      assert testimony.content == "some updated content"
    end

    test "update_testimony/2 with invalid data returns error changeset" do
      testimony = testimony_fixture()
      assert {:error, %Ecto.Changeset{}} = Prayers.update_testimony(testimony, @invalid_attrs)
      assert testimony == Prayers.get_testimony!(testimony.id)
    end

    test "delete_testimony/1 deletes the testimony" do
      testimony = testimony_fixture()
      assert {:ok, %Testimony{}} = Prayers.delete_testimony(testimony)
      assert_raise Ecto.NoResultsError, fn -> Prayers.get_testimony!(testimony.id) end
    end

    test "change_testimony/1 returns a testimony changeset" do
      testimony = testimony_fixture()
      assert %Ecto.Changeset{} = Prayers.change_testimony(testimony)
    end
  end
end
