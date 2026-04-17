defmodule PrayerAppWeb.UserLive.Registration do
  use PrayerAppWeb, :live_view
  require Logger

  alias PrayerApp.Accounts
  alias PrayerApp.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen flex items-center justify-center px-4 py-10">
        <div class="w-full max-w-md card bg-base-100 border border-base-content/20 rounded-[2rem] shadow-sm">
          <div class="card-body p-6 sm:p-8 space-y-4">
            <div class="text-center space-y-1">
              <p class="text-3xl font-black tracking-tight">Re-pray</p>
              <p class="text-sm text-base-content/70">
                Crea tu cuenta para compartir pedidos, seguir personas y orar juntos cada dia.
              </p>
            </div>

            <div class="text-center">
              <.header>
                Crear cuenta
                <:subtitle>
                  ¿Ya tienes cuenta?
                  <.link navigate={~p"/users/log-in"} class="font-semibold text-base-content hover:underline">
                    Inicia sesión
                  </.link>
                </:subtitle>
              </.header>
            </div>

            <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
              <.input
                field={@form[:name]}
                type="text"
                label="Nombre"
                autocomplete="name"
                required
                phx-mounted={JS.focus()}
              />

              <.input
                field={@form[:username]}
                type="text"
                label="Usuario"
                autocomplete="username"
                spellcheck="false"
                required
              />

              <.input
                field={@form[:email]}
                type="email"
                label="Email"
                autocomplete="email"
                spellcheck="false"
                required
              />

              <.input
                field={@form[:password]}
                type="password"
                label="Contrasena"
                autocomplete="new-password"
                required
              />

              <.button phx-disable-with="Creando cuenta..." class="btn btn-primary w-full">
                Crear cuenta
              </.button>
            </.form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: PrayerAppWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{}, %{}, validate_unique: false)

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        email_notice =
          case Accounts.deliver_login_instructions(
                 user,
                 &url(~p"/users/log-in/#{&1}")
               ) do
            {:ok, _} ->
              "An email was sent to #{user.email}, please access it to confirm your account."

            {:error, reason} ->
              Logger.warning("Registration email delivery failed for #{user.email}: #{inspect(reason)}")
              "Your account was created. You can log in with your email and password."
          end

        {:noreply,
         socket
         |> put_flash(:info, email_notice)
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
