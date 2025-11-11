defmodule HackathonApp.Adapters.CLI do
  @moduledoc """
  Interfaz de línea de comandos para interactuar con el sistema Hackathon.
  Permite ejecutar comandos como /teams, /project, /join, /chat y /help.
  """

  alias HackathonApp.Services.{GestionEquipos, GestionProyectos, GestionChat}

  # ==========================================================
  # Inicio del sistema
  # ==========================================================
  def start() do
    IO.puts("=== Bienvenido al Sistema Hackathon ===")
    nombre_usuario = IO.gets("Por favor ingresa tu nombre: ") |> String.trim()
    IO.puts("\nHola, #{nombre_usuario}! Escribe /help para ver los comandos disponibles.\n")
    loop(nombre_usuario)
  end

  # ==========================================================
  # Bucle principal
  # ==========================================================
  defp loop(nombre_usuario) do
    comando = IO.gets("> ") |> String.trim()

    case String.split(comando, " ", parts: 2) do
      ["/help"] ->
        mostrar_ayuda()
        loop(nombre_usuario)

      ["/teams"] ->
        IO.puts("\nEntrando al módulo de gestión de equipos...\n")
        teams_loop(nombre_usuario)

      ["/project"] ->
        IO.puts("\nEntrando al módulo de gestión de proyectos...\n")
        projects_loop(nombre_usuario)

      ["/chat", equipo_id] ->
        abrir_chat(nombre_usuario, equipo_id)
        loop(nombre_usuario)

      ["/exit"] ->
        IO.puts("Saliendo del sistema...")

      _ ->
        IO.puts("Comando no reconocido. Escribe /help para ver opciones.")
        loop(nombre_usuario)
    end
  end

  # ==========================================================
  # LOOP DE TEAMS
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
        [_cmd, equipo_id] = String.split(input, " ")
        GestionEquipos.eliminar_equipo(equipo_id)
        teams_loop(nombre_usuario)

      input == "/salir" ->
        IO.puts("Saliendo del módulo de equipos...\n")
        loop(nombre_usuario)

      input == "/help" ->
        mostrar_ayuda_teams()
        teams_loop(nombre_usuario)

      input == "" ->
        teams_loop(nombre_usuario)
    end
  end

  defp crear_equipo_interactivo() do
    IO.puts("\n=== Crear nuevo equipo ===")
    equipo_id = IO.gets("Ingrese un ID para el equipo: ") |> String.trim()
    nombre = IO.gets("Ingrese el nombre del equipo: ") |> String.trim()
    miembros_str = IO.gets("Ingrese los miembros (separados por comas): ") |> String.trim()

    miembros =
      miembros_str
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    GestionEquipos.crear_equipo(equipo_id, nombre, miembros)
  end

  # ==========================================================
  # LOOP DE PROYECTOS
  # ==========================================================
  defp projects_loop(nombre_usuario) do
    input = IO.gets("[proyectos]> ") |> String.trim()

    cond do
      input == "/listar" ->
        GestionProyectos.listar_proyectos()
        projects_loop(nombre_usuario)

      input == "/crear" ->
        crear_proyecto_interactivo()
        projects_loop(nombre_usuario)

      String.starts_with?(input, "/actualizar ") ->
        [_cmd, id] = String.split(input, " ")
        actualizar_proyecto_interactivo(id)
        projects_loop(nombre_usuario)

      String.starts_with?(input, "/eliminar ") ->
        [_cmd, id] = String.split(input, " ")
        GestionProyectos.eliminar_proyecto(id)
        projects_loop(nombre_usuario)

      input == "/salir" ->
        IO.puts("Saliendo del módulo de proyectos...\n")
        loop(nombre_usuario)

      input == "/help" ->
        mostrar_ayuda_proyectos()
        projects_loop(nombre_usuario)

      input == "" ->
        projects_loop(nombre_usuario)
    end
  end

  defp crear_proyecto_interactivo() do
    IO.puts("\n=== Crear nuevo proyecto ===")
    id = IO.gets("ID del proyecto: ") |> String.trim()
    equipo_id = IO.gets("ID del equipo: ") |> String.trim()
    titulo = IO.gets("Título del proyecto: ") |> String.trim()
    descripcion = IO.gets("Descripción: ") |> String.trim()
    categoria = IO.gets("Categoría: ") |> String.trim()
    estado = IO.gets("Estado inicial (opcional, por defecto 'En progreso'): ") |> String.trim()

    estado_final = if estado == "", do: "En progreso", else: estado
    GestionProyectos.crear_proyecto(id, equipo_id, titulo, descripcion, categoria, estado_final)
  end

  defp actualizar_proyecto_interactivo(id) do
    IO.puts("\n=== Actualizar proyecto #{id} ===")
    nuevo_estado = IO.gets("Nuevo estado: ") |> String.trim()
    nueva_desc = IO.gets("Nueva descripción: ") |> String.trim()
    GestionProyectos.actualizar_proyecto(id, nuevo_estado, nueva_desc)
  end

  # ==========================================================
  # CHAT LOOP
  # ==========================================================
  defp abrir_chat(nombre_usuario, equipo_id) do
    IO.puts("\nEntrando al chat del equipo #{equipo_id}...\n")
    GestionChat.listar_mensajes(equipo_id)
    chat_loop(nombre_usuario, equipo_id)
  end

  defp chat_loop(nombre_usuario, equipo_id) do
    input = IO.gets("[chat equipo #{equipo_id}]> ") |> String.trim()

    cond do
      input == "/salir" ->
        IO.puts("Saliendo del chat...\n")

      input == "/ver" ->
        GestionChat.listar_mensajes(equipo_id)
        chat_loop(nombre_usuario, equipo_id)

      String.starts_with?(input, "/eliminar ") ->
        [_cmd, id_mensaje] = String.split(input, " ")
        GestionChat.eliminar_mensaje(id_mensaje)
        chat_loop(nombre_usuario, equipo_id)

      input == "/limpiar" ->
        GestionChat.eliminar_todos_de_equipo(equipo_id)
        chat_loop(nombre_usuario, equipo_id)

      input != "" ->
        GestionChat.enviar_mensaje(equipo_id, nombre_usuario, input)
        chat_loop(nombre_usuario, equipo_id)

      true ->
        chat_loop(nombre_usuario, equipo_id)
    end
  end

  # ==========================================================
  # AYUDA GLOBAL
  # ==========================================================
  defp mostrar_ayuda() do
    IO.puts("""
    === Comandos principales ===
    /teams                → Entrar al módulo de gestión de equipos
    /project              → Entrar al módulo de gestión de proyectos
    /chat <equipo_id>     → Entrar al chat de un equipo
    /exit                 → Salir del sistema

    === Dentro de /teams ===
    /listar               → Mostrar equipos registrados
    /crear                → Crear un nuevo equipo
    /eliminar <id>        → Eliminar un equipo
    /help                 → Mostrar esta ayuda
    /salir                → Volver al menú principal

    === Dentro de /project ===
    /listar               → Mostrar proyectos registrados
    /crear                → Crear un nuevo proyecto
    /actualizar <id>      → Editar estado o descripción
    /eliminar <id>        → Eliminar un proyecto
    /help                 → Mostrar ayuda
    /salir                → Volver al menú principal

    === Dentro del chat ===
    /ver                  → Ver todos los mensajes
    /eliminar <id>        → Eliminar un mensaje
    /limpiar              → Borrar todos los mensajes del equipo
    /salir                → Salir del chat
    """)
  end

  # ==========================================================
  # AYUDA DEL MÓDULO DE PROYECTOS
  # ==========================================================
  defp mostrar_ayuda_proyectos() do
    IO.puts("""
    === Comandos disponibles en [proyectos] ===
    /listar               → Mostrar todos los proyectos
    /crear                → Crear un nuevo proyecto
    /actualizar <id>      → Editar un proyecto
    /eliminar <id>        → Eliminar un proyecto existente
    /help                 → Mostrar esta ayuda
    /salir                → Volver al menú principal
    """)
  end

  # ==========================================================
  # AYUDA DEL MÓDULO DE TEAMS
  # ==========================================================
  defp mostrar_ayuda_teams() do
    IO.puts("""
    === Comandos disponibles en [equipos] ===
    /listar               → Mostrar todos los equipos
    /crear                → Crear un nuevo equipo
    /eliminar <id>        → Eliminar un equipo existente
    /help                 → Mostrar esta ayuda
    /salir                → Volver al menú principal
    """)
  end
end
