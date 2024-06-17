<h1>Readme</h1>
This code is used to capture IR video from Opgal's Thermapp MD long wave infra red camera. It is distributed as part of the code of the paper: Peles D. et al., "DeePosit: an AI-based tool for
2 detecting mouse urine and fecal depositions from thermal video clips of behavioral experiments."   


<h2>Installation Instructions:</h2>

1. Install Opgal's SDK (we used SDK version EyeR-op-SDK-x86-64-2.15.915.8688-MD) according to the SDK manual on a PC with Ubuntu. To get the SDK, please contact Opgal: https://www.opgal.com/
Run these lines in console after installation:
```
sudo su
cd /lib
ln -s /lib64/ld-linux-x86-64.so.2 ld-linux-x86-64.so.2
```
*To install the IR camera's calibration files, I found it easier to use the manual installation procedure (see the SDK manual) and using ThermApp android app to get the calibration files. After installing the app (contact Opgal to get the app), connect the camera to the Android phone and activate the app. The calibration files will be downloaded into a subdirectory of the app installation folder. This subfolder name will be the camera's serial number.

2. Create a python3.8 virtual environment and install dependencies. If python3.8 is not installed, run (in console):
```
sudo apt update
sudo apt upgrade
sudo apt install python3.8
sudo apt install python3.8-venv # install virtual-env
```
Create virtual env and install dependencies:
```
python3.8 -m venv ~/Desktop/Projects/venv38/
source ~/Desktop/Projects/venv38/bin/activate
pip3 install ./VideoRecording/requirments.txt
```
Create a folder for video recordings:
```
mkdir ~/Desktop/irData/
```

<h2>Recording video:</h2>
1. run RunThermappDeamon.sh from console (sudo password will be required).
2. run GrabbingGUI.sh from console (sudo password will be required).
3. You should see the video in the GUI.
4. Optional: wait 15 minutes to get the camera temperature stable (may improve the accuracy of the measured temperature).
4. Occlude the camera field of view with a uniform surface (a piece of cardboard) and press NUC. Wait until you see a uniform image.
5. You can press Record to start recording the video. A second press on this button to stop recording. The video will be saved in a subdirectory named with the date and time under: ~/Desktop/irData/. Each image is saved in a single bin file. During recording, take a look at the frame rate (FPS). Don't maximize the GUI window, as it might result in a reduction of the frame rate (the FPS is shown above the image. It should be between 8.6-8.7 frames per second).
6. Optional: if there is a black body in the field of view, you can left-click on it to see its temperature. The graph at the bottom part will show its temperature over time. (does not affect recorded video)
7. Optional: press the keyboard m button to change the contrast of the displayed image. (does not affect recorded video).
8. Press the Quit button when finished and close the console windows.

<h2>Open the recorded images</h2>
1. The recording directory will include .bin files named: frame_<frameID>_<Year>_<Month>_<Sec>.<microSec>.bin . Each of these frames includes a 16-bit grayscale image of 288 rows and 384 columns in RAW format. The following Matlab code can be used to read a single image file:
```
fd = fopen(file_name,'rb');
data = fread(fd,'uint16');
image = reshape(data,384,288)';
fclose(fd);
figure,imshow(image,[])
```
2. To get the values in Celsius degrees, use the following conversion:
```
image_celsius = (image - 27315.0)/100.0;
```

3. The recording directory will also include a bin file with a file name that starts with NUC (Non-Uniformity Correction). This is an average image of the last uniform surface that was recorded (see above). This file format is similar to the image file format, except that it is saved as a single precision data. The following code can be used to read this file:
```
fd = fopen(file_name,'rb');
data = fread(fd,'single');
NucImage = reshape(data,384,288)';
fclose(fd);
figure,imshow(NucImage,[])
```

We subtracted the NucImage from each of the recorded images to get better pixel uniformity:
```
NucImage = NucImage- mean(NucImage(:));
image = image - NucImage
image_celsius = (image - 27315.0)/100.0;
```

The image was further corrected by the use of a black body that was placed in the field of view and was set to 37 degrees Celsius.
```
image_celsius_calibrated = image_celsius - mean( image_celsius(black_body_pixels) ) + 37.0
```