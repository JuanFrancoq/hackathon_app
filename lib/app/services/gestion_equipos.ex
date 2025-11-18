defmodule HackathonApp.Services.GestionEquipos do
  @moduledoc """
  Servicio para gestionar equipos: crear, listar, eliminar y agregar miembros.
  Los datos se almacenan en el archivo 'equipos.csv'.
  """

  alias HackathonApp.Domain.Equipo
  alias HackathonApp.Adapters.RepositorioArchivo

  @archivo "equipos.csv"

  # Crea un equipo nuevo con su ID, nombre y lista inicial de miembros
  def crear_equipo(equipo_id, nombre, miembros) do
    equipos_actuales = RepositorioArchivo.leer_datos(@archivo)

    existe =
      Enum.any?(equipos_actuales, fn linea ->
        [id | _] = String.split(linea, ",")
        id == to_string(equipo_id)
      end)

    if existe do
      IO.puts("Ya existe un equipo con ID #{equipo_id}.")
    else
      equipo = Equipo.nuevo(equipo_id, nombre, miembros)
      linea = "#{equipo.equipo_id},#{equipo.nombre},#{Enum.join(equipo.miembros, "|")}"
      RepositorioArchivo.guardar_datos(@archivo, equipos_actuales ++ [linea])
      IO.puts("Equipo '#{nombre}' creado correctamente.")
      equipo
    end
  end

  # Lista todos los equipos registrados en el archivo
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
            IO.puts("Línea inválida: #{linea}")
        end
      end)
    end
  end

  # Elimina un equipo según su ID
  def eliminar_equipo(equipo_id) do
    equipos = RepositorioArchivo.leer_datos(@archivo)

    nuevos =
      Enum.reject(equipos, fn linea ->
        [id | _] = String.split(linea, ",")
        id == to_string(equipo_id)
      end)

    if length(nuevos) < length(equipos) do
      RepositorioArchivo.guardar_datos(@archivo, nuevos)
      IO.puts("Equipo #{equipo_id} eliminado.")
    else
      IO.puts("No se encontró el equipo con ID #{equipo_id}.")
    end
  end

  # Agrega un miembro nuevo al equipo si no pertenece actualmente
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
          IO.puts("#{nombre_usuario} se unió al equipo #{nombre_equipo}.")
        end
    end
  end
end
