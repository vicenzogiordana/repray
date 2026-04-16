defmodule PrayerAppWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use PrayerAppWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :live_action, :atom,
    default: nil,
    doc: "the current LiveView action"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <main>
      {render_slot(@inner_block)}
    </main>

    <div :if={assigns[:live_action] in [:global, :following, :new, :search, :profile]}>
      <div class="fixed bottom-0 left-0 z-50 w-full h-16 bg-base-100 border-t border-base-200 flex justify-around items-center">
        <.link patch={~p"/"} class={["flex flex-col items-center justify-center flex-1 h-full", if(assigns[:live_action] == :global, do: "text-neutral font-bold", else: "text-base-content/40")]}>
          <.icon name="hero-globe-americas" class="w-7 h-7" />
        </.link>

        <.link patch={~p"/following"} class={["flex flex-col items-center justify-center flex-1 h-full", if(assigns[:live_action] == :following, do: "text-neutral font-bold", else: "text-base-content/40")]}>
          <.icon name="hero-home" class="w-7 h-7" />
        </.link>

        <.link patch={~p"/new"} class={["flex flex-col items-center justify-center flex-1 h-full", if(assigns[:live_action] == :new, do: "text-neutral font-bold", else: "text-base-content/40")]}>
          <.icon name="hero-plus-circle" class="w-7 h-7" />
        </.link>

        <.link patch={~p"/search"} class={["flex flex-col items-center justify-center flex-1 h-full", if(assigns[:live_action] == :search, do: "text-neutral font-bold", else: "text-base-content/40")]}>
          <.icon name="hero-magnifying-glass" class="w-7 h-7" />
        </.link>

        <.link patch={~p"/profile"} class={["flex flex-col items-center justify-center flex-1 h-full", if(assigns[:live_action] == :profile, do: "text-neutral font-bold", else: "text-base-content/40")]}>
          <.icon name="hero-user" class="w-7 h-7" />
        </.link>
      </div>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
