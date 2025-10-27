#
#
#

import argparse
import os
import signal
import socket
import sys
import time


DEFAULT_HOST = 'localhost'
DEFAULT_PORT = 6666

def _connect():
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect((DEFAULT_HOST, DEFAULT_PORT))

    except ConnectionRefusedError as e:
        print(f"{e} - likely no odbcpersist-daemon running", file=sys.stderr)
        quit()

    return sock

def build_dgram(cmd_stat, msg):
    b_msg = msg.encode("utf-8")
    m_len = len(b_msg)

    header = f"{cmd_stat}{m_len:06}\r\n\r\n".encode("utf-8")

    return header + b_msg

def recvall(sock):
    bufsize = 4096
    chunks = []
    total = 0

    # Read the first 11 bytes to determine message len. The
    # datagram is formatted [ F 0 0 0 0 0 0 \r \n \r \n ]
    rec = sock.recv(11)

    if rec[7:11] != b'\r\n\r\n':
        raise Exception("Malformed message")

    msg_flg = int(rec[0:1])
    msg_len = int(rec[1:7])

    while total < msg_len:
        rec = sock.recv(min(msg_len - total, bufsize))
        chunks.append(rec)
        total += len(rec)

    return (msg_flg, b''.join(chunks))

def get_pid():
    sock = _connect()
    sock.send(build_dgram(1, "CMD::pid"))

    return recvall(sock)

def get_ttl():
    sock = _connect()
    sock.send(build_dgram(1, "CMD::ttl"))

    return recvall(sock)

def kill():
    flg, pid = get_pid()

    if flg:
        os.kill(int(pid), signal.SIGTERM)
    else:
        raise Exception("Request for pid failed.")

def ttl():
    flg, ttl = get_ttl()

    if flg:
        print(ttl.decode("utf-8"))
    else:
        raise Exception("Request for ttl failed.")

def query():
    parser = argparse.ArgumentParser()
    parser.add_argument('stdin', nargs='?',
        type=argparse.FileType('r'),
        default=sys.stdin,
        help="Query input")

    args = parser.parse_args()

    send_query(args.stdin.read())

def send_query(query):
    sock = _connect()
    sock.send(build_dgram(1, query))

    flg, res = recvall(sock)

    if flg:
        outpipe = sys.stdout
    else:
        outpipe = sys.stderr

    outpipe.reconfigure(encoding="utf-8")
    outpipe.write(res.decode("utf-8"))

if __name__ == '__main__':
    query()
