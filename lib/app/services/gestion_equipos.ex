defmodule HackathonApp.Services.GestionEquipos do
  @moduledoc """
  Gestión de equipos: crear, listar, eliminar y agregar miembros.
  Puede trabajar de manera local (archivo) o concurrente (Agent).
  """

  use Agent
  alias HackathonApp.Domain.Equipo
  alias HackathonApp.Adapters.RepositorioArchivo

  @archivo "equipos.csv"

  # ==========================================================
  # START LINK (para servidor)
  # ==========================================================
  def start_link(_) do
    Agent.start_link(fn ->
      case RepositorioArchivo.leer_datos(@archivo) do
        {:ok, datos} -> datos
        {:error, _} -> []
        datos when is_list(datos) -> datos
      end
    end, name: __MODULE__)
  end

  # ==========================================================
  # HELPER para persistencia híbrida
  # ==========================================================
  defp guardar_datos_concurrente(nuevos_datos) do
    if Process.whereis(__MODULE__) do
      Agent.update(__MODULE__, fn _ ->
        RepositorioArchivo.guardar_datos(@archivo, nuevos_datos)
        nuevos_datos
      end)
    else
      RepositorioArchivo.guardar_datos(@archivo, nuevos_datos)
    end
  end

  defp leer_datos() do
    if Process.whereis(__MODULE__) do
      Agent.get(__MODULE__, & &1)
    else
      case RepositorioArchivo.leer_datos(@archivo) do
        {:ok, datos} -> datos
        datos when is_list(datos) -> datos
        _ -> []
      end
    end
  end

  # ==========================================================
  # Crear equipo
  # ==========================================================
  def crear_equipo(equipo_id, nombre, miembros) do
    equipos_actuales = leer_datos()

    existe =
      Enum.any?(equipos_actuales, fn linea ->
        [id | _] = String.split(linea, ",")
        id == to_string(equipo_id)
      end)

    if existe do
      IO.puts("Ya existe un equipo con ID #{equipo_id}.")
    else
      # Filtrar solo miembros existentes
      miembros_validos =
        Enum.filter(miembros, fn m ->
          HackathonApp.Services.GestionUsuarios.obtener_usuario_por_nombre(m) != nil
        end)

      equipo = %Equipo{
        equipo_id: equipo_id,
        nombre: nombre,
        miembros: miembros_validos
      }

      nueva_linea = "#{equipo.equipo_id},#{equipo.nombre},#{Enum.join(equipo.miembros, "|")}"
      guardar_datos_concurrente(equipos_actuales ++ [nueva_linea])

      IO.puts(
        "Equipo '#{nombre}' creado correctamente con miembros válidos: #{Enum.join(miembros_validos, ", ")}"
      )

      equipo
    end
  end

  # ==========================================================
  # Listar equipos
  # ==========================================================
  def listar_equipos() do
    equipos = leer_datos()

    IO.puts("=== Equipos registrados ===")

    if Enum.empty?(equipos) do
      IO.puts("No hay equipos registrados.")
    else
      Enum.each(equipos, fn linea ->
        case String.split(linea, ",") do
          [id, nombre, miembros_str] ->
            miembros = String.split(miembros_str, "|")
            IO.puts("- #{nombre} [ID: #{id}] (#{Enum.join(miembros, ", ")})")

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
    equipos = leer_datos()

    nuevos =
      Enum.reject(equipos, fn linea ->
        [id | _] = String.split(linea, ",")
        id == to_string(equipo_id)
      end)

    if length(nuevos) < length(equipos) do
      guardar_datos_concurrente(nuevos)
      IO.puts("Equipo #{equipo_id} eliminado.")
    else
      IO.puts("No se encontró el equipo con ID #{equipo_id}.")
    end
  end

  # ==========================================================
  # Agregar miembro a equipo
  # ==========================================================
  def agregar_miembro_a_equipo(equipo_id, nombre_usuario) do
    equipos = leer_datos()

    case Enum.find(equipos, fn linea ->
           [id | _] = String.split(linea, ",")
           id == to_string(equipo_id)
         end) do
      nil ->
        IO.puts("No se encontró un equipo con ID #{equipo_id}.")

      linea ->
        # Validar que usuario exista
        if HackathonApp.Services.GestionUsuarios.obtener_usuario_por_nombre(nombre_usuario) == nil do
          IO.puts("El usuario #{nombre_usuario} no existe.")
        else
          [id, nombre_equipo, miembros_str] = String.split(linea, ",")
          miembros = String.split(miembros_str, "|")

          if nombre_usuario in miembros do
            IO.puts("El usuario #{nombre_usuario} ya pertenece al equipo #{nombre_equipo}.")
          else
            nuevos_miembros = miembros ++ [nombre_usuario]
            nueva_linea = "#{id},#{nombre_equipo},#{Enum.join(nuevos_miembros, "|")}"

            nuevos_datos =
              Enum.map(equipos, fn l -> if l == linea, do: nueva_linea, else: l end)

            guardar_datos_concurrente(nuevos_datos)
            IO.puts("#{nombre_usuario} se unió al equipo #{nombre_equipo}.")
          end
        end
    end
  end
end
