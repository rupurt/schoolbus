defmodule Schoolbus.Bus do
  defmacro __using__(_) do
    quote do
      @type topic :: atom | {atom, atom}
      @type topic_match :: topic | {atom, String.t()}
      @type subscription :: {topic, pid}
      @type topics_opt :: {:topics, [topic]}
      @type partitions_opt :: {:partitions, pos_integer}
      @type option :: topics_opt | partitions_opt

      @spec child_spec(opts :: term) :: Supervisor.child_spec()
      def child_spec(opts) do
        %{
          id: __MODULE__,
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

        Registry.start_link(
          keys: :duplicate,
          name: __MODULE__,
          partitions: partitions,
          meta: [topics: topics]
        )
      end

      @spec topics :: [topic]
      def topics do
        {:ok, topics} = Registry.meta(__MODULE__, :topics)
        topics
      end

      @spec register(topic) :: :ok
      def register(topic) do
        Registry.put_meta(__MODULE__, :topics, [topic | topics()])
      end

      @spec subscribers :: [subscription]
      def subscribers do
        __MODULE__
        |> Registry.select([
          {
            {:"$1", :"$2", :"$3"},
            [],
            [{{:"$1", :"$2"}}]
          }
        ])
      end

      @spec subscribe(topic_match) :: {:ok, [topic]}
      def subscribe({subscribe_namespace, "*"}) do
        registered_topics()
        |> Enum.reduce(
          {:ok, []},
          fn rt, {:ok, subscribed_topics} = acc ->
            registered_namespace = topic_namespace(rt)

            if subscribe_namespace == registered_namespace do
              {:ok, _} = Registry.register(__MODULE__, rt, [])
              {:ok, [rt | subscribed_topics]}
            else
              acc
            end
          end
        )
      end

      def subscribe(topic) do
        registered_topics()
        |> Enum.member?(topic)
        |> case do
          true ->
            {:ok, _} = Registry.register(__MODULE__, topic, [])
            {:ok, [topic]}

          false ->
            {:ok, []}
        end
      end

      @spec unsubscribe(topic) :: :ok
      def unsubscribe(topic) do
        Registry.unregister(__MODULE__, topic)
      end

      @spec broadcast(topic, term) :: :ok
      def broadcast(topic, message) do
        __MODULE__
        |> Registry.dispatch(
          topic,
          fn entries ->
            for {pid, _} <- entries, do: send(pid, message)
          end
        )
      end

      defp topic_namespace({namespace, _}), do: namespace
      defp topic_namespace(namespace), do: namespace

      defp registered_topics do
        {:ok, topics} = Registry.meta(__MODULE__, :topics)
        topics
      end
    end
  end
end
