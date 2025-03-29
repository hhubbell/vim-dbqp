#
#
#

import os


def duckdb_connection(param_str):
    import duckdb

    # FIXME?
    if param_str:
        param_str = os.path.expanduser(param_str)

    return duckdb.connect(param_str)

def snowflake_connection(param_str):
    import snowflake.connector

    return snowflake.connector.connect()

def sqlite_connection(param_str):
    import sqlite3

    return sqlite3.connect(os.path.expanduser(param_str))

