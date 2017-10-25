# Tests de Servidor Paxos con variante de particionamiento
# por cambio send y recepcion que posibilita particiones dinámicas en ejecución

# Compilar y cargar ficheros con modulos necesarios
Code.require_file("servidor_paxos.exs", __DIR__)
#Code.require_file("#{__DIR__}/servidor_paxos.exs")
#Code.require_file("#{__DIR__}/cliente_XX.exs")

#Poner en marcha el servicio de tests unitarios con tiempo de vida limitada
# seed: 0 para que la ejecucion de tests no tenga orden aleatorio
ExUnit.start([timeout: 20000, seed: 0, exclude: [:deshabilitado]]) # milisegundos

defmodule  ServicioPaxosTest do

    use ExUnit.Case

    # @moduletag timeout 100  para timeouts de todos los test de este modulo

    @host1 "127.0.0.1"

    # diversos tiempos de espera en milisegundos

    @tiempo_espera_inicial_decision 15

    @tiempo_espera_adicional_decision 20

    describe "Tests iniciales sin fallos con 3 nodos: " do
        setup do
            servidores = [:"n1@127.0.0.1", :"n2@127.0.0.1", :"n3@127.0.0.1"]
            n1 = ServidorPaxos.start(servidores, @host1, "n1")
            n2 = ServidorPaxos.start(servidores, @host1, "n2")
            n3 = ServidorPaxos.start(servidores, @host1, "n3")

            on_exit fn ->
                    #eliminar_nodos(n1, n2, n3)
                    IO.puts "Finalmente eliminamos los 3 nodos"
                    ServidorPaxos.stop(n1)
                    ServidorPaxos.stop(n2)
                    ServidorPaxos.stop(n3)                                    
                    end

            {:ok, [n1: n1, n2: n2, n3: n3, s: servidores]}
        end


        # Primer test
        # Funciona
        @tag :deshabilitado
        test "Unico proponente", %{n1: n1, s: servidores} do
            IO.puts("Test: Unico proponente ...")

            # solicitar la ejecución de una instancia
            ServidorPaxos.start_instancia(n1, 1, "hello")

            # A esperar a que decidan el mismo valor todos
            esperar_n_nodos(servidores, 1, length(servidores))

            IO.puts(" ... Superado")
        end


        # Segundo test
        #Funciona
        @tag :deshabilitado
        test "Varios propo., un valor", 
                                    %{n1: n1, n2: n2, n3: n3, s: servidores} do
            IO.puts("Test: Varios propo., un valor ...")

            # solicitar la ejecución de una instancia...en los 3 simultaneamente
            ServidorPaxos.start_instancia(n1, 2, "hello")
            ServidorPaxos.start_instancia(n2, 2, "hello")
            ServidorPaxos.start_instancia(n3, 2, "hello")

            # A esperar a que decidan el mismo valor todos
            esperar_n_nodos(servidores, 2, length(servidores))
          
            IO.puts(" ... Superado")
        end


        # Tercer test
        #Funciona
        @tag :deshabilitado
        test "Varios propo., varios valor",
                                        %{n1: n1, n2: n2, n3: n3, s: servers} do
            IO.puts("Test: Varios propo., varios valor ...")

            # solicitar la ejecución de una instancia...en los 3 simultaneamente
            ServidorPaxos.start_instancia(n1, 3, "cuatro")
            ServidorPaxos.start_instancia(n2, 3, "dos")
            ServidorPaxos.start_instancia(n3, 3, "tres")

            # A esperar a que decidan el mismo valor todos
            esperar_n_nodos(servers, 3, length(servers))
          
            IO.puts(" ... Superado")
        end

        # Cuarto test
        #Funciona
        @tag :deshabilitado
        test "Instancias fuera de orden",
                                        %{n1: n1, n2: n2, n3: n3, s: servers} do
            IO.puts("Test: Instancias fuera de orden ...")

            num_servidores = length(servers)

            # solicitar la ejecución de una instancia..en los 3 simultaneamente
            ServidorPaxos.start_instancia(n1, 7, 700)
            ServidorPaxos.start_instancia(n1, 6, 600)
            ServidorPaxos.start_instancia(n2, 5, 500)

            esperar_n_nodos(servers, 7, num_servidores)

            ServidorPaxos.start_instancia(n1, 4, 400)
            ServidorPaxos.start_instancia(n2, 3, 300)

            esperar_n_nodos(servers, 6, num_servidores)
            esperar_n_nodos(servers, 5, num_servidores)
            esperar_n_nodos(servers, 4, num_servidores)
            esperar_n_nodos(servers, 3, num_servidores)

            if ServidorPaxos.maxi(n1) !== 7 do
                exit("maxi(#{n1}) es erróneo")
            end
         
            IO.puts(" ... Superado")
        end    
    end

    describe "5 nodos para prueba con sordos: " do
        setup do
            # Poner en marcha nodos
            num_servidores = 5
            servidores = arrancar_nodos(num_servidores)

            on_exit fn ->
                        #eliminar_nodos
                        IO.puts "Finalmente eliminamos los 5 nodos"
                        parar_nodos(servidores)

                    end

            {:ok, [s: servidores, n_s: num_servidores]}
        end
        # Quinto test
        #Funciona
        @tag :deshabilitado
        test "Proponentes sordos", %{s: s, n_s: num_servidores} do
            IO.puts("Test: Proponentes sordos ...")

            # En primer nodo
            ServidorPaxos.start_instancia(Enum.at(s, 0), 1, "Buenas")

            esperar_n_nodos(s, 1, num_servidores)

            ServidorPaxos.ponte_sordo(Enum.at(s, 0))
            ServidorPaxos.ponte_sordo(Enum.at(s, 4))

            # En segundo nodo
            ServidorPaxos.start_instancia(Enum.at(s, 1), 2, "Adios")
            esperar_mayoria(s, 2)

            if num_decididos(s, 2) !== num_servidores - 2 do
                exit("Error : Algun sordo sabe decision con 2 sordos!!")
            end

            ServidorPaxos.escucha(Enum.at(s, 0))
            ServidorPaxos.start_instancia(Enum.at(s, 0), 1, "WWW")
            esperar_n_nodos(s, 1, num_servidores - 1)

            if num_decididos(s, 1) !== num_servidores - 1 do
                exit("Error : Algun sordo sabe decision con 1 sordo!!")
            end

            ServidorPaxos.escucha(Enum.at(s, 4))
            ServidorPaxos.start_instancia(Enum.at(s, 4), 2, "ZZZ")
            esperar_n_nodos(s, 2, num_servidores)

            IO.puts(" ... Superado")
        end
    end

    describe "6 nodos para olvidar registros: " do
        setup do
            # Poner en marcha nodos
            num_servidores = 6
            servidores = arrancar_nodos(num_servidores)

            on_exit fn ->
                        #eliminar_nodos
                        IO.puts "Finalmente eliminamos los 6 nodos"
                        parar_nodos(servidores)

                    end

            {:ok, [s: servidores, n_s: num_servidores]}
        end
        # Sexto test
        #Funciona
        @tag :deshabilitado
        test "Olvidando", %{s: s, n_s: num_servidores} do
            IO.puts("Test: Olvidando ...")
            
            # Comprobar mini inicial
            Enum.each(s, 
                      fn(nodo) -> 
                          if ServidorPaxos.mini(nodo) > 1 do
                              exit("1er mini erroneo en un servidor")
                          end
                      end)

            # Poner en marcha varios acuerdos
            ServidorPaxos.start_instancia(Enum.at(s, 0), 1, "11")        
            ServidorPaxos.start_instancia(Enum.at(s, 1), 2, "22")        
            ServidorPaxos.start_instancia(Enum.at(s, 2), 3, "33")        
            ServidorPaxos.start_instancia(Enum.at(s, 0), 7, "77")        
            ServidorPaxos.start_instancia(Enum.at(s, 1), 8, "88")        

            esperar_n_nodos(s, 2, num_servidores)
            
            # Comprobar mini, debería ser todavía 1
            Enum.each(s, 
                      fn(nodo) -> 
                          if ServidorPaxos.mini(nodo) > 1 do
                              exit("2º mini erroneo en un servidor")
                          end
                      end)

            # Hechos instancias 1 y 2 para todos -> cambia mini() ?
            Enum.each(s, fn(nodo) -> ServidorPaxos.hecho(nodo, 1) end)
            Enum.each(s, fn(nodo) -> ServidorPaxos.hecho(nodo, 2) end)
            Enum.each(List.zip([s, Enum.to_list(1..num_servidores)]), 
                  fn({x, y}) -> ServidorPaxos.start_instancia(x, 8 + y, "xx") end)
            Process.sleep(12)
            l_mini = for x <- s, do: ServidorPaxos.mini(x)
            all_3 = List.foldl(l_mini, true,
                               fn(x, previo) -> (x === 3) and previo end)
            if not all_3 do
                exit("mini() no ha avanzado despues de hecho() !")
            end

            IO.puts(" ... Superado")
        end
    end

    describe "3 nodos para muchas instancias: " do
        setup do
            # Poner en marcha nodos
            num_servidores = 3
            servidores = arrancar_nodos(num_servidores)

            on_exit fn ->
                        #eliminar_nodos
                        IO.puts "Finalmente eliminamos los 3 nodos"
                        parar_nodos(servidores)

                    end

            {:ok, [s: servidores, n_s: num_servidores]}
        end
        # Septimo test
        #Puede quiza debo revisar V en proponente
        @tag :deshabilitado
        test "Muchas instancias", %{s: s, n_s: num_serv} do
            # Ejecutar 10 lotes, cada uno de 3 instancias a la vez.
            # Es decir,  30 instancias en total
            Enum.each(1..10, 
                      fn(lote) ->
                          Enum.each((((lote - 1) * 3) + 1)..(lote * 3),
                              fn(i) ->
                                  if i >= 4 do
                                      esperar_n_nodos(s, i - 3, num_serv)
                                  end
                                  Enum.each(List.zip([s,
                                              Enum.to_list(1..num_serv)]),
                                            fn({x, y}) ->
                                                ServidorPaxos.start_instancia(
                                                              x, i, (i *10) + y)
                                            end)
                              end)
                      end)
                      
            # Esperar decisión de últimas 3 instancias
            Enum.each(28..30, fn(i) -> esperar_n_nodos(s, i, num_serv) end)

            IO.puts(" ... Superado")
        end
        # Octavo test
        #NO Funciona
        #@tag :deshabilitado
        test "Muchas instancias, comm. no fiable:", %{s: s, n_s: n_serv} do
            # Poner todos los nodos en comunicación no fiable
            Enum.each(s, fn(nodo) -> ServidorPaxos.comm_no_fiable(nodo) end)
            
            # Ejecutar 10 lotes, cada uno de 3 instancias a la vez.
            # Es decir,  30 instancias en total
            Enum.each(1..10, 
                      fn(lote) ->
                          Enum.each((((lote - 1) * 3) + 1)..(lote * 3),
                              fn(i) ->
                                  if i >= 4 do
                                      esperar_n_nodos(s, i - 3, n_serv)
                                  end
                                  Enum.each(List.zip([s,
                                              Enum.to_list(1..n_serv)]),
                                            fn({x, y}) ->
                                                ServidorPaxos.start_instancia(
                                                              x, i, (i *10) + y)
                                            end)
                              end)
                      end)
                      
            # Esperar decisión de últimas 3 instancias
            Enum.each(28..30, fn(i) -> esperar_n_nodos(s, i, n_serv) end)

            IO.puts(" ... Superado")
       end
    end
    
    describe "5 nodos para particionado sin decision" do
        setup do
            # Poner en marcha nodos
            num_servidores = 5
            # Arrancar con particiones con indice elementos desde indice 0
            servidores = arrancar_nodos(num_servidores, [ [0, 2], [1,3], [4] ])
                      
            on_exit fn ->
                        #eliminar_nodos
                        IO.puts "Finalmente eliminamos los 5 nodos"
                        parar_nodos(servidores)

                    end

            {:ok, [s: servidores]}
        end
        # Noveno test
        #Funciona
        @tag :deshabilitado
        test "No hay decisión si particionado", %{s: s} do
            particionar(s, [ [0, 2], [1,3], [4] ] )
        
            ServidorPaxos.start_instancia(Enum.at(s, 1), 1, "11")
            comprobar_max(s, 1, 0)
        end
   end
   
     describe "5 nodos para particiones con decision mayoritaria" do
        setup do
            # Poner en marcha nodos
            num_servidores = 5
            # Arrancar con particiones con indice elementos desde indice 0
            servidores = arrancar_nodos(num_servidores, [ [0], [1, 2, 3], [4] ])
                       
           on_exit fn ->
                        #eliminar_nodos
                        IO.puts "Finalmente eliminamos los 5 nodos"
                        parar_nodos(servidores)

                    end

            {:ok, [s: servidores]}
        end
        # Decimo test
        #Funciona
        @tag :deshabilitado
        test "Decision en particion mayoritaria", %{s: s} do
            particionar(s, [ [0], [1, 2, 3], [4] ] )
        
            ServidorPaxos.start_instancia(Enum.at(s, 1), 1, "11")
            esperar_mayoria(s, 1)
        end
    end
    
    # ------------------ FUNCIONES DE APOYO A TESTS ------------------------

    # Poner en marcha un nº determinado de nodos Elixir
    # con posibilidad de aplicar particiones con listas de indices de nodo
    defp arrancar_nodos(numero, lista_particiones \\ []) do
        servers = Enum.map(1..numero, 
              fn(n) -> String.to_atom("n" <> to_string(n) <> "@"<> @host1) end)

        Enum.each(1..numero,
              fn(n) -> ServidorPaxos.start(servers, @host1, "n" <> to_string(n))
              end)
        servers
    end

    # Parar un nº determinado de nodos Elixir
    defp parar_nodos(servers) do
        Enum.each(servers, fn(s) -> ServidorPaxos.stop(s) end)

        # Cada vez que se paran un conjunto de nodos
        # No hay que detener  epmd (con System.cmd("pkill, ["epmd"]) )
        # ya que el nodo en curso de testeo sigue funcionando
    end

    # Particionar el conjunto de nodos, limitando el acceso entre ellos
    defp particionar(s, lista_particiones) do
       Enum.each(lista_particiones, 
               fn(p_i) -> # pasar lista de nodos de part. a partir de  indices
                  p_no = Enum.map(p_i, fn(i) -> Enum.at(s,i) end)
                  Enum.each(p_no,
                            fn(x) -> ServidorPaxos.limitar_acceso(x, p_no) end)
               end)
               
       # Probar funcionamiento de particionado con trazas de mensajes
       # Process.sleep(100)
       # Enum.each(s, fn(n) -> Enum.each(s, fn(x) -> 
       #                                    ServidorPaxos.envia_llega(n, x) end)
       #                 end)
                        
    end
    
    # Comprobar que el nº de decididos no supera un valor máximo
    defp comprobar_max(servers, num_instancia, maxi) do
        Process.sleep(2000)
        
         nuDecididos = num_decididos(servers, num_instancia)
    
        if  nuDecididos > maxi do
            exit("Hay DEMASIADOS decididos !")
        end  
    end
    
    defp esperar_mayoria(servers, num_instancia) do
        esperar_n_nodos(servers, num_instancia, div(length(servers), 2) + 1)
    end

    defp esperar_n_nodos(servidores, numInstancia, n_deseados) do   
        Process.sleep(@tiempo_espera_inicial_decision)  # en milisegundos
    
        nuDecididos = num_decididos(servidores, numInstancia)
    
        if  nuDecididos < n_deseados do
            esperar_aun_mas_tiempo(servidores, numInstancia, n_deseados,
                                           @tiempo_espera_adicional_decision, 1)
        end
    end

    defp esperar_aun_mas_tiempo(servidores,nuInstancia,nuDeseados,time,iter) do
        Process.sleep(time)  # en milisegundos
    
        nuDecididos = num_decididos(servidores, nuInstancia)
    
        if  nuDecididos < nuDeseados do
            cond  do
                time < 1000 ->
                    esperar_aun_mas_tiempo(servidores, nuInstancia,
                                                nuDeseados, time * 2, iter + 1 )
                time >= 1000 ->
                    cond do
                        iter < 15   ->
                           esperar_aun_mas_tiempo(servidores, nuInstancia,
                                                    nuDeseados, time, iter + 1)
                        iter >= 15  -> # Ya ha pasado mucho tiempo
                           exit("Han decidido MENOS de deseados")
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
        #IO.inspect(  listParDec, label: "lista estados obtenidos")  
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

