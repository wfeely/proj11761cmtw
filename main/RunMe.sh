#!/bin/bash
#RunMe.sh
#Weston Feely, Mario Piergallini, Tom van Drunen, Callie Vaughn

################################################
# This program runs a topic model on the data  #
# and outputs a file containing one vector for #
# each document, with each entry of the vector #
# representing that document's probability of  #
# corresponding with a given topic             #
#                                              #
# The topics are labeled in the first line of  #
# the output file testSetWithTopics.csv        #
#                                              #
# The program takes in 3 arguments:            #
# 1. the file containing the test set data     #
# 2. the file containing the test set's labels #
################################################

op1=`readlink -f $1`
op2=`readlink -f $2`
op3=test

#Remove empty lines from op1 and op2
sed -i '/^$/d' $op1
sed -i '/^$/d' $op2

#Run TurboParser
#./install_turbo.sh

#Pre-Process Data using TurboParser
#./lns_preprocess.sh $op1 ./TurboParser-2.0.2
./lns_preprocess.sh $op1 ~/TurboParser-2.0.2

#Copy input files into named files in Data folder
cp $op1 Data/testSet.dat
cp $op2 Data/testSetLabels.dat

#Formats data for topic model
python Data/makeTestCSV.py Data/testSet.dat Data/testSet.csv

#Runs topic model inference on formatted data
java -Xmx4096m -jar tmt-0.4.0.jar inferTopics.scala

#Adds median feature to feature set
python findMedian.py model/testSet-document-topic-distributuions.csv model/testSet-features-with-median.csv

#Cleanup
rm -f testSet-document-topic-distributions.csv

#Get linguistic features from tagged and parsed data
python getlingfeats.py $op1.tagged $op1.parsed.fixed > Data/other_feats.csv

#Merge topic model features and linguistic features
python realAddLabels.py model/testSet-features-with-median.csv Data/testSetLabels.dat Data/other_feats.csv model/testSet-median-and-labels.csv

#Change space-separated file into comma-separated CSV
sed 's/ /,/g' model/testSet-median-and-labels.csv > model/$op3.csv

#Run Weka on feature set
./fix.py model/$op3.csv

cd java_part
javac -cp .:weka.jar artdet/ArticleDetector.java
java -cp .:weka.jar artdet.ArticleDetector -t ../Data/train.csv ../model/$op3.csv
