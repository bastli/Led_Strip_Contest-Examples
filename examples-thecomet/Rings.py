#!/usr/bin/env python

import sys
import socket
import time
import math
import numpy as np
from random import random

IP_ADDR = sys.argv[1]
IP_PORT = 1337
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

rgb = np.array([[0] * 3 * 112] * 15)
rings = list()


class Ring:
    def __init__(self, freq_x, freq_y, order, color):
        self.tx = 0
        self.ty = 0
        self.fx = freq_x
        self.fy = freq_y
        self.y_pos = 0
        self.v = 0
        self.color = color
        self.order = order


def clear_framebuffer():
        for i, v in enumerate(rgb):
            rgb[i] = 0


def update_rings(dt):
    for ring in rings:
        ring.tx += dt
        ring.ty += dt
        if ring.ty > 1/ring.fy:
            ring.ty = 0
        if ring.tx > 1/ring.fx:
            ring.tx = 0
        ring.y_pos = math.sin(2 * math.pi * ring.fy * ring.ty)
        ring.v = math.cos(2 * math.pi * ring.fy * ring.ty)


def rasterize_rings():
    for ring in rings:
        for x in range(15):
            y_actual = ring.y_pos * 47 + 53 + math.cos(2 * math.pi * ring.order * x/15 + 2*math.pi*ring.tx*ring.fx) * 4
            y_rasterized = int(y_actual + 0.5)
            v = abs(ring.v) + 1
            width = int(math.sqrt(math.log(10)*v))
            for y in range(y_rasterized-width, y_rasterized+width+1):
                if y < 0 or y >= 112:
                    continue
                gauss = math.exp(-(y_actual - y) ** 2 / v)
                rgb[x][y*3+0] = min(255, rgb[x][y*3+0] + int(ring.color[0] * gauss))
                rgb[x][y*3+1] = min(255, rgb[x][y*3+1] + int(ring.color[1] * gauss))
                rgb[x][y*3+2] = min(255, rgb[x][y*3+2] + int(ring.color[2] * gauss))


def send_framebuffer():
    for i in range(15):
        data = bytes([i]) + bytes(rgb[i].astype(np.uint8))
        sock.sendto(data, (IP_ADDR, IP_PORT))


def main():
    rings.append(Ring(0.3, 0.08, 0, (100, 50, 100)))
    rings.append(Ring(0.5, 0.16, 1, (0, 80, 80)))
    rings.append(Ring(0.6, 0.24, 2, (0, 80, 0)))
    rings.append(Ring(0.4, 0.32, 3, (80, 20, 0)))

    dt = 0.01
    while True:
        clear_framebuffer()
        update_rings(dt)
        rasterize_rings()
        send_framebuffer()
        time.sleep(dt)

main()
