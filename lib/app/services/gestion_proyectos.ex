defmodule HackathonApp.Services.GestionProyectos do
  @moduledoc """
  Servicio básico para gestionar proyectos: crear y listar usando un archivo CSV.
  """

  alias HackathonApp.Domain.Proyecto
  alias HackathonApp.Adapters.RepositorioArchivo

  # Crea un nuevo proyecto y lo guarda en data/proyectos.csv
  def crear_proyecto(id, equipo_id, titulo, descripcion, categoria, estado) do
    proyecto = Proyecto.nuevo(id, equipo_id, titulo, descripcion, categoria, estado)

    # Convertir el proyecto en una línea CSV
    linea =
      "#{proyecto.id},#{proyecto.equipo_id},#{proyecto.titulo},#{proyecto.descripcion},#{proyecto.categoria},#{proyecto.estado}"

    # Leer los proyectos existentes
    proyectos_actuales = RepositorioArchivo.leer_datos("proyectos.csv")

    # Agregar el nuevo proyecto al final
    nuevas_lineas = proyectos_actuales ++ [linea]

    # Guardar todos los proyectos actualizados
    RepositorioArchivo.guardar_datos("proyectos.csv", nuevas_lineas)

    IO.puts("Proyecto '#{titulo}' creado y guardado en proyectos.csv")
    proyecto
  end

  # Lista todos los proyectos registrados en el CSV
  def listar_proyectos() do
    proyectos = RepositorioArchivo.leer_datos("proyectos.csv")

    IO.puts("Proyectos registrados:")

    Enum.each(proyectos, fn linea ->
      [id, equipo_id, titulo, descripcion, categoria, estado] = String.split(linea, ",")
      IO.puts("- #{titulo} [ID: #{id}] - #{descripcion} (Equipo: #{equipo_id}, Categoria: #{categoria}, Estado: #{estado})")
    end)
  end
end
