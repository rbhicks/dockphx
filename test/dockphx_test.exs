defmodule Mix.Test.DockphxTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Dockphx
  test "run Dockphx task and check generated files content" do
    options = [
      "china_lake",
      "--app-host-port",
      "4001",
      "--db-host-port",
      "5433",
      "--db-password",
      "postgres-password"
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
     && mix archive.install --force hex phx_new 1.7.2 \
     && apt-get update \
     && apt-get install -y apt-utils \
     && apt-get install -y build-essential \
     && apt-get install -y inotify-tools
    """

    assert docker_compose_content == expected_docker_compose
    assert dockerfile_content == expected_dockerfile
  end

  test "all default values except china_lake" do
    args = ["china_lake"]
    expected = %{
      app_name: "china_lake", 
      app_volume_source_path: "./china_lake", 
      app_volume_destination_path: "/china_lake", 
      app_host_port: 4000, 
      app_container_port: 4000, 
      db_name: "db", 
      db_host_port: 5432, 
      db_container_port: 5432, 
      db_user: "postgres", 
      db_password: "postgres", 
      db_volume_source_path: "./data/db", 
      db_volume_destination_path: "/var/lib/postgresql/data", 
      image_elixir: "elixir:otp-25", 
      image_postgres: "postgres:15", 
      phoenix_version: "1.7.2", 
      phx_new_options: []
    }
    
    assert Dockphx.get_values(args) == expected
  end

  test "mixture of default and overridden values" do
    args = ["china_lake", "--app-host-port", "5000", "--db-password", "new_password", "--binary_id"]
    expected = %{
      app_name: "china_lake", 
      app_volume_source_path: "./china_lake", 
      app_volume_destination_path: "/china_lake", 
      app_host_port: 5000, 
      app_container_port: 4000, 
      db_name: "db", 
      db_host_port: 5432, 
      db_container_port: 5432, 
      db_user: "postgres", 
      db_password: "new_password", 
      db_volume_source_path: "./data/db", 
      db_volume_destination_path: "/var/lib/postgresql/data", 
      image_elixir: "elixir:otp-25", 
      image_postgres: "postgres:15", 
      phoenix_version: "1.7.2",
      phx_new_options: ["--binary_id"]
    }
    
    assert Dockphx.get_values(args) == expected
  end

  test "all overridden values" do
    args = ["my_app", "--app-host-port", "5000", "--app-container-port", "5001", 
            "--db-name", "my_db", "--db-host-port", "6000", "--db-container-port", "6001", 
            "--db-user", "my_user", "--db-password", "new_password", 
            "--db-volume-source-path", "./my_data", "--db-volume-destination-path", "/my_postgres_data",
            "--image-elixir", "some_elixir_image", "--image-postgres", "some_postgres_image", 
            "--phoenix-version", "1.5.9"]
    
    expected = %{
      app_name: "my_app", 
      app_volume_source_path: "./my_app", 
      app_volume_destination_path: "/my_app", 
      app_host_port: 5000, 
      app_container_port: 5001, 
      db_name: "my_db", 
      db_host_port: 6000, 
      db_container_port: 6001, 
      db_user: "my_user", 
      db_password: "new_password", 
      db_volume_source_path: "./my_data", 
      db_volume_destination_path: "/my_postgres_data", 
      image_elixir: "some_elixir_image", 
      image_postgres: "some_postgres_image",
      phoenix_version: "1.5.9",
      phx_new_options: []
    }
    
    assert Dockphx.get_values(args) == expected
  end
end
