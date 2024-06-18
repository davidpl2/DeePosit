<h1>DeePosit: an AI-based tool for detecting mouse urine and fecal depositions from thermal video clips of behavioral experiments</h1>
   
![DeePosit](ExampleOfResults/DeePositScreenShot.png)

<h2>Overview</h2>
This code allows automatic detection of urine and fecal depositions in thermal video of rodents during behavioural experiments. The algorithm is described in the paper mentioned in the title.
It is based on a preliminary hot blob detector and a classifier which is used to classify each preliminary detection as either urine\feces or background (i.e. not urine or feces). The classifier code is based on the code published by:
https://github.com/facebookresearch/detr 
<h2>Project structure</h2>  

1. DeePosit subfolder includes the code for the preliminary detection algorithm as well as the classifier. The project includes both Matlab and Python code. The code was developed in windows but can probably run in linux as well.  

2. ExampleOfResults subfolder includes a video demonstrating the automatic detection of urine (marked in green) and feces (marked in red). Preliminary detections that were classified as background are marked in blue.
   
3. FigStat includes additional statistical data for the figures in the paper.
   
4. Thermapp_VideoRecordingCode includes the code for recording video with the Opgal's IR Thermapp MD infrared camera which was used in this project. To use this code you will need a pc with Linux, a Thermapp MD camera, and the SDK of the camera (you will need to contact Opgal for the SDK).
   
5. VideoDatabase includes a recorded video which can be used to try the code. It should be downloaded from this [link](https://drive.google.com/file/d/1ICq_LorzK8Vlk3Shse2zbUK72bZrGR_6/view?usp=drive_link) and extrated in the project folder.  VideoDatabase\IR_Raw_Data contains the IR video and VideoDatabase\Raw data contains the matching visible wavelength video (visible wavelength video exist only for the trial period).


<h2>Getting Started</h2>

1. git clone https://github.com/davidpl2/DeePosit  

2. Download VideoDatabase from this [link](https://drive.google.com/file/d/1ICq_LorzK8Vlk3Shse2zbUK72bZrGR_6/view?usp=drive_link) and extract it in the project folder. 

3. To see the IR video, run the matlab script DeePositLabeler.m , Press on "Load Video" and choose one of the bin files in the directory VideoDatabase\IR_Raw_Data\SP\13.04.23\2F_1_SP_ICR Dup_WT_2023-04-13_13-56-32\.
   
4. Note that the DeePositLabeler can be used to manually annotate the videos. Specifically it may be used to manually select the frame range for the habituation period and the trial period, to annotate the polygon of the arena floor in habituation and trial periods, and to annotate the blackbody surface (in habituation and trial). These annotations are required before the automatic detection algorithm can run. As this example video is already annotated, these annotation will be overlayed.
   
5. To run the automatic detector, create a virtual environment with python 3.9: python3.9 -m venv YourVirtualEnvironmentName
   
6. From within the virtual environment, install requirements for the classifier using: pip install -r DeePosit\Classifier\requirements.txt
   
7. Edit the file DeePosit\getParams.m and change the following line to point to the relevant python executable:
params.pythonExe = '"YourVirtualEnvironmentName\Scripts\python.exe"';

8. Download the pre-trained weights file from this [link](https://drive.google.com/file/d/16qVqZz5Yz_im1quljCdQ8cLIBGlrLxOY/view?usp=drive_link) and put it in the folder DeePosit\Classifier\TrainedWeights.

8. Running the matlab script RunDeePositOnDB.m will run the preliminary detection and the classifier on all of the videos in the database (a single video is supplied in this github repository). The results will be saved in DeePositDetectionResults\<relative path of the input video>\DeePositRes.csv. Note that the videos in the database should be listed in the csv file: VideoDatabase\vidsID.csv . Note that you will need at least 32GB of RAM and a GPU with at least 4GB of memory. 


<h2>Training the classifier</h2>

1. To train the classifier, you will first need to generate a training and testing database. Do that by adding videos and annotate them using DeePositLabeler.m (including annotation of the urine and feces location). List the videos in the vidsID.csv and specify each video as either train or test video by putting 1 or 0 in the relevant column. Then run the RunDeePositOnDB.m with the flag GenerateTrainTestDB=true to generate the train and test database.
   
2. After generating the train and test database, change to folder DeePosit\Classifier and run the training of the classifier from within the virtual environment by running: python main.py --lr_drop 200 --lr_backbone 1e-5 --output_dir "SpecifyYourOutputDir" --epochs 500 --enc_layers 6 --dec_layers 6 --num_queries 1 --batch_size 24 --resume "PathToPretrainWeights" --dilation --train_img_folder "TrainImgsFolder" --val_img_folder "TestImagesFolder" --bbox_loss_coef 0 --giou_loss_coef 0
   
