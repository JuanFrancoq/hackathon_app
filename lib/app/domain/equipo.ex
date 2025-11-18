defmodule HackathonApp.Domain.Equipo do
  @moduledoc """
  Estructura básica que representa un equipo dentro del sistema.
  Incluye ID, nombre y la lista de miembros.
  """

  # Campos del struct del equipo
  defstruct [:equipo_id, :nombre, :miembros]

  # Crear una nueva instancia de un equipo
  def nuevo(equipo_id, nombre, miembros) do
    %__MODULE__{
      equipo_id: equipo_id,
      nombre: nombre,
      miembros: miembros
    }
  end
end
