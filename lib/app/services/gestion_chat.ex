defmodule HackathonApp.Services.GestionChat do
  @moduledoc """
  Servicio básico de chat: permite registrar y listar mensajes entre miembros de un equipo.
  """

  alias HackathonApp.Domain.Mensaje
  alias HackathonApp.Adapters.RepositorioArchivo

  # Crea un nuevo mensaje y lo guarda en data/mensajes.csv
  def enviar_mensaje(equipo_id, usuario_nombre, contenido) do
    id = System.unique_integer([:positive])
    fecha = DateTime.utc_now() |> DateTime.to_string()
    mensaje = Mensaje.nuevo(id, equipo_id, usuario_nombre, contenido, fecha)

    linea = "#{mensaje.id},#{mensaje.equipo_id},#{mensaje.usuario_nombre},#{mensaje.contenido},#{mensaje.fecha}"

    mensajes_actuales = RepositorioArchivo.leer_datos("mensajes.csv")
    nuevas_lineas = mensajes_actuales ++ [linea]
    RepositorioArchivo.guardar_datos("mensajes.csv", nuevas_lineas)

    IO.puts("[#{usuario_nombre}] envió un mensaje al equipo #{equipo_id}: '#{contenido}'")
    mensaje
  end

  # Lista todos los mensajes de un equipo
  def listar_mensajes(equipo_id) do
    mensajes = RepositorioArchivo.leer_datos("mensajes.csv")

    IO.puts("Mensajes del equipo #{equipo_id}:")
    Enum.each(mensajes, fn linea ->
      [_, eq_id, usuario, contenido, fecha] = String.split(linea, ",")
      if eq_id == Integer.to_string(equipo_id) do
        IO.puts("[#{fecha}] #{usuario}: #{contenido}")
      end
    end)
  end
end
