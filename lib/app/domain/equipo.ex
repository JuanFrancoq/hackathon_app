defmodule Equipo do
  @moduledoc "Entidad Equipo: representa un equipo de participantes"

  defstruct [:id, :nombre, :miembros]

  def nuevo(id, nombre, miembros) do
    %Equipo{id: id, nombre: nombre, miembros: miembros}
  end
end
