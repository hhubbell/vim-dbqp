#
#
#

import argparse
import os
import signal
import socket
import sys
import time


DEFAULT_HOST = ''
DEFAULT_PORT = 6666

def _connect():
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect((DEFAULT_HOST, DEFAULT_PORT))

    except ConnectionRefusedError as e:
        print(f"{e} - likely no odbcpersist-daemon running")
        quit()

    return sock

def build_dgram(msg):
    b_msg = msg.encode("utf-8")
    m_len = len(b_msg)

    header = f"{m_len:06}\r\n\r\n".encode("utf-8")

    return header + b_msg

def recvall(sock):
    bufsize = 4096
    chunks = []
    total = 0

    # Read the first 10 bytes to determine message len. The
    # datagram is formatted [ 0 0 0 0 0 0 \r \n \r \n ]
    rec = sock.recv(10)

    if rec[6:10] != b'\r\n\r\n':
        raise Exception("Malformed message")

    msg_len = int(rec[0:6])

    while total < msg_len:
        rec = sock.recv(min(msg_len - total, bufsize))
        chunks.append(rec)
        total += len(rec)

    return b''.join(chunks)

def get_pid():
    sock = _connect()
    sock.send(build_dgram("CMD::pid"))

    return recvall(sock)

def get_ttl():
    sock = _connect()
    sock.send(build_dgram("CMD::ttl"))

    return recvall(sock)

def kill():
    pid = int(get_pid())
    os.kill(pid, signal.SIGTERM)

def ttl():
    print(get_ttl().decode("utf-8"))

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
    sock.send(build_dgram(query))

    res = recvall(sock)

    print(res.decode('utf-8'))

if __name__ == '__main__':
    query()
