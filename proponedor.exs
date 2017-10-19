defmodule Proponedor do

  @timeout 50
  
  def crear_proponedor(aceptadores, num_instancia, valor, pid) do
    IO.puts("Proponedor creado con instancia #{num_instancia}")
    Node.spawn_link(node(), __MODULE__, :proponedor, [aceptadores, 1,
                    num_instancia, valor, pid])
  end

  def proponedor(aceptadores, n, num_instancia, valor, pid) do
    #Prepara
    Enum.each(aceptadores, fn nodo_paxos ->
              send({:paxos, nodo_paxos},{:prepara, n, num_instancia, pid}) end)
    #Prepara_ok de todos?
    {v, count, n_p} = prepara_ok(0, valor, 0)
    if(count >= (length(aceptadores)/2)+1) do
      #acepta
      Enum.each(aceptadores, fn nodo_paxos ->
        send({:paxos, nodo_paxos}, {:acepta, n, v, num_instancia, pid}) end)
      {n_a, count} = acepto_ok(n,0)
      if(count >= (length(aceptadores)/2)+1) do
        Enum.each(aceptadores, fn nodo_paxos -> 
          send({:paxos, nodo_paxos}, {:decidido, valor, num_instancia}) end)
      else
        proponedor(aceptadores, n_a+1, num_instancia, valor, pid)
      end
    else
      proponedor(aceptadores, n_p+1, num_instancia, valor, pid)
    end
  end

  defp prepara_ok(n_a, v, count) do
    receive do
      {:prepare_ok, n, n_b, v_a} ->
        if n_a <= n_b do
          prepara_ok(n_b, v_a, count+1)
        else
          prepara_ok(n_a, v, count+1)
        end
      {:prepare_reject, n_p} ->
        prepara_ok(n_a, v, count)
        #{v, count, n_p}
      after @timeout ->
        {v, count, n_a}
    end
  end

  defp acepto_ok(n_a, count) do
    receive do
      {:acepta_ok, n} ->
        if n_a = n do
          acepto_ok(n_a, count+1)
        end
      {:acepta_reject, n_p} ->
        {n_p, count}
      after @timeout ->
        {n_a, count}
    end
  end
end