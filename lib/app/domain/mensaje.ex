defmodule Mensaje do
  @moduledoc """
  Entidad Mensaje: representa un mensaje enviado entre usuarios
  """

  defstruct [:id, :equipo_if, :usuario_id, :texto, :timestamp]

  def nuevo(id, equipo_if, usuario_id, texto, timestamp) do
    %Mensaje{id: id, equipo_if: equipo_if, usuario_id: usuario_id, texto: texto, timestamp: timestamp}
  end
end
