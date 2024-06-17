# -*- coding: utf-8 -*-
# Author: David Peles (Based on example from Opgal's SDK).
# Shlomo Wagner's Lab, Sagol Department of Neurobiology, University of Haifa. https://shlomowagner-lab.haifa.ac.il/
# If you use this code, please cite: Peles D et al, "DeePosit: an AI-based tool for detecting mouse urine and fecal depositions from thermal video clips of behavioral experiments"
# Refer to https://github.com/davidpl2/DeePosit/License.txt for license details.
from __future__ import print_function

import argparse
import os
import sys
import time
from datetime import datetime

import numpy as np
import pyeyerop as erop
from matplotlib import pyplot as plt
from matplotlib.widgets import Button
from mpl_toolkits.axes_grid1 import make_axes_locatable

PY_MAJOR_VERSION = sys.version_info[0]

if PY_MAJOR_VERSION > 2:
    NULL_CHAR = 0
    open_args = "w+b"
else:
    NULL_CHAR = '\0'
    open_args = "w+"

quitFlag = 0
recordFlag = 0
newRecordFlag = 1
framesForNuc = 16
nucCompleted = False
nucCnt = 0
dispMode = 0
reDrawColorbar = False
offlineMode = False
rows = 288
cols = 384
BlackBodyX = int(384/2)
BlackBodyY = int(288/2)
bnRec = 0
bnRecAndNUC = 0

def press(event):
    global quitFlag
    global recordFlag
    global newRecordFlag
    global nucCompleted
    global nucCnt
    global dispMode
    global reDrawColorbar
    print('press', event.key)
    sys.stdout.flush()
    print('Key pressed: ',event.key)
    if event.key == 'q':
        quitFlag = 1
    if event.key == 'r':
        newRecordFlag = 1
        recordFlag = 1
    if event.key == 'e':
        recordFlag = 0
    if event.key == 'n':
        print('Computing NUC')
        nucCnt = 0
        nucCompleted = False
    if event.key =='m':
        dispMode = (dispMode+1)%3
        reDrawColorbar = True

def onRecord(event):
    global recordFlag
    global newRecordFlag
    if recordFlag:
        recordFlag = 0
        bnRec.label.set_text("Record")
    else:
        newRecordFlag = 1
        recordFlag = 1
        bnRec.label.set_text("Stop")

def onNUC(event):
    global nucCnt, nucCompleted
    print('Computing NUC')
    nucCnt = 0
    nucCompleted = False

def onRecordAndNUC(event):
    global recordFlag
    onRecord(event)
    if recordFlag:
        onNUC(event)
        bnRecAndNUC.label.set_text("Stop")
    else:
        bnRecAndNUC.label.set_text('REC & NUC')

def onQuit(event):
    global quitFlag
    quitFlag = 1

def onclick(event):
    print('%s click: button=%d, x=%d, y=%d, xdata=%f, ydata=%f' %
          ('double' if event.dblclick else 'single', event.button,
           event.x, event.y, event.xdata, event.ydata))
    global BlackBodyX
    global BlackBodyY
    if event.xdata >=10 and event.xdata<=cols-10-1 and event.ydata >=10 and event.ydata<=rows-10-1:
        BlackBodyX = min(max(10,int(event.xdata)),cols-10-1)
        BlackBodyY = min(max(10,int(event.ydata)),rows-10-1)

def GetDateTimeStr():
    now = datetime.now() # current date and time
    date_time_str = now.strftime("%Y-%m-%d_%H-%M-%S.%f")
    return date_time_str

class OfflineFrameReader:
    def __init__(self,srcDir):
        self.fnames = [f for f in os.listdir(srcDir) if f.endswith(".bin")]  # isfile(join(mypath, f))]
        self.fnames.sort()
        self.curInd = 0
        self.srcDir = srcDir
        self.GetNextFrameCnt = 0

    def GetNextFrame(self):
        curFname = os.path.join(self.srcDir, self.fnames[self.curInd])
        im = np.fromfile(curFname, dtype='int16', sep="")
        im = im.reshape([rows, cols])
        self.curInd = (self.curInd+1)%len(self.fnames)
        self.GetNextFrameCnt = self.GetNextFrameCnt+1

        return im, self.GetNextFrameCnt



def main():
    global recordFlag
    global newRecordFlag
    global quitFlag
    global nucCompleted
    global nucCnt
    global reDrawColorbar
    global bnRec
    global bnRecAndNUC
    p2=0#handle for plot object
    p3=0 #handle for plot object
    #matplotlib.use('qt5agg')

    print("Press r to start record")
    print("Press e to end record")
    print("Press q to quit")
    print("Press m to change contrast")
    print("the first 2 seconds of video after startup is used for non uniformity calibration, so please activate the grabbing software after occluding the camera with a uniform surface")
    print("You can press n re-calculate the NUC (position a uniform surface in front of the camera before pressing n)")

    g_dumpFiles = False
    g_log2Length = 2

    # Instantiate the parser
    parser = argparse.ArgumentParser()
    parser.add_argument('name', nargs="?", type=str, default="",
                        help='part of shared memory name')
    parser.add_argument('-d', type=str,
                        help='path to shared memory name')
    # Optional argument
    parser.add_argument('-l', type=int,
                        help='The log 2 of number of ipc buffers to allocate.\nValid values are in the range of 0 for one buffer and 4 for 16 buffers.\nThe default is 2.')
    args = parser.parse_args()
    name = args.name
    path = args.d
    if args.l is not None: g_log2Length = args.l
    if g_log2Length < 0:
        print("Log 2 Length of %d is less than 0. 0 will be used\n", g_log2Length)
        g_log2Length = 2
    if g_log2Length > 4:
        print("Log 2 Length of %d is greater than 4. 4 will be used\n", g_log2Length)
        g_log2Length = 4;
    print("g_log2Length %d\n", g_log2Length)
    nOutputImageQ = 1 << g_log2Length
    print("name ", name)
    print("nOutputImageQ ", nOutputImageQ)
    usbCam = erop.USBCam(name, nOutputImageQ)
    print("Dump File ", g_dumpFiles)
    nucCompletionFrame = -1
    maxList = []
    BBList = []
    saveNuc = False
    if offlineMode:
        frameReader = OfflineFrameReader('/home/dp/irData/2021-04-27_19-41-34/')
        

    if offlineMode or (usbCam.open_shared_memory() != -1):
        # check if user set any path
        if path is None:
            path = "./"
        fig = 0

        imSum     = np.zeros((rows,cols),np.float32)
        imSumTemp = np.zeros((rows,cols),np.float64)
        if offlineMode:
            nucCompleted = True
            dateStr = GetDateTimeStr()
            nuc_short_fname = "NUC_float_frame_zero.bin"

        frameCntFPS = 0
        startTime = time.time()
        curFPS=0
        firstIter=True
        while True:
            if offlineMode:
                srcImg,imageId= frameReader.GetNextFrame()
            else:
                data = usbCam.get_data()
                if data is None:
                    continue
                imageId = usbCam.imageId

                srcImg = np.frombuffer(data[64:], dtype=np.uint16).reshape(usbCam.imageHeight, usbCam.imageWidth)

            if (nucCnt < framesForNuc) and not nucCompleted:
                imSumTemp = imSumTemp + srcImg.astype(np.float64)
                nucCnt = nucCnt+1

            if (nucCnt == framesForNuc) and not nucCompleted:
                imSumTemp = imSumTemp/framesForNuc
                #imSum = (imSumTemp - imSumTemp.mean()).astype(np.float32)
                imSum = (imSumTemp - np.median(imSumTemp)).astype(np.float32)
                imSumTemp[:] = 0.0
                print('imSum mean is' , imSum.mean(), ' cnt is ',nucCnt)
                nucCompleted = True
                nucCompletionFrame = imageId

                #save this nuc in the parent recording directory:
                dateStr = GetDateTimeStr()
                curNucPath = os.path.join(path, dateStr)
                nuc_short_fname = "NUC_float_frame_{}__{}.bin".format(dateStr, nucCompletionFrame)
                nuc_fname = os.path.join(path , nuc_short_fname)
                f = open(nuc_fname, open_args)
                f.write(imSum)
                f.close()
                saveNuc = True #save this nuc also in the record directory


            #print("Got frame ", usbCam.imageId, " with dimensions ", usbCam.imageWidth, usbCam.imageHeight)
            # save the files
            if recordFlag:
                dateStr = GetDateTimeStr()
                if newRecordFlag:
                    curRecPath = os.path.join(path, dateStr)
                    # create directory if the path not exists
                    if not os.path.exists(curRecPath):
                        os.mkdir(curRecPath)
                        print("Recording to directory: {}".format(curRecPath))
                    newRecordFlag = 0
                    recordedFrames = 0
                    if nucCompleted:
                        saveNuc = True
                if saveNuc:

                    frame_name = os.path.join(curRecPath , nuc_short_fname)
                    print('Saving NUC to{}'.format(frame_name))
                    f = open(frame_name, open_args)
                    f.write(imSum)
                    f.close()
                    saveNuc = False
                frame_name = os.path.join(curRecPath , "frame_{}_{}.bin".format(imageId,dateStr))
                f = open(frame_name, open_args)
                #f.write(data[64:])
                f.write(srcImg)
                f.close()
                recordedFrames = recordedFrames+1
                if np.mod(recordedFrames,10)==0:
                    print('{} recorded frames. Last is: {}'.format(recordedFrames, frame_name))

            celsiusImg = (srcImg.astype(np.float32) - imSum - 27315) / 100.0
            cropIm = celsiusImg[:,130:]
            ind = np.unravel_index(np.argmax(cropIm, axis=None), cropIm.shape)
            ind = [ind[0],ind[1]+130]
            maxTemp = celsiusImg[ind[0], ind[1]]
            r = 5
            meanBlackBody = np.mean(celsiusImg[BlackBodyY - r:BlackBodyY + r + 1, BlackBodyX - r:BlackBodyX + r + 1])
            maxList.append(maxTemp)
            BBList.append(meanBlackBody)
            if len(maxList) > 1044:
                maxList.pop(0)
                BBList.pop(0)

            if 0:
                rgb = srcImg.copy() - srcImg.min()
                rgb = cv2.convertScaleAbs(rgb, alpha=(255.0 / rgb.max()))
                cv2.imshow('image', rgb)
                if cv2.waitKey(1) & 0xFF == ord('q'):
                    break
            else:
                frameCntFPS = frameCntFPS+1
                if frameCntFPS==20:
                    curTime = time.time()
                    curFPS = 20/(curTime - startTime)
                    frameCntFPS = 0
                    startTime = curTime

                if fig==0:
                    fig, ax = plt.subplots(2,1,gridspec_kw={'height_ratios': [3, 1]},figsize=(8, 4))#figsize=(9, 7))
                    fig.canvas.mpl_connect('key_press_event', press)
                    divider = make_axes_locatable(ax[0])
                    cax = divider.append_axes("right", size="5%", pad=0.05)
                    fig.canvas.mpl_connect('button_press_event', onclick)
                    pltHandle=0
                    axRec = plt.axes([0.01, 0.9, 0.09, 0.075])
                    bnRec = Button(axRec, 'Record')
                    bnRec.on_clicked(onRecord)

                    axNUC = plt.axes([0.01, 0.8, 0.09, 0.075])
                    bnNUC = Button(axNUC, 'NUC')
                    bnNUC.on_clicked(onNUC)

                    #axRecAndNuc = plt.axes([0.01, 0.7, 0.09, 0.075])
                    #bnRecAndNUC = Button(axRecAndNuc, 'REC & NUC')
                    #bnRecAndNUC.on_clicked(onRecordAndNUC)

                    axQuit = plt.axes([0.01, 0.6, 0.09, 0.075])
                    bnQuit = Button(axQuit, 'Quit')
                    bnQuit.on_clicked(onQuit)
                    plt.ioff()

                plt.sca(ax[0])
                if not firstIter:
                    p.remove()


                #plt.cla()
                #if 0:#not firstIter:
                    #p.set_data(celsiusImg)
                #else:
                if dispMode==0:
                    #if firstIter:
                        p = plt.imshow(celsiusImg, vmin=15,vmax=45,cmap='jet',interpolation='nearest')
                    #else:
                    #    p.set_array(celsiusImg)
                elif dispMode==1:
                    p = plt.imshow(celsiusImg, vmin=35, vmax=39, cmap='jet',interpolation='nearest')
                else:
                    p = plt.imshow(celsiusImg, vmin=10, vmax=60, cmap='jet',interpolation='nearest')
                if firstIter or reDrawColorbar:
                    cax.cla()
                    plt.colorbar(ax=ax[0],cax=cax)
                    reDrawColorbar = False

                #fig.colorbar(p,ax=ax)
                #plt.sca(ax[0])
                if (imageId%5==0) or firstIter:
                    if p2:
                        p2.pop(0).remove()
                    if p3:
                        p3.pop(0).remove()
                    p2 = ax[0].plot([BlackBodyX-r,BlackBodyX+r,BlackBodyX+r,BlackBodyX-r,BlackBodyX-r],[BlackBodyY-r,BlackBodyY-r,BlackBodyY+r,BlackBodyY+r,BlackBodyY-r],'k')
                    #plt.title(str(celsiusImg[288/2,384/2]))
                    p3 = ax[0].plot(ind[1], ind[0], '+g')
                    #plt.title("FPS{:.2f} , Center Temp(C): {:.2f}, Max: {:.2f}".format( curFPS, celsiusImg[144, 192], maxTemp))

                if imageId%5==0:
                    if recordFlag:
                        plt.title("FPS{:.2f} ,Recorded {} frames to: {}".format(curFPS,recordedFrames, curRecPath))
                    else:
                        plt.title("FPS {:.2f} ,meanBB {:.2f}".format(curFPS,meanBlackBody))


                if imageId%6==0 or firstIter:
                    #plt.sca(ax[1])
                    #plt.cla()
                    #plt.plot(maxList, '.g')
                    #plt.plot(BBList,  '.k')
                    if pltHandle:
                        pltHandle.pop(0).remove()
                        pltHandle.pop(0).remove()
                    pltHandle = ax[1].plot(np.array(maxList)-np.array(BBList) + 37.0, '.g',BBList,  '.k')
                    #plt.plot(maxList,'.r',BBList,'.g',np.array(maxList) - np.array(BBList) + 37.0, '.b')
                    #
                    if firstIter:
                        plt.sca(ax[1])
                        plt.grid()
                        plt.xlabel('frameInd')
                        plt.ylabel('deg(C)')
                        ax[1].legend(['max-BB+37','BB'], loc='upper left')
                if offlineMode:
                    plt.pause(0.001)
                else:
                    plt.pause(0.0001)

                #print('Min celsiusImg is ', celsiusImg.min(),  ' and Max is ', celsiusImg.max())
            if quitFlag:
                print('q was pressed. quitting')
                break
            firstIter = False


        print("finish")
    print("finish")


if __name__ == '__main__':
    main()
