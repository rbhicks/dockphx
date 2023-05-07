# Dockphx Mix Task

## Elixir Custom Mix Task automatic Docker Support for new Phoenix Apps

This Elixir code provides a custom Mix task that automates the process of creating a new Phoenix project and generating necessary Docker files. It handles command-line options to configure the application and Docker settings, making it easier to set up a development environment. The task generates a Docker Compose configuration and builds the application using Docker.

### Features

- Automatically generates a new Phoenix project with specified options
- Creates Dockerfiles and docker-compose.yml for the Elixir and PostgreSQL services
- Configures application settings, such as ports, database name, and volume paths
- Supports customizing the Elixir and PostgreSQL images used for the containers
- Allows specifying a specific Phoenix version for the project



Dockphx is a custom Mix task for Elixir that automatically generates Docker and docker-compose files for your Phoenix applications. This task simplifies the process of setting up a new Phoenix project with Docker by creating the necessary files and configurations for you. It also updates the `config/dev.exs` and `config/test.exs` files with the proper hostname and password for the database connection.

## Installation

1. Clone the repository:

git clone https://github.com/your_username/dockphx.git

2. Navigate to the `dockphx` directory:

cd dockphx

3. Build and install the Mix task archive:

`mix do archive.build, archive.install`

4. You should now have the `Dockphx` Mix task installed and available for use in your Elixir projects.

### Usage

To use this custom Mix task, run the following command with the desired options:

`mix dockphx APP_NAME [OPTIONS]`


#### Options

- `--app_name`: The name of the application to be created
- `--app_volume_source_path`: The source path for the application volume
- `--app_volume_destination_path`: The destination path for the application volume
- `--app_host_port`: The host port for the application
- `--app_container_port`: The container port for the application
- `--db_name`: The name of the PostgreSQL database
- `--db_host_port`: The host port for the PostgreSQL service
- `--db_container_port`: The container port for the PostgreSQL service
- `--db_password`: The password for the PostgreSQL user
- `--db_user`: The username for the PostgreSQL user
- `--db_volume_source_path`: The source path for the PostgreSQL volume
- `--db_volume_destination_path`: The destination path for the PostgreSQL volume
- `--image_elixir`: The Elixir Docker image to use
- `--image_postgres`: The PostgreSQL Docker image to use
- `--phoenix_version`: The Phoenix version to use for the project

### Example

To create a new Phoenix project named "China Lake" with custom settings, run the following command:

`mix dockphx china_lake --app_host_port 4001 --app_container_port 4001 --db_name my_db --db_password my_password --phoenix_version 1.7.2`

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
