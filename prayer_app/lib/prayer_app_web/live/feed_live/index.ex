defmodule PrayerAppWeb.FeedLive.Index do
  use PrayerAppWeb, :live_view

  alias PrayerApp.Prayers
  alias PrayerApp.Prayers.PrayerRequest

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_scope.user

    form =
      %PrayerRequest{}
      |> Prayers.change_prayer_request()
      |> to_form(as: :prayer_request)

    {:ok,
     socket
     |> assign(:form, form)
     |> assign(:requests, [])
     |> assign(:current_user, current_user)
     |> assign(:current_view, :global)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :global, _params) do
    socket
    |> assign(:current_view, :global)
    |> assign(:requests, PrayerApp.Prayers.list_prayer_requests())
  end

  defp apply_action(socket, :following, _params) do
    socket
    |> assign(:current_view, :following)
    |> assign(:requests, PrayerApp.Prayers.list_following_feed(socket.assigns.current_user))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:current_view, :new)
    |> assign(:requests, [])
  end

  defp apply_action(socket, :search, _params) do
    socket
    |> assign(:current_view, :search)
    |> assign(:requests, [])
  end

  defp apply_action(socket, :profile, _params) do
    socket
    |> assign(:current_view, :profile)
    |> assign(:requests, [])
  end

  @impl true
  def handle_event("save_prayer", %{"prayer_request" => params}, socket) do
    current_user = socket.assigns.current_user

    attrs =
      params
      |> Map.put("user_id", current_user.id)
      |> Map.put("status", "active")

    case Prayers.create_prayer_request(attrs) do
      {:ok, prayer_request} ->
        _prayer_request =
          PrayerApp.Repo.preload(prayer_request, [:user, :re_prays])

        form =
          %PrayerRequest{}
          |> Prayers.change_prayer_request()
          |> to_form(as: :prayer_request)

        {:noreply,
         socket
         |> assign(:form, form)
         |> push_patch(to: ~p"/")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :prayer_request))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} live_action={@live_action} current_scope={assigns[:current_scope] || nil}>
      <div class="max-w-2xl mx-auto py-8 px-4 sm:px-0 pb-24">
        <div :if={@live_action == :new}>
          <div class="mb-6 px-1">
            <h1 class="text-2xl font-semibold">Nuevo Pedido de Oracion</h1>
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
        </div>

        <div :if={@live_action in [:global, :following]}>

          <div :for={request <- @requests}>
            <div
              :if={@live_action == :following and not Enum.empty?(request.re_prays || [])}
              class="text-xs text-base-content/50 ml-4 mt-2"
            >
              Alguien hizo re-pray
            </div>

            <div class="card bg-base-100 shadow-sm mb-4 border border-base-200">
              <div class="card-body">
                <div class="flex items-center gap-3 mb-2">
                  <div class="avatar placeholder">
                    <div class="bg-base-300 text-base-content rounded-full w-10">
                      <span>{avatar_initial(request)}</span>
                    </div>
                  </div>

                  <p class="font-semibold">{display_name(request)}</p>
                </div>

                <p class="text-base leading-relaxed">{request.content}</p>

                <div class="card-actions justify-start mt-4">
                  <button type="button" class="btn btn-ghost btn-sm rounded-full">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      viewBox="0 0 256 256"
                      width="24"
                      height="24"
                      fill="currentColor"
                      style="opacity:1;"
                      aria-hidden="true"
                    >
                      <path d="m233.9 181.42l-36.59-36.6L160.71 24A19.75 19.75 0 0 0 128 15.62A19.75 19.75 0 0 0 95.29 24l-36.6 120.82l-36.59 36.6a14 14 0 0 0 0 19.79l32.69 32.69a14 14 0 0 0 19.79 0l48.29-48.28a38 38 0 0 0 5.13-6.38a38 38 0 0 0 5.13 6.38l48.29 48.28a14 14 0 0 0 19.79 0l32.69-32.69a14 14 0 0 0 0-19.79m-167.8 44a2 2 0 0 1-2.83 0l-32.69-32.69a2 2 0 0 1 0-2.83l14.11-14.1l35.51 35.51Zm48.28-48.29l-25.69 25.7l-35.52-35.52l15.07-15.07a6 6 0 0 0 1.5-2.5l37-122.22A7.78 7.78 0 0 1 122 29.78v129a25.83 25.83 0 0 1-7.62 18.35M134 158.75v-129a7.78 7.78 0 0 1 15.22-2.26l37 122.22a6 6 0 0 0 1.5 2.5l15.93 15.94l-36.28 34.74l-25.79-25.79a25.83 25.83 0 0 1-7.58-18.35m91.42 34l-32.69 32.69a2 2 0 0 1-2.83 0l-14-14l36.29-34.74l13.24 13.23a2 2 0 0 1-.01 2.8Z" />
                    </svg>
                  </button>
                  <button type="button" class="btn btn-ghost btn-sm rounded-full">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      stroke="currentColor"
                      class="size-6"
                      aria-hidden="true"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M19.5 12c0-1.232-.046-2.453-.138-3.662a4.006 4.006 0 0 0-3.7-3.7 48.678 48.678 0 0 0-7.324 0 4.006 4.006 0 0 0-3.7 3.7c-.017.22-.032.441-.046.662M19.5 12l3-3m-3 3-3-3m-12 3c0 1.232.046 2.453.138 3.662a4.006 4.006 0 0 0 3.7 3.7 48.656 48.656 0 0 0 7.324 0 4.006 4.006 0 0 0 3.7-3.7c.017-.22.032-.441.046-.662M4.5 12l3 3m-3-3-3 3"
                      />
                    </svg>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div :if={@current_view == :search} class="card bg-base-100 shadow-sm border border-base-200">
          <div class="card-body">
            <h2 class="card-title">Busqueda</h2>
            <p class="text-base-content/60">Aqui iremos mostrando resultados de busqueda.</p>
          </div>
        </div>

        <div :if={@current_view == :profile} class="card bg-base-100 shadow-sm border border-base-200">
          <div class="card-body">
            <h2 class="card-title">Perfil</h2>
            <p class="text-base-content/60">Aqui iremos mostrando tu perfil.</p>
          </div>
        </div>
      </div>
    </Layouts.app>
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
