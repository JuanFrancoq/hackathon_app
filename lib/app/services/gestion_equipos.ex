defmodule App.Services.GestionEquipos do
  alias App.Domain.Equipo

  # Crea un nuevo equipo
  def crear_equipo(id, nombre, miembros) do
    Equipo.nuevo(id, nombre, miembros)
  end

  # Recibe una lista de equipos y los muestra por consola
  def listar_equipos(equipos) do
    IO.puts("Equipos registrados:")
    Enum.each(equipos, fn equipo ->
      IO.puts("- #{equipo.nombre} (#{Enum.join(equipo.miembros, ", ")})")
    end)
  end
end
