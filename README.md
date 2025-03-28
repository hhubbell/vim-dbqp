# Vim Database Query Persist

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

## Usage

Calling the `SendQuery()` function will try to find the current query based on the cursor location. This behavior is very basic.

```
:call SendQuery()
```

