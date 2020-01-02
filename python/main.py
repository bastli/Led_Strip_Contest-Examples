#    _____         .__        
#   /     \ _____  |__| ____  
#  /  \ /  \\__  \ |  |/    \ 
# /    Y    \/ __ \|  |   |  \
# \____|__  (____  /__|___|  /
#         \/     \/        \/ 

"""This file handels the hole process including the GUI, processing and uploading"""

__author__ = 'Manumerus'
__maintainer__ = 'Manumerus'
__created__ = '36c3, December 2019'
__license__ = 'GPL'

import manipulators
from net_interface import NetInterface

IP = '151.217.142.197'
PORT = 1337    

def main():

    # strip_selector = 3
    # payload= [40]*112*3
    # data_list = [strip_selector]+payload
    # data_binary = bytes(data_list)
    
    barco = NetInterface(IP, PORT)
    barco.clear_strips()

    current_matrix = manipulators.strip_command_matrix(30,30,0)
    print(current_matrix)

    barco.command_matrix_to_command_list(current_matrix)
   
if __name__ == "__main__":
    main()