defmodule Mix.Tasks.Dockphx do
  use Mix.Task

  @impl Mix.Task
  def run(args) do
    values = get_values(args)
    Mix.Task.run("phx.new", [values.app_name] ++ values.phx_new_options)
    generate_docker_files(values)
    update_config_exs(values, "dev")
    update_config_exs(values, "test")
    Mix.Shell.cmd("cd #{values.app_name}; docker-compose build", [], &IO.puts(&1))
  end
  
  def get_values(args) do    
    default_values = %{
      app_host_port: 4000,
      app_container_port: 4000,
      db_name: "db",
      db_host_port: 5432,
      db_container_port: 5432,
      db_user: "postgres",
      db_password: "postgres",
      db_volume_source_path: "./data/db",
      db_volume_destination_path: "/var/lib/postgresql/data",
      image_elixir: "elixir:latest",
      image_postgres: "postgres:15",
      phoenix_version: "1.7.2"
    }

    {switch_options_kw_list, postitional_options, unexpected_options} =
      OptionParser.parse(args,
        strict: [
          app_name: :string,
          app_volume_source_path: :string,
          app_volume_destination_path: :string,
          app_host_port: :integer,
          app_container_port: :integer,
          db_name: :string,
          db_host_port: :integer,
          db_container_port: :integer,
          db_password: :string,
          db_user: :string,
          db_volume_source_path: :string,
          db_volume_destination_path: :string,
          image_elixir: :string,
          image_postgres: :string,
          phoenix_version: :string
        ]
      )

    switch_options = switch_options_kw_list |> Enum.into(%{})
    phoenix_new_options = unexpected_options |> Enum.map(fn (tuple) -> elem(tuple, 0) end)
    app_name = postitional_options |> hd
    default_base_name = app_name
    default_base_path = "./"

    # Convert the parsed_options list into a map
    options =
      switch_options
      |> Map.put(:app_volume_source_path, "#{default_base_path}")
      |> Map.put(:app_volume_destination_path, "/#{default_base_name}")
      |> Map.put(:app_name, app_name)
      |> Map.put(:phx_new_options, phoenix_new_options)
    
    # Merge the maps with precedence given to the parsed values
    Map.merge(default_values, options)
  end

  def generate_docker_files(values) do
    File.mkdir_p("#{values.app_name}/#{values.db_volume_source_path}")

    File.write(
      "./#{values.app_name}/docker-compose.yml",
      generate_docker_compose_yml(values)
    )

    File.write(
      "./#{values.app_name}/Dockerfile",
      generate_dockerfile(values)
    )
  end

  def update_config_exs(values, config_name) do
    dev_exs_path = "#{values.app_name}/config/#{config_name}.exs"
    {:ok, file} = File.open(dev_exs_path, [:utf8])

    IO.read(file, :all)
    |> (&Regex.replace(~r/password: "postgres",/, &1, "password: \"postgres\",")).()
    |> (&Regex.replace(~r/hostname: "localhost",/, &1, "hostname: \"#{values.db_name}\",")).()
    |> (&File.write(dev_exs_path, &1)).()
  end

  def verify_arg(nil), do: {:error, nil}
  def verify_arg(arg), do: {:ok, arg}

  def generate_docker_compose_yml(args) do
    """
    version: '3'
    services:
      #{args.app_name}:
        image: #{args.app_name}
        build: .
        ports:
          - "#{args.app_host_port}:#{args.app_container_port}"
        volumes:
          - #{args.app_volume_source_path}:#{args.app_volume_destination_path}
        depends_on:
          - db
        command: /bin/bash -c  'mix ecto.create && mix ecto.migrate && mix phx.server'
      #{args.db_name}:
        image: #{args.image_postgres}
        ports:
          - "#{args.db_host_port}:#{args.db_container_port}"
        environment:
          POSTGRES_USER: #{args.db_user}
          POSTGRES_PASSWORD: #{args.db_password}
        volumes:
          - #{args.db_volume_source_path}:#{args.db_volume_destination_path}
    """
  end

  def generate_dockerfile(args) do
    """
    FROM #{args.image_elixir}

    RUN apt-get update && apt-get install --yes postgresql-client

    ENV APP_HOME /#{args.app_name}
    RUN mkdir -p $APP_HOME
    WORKDIR $APP_HOME

    RUN mix local.hex --force \
     && mix archive.install --force hex phx_new #{args.phoenix_version} \
     && apt-get update \
     && apt-get install -y apt-utils \
     && apt-get install -y build-essential \
     && apt-get install -y inotify-tools
    """
  end
end
