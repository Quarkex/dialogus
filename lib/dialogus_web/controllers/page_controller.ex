defmodule DialogusWeb.PageController do
  use DialogusWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
