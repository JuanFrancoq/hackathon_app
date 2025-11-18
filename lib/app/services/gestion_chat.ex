defmodule HackathonApp.Services.GestionChat do
  @moduledoc """
  Servicio de chat: permite registrar, listar y eliminar mensajes entre miembros de un equipo.
  Los mensajes se almacenan en 'data/mensajes.csv'.
  """

  alias HackathonApp.Domain.Mensaje
  alias HackathonApp.Adapters.RepositorioArchivo

  @archivo "mensajes.csv"

  # Envía un mensaje y lo guarda en el archivo de mensajes
  def enviar_mensaje(equipo_id, usuario_nombre, contenido) do
    id = System.unique_integer([:positive])
    fecha = DateTime.utc_now() |> DateTime.to_string()

    mensaje =
      Mensaje.nuevo(id, equipo_id, usuario_nombre, contenido, fecha)

    linea =
      "#{mensaje.id},#{mensaje.equipo_id},#{mensaje.usuario_nombre},#{mensaje.contenido},#{mensaje.fecha}"

    mensajes_actuales = RepositorioArchivo.leer_datos(@archivo)
    nuevas_lineas = mensajes_actuales ++ [linea]
    RepositorioArchivo.guardar_datos(@archivo, nuevas_lineas)

    IO.puts("[#{usuario_nombre}] → equipo #{equipo_id}: '#{contenido}'")
    mensaje
  end
  # Listar mensajes enviados en el equipo, con hora, fecha y id
  def listar_mensajes(equipo_id) do
    mensajes = RepositorioArchivo.leer_datos(@archivo)

    IO.puts("\n=== Mensajes del equipo #{equipo_id} ===")

    Enum.each(mensajes, fn linea ->
      case String.split(linea, ",") do
        [id, eq_id, usuario, contenido, fecha] ->
          if eq_id == to_string(equipo_id) do
            IO.puts("[#{fecha}] (ID #{id}) #{usuario}: #{contenido}")
          end

        _ ->
          :ignore
      end
    end)
  end

  def eliminar_mensaje(id_mensaje) do
    mensajes = RepositorioArchivo.leer_datos(@archivo)

    nuevos_mensajes =
      Enum.reject(mensajes, fn linea ->
        [id_str | _] = String.split(linea, ",")
        id_str == to_string(id_mensaje)
      end)

    if length(nuevos_mensajes) < length(mensajes) do
      RepositorioArchivo.guardar_datos(@archivo, nuevos_mensajes)
      IO.puts("Mensaje #{id_mensaje} eliminado correctamente.")
    else
      IO.puts("No se encontró el mensaje con ID #{id_mensaje}.")
    end
  end

  def eliminar_todos_de_equipo(equipo_id) do
    mensajes = RepositorioArchivo.leer_datos(@archivo)

    nuevos_mensajes =
      Enum.reject(mensajes, fn linea ->
        [_, eq_id | _] = String.split(linea, ",")
        eq_id == to_string(equipo_id)
      end)

    RepositorioArchivo.guardar_datos(@archivo, nuevos_mensajes)
    IO.puts("Todos los mensajes del equipo #{equipo_id} fueron eliminados.")
  end
end
