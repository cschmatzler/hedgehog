defmodule Hedgehog.User do
  @moduledoc """
  Behavior to automatically process user data for use in analytics events.

  ## Default implementation

  The behavior can quickly be implemented by adding `use Hedgehog.User` to your user module that contains the Ecto schema.  
  This works for user implementations that have an `id` field containing their unique identifier, and Plug/LiveView implementations that
  assign the current user under the `:current_user` key - this is the default for `mix phx.gen.auth`.  

  In the default implementation, since `mix phx.gen.auth` does not provide any specification for groups, the `groups/2` function always
  returns an empty map.
  """

  alias Phoenix.LiveView.Socket

  @doc """
  Returns the unique identifier of the user.
  """
  @callback id(user :: any()) :: id :: binary()
  @doc """
  Returns a map of groups the user is a member of - the key being the group name, and the value being the group identifier.  
  Additionally receives the current request's `Plug.Conn` or `Phoenix.LiveView.Socket` for context.
  """
  # NOTE: Not sure the `conn_or_socket` argument makes sense, since it limits the function to only being used in a connectin context.
  @callback groups(user :: any(), conn_or_socket :: %Plug.Conn{} | %Socket{}) :: groups :: map()
  @doc """
  Returns the user given the current request's `Plug.Conn` or `Phoenix.LiveView.Socket`.
  """
  @callback from_view(conn_or_socket :: %Plug.Conn{} | %Socket{}) :: user :: any()

  defmacro __using__(_) do
    quote do
      @behaviour Hedgehog.User

      @impl Hedgehog.User
      def id(user) when is_struct(user) do
        Map.get(user, :id)
      end

      @impl Hedgehog.User
      def groups(_user, _conn_or_socket) do
        %{}
      end

      @impl Hedgehog.User
      def from_view(%Socket{} = socket) do
        socket.assigns.current_user
      end

      def from_view(%Plug.Conn{} = conn) do
        conn.assigns.current_user
      end

      defoverridable Hedgehog.User
    end
  end
end
