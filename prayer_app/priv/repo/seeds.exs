import Ecto.Query

alias PrayerApp.Repo
alias PrayerApp.Accounts
alias PrayerApp.Accounts.User
alias PrayerApp.Prayers
alias PrayerApp.Prayers.PrayerRequest
alias PrayerApp.Prayers.Update
alias PrayerApp.Prayers.Testimony
alias PrayerApp.Interactions
alias PrayerApp.Interactions.Pray
alias PrayerApp.Interactions.RePray
alias PrayerApp.Social
alias PrayerApp.Social.Follow

IO.puts("Seeding fake data...")

user_seed = [
	%{name: "Ana Torres", username: "anatorres", email: "ana@example.com", password: "supersecure123"},
	%{name: "Pedro Diaz", username: "pedrodiaz", email: "pedro@example.com", password: "supersecure123"},
	%{name: "Luisa Mora", username: "luisamora", email: "luisa@example.com", password: "supersecure123"},
	%{name: "David Rios", username: "davidrios", email: "david@example.com", password: "supersecure123"},
	%{name: "Maria Sol", username: "mariasol", email: "maria@example.com", password: "supersecure123"},
	%{name: "Tomas Vega", username: "tomasvega", email: "tomas@example.com", password: "supersecure123"},
	%{name: "Elena Cruz", username: "elenacruz", email: "elena@example.com", password: "supersecure123"},
	%{name: "Nico Paz", username: "nicopaz", email: "nico@example.com", password: "supersecure123"}
]

ensure_user = fn attrs ->
	case Accounts.get_user_by_email(attrs.email) do
		nil ->
			case Accounts.register_user(attrs) do
				{:ok, user} ->
					Repo.update!(User.confirm_changeset(user))

				{:error, changeset} ->
					raise "Could not create user #{attrs.email}: #{inspect(changeset.errors)}"
			end

		user ->
			user
	end
end

users = Enum.map(user_seed, ensure_user)
users_by_username = Map.new(users, &{&1.username, &1})

request_seed = [
	%{username: "anatorres", content: "Pido oracion por paz en mi casa y sabiduria para cuidar mejor a mi familia.", is_anonymous: false, status: "active"},
	%{username: "pedrodiaz", content: "Tengo una entrevista laboral importante esta semana. Oren para que Dios abra puertas.", is_anonymous: false, status: "active"},
	%{username: "luisamora", content: "Mi mama esta en recuperacion. Pido fortaleza y una mejora completa de salud.", is_anonymous: false, status: "active"},
	%{username: "davidrios", content: "Estamos organizando un grupo de jovenes en la iglesia. Oren por unidad y constancia.", is_anonymous: false, status: "active"},
	%{username: "mariasol", content: "Necesito direccion para una decision de estudios y finanzas. Pido claridad.", is_anonymous: true, status: "active"},
	%{username: "tomasvega", content: "Por favor oren por reconciliacion en mi matrimonio y restauracion del dialogo.", is_anonymous: false, status: "active"},
	%{username: "elenacruz", content: "Estoy luchando con ansiedad. Pido calma, descanso y confianza en Dios.", is_anonymous: false, status: "active"},
	%{username: "nicopaz", content: "Queremos servir mas en nuestra comunidad. Oren por oportunidades concretas.", is_anonymous: false, status: "active"}
]

ensure_request = fn %{username: username} = attrs ->
	user = Map.fetch!(users_by_username, username)

	case Repo.get_by(PrayerRequest, user_id: user.id, content: attrs.content) do
		nil ->
			attrs = Map.drop(attrs, [:username]) |> Map.put(:user_id, user.id)
			{:ok, request} = Prayers.create_prayer_request(attrs)
			request

		request ->
			request
	end
end

requests = Enum.map(request_seed, ensure_request)
requests_by_content = Map.new(requests, &{&1.content, &1})

update_seed = [
	%{content: "Comenzamos una rutina de oracion familiar diaria. Gracias por orar.", request_content: "Pido oracion por paz en mi casa y sabiduria para cuidar mejor a mi familia."},
	%{content: "La entrevista fue bien. Ahora estoy esperando respuesta.", request_content: "Tengo una entrevista laboral importante esta semana. Oren para que Dios abra puertas."},
	%{content: "Mi mama reacciono bien al tratamiento de esta semana.", request_content: "Mi mama esta en recuperacion. Pido fortaleza y una mejora completa de salud."},
	%{content: "Ya se sumaron 9 jovenes al grupo. Seguimos avanzando.", request_content: "Estamos organizando un grupo de jovenes en la iglesia. Oren por unidad y constancia."},
	%{content: "Hable con mi pareja y tuvimos una conversacion sincera.", request_content: "Por favor oren por reconciliacion en mi matrimonio y restauracion del dialogo."}
]

Enum.each(update_seed, fn %{request_content: request_content, content: content} ->
	request = Map.fetch!(requests_by_content, request_content)

	case Repo.get_by(Update, prayer_request_id: request.id, content: content) do
		nil ->
			Prayers.create_update(%{prayer_request_id: request.id, content: content})

		_update ->
			:ok
	end
end)

testimony_seed = [
	%{request_content: "Tengo una entrevista laboral importante esta semana. Oren para que Dios abra puertas.", content: "Me confirmaron para una segunda entrevista y una propuesta inicial."},
	%{request_content: "Mi mama esta en recuperacion. Pido fortaleza y una mejora completa de salud.", content: "Los estudios salieron mejor de lo esperado. Gracias por sostenernos en oracion."}
]

Enum.each(testimony_seed, fn %{request_content: request_content, content: content} ->
	request = Map.fetch!(requests_by_content, request_content)

	case Repo.get_by(Testimony, prayer_request_id: request.id) do
		nil ->
			Prayers.create_testimony(%{prayer_request_id: request.id, content: content})

		_testimony ->
			:ok
	end
end)

follow_seed = [
	{"anatorres", "pedrodiaz"},
	{"anatorres", "luisamora"},
	{"anatorres", "elenacruz"},
	{"pedrodiaz", "anatorres"},
	{"pedrodiaz", "mariasol"},
	{"luisamora", "anatorres"},
	{"luisamora", "nicopaz"},
	{"davidrios", "anatorres"},
	{"mariasol", "elenacruz"},
	{"tomasvega", "davidrios"},
	{"elenacruz", "anatorres"},
	{"nicopaz", "tomasvega"}
]

Enum.each(follow_seed, fn {follower_username, followed_username} ->
	follower = Map.fetch!(users_by_username, follower_username)
	followed = Map.fetch!(users_by_username, followed_username)

	case Repo.get_by(Follow, follower_id: follower.id, followed_id: followed.id) do
		nil ->
			Social.follow(follower.id, followed.id)

		_follow ->
			:ok
	end
end)

pray_seed = [
	{"pedrodiaz", "Pido oracion por paz en mi casa y sabiduria para cuidar mejor a mi familia."},
	{"luisamora", "Pido oracion por paz en mi casa y sabiduria para cuidar mejor a mi familia."},
	{"mariasol", "Pido oracion por paz en mi casa y sabiduria para cuidar mejor a mi familia."},
	{"anatorres", "Tengo una entrevista laboral importante esta semana. Oren para que Dios abra puertas."},
	{"davidrios", "Tengo una entrevista laboral importante esta semana. Oren para que Dios abra puertas."},
	{"tomasvega", "Mi mama esta en recuperacion. Pido fortaleza y una mejora completa de salud."},
	{"elenacruz", "Estamos organizando un grupo de jovenes en la iglesia. Oren por unidad y constancia."},
	{"nicopaz", "Por favor oren por reconciliacion en mi matrimonio y restauracion del dialogo."},
	{"anatorres", "Estoy luchando con ansiedad. Pido calma, descanso y confianza en Dios."},
	{"luisamora", "Queremos servir mas en nuestra comunidad. Oren por oportunidades concretas."}
]

Enum.each(pray_seed, fn {username, request_content} ->
	user = Map.fetch!(users_by_username, username)
	request = Map.fetch!(requests_by_content, request_content)

	case Repo.get_by(Pray, user_id: user.id, prayer_request_id: request.id) do
		nil ->
			Interactions.create_pray(%{user_id: user.id, prayer_request_id: request.id})

		_pray ->
			:ok
	end
end)

repray_seed = [
	{"anatorres", "Mi mama esta en recuperacion. Pido fortaleza y una mejora completa de salud.", "Estoy orando por tu familia hoy. No estan solos."},
	{"pedrodiaz", "Pido oracion por paz en mi casa y sabiduria para cuidar mejor a mi familia.", "Dios les de unidad y paciencia en este tiempo."},
	{"luisamora", "Tengo una entrevista laboral importante esta semana. Oren para que Dios abra puertas.", "Orando por favor y por una buena noticia."},
	{"davidrios", "Estoy luchando con ansiedad. Pido calma, descanso y confianza en Dios.", "Que el Senor te de paz y descanso esta semana."},
	{"mariasol", "Por favor oren por reconciliacion en mi matrimonio y restauracion del dialogo.", "Orando por restauracion y un nuevo comienzo."},
	{"tomasvega", "Queremos servir mas en nuestra comunidad. Oren por oportunidades concretas.", "Hermoso deseo. Oren y avancen con valentia."},
	{"elenacruz", "Pido oracion por paz en mi casa y sabiduria para cuidar mejor a mi familia.", "Dios fortalezca tu hogar paso a paso."},
	{"nicopaz", "Estamos organizando un grupo de jovenes en la iglesia. Oren por unidad y constancia.", "Orando para que sea de bendicion para muchos."}
]

Enum.each(repray_seed, fn {username, request_content, comment} ->
	user = Map.fetch!(users_by_username, username)
	request = Map.fetch!(requests_by_content, request_content)

	case Repo.get_by(RePray, user_id: user.id, prayer_request_id: request.id) do
		nil ->
			Interactions.create_re_pray(%{user_id: user.id, prayer_request_id: request.id, comment: comment})

		_repray ->
			:ok
	end
end)

Repo.all(PrayerRequest)
|> Enum.each(fn request ->
	prays = Repo.aggregate(Ecto.assoc(request, :prays), :count)

	from(r in PrayerRequest, where: r.id == ^request.id)
	|> Repo.update_all(set: [prays_count: prays])
end)

IO.puts("Done. Fake data seeded successfully.")
