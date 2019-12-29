import socket
import sys

IP_ADDR = "151.217.142.197"

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
for i in range(15):
    sock.sendto(bytes([i]) + b"\x00\x00\x00"*112, (IP_ADDR, 1337))
sock.sendto(bytes([int(sys.argv[1])]) + b"\x00\x50\x50"*112, (IP_ADDR, 1337))

