# Schoolbus
[![Build Status](https://github.com/rupurt/schoolbus/workflows/Test/badge.svg?branch=master)](https://github.com/rupurt/schoolbus/actions?query=workflow%3ATest)
[![hex.pm version](https://img.shields.io/hexpm/v/schoolbus.svg?style=flat)](https://hex.pm/packages/ex_deribit)

Manage one or more PubSub instances using the Elixir registry

## Installation

`schoolbus` requires Elixir 1.9+ & Erlang/OTP 21+

Add the `schoolbus` package to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:schoolbus, "~> 0.0.1"}]
end
```

## Usage

### The default single bus

Start the bus

```elixir
iex(1)> {:ok, _bus} = Schoolbus.start_link([])
{:ok, #PID<0.212.0>}
```

Register a topic

```elixir
iex(2)> Schoolbus.register(:games)
:ok
```

Register a namespaced topic

```elixir
iex(3)> Schoolbus.register({:songs, :diplo})
:ok
iex(4)> Schoolbus.register({:songs, :tiesto})
:ok
```

Subscribe to a registered topic

```elixir
iex(3)> Schoolbus.subscribers()
[]
iex(4)> Schoolbus.subscribe(:games)
{:ok, [:games]}
iex(5)> self()
#PID<0.208.0>
iex(6)> Schoolbus.subscribers()
[topic_a: #PID<0.208.0>]
```

Subscribe to all topics within a namespace

```elixir
iex(7)> Schoolbus.subscribers()
[topic_a: #PID<0.208.0>]
iex(8)> Schoolbus.subscribe({:songs, "*"})
{:ok, [:games, {:songs, :diplo}, {:songs, :tiesto}]}
iex(9)> self()
#PID<0.208.0>
iex(10)> Schoolbus.subscribers()
[topic_a: #PID<0.208.0>]
```

Broadcast a topic to all subscribers

```elixir
iex(11)> flush
:ok
iex(12)> Schoolbus.broadcast(:games, :uno)
:ok
iex(13)> flush
:uno
:ok
```

### Multiple buses

Start two buses

```elixir
iex(1)> {:ok, bus_a} = Schoolbus.start_link([id: :bus_a])
{:ok, #PID<0.210.0>}
iex(2)> {:ok, bus_b} = Schoolbus.start_link([id: :bus_b])
{:ok, #PID<0.220.0>}
```

Register the topics

```elixir
iex(3)> Schoolbus.register(:bus_a_topic, :bus_a)
:ok
iex(4)> Schoolbus.register(:bus_b_topic, :bus_b)
:ok
```

Subscribe to a registered topic

```elixir
iex(5)> Schoolbus.subscribers(:bus_a)
[]
iex(6)> Schoolbus.subscribers(:bus_b)
[]
iex(7)> Schoolbus.subscribe(:bus_a_topic, :bus_a)
{:ok, [:bus_a]}
iex(8)> Schoolbus.subscribe(:bus_b_topic, :bus_b)
{:ok, [:bus_b]}
iex(9)> self()
#PID<0.208.0>
iex(10)> Schoolbus.subscribers(:bus_a)
[bus_a_topic: #PID<0.208.0>]
iex(11)> Schoolbus.subscribers(:bus_b)
[bus_b_topic: #PID<0.208.0>]
```

Broadcast a topic to all subscribers

```elixir
iex(12)> flush
:ok
iex(13)> Schoolbus.broadcast(:bus_a_topic, :my_message_a, :bus_a)
:ok
iex(14)> flush
:my_message_a
:ok
iex(15)> Schoolbus.broadcast(:bus_a_topic, :my_message_b, :bus_b)
:ok
iex(16)> flush
:my_message_b
:ok
```

## Authors

* Alex Kwiatkowski - alex+git@rival-studios.com

## License

`schoolbus` is released under the [MIT license](./LICENSE.md)
