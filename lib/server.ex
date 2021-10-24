defmodule Server do
  @moduledoc """
  SimpleChat server.
  """

  use GenServer
  require Logger

  defp port(), do: Application.get_env(:simple_chat, :port, 10_000)
  defp ip_addr(), do: Application.get_env(:simple_chat, :ip_addr, {0, 0, 0, 0})

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec init(any) :: {:ok, list(Client.t())}
  def init(_opts) do
    Logger.info("Starting server on port #{port()}...")

    {:ok, socket} =
      :gen_tcp.listen(port(), [:binary, {:packet, 0}, {:active, true}, {:ip, ip_addr()}])

    Logger.info("Listening...")
    pid = self()

    spawn_link(fn ->
      loop(socket, pid)
    end)

    # List of connected clients
    {:ok, []}
  end

  defp loop(socket, parent_pid) do
    case :gen_tcp.accept(socket) do
      {:ok, connection} ->
        :gen_tcp.controlling_process(connection, parent_pid)
        Server.add_connection(connection)

      err ->
        Logger.error("Error receiving data from client: #{inspect(err)}")
    end

    loop(socket, parent_pid)
  end

  def add_connection(connection),
    do: GenServer.cast(__MODULE__, {:add_connection, connection})

  def remove_connection(connection),
    do: GenServer.cast(__MODULE__, {:remove_connection, connection})

  def clients(),
    do: GenServer.call(__MODULE__, :clients)

  #
  # Callbacks
  #

  def handle_call(:clients, _from, clients) do
    {:reply, clients, clients}
  end

  def handle_cast({:add_connection, connection}, clients) do
    client = Client.new(connection)

    send_message(
      connection,
      "#########################################################\n" <>
      "Welcome to SimpleChat.\nThere are #{length(clients)} other people here and you are '#{client.user}'\nType '\q' to quit.\n" <>
      "#########################################################"
    )

    Logger.debug("Connection added: #{inspect(client)}")

    clients = Client.add(clients, client)
    {:noreply, clients}
  end

  def handle_cast({:remove_connection, connection}, clients) do
    Logger.debug("Connection removed: #{inspect(connection)}")
    {:noreply, Client.remove(clients, connection)}
  end

  def handle_info({:tcp, connection, data}, clients) do
    data = String.trim(data)

    clients =
      case apply_command(data) do
        :continue ->
          user = Client.get_user(clients, connection)
          Client.all_clients_except(clients, connection)
          |> send_message("#{user}: #{data}")

          clients
        :quit ->
          :gen_tcp.close(connection)
          Client.remove(clients, connection)
      end

    {:noreply, clients}
  end

  def handle_info({:tcp_closed, connection}, clients) do
    Logger.debug("Client lost.")
    :gen_tcp.close(connection)
    {:noreply, Client.remove(clients, connection)}
  end

  def handle_info({:tcp_error, _connection, reason}, clients) do
    Logger.error("Client error: #{inspect(reason)}")
    {:noreply, clients}
  end

  defp send_message(clients, message) when is_list(clients) do
    Enum.each(clients, fn client ->
      send_message(client.connection, message)
    end)
  end

  defp send_message(connection, message) do
    :gen_tcp.send(connection, "#{message}\n")
  end

  defp apply_command("\\q"), do: :quit
  defp apply_command(_data), do: :continue
end
