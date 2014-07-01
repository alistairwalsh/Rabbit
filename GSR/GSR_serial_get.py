# -*- coding: utf-8 -*-
"""
Created on Tue Jul  1 14:08:39 2014

@author: Wintermute
"""

import serial, time

ser = serial.Serial('/dev/tty.usbmodem000001', 115200, timeout=1) 
#ser.open()
time.sleep(1)
while True:
    daat = ser.readall()
    print ser.name, 'says', daat
    cont = raw_input('continue? y/n: ')
    if cont != 'y':
        break

ser.close()