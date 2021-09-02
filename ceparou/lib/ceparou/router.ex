defmodule Ceparou.Router do
  use Plug.Router

  alias Ceparou.Stubs

  plug(Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["text/*"],
    json_decoder: Jason
  )

  plug(:match)
  plug(:dispatch)

  get "/ping" do
    send_resp(conn, 200, "pong")
  end

  get "/" do
    cursor = Mongo.find(:mongo, "feeds", %{}, limit: 10)

    cursor
    |> Enum.to_list()
    |> IO.inspect()

    Mongo.show_collections(:mongo) |> Enum.to_list() |> IO.inspect()

    render(conn, "index.html", portfolio: Stubs.portfolio_entries())
  end

  get "/:feed_id/:item_id/enclosure.*cache_key" do
    feed_id = conn.params["feed_id"]
    item_id = conn.params["item_id"]
    cache_key = conn.params["cache_key"]

    cache_key = "#{feed_id}_#{item_id}_#{cache_key |> Enum.join()}"

    with {:ok, enc_url} <- Cachex.get(:redirect_cache, cache_key),
         true <- is_binary(enc_url),
         true <- String.length(enc_url) > 0 do
      conn
      |> put_status(302)
      |> put_resp_header("location", enc_url)
      |> render_json(%{location: enc_url})
    else
      _ ->
        feed =
          Mongo.find_one(
            :mongo,
            "feeds",
            %{
              disabled: %{"$ne": true},
              draft: %{"$ne": true},
              "$or": [%{identifier: feed_id}, %{_slugs: feed_id}, %{_id: feed_id}]
            },
            sort: %{items_updated_at: -1, external: 1}
          )

        item =
          Mongo.find_one(
            :mongo,
            "items",
            %{
              feed_id: feed["_id"],
              "$or": [%{_slugs: item_id}, %{_id: item_id}]
            },
            sort: %{published_at: -1}
          )

        with enclosure <- Map.get(item, "enclosure"),
             true <- is_map(enclosure),
             meta_url <- Map.get(enclosure, "meta_url"),
             true <- is_map(meta_url),
             enc_url <- Map.get(meta_url, "path"),
             true <- is_binary(enc_url),
             enc_url <- enc_url |> String.trim(),
             true <- enc_url |> String.length() > 0 do
          Cachex.put(:redirect_cache, cache_key, enc_url)

          conn
          |> put_status(302)
          |> put_resp_header("location", enc_url)
          |> render_json(%{location: enc_url})
        else
          _ -> conn |> put_status(404) |> render_json(%{error: true})
        end
    end
  end

  get "/contact" do
    render(conn, "contact.html")
  end

  post "/contact" do
    Stubs.submit_contact(conn.params)
    render_json(conn, %{message: "Thank you! We will get back to you shortly."})
  end

  match _ do
    send_resp(conn, 404, "Oh no! What you seek cannot be found.")
  end

  @template_dir "lib/ceparou/templates"

  defp render(%{status: status} = conn, template, assigns \\ []) do
    body =
      @template_dir
      |> Path.join(template)
      |> String.replace_suffix(".html", ".html.eex")
      |> EEx.eval_file(assigns)

    send_resp(conn, status || 200, body)
  end

  defp render_json(%{status: status} = conn, data) do
    body = Jason.encode!(data)
    send_resp(conn, status || 200, body)
  end
end
