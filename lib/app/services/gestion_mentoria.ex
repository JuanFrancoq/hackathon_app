defmodule HackathonApp.Services.GestionMentoria do
  @moduledoc """
  Servicio para gestionar la retroalimentación de mentores hacia los proyectos.
  Permite registrar comentarios, listarlos y eliminarlos.
  """

  alias HackathonApp.Adapters.RepositorioArchivo
  alias HackathonApp.Services.{GestionUsuarios, GestionProyectos}

  @archivo Path.join([File.cwd!(), "data/mentorias.csv"])

  @doc """
  Registra una retroalimentación de un mentor a un proyecto.
  """
  def registrar_mentoria(mentor_id, proyecto_id, comentario) do
    mentor = GestionUsuarios.obtener_usuario(mentor_id)

    cond do
      mentor == nil ->
        IO.puts("⚠️ El mentor con ID #{mentor_id} no existe.")

      mentor.rol != "mentor" ->
        IO.puts("⚠️ El usuario con ID #{mentor_id} no es un mentor.")

      not proyecto_existe?(proyecto_id) ->
        IO.puts("⚠️ No se encontró el proyecto con ID #{proyecto_id}.")

      true ->
        id = generar_id()
        fecha = DateTime.utc_now() |> DateTime.to_string()
        linea = "#{id},#{mentor_id},#{proyecto_id},#{comentario},#{fecha}"

        existentes = RepositorioArchivo.leer_datos(@archivo)
        RepositorioArchivo.guardar_datos(@archivo, existentes ++ [linea])

        IO.puts("Retroalimentación registrada correctamente por el mentor #{mentor.nombre}.")
    end
  end

  # ==========================================================
  # Listar todas las mentorías
  # ==========================================================
  @doc """
  Muestra todas las retroalimentaciones registradas.
  """
  def listar_mentorias() do
    mentorias = RepositorioArchivo.leer_datos(@archivo)

    IO.puts("=== Retroalimentaciones registradas ===")

    if Enum.empty?(mentorias) do
      IO.puts("No hay retroalimentaciones registradas.")
    else
      Enum.each(mentorias, fn linea ->
        case String.split(linea, ",", parts: 5) do
          [id, mentor_id, proyecto_id, comentario, fecha] ->
            IO.puts("""
            [ID: #{id}] Proyecto #{proyecto_id}
            Mentor: #{mentor_id}
            Comentario: #{comentario}
            Fecha: #{fecha}
            """)

          _ ->
            nil
        end
      end)
    end
  end

  @doc """
  Muestra todas las retroalimentaciones relacionadas con un proyecto.
  """
  def listar_por_proyecto(proyecto_id) do
    mentorias = RepositorioArchivo.leer_datos(@archivo)

    filtradas =
      Enum.filter(mentorias, fn linea ->
        [_id, _mentor_id, pid | _] = String.split(linea, ",")
        pid == to_string(proyecto_id)
      end)

    IO.puts("=== Retroalimentaciones del proyecto #{proyecto_id} ===")

    if Enum.empty?(filtradas) do
      IO.puts("No hay retroalimentaciones para este proyecto.")
    else
      Enum.each(filtradas, fn linea ->
        [id, mentor_id, _pid, comentario, fecha] = String.split(linea, ",", parts: 5)
        IO.puts("""
        [ID: #{id}] Mentor #{mentor_id} dijo:
        "#{comentario}" (#{fecha})
        """)
      end)
    end
  end

  @doc """
  Elimina una retroalimentación específica por su ID.
  """
  def eliminar_mentoria(id) do
    mentorias = RepositorioArchivo.leer_datos(@archivo)

    nuevas =
      Enum.reject(mentorias, fn linea ->
        String.starts_with?(linea, "#{id},")
      end)

    if length(nuevas) < length(mentorias) do
      RepositorioArchivo.guardar_datos(@archivo, nuevas)
      IO.puts("Retroalimentación #{id} eliminada correctamente.")
    else
      IO.puts("No se encontró la retroalimentación con ID #{id}.")
    end
  end

  # ==========================================================
  # Helpers
  # ==========================================================
  defp proyecto_existe?(id) do
    proyectos = RepositorioArchivo.leer_datos(Path.join([File.cwd!(), "data/proyectos.csv"]))

    Enum.any?(proyectos, fn linea ->
      String.starts_with?(linea, "#{id},")
    end)
  end

  defp generar_id() do
    :crypto.strong_rand_bytes(4)
    |> Base.encode16()
    |> binary_part(0, 6)
  end
end
