#
#
#

import argparse
import datetime
import math
import os
import select
import socket
import time
from . import connection
from .controller import recvall, build_dgram, DEFAULT_HOST, DEFAULT_PORT


DEFAULT_TTL = 900

def _connect(dsn):
    """
    Expects format database://key=value;key=value
    """
    dbm, params = dsn.split("://")

    return getattr(connection, dbm + "_connection")(params)

def _format_result(header, rows):
    """
    """
    # this is just a mess but I want something basic to start
    final = []
    final.append(header)

    widths = [1 for _ in header]

    for row in rows:
        fmt = []
        for i, val in enumerate(row):
            if isinstance(val, bytes):
                val = val.decode('utf-8')
            elif isinstance(val, datetime.datetime):
                val = str(val)
            else:
                val = str(val)

            fmt.append(val)

            widths[i] = max(widths[i], len(val))

        final.append(fmt)
    
    return '\n'.join('\u2502'.join(f"{x:<{i + 1}}" for i, x in zip(widths, row)) for row in final)

def daemon():
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--conn', nargs='?')
    parser.add_argument('-t', '--ttl', nargs='?', type=int)
    parser.add_argument('-q', '--quiet', action='store_true')

    args = parser.parse_args()

    if args.ttl is None:
        ttl = DEFAULT_TTL
    else:
        ttl = args.ttl

    try:
        start_daemon(args.conn, ttl, args.quiet)
    except OSError as e:
        # Print just the error not the full traceback when running as a cli
        print(e)
        quit()

def start_daemon(conn_str, ttl, quiet=False):
    # NOTE: Most of the time, Python docs recommend disposing of cursors
    # frequently and getting new ones for all queries. However, the goal of
    # this tool is to retain all connection data for the time persisted, and
    # so we want to retain the cursor as well. That way, temp tables and other
    # session objects are retained.
    conn = _connect(conn_str)
    cur = conn.cursor()

    if not quiet:
        print("Connected.", flush=True)

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.bind((DEFAULT_HOST, DEFAULT_PORT))
    sock.listen(1)

    now = time.time()
    kill = now + ttl

    while now <= kill:
        r, w, x = select.select([sock], [], [], 1)

        if r:
            co, adr = sock.accept()
            _, payload = recvall(co)

            if payload == b"CMD::pid":
                co.send(build_dgram(1, str(os.getpid())))

            if payload == b"CMD::ttl":
                rem = kill - now
                co.send(build_dgram(1, f"alive for {math.floor(rem / 60)}:{math.floor(rem % 60)} minutes"))
            else:
                try:
                    cur.execute(payload.decode("utf-8"))
                    data = cur.fetchall()
                    head = [x[0] for x in cur.description]
                    res = _format_result(head, data)
                    flg = 1

                except Exception as e:
                    res = e
                    flg = 0

                co.send(build_dgram(flg, str(res)))

            # Any time we receive a command, keep alive for another ttl window
            kill = now + ttl

        now = time.time()

if __name__ == '__main__':
    #start_daemon(ConnMock())
    daemon()
