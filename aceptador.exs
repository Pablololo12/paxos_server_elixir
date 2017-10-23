Code.require_file("#{__DIR__}/send_adicional.exs")

defmodule Aceptador do
  
  def crear_aceptador(nu_instancia) do
    IO.puts("Aceptador creado con instancia #{nu_instancia}")
    Node.spawn_link(node(), __MODULE__, :aceptador, [0,0,0,nu_instancia])
  end

  def aceptador(n_p, n_a, v_a, nu_instancia) do
    receive do
      {:prepara, n, pid} ->
        if n > n_p do
          #IO.puts("prepare_ok")
          Send.con_nodo_emisor(pid, {:prepare_ok, n, n_a, v_a, nu_instancia})
          aceptador(n, n_a, v_a, nu_instancia)
        else
          #IO.puts("prepare_reject")
          Send.con_nodo_emisor(pid, {:prepare_reject, n_p, nu_instancia})
          aceptador(n, n_p, v_a, nu_instancia)
        end
      {:acepta, n, v, pid} ->
        if n >= n_p do
          #IO.puts("acepta_ok")
          Send.con_nodo_emisor(pid, {:acepta_ok, n, nu_instancia})
          aceptador(n, n, v, nu_instancia)
        else
          #IO.puts("acepta_reject")
          Send.con_nodo_emisor(pid, {:acepta_reject, n_p, nu_instancia})
          aceptador(n_p, n_a, v_a, nu_instancia)
        end
      _ ->
        IO.puts("Algo raro ha pasado en aceptador")
    end
  end
end