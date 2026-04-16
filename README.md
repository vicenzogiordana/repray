# PrayerApp – Guía de Inicialización y Arquitectura

Este repositorio contiene la guía exacta para crear `PrayerApp` con Phoenix LiveView, PostgreSQL, autenticación y arquitectura Ecto completa.

## Paso 1: Inicialización y Setup

### 1) Crear proyecto Phoenix (LiveView + PostgreSQL)

```bash
mix local.hex --force
mix archive.install hex phx_new --force
mix phx.new prayer_app --live --database postgres
cd prayer_app
mix deps.get
```

### 2) Instalar DaisyUI y configurar modo claro

```bash
cd assets
npm install -D daisyui@latest
cd ..
```

Editar `assets/tailwind.config.js`:

```js
module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/*_web.ex",
    "../lib/*_web/**/*.*ex"
  ],
  theme: {
    extend: {}
  },
  plugins: [require("daisyui")],
  daisyui: {
    themes: ["light"],
    darkTheme: "light"
  }
};
```

### 3) Generar autenticación y extender `User`

```bash
mix phx.gen.auth Accounts User users
```

Antes de correr migraciones, editar:

- `priv/repo/migrations/*_create_users_auth_tables.exs`
- `lib/prayer_app/accounts/user.ex`
- `lib/prayer_app/accounts/user_notifier.ex` (sin cambios funcionales)

#### Migración de users (fragmento exacto a agregar)

Dentro del `create table(:users)`:

```elixir
add :name, :string, null: false
add :username, :string, null: false
```

Y crear índice único:

```elixir
create unique_index(:users, [:username])
```

#### Esquema `User` (`lib/prayer_app/accounts/user.ex`)

```elixir
defmodule PrayerApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :naive_datetime
    field :name, :string
    field :username, :string

    timestamps(type: :utc_datetime)
  end

  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :name, :username])
    |> validate_required([:email, :password, :name, :username])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:username, min: 3, max: 30)
    |> validate_format(:username, ~r/^[a-zA-Z0-9_]+(\.[a-zA-Z0-9_]+)*$/)
    |> unsafe_validate_unique(:email, PrayerApp.Repo)
    |> unsafe_validate_unique(:username, PrayerApp.Repo)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> validate_email(opts)
    |> validate_password(opts)
  end

  # resto del archivo generado por phx.gen.auth sin cambios
end
```

---

## Paso 2: Arquitectura de Base de Datos (Ecto)

### Comandos de generación

```bash
mix phx.gen.context Prayers PrayerRequest prayer_requests content:text is_anonymous:boolean status:string prays_count:integer user_id:references:users
mix phx.gen.context Prayers Update updates content:text prayer_request_id:references:prayer_requests
mix phx.gen.context Prayers Testimony testimonies content:text prayer_request_id:references:prayer_requests
mix phx.gen.context Social Follow follows follower_id:references:users followed_id:references:users
mix phx.gen.context Interactions Pray prays user_id:references:users prayer_request_id:references:prayer_requests
mix phx.gen.context Interactions RePray re_prays user_id:references:users prayer_request_id:references:prayer_requests comment:text
```

> Luego ajusta migraciones/esquemas para defaults, índices compuestos y relaciones exactas.

### Migraciones (código recomendado)

#### `*_create_prayer_requests.exs`

```elixir
def change do
  create table(:prayer_requests) do
    add :content, :text, null: false
    add :is_anonymous, :boolean, default: false, null: false
    add :status, :string, default: "active", null: false
    add :prays_count, :integer, default: 0, null: false
    add :user_id, references(:users, on_delete: :delete_all), null: false

    timestamps(type: :utc_datetime)
  end

  create index(:prayer_requests, [:user_id])
  create index(:prayer_requests, [:status])
  create index(:prayer_requests, [:inserted_at])
end
```

#### `*_create_updates.exs`

```elixir
def change do
  create table(:updates) do
    add :content, :text, null: false
    add :prayer_request_id, references(:prayer_requests, on_delete: :delete_all), null: false

    timestamps(type: :utc_datetime)
  end

  create index(:updates, [:prayer_request_id])
end
```

#### `*_create_testimonies.exs`

```elixir
def change do
  create table(:testimonies) do
    add :content, :text, null: false
    add :prayer_request_id, references(:prayer_requests, on_delete: :delete_all), null: false

    timestamps(type: :utc_datetime)
  end

  create unique_index(:testimonies, [:prayer_request_id])
end
```

#### `*_create_follows.exs`

```elixir
def change do
  create table(:follows) do
    add :follower_id, references(:users, on_delete: :delete_all), null: false
    add :followed_id, references(:users, on_delete: :delete_all), null: false

    timestamps(type: :utc_datetime)
  end

  create index(:follows, [:follower_id])
  create index(:follows, [:followed_id])
  create unique_index(:follows, [:follower_id, :followed_id])
end
```

#### `*_create_prays.exs`

```elixir
def change do
  create table(:prays) do
    add :user_id, references(:users, on_delete: :delete_all), null: false
    add :prayer_request_id, references(:prayer_requests, on_delete: :delete_all), null: false

    timestamps(type: :utc_datetime)
  end

  create index(:prays, [:user_id])
  create index(:prays, [:prayer_request_id])
  create unique_index(:prays, [:user_id, :prayer_request_id])
end
```

#### `*_create_re_prays.exs`

```elixir
def change do
  create table(:re_prays) do
    add :user_id, references(:users, on_delete: :delete_all), null: false
    add :prayer_request_id, references(:prayer_requests, on_delete: :delete_all), null: false
    add :comment, :text, null: false

    timestamps(type: :utc_datetime)
  end

  create index(:re_prays, [:user_id])
  create index(:re_prays, [:prayer_request_id])
  create unique_index(:re_prays, [:user_id, :prayer_request_id])
end
```

### Esquemas y relaciones

#### `lib/prayer_app/prayers/prayer_request.ex`

```elixir
defmodule PrayerApp.Prayers.PrayerRequest do
  use Ecto.Schema
  import Ecto.Changeset

  schema "prayer_requests" do
    field :content, :string
    field :is_anonymous, :boolean, default: false
    field :status, :string, default: "active"
    field :prays_count, :integer, default: 0

    belongs_to :user, PrayerApp.Accounts.User
    has_many :updates, PrayerApp.Prayers.Update
    has_one :testimony, PrayerApp.Prayers.Testimony
    has_many :prays, PrayerApp.Interactions.Pray
    has_many :re_prays, PrayerApp.Interactions.RePray

    timestamps(type: :utc_datetime)
  end

  def changeset(prayer_request, attrs) do
    prayer_request
    |> cast(attrs, [:content, :is_anonymous, :status, :prays_count, :user_id])
    |> validate_required([:content, :status, :user_id])
    |> assoc_constraint(:user)
  end
end
```

#### `lib/prayer_app/prayers/update.ex`

```elixir
defmodule PrayerApp.Prayers.Update do
  use Ecto.Schema
  import Ecto.Changeset

  schema "updates" do
    field :content, :string
    belongs_to :prayer_request, PrayerApp.Prayers.PrayerRequest

    timestamps(type: :utc_datetime)
  end

  def changeset(update, attrs) do
    update
    |> cast(attrs, [:content, :prayer_request_id])
    |> validate_required([:content, :prayer_request_id])
    |> assoc_constraint(:prayer_request)
  end
end
```

#### `lib/prayer_app/prayers/testimony.ex`

```elixir
defmodule PrayerApp.Prayers.Testimony do
  use Ecto.Schema
  import Ecto.Changeset

  schema "testimonies" do
    field :content, :string
    belongs_to :prayer_request, PrayerApp.Prayers.PrayerRequest

    timestamps(type: :utc_datetime)
  end

  def changeset(testimony, attrs) do
    testimony
    |> cast(attrs, [:content, :prayer_request_id])
    |> validate_required([:content, :prayer_request_id])
    |> assoc_constraint(:prayer_request)
    |> unique_constraint(:prayer_request_id)
  end
end
```

#### `lib/prayer_app/social/follow.ex`

```elixir
defmodule PrayerApp.Social.Follow do
  use Ecto.Schema
  import Ecto.Changeset

  schema "follows" do
    belongs_to :follower, PrayerApp.Accounts.User
    belongs_to :followed, PrayerApp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(follow, attrs) do
    changeset =
      follow
      |> cast(attrs, [:follower_id, :followed_id])
      |> validate_required([:follower_id, :followed_id])

    changeset =
      case {get_field(changeset, :follower_id), get_field(changeset, :followed_id)} do
        {id, id} when not is_nil(id) ->
          add_error(changeset, :followed_id, "no puedes seguirte a ti mismo")

        _ ->
          changeset
      end

    changeset
    |> unique_constraint([:follower_id, :followed_id])
    |> assoc_constraint(:follower)
    |> assoc_constraint(:followed)
  end
end
```

> Si prefieres evitar ambigüedad de FK, puedes declarar explícitamente:
> `belongs_to :follower, PrayerApp.Accounts.User, foreign_key: :follower_id`
> `belongs_to :followed, PrayerApp.Accounts.User, foreign_key: :followed_id`

#### `lib/prayer_app/interactions/pray.ex`

```elixir
defmodule PrayerApp.Interactions.Pray do
  use Ecto.Schema
  import Ecto.Changeset

  schema "prays" do
    belongs_to :user, PrayerApp.Accounts.User
    belongs_to :prayer_request, PrayerApp.Prayers.PrayerRequest

    timestamps(type: :utc_datetime)
  end

  def changeset(pray, attrs) do
    pray
    |> cast(attrs, [:user_id, :prayer_request_id])
    |> validate_required([:user_id, :prayer_request_id])
    |> unique_constraint([:user_id, :prayer_request_id])
    |> assoc_constraint(:user)
    |> assoc_constraint(:prayer_request)
  end
end
```

#### `lib/prayer_app/interactions/re_pray.ex`

```elixir
defmodule PrayerApp.Interactions.RePray do
  use Ecto.Schema
  import Ecto.Changeset

  schema "re_prays" do
    field :comment, :string

    belongs_to :user, PrayerApp.Accounts.User
    belongs_to :prayer_request, PrayerApp.Prayers.PrayerRequest

    timestamps(type: :utc_datetime)
  end

  def changeset(re_pray, attrs) do
    re_pray
    |> cast(attrs, [:comment, :user_id, :prayer_request_id])
    |> validate_required([:comment, :user_id, :prayer_request_id])
    |> validate_change(:comment, &validate_comment_word_count/2)
    |> unique_constraint([:user_id, :prayer_request_id])
    |> assoc_constraint(:user)
    |> assoc_constraint(:prayer_request)
  end

  defp validate_comment_word_count(_field, comment) when is_binary(comment) do
    words =
      comment
      |> String.trim()
      |> String.split(~r/\s+/, trim: true)
      |> length()

    if words > 50 do
      [comment: "debe tener como máximo 50 palabras"]
    else
      []
    end
  end

  defp validate_comment_word_count(_field, _), do: []
end
```

---

## Paso 3: Lógica de consultas – `list_following_feed(current_user)`

Agregar en `lib/prayer_app/prayers.ex`:

```elixir
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
      preload: [:user]

  requests = PrayerApp.Repo.all(feed_query)

  PrayerApp.Repo.preload(
    requests,
    re_prays:
      from rp in PrayerApp.Interactions.RePray,
        where: rp.user_id in subquery(followed_ids_query),
        order_by: [desc: rp.inserted_at],
        preload: [:user]
  )
end
```

Cumple con:
- pedidos creados por seguidos,
- pedidos republicados (RePray) por seguidos,
- `distinct` para evitar duplicados,
- orden descendente por fecha,
- preload del creador (`:user`) y los `re_prays` con su usuario y comentario.

---

## Orden recomendado para migraciones (evita conflictos FK)

1. `users` (auth)
2. `prayer_requests` (depende de users)
3. `updates` (depende de prayer_requests)
4. `testimonies` (depende de prayer_requests)
5. `follows` (depende de users)
6. `prays` (depende de users + prayer_requests)
7. `re_prays` (depende de users + prayer_requests)

Si los timestamps de archivos no quedan en ese orden, renómbralos antes de migrar.

### Ejecución final

```bash
mix ecto.create
mix ecto.migrate
mix phx.server
```

Si cambiaste migraciones ya ejecutadas en local:

```bash
mix ecto.drop
mix ecto.setup
```
