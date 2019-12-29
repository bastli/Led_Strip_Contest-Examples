#!/usr/bin/env python

import sys
import socket
import numpy as np
import math
import time
from random import random

IP_ADDR = sys.argv[1]

def random_range(range_tuple):
    return (range_tuple[1] - range_tuple[0]) * random() + range_tuple[0]


def wrap(lower, upper, value):
    length = upper - lower
    while value > upper:
        value -= length
    while value < lower:
        value += length
    return value


class FrameBuffer(object):
    def __init__(self, size_x, size_y):
        self.x = size_x
        self.y = size_y
        self.fb = np.array([[0] * 3 * size_y] * size_x)
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    def clear(self):
        for y in range(self.y):
            for x in range(self.x):
                self.fb[x][y*3+0] = 0
                self.fb[x][y*3+1] = 0
                self.fb[x][y*3+2] = 0

    def send(self):
        for x in range(self.x):
            strip = self.fb[x]
            self.sock.sendto(bytes([x]) + bytes(strip.astype(np.uint8)), (IP_ADDR, 1337))


class Flare(object):
    ANGLE_RANGE = (3.14/10, 3.14/5)
    SPEED_RANGE = (1, 3)
    SIZE_RANGE = (0.02, 0.05)
    TRAIL_LENGTH = 40
    ASPECT_RATIO = 1/4

    def __init__(self):
        self.angle = random_range(self.ANGLE_RANGE)
        self.speed = random_range(self.SPEED_RANGE)
        self.size = random_range(self.SIZE_RANGE)
        self.color = (random(), random(), random())
        self.x = random()
        self.y = 1.0
        self.points = [[self.x, self.y]] * self.TRAIL_LENGTH

    def update(self, dt):
        self.points.insert(0, [self.points[0][0], self.points[0][1]])
        self.points.pop()
        self.points[0][0] += np.sin(self.angle) * self.speed * dt
        self.points[0][1] -= np.cos(self.angle) * self.speed * dt * self.ASPECT_RATIO

    def is_alive(self):
        # if lowest point is still on screen
        return self.points[self.TRAIL_LENGTH - 1][1] > 0.0

    def rasterize(self, framebuffer):
        for i, point in enumerate(self.points):
            intensity = (self.TRAIL_LENGTH - i) / self.TRAIL_LENGTH
            px = math.ceil(point[0]) - point[0]
            py = point[1]
            size = self.size * intensity

            px, py, sx, sy, ex, ey = self.determine_bb(framebuffer, px, py, size)
            for x in range(sx, ex):
                for y in range(sy, ey):
                    gaussian = math.exp(-1/2 * ((px - x)**2 + ((py - y)*self.ASPECT_RATIO)**2))
                    x = wrap(0, framebuffer.x-1, x)
                    if y < framebuffer.y and y >= 0:
                        framebuffer.fb[x][y*3 + 0] += int(self.color[0] * gaussian * 255 * intensity)
                        framebuffer.fb[x][y*3 + 1] += int(self.color[1] * gaussian * 255 * intensity)
                        framebuffer.fb[x][y*3 + 2] += int(self.color[2] * gaussian * 255 * intensity)

    def determine_bb(self, fb, px, py, size):
        # determine bounding box of affected pixels in framebuffer
        px_r = px * (fb.x-1)
        py_r = py * (fb.y-1)
        radx_r = size * (fb.x-1)
        rady_r = size * (fb.y-1) * self.ASPECT_RATIO
        return px_r, \
               py_r, \
               int(math.floor(px_r - radx_r)), \
               int(math.floor(py_r - rady_r)), \
               int(math.ceil(px_r + radx_r)), \
               int(math.ceil(py_r + rady_r))


def main():
    flares = list()
    fb = FrameBuffer(15, 112)
    MAX_FLARES = 3
    while True:
        for i, flare in enumerate(flares):
            if not flare.is_alive():
                flares.remove(flare)
        if random() > 0.2 and len(flares) < MAX_FLARES:
            flares.append(Flare())

        fb.clear()
        for flare in flares:
            flare.update(0.04)
            flare.rasterize(fb)
        fb.send()

        time.sleep(0.02)


main()
