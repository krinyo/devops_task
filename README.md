# PostgreSQL Backup Script

A simple Bash script to perform backups of PostgreSQL databases.

## Usage

The script is configured via command-line flags. The following is the output of the `--help` command:

```
Usage: ./backup.sh [-d BACKUP_DIR] [-u DB_USER] [-h DB_HOST] [-p DB_PORT] [-l LOG_FILE]

A script to back up PostgreSQL databases.

Options:
  -d    Path to the backup directory. Default: backups
  -u    Database user. Default: postgres
  -h    Database host. Default: localhost
  -p    Database port. Default: 5432
  -l    Path to the log file. Default: db_backup.log

Password should be configured in the .pgpass file in the script's directory.
The file must have permissions set to 600 (e.g., chmod 600 .pgpass).

Format:  hostname:port:database:username:password
Example: localhost:5432:*:postgres:mysecretpassword
```

## Testing with Docker

This method uses the provided `Dockerfile` and `init.sql` to create a test database with pre-filled data, and then runs the local `backup.sh` script against it.

1.  **Build the test database image:** This command uses the `Dockerfile` in the root directory.
    ```sh
    docker build -t test-db-server .
    ```

2.  **Run the test database container.** It will automatically create the test databases from `init.sql` on first run.
    ```sh
    docker run --name pg-test -e POSTGRES_PASSWORD=mysecretpassword -p 15432:5432 -d test-db-server
    ```

3.  **Create a `.pgpass` file** for the connection in the project root. Add the following line to the file:
    ```
    localhost:15432:*:postgres:mysecretpassword
    ```
    Then, set the correct permissions:
    ```sh
    chmod 600 .pgpass
    ```

4.  **Wait a few seconds** for the database to initialize, then run the backup script, pointing it to the test container:
    ```sh
    ./backup.sh -h localhost -p 15432
    ```

5.  **Verify the result.** A new backup archive should appear in the `backups/` directory, containing dumps of the databases created by `init.sql`.

6.  **Clean up** the test container when done:
    ```sh
    docker stop pg-test && docker rm pg-test
    ```