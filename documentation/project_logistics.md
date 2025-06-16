# Overview
In general, I'm trying to keep code, raw data, processed data, results, and images separate.  I have soft coded these directories; and only two files needs to be changed (the ones in project_logistics) to change the project directories and subdirectories.

Smaller bits of analysis that are related (or depend on previous) are collected together in a wrapper.

# Cloning from Github and other setup
Min-Yang is using Rstudio to write Rmd and it's git version controling to commit/push/pull from github. It works reasonably well.  So does github desktop.  You will also need git installed.

The easist thing to do is create a new repository using this as a template. [Here's a starting guide](https://cfss.uchicago.edu/setup/git-with-rstudio/).  Don't put spaces in the name.  This will set up many, but not all of the folders.
# Description of the folders

## project_logistics
A pair of small do files to set up folders and then make stata aware of folders.

## data_extraction_processing
There is sample code in "data_extraction_processing" that you can use to get deflators.  This can be done with "/data_extraction_processing/wrapper_external.do".  You'll need an API key to import fred.  Extracting OES and QCEW data is really slow. 

## summary stats

The code in here will do a bunch of data exploration.  Violin plots take a while to run.  

## Sub-projects
Code for smaller pieces of the project are all in their individual folders in "stata_code". For the most part, they produce datasets or tables in  "/results/" and images in "/images/"
