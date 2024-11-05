defmodule Hedgehog.ConfigTest do
  use ExUnit.Case, async: true

  alias Hedgehog.Config

  describe "start_link/1" do
    test "starts with valid options" do
      options = [
        endpoint: "https://eu.i.posthog.com",
        api_key: "phc_123",
        analytics: [user: :user_id]
      ]

      assert {:ok, pid} = Config.start_link(options)
      assert Process.alive?(pid)
    end

    test "fails with missing required options" do
      assert {:error, %NimbleOptions.ValidationError{message: message}} = Config.start_link([])
      assert message =~ "required :endpoint option not found"
    end

    test "fails with invalid endpoint type" do
      options = [
        endpoint: 123,
        api_key: "phc_123",
        analytics: [user: :user_id]
      ]

      assert {:error, %NimbleOptions.ValidationError{message: message}} = Config.start_link(options)
      assert message =~ "invalid value for :endpoint option: expected string, got: 123"
    end

    test "fails with invalid api_key type" do
      options = [
        endpoint: "https://eu.i.posthog.com",
        api_key: 123,
        analytics: [user: :user_id]
      ]

      assert {:error, %NimbleOptions.ValidationError{message: message}} = Config.start_link(options)
      assert message =~ "invalid value for :api_key option: expected string, got: 123"
    end
  end

  describe "get/2" do
    setup do
      options = [
        endpoint: "https://eu.i.posthog.com",
        api_key: "phc_123",
        analytics: [user: :user_id]
      ]

      start_supervised!({Config, options})
      :ok
    end

    test "gets value for single key" do
      assert Config.get(:endpoint) == "https://eu.i.posthog.com"
      assert Config.get(:api_key) == "phc_123"
    end

    test "gets nested value with key list" do
      assert Config.get([:analytics, :user]) == :user_id
      assert Config.get([:analytics, :enabled]) == true
    end

    test "returns default value for non-existent key" do
      assert Config.get(:non_existent, :default) == :default
      assert Config.get([:non, :existent], :default) == :default
    end

    test "returns default values for optional settings" do
      assert Config.get([:analytics, :pageview]) == true
      assert Config.get([:analytics, :batch_size]) == 500
      assert Config.get([:analytics, :batch_timeout]) == 10_000
    end
  end
end
