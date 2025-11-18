defmodule HackathonApp.Services.GestionUsuarios do
  @moduledoc """
  Servicio para gestionar usuarios: creación, listado, filtrado, asignación a equipos y eliminación.
  Soporta roles: participante y mentor.
  Persistencia híbrida: local y concurrente mediante Agent.
  """

  use Agent
  alias HackathonApp.Domain.Usuario
  alias HackathonApp.Adapters.RepositorioArchivo

  @archivo "usuarios.csv"

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
    Agent.update(__MODULE__, fn usuarios ->
      nuevos = usuarios ++ [linea]
      RepositorioArchivo.guardar_datos(@archivo, nuevos)
      nuevos
    end)
  end

  defp eliminar_linea(id_o_nombre) do
    Agent.update(__MODULE__, fn usuarios ->
      nuevos =
        Enum.reject(usuarios, fn linea ->
          [uid, uname | _] = String.split(linea, ",")
          uid == id_o_nombre or String.downcase(uname) == String.downcase(id_o_nombre)
        end)

      RepositorioArchivo.guardar_datos(@archivo, nuevos)
      nuevos
    end)
  end

  defp obtener_todos(), do: Agent.get(__MODULE__, & &1)

  # ==========================================================
  # CREAR USUARIO
  # ==========================================================
  def crear_usuario(id, nombre, rol) do
    usuarios = obtener_todos()

    existe =
      Enum.any?(usuarios, fn linea ->
        [uid, uname | _] = String.split(linea, ",")
        uid == id or String.downcase(uname) == String.downcase(nombre)
      end)

    cond do
      existe ->
        IO.puts("No se pudo crear el usuario: ya existe un usuario con ese ID o nombre.")
        nil

      rol not in ["participante", "mentor"] ->
        IO.puts("El rol '#{rol}' no es válido. Solo se permiten participante o mentor.")
        nil

      true ->
        usuario = Usuario.nuevo(id, nombre, rol)
        linea = "#{usuario.id},#{usuario.nombre},#{usuario.rol}"
        guardar_linea(linea)
        IO.puts("Usuario '#{nombre}' con rol #{rol} creado correctamente.")
        usuario
    end
  end

  # ==========================================================
  # LISTAR USUARIOS
  # ==========================================================
  def listar_usuarios() do
    usuarios = obtener_todos()

    IO.puts("=== Usuarios registrados ===")
    if Enum.empty?(usuarios) do
      IO.puts("No se encontraron usuarios registrados.")
    else
      Enum.each(usuarios, fn linea ->
        [id, nombre, rol] = String.split(linea, ",")
        IO.puts("- #{nombre} [ID: #{id}] (Rol: #{rol})")
      end)
    end
  end

  # ==========================================================
  # LISTAR POR ROL
  # ==========================================================
  def listar_por_rol(rol_buscado) do
    usuarios = obtener_todos()

    filtrados =
      Enum.filter(usuarios, fn linea ->
        [_id, _nombre, rol] = String.split(linea, ",")
        String.downcase(rol) == String.downcase(rol_buscado)
      end)

    IO.puts("=== Usuarios con rol #{rol_buscado} ===")
    if Enum.empty?(filtrados) do
      IO.puts("No hay usuarios con ese rol.")
    else
      Enum.each(filtrados, fn linea ->
        [id, nombre, rol] = String.split(linea, ",")
        IO.puts("- #{nombre} [ID: #{id}] (Rol: #{rol})")
      end)
    end
  end

  # ==========================================================
  # OBTENER USUARIO POR ID
  # ==========================================================
  def obtener_usuario(id) do
    usuarios = obtener_todos()

    case Enum.find(usuarios, fn linea ->
           [uid | _] = String.split(linea, ",")
           uid == id
         end) do
      nil ->
        IO.puts("No existe un usuario con el ID #{id}.")
        nil

      linea ->
        [uid, nombre, rol] = String.split(linea, ",")
        Usuario.nuevo(uid, nombre, rol)
    end
  end

  # ==========================================================
  # OBTENER USUARIO POR NOMBRE
  # ==========================================================
  def obtener_usuario_por_nombre(nombre) do
    usuarios = obtener_todos()

    Enum.find_value(usuarios, fn linea ->
      case String.split(linea, ",") do
        [id, nombre_usuario, rol] ->
          if String.downcase(nombre_usuario) == String.downcase(nombre) do
            %{id: id, nombre: nombre_usuario, rol: rol}
          else
            nil
          end

        _ -> nil
      end
    end)
  end

  # ==========================================================
  # ASIGNAR USUARIO A EQUIPO
  # ==========================================================
  def asignar_a_equipo(usuario_id, equipo_id) do
    case obtener_usuario(usuario_id) do
      nil ->
        IO.puts("Usuario no encontrado.")

      %Usuario{rol: "mentor"} ->
        IO.puts("Los mentores no pueden unirse a equipos.")

      %Usuario{nombre: nombre, rol: "participante"} ->
        equipos = RepositorioArchivo.leer_datos("equipos.csv")

        case Enum.find(equipos, fn linea -> String.starts_with?(linea, "#{equipo_id},") end) do
          nil ->
            IO.puts("No existe un equipo con ID #{equipo_id}.")

          linea ->
            [id, nombre_equipo, miembros_str] = String.split(linea, ",")
            miembros = String.split(miembros_str, "|")

            if Enum.member?(miembros, nombre) do
              IO.puts("El usuario #{nombre} ya pertenece al equipo #{nombre_equipo}.")
            else
              nuevos_miembros = miembros ++ [nombre]
              nueva_linea = "#{id},#{nombre_equipo},#{Enum.join(nuevos_miembros, "|")}"

              nuevos_equipos =
                Enum.map(equipos, fn l -> if l == linea, do: nueva_linea, else: l end)

              RepositorioArchivo.guardar_datos("equipos.csv", nuevos_equipos)
              IO.puts("El participante #{nombre} fue agregado al equipo #{nombre_equipo}.")
            end
        end
    end
  end

  # ==========================================================
  # ELIMINAR USUARIO
  # ==========================================================
  def eliminar_usuario(id_o_nombre) do
    usuarios = obtener_todos()

    if Enum.any?(usuarios, fn linea ->
         [uid, uname | _] = String.split(linea, ",")
         uid == id_o_nombre or String.downcase(uname) == String.downcase(id_o_nombre)
       end) do
      eliminar_linea(id_o_nombre)
      IO.puts("Usuario '#{id_o_nombre}' eliminado correctamente.")
      :ok
    else
      IO.puts("No se encontró ningún usuario con ID o nombre '#{id_o_nombre}'.")
      :error
    end
  end
end
