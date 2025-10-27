defmodule HackathonApp.Services.GestionEquipos do
  @moduledoc """
  Servicio para gestionar equipos: crear, listar y guardar en archivo CSV.
  """

  alias HackathonApp.Domain.Equipo
  alias HackathonApp.Adapters.RepositorioArchivo

  # Crea un nuevo equipo y lo guarda en el archivo CSV
  def crear_equipo(id, nombre, miembros) do
    equipo = Equipo.nuevo(id, nombre, miembros)

    # Convertir el equipo en una línea CSV simple
    linea = "#{equipo.id},#{equipo.nombre},#{Enum.join(equipo.miembros, "|")}"

    # Leer los datos existentes
    equipos_actuales = RepositorioArchivo.leer_datos("equipos.csv")

    # Agregar la nueva línea al final
    nuevas_lineas = equipos_actuales ++ [linea]

    # Guardar todos los equipos actualizados
    RepositorioArchivo.guardar_datos("equipos.csv", nuevas_lineas)

    IO.puts("Equipo '#{nombre}' creado y guardado en equipos.csv")
    equipo
  end

  # Muestra por consola los equipos leídos del CSV
  def listar_equipos() do
    equipos = RepositorioArchivo.leer_datos("equipos.csv")

    IO.puts("Equipos registrados:")

    Enum.each(equipos, fn linea ->
      [id, nombre, miembros_str] = String.split(linea, ",")
      miembros = String.split(miembros_str, "|")
      IO.puts("- #{nombre} (#{Enum.join(miembros, ", ")}) [ID: #{id}]")
    end)
  end
end
