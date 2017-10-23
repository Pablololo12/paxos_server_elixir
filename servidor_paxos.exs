# Compilar y cargar ficheros con modulos necesarios
Code.require_file("#{__DIR__}/nodo_remoto.exs")
Code.require_file("#{__DIR__}/proponedor.exs")
Code.require_file("#{__DIR__}/aceptador.exs")
Code.require_file("#{__DIR__}/send_adicional.exs")

defmodule ServidorPaxos do

  @moduledoc """
    modulo del servicio de vistas
  """

  # Tipo estructura de datos que guarda el estado del servidor Paxos
  # COMPLETAR  con lo campos necesarios para gestionar
  # el estado del gestor de vistas

  defstruct   fiabilidad: :fiable,
        n_mensajes: 0,
        servidores: [],
        yo: nil,
        nodos_accesibles: [],
        #completar esta estructura de datos con lo que se necesite
        instancias: %{},
        proponentes: %{},
        aceptadores: %{}

  @timeout 50


  @doc """
    Crear y poner en marcha un servidor Paxos
    Los nombres Elixir completos de todos los servidores están en servidores
    Y el nombre de máquina y nombre nodo Elixir de este servidor están en 
    host y nombre_nodo
    Devuelve :  :ok.

  """
  @spec start([atom], String.t, String.t) :: atom
  def start(servidores, host, nombre_nodo) do
    nodo = NodoRemoto.start(host, nombre_nodo,__ENV__.file, __MODULE__)
    Process.flag(:trap_exit, true)
    Node.spawn_link(nodo, __MODULE__, :init, [servidores, nodo])
    nodo
  end

  @doc """
    Parar un servidor Paxos
    Devuelve : :ok
  """
  @spec stop(node) :: :ok
  def stop(nodo_paxos) do
    nodo = NodoRemoto.stop(nodo_paxos)
    vaciar_buzon()
  end

  @doc """
    Vaciar buzón del proceso en curso (denominado flush en iex)
    Devuelve : :ok
  """
  @spec vaciar_buzon() :: :ok
  def vaciar_buzon() do
    receive do 
      _ -> vaciar_buzon()
    after   0 -> :ok
    end
  end

  @doc """
    Petición de inicio de proceso de acuerdo para una instancia nu_instancia
    con valor propuesto valor, al servidor Paxos  nodo_paxos
    Devuelve de inmediato:  :ok
  """
  @spec start_instancia(node, non_neg_integer, String.t) :: :ok
  def start_instancia(nodo_paxos, nu_instancia, valor) do
    Send.con_nodo_emisor({:paxos, nodo_paxos}, {:start_instancia, nu_instancia, valor})
    :ok
  end

  @doc """
    La aplicación quiere saber si el servidor nodo_paxos opina que
    la instancia nu_instancia ya se ha decidido.
    Solo debe mirar el servidor NodoPaxos sin contactar con ningún otro
    Devuelve : {Decidido :: bool, valor}
  """
  @spec estado(node, non_neg_integer) :: {boolean, String.t}
  def estado(nodo_paxos, nu_instancia) do
    Send.con_nodo_emisor({:paxos, nodo_paxos}, {:estado, nu_instancia, self()})
    receive do
      {:estado, elegido, valor} ->
        {elegido, valor}
      after @timeout ->
        {false, :ficticio}
    end
  end

  @doc """
    La aplicación en el servidor nodo_paxos ya ha terminado
    con todas las instancias <= nu_instancia
    Mirar comentarios de min() para más explicaciones
    Devuelve :  :ok
  """
  @spec hecho(node, non_neg_integer) :: {boolean, String.t}
  def hecho(nodo_paxos, nu_instancia) do
    
    Send.con_nodo_emisor({:paxos, nodo_paxos}, {:hecho, self(), nu_instancia})
    receive do
      {:hecho, valor} ->
        valor
      after @timeout ->
        false
    end

  end

  @doc """
    Aplicación quiere saber el máximo número de instancia que ha visto
    este servidor NodoPaxos
    Devuelve : NuInstancia
  """
  @spec maxi(node) :: non_neg_integer
  def maxi(nodo_paxos) do
    
    Send.con_nodo_emisor({:paxos, nodo_paxos}, {:maxi, self()})
    receive do
      {:maxi, valor} ->
        valor
      after @timeout ->
        0
    end

  end

  @doc """
    Minima instancia vigente de entre todos los nodos Paxos
    Se calcula en función Aceptador.modificar_state_inst_y_hechos
    Devuelve : nu_instancia = hecho + 1
  """
  @spec mini(node) :: non_neg_integer
  def mini(nodo_paxos) do
    
    Send.con_nodo_emisor({:paxos, nodo_paxos}, {:mini, self()})
    receive do
      {:mini, valor} ->
        valor
      after @timeout ->
        0
    end

  end

  @doc """
    Cambiar comportamiento de comunicación del Nodo Elixir a NO FIABLE
  """
  @spec comm_no_fiable(node) :: :comm_no_fiable
  def comm_no_fiable(nodo_paxos) do       
    Send.con_nodo_emisor({:paxos, nodo_paxos}, :comm_no_fiable)
  end

  @doc """
    Limitar acceso de un Nodo a solo otro conjunto de Nodos,
    incluido este nodo de control
    Para SIMULAR particiones de red
  """
  @spec limitar_acceso(node, [node]) :: :ok
  def limitar_acceso(nodo_paxos, otros_nodos) do
    Send.con_nodo_emisor({:paxos, nodo_paxos},{:limitar_acceso, otros_nodos ++ [node()]})
    :ok
  end

  @doc """
    Hacer que un servidor Paxos deje de escuchar cualquier mensaje,
    salvo 'escucha'
  """
  @spec ponte_sordo(node) :: :ponte_sordo
  def ponte_sordo(nodo_paxos) do
    Send.con_nodo_emisor({:paxos, nodo_paxos},:ponte_sordo)
  end

  @doc """
    Hacer que un servidor Paxos deje de escuchar cualquier mensaje,
    salvo 'escucha'
  """
  @spec escucha(node) :: :escucha
  def escucha(nodo_paxos) do
    Send.con_nodo_emisor({:paxos, nodo_paxos},:escucha)
  end

  @doc """
    Obtener numero de mensajes recibidos en un nodo
  """
  @spec n_mensajes(node) :: non_neg_integer
  def n_mensajes(nodo_paxos) do
    Send.con_nodo_emisor({:paxos, nodo_paxos},{:n_mensajes, self()})
    receive do Respuesta -> Respuesta end
  end


  #------------------- Funciones privadas

  # La primera debe ser def (pública) para la llamada :
  # spawn_link(__MODULE__, init,[...])
  def init(servidores, yo) do
    Process.register(self(), :paxos)

    bucle_recepcion(%ServidorPaxos{fiabilidad: :fiable,
        n_mensajes: 0,
        servidores: servidores,
        yo: yo})
  end

  defp bucle_recepcion(estado) do
    estado = %{estado | n_mensajes: estado.n_mensajes + 1}
    # Obtener mensaje si viene de misma particion, y procesarlo
    case filtra_recepcion(estado.nodos_accesibles) do
      :invalido ->    # se ignora este tipo de mensaje
        bucle_recepcion(estado)
      :comm_no_fiable    ->
        poner_no_fiable(estado)
        bucle_recepcion(estado)

      :comm_fiable       ->
        poner_fiable(estado)
        bucle_recepcion(estado)
        
      {:es_fiable, pid} -> 
        send(pid, es_fiable?(estado))
        bucle_recepcion(estado)

      {:limitar_acceso, nodos} ->
        estado = %{estado | nodos_accesibles: nodos}
        bucle_recepcion(estado)    

      {:n_mensajes, pid} ->
        send(pid, ServidorPaxos.n_mensajes)
        bucle_recepcion(estado)
      
      :ponte_sordo -> espero_escucha(estado);

      {'EXIT', _pid, dato_devuelto} -> 
        # Cuando proceso proponente acaba
  
        # VUESTRO CODIGO AQUI

        bucle_recepcion(estado)

      # mensajes para proponente y aceptador del servidor local
      mensajes_prop_y_acept ->
        simula_fallo_mensj_prop_y_acep(mensajes_prop_y_acept, estado)
    end
  end

  defp filtra_recepcion(nodos_accesibles) do
    receive do
      {nodo_emisor, mensaje} ->
        case nodos_accesibles do
          [] -> mensaje # no hay limitacion red de este nodo receptor 
          nodos_acc ->
            # nodo emisor esta en misma particion de nodo receptor
            if Enum.member?(nodos_acc, nodo_emisor), do: mensaje,
            # si NO lo esta, el mensaje NO se admite
            else: :invalido  # nodo emisor NO es accesible
        end
      otro_msj ->
        exit("Error: función filtra_recepcion, mensaje : #{otro_msj}")
    end
  end

  defp poner_no_fiable(estado) do
    estado = %{estado | fiabilidad: :nofiable}
  end

  defp poner_fiable(estado) do
    estado = %{estado | fiabilidad: :fiable}
  end

  defp es_fiable?(estado) do
    estado.fiabilidad==:fiable
  end

  defp espero_escucha(estado) do
    IO.puts("#{node()} : Esperando a recibir escucha")
    receive do
      {pid, :escucha} ->
        IO.puts("#{node()} : Salgo de la sordera !!")
        bucle_recepcion(estado)
      
      _resto -> espero_escucha(estado)
    end
  end
  
  defp simula_fallo_mensj_prop_y_acep(mensaje, estado) do
    fiable = es_fiable?(estado)
      # utilizamos el modulo de numeros aleatorios de Erlang "rand"
    aleatorio = :rand.uniform(1000)
    
    #si no fiable, eliminar mensaje con cierta aleatoriedad
    if  ((not fiable) and (aleatorio < 200)) do 
      bucle_recepcion(estado);
          
    else  # Y si lo es tratar el mensaje recibido correctamente
      gestion_mnsj_prop_y_acep(mensaje, estado)
    end
  end

  defp minimo(colection, [h|t]) do
    if colection[h] != nil do
      h
    else
      minimo(colection, t)
    end
  end
  defp minimo(colection, []) do
    0
  end

  defp hecho(colection, [h|t], val) do
    if h <= val do
      hecho(Map.delete(colection, h), t, val)
    else
      colection
    end
  end
  defp hecho(colection, [], val) do
    colection
  end

  defp gestion_mnsj_prop_y_acep(mensaje, estado) do

    case mensaje do
      {:estado, nu_instancia, pid} ->
        if estado.instancias[nu_instancia] == nil do
          send(pid, {:estado, false, :ficticio})
        else
          IO.inspect(estado.instancias[nu_instancia])
          send(pid, {:estado, true, estado.instancias[nu_instancia]})
        end
      {:start_instancia, nu_instancia, valor} ->
        if estado.aceptadores[nu_instancia] == nil do
          acep = Aceptador.crear_aceptador(nu_instancia)
          estado = %{estado | aceptadores: Map.put(estado.aceptadores,
                                                   nu_instancia,acep)}
        end
        if estado.proponentes[nu_instancia] == nil do
          prop = Proponedor.crear_proponedor(estado.servidores,
                                             nu_instancia, valor, self())
          estado = %{estado | proponentes: Map.put(estado.proponentes,
                                                   nu_instancia,prop)}
        end
      {:hecho, pid, val} ->
        ret = hecho(estado.instancias, Enum.sort(Map.keys(estado.instancias)),val)
        estado = %{estado | instancias: ret}
        send(pid, {:hecho, true})
      {:maxi, pid} ->
        maximo = Enum.max(Map.keys(estado.instancias))
        send(pid, {:maxi, maximo})
      {:mini, pid} ->
        minimo = minimo(estado.instancias, Enum.sort(Map.keys(estado.instancias)))
        send(pid, {:mini, minimo})
      # Mensajes recibidos de proponente
      {:prepara, n, nu_instancia, pid} ->
        if estado.aceptadores[nu_instancia] == nil do
          acep = Aceptador.crear_aceptador(nu_instancia)
          estado = %{estado | aceptadores: Map.put(estado.aceptadores,
                                                   nu_instancia,acep)}
        end
        send(estado.aceptadores[nu_instancia], {:prepara, n, pid})
      {:acepta, n, v, nu_instancia, pid} ->
        send(estado.aceptadores[nu_instancia], {:acepta, n, v, pid})
      {:decidido, v, nu_instancia} ->
        estado = %{estado | instancias: Map.put(estado.instancias,
                                                nu_instancia, v)}
      # Mensajes recibidos de aceptadores
      {:prepare_ok, n, n_a, v_a, nu_instancia} ->
        send(estado.proponentes[nu_instancia], {:prepare_ok, n, n_a, v_a})
      {:prepare_reject, n_p, nu_instancia} ->
        send(estado.proponentes[nu_instancia], {:prepare_reject, n_p})
      {:acepta_ok, n, nu_instancia} ->
        send(estado.proponentes[nu_instancia], {:acepta_ok, n})
      {:acepta_reject, n_p, nu_instancia} ->
        send(estado.proponentes[nu_instancia], {:acepta_reject, n_p})
      _ ->
        IO.puts("Algo raro ha pasado en gestion_mnsj_prop_y_acep")
        IO.inspect(mensaje)
    end
    
    bucle_recepcion(estado)
  end

end
