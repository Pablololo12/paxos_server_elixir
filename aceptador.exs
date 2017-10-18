defmodule Aceptador do
  
  def crear_aceptador(n_p, n_a, v_a) do
    Node.spawn_link(node(), __MODULE__, :aceptador, [n_p, n_a, v_a])
  end

  defp aceptador(n_p, n_a, v_a) do
    receive do
      {:prepara, n, Pid} ->
        if n > n_p do
          send(Pid, {:prepare_ok, n, n_a, v_a})
          aceptador(n, n_a, v_a)
        else
          send(Pid, {:prepare_reject, n_p})
          aceptador(n, n_a, v_a)
        end
      {:acepta, n, v, Pid} ->
        if n >= n_p do
          send(Pid, {:acepta_ok, n})
          aceptador(n, n, v)
        else
          send(Pid, {:acepta_reject, n_p})
          aceptador(n_p, n_a, v_a)
        end
    end
  end
end