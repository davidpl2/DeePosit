<h1>DeePosit: an AI-based tool for detecting mouse urine and fecal depositions from thermal video clips of behavioral experiments</h1>
   
![DeePosit](ExampleOfResults/DeePositScreenShot.png)

<h2>Overview</h2>
This code allows automatic detection of urine and fecal depositions in thermal video of rodents during behavioural experiments. The algorithm is described in the paper mentioned in the title.
It is based on a preliminary hot blob detector and a classifier which is used to classify each preliminary detection as either urine\feces or background (i.e. not urine or feces). The classifier code is based on the code published by:
https://github.com/facebookresearch/detr 
<h2>Project structure</h2>
1. DeePosit subfolder includes the code for the preliminary detection algorithm as well as the classifier. The project includes both Matlab and Python code. The code was developed in windows but can probably run in linux as well.  

2. The trained weights of the classifier are in DeePosit\Classifier\TrainedWeights .
   
4. ExampleOfResults includes a video demonstrating the automatic detection of urine (marked in green) and feces (marked in red). Preliminary detections that were classified as background are marked in blue.
   
6. FigStat includes additional statistical data for the figures in the paper.
   
8. Thermapp_VideoRecordingCode includes the code for recording video with the Opgal's IR Thermapp MD infrared camera which was used in this project. To use this code you will need a pc with Linux, a Thermapp MD camera, and the SDK of the camera (you will need to contact Opgal for the SDK).
   
10. VideoDatabase includes a recorded video which can be used to try the code. VideoDatabase\IR_Raw_Data contains the IR video and VideoDatabase\Raw data contains the matching visible wavelength video (visible wavelength video exist only for the trial period).


<h2>Getting Started</h2>
1. git clone https://github.com/davidpl2/DeePosit
2. Extract the zip file containing the video frames for the example video. The zip is located in: VideoDatabase\IR_Raw_Data\SP\13.04.23\2F_1_SP_ICR Dup_WT_2023-04-13_13-56-32.zip and should be extracted into the folder: \IR_Raw_Data\SP\13.04.23\2F_1_SP_ICR Dup_WT_2023-04-13_13-56-32
. Note that the bin files (the video frames) should be in the folder \IR_Raw_Data\SP\13.04.23\2F_1_SP_ICR Dup_WT_2023-04-13_13-56-32.
3. To see the IR video, run the matlab script DeePositLabeler.m , Press on "Load Video" and choose one of the bin files in the directory above.
4. Note that the DeePositLabeler can be used to manually annotate the videos. Specifically manually select the frame range for the habituation period and the trial period, to annotate the polygon of the arena floor in habituation and trial periods, and to annotate the blackbody surface (in habituation and trial). These annotations are required before the automatic detection algorithm can run. As this example video is already annotated, these annotation will be overlayed. 
5. To run the automatic detector, create a virtual environment with python 3.9: python3.9 -m venv <YourVirtualEnvironmentName>
6. From within the virtual environment, install requirements for the classifier using: pip install -r DeePosit\Classifier\requirements.txt
7. Edit the file DeePosit\getParams.m and change the following line to point to the relevant python executable:
params.pythonExe = '"YourVirtualEnvironmentName\Scripts\python.exe"';
8. Running the matlab script RunDeePositOnDB.m will run the preliminary detection and the classifier on all of the videos in the database (a single video is supplied in this github repository). The results will be saved in DeePositDetectionResults\<relative path of the input video>\DeePositRes.csv. Note that the videos in the database should be listed in the csv file: VideoDatabase\vidsID.csv . Note that you will need at least 32GB of RAM and a GPU with at least 4GB of memory. 


<h2>Training the classifier</h2>
1. To train the classifier, you will first need to generate a training and testing database. Do that by adding videos and annotating them using DeePositLabeler.m (including annotation of the urine and feces). List the videos in the vidsID.csv and specify each video as either train or test video by putting 1 or 0 in the relevant column. Then run the RunDeePositOnDB.m with the flag GenerateTrainTestDB=true to generate the train and test database.
2. After generating the train and test database, change to folder DeePosit\Classifier and run the training of the classifier by from within the virtual environment by running: python main.py --lr_drop 200 --lr_backbone 1e-5 --output_dir "SpecifyYourOutputDir" --epochs 500 --enc_layers 6 --dec_layers 6 --num_queries 1 --batch_size 24 --resume "PathToPretrainWeights" --dilation --train_img_folder "TrainImgsFolder" --val_img_folder "TestImagesFolder" --bbox_loss_coef 0 --giou_loss_coef 0 
