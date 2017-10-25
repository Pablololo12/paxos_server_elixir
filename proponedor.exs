Code.require_file("#{__DIR__}/send_adicional.exs")

defmodule Proponedor do

  @timeout 50
  #:os.system_time(:milli_seconds)
  def crear_proponedor(aceptadores, num_instancia, valor, pid) do
    IO.puts("Proponedor creado con instancia #{num_instancia} #{valor}")
    Node.spawn_link(node(), __MODULE__, :proponedor, [aceptadores, 0,
                    num_instancia, valor, pid])
  end

  def proponedor(aceptadores, n, num_instancia, valor, pid) do
    #Prepara
    Enum.each(aceptadores, fn nodo_paxos ->
              Send.con_nodo_emisor({:paxos, nodo_paxos},
                                  {:prepara, n, num_instancia, pid}) end)
    #Prepara_ok de todos?
    {v, count, n_p} = prepara_ok(n, 0, valor, 0)
    if(count >= (div(length(aceptadores),2)+1)) do
      #acepta
      Enum.each(aceptadores, fn nodo_paxos ->
        Send.con_nodo_emisor({:paxos, nodo_paxos},
                            {:acepta, n, v, num_instancia, pid}) end)
      {n_a, count} = acepto_ok(n,0)
      if(count >= (div(length(aceptadores),2)+1)) do
        decide(aceptadores, v, num_instancia)
        IO.puts("#Decido #{node()} #{num_instancia} #{v}")
      else
        proponedor(aceptadores, n_a+2, num_instancia, valor, pid)
      end
    else
      proponedor(aceptadores, n_p+2, num_instancia, valor, pid)
    end
  end

  defp decide(aceptadores, valor, nu_instancia) do
    Enum.each(aceptadores, fn nodo_paxos->
      Send.con_nodo_emisor({:paxos, nodo_paxos},
                           {:decidido, valor, nu_instancia, node()}) end)
      if espero(0) != length(aceptadores) do
        decide(aceptadores, valor, nu_instancia)
      end
  end
    
  defp espero(count) do
    receive do
      {:ACK, _} -> espero(count+1)
    after @timeout -> count
    end

  end

  defp prepara_ok(n_mio, n_a, v, count) do
    receive do
      {:prepare_ok, n, n_b, v_a} ->
        if n_b!=0 do
          if n_a < n_b do
            prepara_ok(n_mio, n_b, v_a, count+1)
          else
            prepara_ok(n_mio, n_a, v, count+1)
          end
        else
          prepara_ok(n_mio, n_a, v, count+1)
        end
      {:prepare_reject, n_p} ->
        prepara_ok(n_mio, n_a, v, count)
      after @timeout ->
        if n_a == 0 do
          {v, count, n_mio}
        else
          {v, count, n_a}
        end
    end
  end

  defp acepto_ok(n_a, count) do
    receive do
      {:acepta_ok, n} ->
        if n_a == n do
          acepto_ok(n_a, count+1)
        else
          acepto_ok(n_a, count)
        end
      {:acepta_reject, n_p} ->
        {n_p, 0}
      after @timeout ->
        {n_a, count}
    end
  end
end
