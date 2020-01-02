

"""This file handels the hole process including the GUI, processing and uploading"""

__author__ = 'Manumerus'
__maintainer__ = 'Manumerus'
__created__ = '36c3, December 2019'
__license__ = 'GPL'
   
   
   
    def strobo(self, freq):
        delay = 1/(2*freq)
        payload= [0]*336
        for i in range(15):
            data_list = [i]+payload
            self.connection.sendto(bytes(data_list), (self.ip, self.port))
        
        time.sleep(delay)

        payload= [100]*336
        for i in range(15):
            data_list = [i]+payload
            self.connection.sendto(bytes(data_list), (self.ip, self.port))
        
        time.sleep(delay)

    def colour_to_data_list(self, rgb):
        data_list= [0]*336
        for i in range(336):
            data_list[i]= rgb[i%3]

        return data_list