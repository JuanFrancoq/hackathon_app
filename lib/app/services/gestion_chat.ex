defmodule HackathonApp.Services.GestionChat do
  @moduledoc """
  Servicio de chat: permite registrar, listar y eliminar mensajes entre miembros de un equipo,
  usando persistencia concurrente con Agent y archivo 'mensajes.csv'.
  """

  use Agent
  alias HackathonApp.Domain.Mensaje
  alias HackathonApp.Adapters.RepositorioArchivo

  @archivo "mensajes.csv"

  # ==========================================================
  # AGENT PARA PERSISTENCIA CONCURRENTE
  # ==========================================================
  def start_link(_) do
    Agent.start_link(fn -> RepositorioArchivo.leer_datos(@archivo) end, name: __MODULE__)
  end

  defp agregar_linea(linea) do
    Agent.update(__MODULE__, fn mensajes ->
      nuevos = mensajes ++ [linea]
      RepositorioArchivo.guardar_datos(@archivo, nuevos)
      nuevos
    end)
  end

  defp eliminar_linea(id_mensaje) do
    Agent.update(__MODULE__, fn mensajes ->
      nuevos = Enum.reject(mensajes, fn linea ->
        [id_str | _] = String.split(linea, ",")
        id_str == to_string(id_mensaje)
      end)
      RepositorioArchivo.guardar_datos(@archivo, nuevos)
      nuevos
    end)
  end

  defp eliminar_por_equipo(equipo_id) do
    Agent.update(__MODULE__, fn mensajes ->
      nuevos = Enum.reject(mensajes, fn linea ->
        [_, eq_id | _] = String.split(linea, ",")
        eq_id == to_string(equipo_id)
      end)
      RepositorioArchivo.guardar_datos(@archivo, nuevos)
      nuevos
    end)
  end

  defp obtener_mensajes(), do: Agent.get(__MODULE__, & &1)

  # ==========================================================
  # FUNCIONES PÚBLICAS DEL CHAT
  # ==========================================================
  def enviar_mensaje(equipo_id, usuario_nombre, contenido) do
    Task.start(fn ->
      id = System.unique_integer([:positive])
      fecha = DateTime.utc_now() |> DateTime.to_string()

      mensaje = Mensaje.nuevo(id, equipo_id, usuario_nombre, contenido, fecha)

      linea =
        "#{mensaje.id},#{mensaje.equipo_id},#{mensaje.usuario_nombre},#{mensaje.contenido},#{mensaje.fecha}"

      agregar_linea(linea)

      IO.puts("[#{usuario_nombre}] → equipo #{equipo_id}: '#{contenido}'")
    end)
  end

  def listar_mensajes(equipo_id) do
    mensajes = obtener_mensajes()

    IO.puts("\n=== Mensajes del equipo #{equipo_id} ===")

    Enum.each(mensajes, fn linea ->
      case String.split(linea, ",") do
        [id, eq_id, usuario, contenido, fecha] ->
          if eq_id == to_string(equipo_id) do
            IO.puts("[#{fecha}] (ID #{id}) #{usuario}: #{contenido}")
          end

        _ -> :ignore
      end
    end)
  end

  def eliminar_mensaje(id_mensaje) do
    eliminar_linea(id_mensaje)
    IO.puts("Intento de eliminación del mensaje #{id_mensaje} ejecutado.")
  end

  def eliminar_todos_de_equipo(equipo_id) do
    eliminar_por_equipo(equipo_id)
    IO.puts("Todos los mensajes del equipo #{equipo_id} fueron eliminados.")
  end
end
