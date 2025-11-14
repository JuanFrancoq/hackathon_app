defmodule HackathonApp do
  @moduledoc """
  Application principal del sistema Hackathon.
  """

  use Application


  @doc """
  Arranque de la aplicación.
  """
  def start(_type, _args) do
    # Detecta si este nodo ES el nodo servidor
    if nodo_servidor?() do
      IO.puts("[HackathonApp] Nodo servidor detectado. Iniciando ServidorDatos...")

      children = [
        {HackathonApp.Adapters.ServidorDatos, []}
      ]

      opts = [strategy: :one_for_one, name: HackathonApp.Supervisor]
      Supervisor.start_link(children, opts)
    else
      IO.puts("[HackathonApp] Nodo cliente detectado. No se inicia ServidorDatos.")
      Supervisor.start_link([], strategy: :one_for_one)
    end
  end

  # ==============================================
  # DETECTA SI ESTE NODO ES EL SERVIDOR
  # ==============================================
  defp nodo_servidor? do
    # cambia esto si tu nodo servidor tiene otro nombre
    node() == :"servidor@Pc_Juan"
  end
end
