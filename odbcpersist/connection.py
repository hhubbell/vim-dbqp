

def duckdb_connection(param_str):
    import duckdb

    # FIXME
    return duckdb.connect(param_str)

def snowflake_connection(param_str):
    import snowflake.connector

    # FIXME
    return snowflake.connector.connect(param_str)

def sqlite_connection(param_str):
    import sqlite3

    return sqlite3.connect(param_str)


