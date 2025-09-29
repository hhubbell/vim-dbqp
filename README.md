# Vim Database Query Plugin

Interactively send queries to a database using a persistent ODBC connection.


## Installing

The database connection is managed through a small Python daemon. Queries are sent to to this daemon through the controller. Install `odbcpersist` first.

```bash
pip install .
```

Copy `dbqp.vim` to `~/.vim/autoload`.

```bash
cp autoload/dbqp.vim ~/.vim/autoload/
```

## Connecting

Initialize a database connection by calling `Connect`. Currently, snowflake, duckdb, and sqlite connections are supported. These connections require the appropriate driver library to be installed. Use the database type as the protocol indicator as the parameter passed to connect.

```
:call dbqp#Connect('duckdb://path_to_db.db')
```

## Usage

Calling the `SendQuery()` function will try to find the current query based on the cursor location. This behavior is very basic.

```
:call SendQuery()
```

