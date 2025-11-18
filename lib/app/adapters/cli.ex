defmodule HackathonApp.Adapters.CLI do
  @moduledoc """
  Interfaz de línea de comandos del sistema Hackathon.
  Permite interactuar con los módulos de usuarios, equipos, proyectos, chat y mentoría.
  """

  alias HackathonApp.Services.{
    GestionEquipos,
    GestionProyectos,
    GestionChat,
    GestionUsuarios,
    GestionMentoria
  }

  # ==========================================================
  # INICIO
  # ==========================================================
  def start() do
    {:ok, _pid} = HackathonApp.Services.GestionUsuarios.start_link(nil)
    {:ok, _pid} = HackathonApp.Services.GestionProyectos.start_link(nil)
    {:ok, _pid} = HackathonApp.Services.GestionEquipos.start_link(nil)
    {:ok, _pid} = HackathonApp.Services.GestionChat.start_link(nil)
    IO.puts("=== Sistema Proyecto ===")
    nombre_usuario = IO.gets("Ingresa tu nombre: ") |> String.trim()
    IO.puts("Bienvenido, #{nombre_usuario}. Usa /help para ver los comandos disponibles.")
    loop(nombre_usuario)
  end

  # ==========================================================
  # MENÚ PRINCIPAL
  # ==========================================================
  defp loop(nombre_usuario) do
    comando = IO.gets("> ") |> String.trim()

    case String.split(comando, " ", parts: 2) do
      ["/help"] ->
        mostrar_ayuda()
        loop(nombre_usuario)

      ["/user"] ->
        IO.puts("Entrando al módulo de usuarios...")
        user_loop(nombre_usuario)

      ["/user", "mentor"] ->
        IO.puts("Entrando al módulo de mentores...")
        mentor_loop(nombre_usuario)

      ["/user", "participante"] ->
        IO.puts("Entrando al módulo de participantes...")
        participante_loop(nombre_usuario)

      ["/teams"] ->
        IO.puts("Entrando al módulo de equipos...")
        teams_loop(nombre_usuario)

      ["/project"] ->
        IO.puts("Entrando al módulo de proyectos...")
        projects_loop(nombre_usuario)

      ["/chat", equipo_id] ->
        abrir_chat(nombre_usuario, equipo_id)
        loop(nombre_usuario)

      ["/exit"] ->
        IO.puts("Saliendo del sistema...")

      _ ->
        IO.puts("Comando no reconocido. Usa /help para ver opciones.")
        loop(nombre_usuario)
    end
  end

  # ==========================================================
  # MÓDULO DE USUARIOS
  # ==========================================================
  defp user_loop(nombre_usuario) do
    input = IO.gets("[usuarios]> ") |> String.trim()

    cond do
      input == "/listar" ->
        GestionUsuarios.listar_usuarios()
        user_loop(nombre_usuario)

      input == "/crear" ->
        crear_usuario_interactivo()
        user_loop(nombre_usuario)

      String.starts_with?(input, "/eliminar ") ->
        [_cmd, id_o_nombre] = String.split(input, " ", parts: 2)
        GestionUsuarios.eliminar_usuario(id_o_nombre)
        user_loop(nombre_usuario)

      input == "/mentor" ->
        mentor_loop(nombre_usuario)

      input == "/participante" ->
        participante_loop(nombre_usuario)

      input == "/help" ->
        mostrar_ayuda_usuarios()
        user_loop(nombre_usuario)

      input == "/salir" ->
        loop(nombre_usuario)

      true ->
        IO.puts("Comando no reconocido. Usa /help para ver opciones.")
        user_loop(nombre_usuario)
    end
  end

  defp crear_usuario_interactivo() do
    IO.puts("=== Crear usuario ===")
    id = IO.gets("ID: ") |> String.trim()
    nombre = IO.gets("Nombre: ") |> String.trim()
    rol = IO.gets("Rol (participante o mentor): ") |> String.trim() |> String.downcase()

    case rol do
      "participante" -> GestionUsuarios.crear_usuario(id, nombre, "participante")
      "mentor" -> GestionUsuarios.crear_usuario(id, nombre, "mentor")
      _ -> IO.puts("Rol inválido.")
    end
  end

  # ==========================================================
  # MÓDULO DE PARTICIPANTE
  # ==========================================================
  defp participante_loop(nombre_usuario) do
    input = IO.gets("[participante]> ") |> String.trim()

    cond do
      input == "/listar" ->
        GestionUsuarios.listar_por_rol("participante")
        participante_loop(nombre_usuario)

      String.starts_with?(input, "/join ") ->
        case String.split(input, " ") do
          ["/join", usuario_id, equipo_id] ->
            GestionUsuarios.asignar_a_equipo(usuario_id, equipo_id)
          _ ->
            IO.puts("Uso correcto: /join <usuario_id> <equipo_id>")
        end
        participante_loop(nombre_usuario)

      input == "/salir" -> user_loop(nombre_usuario)

      input == "/help" ->
        IO.puts("""
        === Comandos de Participante ===
        /listar                   → Ver todos los participantes
        /join <uid> <eid>         → Unirse a un equipo
        /salir                    → Volver al menú de usuarios
        """)
        participante_loop(nombre_usuario)

      true ->
        IO.puts("Comando no reconocido.")
        participante_loop(nombre_usuario)
    end
  end

  # ==========================================================
  # MÓDULO DE MENTOR
  # ==========================================================
  defp mentor_loop(nombre_usuario) do
    input = IO.gets("[mentor]> ") |> String.trim()

    cond do
      input == "/listar" ->
        GestionUsuarios.listar_por_rol("mentor")
        mentor_loop(nombre_usuario)

      String.starts_with?(input, "/proyectos") ->
        GestionProyectos.listar_proyectos()
        mentor_loop(nombre_usuario)

      String.starts_with?(input, "/retroalimentar ") ->
        [_cmd, proyecto_id] = String.split(input, " ")
        comentario = IO.gets("Comentario: ") |> String.trim()
        mentor = GestionUsuarios.obtener_usuario_por_nombre(nombre_usuario)
        if mentor != nil, do: GestionMentoria.registrar_mentoria(mentor.id, proyecto_id, comentario)
        mentor_loop(nombre_usuario)

      String.starts_with?(input, "/ver_proyecto ") ->
        [_cmd, proyecto_id] = String.split(input, " ")
        GestionMentoria.listar_por_proyecto(proyecto_id)
        mentor_loop(nombre_usuario)

      String.starts_with?(input, "/eliminar_retro ") ->
        [_cmd, retro_id] = String.split(input, " ")
        GestionMentoria.eliminar_mentoria(retro_id)
        mentor_loop(nombre_usuario)

      input == "/salir" -> user_loop(nombre_usuario)

      input == "/help" ->
        IO.puts("""
        === Comandos de Mentor ===
        /listar                 → Ver todos los mentores
        /proyectos              → Ver proyectos registrados
        /retroalimentar <id>    → Dar feedback a un proyecto
        /ver_proyecto <id>      → Ver retroalimentaciones de un proyecto
        /eliminar_retro <id>    → Eliminar una retroalimentación
        /salir                  → Volver al menú de usuarios
        """)
        mentor_loop(nombre_usuario)

      true ->
        IO.puts("Comando no reconocido.")
        mentor_loop(nombre_usuario)
    end
  end

  # ==========================================================
  # MÓDULO DE EQUIPOS
  # ==========================================================
  defp teams_loop(nombre_usuario) do
    input = IO.gets("[equipos]> ") |> String.trim()

    cond do
      input == "/listar" ->
        GestionEquipos.listar_equipos()
        teams_loop(nombre_usuario)

      input == "/crear" ->
        crear_equipo_interactivo()
        teams_loop(nombre_usuario)

      String.starts_with?(input, "/eliminar ") ->
        [_cmd, id] = String.split(input, " ")
        GestionEquipos.eliminar_equipo(id)
        teams_loop(nombre_usuario)

      input == "/salir" -> loop(nombre_usuario)

      input == "/help" ->
        mostrar_ayuda_teams()
        teams_loop(nombre_usuario)

      true ->
        IO.puts("Comando no reconocido.")
        teams_loop(nombre_usuario)
    end
  end

  defp crear_equipo_interactivo() do
    IO.puts("=== Crear equipo ===")
    equipo_id = IO.gets("ID del equipo: ") |> String.trim()
    nombre = IO.gets("Nombre del equipo: ") |> String.trim()
    miembros_str = IO.gets("Miembros (separados por comas): ") |> String.trim()
    miembros = miembros_str |> String.split(",") |> Enum.map(&String.trim/1)
    GestionEquipos.crear_equipo(equipo_id, nombre, miembros)
  end

  # ==========================================================
  # MÓDULO DE PROYECTOS
  # ==========================================================
  defp projects_loop(nombre_usuario) do
    input = IO.gets("[proyectos]> ") |> String.trim()

    cond do
      input == "/listar" -> GestionProyectos.listar_proyectos(); projects_loop(nombre_usuario)
      input == "/crear" -> crear_proyecto_interactivo(); projects_loop(nombre_usuario)
      String.starts_with?(input, "/actualizar ") ->
        [_cmd, id] = String.split(input, " ")
        actualizar_proyecto_interactivo(id)
        projects_loop(nombre_usuario)
      String.starts_with?(input, "/buscar_estado ") ->
        [_cmd, estado] = String.split(input, " ")
        GestionProyectos.buscar_por_estado(estado)
        projects_loop(nombre_usuario)
      String.starts_with?(input, "/buscar_categoria ") ->
        [_cmd, cat] = String.split(input, " ")
        GestionProyectos.buscar_por_categoria(cat)
        projects_loop(nombre_usuario)
      String.starts_with?(input, "/eliminar ") ->
        [_cmd, id] = String.split(input, " ")
        GestionProyectos.eliminar_proyecto(id)
        projects_loop(nombre_usuario)
      input == "/salir" -> loop(nombre_usuario)
      input == "/help" -> mostrar_ayuda_proyectos(); projects_loop(nombre_usuario)
      true -> IO.puts("Comando no reconocido."); projects_loop(nombre_usuario)
    end
  end

  defp crear_proyecto_interactivo() do
    IO.puts("=== Crear proyecto ===")
    id = IO.gets("ID: ") |> String.trim()
    equipo_id = IO.gets("Equipo ID: ") |> String.trim()
    titulo = IO.gets("Título: ") |> String.trim()
    descripcion = IO.gets("Descripción: ") |> String.trim()
    categoria = IO.gets("Categoría: ") |> String.trim()
    estado = IO.gets("Estado: ") |> String.trim()
    GestionProyectos.crear_proyecto(id, equipo_id, titulo, descripcion, categoria, estado)
  end

  defp actualizar_proyecto_interactivo(id) do
    IO.puts("=== Actualizar proyecto #{id} ===")
    nuevo_estado = IO.gets("Nuevo estado: ") |> String.trim()
    nueva_desc = IO.gets("Nueva descripción: ") |> String.trim()
    GestionProyectos.actualizar_proyecto(id, nuevo_estado, nueva_desc)
  end

  # ==========================================================
  # CHAT
  # ==========================================================
  defp abrir_chat(nombre_usuario, equipo_id) do
    IO.puts("Entrando al chat del equipo #{equipo_id}...")
    GestionChat.listar_mensajes(equipo_id)
    chat_loop(nombre_usuario, equipo_id)
  end

  defp chat_loop(nombre_usuario, equipo_id) do
    input = IO.gets("[chat equipo #{equipo_id}]> ") |> String.trim()

    cond do
      input == "/salir" -> :ok
      input == "/ver" -> GestionChat.listar_mensajes(equipo_id); chat_loop(nombre_usuario, equipo_id)
      String.starts_with?(input, "/eliminar ") ->
        [_cmd, id] = String.split(input, " ")
        GestionChat.eliminar_mensaje(id)
        chat_loop(nombre_usuario, equipo_id)
      input == "/limpiar" -> GestionChat.eliminar_todos_de_equipo(equipo_id); chat_loop(nombre_usuario, equipo_id)
      input != "" -> GestionChat.enviar_mensaje(equipo_id, nombre_usuario, input); chat_loop(nombre_usuario, equipo_id)
      true -> chat_loop(nombre_usuario, equipo_id)
    end
  end

  # ==========================================================
  # AYUDA
  # ==========================================================
  defp mostrar_ayuda() do
    IO.puts("""
    === Comandos principales ===
    /user                 → Módulo de usuarios
    /teams                → Módulo de equipos
    /project              → Módulo de proyectos
    /chat <equipo_id>     → Chat del equipo
    /exit                 → Salir
    """)
  end

  defp mostrar_ayuda_usuarios() do
    IO.puts("""
    === Comandos [usuarios] ===
    /crear          → Crear un nuevo usuario
    /listar         → Listar todos los usuarios
    /eliminar <id/nombre> → Eliminar un usuario
    /mentor         → Entrar al módulo mentor
    /participante   → Entrar al módulo participante
    /help           → Ver ayuda
    /salir          → Volver al menú principal
    """)
  end

  defp mostrar_ayuda_teams() do
    IO.puts("""
    === Comandos [equipos] ===
    /listar       → Listar equipos
    /crear        → Crear equipo
    /eliminar <id>→ Eliminar equipo
    /help         → Ver ayuda
    /salir        → Volver
    """)
  end

  defp mostrar_ayuda_proyectos() do
    IO.puts("""
    === Comandos [proyectos] ===
    /listar                 → Listar proyectos
    /crear                  → Crear proyecto
    /actualizar <id>        → Actualizar proyecto
    /eliminar <id>          → Eliminar proyecto
    /buscar_estado <estado> → Buscar proyectos por estado
    /buscar_categoria <cat> → Buscar proyectos por categoría
    /help                   → Ver ayuda
    /salir                  → Volver
    """)
  end
end
