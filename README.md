# sustainability_index
This repository contains all the code I used to generate an agricultural sustainability index using item response theory

## still under construction...

## GUIDE FOR USING THE STATA FILES IN THE PRELIMINARY ANALYSES
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

## After the preliminary analysis, all files run independently after the working directory is set.
