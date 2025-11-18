# Módulo encargado de leer y guardar datos en archivos CSV para el sistema
defmodule HackathonApp.Adapters.RepositorioArchivo do

  @moduledoc """
  Cliente local y remoto para guardar y leer datos utilizando el nodo servidor.
  """

  @nombre_nodo_servidor :servidor@Pc_Juan
  @proceso_servidor :servidor_datos

  # ==============================================================
  # GUARDAR (llama SIEMPRE al servidor)
  # ==============================================================
  def guardar_datos(nombre_archivo, lineas) do
    mensaje = {:guardar, nombre_archivo, lineas}

    case call_servidor(mensaje) do
      :ok ->
        IO.puts("Servidor: datos guardados en #{nombre_archivo}")

      {:error, :no_conectado} ->
        IO.puts("ERROR: No se pudo contactar al nodo servidor #{@nombre_nodo_servidor}")
    end
  end

  # ==============================================================
  # LEER (también desde el servidor)
  # ==============================================================
  def leer_datos(nombre_archivo) do
  mensaje = {:leer, nombre_archivo}

  case call_servidor(mensaje) do
    {:ok, lineas} -> lineas
    {:error, :no_conectado} ->
      IO.puts("ERROR: No se pudo contactar al nodo servidor #{@nombre_nodo_servidor}")
      []
    {:error, :no_respuesta} ->
      IO.puts("ERROR: El servidor no respondió a tiempo")
      []
  end
end

  # ==============================================================
  # Enviar mensaje al servidor
  # ==============================================================

  defp call_servidor(mensaje) do
    if Node.connect(@nombre_nodo_servidor) do
      send({@proceso_servidor, @nombre_nodo_servidor}, {self(), mensaje})

      receive do
        respuesta -> respuesta
      after
        2000 -> {:error, :no_respuesta}
      end
    else
      {:error, :no_conectado}
    end
  end
end
