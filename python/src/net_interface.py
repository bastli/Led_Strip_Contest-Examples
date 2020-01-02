#  _______          __    .___        __                 _____                     
#  \      \   _____/  |_  |   | _____/  |_  ____________/ ____\____    ____  ____  
#  /   |   \_/ __ \   __\ |   |/    \   __\/ __ \_  __ \   __\\__  \ _/ ___\/ __ \ 
# /    |    \  ___/|  |   |   |   |  \  | \  ___/|  | \/|  |   / __ \\  \__\  ___/ 
# \____|__  /\___  >__|   |___|___|  /__|  \___  >__|   |__|  (____  /\___  >___  >
#         \/     \/                \/          \/                  \/     \/    \/ 

"""This file handels the UDP connection to communicate with the barco strips"""

__author__ = 'Manumerus'
__maintainer__ = 'Manumerus'
__created__ = '36c3, December 2019'
__license__ = 'GPL'


import socket
import numpy as np
import time


class NetInterface():

    def __init__(self, ip, port, ):
        self.ip = ip
        self.port = port
        self.connection = socket.socket(socket.AF_INET, socket.SOCK_DGRAM) 

    def command_matrix_to_command_list(self, command_matrix):
        command_list = [command_matrix[0,0],command_matrix[0,1],command_matrix[0,1]]
        for i in range(1 , 112 , 1):
            command_list += [command_matrix[i,0],command_matrix[i,1],command_matrix[i,1]]
        return command_list

    def set_single_strip(self, strip_id, strip_command_list):
        payload = [strip_id]+strip_command_list
        self.connection.sendto(bytes(payload), (self.ip, self.port))

    def set_all_strips(self, strip_command_list):
        for strip_id in range(15):
            payload = [strip_id]+strip_command_list
            self.connection.sendto(bytes(payload), (self.ip, self.port))

    def clear_strips(self):
        payload= [0]*336
        for i in range(15):
            data_list = [i]+payload
            self.connection.sendto(bytes(data_list), (self.ip, self.port))

  


### for isolated testing purpose only ###
def main():

    IP = '151.217.142.197'
    PORT = 1337 

    strip_selector = 3
    payload= [40]*112*3
    data_list = [strip_selector]+payload
    
    barco = BarcoConnection(IP, PORT)
    barco.clear_strips()
    barco.set_all_strips(data_list)
   
if __name__ == "__main__":
    main()