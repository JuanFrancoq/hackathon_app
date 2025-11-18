defmodule HackathonApp.Services.GestionProyectos do
  @moduledoc """
  Servicio para gestionar proyectos: crear, listar, actualizar, eliminar y buscar.
  Soporta persistencia híbrida: local y concurrente mediante Agent.
  """

  use Agent
  alias HackathonApp.Domain.Proyecto
  alias HackathonApp.Adapters.RepositorioArchivo

  @archivo "proyectos.csv"

  # ==========================================================
  # AGENT PARA PERSISTENCIA CONCURRENTE
  # ==========================================================
  def start_link(_) do
    Agent.start_link(fn ->
      case RepositorioArchivo.leer_datos(@archivo) do
        {:ok, datos} -> datos
        {:error, _razon} -> []
        datos when is_list(datos) -> datos
      end
    end, name: __MODULE__)
  end

  # ==========================================================
  # FUNCIONES INTERNAS PARA AGENT
  # ==========================================================
  defp guardar_linea(linea) do
    Agent.update(__MODULE__, fn proyectos ->
      nuevos = proyectos ++ [linea]
      RepositorioArchivo.guardar_datos(@archivo, nuevos)
      nuevos
    end)
  end

  defp eliminar_linea(id_proyecto) do
    Agent.update(__MODULE__, fn proyectos ->
      nuevos =
        Enum.reject(proyectos, fn linea ->
          [pid | _] = String.split(linea, ",")
          pid == id_proyecto
        end)

      RepositorioArchivo.guardar_datos(@archivo, nuevos)
      nuevos
    end)
  end

  defp actualizar_linea(id, nuevo_linea) do
    Agent.update(__MODULE__, fn proyectos ->
      nuevos =
        Enum.map(proyectos, fn linea ->
          [pid | _] = String.split(linea, ",")
          if pid == id, do: nuevo_linea, else: linea
        end)

      RepositorioArchivo.guardar_datos(@archivo, nuevos)
      nuevos
    end)
  end

  defp obtener_todos(), do: Agent.get(__MODULE__, & &1)

  # ==========================================================
  # CREAR PROYECTO
  # ==========================================================
  def crear_proyecto(id, equipo_id, titulo, descripcion, categoria, estado \\ "En progreso") do
    proyectos = obtener_todos()

    existe =
      Enum.any?(proyectos, fn linea ->
        [pid | _] = String.split(linea, ",")
        pid == id
      end)

    if existe do
      IO.puts("Ya existe un proyecto con ID #{id}.")
    else
      proyecto = Proyecto.nuevo(id, equipo_id, titulo, descripcion, categoria, estado)
      linea =
        "#{proyecto.id},#{proyecto.equipo_id},#{proyecto.titulo},#{proyecto.descripcion},#{proyecto.categoria},#{proyecto.estado}"

      guardar_linea(linea)
      IO.puts("Proyecto '#{titulo}' creado correctamente.")
      proyecto
    end
  end

  # ==========================================================
  # LISTAR PROYECTOS
  # ==========================================================
  def listar_proyectos() do
    proyectos = obtener_todos()
    IO.puts("=== Proyectos registrados ===")

    if Enum.empty?(proyectos) do
      IO.puts("No hay proyectos registrados.")
    else
      Enum.each(proyectos, &mostrar_proyecto/1)
    end
  end

  # ==========================================================
  # ACTUALIZAR PROYECTO
  # ==========================================================
  def actualizar_proyecto(id, nuevo_estado, nueva_descripcion) do
    proyectos = obtener_todos()

    nuevo_linea =
      Enum.find_value(proyectos, fn linea ->
        [pid, equipo_id, titulo, _desc, categoria, _estado] = String.split(linea, ",")
        if pid == id do
          "#{pid},#{equipo_id},#{titulo},#{nueva_descripcion},#{categoria},#{nuevo_estado}"
        else
          nil
        end
      end)

    if nuevo_linea do
      actualizar_linea(id, nuevo_linea)
      IO.puts("Proyecto #{id} actualizado.")
    else
      IO.puts("No se encontró el proyecto con ID #{id}.")
    end
  end

  # ==========================================================
  # ELIMINAR PROYECTO
  # ==========================================================
  def eliminar_proyecto(id) do
    proyectos = obtener_todos()
    if Enum.any?(proyectos, fn linea -> [pid | _] = String.split(linea, ","); pid == id end) do
      eliminar_linea(id)
      IO.puts("Proyecto #{id} eliminado.")
    else
      IO.puts("No se encontró el proyecto con ID #{id}.")
    end
  end

  # ==========================================================
  # BUSCAR PROYECTOS POR ESTADO
  # ==========================================================
  def buscar_por_estado(estado_buscado) do
    proyectos = obtener_todos()
    filtrados =
      Enum.filter(proyectos, fn linea ->
        [_id, _equipo_id, _titulo, _desc, _cat, estado] = String.split(linea, ",")
        String.downcase(estado) == String.downcase(estado_buscado)
      end)

    IO.puts("=== Proyectos con estado '#{estado_buscado}' ===")
    if Enum.empty?(filtrados), do: IO.puts("No hay proyectos con ese estado."), else: Enum.each(filtrados, &mostrar_proyecto/1)
  end

  # ==========================================================
  # BUSCAR PROYECTOS POR CATEGORÍA
  # ==========================================================
  def buscar_por_categoria(categoria_buscada) do
    proyectos = obtener_todos()
    filtrados =
      Enum.filter(proyectos, fn linea ->
        [_id, _equipo_id, _titulo, _desc, categoria, _estado] = String.split(linea, ",")
        String.downcase(categoria) == String.downcase(categoria_buscada)
      end)

    IO.puts("=== Proyectos en categoría '#{categoria_buscada}' ===")
    if Enum.empty?(filtrados), do: IO.puts("No hay proyectos en esa categoría."), else: Enum.each(filtrados, &mostrar_proyecto/1)
  end

  # ==========================================================
  # FUNCIONES AUXILIARES
  # ==========================================================
  defp mostrar_proyecto(linea) do
    case String.split(linea, ",") do
      [id, equipo_id, titulo, descripcion, categoria, estado] ->
        IO.puts("""
        - #{titulo} [ID: #{id}]
          Descripción: #{descripcion}
          Equipo: #{equipo_id}
          Categoría: #{categoria}
          Estado: #{estado}
        """)

      _ -> :ignore
    end
  end
end
