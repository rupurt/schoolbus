defmodule Schoolbus do
  @moduledoc File.read!("README.md")

  @type bus_id :: atom
  @type topic :: atom | {atom, atom}
  @type topic_match :: topic | {atom, String.t()}
  @type subscription :: {topic, pid}
  @type topics_opt :: {:topics, [topic]}
  @type partitions_opt :: {:partitions, pos_integer}
  @type bus_id_opt :: {:id, bus_id}
  @type option :: topics_opt | partitions_opt | bus_id_opt

  @default_id :default

  @spec child_spec(opts :: term) :: Supervisor.child_spec()
  def child_spec(opts) do
    id = get_id(opts)

    %{
      id: :"#{__MODULE__}_#{id}",
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor,
      restart: :permanent,
      shutdown: 500
    }
  end

  @spec start_link([option]) :: {:ok, pid} | {:error, term}
  def start_link(opts) do
    partitions = Keyword.get(opts, :partitions, System.schedulers_online())
    topics = Keyword.get(opts, :topics, [])
    id = get_id(opts)
    name = to_name(id)

    Registry.start_link(
      keys: :duplicate,
      name: name,
      partitions: partitions,
      meta: [topics: topics]
    )
  end

  @spec to_name(bus_id) :: atom
  def to_name(id), do: :"#{__MODULE__}_#{id}"

  @spec topics :: [topic]
  @spec topics(bus_id) :: [topic]
  def topics(id \\ @default_id) do
    {:ok, topics} = id |> to_name |> Registry.meta(:topics)
    topics
  end

  @spec register(topic) :: :ok
  @spec register(topic, bus_id) :: :ok
  def register(topic, id \\ @default_id) do
    id
    |> to_name
    |> Registry.put_meta(:topics, [topic | topics(id)])
  end

  @spec subscribers :: [subscription]
  @spec subscribers(bus_id) :: [subscription]
  def subscribers(id \\ @default_id) do
    id
    |> to_name
    |> Registry.select([
      {
        {:"$1", :"$2", :"$3"},
        [],
        [{{:"$1", :"$2"}}]
      }
    ])
  end

  @spec subscribe(topic_match) :: {:ok, [topic]}
  @spec subscribe(topic_match, bus_id) :: {:ok, [topic]}
  def subscribe(topic), do: subscribe(topic, @default_id)

  def subscribe({subscribe_namespace, "*"}, bus_id) do
    bus_id
    |> registered_topics()
    |> Enum.reduce(
      {:ok, []},
      fn rt, {:ok, subscribed_topics} = acc ->
        registered_namespace = topic_namespace(rt)

        if subscribe_namespace == registered_namespace do
          {:ok, _} = bus_id |> to_name |> Registry.register(rt, [])
          {:ok, [rt | subscribed_topics]}
        else
          acc
        end
      end
    )
  end

  def subscribe(topic, bus_id) do
    bus_id
    |> registered_topics()
    |> Enum.member?(topic)
    |> case do
      true ->
        {:ok, _} = bus_id |> to_name |> Registry.register(topic, [])
        {:ok, [topic]}

      false ->
        {:ok, []}
    end
  end

  @spec unsubscribe(topic) :: :ok
  @spec unsubscribe(topic, bus_id) :: :ok
  def unsubscribe(topic, id \\ @default_id) do
    id
    |> to_name
    |> Registry.unregister(topic)
  end

  @spec broadcast(topic, term) :: :ok
  @spec broadcast(topic, term, bus_id) :: :ok
  def broadcast(topic, message, id \\ @default_id) do
    id
    |> to_name
    |> Registry.dispatch(
      topic,
      fn entries ->
        for {pid, _} <- entries, do: send(pid, message)
      end
    )
  end

  defp get_id(opts), do: Keyword.get(opts, :id, @default_id)

  defp topic_namespace({namespace, _}), do: namespace
  defp topic_namespace(namespace), do: namespace

  defp registered_topics(bus_id) do
    {:ok, topics} = bus_id |> to_name |> Registry.meta(:topics)
    topics
  end
end
