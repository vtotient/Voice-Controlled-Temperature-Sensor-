import serial
import serial.tools.list_ports

PORT = 'COM3'
try:
	ser.close();
except:
	 print();
try:
	 ser = serial.Serial(PORT, 115200, timeout=100)
except:
	 print ('Serial port %s is not available' % PORT);
	 portlist=list(serial.tools.list_ports.comports())
	 print('Trying with port %s' % portlist[0][0]);
	 ser = serial.Serial(portlist[0][0], 115200, timeout=100)
	 ser.isOpen()
while 1 :
	 strin = ser.readline();
	 print(strin.decode('ascii')); 