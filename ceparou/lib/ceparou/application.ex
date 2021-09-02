defmodule Ceparou.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Ceparou.Router,
        options: [port: application_port()]
      ),
      %{
        id: Mongo,
        start: {
          Mongo,
          :start_link,
          [
            [
              name: :mongo,
              database: "podcloud",
              pool_size: 3,
              seeds: ["dave:27017"]
            ]
          ]
        },
        type: :worker
      },
      %{
        id: :redirect_cache_worker,
        start: {Cachex, :start_link, [:redirect_cache, []]}
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ceparou.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp application_port do
    System.get_env()
    |> Map.get("PORT", "4001")
    |> String.to_integer()
  end
end
