defmodule HackathonApp.Services.GestionChatStore do
  @moduledoc """
  Agent que maneja la persistencia concurrente de mensajes en memoria
  y sincroniza con el archivo CSV.
  """

  use Agent
  alias HackathonApp.Adapters.RepositorioArchivo

  @archivo "mensajes.csv"

  # Inicia el agente con los datos del archivo
  def start_link(_) do
    Agent.start_link(fn -> RepositorioArchivo.leer_datos(@archivo) end, name: __MODULE__)
  end

  # Agrega una línea de mensaje de forma segura
  def agregar_linea(linea) do
    Agent.update(__MODULE__, fn mensajes ->
      nuevos = mensajes ++ [linea]
      RepositorioArchivo.guardar_datos(@archivo, nuevos)
      nuevos
    end)
  end

  # Elimina un mensaje por ID de forma segura
  def eliminar_linea(id_mensaje) do
    Agent.update(__MODULE__, fn mensajes ->
      nuevos = Enum.reject(mensajes, fn linea ->
        [id_str | _] = String.split(linea, ",")
        id_str == to_string(id_mensaje)
      end)
      RepositorioArchivo.guardar_datos(@archivo, nuevos)
      nuevos
    end)
  end

  # Elimina todos los mensajes de un equipo específico
  def eliminar_por_equipo(equipo_id) do
    Agent.update(__MODULE__, fn mensajes ->
      nuevos = Enum.reject(mensajes, fn linea ->
        [_, eq_id | _] = String.split(linea, ",")
        eq_id == to_string(equipo_id)
      end)
      RepositorioArchivo.guardar_datos(@archivo, nuevos)
      nuevos
    end)
  end

  # Obtiene todos los mensajes
  def obtener_mensajes(), do: Agent.get(__MODULE__, & &1)
end
