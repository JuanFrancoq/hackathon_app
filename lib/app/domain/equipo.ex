defmodule HackathonApp.Domain.Equipo do
  defstruct [:equipo_id, :nombre, :miembros]

  def nuevo(equipo_id, nombre, miembros) do
    %__MODULE__{
      equipo_id: equipo_id,
      nombre: nombre,
      miembros: miembros
    }
  end
end
