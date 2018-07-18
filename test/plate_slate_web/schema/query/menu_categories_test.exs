defmodule PlateSlateWeb.Schema.Query.MenuCategoriesTest do
  use PlateSlateWeb.ConnCase, async: true

  setup do
    PlateSlate.Seeds.run()
  end

  @query """
  {
    categories {
      name
    }
  }
  """

  test "categories field returns menu categories" do
    conn = build_conn()
    conn = get conn, "/api", query: @query

    assert json_response(conn, 200) == %{
      "data" => %{
        "categories" => [
          %{"name" => "Beverages"},
          %{"name" => "Sandwiches"},
          %{"name" => "Sides"},
        ]
      }
    }
  end

  @query """
  {
    categories(matching: "Sid") {
      name
    }
  }
  """
  test "categories field returns menu items filtered by name" do
    conn = build_conn()
    conn = get conn, "/api", query: @query

    assert json_response(conn, 200) == %{
      "data" => %{
        "categories" => [
          %{"name" => "Sides"}
        ]
      }
    }
  end

end
