# Schoolbus
[![Build Status](https://github.com/rupurt/schoolbus/workflows/test/badge.svg?branch=main)](https://github.com/rupurt/schoolbus/actions?query=workflow%3Atest)
[![hex.pm version](https://img.shields.io/hexpm/v/schoolbus.svg?style=flat)](https://hex.pm/packages/schoolbus)

Manage one or more PubSub instances using the Elixir registry

## Installation

`schoolbus` requires Elixir 1.9+ & Erlang/OTP 21+

Add the `schoolbus` package to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:schoolbus, "~> 0.0.3"}]
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
[games: #PID<0.208.0>]
```

Subscribe to all topics within a namespace

```elixir
iex(7)> Schoolbus.subscribers()
[games: #PID<0.208.0>]
iex(8)> Schoolbus.subscribe({:songs, "*"})
{:ok, [songs: :diplo, songs: :tiesto]}
iex(9)> self()
#PID<0.208.0>
iex(10)> Schoolbus.subscribers()
[
  {{:songs, :tiesto}, #PID<0.208.0>},
  {{:songs, :diplo}, #PID<0.208.0>},
  {:games, #PID<0.208.0>}
]
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

Define two buses

`BusA`:

```elixir
iex(1)> defmodule BusA do
...(1)>   use Schoolbus.Bus
...(1)> end
{:module, BusA,
 <<70, 79, 82, 49, 0, 0, 16, 196, 66, 69, 65, 77, 65, 116, 85, 56, 0, 0, 2, 32,
   0, 0, 0, 53, 11, 69, 108, 105, 120, 105, 114, 46, 66, 117, 115, 65, 8, 95,
   95, 105, 110, 102, 111, 95, 95, 7, 99, ...>>, {:registered_topics, 0}}
```

`BusB`:

```elixir
iex(2)> defmodule BusB do
...(2)>   use Schoolbus.Bus
...(2)> end
{:module, BusB,
 <<70, 79, 82, 49, 0, 0, 16, 200, 66, 69, 65, 77, 65, 116, 85, 56, 0, 0, 2, 32,
   0, 0, 0, 53, 11, 69, 108, 105, 120, 105, 114, 46, 66, 117, 115, 66, 8, 95,
   95, 105, 110, 102, 111, 95, 95, 7, 99, ...>>, {:registered_topics, 0}}
```

Start the two buses

```elixir
iex(1)> {:ok, _bus_a} = BusA.start_link([])
{:ok, #PID<0.210.0>}
iex(2)> {:ok, _bus_b} = BusB.start_link([])
{:ok, #PID<0.220.0>}
```

Register the topics

```elixir
iex(3)> BusA.register(:bus_a_topic)
:ok
iex(4)> BusB.register(:bus_b_topic)
:ok
```

Subscribe to a registered topic

```elixir
iex(5)> BusA.subscribers()
[]
iex(6)> BusB.subscribers()
[]
iex(7)> BusA.subscribe(:bus_a_topic)
{:ok, [:bus_a_topic]}
iex(8)> BusB.subscribe(:bus_b_topic)
{:ok, [:bus_b_topic]}
iex(9)> self()
#PID<0.208.0>
iex(10)> BusA.subscribers()
[bus_a_topic: #PID<0.208.0>]
iex(11)> BusB.subscribers()
[bus_b_topic: #PID<0.208.0>]
```

Broadcast a topic to all subscribers

```elixir
iex(12)> flush
:ok
iex(13)> BusA.broadcast(:bus_a_topic, :my_message_a)
:ok
iex(14)> flush
:my_message_a
:ok
iex(15)> BusB.broadcast(:bus_a_topic, :my_message_b)
:ok
iex(16)> flush
:my_message_b
:ok
```

## Authors

* Alex Kwiatkowski - alex+git@rival-studios.com

## License

`schoolbus` is released under the [MIT license](./LICENSE.md)
