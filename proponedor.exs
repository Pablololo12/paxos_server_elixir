defmodule Proponedor do

  @timeout 50
  
  def crear_proponedor(aceptadores, num_instancia, valor) do
    Node.spawn_link(node(), __MODULE__, :proponedor, [aceptadores, 0, num_instancia, valor])
  end

  defp proponedor(aceptadores, n, num_instancia, valor) do
    #Prepara
    Enum.map(aceptadores, fn Pid -> send(Pid, {:prepara, n}) end)
    #Prepara_ok de todos?
    {v, count} = prepara_ok(0, 0, 0)
    if(count > (length(estado.nodos_paxos)/2)+1) do
      #acepta
      Enum.map(aceptadores, fn Pid -> send(Pid, {:acepta, n, v}) end)
    end
  end

  defp prepara_ok(n_a, v, count) do
    receive do
      {:prepare_ok, n, n_b, v_a} ->
        if n_a < n_b do
          prepara_ok(n_b, v_a, count+1)
        end
      {:prepare_reject, n_p} ->
        IO.puts("Reject")
        {v, count}
      after @timeout ->
        {v, count}
    end
  end
end