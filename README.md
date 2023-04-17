# sustainability_index
This repository contains all the code I used to generate an agricultural sustainability index using item response theory.

## still under construction...

Authors: Brian Beadle, Stephan Brosig, Christoph Wunder <br>
Date: developed from 2020 - 2023 <br>
Data source: FADN (observation period = 2004 - 2013, focus region = Germany) and other secondary sources <br>
Programs: R (version 3.6.3) and Stata (versions 14 and 17) <br>
<br>
# main tasks: 
     1 import and clean all data
     2 generate continuous variables for measuring farm sustainability
     3 transform variables into 4-category ordinal items
     4 estimate item response models for agricultural sustainability
     5 test model for robustness against missing data and simulate scale linking procedures
     6 apply model to two topics: sustainability of non-food crop production, 
           and sustainability differences between conventional and organic farms
     7 generate all tables and graphs for thesis

## guide for using stata files in preliminary analysis
      1 a) make /stata your working directory: from command window type   cd ..../stata
        b) define the desired location of log file (because do files use that reference):  
           e.g.   log using log/XYZ.log (or log using log/XYZ.smcl)
        c) define the global macro scriptname (because some do files use that macro) : global scriptname XYZ
        d) run the do file: do cmd/XYZ.do
        e) close log file: log close
      2 a) do steps 1 a) 1 b) and 1 c)
        b) load do file in stata editor
        c) execute it from the editor
        d) step 1 e)
      3 a) do step 1 a)
        b) edit /cmd/000-asci_steer.do and add command runsub(XYZ)  to the end of that file 
        c) run the steering do file: do 000-asci_steer.do

## after the preliminary analysis, all files run independently after the working directory is set.
