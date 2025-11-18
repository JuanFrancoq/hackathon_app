defmodule HackathonApp.Domain.Proyecto do
  @moduledoc "Entidad Proyecto: representa un proyecto dentro del sistema"

  # Estructura del proyecto con sus campos principales
  defstruct [:id, :equipo_id, :titulo, :descripcion, :categoria, :estado]

  # Constructor para crear un nuevo proyecto
  def nuevo(id, equipo_id, titulo, descripcion, categoria, estado) do
    %__MODULE__{
      id: id,
      equipo_id: equipo_id,
      titulo: titulo,
      descripcion: descripcion,
      categoria: categoria,
      estado: estado
    }
  end
end
