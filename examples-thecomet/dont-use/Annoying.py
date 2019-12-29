import socket
import time

IP_ADDR = "151.217.142.197"

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

while True:
    for i in range(15):
        sock.sendto(bytes([i]) + b"\xFF\xFF\xFF"*112, (IP_ADDR, 1337))
    time.sleep(0.07)
    for i in range(15):
        sock.sendto(bytes([i]) + b"\x00\x00\x00"*112, (IP_ADDR, 1337))
    time.sleep(0.07)
