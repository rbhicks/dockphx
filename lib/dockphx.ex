defmodule Mix.Tasks.Dockphx do
  use Mix.Task
  
  @impl Mix.Task
  def run(args) do
    default_base_name = File.cwd |> elem(1) |> Path.split() |> List.last()
    default_base_path = "./"
    default_values = %{
      app_name: "#{default_base_name}",
      app_volume_source_path: "#{default_base_path}",
      app_volume_destination_path:  "/#{default_base_name}",
      app_host_port: 4000,
      app_container_port: 4000,
      db_name: "db",
      db_host_port: 5432,
      db_container_port: 5432,
      db_user: "postgres",
      db_password: "bloo_wackadoo",
      db_volume_source_path: "./data/db",
      db_volume_destination_path: "/var/lib/postgresql/data"
    }
    reversed_arg_map_merge = &(Map.merge(default_values, &1))
    parsed_args = OptionParser.parse(args,
      strict: [app_name: :string,
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
              ])
    values = parsed_args
    |> elem(0)
    |> Enum.into(%{})
    |> reversed_arg_map_merge.()
    
    # if we have a non-switch arg, use it to override app_name
    values = with {:ok, non_switch_name_arg} <- parsed_args
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
    values = if !String.equivalent?(values.app_name, default_base_name) do
      values
      |> Map.replace!(:app_volume_source_path, "./#{values.app_name}")
      |> Map.replace!(:app_volume_destination_path, "/#{values.app_name}")
    else
      values
    end
    
    Mix.Task.run "phx.new", [values.app_name]
    File.mkdir_p("#{values.app_name}/#{values.db_volume_source_path}")
    File.write("./#{values.app_name}/docker-compose.yml",
               generate_docker_compose_yml(values))
    File.write("./#{values.app_name}/Dockerfile",
               generate_dockerfile(values))        
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
        command: /bin/bash -c  'mix ecto.create; mix ecto.migrate; mix phx.server'
      #{args.db_name}:
        image: postgres:11
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
    FROM elixir:1.9

    RUN apt-get update && apt-get install --yes postgresql-client

    ENV APP_HOME /#{args.app_name}
    RUN mkdir -p $APP_HOME
    WORKDIR $APP_HOME

    RUN mix local.hex --force \
     && mix archive.install --force hex phx_new 1.4.8 \
     && apt-get update \
     && curl -sL https://deb.nodesource.com/setup_10.x | bash \
     && apt-get install -y apt-utils \
     && apt-get install -y nodejs \
     && apt-get install -y build-essential \
     && apt-get install -y inotify-tools
    """
  end
end
