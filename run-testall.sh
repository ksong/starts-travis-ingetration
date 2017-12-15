#!/bin/bash

mkdir -p run

cd run

APIKEY="APIKEY"

for line in `cat ../projects`; 
do 
    proj=`echo $line|cut -d, -f1`
    BRANCH=`echo $line|cut -d, -f2`
    DIR=/tmp/$proj; 
    ls -ld $DIR; 
    echo "../generate-stats-with-travis-normal-full-automation.sh -d $DIR -n 10 -k ${APIKEY} -b ${BRANCH} -o ${proj}_testall.csv"
    ../generate-stats-with-travis-normal-full-automation.sh -d $DIR -n 10 -k ${APIKEY} -b ${BRANCH} -o ${proj}_testall.csv
    sleep 60
done
