defmodule PrayerAppWeb.UserLive.Login do
  use PrayerAppWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen flex items-center justify-center px-4 py-10">
        <div class="w-full max-w-md card bg-base-100 border border-base-content/20 rounded-[2rem] shadow-sm">
          <div class="card-body p-6 sm:p-8 space-y-4">
            <div class="text-center space-y-1">
              <p class="text-3xl font-black tracking-tight">Re-Pray</p>
              <p class="text-sm text-base-content/70">
                Una app para compartir pedidos, testimonios y seguir personas para orar juntos cada dia.
              </p>
            </div>

            <div class="text-center">
              <.header>
                <p>Iniciar sesión</p>
                <:subtitle>
                  <%= if @current_scope do %>
                    Vuelve a autenticarte para continuar.
                  <% else %>
                    ¿No tienes cuenta? <.link
                      navigate={~p"/users/register"}
                      class="font-semibold text-base-content hover:underline"
                      phx-no-format
                    >Registrate</.link> ahora.
                  <% end %>
                </:subtitle>
              </.header>
            </div>

            <.form
              :let={f}
              for={@form}
              id="login_form_password"
              action={~p"/users/log-in"}
              phx-submit="submit_password"
              phx-trigger-action={@trigger_submit}
            >
              <.input
                readonly={!!@current_scope}
                field={f[:email]}
                type="email"
                label="Email"
                autocomplete="username"
                spellcheck="false"
                required
                phx-mounted={JS.focus()}
              />
              <.input
                field={@form[:password]}
                type="password"
                label="Contrasena"
                autocomplete="current-password"
                spellcheck="false"
              />
              <.button class="btn btn-primary w-full" name={@form[:remember_me].name} value="true">
                Ingresar y recordar sesión <span aria-hidden="true">→</span>
              </.button>
              <.button class="btn btn-primary btn-soft w-full mt-2">
                Ingresar solo esta vez
              </.button>
            </.form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end
end
