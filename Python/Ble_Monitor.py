# -*- coding: utf-8 -*-
"""
Created on Mon Jan  9 13:35:26 2023

@author: Josie Cooper
"""

import matplotlib.pyplot as plt
import asyncio
from bleak import BleakScanner
import binascii


plt.ion()



TargetName = "----"

data = ''

run = True


def detection_callback(device, advertisement_data):
    if(device.name == TargetName):
        #print(device.address, "RSSI:", device.rssi, advertisement_data)
        global data
        data = advertisement_data.manufacturer_data[1565]

async def main():
    graph = Graph()
    while(run):
        scanner = BleakScanner()
        scanner.register_detection_callback(detection_callback)
        await scanner.start()
        await asyncio.sleep(1.0)
        await scanner.stop()
        found = False
        targetD = 0
        for d in scanner.discovered_devices:
            if(d.name == TargetName):
                found = True
                targetD = d
        printResult(found,targetD,graph)
        
def convertUUID(uuid):
    try:
        Sample = binascii.hexlify(uuid)
        print(Sample)
        val = float(int(Sample[26:30],16)&0xffff)
    except:
        return 0
    val = val*0.001
    print(str(val), "%")
    return val

def printResult(isFound, targetDevice,graph):
    if(isFound):
        print("Device Advertising", targetDevice)
        graph.appendToGraph(convertUUID(data))
        
    else:
        print("Device not Advertising")
        
class Graph:
    fig = ''
    ax = ''
    count = 0
    xs = []
    ys = []
        
    def __init__(self):
        self.fig = plt.figure()
        plt.xlabel('Time(~s)')
        plt.ylabel('Stretch(%)')
        self.ax = self.fig.add_subplot(1,1,1)
        plt.show(block=False)
        
    def appendToGraph(self, val):
        self.count = self.count + 1
        self.xs.append(self.count)
        self.ys.append(val)
        self.ax.clear()
        self.ax.plot(self.xs,self.ys)
        plt.ylim(0,100)
        plt.xlabel('Time(~s)')
        plt.ylabel('Value(%)')
        plt.draw()
        plt.pause(0.001)
        


loop = asyncio.new_event_loop()
loop.run_until_complete(main())






    
    
        


    
    
