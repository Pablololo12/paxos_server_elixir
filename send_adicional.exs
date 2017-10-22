# Posibilidad de send con inclusion automatica de nodo emisor
# Que posibilita particiones dinámicas en ejecución

defmodule Send do

    @doc """
        Send.con_nodo_emisor : nodo emisor dentro del mensaje,
        junto a mensaje original
    """
    @spec con_nodo_emisor(pid | atom | {atom, node}, any) :: any
    def con_nodo_emisor(destino, mensaje) do
        send(destino, {node(), mensaje})
    end

end
