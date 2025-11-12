defmodule HackathonApp.Services.GestionMentoria do
  @moduledoc """
  Servicio para gestionar la retroalimentación de mentores hacia los proyectos.
  Permite registrar, listar, filtrar y eliminar comentarios.
  """

  alias HackathonApp.Adapters.RepositorioArchivo
  alias HackathonApp.Services.GestionUsuarios

  @archivo "mentorias.csv"
  @archivo_proyectos "proyectos.csv"

  # ==========================================================
  # REGISTRAR MENTORÍA
  # ==========================================================
  def registrar_mentoria(mentor_id, proyecto_id, comentario) do
    mentor = GestionUsuarios.obtener_usuario(mentor_id)

    cond do
      mentor == nil ->
        IO.puts("El mentor con ID #{mentor_id} no existe.")

      String.downcase(mentor.rol) != "mentor" ->
        IO.puts("El usuario con ID #{mentor_id} no es un mentor.")

      not proyecto_existe?(proyecto_id) ->
        IO.puts("No se encontró el proyecto con ID #{proyecto_id}.")

      true ->
        id = generar_id()
        fecha = DateTime.utc_now() |> DateTime.to_string()
        linea = "#{id},#{mentor_id},#{proyecto_id},#{comentario},#{fecha}"

        existentes = RepositorioArchivo.leer_datos(@archivo)
        RepositorioArchivo.guardar_datos(@archivo, existentes ++ [linea])

        IO.puts("Retroalimentación registrada correctamente.")
    end
  end

  # ==========================================================
  # LISTAR TODAS LAS MENTORÍAS
  # ==========================================================
  def listar_mentorias() do
    mentorias = RepositorioArchivo.leer_datos(@archivo)
    IO.puts("=== Retroalimentaciones registradas ===")

    if Enum.empty?(mentorias) do
      IO.puts("No hay retroalimentaciones registradas.")
    else
      Enum.each(mentorias, fn linea ->
        case String.split(linea, ",", parts: 5) do
          [id, mentor_id, proyecto_id, comentario, fecha] ->
            IO.puts("[#{id}] Mentor #{mentor_id} → Proyecto #{proyecto_id}: #{comentario} (#{fecha})")
          _ -> :ok
        end
      end)
    end
  end

  # ==========================================================
  # LISTAR POR PROYECTO
  # ==========================================================
  def listar_por_proyecto(proyecto_id) do
    mentorias = RepositorioArchivo.leer_datos(@archivo)
    filtradas = Enum.filter(mentorias, fn l -> String.contains?(l, ",#{proyecto_id},") end)

    IO.puts("=== Retroalimentaciones del proyecto #{proyecto_id} ===")

    if Enum.empty?(filtradas) do
      IO.puts("No hay retroalimentaciones para este proyecto.")
    else
      Enum.each(filtradas, fn linea ->
        [id, mentor_id, _pid, comentario, fecha] = String.split(linea, ",", parts: 5)
        IO.puts("[#{id}] Mentor #{mentor_id}: #{comentario} (#{fecha})")
      end)
    end
  end

  # ==========================================================
  # LISTAR POR MENTOR
  # ==========================================================
  def listar_por_mentor(mentor_id) do
    mentorias = RepositorioArchivo.leer_datos(@archivo)
    filtradas = Enum.filter(mentorias, fn l -> String.starts_with?(l, ",#{mentor_id},") end)

    IO.puts("=== Retroalimentaciones del mentor #{mentor_id} ===")

    if Enum.empty?(filtradas) do
      IO.puts("Este mentor no ha registrado retroalimentaciones.")
    else
      Enum.each(filtradas, fn linea ->
        [id, _mid, proyecto_id, comentario, fecha] = String.split(linea, ",", parts: 5)
        IO.puts("[#{id}] Proyecto #{proyecto_id}: #{comentario} (#{fecha})")
      end)
    end
  end

  # ==========================================================
  # ELIMINAR MENTORÍA
  # ==========================================================
  def eliminar_mentoria(id) do
    mentorias = RepositorioArchivo.leer_datos(@archivo)
    nuevas = Enum.reject(mentorias, fn l -> String.starts_with?(l, "#{id},") end)

    if length(nuevas) < length(mentorias) do
      RepositorioArchivo.guardar_datos(@archivo, nuevas)
      IO.puts("Retroalimentación #{id} eliminada correctamente.")
    else
      IO.puts("No se encontró la retroalimentación con ID #{id}.")
    end
  end

  # ==========================================================
  # FUNCIONES PRIVADAS
  # ==========================================================
  defp proyecto_existe?(id) do
    proyectos = RepositorioArchivo.leer_datos(@archivo_proyectos)
    Enum.any?(proyectos, fn linea -> String.starts_with?(linea, "#{id},") end)
  end

  defp generar_id() do
    :crypto.strong_rand_bytes(3)
    |> Base.encode16()
    |> String.slice(0, 6)
  end
end
