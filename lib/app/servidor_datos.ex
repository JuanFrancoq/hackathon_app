defmodule HackathonApp.ServidorDatos do
  @moduledoc """
  Proceso centralizado que se ejecuta SOLO en el nodo servidor.
  Se encarga de leer y escribir los archivos que usan los equipos,
  proyectos, usuarios y chat.
  """

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: {:global, :servidor_datos})
  end

  def guardar(nombre_archivo, lineas) do
    GenServer.call({:global, :servidor_datos}, {:guardar, nombre_archivo, lineas})
  end

  def leer(nombre_archivo) do
    GenServer.call({:global, :servidor_datos}, {:leer, nombre_archivo})
  end

  def init(_) do
    IO.puts("[ServidorDatos] Proceso de archivos iniciado.")
    {:ok, nil}
  end

  def handle_call({:guardar, nombre_archivo, lineas}, _from, state) do
    contenido = Enum.join(lineas, "\n")
    File.write!("data/#{nombre_archivo}", contenido)

    IO.puts("[ServidorDatos] Archivo guardado: #{nombre_archivo}")

    {:reply, :ok, state}
  end

  def handle_call({:leer, nombre_archivo}, _from, state) do
    ruta = "data/#{nombre_archivo}"

    resultado =
      if File.exists?(ruta) do
        File.read!(ruta)
        |> String.split("\n", trim: true)
      else
        []
      end

    {:reply, resultado, state}
  end
end
