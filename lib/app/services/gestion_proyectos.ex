defmodule HackathonApp.Services.GestionProyectos do
  @moduledoc """
  Servicio para gestionar proyectos: crear, listar, actualizar, eliminar y buscar.
  Los datos se almacenan en 'proyectos.csv'.
  """

  alias HackathonApp.Domain.Proyecto
  alias HackathonApp.Adapters.RepositorioArchivo

  @archivo "proyectos.csv"

  # ==========================================================
  # Crear un proyecto
  # ==========================================================
  def crear_proyecto(id, equipo_id, titulo, descripcion, categoria, estado \\ "En progreso") do
    proyectos = RepositorioArchivo.leer_datos(@archivo)

    existe =
      Enum.any?(proyectos, fn linea ->
        [pid | _] = String.split(linea, ",")
        pid == to_string(id)
      end)

    if existe do
      IO.puts("⚠️ Ya existe un proyecto con ID #{id}.")
    else
      proyecto = Proyecto.nuevo(id, equipo_id, titulo, descripcion, categoria, estado)
      linea = "#{proyecto.id},#{proyecto.equipo_id},#{proyecto.titulo},#{proyecto.descripcion},#{proyecto.categoria},#{proyecto.estado}"
      RepositorioArchivo.guardar_datos(@archivo, proyectos ++ [linea])
      IO.puts("✅ Proyecto '#{titulo}' creado correctamente.")
      proyecto
    end
  end

  # ==========================================================
  # Listar proyectos
  # ==========================================================
  def listar_proyectos() do
    proyectos = RepositorioArchivo.leer_datos(@archivo)

    IO.puts("=== Proyectos registrados ===")

    if Enum.empty?(proyectos) do
      IO.puts("No hay proyectos registrados.")
    else
      Enum.each(proyectos, fn linea ->
        case String.split(linea, ",") do
          [id, equipo_id, titulo, descripcion, categoria, estado] ->
            IO.puts("""
            - #{titulo} [ID: #{id}]
              Descripción: #{descripcion}
              Equipo: #{equipo_id}
              Categoría: #{categoria}
              Estado: #{estado}
            """)

          _ ->
            IO.puts("Línea inválida: #{linea}")
        end
      end)
    end
  end

  # ==========================================================
  # Actualizar estado o descripción
  # ==========================================================
  def actualizar_proyecto(id, nuevo_estado, nueva_descripcion) do
    proyectos = RepositorioArchivo.leer_datos(@archivo)

    nuevos =
      Enum.map(proyectos, fn linea ->
        case String.split(linea, ",") do
          [pid, equipo_id, titulo, _desc, categoria, _estado] when pid == id ->
            "#{pid},#{equipo_id},#{titulo},#{nueva_descripcion},#{categoria},#{nuevo_estado}"

          _ ->
            linea
        end
      end)

    RepositorioArchivo.guardar_datos(@archivo, nuevos)
    IO.puts("✅ Proyecto #{id} actualizado.")
  end

  # ==========================================================
  # Eliminar proyecto
  # ==========================================================
  def eliminar_proyecto(id) do
    proyectos = RepositorioArchivo.leer_datos(@archivo)

    nuevos =
      Enum.reject(proyectos, fn linea ->
        String.starts_with?(linea, "#{id},")
      end)

    if length(nuevos) < length(proyectos) do
      RepositorioArchivo.guardar_datos(@archivo, nuevos)
      IO.puts("🗑️ Proyecto #{id} eliminado.")
    else
      IO.puts("⚠️ No se encontró el proyecto con ID #{id}.")
    end
  end

  # ==========================================================
  # Buscar proyectos por estado
  # ==========================================================
  def buscar_por_estado(estado_buscado) do
    proyectos = RepositorioArchivo.leer_datos(@archivo)

    filtrados =
      Enum.filter(proyectos, fn linea ->
        [_id, _equipo_id, _titulo, _desc, _cat, estado] = String.split(linea, ",")
        String.downcase(estado) == String.downcase(estado_buscado)
      end)

    IO.puts("=== Proyectos con estado '#{estado_buscado}' ===")

    if Enum.empty?(filtrados) do
      IO.puts("No hay proyectos con ese estado.")
    else
      Enum.each(filtrados, fn linea ->
        [id, equipo_id, titulo, descripcion, categoria, estado] = String.split(linea, ",")
        IO.puts("""
        - #{titulo} [ID: #{id}]
          Descripción: #{descripcion}
          Equipo: #{equipo_id}
          Categoría: #{categoria}
          Estado: #{estado}
        """)
      end)
    end
  end

  # ==========================================================
  # Buscar proyectos por categoría
  # ==========================================================
  def buscar_por_categoria(categoria_buscada) do
    proyectos = RepositorioArchivo.leer_datos(@archivo)

    filtrados =
      Enum.filter(proyectos, fn linea ->
        [_id, _equipo_id, _titulo, _desc, categoria, _estado] = String.split(linea, ",")
        String.downcase(categoria) == String.downcase(categoria_buscada)
      end)

    IO.puts("=== Proyectos en categoría '#{categoria_buscada}' ===")

    if Enum.empty?(filtrados) do
      IO.puts("No hay proyectos en esa categoría.")
    else
      Enum.each(filtrados, fn linea ->
        [id, equipo_id, titulo, descripcion, categoria, estado] = String.split(linea, ",")
        IO.puts("""
        - #{titulo} [ID: #{id}]
          Descripción: #{descripcion}
          Equipo: #{equipo_id}
          Categoría: #{categoria}
          Estado: #{estado}
        """)
      end)
    end
  end
end
