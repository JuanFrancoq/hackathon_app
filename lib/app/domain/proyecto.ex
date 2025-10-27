defmodule Proyecto do
  @moduledoc "Entidad Proyecto: representa un proyecto dentro del sistema"

  defstruct [:id, :equipo_id, :titutlo, :descripcion, :categoria, :estado]

  def nuevo(id, equipo_id, titutlo, descripcion, categoria, estado) do
    %Proyecto{id: id, equipo_id: equipo_id, titutlo: titutlo, descripcion: descripcion, categoria: categoria, estado: estado}
  end
end
