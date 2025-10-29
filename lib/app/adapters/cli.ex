defmodule HackathonApp.Adapters.CLI do
  @moduledoc """
  Interfaz de línea de comandos para interactuar con el sistema Hackathon.
  Permite ejecutar comandos como /teams, /project, /join, /chat y /help.
  """

  alias HackathonApp.Services.{GestionEquipos, GestionProyectos, GestionUsuarios, GestionChat}

  def start() do
    IO.puts("=== Bienvenido al Sistema  ===")
    IO.puts("Escribe /help para ver los comandos disponibles.\n")

    loop()
  end

  # Bucle principal que lee comandos del usuario
  defp loop() do
    comando = IO.gets("> ") |> String.trim()

    case String.split(comando, " ") do
      ["/help"] ->
        mostrar_ayuda()

      ["/teams"] ->
        GestionEquipos.listar_equipos()

      ["/project", nombre_equipo] ->
        IO.puts("Mostrando proyecto del equipo: #{nombre_equipo}")
        GestionProyectos.listar_proyectos()

      ["/join", nombre_equipo] ->
        IO.puts("Te uniste al equipo: #{nombre_equipo}")

      ["/chat", equipo_id] ->
        GestionChat.listar_mensajes(String.to_integer(equipo_id))

      ["/exit"] ->
        IO.puts("Saliendo del sistema...")
        :ok

      _ ->
        IO.puts("Comando no reconocido. Escribe /help para ver opciones.")
    end

    if comando != "/exit", do: loop()
  end

  defp mostrar_ayuda() do
    IO.puts("""
    === Comandos disponibles ===
    /teams                → Listar equipos registrados
    /project nombre_equipo → Mostrar información del proyecto
    /join equipo          → Unirse a un equipo
    /chat equipo_id       → Ver mensajes del chat de un equipo
    /help                 → Mostrar esta ayuda
    /exit                 → Salir del sistema
    """)
  end
end
