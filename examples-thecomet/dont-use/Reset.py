import socket

IP_ADDR = "151.217.142.197"

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
for i in range(15):
    sock.sendto(bytes([i]) + b"\x00\x20\x20"*112, (IP_ADDR, 1337))
