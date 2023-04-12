/// 010-asci_fadn.do   import all csv data, attach labels, check availability of vars in all years, describe data
///            using the original data files (with FADN and NUTS3 data in separate csv files)
/// purpose:  import fadn csv files and nuts3 files, merge them and save by year and combined
///           drop all vars with constant (or missing) value over all observations 
///           attach labels
///           check consistency of files: completeness of variables appearing in all rounds
///           data cleaning: replace pre2009 values of F86 (land rent) by imputed values
/// Input:  ~\stata\inp\fadn variable labels.txt
///         ~D:\work(nobackup)\FADN Data_v1\\f20180410_0517\\YYY20XX.csv  (fadn raw data except NUTS3 code, YYY=country code, XX=year, from IAMO_20180410.zip)
///         ~D:\work(nobackup)\FADN Data_v1\\f20180410_0517\\NUTS3\YYY20XX.csv  (table for matching farm ID and NUTS3 code, YYY=country code,XX=year, from SO_NUTS3 Update 20180517.zip)
/// requires: \cmd\011-asci_nutsvars.do   changes nuts2 and nuts3 codes where possible to 2013-standards (in some cases unprecise) and  generate factor variables (which can be labelled) from some string variables
///           \cmd\012-asci_Format_long.do, 013-asci_Format_short.do, AND 014-asci_Format_vnamepluslong.do  define and applies variable and value labels (long incl measurement units etc)
///           
/// Output: C:\Eigene Dateien\IAMO Cloud\Brian\stata\dat\010-asci_fadnYYY_all.dta    data file, YYY=country code, e.g. DEU
///         C:\Eigene Dateien\IAMO Cloud\Brian\stata\log\010-asci_fadnYYY.log     w YYY=country code, e.g. DEU; contains table on data availability of variables
///                                  and codebook of the big file 

*global raw "C:\Users\Beadle\Desktop\fadn_fix"          // fadn raw data directory BRIAN
global raw "C:\work(nobackup)\FADN Data_v1"             // fadn raw data directory (path on Stephan's computer)
*global raw "\\Client\C$\work(nobackup)\FADN Data_v1"   // fadn raw data directory (path to be used when running Stata from STephan'S login on work station 7)

global land "DEU"     // indicate code for the country for which the data are to be used

qui log on
di "The log for the do file ${scriptname}.do is in separate log files for each country, ${scriptname}DEU.log, ${scriptname}FRA.log, ect."
qui log off

capture log close                                 // just in case...
qui log using "log\\${scriptname}${land}.log", text replace   // define log file
qui log off

capture erase "dat\\${scriptname}${land}_tmp" // if existing
capture erase "dat\\${scriptname}${land}_all" // if existing

import delim using "inp\fadn variable labels.txt", delim(";") varnames(1) clear          // copied from fadn website
replace var = ustrtrim(var)  // remove trailing and leading blanks (inkl unicode)
replace label = ustrtrim(label)  // remove trailing and leading blanks (inkl unicode)
duplicates drop var, force 
save "dat\\${scriptname}${land}_tmp", replace  // first version of this file with only two vars: Varname and Label. ... to be enlarged by merging...

capture program drop druck // in case it already exists
program druck   // add a variable indicating which variables exist in the respective round
qui log on
di "This log file describes the data compiled BY MERGING FADN AND NUTS3 FILES. It contains 3 parts:" _n ///
    "  1) data set description and compact codebook with each variable described in one line" _n ///
    "  2) a detailed codebook with univariate statistics for each variable" _n ///
    "  3) a list showing which variables are available for each round (year)"
    qui log off
end // end program druck

druck


capture program drop roundvars // in case it already exists
program roundvars   // add a variable indicating which variables exist in the respective round
args jahr // specifies the file (survey round) to be used

import delim using "${raw}\\f20180410_0517\\\${land}`jahr'.csv", varnames(1) case(preserve) clear stringcols(980)    //  THE OLD DATA SOURCE: FADN data without NUTS3-code
save "dat\\${scriptname}${land}_`jahr'", replace   // save in stata format
import delim using "${raw}\\f20180410_0517\\NUTS3\\${land}`jahr'.csv", varnames(1) case(preserve) clear stringcols(4)   // THE OLD DATA SOURCE: NUTS3-code
di _n "fadn and nuts3 for `jahr':"
merge 1:m id using "dat\\${scriptname}${land}_`jahr'"  // merge fadn-data file and nuts3 file by id AND A1
qui drop if _merge==1
drop _merge

*qui do "cmd\\013-asci_Format_short.do"  // assign SHORT label definitions
*qui do "cmd\\014-asci_Format_vnamepluslong.do"  // assign definitions of labels consisting of VARNAME PLUS LONG label
*qui do "cmd\\012-asci_Format_long.do"  // assign LONG label definitions
save "dat\\${scriptname}${land}_`jahr'", replace   // save in stata format for later use

qui ds             // save all variable names in a string that can be called by r(varlist)
local vliste  = r(varlist)
local laenge = wordcount(r(varlist))

drop _all
set obs  `laenge'
qui gen byte  y`jahr' = 1    // indicator that this variable is present in the data set of that year
qui gen str11 var = ""     // generate an empty variable that will contain the variable names of the data set
forvalues i = 1/`laenge' {
qui replace var = word("`vliste'",`i') if _n==`i'
}
*replace var = stritrim(var)  // remove internal blanks
*replace var = strtrim(var)  // remove trailing and leading blanks

merge m:m var using "dat\\${scriptname}${land}_tmp", nogen   // merge the data of current round to existing set
save                "dat\\${scriptname}${land}_tmp", replace  

end // end roundvars


roundvars 2004
roundvars 2005
roundvars 2006
roundvars 2007
roundvars 2008
roundvars 2009
roundvars 2010
roundvars 2011
roundvars 2012
roundvars 2013

// COMPILE ALL DATA IN ONE LARGE FILE
use "dat\\${scriptname}${land}_2004", clear
capture append using "dat\\${scriptname}${land}_2005" "dat\\${scriptname}${land}_2006" "dat\\${scriptname}${land}_2007" ///
                     "dat\\${scriptname}${land}_2008" "dat\\${scriptname}${land}_2009" "dat\\${scriptname}${land}_2010" ///
                     "dat\\${scriptname}${land}_2011" "dat\\${scriptname}${land}_2012" "dat\\${scriptname}${land}_2013" 
qui codebook, problems // stores in r(cons) the names of all vars with constant (or missing) value
local cons_miss  = r(cons)  
drop `cons_miss'  // drop all vars with constant (or missing) value



qui do "cmd\\011-asci_nutsvars.do"  // generate factor variables (which can be labelled) from NUTS2 and NUTS3 string variables 
order NUTS1 NUTS2 NUTS3, a(A1)  // arrange variables in data set ( NUTS1 NUTS2 NUTS3 may be candidates for dropping)
encode id, gen(idn)   // integer id variable (generated from the (length 16) numeric string variable of the fadn original
label save idn using "fmt\idn", replace  // to be called in asci_Format...do
order idn, a(id)  // arrange variables in data set: idn after id
drop id //  to avoid using it by mistake. idn is the integer id variable containing the original character 16-digit numeric strings as value labels
// DATA REPAIR: IMPUTE VALUES FOR PRE-2009 YEARS OF f86 (land rent paid). (FADN data contain zero values throughout pre-2009 years.) Imputed values are fractions of total rent paid (including for buildings) based on land rent shares of the most recent 2009ff year available
gen lndpct = F86/F85  // share of land rents in total rents paid
replace lndpct=1 if F85==0
gen lp09 = lndpct if YEAR==2009 
gen lp10 = lndpct if YEAR==2010 
gen lp11 = lndpct if YEAR==2011 
gen lp12 = lndpct if YEAR==2012 
gen lp13 = lndpct if YEAR==2013

bysort idn: egen lpem09 = max(lp09)  // copy land rent share of the farm in 2009 to all years
bysort idn: egen lpem10 = max(lp10)
bysort idn: egen lpem11 = max(lp11)
bysort idn: egen lpem12 = max(lp12)
bysort idn: egen lpem13 = max(lp13)

gen     lndpcte = lpem09
replace lndpcte = lpem10 if lndpcte == .
replace lndpcte = lpem11 if lndpcte == .
replace lndpcte = lpem12 if lndpcte == .
replace lndpcte = lpem13 if lndpcte == .
replace lndpcte = 1 if lndpcte == .      // F85 will be copied in pre2009 years if no info for 2009ff exists

replace F86 = F85*lndpcte if YEAR<2009   // impute the missing land rent values in years before 2009 by the total rent values (incl rent for buildings) times the farm's most recent available share of land rent in total rent
drop lp* lndpct*
// end of DATA REPAIR: IMPUTE VALUES FOR PRE-2009 YEARS OF f86 
qui do "cmd\\013-asci_Format_short.do"  // codefile containing SHORT label definitions
qui do "cmd\\014-asci_Format_vnamepluslong.do"  // assign definitions of labels consisting of VARNAME PLUS LONG label
qui do "cmd\\012-asci_Format_long.do"  // codefile containing LONG label definitions
compress // change storage type where possible without information loss to reduce file size
save   "dat\\${scriptname}${land}_all", replace  // save all data for all years in one file 


// INDICATE FOR EACH ROUND (YEAR) WHICH VARS ARE PRESENT (after removing variables with strictly constant values)
use "dat\\${scriptname}${land}_tmp", clear  // data set indicating which vars are present in by round (year)
foreach iii in `cons_miss' {
 qui drop if var == "`iii'" // drops variables with constant value throughout
}                  

save                "dat\\${scriptname}${land}_tmp", replace  


// PRINT LOG FILE
// CODEBOOK
capture program drop cleanprint // in case it already exists
program cleanprint   // printing into the log without repeating commands only works if called inside a program


use "dat\\${scriptname}${land}_all", clear 
set linesize 111 // portrait
order _all, alphabetic
label language long  // long or short   (long includes variable names in the label and sometimes adds esplanation)
qui log on
di _char(12) "1) DATA SET DESCRIPTION AND COMPACT CODEBOOK WITH EACH VARIABLE DESCRIBED IN ONE LINE"
describe, short
codebook, compact
di _char(12) "2) A DETAILED CODEBOOK WITH UNIVARIATE STATISTICS FOR EACH VARIABLE"
codebook , tabulate(25)

// VARIABLES INCLUDED BY ROUND
use "dat\\${scriptname}${land}_tmp", clear
sort var
set linesize 150 // landscape

di _char(12) "3) A LIST SHOWING WHICH VARIABLES ARE AVAILABLE FOR EACH ROUND (YEAR)"
list var label y20* , sep(0) noobs
qui log off

end // end program cleanprint 

cleanprint // call program cleanprint

capture erase "dat\\${scriptname}${land}_tmp.dta" // file indicating the availability of variables by year
forvalues j = 2004/2013  {
capture erase "dat\\${scriptname}${land}_`j'.dta" // data file for the particular year
}

