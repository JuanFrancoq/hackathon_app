defmodule HackathonApp.Services.GestionEquipos do
  @moduledoc """
  Servicio para gestionar equipos: crear, listar y eliminar registros
  almacenados en el archivo CSV.
  """

  alias HackathonApp.Domain.Equipo
  alias HackathonApp.Adapters.RepositorioArchivo

  @archivo "equipos.csv"

  @doc """
  Crea un nuevo equipo y lo guarda en el archivo CSV.
  Si ya existe un equipo con el mismo ID, muestra una advertencia.
  """
  def crear_equipo(equipo_id, nombre, miembros) do
    equipos_actuales = RepositorioArchivo.leer_datos(@archivo)

    ya_existe =
      Enum.any?(equipos_actuales, fn linea ->
        [id | _] = String.split(linea, ",")
        id == to_string(equipo_id)
      end)

    if ya_existe do
      IO.puts("Ya existe un equipo con ID #{equipo_id}.")
    else
      equipo = Equipo.nuevo(equipo_id, nombre, miembros)

      linea =
        "#{equipo.equipo_id},#{equipo.nombre},#{Enum.join(equipo.miembros, "|")}"

      nuevas_lineas = equipos_actuales ++ [linea]
      RepositorioArchivo.guardar_datos(@archivo, nuevas_lineas)

      IO.puts("Equipo '#{nombre}' creado correctamente y guardado en #{@archivo}.")
      equipo
    end
  end

  # ==========================================================
  # Listar equipos
  # ==========================================================
  @doc """
  Muestra por consola todos los equipos guardados en el archivo CSV.
  Si una línea tiene formato incorrecto, se avisa sin detener el programa.
  """
  def listar_equipos() do
    equipos = RepositorioArchivo.leer_datos(@archivo)

    IO.puts("=== Equipos registrados ===")

    if Enum.empty?(equipos) do
      IO.puts("No hay equipos registrados.")
    else
      Enum.each(equipos, fn linea ->
        case String.split(linea, ",") do
          [equipo_id, nombre, miembros_str] ->
            miembros = String.split(miembros_str, "|")
            IO.puts("- #{nombre} [ID: #{equipo_id}] (#{Enum.join(miembros, ", ")})")

          _ ->
            IO.puts("Línea con formato inválido: #{linea}")
        end
      end)
    end
  end

  # ==========================================================
  # Eliminar un equipo por ID
  # ==========================================================
  @doc """
  Elimina un equipo del archivo CSV por su ID.
  """
  def eliminar_equipo(equipo_id) do
    equipos = RepositorioArchivo.leer_datos(@archivo)

    nuevos_equipos =
      Enum.reject(equipos, fn linea ->
        [id | _] = String.split(linea, ",")
        id == to_string(equipo_id)
      end)

    if length(nuevos_equipos) < length(equipos) do
      RepositorioArchivo.guardar_datos(@archivo, nuevos_equipos)
      IO.puts("Equipo #{equipo_id} eliminado correctamente.")
    else
      IO.puts("No se encontró el equipo con ID #{equipo_id}.")
    end
  end
end
