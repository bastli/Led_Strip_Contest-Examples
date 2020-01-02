import math
import socket


class Barco:
    LEDS = 112
    STRIPS = 15

    def __init__(self, ip, port):
        self.ip = ip
        self.port = port

        self.socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    def send(self, msg):
        #print('sending message: {}'.format(msg))
        self.socket.sendto(bytes(msg), (self.ip, self.port))

    def apply_to_strip(self, strip, effect, *args, **kwargs):
        self.send([strip] + effect(*args, **kwargs))

    def apply_to_all_strips(self, effect, *args, **kwargs):
        msg = effect(*args, **kwargs)
        for i in range(self.STRIPS):
            self.send([i] + msg)

    def clear_all_strips(self):
        self.apply_to_all_strips(self.clear)

    # effects

    def clear(self):
        return self.LEDS * 3 * [0]

    def unicolor(self, color):
        return self.LEDS * color

    def gradient(self, color, reverse=False):
        msg = []
        for i in range(self.LEDS):
            intensity = float(i) / self.LEDS
            if reverse:
                intensity = 1.0 - intensity
            msg.extend(
                [int(x*intensity) for x in color]
            )
        return self._apply_offset(msg)

    def sin(self, color):
        """ Apply sin intensity to color, such that it has the peak in the center. """
        msg = []
        for i in range(self.LEDS):
            intensity = math.sin(float(i) / self.LEDS * math.pi)
            msg.extend(
                [int(x*intensity) for x in color]
            )
        return self._apply_offset(msg)

    # helpers

    @staticmethod
    def _dim_color(color, intensity):
        return [int(x*intensity) for x in color]

    @staticmethod
    def _to_int(data):
        return [int(x) for x in data]

    @staticmethod
    def _apply_offset(data, offset=10):
        """ Add offset to each entry of data if it's not zero. """
        return [
            x + offset if x != 0 else x for x in data
        ]

