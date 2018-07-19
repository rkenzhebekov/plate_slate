defmodule PlateSlateWeb.Schema do
  use Absinthe.Schema

  alias PlateSlateWeb.Resolvers
  import_types __MODULE__.MenuTypes

  enum :sort_order do
    value :asc
    value :desc
  end

  scalar :date do
    parse fn input ->
      with %Absinthe.Blueprint.Input.String{value: value} <- input,
        {:ok, date} <- Date.from_iso8601(value) do
          {:ok, date}
      else
        _ -> :error
      end
    end

    serialize fn date ->
      Date.to_iso8601(date)
    end
  end


  query do
    import_fields :menu_queries

    @desc "The list of categories"
    field :categories, list_of(:category) do

      arg :matching, :string
      arg :order, type: :sort_order, default_value: :asc

      resolve &Resolvers.Menu.menu_categories/3
    end
  end


  object :category do
    field :id, :id
    field :name, :string
    field :description, :string
  end
end
