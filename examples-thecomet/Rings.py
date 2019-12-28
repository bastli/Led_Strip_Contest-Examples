import socket
import time
import math
from random import random

IP_ADDR = "151.217.142.197"
IP_PORT = 1337
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

rgb = [0] * 3 * 112
rings = list()


class Ring:
    def __init__(self, freq, color):
        self.t = 0
        self.f = freq
        self.y_pos = 0
        self.v = 0
        self.color = color


def clear_framebuffer():
        for i, v in enumerate(rgb):
            rgb[i] = 0


def update_rings(dt):
    for ring in rings:
        ring.t += dt
        if ring.t > 1/ring.f:
            ring.t = 0
        ring.y_pos = math.sin(2 * math.pi * ring.f * ring.t)
        ring.v = math.cos(2 * math.pi * ring.f * ring.t)


def rasterize_rings():
    for ring in rings:
        y_actual = ring.y_pos * 55 + 56
        y_rasterized = int(y_actual + 0.5)
        v = abs(ring.v) + 1
        width = int(math.sqrt(math.log(10)*v))
        for y in range(y_rasterized-width, y_rasterized+width+1):
            if y < 0 or y >= 112:
                continue
            gauss = math.exp(-(y_actual - y) ** 2 / v)
            rgb[y*3+0] = min(255, rgb[y*3+0] + int(ring.color[0] * gauss))
            rgb[y*3+1] = min(255, rgb[y*3+1] + int(ring.color[1] * gauss))
            rgb[y*3+2] = min(255, rgb[y*3+2] + int(ring.color[2] * gauss))


def send_framebuffer():
    for i in range(15):
        data = bytes([i]) + bytes(rgb)
        sock.sendto(data, (IP_ADDR, IP_PORT))


def main():
    rings.append(Ring(0.08, (100, 50, 100)))
    rings.append(Ring(0.16, (0, 80, 80)))
    rings.append(Ring(0.24, (0, 80, 0)))
    rings.append(Ring(0.32, (80, 20, 0)))

    dt = 0.01
    while True:
        clear_framebuffer()
        update_rings(dt)
        rasterize_rings()
        send_framebuffer()
        time.sleep(dt)

main()
