defmodule HackathonApp.Adapters.RepositorioArchivo do
  @moduledoc """
  Módulo simple para leer y escribir datos en archivos CSV.
  """

  # Guarda una lista de líneas en un archivo CSV
  def guardar_datos(nombre_archivo, lineas) do

    contenido = Enum.join(lineas, "\n")

    File.write!("data/#{nombre_archivo}", contenido)

    IO.puts("Datos guardados en data/#{nombre_archivo}")
  end

  def leer_datos(nombre_archivo) do
    ruta = "data/#{nombre_archivo}"

    if File.exists?(ruta) do
      File.read!(ruta)
      |> String.split("\n", trim: true)
    else
      []
    end
  end
end
