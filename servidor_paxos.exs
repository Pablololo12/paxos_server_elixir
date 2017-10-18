# Compilar y cargar ficheros con modulos necesarios
Code.require_file("#{__DIR__}/nodo_remoto.exs")
Code.require_file("#{__DIR__}/proponedor.exs")
Code.require_file("#{__DIR__}/aceptador.exs")

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
        yo: nil 
        #completar esta estructura de datos con lo que se necesite

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
    
    # VUESTRO CODIGO AQUI
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
    
    # VUESTRO CODIGO AQUI
    {true, :ficticio}
  end

  @doc """
    La aplicación en el servidor nodo_paxos ya ha terminado
    con todas las instancias <= nu_instancia
    Mirar comentarios de min() para más explicaciones
    Devuelve :  :ok
  """
  @spec hecho(node, non_neg_integer) :: {boolean, String.t}
  def hecho(nodo_paxos, nu_instancia) do
    
    # VUESTRO CODIGO AQUI
    :ok

  end

  @doc """
    Aplicación quiere saber el máximo número de instancia que ha visto
    este servidor NodoPaxos
    Devuelve : NuInstancia
  """
  @spec maxi(node) :: non_neg_integer
  def maxi(nodo_paxos) do
    
    # VUESTRO CODIGO AQUI

  end

  @doc """
    Minima instancia vigente de entre todos los nodos Paxos
    Se calcula en función Aceptador.modificar_state_inst_y_hechos
    Devuelve : nu_instancia = hecho + 1
  """
  @spec mini(node) :: non_neg_integer
  def mini(nodo_paxos) do
    
    # VUESTRO CODIGO AQUI

  end

  @doc """
    Cambiar comportamiento de comunicación del Nodo Elixir a NO FIABLE
  """
  @spec comm_no_fiable(node) :: :comm_no_fiable
  def comm_no_fiable(nodo_paxos) do       
    send({:paxos, nodo_paxos}, :comm_no_fiable)
  end

  @doc """
    Limitar acceso de un Nodo a solo otro conjunto de Nodos,
    incluido este nodo de control
    Para SIMULAR particiones de red
  """
  @spec limitar_acceso(node, [node]) :: :ok
  def limitar_acceso(nodo_paxos, otros_nodos) do
    send({:paxos, nodo_paxos},{:limitar_acceso, otros_nodos ++ [node()]})
    :ok
  end

  @doc """
    Hacer que un servidor Paxos deje de escuchar cualquier mensaje,
    salvo 'escucha'
  """
  @spec ponte_sordo(node) :: :ponte_sordo
  def ponte_sordo(nodo_paxos) do
    send({:paxos, nodo_paxos},:ponte_sordo)
  end

  @doc """
    Hacer que un servidor Paxos deje de escuchar cualquier mensaje,
    salvo 'escucha'
  """
  @spec escucha(node) :: :escucha
  def escucha(nodo_paxos) do
    send({:paxos, nodo_paxos},:escucha)
  end

  @doc """
    Obtener numero de mensajes recibidos en un nodo
  """
  @spec n_mensajes(node) :: non_neg_integer
  def n_mensajes(nodo_paxos) do
    send({:paxos, nodo_paxos},{:n_mensajes, self()})
    receive do Respuesta -> Respuesta end
  end


  #------------------- Funciones privadas

  # La primera debe ser def (pública) para la llamada :
  # spawn_link(__MODULE__, init,[...])
  def init(servidores, yo) do
    Process.register(self(), :paxos)

    #### VUESTRO CODIGO DE INICIALIZACION
    IO.puts("Arrancando")

    bucle_recepcion(%ServidorPaxos{fiabilidad: :fiable,
        n_mensajes: 0,
        servidores: servidores,
        yo: yo})
  end

  defp bucle_recepcion(estado) do
    receive do
      :comm_no_fiable    ->
        poner_no_fiable(estado)
        bucle_recepcion(estado)

      :comm_fiable       ->
        poner_fiable(estado)
        bucle_recepcion(estado)
        
      {:es_fiable, Pid} -> 
        send(Pid, es_fiable?(estado))
        bucle_recepcion(estado)

      {:limitar_acceso, Nodos} ->
        #????????????
        bucle_recepcion(estado)    

      {:n_mensajes, Pid} ->
        send(Pid, ServidorPaxos.n_mensajes)
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
      :escucha ->
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

  defp gestion_mnsj_prop_y_acep(mensaje, estado) do

    # VUESTRO CODIGO AQUI
    
    bucle_recepcion(estado)
  end


  defp proponente(n, v, n_a, v_a) do
    
  end

end
