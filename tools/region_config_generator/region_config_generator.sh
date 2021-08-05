#!/bin/bash

fileName=$1
dirName=$2
filePath=../../../../$3 #envs/prod/17app/dirName/fileName
# $4 ~ regions 
cd ../../envs
for env in dev sta prod uat
do
    for a
    do
        if [ $a != $1 ] && [ $a != $2 ] && [ $a != $3 ];then
            cd $env/17app/
            if [ ! -d $dirName ];then
                mkdir $dirName
            fi
            cd $dirName
            if [ $a != TW ] && [ ! -f ${a}_$fileName ];then
                cp $filePath ${a}_${fileName}
            elif [ ! -f $fileName ];then
                cp $filePath $fileName
            fi
            cd ../../../
        fi 
    done
done

