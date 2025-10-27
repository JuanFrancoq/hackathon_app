defmodule HackathonApp.Services.GestionUsuarios do
  @moduledoc """
  Servicio básico para gestionar usuarios: crear y listar usando un archivo CSV.
  """

  alias HackathonApp.Domain.Usuario
  alias HackathonApp.Adapters.RepositorioArchivo

  # Crea un nuevo usuario y lo guarda en data/usuarios.csv
  def crear_usuario(id, nombre, rol) do
    usuario = Usuario.nuevo(id, nombre, rol)

    linea = "#{usuario.id},#{usuario.nombre},#{usuario.rol}"

    usuarios_actuales = RepositorioArchivo.leer_datos("usuarios.csv")

    nuevas_lineas = usuarios_actuales ++ [linea]

    RepositorioArchivo.guardar_datos("usuarios.csv", nuevas_lineas)

    IO.puts("Usuario '#{nombre}' creado y guardado en usuarios.csv")
    usuario
  end

  # Listar todos los usuarios registrados
  def listar_usuarios() do
    usuarios = RepositorioArchivo.leer_datos("usuarios.csv")

    IO.puts("Usuarios registrados:")

    Enum.each(usuarios, fn linea ->
      [id, nombre, rol] = String.split(linea, ",")
      IO.puts("- #{nombre} [ID: #{id}] (Rol: #{rol})")
    end)
  end
end
