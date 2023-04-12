********************************************************************************
* asci_steer.do   steering file for Agricultural Sustainability Index project
* Author: Stephan Brosig (modified by Brian Beadle)

* purpose:  A. define the program 'runsub' which takes a do file name as ///
* argument, creates and the corresponding log file and defines the ///
* global macro 'scriptname' 
* C. present the list of runsub calls with the respective do files as ///
* arguments (and brief description). 

* To execute do files the respective runsub command is commented out

* I usually copy the change-working-directory-command from here and paste it ///
* into the stata command window: cd D:\github\agricultural_sustainability\stata

* FOR BRIAN, SHARED DIRECTORY: start STATA and change working directory:  
*	cd C:/Users/Beadle/Documents/GitHub/sustainability_index/chapter2   
* then start from stata commandline with: do ch2-1.do
********************************************************************************

clear all
set more off

*** DEFINE PROGRAM WHICH:
* 		a) RUNS A SUB-PROGRAM USING THE DO FILE NAME FOUND IN THE ARGUMENT,
*       b) DEFINES A GLOBAL MACRO CONTAINING THE SCIPTNAME, AND 
*       c) DIRECTS the SUB-PROGRAM's LOG TO THE RESPECTIVE LOG FILE
capture program drop runsub    
program runsub
   args name
clear                       // just in case...
global scriptname "`name'"  // in case that the scriptname will be used in ///
* 								sub-program, e.g. for naming graphs
capture log close                                 // just in case...
qui log using "log\\`name'.log", text replace     // define log file
capture log off
do "cmd\\`name'.do"                               // run do file
end   // end of prorgam runsub

set dp period // set to comma for export into German MSExcel, otherwise period
*set scheme steph1  // graphic settings!!! file sits in PERSONAL directory, ///
* 						e.g. c:\ado\personal\scheme-steph1.scheme
*set scheme s2mono

***** RUNNING THE DO-FILES 

*runsub  csrGlobals    // set global macros

runsub  010-asci_fadn  // to do the following: 
* 	a) import all fadn data (csv format) (file location has to be specified!) 
* 	b) attach labels 
* 	c) check availability of vars in all years 
* 	d) describe data

* import additional data files for indicators
runsub  020-asci_impadd 

* computes quantiles of ag labor remuneration and compares to TBN data (Thünen)
runsub  100-asci_wage_quantiles 

* compare summary statistics downloaded from FADN Public Data Base,
* with summary statistics of our data
runsub  140-asci_comp_w_FADN_Public_Database

*runsub  asci_mfp // data for multi factor productivity computation
*runsub  112-asi2013-methods_comparison // 
*runsub  120-asci_panmemscreen    // CONVENIENCE program to create tables showing devt of important farm characteristics across years
*runsub  150-asci_StandOutp    // generate standard output for different ouput types
*runsub  2XX-asci_screenIRMResults    // screen GRM3 results 
