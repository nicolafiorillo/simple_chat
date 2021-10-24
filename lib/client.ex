defmodule Client do
  defstruct connection: nil, user: ""

  @type t :: __MODULE__

  @spec new(port) :: map
  def new(connection) do
    %__MODULE__{connection: connection, user: get_user_name(connection)}
  end

  @spec add(list(map), map) :: list(Client.t())
  def add(clients, client) do
    clients ++ [client]
  end

  @spec remove(list(Client.t()), port) :: list(Client.t())
  def remove(clients, connection) do
    Enum.filter(clients, fn client -> client.connection != connection end)
  end

  @spec all_clients_except(list(Client.t()), port) :: list(Client.t())
  def all_clients_except(clients, connection) do
    Enum.filter(clients, fn client -> client.connection != connection end)
  end

  @spec get_user(list(Client.t()), port) :: binary
  def get_user(clients, connection) do
    case Enum.find(clients, fn client -> client.connection == connection end) do
      nil -> ""
      c -> c.user
    end
  end

  @spec get_user_name(port) :: binary
  defp get_user_name(connection) do
    id =
      Port.info(connection)
      |> Keyword.get(:id)

    "User #{id}"
  end
end
