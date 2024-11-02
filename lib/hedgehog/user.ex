defmodule Hedgehog.User do
  @moduledoc false

  @callback id(any()) :: binary()
  @callback groups(any()) :: map()
  @callback from_view(%Phoenix.LiveView.Socket{} | %Plug.Conn{}) :: any()

  defmacro __using__(_) do
    quote do
      @behaviour Hedgehog.User

      @impl true
      def id(user) when is_struct(user) do
        Map.get(user, :id)
      end

      @impl true
      def groups(_user) do
        %{}
      end

      @impl true
      def from_view(%Phoenix.LiveView.Socket{} = socket) do
        socket.assigns.current_user
      end

      def from_view(%Plug.Conn{} = conn) do
        conn.assigns.current_user
      end

      defoverridable Hedgehog.User
    end
  end
end
