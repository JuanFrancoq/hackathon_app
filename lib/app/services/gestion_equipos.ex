defmodule HackathonApp.Services.GestionEquipos do
  @moduledoc """
  Servicio para gestionar equipos: crear, listar, eliminar y unir miembros.
  Los datos se almacenan en el archivo CSV `equipos.csv`.
  """

  alias HackathonApp.Domain.Equipo
  alias HackathonApp.Adapters.RepositorioArchivo

  @archivo "equipos.csv"

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

      linea = "#{equipo.equipo_id},#{equipo.nombre},#{Enum.join(equipo.miembros, "|")}"

      nuevas_lineas = equipos_actuales ++ [linea]
      RepositorioArchivo.guardar_datos(@archivo, nuevas_lineas)

      IO.puts("Equipo '#{nombre}' creado correctamente y guardado en #{@archivo}.")
      equipo
    end
  end

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

  @doc """
  Agrega un nuevo miembro (usuario) a un equipo existente en el archivo CSV.
  """
  def agregar_miembro_a_equipo(equipo_id, nombre_usuario) do
    equipos = RepositorioArchivo.leer_datos(@archivo)

    case Enum.find(equipos, fn linea ->
           [id | _] = String.split(linea, ",")
           id == to_string(equipo_id)
         end) do
      nil ->
        IO.puts("No se encontró un equipo con ID #{equipo_id}.")

      linea ->
        [id, nombre_equipo, miembros_str] = String.split(linea, ",")
        miembros = String.split(miembros_str, "|")

        if nombre_usuario in miembros do
          IO.puts("El usuario #{nombre_usuario} ya pertenece al equipo #{nombre_equipo}.")
        else
          nuevos_miembros = miembros ++ [nombre_usuario]
          nueva_linea = "#{id},#{nombre_equipo},#{Enum.join(nuevos_miembros, "|")}"

          nuevos_datos =
            Enum.map(equipos, fn l ->
              if l == linea, do: nueva_linea, else: l
            end)

          RepositorioArchivo.guardar_datos(@archivo, nuevos_datos)

          IO.puts("#{nombre_usuario} se unió al equipo #{nombre_equipo} correctamente.")
        end
    end
  end
end
