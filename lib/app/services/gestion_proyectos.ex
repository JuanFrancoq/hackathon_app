defmodule HackathonApp.Services.GestionProyectos do
  @moduledoc """
  Servicio para gestionar proyectos: crear, listar, actualizar y eliminar proyectos
  almacenados en el archivo proyectos.csv.
  """

  alias HackathonApp.Domain.Proyecto
  alias HackathonApp.Adapters.RepositorioArchivo

  @archivo "proyectos.csv"

  def crear_proyecto(id, equipo_id, titulo, descripcion, categoria, estado \\ "En progreso") do
    proyectos_actuales = RepositorioArchivo.leer_datos(@archivo)

    ya_existe =
      Enum.any?(proyectos_actuales, fn linea ->
        [pid | _] = String.split(linea, ",")
        pid == to_string(id)
      end)

    if ya_existe do
      IO.puts("Ya existe un proyecto con ID #{id}.")
    else
      proyecto = Proyecto.nuevo(id, equipo_id, titulo, descripcion, categoria, estado)

      linea =
        "#{proyecto.id},#{proyecto.equipo_id},#{proyecto.titulo},#{proyecto.descripcion},#{proyecto.categoria},#{proyecto.estado}"

      nuevas_lineas = proyectos_actuales ++ [linea]
      RepositorioArchivo.guardar_datos(@archivo, nuevas_lineas)

      IO.puts("Proyecto '#{titulo}' creado correctamente y guardado en #{@archivo}.")
      proyecto
    end
  end

  def listar_proyectos() do
    proyectos = RepositorioArchivo.leer_datos(@archivo)

    IO.puts("=== Proyectos registrados ===")

    if Enum.empty?(proyectos) do
      IO.puts("No hay proyectos registrados.")
    else
      Enum.each(proyectos, fn linea ->
        case String.split(linea, ",") do
          [id, equipo_id, titulo, descripcion, categoria, estado] ->
            IO.puts("- #{titulo} [ID: #{id}]")
            IO.puts("Descripción: #{descripcion}")
            IO.puts("Equipo: #{equipo_id} | Categoría: #{categoria} | Estado: #{estado}\n")
          _ ->
            IO.puts("Línea inválida: #{linea}")
        end
      end)
    end
  end

  def actualizar_proyecto(id, nuevo_estado, nueva_descripcion) do
    proyectos = RepositorioArchivo.leer_datos(@archivo)

    nuevos_proyectos =
      Enum.map(proyectos, fn linea ->
        case String.split(linea, ",") do
          [pid, equipo_id, titulo, _desc, categoria, _estado] when pid == id ->
            "#{pid},#{equipo_id},#{titulo},#{nueva_descripcion},#{categoria},#{nuevo_estado}"
          _ ->
            linea
        end
      end)

    RepositorioArchivo.guardar_datos(@archivo, nuevos_proyectos)
    IO.puts("Proyecto #{id} actualizado correctamente.")
  end

  def eliminar_proyecto(id) do
    proyectos = RepositorioArchivo.leer_datos(@archivo)

    nuevos =
      Enum.reject(proyectos, fn linea ->
        String.starts_with?(linea, "#{id},")
      end)

    if length(nuevos) < length(proyectos) do
      RepositorioArchivo.guardar_datos(@archivo, nuevos)
      IO.puts("Proyecto #{id} eliminado correctamente.")
    else
      IO.puts("No se encontró el proyecto con ID #{id}.")
    end
  end
end
