defmodule HackathonApp.Adapters.RepositorioArchivo do
  @moduledoc """
  Cliente local y remoto para guardar y leer datos.
  Guardado silencioso, lectura solo cuando se solicita.
  """

  @nombre_nodo_servidor :servidor@Pc_Juan
  @proceso_servidor :servidor_datos

  # Guardar datos (silencioso)
  def guardar_datos(nombre_archivo, lineas) do
    # Guardar local siempre
    File.write!(nombre_archivo, Enum.join(lineas, "\n"))

    # Intentar guardar en servidor, ignorando errores de salida
    mensaje = {:guardar, nombre_archivo, lineas}

    case call_servidor(mensaje) do
      :ok -> :ok
      {:error, _} -> :ok
    end
  end

  # Leer datos
  def leer_datos(nombre_archivo) do
    mensaje = {:leer, nombre_archivo}

    case call_servidor(mensaje) do
      {:ok, lineas} -> lineas
      {:error, _} -> leer_local(nombre_archivo)
    end
  end

  # Lectura local
  defp leer_local(nombre_archivo) do
    case File.read(nombre_archivo) do
      {:ok, contenido} -> String.split(contenido, "\n", trim: true)
      {:error, _} -> []
    end
  end

  # Enviar mensaje al servidor
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
