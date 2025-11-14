defmodule HackathonApp.Adapters.ServidorDatos do
  @moduledoc """
  Proceso que corre únicamente en el nodo servidor y se encarga
  de guardar y leer archivos para todos los clientes conectados.
  """

  use GenServer

  # ------------------------------------------------------------
  # INICIO DEL SERVIDOR
  # ------------------------------------------------------------
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: :servidor_datos)
  end

  def init(state) do
    IO.puts("[ServidorDatos] Servidor de archivos iniciado.")
    {:ok, state}
  end

  # ------------------------------------------------------------
  # API: mensajes desde clientes
  # ------------------------------------------------------------

  # Guardar
  def handle_info({from, {:guardar, nombre_archivo, lineas}}, state) do
    ruta = "data/#{nombre_archivo}"
    contenido = Enum.join(lineas, "\n")
    File.write!(ruta, contenido)

    send(from, :ok)
    {:noreply, state}
  end

  # Leer
  def handle_info({from, {:leer, nombre_archivo}}, state) do
    ruta = "data/#{nombre_archivo}"

    if File.exists?(ruta) do
      lineas =
        File.read!(ruta)
        |> String.split("\n", trim: true)

      send(from, {:ok, lineas})
    else
      send(from, {:ok, []})
    end

    {:noreply, state}
  end
end
