defmodule SchoolbusTest do
  use ExUnit.Case, async: false

  @other_bus :other
  @default_topics [:games, {:songs, :diplo}, {:songs, :prodigy}]
  @other_topics [:animals, {:songs, :rage_against_the_machine}]

  setup do
    start_supervised!({Schoolbus, topics: @default_topics})
    start_supervised!({Schoolbus, topics: @other_topics, id: @other_bus})
    :ok
  end

  describe ".topics/1 default event bus" do
    test "returns the list of registered topics" do
      topics = Schoolbus.topics()

      assert Enum.count(topics) == 3
      assert Enum.at(topics, 0) == :games
      assert Enum.at(topics, 1) == {:songs, :diplo}
      assert Enum.at(topics, 2) == {:songs, :prodigy}
    end
  end

  describe ".topics/1 named event bus" do
    test "returns the list of registered topics" do
      topics = Schoolbus.topics(@other_bus)

      assert Enum.count(topics) == 2
      assert Enum.at(topics, 0) == :animals
      assert Enum.at(topics, 1) == {:songs, :rage_against_the_machine}
    end
  end

  describe ".register/1 default event bus" do
    test "adds the registered topic" do
      assert Schoolbus.register({:songs, :tiesto}) == :ok

      topics = Schoolbus.topics()
      assert Enum.count(topics) == 4
      assert Enum.member?(topics, :games)
      assert Enum.member?(topics, {:songs, :diplo})
      assert Enum.member?(topics, {:songs, :prodigy})
      assert Enum.member?(topics, {:songs, :tiesto})
    end
  end

  describe ".register/2 named event bus" do
    test "adds the registered topic" do
      assert Schoolbus.register({:songs, :grinspoon}, @other_bus) == :ok

      topics = Schoolbus.topics(@other_bus)
      assert Enum.count(topics) == 3
      assert Enum.member?(topics, :animals)
      assert Enum.member?(topics, {:songs, :rage_against_the_machine})
      assert Enum.member?(topics, {:songs, :grinspoon})
    end
  end

  describe ".subscribe/1 default event bus - " do
    test "can subscribe to a single topic" do
      assert {:ok, topics} = Schoolbus.subscribe(:games)
      assert Enum.count(topics) == 1
      assert Enum.member?(topics, :games)

      assert {:ok, topics} = Schoolbus.subscribe({:songs, :diplo})
      assert Enum.count(topics) == 1
      assert Enum.member?(topics, {:songs, :diplo})
    end

    test "can subscribe to a wildcard match of topics" do
      assert {:ok, topics} = Schoolbus.subscribe({:songs, "*"})
      assert Enum.count(topics) == 2
      assert Enum.member?(topics, {:songs, :diplo})
      assert Enum.member?(topics, {:songs, :prodigy})
    end
  end

  describe ".subscribe/2 named event bus - " do
    test "can register to a single topic" do
      assert {:ok, topics} = Schoolbus.subscribe(:animals, @other_bus)
      assert Enum.count(topics) == 1
      assert Enum.member?(topics, :animals)

      assert {:ok, topics} = Schoolbus.subscribe({:songs, :rage_against_the_machine}, @other_bus)
      assert Enum.count(topics) == 1
      assert Enum.member?(topics, {:songs, :rage_against_the_machine})
    end

    test "can subscribe to a wildcard match of topics" do
      assert {:ok, topics} = Schoolbus.subscribe({:songs, "*"}, @other_bus)
      assert Enum.count(topics) == 1
      assert Enum.member?(topics, {:songs, :rage_against_the_machine})
    end
  end

  describe ".subscribers/1 default event bus - " do
    test "returns a list of topics and the subscribing pid" do
      assert {:ok, _} = Schoolbus.subscribe(:games)

      subscribers = Schoolbus.subscribers()
      assert Enum.count(subscribers) == 1
      assert Enum.at(subscribers, 0) == {:games, self()}
    end
  end

  describe ".subscribers/2 named event bus - " do
    test "returns a list of topics and the subscribing pid" do
      assert {:ok, _} = Schoolbus.subscribe({:songs, "*"}, @other_bus)

      subscribers = Schoolbus.subscribers(@other_bus)
      assert Enum.count(subscribers) == 1
      assert Enum.at(subscribers, 0) == {{:songs, :rage_against_the_machine}, self()}
    end
  end

  describe ".broadcast/1 default event bus - " do
    test "sends a message to all subscribers" do
      Schoolbus.subscribe(:games)
      Schoolbus.subscribe(:games)

      Schoolbus.broadcast(:games, :uno)

      assert_receive :uno
      assert_receive :uno
    end
  end

  describe ".broadcast/2 named event bus - " do
    test "sends a message to all subscribers" do
      Schoolbus.subscribe(:animals, @other_bus)
      Schoolbus.subscribe(:animals, @other_bus)

      Schoolbus.broadcast(:animals, :cats, @other_bus)

      assert_receive :cats
      assert_receive :cats
    end
  end

  describe ".unsubscribe/1 default event bus - " do
    test "removes the subscriber from the topic" do
      Schoolbus.subscribe(:games)
      Schoolbus.broadcast(:games, :uno)

      assert_receive :uno

      Schoolbus.unsubscribe(:games)
      Schoolbus.broadcast(:games, :uno)

      refute_receive :uno
    end
  end

  describe ".unsubscribe/2 named event bus - " do
    test "removes the subscriber from the topic" do
      Schoolbus.subscribe(:animals, @other_bus)
      Schoolbus.broadcast(:animals, :cats, @other_bus)

      assert_receive :cats

      Schoolbus.unsubscribe(:animals, @other_bus)
      Schoolbus.broadcast(:animals, :cats, @other_bus)

      refute_receive :cats
    end
  end
end
