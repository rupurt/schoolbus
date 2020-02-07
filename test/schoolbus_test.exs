defmodule SchoolbusTest do
  use ExUnit.Case, async: false

  @topics [:games, {:songs, :diplo}, {:songs, :prodigy}]

  setup do
    start_supervised!({Schoolbus, topics: @topics})
    :ok
  end

  describe ".topics/1" do
    test "returns the list of registered topics" do
      topics = Schoolbus.topics()

      assert Enum.count(topics) == 3
      assert Enum.at(topics, 0) == :games
      assert Enum.at(topics, 1) == {:songs, :diplo}
      assert Enum.at(topics, 2) == {:songs, :prodigy}
    end
  end

  describe ".register/1" do
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

  describe ".subscribe/1" do
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

  describe ".subscribers/1" do
    test "returns a list of topics and the subscribing pid" do
      assert {:ok, _} = Schoolbus.subscribe(:games)

      subscribers = Schoolbus.subscribers()
      assert Enum.count(subscribers) == 1
      assert Enum.at(subscribers, 0) == {:games, self()}
    end
  end

  describe ".broadcast/1" do
    test "sends a message to all subscribers" do
      Schoolbus.subscribe(:games)
      Schoolbus.subscribe(:games)

      Schoolbus.broadcast(:games, :uno)

      assert_receive :uno
      assert_receive :uno
    end
  end

  describe ".unsubscribe/1" do
    test "removes the subscriber from the topic" do
      Schoolbus.subscribe(:games)
      Schoolbus.broadcast(:games, :uno)

      assert_receive :uno

      Schoolbus.unsubscribe(:games)
      Schoolbus.broadcast(:games, :uno)

      refute_receive :uno
    end
  end
end
