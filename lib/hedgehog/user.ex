defmodule Hedgehog.User do
  @moduledoc false

  alias Phoenix.LiveView.Socket

  @callback id(any()) :: binary()
  @callback groups(any(), %Plug.Conn{} | %Socket{}) :: map()
  @callback from_view(%Plug.Conn{} | %Socket{}) :: any()

  defmacro __using__(_) do
    quote do
      @behaviour Hedgehog.User

      @impl true
      def id(user) when is_struct(user) do
        Map.get(user, :id)
      end

      @impl true
      def groups(_user, _conn_or_socket) do
        %{}
      end

      @impl true
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
