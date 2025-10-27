defmodule HackathonApp.Domain.Equipo do
  defstruct [:id, :nombre, :miembros]

  def nuevo(id, nombre, miembros) do
    %__MODULE__{
      id: id,
      nombre: nombre,
      miembros: miembros
    }
  end
end
