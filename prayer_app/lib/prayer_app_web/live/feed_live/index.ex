defmodule PrayerAppWeb.FeedLive.Index do
  use PrayerAppWeb, :live_view

  alias PrayerApp.Accounts
  alias PrayerApp.Interactions
  alias PrayerApp.Prayers
  alias PrayerApp.Prayers.PrayerRequest
  alias PrayerApp.Social

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
      |> assign(:current_view, :global)
      |> assign(:open_update_forms, MapSet.new())
      |> assign(:open_testimony_forms, MapSet.new())
        |> assign(:profile_tab, :requests)
          |> assign(:profile_user, current_user)
          |> assign(:is_own_profile, true)
        |> assign(:search_results, [])
        |> assign(:search_query, "")
            |> assign(:followed_ids, Social.list_followed_ids(current_user.id))
      |> assign(:profile_requests, [])
      |> assign(:profile_repray_requests, [])
      |> assign(:profile_stats, %{requests: 0, followers: 0, following: 0})}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :global, _params) do
    socket
    |> assign(:current_view, :global)
    |> assign(:open_update_forms, MapSet.new())
    |> assign(:open_testimony_forms, MapSet.new())
    |> assign(:requests, PrayerApp.Prayers.list_prayer_requests())
  end

  defp apply_action(socket, :following, _params) do
    socket
    |> assign(:current_view, :following)
    |> assign(:open_update_forms, MapSet.new())
    |> assign(:open_testimony_forms, MapSet.new())
    |> assign(:requests, PrayerApp.Prayers.list_following_feed(socket.assigns.current_user))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:current_view, :new)
    |> assign(:open_update_forms, MapSet.new())
    |> assign(:open_testimony_forms, MapSet.new())
    |> assign(:requests, [])
  end

  defp apply_action(socket, :search, _params) do
    current_user = socket.assigns.current_user

    socket
    |> assign(:current_view, :search)
    |> assign(:open_update_forms, MapSet.new())
    |> assign(:open_testimony_forms, MapSet.new())
    |> assign(:requests, [])
    |> assign(:search_results, [])
    |> assign(:search_query, "")
    |> assign(:followed_ids, Social.list_followed_ids(current_user.id))
  end

  defp apply_action(socket, :profile, _params) do
    current_user = socket.assigns.current_user
    {profile_requests, profile_repray_requests, profile_stats} = profile_data_for(current_user)

    socket
    |> assign(:current_view, :profile)
    |> assign(:open_update_forms, MapSet.new())
    |> assign(:open_testimony_forms, MapSet.new())
    |> assign(:requests, [])
    |> assign(:profile_tab, :requests)
    |> assign(:profile_user, current_user)
    |> assign(:is_own_profile, true)
    |> assign(:followed_ids, Social.list_followed_ids(current_user.id))
    |> assign(:profile_requests, profile_requests)
    |> assign(:profile_repray_requests, profile_repray_requests)
    |> assign(:profile_stats, profile_stats)
  end

  defp apply_action(socket, :user_profile, %{"username" => username}) do
    current_user = socket.assigns.current_user

    case Accounts.get_user_by_username(username) do
      nil ->
        socket
        |> put_flash(:error, "Perfil no encontrado")
        |> push_patch(to: ~p"/search")

      profile_user ->
        {profile_requests, profile_repray_requests, profile_stats} = profile_data_for(profile_user)

        socket
        |> assign(:current_view, :profile)
        |> assign(:open_update_forms, MapSet.new())
        |> assign(:open_testimony_forms, MapSet.new())
        |> assign(:requests, [])
        |> assign(:profile_tab, :requests)
        |> assign(:profile_user, profile_user)
        |> assign(:is_own_profile, profile_user.id == current_user.id)
        |> assign(:followed_ids, Social.list_followed_ids(current_user.id))
        |> assign(:profile_requests, profile_requests)
        |> assign(:profile_repray_requests, profile_repray_requests)
        |> assign(:profile_stats, profile_stats)
    end
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
  def handle_event("toggle_update_form", %{"request_id" => request_id}, socket) do
    case editable_request(socket, request_id) do
      {:ok, request} ->
        {:noreply,
         update(socket, :open_update_forms, fn open ->
           toggle_set(open, request.id)
         end)}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_testimony_form", %{"request_id" => request_id}, socket) do
    case editable_request(socket, request_id) do
      {:ok, request} ->
        if request.testimony do
          {:noreply, socket}
        else
          {:noreply,
           update(socket, :open_testimony_forms, fn open ->
             toggle_set(open, request.id)
           end)}
        end

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("save_update", %{"request_id" => request_id, "content" => content}, socket) do
    case editable_request(socket, request_id) do
      {:ok, request} ->
        content = String.trim(content || "")

        if content == "" do
          {:noreply, put_flash(socket, :error, "El update no puede estar vacio")}
        else
          case Prayers.create_update(%{"prayer_request_id" => request.id, "content" => content}) do
            {:ok, update_item} ->
              {:noreply,
               socket
               |> update(:requests, fn requests ->
                 Enum.map(requests, fn req ->
                   if req.id == request.id do
                     %{req | updates: List.wrap(req.updates) ++ [update_item]}
                   else
                     req
                   end
                 end)
               end)
               |> update(:open_update_forms, &MapSet.delete(&1, request.id))}

            {:error, _changeset} ->
              {:noreply, put_flash(socket, :error, "No se pudo guardar el update")}
          end
        end

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("save_testimony", %{"request_id" => request_id, "content" => content}, socket) do
    case editable_request(socket, request_id) do
      {:ok, request} ->
        content = String.trim(content || "")

        cond do
          content == "" ->
            {:noreply, put_flash(socket, :error, "El testimonio no puede estar vacio")}

          request.testimony != nil ->
            {:noreply, put_flash(socket, :error, "Este pedido ya tiene testimonio")}

          true ->
            case Prayers.create_testimony(%{"prayer_request_id" => request.id, "content" => content}) do
              {:ok, testimony_item} ->
                {:noreply,
                 socket
                 |> update(:requests, fn requests ->
                   Enum.map(requests, fn req ->
                     if req.id == request.id do
                       %{req | testimony: testimony_item}
                     else
                       req
                     end
                   end)
                 end)
                 |> update(:open_testimony_forms, &MapSet.delete(&1, request.id))}

              {:error, _changeset} ->
                {:noreply, put_flash(socket, :error, "No se pudo guardar el testimonio")}
            end
        end

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("set_profile_tab", %{"tab" => tab}, socket) do
    profile_tab = if tab == "reprays", do: :reprays, else: :requests
    {:noreply, assign(socket, :profile_tab, profile_tab)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    query = String.trim(query || "")
    followed_ids = Social.list_followed_ids(socket.assigns.current_user.id)

    results =
      if String.length(query) >= 2 do
        Accounts.search_users(query, socket.assigns.current_user.id)
      else
        []
      end

    {:noreply,
     socket
     |> assign(:search_query, query)
      |> assign(:search_results, results)
      |> assign(:followed_ids, followed_ids)}
  end

  @impl true
  def handle_event("toggle_follow", %{"id" => followed_id_str}, socket) do
    follower_id = socket.assigns.current_user.id

    case Integer.parse(to_string(followed_id_str)) do
      {followed_id, ""} ->
        followed_ids = Social.list_followed_ids(follower_id)

        if followed_id in followed_ids do
            Social.unfollow(follower_id, followed_id)
        else
            case Social.follow(follower_id, followed_id) do
              {:ok, _} -> :ok
              {:error, _} -> :ok
            end
        end

        refreshed_followed_ids = Social.list_followed_ids(follower_id)

        {:noreply, assign(socket, :followed_ids, refreshed_followed_ids)}

      _ ->
        {:noreply, socket}
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
          <ul class="timeline timeline-vertical timeline-compact">
            <li :for={{request, idx} <- Enum.with_index(@requests)}>
              <hr :if={idx > 0} />
              <div class="timeline-start text-xs text-base-content/60 pt-2">
                {format_timeline_date(request.inserted_at)}
              </div>
              <div class="timeline-middle text-base-content/70">
                <.icon name="hero-minus-circle" class="size-4" />
              </div>
              <div class="timeline-end w-full pb-4">
            <div
              :if={@live_action == :following and not Enum.empty?(request.re_prays || [])}
              class="text-xs text-base-content/50 ml-4 mt-2"
            >
              Alguien hizo re-pray
            </div>

            <div class={[
              "card bg-base-100 shadow-sm mb-4 border",
              if(request.testimony, do: "border-success", else: "border-base-200")
            ]}>
              <div class="card-body">
                <div class="flex items-center gap-3 mb-2">
                  <div class="bg-base-300 text-base-content rounded-full w-10 h-10 grid place-items-center text-center overflow-hidden shrink-0">
                    <span class="block leading-none select-none">{avatar_initial(request)}</span>
                  </div>

                  <.link
                    :if={not request.is_anonymous and not is_nil(request.user)}
                    patch={profile_path(request.user, @current_user)}
                    class="font-semibold hover:underline"
                  >
                    {display_name(request)}
                  </.link>
                  <p :if={request.is_anonymous or is_nil(request.user)} class="font-semibold">{display_name(request)}</p>
                </div>

                <p class="text-base leading-relaxed">{request.content}</p>

                <details class="collapse collapse-arrow mt-4 rounded-2xl border border-base-200 bg-base-100">
                  <summary class="collapse-title text-sm font-medium">Historial</summary>
                  <div class="collapse-content">
                    <% events = history_events(request) %>
                    <ul class="timeline timeline-vertical timeline-compact">
                      <li :for={{event, idx} <- Enum.with_index(events)}>
                        <hr :if={idx > 0} />

                        <%= case event do %>
                          <% {:created, at, _} -> %>
                            <div class="timeline-start text-xs text-base-content/60">{format_timeline_date(at)}</div>
                            <div class="timeline-middle text-base-content/70">
                              <.icon name="hero-minus-circle" class="size-4" />
                            </div>
                            <div class="timeline-end timeline-box shadow-sm">Pedido creado</div>

                          <% {:update, at, content} -> %>
                            <div class="timeline-start text-xs text-base-content/60">{format_timeline_date(at)}</div>
                            <div class="timeline-middle text-base-content/70">
                              <.icon name="hero-minus-circle" class="size-4" />
                            </div>
                            <div class="timeline-end timeline-box shadow-sm">{content}</div>

                          <% {:testimony, at, content} -> %>
                            <div class="timeline-start text-xs text-base-content/60">{format_timeline_date(at)}</div>
                            <div class="timeline-middle text-success">
                              <.icon name="hero-check-circle" class="size-4" />
                            </div>
                            <div class="timeline-end timeline-box shadow-sm border-success/30">{content}</div>
                        <% end %>

                        <hr :if={idx < length(events) - 1} />
                      </li>
                    </ul>
                  </div>
                </details>

                <div class="card-actions justify-start items-center mt-4 gap-1 flex-nowrap">
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
                  <button
                    :if={owns_request?(request, @current_user)}
                    type="button"
                    class="btn btn-ghost btn-sm rounded-full"
                    phx-click="toggle_update_form"
                    phx-value-request_id={request.id}
                    aria-label="Agregar update"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      viewBox="0 0 24 24"
                      width="24"
                      height="24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      style="opacity:1;"
                    >
                      <path
                        fill="none"
                        d="M4.266 16.06a8.92 8.92 0 0 0 3.915 3.978a8.7 8.7 0 0 0 5.471.832a8.8 8.8 0 0 0 4.887-2.64a9.07 9.07 0 0 0 2.388-5.079a9.14 9.14 0 0 0-1.044-5.53a8.9 8.9 0 0 0-4.069-3.815a8.7 8.7 0 0 0-5.5-.608c-1.85.401-3.366 1.313-4.62 2.755c-.151.16-.735.806-1.22 1.781M7.5 8l-3.609.72L3 5m9 4v4l3 2"
                      />
                    </svg>
                  </button>
                  <button
                    :if={owns_request?(request, @current_user)}
                    type="button"
                    class={["btn btn-ghost btn-sm rounded-full", if(request.testimony, do: "btn-disabled opacity-40", else: "")]}
                    phx-click="toggle_testimony_form"
                    phx-value-request_id={request.id}
                    aria-label="Agregar testimonio"
                    disabled={!!request.testimony}
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      viewBox="0 0 48 48"
                      width="24"
                      height="24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      style="opacity:1;"
                    >
                      <path
                        fill="none"
                        d="m23.52 31.518l3.227 1.188h11.781c3.098 0 3.872 2.488 3.849 3.595L29.283 41.19c-.772.288-1.678.223-2.472 0l-10.724-3.01V22.14h3.35l12.95 4.881c2.24.844 1.44 3.852-.537 4.06M9.04 22.217c1.96 0 3.54 1.605 3.54 3.6v12.14c0 1.994-1.58 3.6-3.54 3.6c-1.961 0-3.54-1.606-3.54-3.6v-12.14c0-1.995 1.579-3.6 3.54-3.6m25.392 1.14l5.659-5.682c2.148-2.158 2.452-3.649 2.405-5.966c-.055-2.714-2.618-5.13-5.763-5.262c-1.426-.06-3.147.595-4.802 1.983c-1.655-1.388-3.376-2.043-4.802-1.983c-3.145.132-5.708 2.548-5.763 5.262c-.047 2.317.257 3.808 2.405 5.966l5.66 5.682c.588.59 1.291 1.053 2.5 1.053s1.912-.462 2.5-1.053"
                      />
                    </svg>
                  </button>
                </div>

                <div
                  :if={MapSet.member?(@open_update_forms, request.id)}
                  class="mt-3 p-3 rounded-xl border border-base-200 bg-base-100"
                >
                  <form phx-submit="save_update" class="space-y-2">
                    <input type="hidden" name="request_id" value={request.id} />
                    <textarea
                      name="content"
                      class="textarea textarea-bordered w-full"
                      rows="3"
                      placeholder="Escribe una actualizacion..."
                      required
                    ></textarea>
                    <button type="submit" class="btn btn-neutral btn-sm">Guardar update</button>
                  </form>
                </div>

                <div
                  :if={MapSet.member?(@open_testimony_forms, request.id) and is_nil(request.testimony)}
                  class="mt-3 p-3 rounded-xl border border-base-200 bg-base-100"
                >
                  <form phx-submit="save_testimony" class="space-y-2">
                    <input type="hidden" name="request_id" value={request.id} />
                    <textarea
                      name="content"
                      class="textarea textarea-bordered w-full"
                      rows="3"
                      placeholder="Comparte tu testimonio..."
                      required
                    ></textarea>
                    <button type="submit" class="btn btn-neutral btn-sm">Guardar testimonio</button>
                  </form>
                </div>
              </div>
            </div>
              </div>
              <hr :if={idx < length(@requests) - 1} />
            </li>
          </ul>
        </div>

        <div :if={@current_view == :search}>
          <form phx-change="search" phx-submit="search" class="mb-6">
            <div class="relative">
              <.icon name="hero-magnifying-glass" class="absolute left-4 top-3.5 w-5 h-5 text-base-content/40" />
              <input
                type="text"
                name="query"
                value={@search_query}
                phx-debounce="300"
                placeholder="Buscar por nombre o @usuario..."
                class="input input-bordered w-full pl-12 rounded-full bg-base-100 shadow-sm"
                autocomplete="off"
              />
            </div>
          </form>

          <div :for={user <- @search_results} class="flex items-center justify-between p-4 bg-base-100 rounded-[2rem] shadow-sm border border-base-200 mb-3">
            <.link patch={profile_path(user, @current_user)} class="flex items-center gap-4 min-w-0">
              <div class="bg-base-300 text-base-content text-lg font-bold rounded-full w-12 h-12 grid place-items-center text-center overflow-hidden shrink-0">
                <span class="block leading-none select-none">{user_initial(user)}</span>
              </div>
              <div class="min-w-0">
                <p class="font-bold truncate">{user.name}</p>
                <p class="text-sm text-base-content/50 truncate">@{user.username}</p>
              </div>
            </.link>

            <button
              type="button"
              phx-click="toggle_follow"
              phx-value-id={user.id}
              class={[
                "btn btn-sm rounded-full",
                if(user.id in @followed_ids, do: "btn-neutral", else: "btn-outline")
              ]}
            >
              {if user.id in @followed_ids, do: "Siguiendo", else: "Seguir"}
            </button>
          </div>

          <div :if={@search_query != "" and Enum.empty?(@search_results)} class="text-center text-base-content/60 py-8">
            No se encontraron usuarios.
          </div>
        </div>

        <div :if={@current_view == :profile} class="space-y-4">
          <div class="card bg-base-100 shadow-sm border border-base-200 rounded-[2rem]">
            <div class="card-body">
              <div class="flex items-start justify-between gap-3 sm:gap-4">
                <div class="flex items-center gap-3 sm:gap-4 flex-1 min-w-0">
                  <div class="bg-base-300 text-base-content rounded-full w-14 h-14 sm:w-20 sm:h-20 grid place-items-center text-center overflow-hidden shrink-0">
                    <span class="text-xl sm:text-2xl leading-none select-none">{profile_initial(@profile_user)}</span>
                  </div>

                  <div class="grid grid-cols-3 gap-2 sm:gap-4 text-center flex-1 min-w-0">
                    <div>
                      <p class="font-semibold text-lg sm:text-xl leading-none">{@profile_stats.requests}</p>
                      <p class="text-[11px] sm:text-xs text-base-content/60 leading-tight">Pedidos</p>
                    </div>
                    <div>
                      <p class="font-semibold text-lg sm:text-xl leading-none">{@profile_stats.followers}</p>
                      <p class="text-[11px] sm:text-xs text-base-content/60 leading-tight">Seguidores</p>
                    </div>
                    <div>
                      <p class="font-semibold text-lg sm:text-xl leading-none">{@profile_stats.following}</p>
                      <p class="text-[11px] sm:text-xs text-base-content/60 leading-tight">Seguidos</p>
                    </div>
                  </div>
                </div>

                <div :if={@is_own_profile} class="dropdown dropdown-end shrink-0">
                  <div tabindex="0" role="button" class="btn btn-ghost btn-circle btn-sm">
                    <.icon name="hero-cog-6-tooth" class="size-5" />
                  </div>
                  <ul tabindex="0" class="dropdown-content menu bg-base-100 rounded-box z-[1] mt-2 w-44 p-2 shadow border border-base-200">
                    <li><.link navigate={~p"/users/settings"}>Settings</.link></li>
                    <li><.link href={~p"/users/log-out"} method="delete">Cerrar sesion</.link></li>
                  </ul>
                </div>
              </div>

              <div class="mt-3">
                <p class="font-semibold">{display_name_from_user(@profile_user)}</p>
                <p class="text-sm text-base-content/60">@{profile_username(@profile_user)}</p>
              </div>

              <button
                :if={@is_own_profile}
                type="button"
                class="btn btn-outline btn-sm w-full mt-4 rounded-[2rem]"
              >
                Editar Perfil
              </button>

              <button
                :if={not @is_own_profile}
                type="button"
                phx-click="toggle_follow"
                phx-value-id={@profile_user.id}
                class={[
                  "btn btn-sm w-full mt-4 rounded-[2rem]",
                  if(@profile_user.id in @followed_ids, do: "btn-neutral", else: "btn-outline")
                ]}
              >
                {if @profile_user.id in @followed_ids, do: "Siguiendo", else: "Seguir"}
              </button>
            </div>
          </div>

          <div class="tabs tabs-boxed justify-center bg-base-100 border border-base-200 rounded-[2rem] p-1">
            <button
              type="button"
              phx-click="set_profile_tab"
              phx-value-tab="requests"
              class={[
                "tab gap-2 rounded-[2rem]",
                if(@profile_tab == :requests, do: "tab-active", else: "")
              ]}
            >
              <.icon name="hero-document-text" class="size-4" /> Pedidos
            </button>
            <button
              type="button"
              phx-click="set_profile_tab"
              phx-value-tab="reprays"
              class={[
                "tab gap-2 rounded-[2rem]",
                if(@profile_tab == :reprays, do: "tab-active", else: "")
              ]}
            >
              <.icon name="hero-arrow-path" class="size-4" /> Re-prays
            </button>
          </div>

          <% profile_items = if @profile_tab == :requests, do: @profile_requests, else: @profile_repray_requests %>

          <div class="space-y-4" :if={profile_items == []}>
            <div class="card bg-base-100 shadow-sm border border-base-200 rounded-[2rem]">
              <div class="card-body text-center text-base-content/60">
                No hay contenido para mostrar en esta pestana.
              </div>
            </div>
          </div>

          <div class="space-y-4" :if={profile_items != []}>
            <div :for={request <- profile_items} class={[
              "card bg-base-100 shadow-sm border rounded-[2rem]",
              if(request.testimony, do: "border-success", else: "border-base-200")
            ]}>
              <div class="card-body">
                <div class="flex items-center justify-between gap-3 mb-2">
                  <div class="flex items-center gap-3">
                    <div class="bg-base-300 text-base-content rounded-full w-10 h-10 grid place-items-center text-center overflow-hidden shrink-0">
                      <span class="block leading-none select-none">{avatar_initial(request)}</span>
                    </div>
                    <.link
                      :if={not request.is_anonymous and not is_nil(request.user)}
                      patch={profile_path(request.user, @current_user)}
                      class="font-semibold hover:underline"
                    >
                      {display_name(request)}
                    </.link>
                    <p :if={request.is_anonymous or is_nil(request.user)} class="font-semibold">{display_name(request)}</p>
                  </div>

                  <span :if={@profile_tab == :reprays} class="badge badge-outline">Re-pray</span>
                </div>

                <p class="text-base leading-relaxed">{request.content}</p>

                <details class="collapse collapse-arrow mt-4 rounded-2xl border border-base-200 bg-base-100">
                  <summary class="collapse-title text-sm font-medium">Historial</summary>
                  <div class="collapse-content">
                    <% events = history_events(request) %>
                    <ul class="timeline timeline-vertical timeline-compact">
                      <li :for={{event, idx} <- Enum.with_index(events)}>
                        <hr :if={idx > 0} />

                        <%= case event do %>
                          <% {:created, at, _} -> %>
                            <div class="timeline-start text-xs text-base-content/60">{format_timeline_date(at)}</div>
                            <div class="timeline-middle text-base-content/70">
                              <.icon name="hero-minus-circle" class="size-4" />
                            </div>
                            <div class="timeline-end timeline-box shadow-sm">Pedido creado</div>

                          <% {:update, at, content} -> %>
                            <div class="timeline-start text-xs text-base-content/60">{format_timeline_date(at)}</div>
                            <div class="timeline-middle text-base-content/70">
                              <.icon name="hero-minus-circle" class="size-4" />
                            </div>
                            <div class="timeline-end timeline-box shadow-sm">{content}</div>

                          <% {:testimony, at, content} -> %>
                            <div class="timeline-start text-xs text-base-content/60">{format_timeline_date(at)}</div>
                            <div class="timeline-middle text-success">
                              <.icon name="hero-check-circle" class="size-4" />
                            </div>
                            <div class="timeline-end timeline-box shadow-sm border-success/30">{content}</div>
                        <% end %>

                        <hr :if={idx < length(events) - 1} />
                      </li>
                    </ul>
                  </div>
                </details>
              </div>
            </div>
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

  defp display_name_from_user(%{name: name}) when is_binary(name) and byte_size(name) > 0, do: name
  defp display_name_from_user(_), do: "Usuario"

  defp profile_path(%{id: user_id}, %{id: current_user_id}) when user_id == current_user_id do
    ~p"/profile"
  end

  defp profile_path(%{username: username}, _current_user)
       when is_binary(username) and byte_size(username) > 0 do
    ~p"/profile/#{username}"
  end

  defp profile_path(_, _), do: ~p"/profile"

  defp profile_username(%{username: username}) when is_binary(username) and byte_size(username) > 0,
    do: username

  defp profile_username(%{email: email}) when is_binary(email) do
    email
    |> String.split("@")
    |> List.first()
    |> to_string()
    |> String.replace(~r/[^a-zA-Z0-9_\.]/, "")
    |> String.downcase()
  end

  defp profile_username(_), do: "usuario"

  defp profile_initial(%{name: name}) when is_binary(name) and byte_size(name) > 0 do
    name
    |> String.trim()
    |> String.first()
    |> String.upcase()
  end

  defp profile_initial(_), do: "U"

  defp user_initial(%{name: name}) when is_binary(name) and byte_size(name) > 0 do
    name
    |> String.trim()
    |> String.first()
    |> String.upcase()
  end

  defp user_initial(_), do: "U"

  defp profile_data_for(profile_user) do
    profile_requests = Prayers.list_user_requests(profile_user.id)

    profile_repray_requests =
      profile_user.id
      |> Interactions.list_user_re_prays()
      |> Enum.map(& &1.prayer_request)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq_by(& &1.id)

    profile_stats = %{
      requests: length(profile_requests),
      followers: Social.count_followers(profile_user.id),
      following: Social.count_following(profile_user.id)
    }

    {profile_requests, profile_repray_requests, profile_stats}
  end

  defp history_events(request) do
    updates =
      request.updates
      |> List.wrap()
      |> Enum.sort_by(& &1.inserted_at || ~N[0000-01-01 00:00:00])

    testimony_events =
      case request.testimony do
        nil -> []
        testimony -> [{:testimony, testimony.inserted_at, testimony.content}]
      end

    [{:created, request.inserted_at, nil}] ++
      Enum.map(updates, &{:update, &1.inserted_at, &1.content}) ++
      testimony_events
  end

  defp owns_request?(%PrayerRequest{user_id: user_id}, %{id: current_user_id}) do
    user_id == current_user_id
  end

  defp owns_request?(_, _), do: false

  defp editable_request(socket, request_id) do
    with {id, ""} <- Integer.parse(to_string(request_id)),
         %PrayerRequest{} = request <- Enum.find(socket.assigns.requests, &(&1.id == id)),
         true <- owns_request?(request, socket.assigns.current_user) do
      {:ok, request}
    else
      _ -> :error
    end
  end

  defp toggle_set(set, id) do
    if MapSet.member?(set, id) do
      MapSet.delete(set, id)
    else
      MapSet.put(set, id)
    end
  end

  defp format_timeline_date(nil), do: "Sin fecha"

  defp format_timeline_date(%NaiveDateTime{} = date_time) do
    Calendar.strftime(date_time, "%d/%m/%y %H:%M")
  end

  defp format_timeline_date(%DateTime{} = date_time) do
    date_time
    |> DateTime.to_naive()
    |> Calendar.strftime("%d/%m/%y %H:%M")
  end
end
