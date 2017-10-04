# Compilar y cargar ficheros con modulos necesarios
Code.require_file("servidor_paxos.exs", __DIR__)
#Code.require_file("#{__DIR__}/servidor_paxos.exs")
#Code.require_file("#{__DIR__}/cliente_XX.exs")

#Poner en marcha el servicio de tests unitarios con tiempo de vida limitada
# seed: 0 para que la ejecucion de tests no tenga orden aleatorio
ExUnit.start([timeout: 20000, seed: 0]) # milisegundos

defmodule  ServicioPaxosTest do

    use ExUnit.Case

    # @moduletag timeout 100  para timeouts de todos los test de este modulo

    @host1 "127.0.0.1"

    @tiempo_espera 10


    setup_all do
        # Poner en marcha nodos
        # n1 = :"n1@127.0.0.1"
        # n2 = :"n2@127.0.0.1"
        # n3 = :"n3@127.0.0.1"

        servidores = [:"n1@127.0.0.1", :"n2@127.0.0.1", :"n3@127.0.0.1"]
        n1 = ServidorPaxos.start(servidores, @host1, "n1")
        n2 = ServidorPaxos.start(servidores, @host1, "n2")
        n3 = ServidorPaxos.start(servidores, @host1, "n3")
        Process.sleep(@tiempo_espera)

        on_exit fn ->
                    #eliminar_nodos(n1, n2, n3)
                    IO.puts "Finalmente eliminamos nodos"
                    ServidorPaxos.stop(n1)
                    ServidorPaxos.stop(n2)
                    ServidorPaxos.stop(n3)                                    
                end

        {:ok, [n1: n1, n2: n2, n3: n3]}
    end


    # Primer test
    test "Unico proponente", %{n1: n1} do
        IO.puts("Test: Unico proponente ...")

        # solicitar la ejecución de una instancia
        ServidorPaxos.start_instancia(n1, 1, "hello")

        # A esperar a que decidan el mismo valor todos
        esperar_n_nodos(servidores, 1, length(servidores))

        IO.puts(" ... Superado")
    end


    # Segundo test
    test "Varios propo., un valor", %{n1: n1, n2: n2, n3: n3} do
        IO.puts("Test: Varios propo., un valor ...")

         # solicitar la ejecución de una instancia... en los  simultaneamente
        ServidorPaxos.start_instancia(n1, 2, "hello")
        ServidorPaxos.start_instancia(n, 2, "hello")
        ServidorPaxos.start_instancia(n3, 2, "hello")

        # A esperar a que decidan el mismo valor todos
        esperar_n_nodos(servidores, 2, length(servidores))
      
        IO.puts(" ... Superado")
    end


    # Tercer test
    test "Varios propo., varios valor", %{n1: n1, n2: n2, n3: n3} do
        IO.puts("Test: Varios propo., varios valor ...")

          # solicitar la ejecución de una instancia... en los  simultaneamente
        ServidorPaxos.start_instancia(n1, 3, "cuatro")
        ServidorPaxos.start_instancia(n2, 3, "dos")
        ServidorPaxos.start_instancia(n3, 3, "tres")

        # A esperar a que decidan el mismo valor todos
        esperar_n_nodos(servidores, 3, length(servidores))
      
        IO.puts(" ... Superado")
    end


    # ------------------ FUNCIONES DE APOYO A TESTS ------------------------

    defp esperar_n_nodos(servidores, numInstancia, n_deseados) do   
        Process.sleep(15)  # en milisegundos
    
        nuDecididos = num_decididos(servidores, numInstancia)
    
        if  nuDecididos < n_deseados do
            esperar_aun_mas_tiempo(servidores, numInstancia, n_deseados, 20, 1)

        else
            :ok
        end
    end

    defp esperar_aun_mas_tiempo(servidores,nuInstancia,nuDeseados,time,iter) do
        Process.sleep(time)  # en milisegundos
    
        nuDecididos = num_decididos(servidores, nuInstancia)
    
        if  nuDecididos < nuDeseados do
            cond  do
                time < 1000 ->
                    esperar_aun_mas_tiempo(servidores, nuInstancia,
                                                nuDeseados, time * 2, iter +1 )
                time >= 1000 ->
                    cond do
                        iter < 15   ->
                           esperar_aun_mas_tiempo(servidores, nuInstancia,
                                                    nuDeseados, time, iter + 1)
                        iter >= 15  -> # Ya ha pasado mucho tiempo
                           Process.exit(self(),"Han decidido MENOS de deseados")
                    end
            end
        else 
            :ok
        end
    end

    defp num_decididos(servidores, numInstancia) do 
        listParDec = for  serv <- servidores do
                        ServidorPaxos.estado(serv, numInstancia)
                     end
    
        listDecid = for {true, v} <- listParDec, do: v
         
        # todos los valores decididos deben ser idénticos
        iguales(listDecid)

        # si lo valores ha sido iguales, cuantos ha sido decididos ?  
        length(listDecid)
    end

    defp iguales([]), do: :ok
    defp iguales([ _A | [] ]), do: :ok
    defp iguales([primerValor | restoValoresDecid]) do
        List.foldl( restoValoresDecid,
                    primerValor,
                    fn(x,previo) -> 
                        if x === previo do
                            x
                        else # 2 valores no coinciden !!!!
                            exit("Valores decididos no coinciden !")
                        end
                    end )
    end

end

