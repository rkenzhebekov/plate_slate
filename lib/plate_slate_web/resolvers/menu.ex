defmodule PlateSlateWeb.Resolvers.Menu do
  alias PlateSlate.Menu
  import Absinthe.Resolution.Helpers, only: [async: 1]

  def menu_items(_, args, _) do
    {:ok, Menu.list_items(args)}
  end

  def menu_categories(_, args, _) do
    {:ok, Menu.list_categories(args)}
  end

  #def items_for_category(category, _, _) do
  #  query = Ecto.assoc(category, :items)
  #  {:ok, PlateSlate.Repo.all(query)}
  #end

  def search(_, %{matching: term}, _) do
    {:ok, Menu.search(term)}
  end

  def create_item(_, %{input: params}, _) do
    with {:ok, item} <- Menu.create_item(params) do
      {:ok, %{menu_item: item}}
    end
  end

  def update_item(_, %{input: params, id: id}, _) do
    item = Menu.get_item!(id)

    with {:ok, menu_item} <- Menu.update_item(item, params) do
      {:ok, %{menu_item: menu_item}}
    end
  end

  def error_details(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, _} -> msg end)
  end

  def items_for_category(category, _, _) do
    query = Ecto.assoc(category, :items)
    {:ok, PlateSlate.Repo.all(query)}
  end

  def category_for_item(menu_item, _, _) do
    async(fn ->
      query = Ecto.assoc(menu_item, :category)
      {:ok, PlateSlate.Repo.one(query)}
    end) |> IO.inspect
  end
end

