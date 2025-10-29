defmodule HackathonApp.Domain.Mensaje do
  @moduledoc "Entidad Mensaje: representa un mensaje en el chat de un equipo"

  defstruct [:id, :equipo_id, :usuario_nombre, :contenido, :fecha]

  def nuevo(id, equipo_id, usuario_nombre, contenido, fecha) do
    %__MODULE__{
      id: id,
      equipo_id: equipo_id,
      usuario_nombre: usuario_nombre,
      contenido: contenido,
      fecha: fecha
    }
  end
end
