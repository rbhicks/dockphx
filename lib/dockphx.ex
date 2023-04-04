defmodule Mix.Tasks.Dockphx do
  use Mix.Task

  @impl Mix.Task
  def run(args) do
    values = get_values(args)

    Mix.Task.run("phx.new", [values.app_name])
    generate_docker_files(values)
    update_config_exs(values, "dev")
    update_config_exs(values, "test")
    Mix.Shell.cmd("cd #{values.app_name}; docker-compose build", [], &IO.puts(&1))
  end

  def get_values(args) do
    default_base_name = File.cwd() |> elem(1) |> Path.split() |> List.last()
    default_base_path = "./"

    default_values = %{
      app_name: "#{default_base_name}",
      app_volume_source_path: "#{default_base_path}",
      app_volume_destination_path: "/#{default_base_name}",
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
      image_postgres: "postgres:15"
    }

    parsed_args =
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
          db_volume_destination_path: :string
        ]
      )

    {_, positional_args, parsed_options} = parsed_args

    # Convert the positional_args list into a map
    positional_args_map = %{
      app_name: Enum.at(positional_args, 0),
      app_host_port:
        Enum.at(positional_args, 1) && String.to_integer(Enum.at(positional_args, 1)),
      db_host_port: Enum.at(positional_args, 2) && String.to_integer(Enum.at(positional_args, 2)),
      db_password: Enum.at(positional_args, 3)
    }

    # Convert the parsed_options list into a map
    parsed_options_map =
      parsed_options
      |> Enum.map(fn {k, v} -> {String.to_atom(String.trim_leading(k, "-")), v} end)
      |> Enum.reject(fn {_k, v} -> v == nil end)
      |> Enum.into(%{})

    # Merge the maps with precedence given to the parsed values
    values =
      Map.merge(default_values, positional_args_map)
      |> Map.merge(parsed_options_map)
      |> Enum.reject(fn {_k, v} -> v == nil end)
      |> Enum.into(%{})

    # if we have a non-switch arg, use it to override app_name
    values =
      with {:ok, non_switch_name_arg} <-
             parsed_args
             |> elem(1)
             |> List.first()
             |> verify_arg() do
        values
        |> Map.replace!(:app_name, non_switch_name_arg)
        |> Map.replace!(:app_volume_source_path, "./#{non_switch_name_arg}")
        |> Map.replace!(:app_volume_destination_path, "/#{non_switch_name_arg}")
      else
        {:error, nil} -> values
      end

    # we could end up with a scenario where we have a non-default
    # app_name, but it doesn't get populated to app_volume_source_path,
    # and app_volume_destination_path. check and fix it if needed
    if !String.equivalent?(values.app_name, default_base_name) do
      values
      |> Map.replace!(:app_volume_source_path, "./")
      |> Map.replace!(:app_volume_destination_path, "/#{values.app_name}")
    else
      values
    end
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
     && mix archive.install --force hex phx_new 1.6.0 \
     && apt-get update \
     && apt-get install -y apt-utils \
     && apt-get install -y build-essential \
     && apt-get install -y inotify-tools
    """
  end
end
