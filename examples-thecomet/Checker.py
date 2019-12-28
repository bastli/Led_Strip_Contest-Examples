import socket
import time

IP_ADDR = "151.217.142.197"

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
def checker(flip=0):
    for i in range(15):
        if i % 2 == flip:
            sock.sendto(bytes([i]) + b"\x00\x40\x40\x00\x00\x00"*56, (IP_ADDR, 1337))
        else:
            sock.sendto(bytes([i]) + b"\x00\x00\x00\x40\x40\x00"*56, (IP_ADDR, 1337))

while True:
    checker(0)
    time.sleep(0.2)
    checker(1)
    time.sleep(0.2)
