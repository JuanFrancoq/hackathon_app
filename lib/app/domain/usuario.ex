defmodule HackathonApp.Domain.Usuario do
  defstruct [:id, :nombre, :rol]

  def nuevo(id, nombre, rol) do
    %__MODULE__{
      id: id,
      nombre: nombre,
      rol: rol
    }
  end
end
