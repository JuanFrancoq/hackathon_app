defmodule Usuario do
  @moduledoc "Entidad Usuario: puede ser participante o mentos"

  defstruct [:id, :nombre, :email, :rol]

  def nuevo(id, nombre, email, rol) do
    %Usuario{id: id, nombre: nombre, email: email, rol: rol}
  end
end
