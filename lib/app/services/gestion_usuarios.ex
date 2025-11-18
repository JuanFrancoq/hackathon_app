defmodule HackathonApp.Services.GestionUsuarios do
  @moduledoc """
  Servicio para gestionar usuarios: creación, listado, filtrado, asignación a equipos y eliminación.
  Soporta roles: participante y mentor.
  """

  alias HackathonApp.Domain.Usuario
  alias HackathonApp.Adapters.RepositorioArchivo

  @archivo "usuarios.csv"

  # Crear usuario
  def crear_usuario(id, nombre, rol) do
    usuarios = RepositorioArchivo.leer_datos(@archivo)

    existe =
      Enum.any?(usuarios, fn linea ->
        [uid, uname | _] = String.split(linea, ",")
        uid == to_string(id) or String.downcase(uname) == String.downcase(nombre)
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
        RepositorioArchivo.guardar_datos(@archivo, usuarios ++ [linea])
        IO.puts("Usuario '#{nombre}' con rol #{rol} creado correctamente.")
        usuario
    end
  end

  # Listar todos los usuarios
  def listar_usuarios() do
    usuarios = RepositorioArchivo.leer_datos(@archivo)

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

  # Listar usuarios por rol
  def listar_por_rol(rol_buscado) do
    usuarios = RepositorioArchivo.leer_datos(@archivo)

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

  # Obtener usuario por ID
  def obtener_usuario(id) do
    usuarios = RepositorioArchivo.leer_datos(@archivo)

    case Enum.find(usuarios, fn linea ->
           [uid | _] = String.split(linea, ",")
           uid == to_string(id)
         end) do
      nil ->
        IO.puts("No existe un usuario con el ID #{id}.")
        nil

      linea ->
        [uid, nombre, rol] = String.split(linea, ",")
        Usuario.nuevo(uid, nombre, rol)
    end
  end

  # Obtener usuario por nombre
  def obtener_usuario_por_nombre(nombre) do
    usuarios = RepositorioArchivo.leer_datos(@archivo)

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

  # Asignar usuario a equipo (solo participantes)
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
  # NUEVO: Eliminar usuario por ID o nombre
  # ==========================================================
  def eliminar_usuario(id_o_nombre) do
    usuarios = RepositorioArchivo.leer_datos(@archivo)

    {filtrados, eliminados} =
      Enum.split_with(usuarios, fn linea ->
        [uid, uname | _] = String.split(linea, ",")
        uid != to_string(id_o_nombre) and String.downcase(uname) != String.downcase(id_o_nombre)
      end)

    if length(usuarios) == length(filtrados) do
      IO.puts("No se encontró ningún usuario con ID o nombre '#{id_o_nombre}'.")
      :error
    else
      RepositorioArchivo.guardar_datos(@archivo, filtrados)
      IO.puts("Usuario(s) '#{id_o_nombre}' eliminado(s) correctamente.")
      :ok
    end
  end
end
