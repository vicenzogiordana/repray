defmodule PrayerAppWeb.FeedLive.Index do
  use PrayerAppWeb, :live_view

  alias PrayerApp.Prayers
  alias PrayerApp.Prayers.PrayerRequest

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_scope.user
    requests = Prayers.list_prayer_requests()
    form =
      %PrayerRequest{}
      |> Prayers.change_prayer_request()
      |> to_form(as: :prayer_request)

    {:ok,
     socket
     |> assign(:form, form)
     |> assign(:requests, requests)
      |> assign(:current_user, current_user)
     |> assign(:active_tab, :general)}
  end

  @impl true
  def handle_event("change_tab", %{"tab" => "general"}, socket) do
    {:noreply,
     socket
     |> assign(:requests, Prayers.list_prayer_requests())
     |> assign(:active_tab, :general)}
  end

  def handle_event("change_tab", %{"tab" => "following"}, socket) do
    current_user = socket.assigns.current_user

    {:noreply,
     socket
     |> assign(:requests, Prayers.list_following_feed(current_user))
     |> assign(:active_tab, :following)}
  end

  def handle_event("save_prayer", %{"prayer_request" => params}, socket) do
    current_user = socket.assigns.current_user

    attrs =
      params
      |> Map.put("user_id", current_user.id)
      |> Map.put("status", "active")

    case Prayers.create_prayer_request(attrs) do
      {:ok, prayer_request} ->
        prayer_request =
          PrayerApp.Repo.preload(prayer_request, [:user, :re_prays])

        form =
          %PrayerRequest{}
          |> Prayers.change_prayer_request()
          |> to_form(as: :prayer_request)

        {:noreply,
         socket
         |> assign(:form, form)
         |> update(:requests, fn requests -> [prayer_request | requests] end)}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :prayer_request))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto py-8 px-4 sm:px-0">
      <div class="tabs tabs-boxed mb-6">
        <button
          type="button"
          class={["tab", @active_tab == :general && "tab-active"]}
          phx-click="change_tab"
          phx-value-tab="general"
        >
          Muro General
        </button>

        <button
          type="button"
          class={["tab", @active_tab == :following && "tab-active"]}
          phx-click="change_tab"
          phx-value-tab="following"
        >
          Siguiendo
        </button>
      </div>

      <div class="card bg-base-100 shadow-sm mb-8">
        <div class="card-body">
          <.form for={@form} phx-submit="save_prayer">
            <textarea
              name={@form[:content].name}
              id={@form[:content].id}
              class="textarea textarea-bordered w-full text-lg"
              rows="4"
              placeholder="Comparte tu pedido de oracion..."
              required
            ><%= Phoenix.HTML.Form.normalize_value("textarea", @form[:content].value) %></textarea>

            <div class="mt-4 flex items-center justify-between gap-4">
              <label class="label cursor-pointer gap-2">
                <input
                  type="hidden"
                  name={@form[:is_anonymous].name}
                  value="false"
                />
                <input
                  type="checkbox"
                  name={@form[:is_anonymous].name}
                  value="true"
                  class="checkbox checkbox-sm"
                />
                <span class="label-text">Postear como anonimo</span>
              </label>

              <button type="submit" class="btn btn-neutral btn-sm rounded-full">
                Pedir Oracion
              </button>
            </div>
          </.form>
        </div>
      </div>

      <div :for={request <- @requests}>
        <div
          :if={@active_tab == :following and not Enum.empty?(request.re_prays || [])}
          class="text-xs text-base-content/50 ml-4 mt-2"
        >
          Alguien hizo re-pray
        </div>

        <div class="card bg-base-100 shadow-sm mb-4 border border-base-200">
          <div class="card-body">
            <div class="flex items-center gap-3 mb-2">
              <div class="avatar placeholder">
                <div class="bg-base-300 text-base-content rounded-full w-10">
                  <span>
                    {avatar_initial(request)}
                  </span>
                </div>
              </div>

              <p class="font-semibold">
                {display_name(request)}
              </p>
            </div>

            <p class="text-base leading-relaxed">{request.content}</p>

            <div class="card-actions justify-start mt-4">
              <button type="button" class="btn btn-ghost btn-sm rounded-full">
                🙏 Me uno a orar
              </button>
              <button type="button" class="btn btn-ghost btn-sm rounded-full">
                🔁 Re-pray
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp display_name(%PrayerRequest{is_anonymous: true}), do: "Anonimo"

  defp display_name(%PrayerRequest{user: %{name: name}}) when is_binary(name) and byte_size(name) > 0,
    do: name

  defp display_name(_), do: "Usuario"

  defp avatar_initial(%PrayerRequest{is_anonymous: true}), do: "A"

  defp avatar_initial(%PrayerRequest{user: %{name: name}}) when is_binary(name) and byte_size(name) > 0 do
    name
    |> String.trim()
    |> String.first()
    |> String.upcase()
  end

  defp avatar_initial(_), do: "U"
end
