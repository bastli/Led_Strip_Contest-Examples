import sys
import time

from barco import Barco


ORANGE = [255, 87, 51]


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('Usage: {} <IP> <port>'.format(sys.argv[0]))
        sys.exit(-1)

    b = Barco(sys.argv[1], sys.argv[2])
    b.clear_all_strips()

    time.sleep(1)
    b.apply_to_all_strips(b.unicolor, [11, 11, 11])
    b.apply_to_strip(1, b.gradient, [30, 0, 0], True)
    b.apply_to_strip(1, b.sin, [0, 15, 0])

    time.sleep(1)
    o = b._dim_color(ORANGE, 0.15)
    b.apply_to_all_strips(b.unicolor, o)

    time.sleep(1)
    b.clear_all_strips()
