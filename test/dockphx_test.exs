defmodule Mix.Test.DockphxTest do
  use ExUnit.Case, async: true

  test "run Dockphx task and check generated files content" do
    options = [
      "--app_name", "test_app",
      "--app_host_port", "4001",
      "--db_host_port", "5433",
      "--db_password", "postgres_password"
    ]

    on_exit(fn ->
      File.rm_rf("test_app")
    end)

    Mix.Tasks.Dockphx.run(options)
    assert File.exists?("test_app/docker-compose.yml")
    assert File.exists?("test_app/Dockerfile")

    docker_compose_content = File.read!("test_app/docker-compose.yml")
    expected_docker_compose = """
    version: '3'
    services:
      test_app:
        image: test_app
        build: .
        ports:
          - "4001:4000"
        volumes:
          - ./:/test_app
        depends_on:
          - db
        command: /bin/bash -c  'mix ecto.create && mix ecto.migrate && mix phx.server'
      db:
        image: postgres:15
        ports:
          - "5433:5432"
        environment:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres_password
        volumes:
          - ./data/db:/var/lib/postgresql/data
    """

    dockerfile_content = File.read!("test_app/Dockerfile")
    expected_dockerfile = """
    FROM elixir:otp-25

    RUN apt-get update && apt-get install --yes postgresql-client

    ENV APP_HOME /test_app
    RUN mkdir -p $APP_HOME
    WORKDIR $APP_HOME

    RUN mix local.hex --force \
     && mix archive.install --force hex phx_new 1.6.0 \
     && apt-get update \
     && apt-get install -y apt-utils \
     && apt-get install -y build-essential \
     && apt-get install -y inotify-tools
    """

    assert docker_compose_content == expected_docker_compose
    assert dockerfile_content == expected_dockerfile
  end
end
