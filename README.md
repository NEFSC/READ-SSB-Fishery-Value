# Project Template

A repository for the Fishery Value Project. 

# How to Contribute

1. Please use base R and tidyverse as much as possible.
2. Use snake_case (example: user_input). Please do not use camelCase.

# Overview and Folder structure

This is mostly borrowed from the world bank's EDB. https://dimewiki.worldbank.org/wiki/Stata_Coding_Practices
Please use forward slashes (that is C:/path/to/your/folder) instead of backslashes for unix/mac compatability. I'm forgetful about this. 

I keep each project in a separate folder.  A stata do file containing folder names get stored as a macro in stata's startup profile.do.  This lets me start working on any of my projects by opening stata and typing: 
```
do $my_project_name
```
Rstudio users using projects don't have to do this step.  But it is convenient to read paths into variables by using the "R_paths_libraries.R" file.

# NOAA Requirements
This repository is a scientific product and is not official communication of the National Oceanic and Atmospheric Administration, or the United States Department of Commerce. All NOAA GitHub project code is provided on an ‘as is’ basis and the user assumes responsibility for its use. Any claims against the Department of Commerce or Department of Commerce bureaus stemming from the use of this GitHub project will be governed by all applicable Federal law. Any reference to specific commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply their endorsement, recommendation or favoring by the Department of Commerce. The Department of Commerce seal and logo, or the seal and logo of a DOC bureau, shall not be used in any manner to imply endorsement of any commercial product or activity by DOC or the United States Government.”


1. who worked on this project:  Min-Yang Lee
1. when this project was created: June, 2025 
1. what the project does: Fishery Value project 
1. why the project is useful:  ST5 asked us to do it. 
1. how users can get started with the project: Download and follow the readme
1. where users can get help with your project:  email me or open an issue
1. who maintains and contributes to the project. Min-Yang

# License file
See here for the [license file](License.txt)
