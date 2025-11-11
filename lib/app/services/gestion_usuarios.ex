defmodule HackathonApp.Services.GestionUsuarios do
  @moduledoc """
  Servicio para gestionar usuarios: creación, listado y asignación a equipos.
  Soporta roles: participante y mentor.
  """

  alias HackathonApp.Domain.Usuario
  alias HackathonApp.Adapters.RepositorioArchivo
  alias HackathonApp.Services.GestionEquipos

  # Ruta al archivo de datos
  @archivo "usuarios.csv"

  # ==========================================================
  # CREAR USUARIO
  # ==========================================================
  @doc """
  Crea un nuevo usuario con ID, nombre y rol (participante o mentor).
  Evita duplicados por ID o nombre.
  """
  def crear_usuario(id, nombre, rol) do
    usuarios = RepositorioArchivo.leer_datos(@archivo)

    # Validar duplicados
    ya_existe =
      Enum.any?(usuarios, fn linea ->
        [uid, uname | _] = String.split(linea, ",")
        uid == to_string(id) or String.downcase(uname) == String.downcase(nombre)
      end)

    if ya_existe do
      IO.puts("Ya existe un usuario con ID o nombre similar.")
    else
      usuario = Usuario.nuevo(id, nombre, rol)
      linea = "#{usuario.id},#{usuario.nombre},#{usuario.rol}"

      nuevas_lineas = usuarios ++ [linea]
      RepositorioArchivo.guardar_datos(@archivo, nuevas_lineas)

      IO.puts("Usuario '#{nombre}' (#{rol}) creado correctamente.")
      usuario
    end
  end

  # ==========================================================
  # LISTAR USUARIOS
  # ==========================================================
  @doc """
  Muestra todos los usuarios registrados.
  """
  def listar_usuarios() do
    usuarios = RepositorioArchivo.leer_datos(@archivo)

    IO.puts("=== Usuarios registrados ===")

    if Enum.empty?(usuarios) do
      IO.puts("No hay usuarios registrados.")
    else
      Enum.each(usuarios, fn linea ->
        [id, nombre, rol] = String.split(linea, ",")
        IO.puts("- #{nombre} [ID: #{id}] (Rol: #{rol})")
      end)
    end
  end

  # ==========================================================
  # FILTRAR POR ROL
  # ==========================================================
  @doc """
  Lista los usuarios filtrando por rol ("participante" o "mentor").
  """
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

  # ==========================================================
  # OBTENER USUARIO
  # ==========================================================
  @doc """
  Devuelve la estructura de un usuario si existe.
  """
  def obtener_usuario(id) do
    usuarios = RepositorioArchivo.leer_datos(@archivo)

    case Enum.find(usuarios, fn linea ->
           [uid | _] = String.split(linea, ",")
           uid == to_string(id)
         end) do
      nil ->
        IO.puts("No se encontró el usuario con ID #{id}.")
        nil

      linea ->
        [uid, nombre, rol] = String.split(linea, ",")
        Usuario.nuevo(uid, nombre, rol)
    end
  end

  # ==========================================================
  # UNIRSE A UN EQUIPO
  # ==========================================================
  @doc """
  Asigna un usuario (participante) a un equipo, agregándolo al CSV de equipos.
  """
  def asignar_a_equipo(usuario_id, equipo_id) do
    case obtener_usuario(usuario_id) do
      nil ->
        IO.puts("Usuario no encontrado.")

      %Usuario{rol: "mentor"} ->
        IO.puts("Los mentores no pueden unirse a equipos.")

      %Usuario{nombre: nombre, rol: "participante"} ->
        # Leer equipos
        equipos = RepositorioArchivo.leer_datos("equipos.csv")

        case Enum.find(equipos, fn linea ->
               String.starts_with?(linea, "#{equipo_id},")
             end) do
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
                Enum.map(equipos, fn l ->
                  if l == linea, do: nueva_linea, else: l
                end)

              RepositorioArchivo.guardar_datos("equipos.csv", nuevos_equipos)
              IO.puts("El participante #{nombre} fue agregado al equipo #{nombre_equipo}.")
            end
        end
    end
  end
end
