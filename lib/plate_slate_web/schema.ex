defmodule PlateSlateWeb.Schema do
  use Absinthe.Schema

  alias PlateSlateWeb.Resolvers
  alias PlateSlateWeb.Schema.Middleware

  import_types __MODULE__.MenuTypes
  import_types __MODULE__.OrderingTypes
  import_types __MODULE__.AccountsTypes

  def middleware(middleware, field, object) do
    middleware
    |> apply(:errors, field, object)
    |> apply(:get_string, field, object)
    |> apply(:debug, field, object)
  end

  defp apply(middleware, :errors, _field, %{identifier: :mutation}) do
    middleware ++ [Middleware.ChangesetErrors]
  end

  defp apply([], :get_string, field, %{identifier: :allergy_info}) do
    [{Absinthe.Middleware.MapGet, to_string(field.identifier)}]
  end

  defp apply(middleware, :debug, _field, _object) do
    if System.get_env("DEBUG") do
      [{Middleware.Debug, :start}] ++ middleware
    else
      middleware
    end
  end

  defp apply(middleware, _, _, _) do
    middleware
  end

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

  scalar :decimal do
    parse fn
      %{value: value}, _ ->
        Decimal.parse(value)
      _, _ ->
        :error
    end

    serialize &to_string/1
  end


  query do
    field :me, :user do
      middleware Middleware.Authorize, :any
      resolve &Resolvers.Accounts.me/3
    end

    import_fields :menu_queries

    @desc "The list of categories"
    field :categories, list_of(:category) do

      arg :matching, :string
      arg :order, type: :sort_order, default_value: :asc

      resolve &Resolvers.Menu.menu_categories/3
    end

    field :search, list_of(:search_result) do
      arg :matching, non_null(:string)
      resolve &Resolvers.Menu.search/3
    end
  end

  input_object :menu_item_input do
    field :name, non_null(:string)
    field :description, :string
    field :price, non_null(:decimal)
    field :category_id, non_null(:id)
  end

  mutation do
    field :create_menu_item, :menu_item_result do
      arg :input, non_null(:menu_item_input)
      middleware Middleware.Authorize, "employee"
      resolve &Resolvers.Menu.create_item/3
    end

    field :update_menu_item, :menu_item_result do
      arg :input, non_null(:menu_item_input)
      arg :id, non_null(:id)
      resolve &Resolvers.Menu.update_item/3
    end

    field :place_order, :order_result do
      arg :input, non_null(:place_order_input)
      middleware Middleware.Authorize, :any
      resolve &Resolvers.Ordering.place_order/3
    end

    field :ready_order, :order_result do
      arg :id, non_null(:id)
      resolve &Resolvers.Ordering.ready_order/3
    end

    field :complete_order, :order_result do
      arg :id, non_null(:id)
      resolve &Resolvers.Ordering.complete_order/3
    end

    field :login, :session do
      arg :email, non_null(:string)
      arg :password, non_null(:string)
      arg :role, non_null(:role)
      resolve &Resolvers.Accounts.login/3
      middleware fn res, _ ->
        with %{value: %{user: user}} <- res do
          %{res | context: Map.put(res.context, :current_user, user)}
        end
      end
    end
  end

  subscription do
    field :new_order, :order do
      config fn _args, %{context: context} ->
        case context[:current_user] do
          %{role: "customer", id: id} ->
            {:ok, topic: id}
          %{role: "employee"} ->
            {:ok, topic: "*"}
          _ ->
            {:error, "authorized"}
        end
      end

      resolve fn root, _, _ ->
        # IO.inspect(root)
        {:ok, root}
      end
    end

    field :update_order, :order do
      arg :id, non_null(:id)

      config fn args, _info ->
        {:ok, topic: args.id}
      end

      trigger [:ready_order, :complete_order], topic: fn
        %{order: order} -> [order.id]
        _ -> []
      end

      resolve fn %{order: order}, _, _ ->
        {:ok, order}
      end
    end
  end
end
