# Dockphx Mix Task

Dockphx is a custom Mix task for Elixir that automatically generates Docker and docker-compose files for your Phoenix applications. This task simplifies the process of setting up a new Phoenix project with Docker by creating the necessary files and configurations for you. It also updates the `config/dev.exs` and `config/test.exs` files with the proper hostname and password for the database connection.

## Installation

1. Clone the repository:

git clone https://github.com/your_username/dockphx.git

2. Navigate to the `dockphx` directory:

cd dockphx

3. Build and install the Mix task archive:

`mix do archive.build, archive.install`

4. You should now have the `Dockphx` Mix task installed and available for use in your Elixir projects.

## Usage

To use the `Dockphx` Mix task, run the following command:

`mix dockphx [app_name] [options]`

### Arguments

- `app_name`: The name of your Phoenix application. This can be provided as the first argument without using the `--app_name` switch.

### Options

The following options can be provided to the `mix dockphx` command:

- `--app_volume_source_path`: The source path for the application volume in the Docker container.
- `--app_volume_destination_path`: The destination path for the application volume in the Docker container.
- `--app_host_port`: The host port for your Phoenix application.
- `--app_container_port`: The container port for your Phoenix application.
- `--db_name`: The name of the database container.
- `--db_host_port`: The host port for the PostgreSQL database.
- `--db_container_port`: The container port for the PostgreSQL database.
- `--db_user`: The PostgreSQL user.
- `--db_password`: The PostgreSQL password.
- `--db_volume_source_path`: The source path for the database volume in the Docker container.
- `--db_volume_destination_path`: The destination path for the database volume in the Docker container.

If you don't provide any options, the Mix task will use the default values specified in the code.

### Example

`mix dockphx phoenix_app --app_host_port 4001 --db_host_port 5433 --db_password postgres_password`

This command will create a new Phoenix application called `phoenix_app` with the specified options, generate the Docker and docker-compose files, and build the Docker container.


## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
