defmodule HackathonApp.Domain.Usuario do
  # Estructura que representa un usuario dentro del sistema
  defstruct [:id, :nombre, :rol]

  # Constructor para crear un nuevo usuario
  def nuevo(id, nombre, rol) do
    %__MODULE__{
      id: id,
      nombre: nombre,
      rol: rol
    }
  end
end
