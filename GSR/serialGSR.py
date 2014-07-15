import serial
ser = serial.Serial('/dev/tty.usbmodem000001', 115200, timeout=1) 
s = ser.read(10)        # read up to ten bytes (timeout)
line = ser.readline()   # read a '\n' terminated line
print ser.name, s, line,

while True:
print ser.readline()


ser.close()