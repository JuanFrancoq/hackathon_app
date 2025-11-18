defmodule HackathonApp.Services.GestionEquipos do
  @moduledoc """
  Servicio para gestionar equipos: crear, listar, eliminar y agregar miembros.
  Implementa persistencia concurrente con Agent y archivo 'equipos.csv'.
  """

  use Agent
  alias HackathonApp.Domain.Equipo
  alias HackathonApp.Adapters.RepositorioArchivo
  alias HackathonApp.Services.GestionUsuarios

  @archivo "equipos.csv"

  # ==========================================================
  # AGENT PARA PERSISTENCIA CONCURRENTE
  # ==========================================================
  def start_link(_) do
    Agent.start_link(fn ->
      case RepositorioArchivo.leer_datos(@archivo) do
        {:ok, datos} -> datos
        {:error, _razon} -> []   # inicia vacío si falla
        datos when is_list(datos) -> datos  # en caso de que devuelva directamente la lista
      end
    end, name: __MODULE__)
  end

  # ==========================================================
  # Crear equipo
  # ==========================================================
  def crear_equipo(equipo_id, nombre, miembros) do
    Agent.get_and_update(__MODULE__, fn equipos ->
      # Validar que los miembros existen
      miembros_validos =
        Enum.filter(miembros, fn nombre_usuario ->
          GestionUsuarios.obtener_usuario_por_nombre(nombre_usuario) != nil
        end)

      existe = Enum.any?(equipos, fn linea ->
        [id | _] = String.split(linea, ",")
        id == to_string(equipo_id)
      end)

      if existe do
        IO.puts("Ya existe un equipo con ID #{equipo_id}.")
        {nil, equipos}
      else
        equipo = Equipo.nuevo(equipo_id, nombre, miembros_validos)
        linea = "#{equipo.equipo_id},#{equipo.nombre},#{Enum.join(equipo.miembros, "|")}"
        RepositorioArchivo.guardar_datos(@archivo, equipos ++ [linea])
        IO.puts("Equipo '#{nombre}' creado correctamente con miembros válidos: #{Enum.join(miembros_validos, ", ")}")
        {equipo, equipos ++ [linea]}
      end
    end)
  end

  # ==========================================================
  # Listar equipos
  # ==========================================================
  def listar_equipos() do
    equipos = Agent.get(__MODULE__, & &1)
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

  # ==========================================================
  # Eliminar equipo
  # ==========================================================
  def eliminar_equipo(equipo_id) do
    Agent.get_and_update(__MODULE__, fn equipos ->
      nuevos = Enum.reject(equipos, fn linea ->
        [id | _] = String.split(linea, ",")
        id == to_string(equipo_id)
      end)

      if length(nuevos) < length(equipos) do
        RepositorioArchivo.guardar_datos(@archivo, nuevos)
        IO.puts("Equipo #{equipo_id} eliminado.")
      else
        IO.puts("No se encontró el equipo con ID #{equipo_id}.")
      end

      { :ok, nuevos }
    end)
  end

  # ==========================================================
  # Agregar miembro a equipo
  # ==========================================================
  def agregar_miembro_a_equipo(equipo_id, nombre_usuario) do
    Agent.get_and_update(__MODULE__, fn equipos ->
      case Enum.find(equipos, fn linea ->
             [id | _] = String.split(linea, ",")
             id == to_string(equipo_id)
           end) do
        nil ->
          IO.puts("No se encontró un equipo con ID #{equipo_id}.")
          { :error, equipos }

        linea ->
          # Validar que el usuario exista
          if GestionUsuarios.obtener_usuario_por_nombre(nombre_usuario) == nil do
            IO.puts("No se puede agregar '#{nombre_usuario}': usuario no existe.")
            { :error, equipos }
          else
            [id, nombre_equipo, miembros_str] = String.split(linea, ",")
            miembros = String.split(miembros_str, "|")

            if nombre_usuario in miembros do
              IO.puts("El usuario #{nombre_usuario} ya pertenece al equipo #{nombre_equipo}.")
              { :error, equipos }
            else
              nuevos_miembros = miembros ++ [nombre_usuario]
              nueva_linea = "#{id},#{nombre_equipo},#{Enum.join(nuevos_miembros, "|")}"
              nuevos_datos = Enum.map(equipos, fn l -> if l == linea, do: nueva_linea, else: l end)
              RepositorioArchivo.guardar_datos(@archivo, nuevos_datos)
              IO.puts("#{nombre_usuario} se unió al equipo #{nombre_equipo}.")
              { :ok, nuevos_datos }
            end
          end
      end
    end)
  end
end
