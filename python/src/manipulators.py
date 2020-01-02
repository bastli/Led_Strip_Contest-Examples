#    _____                .__             .__          __                       
#   /     \ _____    ____ |__|_____  __ __|  | _____ _/  |_  ___________  ______
#  /  \ /  \\__  \  /    \|  \____ \|  |  \  | \__  \\   __\/  _ \_  __ \/  ___/
# /    Y    \/ __ \|   |  \  |  |_> >  |  /  |__/ __ \|  | (  <_> )  | \/\___ \ 
# \____|__  (____  /___|  /__|   __/|____/|____(____  /__|  \____/|__|  /____  >
#         \/     \/     \/   |__|                   \/                       \/ 

"""This file contains usefull functions to create and manipulate command matrices """

__author__ = 'Manumerus'
__maintainer__ = 'Manumerus'
__created__ = '36c3, December 2019'
__license__ = 'GPL'

import numpy as np

### function definitions ###

def strip_command_matrix(r,g,b):
    strip_command_list = np.empty((112,3))

    for i in range(112):
        strip_command_list[i,0] = r
        strip_command_list[i,1] = g
        strip_command_list[i,2] = b

    return strip_command_list


# def colour_to_strip_list(colour_list):
#     data_list= [0]*336
#     for i in range(336):
#         data_list[i]= rgb[i%3]


### for isolated testing purpose only ###
def main():

    data = strip_command_matrix(20,40,40)
    print(data)
   
if __name__ == "__main__":
    main()