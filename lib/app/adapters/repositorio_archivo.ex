defmodule HackathonApp.Adapters.RepositorioArchivo do
  @moduledoc """
  Cliente local y remoto para guardar y leer datos.
  Guardado silencioso, lectura solo cuando se solicita.
  Usa automáticamente la carpeta 'data/'.
  """

  @data_path Path.expand("data")  # Carpeta donde están tus CSV
  @nombre_nodo_servidor :servidor@Pc_Juan
  @proceso_servidor :servidor_datos

  # ==========================================================
  # Construir ruta completa del archivo
  # ==========================================================
  defp archivo(nombre_archivo), do: Path.join(@data_path, nombre_archivo)

  # ==========================================================
  # Guardar datos (silencioso)
  # ==========================================================
  def guardar_datos(nombre_archivo, lineas) do
    path = archivo(nombre_archivo)

    # Crear carpeta data si no existe
    File.mkdir_p!(@data_path)

    # Guardar local siempre
    File.write!(path, Enum.join(lineas, "\n"))

    # Intentar guardar en servidor, ignorando errores
    mensaje = {:guardar, nombre_archivo, lineas}

    case call_servidor(mensaje) do
      :ok -> :ok
      {:error, _} -> :ok
    end
  end

  # ==========================================================
  # Leer datos
  # ==========================================================
  def leer_datos(nombre_archivo) do
    path = archivo(nombre_archivo)
    mensaje = {:leer, nombre_archivo}

    case call_servidor(mensaje) do
      {:ok, lineas} -> lineas
      {:error, _} -> leer_local(path)
    end
  end

  # ==========================================================
  # Lectura local
  # ==========================================================
  defp leer_local(path) do
    case File.read(path) do
      {:ok, contenido} -> String.split(contenido, "\n", trim: true)
      {:error, _} -> []
    end
  end

  # ==========================================================
  # Enviar mensaje al servidor
  # ==========================================================
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
