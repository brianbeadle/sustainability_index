********************************************************************************
* Code for final stats and graphs for ASI
* Beadle
* 10.01.23
* Tasks:
* 	- create shapefiles
* 	- merge ci results with IRM output
* 	- compare the models with correlation coefficient
* 	- create maps with shapefiles
********************************************************************************

* making shapefiles  // install these for running the shapefiles
*ssc install "shp2dta"
*ssc install "spmap"
*ssc install "mif2dta"

*cd C:/Users/Beadle/Documents/GitHub/agricultural_sustainability/stata  // office
cd C:/asci/git/agricultural_sustainability/stata  // laptop

* importing csv files of ordinal results
import delimited results/asi-scale-linking-master.csv, clear
rename id idn
rename asi asi4
lab var asi4 "4-category GRM"
save dat/asi-ord4-cs.dta, replace

use dat/100-asi-ci_scores-panel, clear  // this file has explanatory variables

merge 1:1 idn YEAR using dat/100-asi-ord4-panel.dta // ordinal items
keep if _merge == 3
drop _merge 

drop if YEAR < 2013
drop YEAR

lab var profit4 "Profitability"
lab var solvency4 "Solvency"
lab var paid_wage4 "Wage ratio"
lab var e_diverse4 "Economic Diversity"
lab var prov_employ4 "Provision of employment"
lab var pesticide4 "Expenditure on pesticides"
lab var productivity4 "Multi-factor productivity"
lab var land_quality4 "Land ecosystem quality"
lab var ghg_emissions4 "GHG emissions"

* merging asi4 and composite indicator scores
merge 1:1 idn using dat/asi-ord4-cs.dta
keep if _merge == 3
drop _merge

save dat/199-asi-final-analysis.dta, replace

*************************************************************************
* visuals and desc stats
*************************************************************************

use dat/199-asi-final-analysis, clear

* histograms for relative frequencies in each item
foreach var of varlist profit4 solvency4 paid_wage4 e_diverse4 prov_employ4 ///
pesticide4 productivity4 land_quality4 ghg_emissions4 {
hist `var', frequency barwidth(.5) fc(black) lc(black) ///
ytitle("Frequency") ylabel(0(1000)8000) xlab(0 "1" 1 "2" 2 "3" 3 "4")
graph save results/hist-`var'.gph, replace
}

graph combine results/hist-profit4.gph results/hist-solvency4.gph  ///
	results/hist-paid_wage4.gph results/hist-e_diverse4.gph  ///
	results/hist-prov_employ4.gph results/hist-pesticide4.gph  ///
	results/hist-ghg_emissions4.gph results/hist-productivity4.gph  ///
	results/hist-land_quality4.gph, col(3) ysize(11) xsize(8)
graph export results/item-frequencies.pdf, as(pdf) replace 

* distribution
summarize asi4 
local m=r(mean) 
local sd=r(sd) 
local low = `m'-`sd' 
local high=`m'+`sd' 

twoway histogram asi4, ///
fc(none) lc(blue) xline(`m', lc(red)) ///
xline(`low', lc(red)) xline(`high', lc(red)) scale(0.5) ///
percent xtitle("AS score ({&theta})") ytitle("Percent of farms") /// 
xlabel(-1.4(0.2)1.4) ylabel(0(1)9)
graph export results/distribution_2013.pdf, as(pdf) replace

* averages by farm type and size
est clear
estpost tabstat asi4, by(TF8) ///
stat(mean sd n) c(stat) nototal
eststo

esttab using results/descstats_tf8-table.tex, replace ////
cells("mean(fmt(%6.3fc)) sd(fmt(%6.3fc)) count(fmt(%2.0f))") nonumber ///
nomtitle nonote noobs label booktabs ///
collabels("Mean" "SD" "Obs")

lab define sizecat 6 "25,000 - <50,000" 7 "50,000 - <100,000"  ///
	8 "100,000 - <250,000" 9 "250,000 - <500,000" 10 "500,000 - <750,000"  ///
	11 "750,000 - <1,000,000" 12 "1,000,000 - 1,500,000"  ///
	13 "1,500,000 - 3,000,000" 14 ">= 3,000,000"
lab value A26 sizecat

est clear
estpost tabstat asi4, by(A26) ///
stat(mean sd n) c(stat) nototal
eststo

esttab using results/descstats_a26-table.tex, replace ////
cells("mean(fmt(%6.3fc)) sd(fmt(%6.3fc)) count(fmt(%2.0f))") nonumber ///
nomtitle nonote noobs label booktabs ///
collabels("Mean" "SD" "Obs")

*************************************************************************
*results from item deletion experiments
*************************************************************************
cd C:/asci/git/agricultural_sustainability

*** import files, renaming variables, saving as .dat files
import delimited results/94-asi-missing-1-10.csv, clear
rename asi asi4_110
lab var asi4_110 "1 item missing in 10% of sample"
rename id idn
save stata/dat/94-asi-missing-1-10.dat, replace

import delimited results/95-asi-missing-1-30.csv, clear
rename asi asi4_130
lab var asi4_130 "1 item missing in 30% of sample"
rename id idn
save stata/dat/95-asi-missing-1-30.dat, replace

import delimited results/96-asi-missing-1-50.csv, clear
rename asi asi4_150
lab var asi4_150 "1 item missing in 50% of sample"
rename id idn
save stata/dat/96-asi-missing-1-50.dat, replace

import delimited results/97-asi-missing-2-10.csv, clear
rename asi asi4_210
lab var asi4_210 "2 items missing in 10% of sample"
rename id idn
save stata/dat/97-asi-missing-2-10.dat, replace

import delimited results/98-asi-missing-2-30.csv, clear
rename asi asi4_230
lab var asi4_230 "2 items missing in 30% of sample"
rename id idn
save stata/dat/98-asi-missing-2-30.dat, replace

import delimited results/99-asi-missing-2-50.csv, clear
rename asi asi4_250
lab var asi4_250 "2 items missing in 50% of sample"
rename id idn
save stata/dat/99-asi-missing-2-50.dat, replace

import delimited results/100-asi-missing-3-10.csv, clear
rename asi asi4_310
lab var asi4_310 "3 items missing in 10% of sample"
rename id idn
save stata/dat/100-asi-missing-3-10.dat, replace

import delimited results/101-asi-missing-3-30.csv, clear
rename asi asi4_330
lab var asi4_330 "3 items missing in 30% of sample"
rename id idn
save stata/dat/101-asi-missing-3-30.dat, replace

import delimited results/102-asi-missing-3-50.csv, clear
rename asi asi4_350
lab var asi4_350 "3 items missing in 50% of sample"
rename id idn
save stata/dat/102-asi-missing-3-50.dat, replace

*** merging all results
use stata/dat/199-asi-final-analysis, clear

merge 1:1 idn using stata/dat/94-asi-missing-1-10.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/95-asi-missing-1-30.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/96-asi-missing-1-50.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/97-asi-missing-2-10.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/98-asi-missing-2-30.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/99-asi-missing-2-50.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/100-asi-missing-3-10.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/101-asi-missing-3-30.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/102-asi-missing-3-50.dat
keep if _merge == 3
drop _merge

*** correlations: will create a table manually in the tex doc
foreach var of varlist asi4_* {
cor asi4 `var'
}

*** scatter plots
foreach var of varlist asi4_* {
graph twoway (lfit asi4 `var') (scatter asi4 `var', mcolor(black) leg(off) ///
ytitle("Control group") msize(small)) 
graph save stata/results/missing-`var'.gph, replace
}

graph combine stata/results/missing-asi4_110.gph ///
	stata/results/missing-asi4_130.gph stata/results/missing-asi4_150.gph ///
	stata/results/missing-asi4_210.gph, col(2) ysize(6) xsize(6)
graph export stata/results/missing-combine.pdf, as(pdf) replace

graph combine stata/results/missing-asi4_230.gph ///
	stata/results/missing-asi4_250.gph stata/results/missing-asi4_310.gph ///
	stata/results/missing-asi4_330.gph stata/results/missing-asi4_350.gph, ///
	col(2) xsize(6) ysize(9)
graph export stata/results/missing-combine2.pdf, as(pdf) replace
	
************************************************************************
* results for scale linking simulation
************************************************************************

*** importing files, renaming variables, saving at .dat files

import delimited results/30-scale-linking/31-corr/east-1-west-2.csv, clear 
rename asi asi4_12
lab var asi4_12 "Missing items 1 & 2"
rename id idn
save stata/dat/105-scale-linking-1-2.dat, replace

import delimited results/30-scale-linking/31-corr/east-1-west-3.csv, clear 
rename asi asi4_13
lab var asi4_13 "Missing items 1 & 3"
rename id idn
save stata/dat/106-scale-linking-1-3.dat, replace

import delimited results/30-scale-linking/31-corr/east-1-west-4.csv, clear 
rename asi asi4_14
lab var asi4_14 "Missing items 1 & 4"
rename id idn
save stata/dat/107-scale-linking-1-4.dat, replace

import delimited results/30-scale-linking/31-corr/east-1-west-5.csv, clear 
rename asi asi4_15
lab var asi4_15 "Missing items 1 & 5"
rename id idn
save stata/dat/108-scale-linking-1-5.dat, replace

import delimited results/30-scale-linking/31-corr/east-1-west-6.csv, clear 
rename asi asi4_16
lab var asi4_16 "Missing items 1 & 6"
rename id idn
save stata/dat/109-scale-linking-1-6.dat, replace

import delimited results/30-scale-linking/31-corr/east-1-west-7.csv, clear 
rename asi asi4_17
lab var asi4_17 "Missing items 1 & 7"
rename id idn
save stata/dat/110-scale-linking-1-7.dat, replace

import delimited results/30-scale-linking/31-corr/east-1-west-8.csv, clear 
rename asi asi4_18
lab var asi4_18 "Missing items 1 & 8"
rename id idn
save stata/dat/111-scale-linking-1-8.dat, replace

import delimited results/30-scale-linking/31-corr/east-1-west-9.csv, clear 
rename asi asi4_19
lab var asi4_19 "Missing items 1 & 9"
rename id idn
save stata/dat/112-scale-linking-1-9.dat, replace

import delimited results/30-scale-linking/31-corr/east-2-west-3.csv, clear 
rename asi asi4_23
lab var asi4_23 "Missing items 2 & 3"
rename id idn
save stata/dat/113-scale-linking-2-3.dat, replace

import delimited results/30-scale-linking/31-corr/east-2-west-4.csv, clear 
rename asi asi4_24
lab var asi4_24 "Missing items 2 & 4"
rename id idn
save stata/dat/114-scale-linking-2-4.dat, replace

import delimited results/30-scale-linking/31-corr/east-2-west-5.csv, clear 
rename asi asi4_25
lab var asi4_25 "Missing items 2 & 5"
rename id idn
save stata/dat/115-scale-linking-2-5.dat, replace

import delimited results/30-scale-linking/31-corr/east-2-west-6.csv, clear 
rename asi asi4_26
lab var asi4_26 "Missing items 2 & 6"
rename id idn
save stata/dat/116-scale-linking-2-6.dat, replace

import delimited results/30-scale-linking/31-corr/east-2-west-7.csv, clear 
rename asi asi4_27
lab var asi4_27 "Missing items 2 & 7"
rename id idn
save stata/dat/117-scale-linking-2-7.dat, replace

import delimited results/30-scale-linking/31-corr/east-2-west-8.csv, clear 
rename asi asi4_28
lab var asi4_28 "Missing items 2 & 8"
rename id idn
save stata/dat/118-scale-linking-2-8.dat, replace

import delimited results/30-scale-linking/31-corr/east-2-west-9.csv, clear 
rename asi asi4_29
lab var asi4_29 "Missing items 2 & 9"
rename id idn
save stata/dat/119-scale-linking-2-9.dat, replace

import delimited results/30-scale-linking/31-corr/east-3-west-4.csv, clear 
rename asi asi4_34
lab var asi4_34 "Missing items 3 & 4"
rename id idn
save stata/dat/120-scale-linking-3-4.dat, replace

import delimited results/30-scale-linking/31-corr/east-3-west-5.csv, clear
rename asi asi4_35
lab var asi4_35 "Missing items 3 & 5"
rename id idn
save stata/dat/121-scale-linking-3-5.dat, replace

import delimited results/30-scale-linking/31-corr/east-3-west-6.csv, clear
rename asi asi4_36
lab var asi4_36 "Missing items 3 & 6"
rename id idn
save stata/dat/122-scale-linking-3-6.dat, replace

import delimited results/30-scale-linking/31-corr/east-3-west-7.csv, clear 
rename asi asi4_37
lab var asi4_37 "Missing items 3 & 7"
rename id idn
save stata/dat/123-scale-linking-3-7.dat, replace

import delimited results/30-scale-linking/31-corr/east-3-west-8.csv, clear
rename asi asi4_38
lab var asi4_38 "Missing items 3 & 8"
rename id idn
save stata/dat/124-scale-linking-3-8.dat, replace

import delimited results/30-scale-linking/31-corr/east-3-west-9.csv, clear
rename asi asi4_39
lab var asi4_39 "Missing items 3 & 9"
rename id idn
save stata/dat/125-scale-linking-3-9.dat, replace

import delimited results/30-scale-linking/31-corr/east-4-west-5.csv, clear
rename asi asi4_45
lab var asi4_45 "Missing items 4 & 5"
rename id idn
save stata/dat/126-scale-linking-4-5.dat, replace

import delimited results/30-scale-linking/31-corr/east-4-west-6.csv, clear
rename asi asi4_46
lab var asi4_46 "Missing items 4 & 6"
rename id idn
save stata/dat/127-scale-linking-4-6.dat, replace

import delimited results/30-scale-linking/31-corr/east-4-west-7.csv, clear
rename asi asi4_47
lab var asi4_47 "Missing items 4 & 7"
rename id idn
save stata/dat/128-scale-linking-4-7.dat, replace

import delimited results/30-scale-linking/31-corr/east-4-west-8.csv, clear
rename asi asi4_48
lab var asi4_48 "Missing items 4 & 8"
rename id idn
save stata/dat/129-scale-linking-4-8.dat, replace

import delimited results/30-scale-linking/31-corr/east-4-west-9.csv, clear
rename asi asi4_49
lab var asi4_49 "Missing items 4 & 9"
rename id idn
save stata/dat/130-scale-linking-4-9.dat, replace

import delimited results/30-scale-linking/31-corr/east-5-west-6.csv, clear
rename asi asi4_56
lab var asi4_56 "Missing items 5 & 6"
rename id idn
save stata/dat/131-scale-linking-5-6.dat, replace

import delimited results/30-scale-linking/31-corr/east-5-west-7.csv, clear
rename asi asi4_57
lab var asi4_57 "Missing items 5 & 7"
rename id idn
save stata/dat/132-scale-linking-5-7.dat, replace

import delimited results/30-scale-linking/31-corr/east-5-west-8.csv, clear
rename asi asi4_58
lab var asi4_58 "Missing items 5 & 8"
rename id idn
save stata/dat/133-scale-linking-5-8.dat, replace

import delimited results/30-scale-linking/31-corr/east-5-west-9.csv, clear
rename asi asi4_59
lab var asi4_59 "Missing items 5 & 9"
rename id idn
save stata/dat/134-scale-linking-5-9.dat, replace

import delimited results/30-scale-linking/31-corr/east-6-west-7.csv, clear
rename asi asi4_67
lab var asi4_67 "Missing items 6 & 7"
rename id idn
save stata/dat/135-scale-linking-6-7.dat, replace

import delimited results/30-scale-linking/31-corr/east-6-west-8.csv, clear
rename asi asi4_68
lab var asi4_68 "Missing items 6 & 8"
rename id idn
save stata/dat/136-scale-linking-6-8.dat, replace

import delimited results/30-scale-linking/31-corr/east-6-west-9.csv, clear
rename asi asi4_69
lab var asi4_69 "Missing items 6 & 9"
rename id idn
save stata/dat/137-scale-linking-6-9.dat, replace

import delimited results/30-scale-linking/31-corr/east-7-west-8.csv, clear
rename asi asi4_78
lab var asi4_78 "Missing items 7 & 8"
rename id idn
save stata/dat/138-scale-linking-7-8.dat, replace

import delimited results/30-scale-linking/31-corr/east-7-west-9.csv, clear
rename asi asi4_79
lab var asi4_79 "Missing items 7 & 9"
rename id idn
save stata/dat/139-scale-linking-7-9.dat, replace

import delimited results/30-scale-linking/31-corr/east-8-west-9.csv, clear
rename asi asi4_89
lab var asi4_89 "Missing items 8 & 9"
rename id idn
save stata/dat/140-scale-linking-8-9.dat, replace

***********************
*** merging all results
***********************
use stata/dat/199-asi-final-analysis, clear

merge 1:1 idn using stata/dat/105-scale-linking-1-2.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/106-scale-linking-1-3.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/107-scale-linking-1-4.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/108-scale-linking-1-5.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/109-scale-linking-1-6.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/110-scale-linking-1-7.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/111-scale-linking-1-8.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/112-scale-linking-1-9.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/113-scale-linking-2-3.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/114-scale-linking-2-4.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/115-scale-linking-2-5.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/116-scale-linking-2-6.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/117-scale-linking-2-7.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/118-scale-linking-2-8.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/119-scale-linking-2-9.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/120-scale-linking-3-4.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/121-scale-linking-3-5.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/122-scale-linking-3-6.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/123-scale-linking-3-7.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/124-scale-linking-3-8.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/125-scale-linking-3-9.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/126-scale-linking-4-5.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/127-scale-linking-4-6.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/128-scale-linking-4-7.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/129-scale-linking-4-8.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/130-scale-linking-4-9.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/131-scale-linking-5-6.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/132-scale-linking-5-7.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/133-scale-linking-5-8.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/134-scale-linking-5-9.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/135-scale-linking-6-7.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/136-scale-linking-6-8.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/137-scale-linking-6-9.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/138-scale-linking-7-8.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/139-scale-linking-7-9.dat
keep if _merge == 3
drop _merge

merge 1:1 idn using stata/dat/140-scale-linking-8-9.dat
keep if _merge == 3
drop _merge

*** correlations: will create a table manually in the tex doc
foreach var of varlist asi4_* {
cor asi4 `var'
}

* creating groups so scatter plots can have diff color markers
gen group = 1
replace group = 2 if NUTS2 == "DE80" | NUTS2 == "DE30" ///
	| NUTS2 == "DE40" | NUTS2 == "DEE0" | NUTS2 == "DED2" ///
	| NUTS2 == "DED3" | NUTS2 == "DED5" | NUTS2 == "DEG0"

* scatter plots
foreach var of varlist asi4_* {
twoway (lfit asi4 `var') ///
		(scatter asi4 `var' if group == 1, msize(small) mcolor(blue)) ///
		(scatter asi4 `var' if group == 2, msize(small) mcolor(yellow)), ///
		ytitle("Control group") legend(label(1 "Fit line") ///
		label(2 "West") label(3 "East"))
		graph save stata/results/linking-`var'.gph, replace
}

grc1leg stata/results/linking-asi4_12.gph ///
	stata/results/linking-asi4_13.gph stata/results/linking-asi4_14.gph ///
	stata/results/linking-asi4_15.gph, /// 
	legendfrom(stata/results/linking-asi4_12.gph) ///
	position(9) col(2) ysize(11) xsize(8) title("Scale linking simulations")
graph export stata/results/linking16.pdf, as(pdf) replace

grc1leg stata/results/linking-asi4_16.gph ///
	stata/results/linking-asi4_17.gph stata/results/linking-asi4_18.gph ///
	stata/results/linking-asi4_19.gph, /// 
	legendfrom(stata/results/linking-asi4_16.gph) ///
	position(9) col(2) ysize(11) xsize(8) title("Scale linking simulations")
graph export stata/results/linking26.pdf, as(pdf) replace

grc1leg stata/results/linking-asi4_23.gph ///
	stata/results/linking-asi4_24.gph stata/results/linking-asi4_25.gph ///
	stata/results/linking-asi4_26.gph, /// 
	legendfrom(stata/results/linking-asi4_23.gph) ///
	position(9) col(2) ysize(11) xsize(8) title("Scale linking simulations")
graph export stata/results/linking36.pdf, as(pdf) replace

grc1leg stata/results/linking-asi4_27.gph ///
	stata/results/linking-asi4_28.gph stata/results/linking-asi4_29.gph ///
	stata/results/linking-asi4_34.gph, /// 
	legendfrom(stata/results/linking-asi4_27.gph) ///
	position(9) col(2) ysize(11) xsize(8) title("Scale linking simulations")
graph export stata/results/linking46.pdf, as(pdf) replace

grc1leg stata/results/linking-asi4_35.gph ///
	stata/results/linking-asi4_36.gph stata/results/linking-asi4_37.gph ///
	stata/results/linking-asi4_38.gph, /// 
	legendfrom(stata/results/linking-asi4_38.gph) ///
	position(9) col(2) ysize(11) xsize(8) title("Scale linking simulations")
graph export stata/results/linking56.pdf, as(pdf) replace

grc1leg stata/results/linking-asi4_39.gph ///
	stata/results/linking-asi4_45.gph stata/results/linking-asi4_46.gph ///
	stata/results/linking-asi4_47.gph, /// 
	legendfrom(stata/results/linking-asi4_47.gph) ///
	position(9) col(2) ysize(11) xsize(8) title("Scale linking simulations")
graph export stata/results/linking66.pdf, as(pdf) replace

grc1leg stata/results/linking-asi4_48.gph ///
	stata/results/linking-asi4_49.gph stata/results/linking-asi4_56.gph ///
	stata/results/linking-asi4_57.gph, /// 
	legendfrom(stata/results/linking-asi4_57.gph) ///
	position(9) col(2) ysize(11) xsize(8) title("Scale linking simulations")
graph export stata/results/linking76.pdf, as(pdf) replace

grc1leg stata/results/linking-asi4_58.gph ///
	stata/results/linking-asi4_59.gph stata/results/linking-asi4_67.gph ///
	stata/results/linking-asi4_68.gph, /// 
	legendfrom(stata/results/linking-asi4_68.gph) ///
	position(9) col(2) ysize(11) xsize(8) title("Scale linking simulations")
graph export stata/results/linking86.pdf, as(pdf) replace

grc1leg stata/results/linking-asi4_69.gph ///
	stata/results/linking-asi4_78.gph stata/results/linking-asi4_79.gph ///
	stata/results/linking-asi4_89.gph, /// 
	legendfrom(stata/results/linking-asi4_89.gph) ///
	position(9) col(2) ysize(11) xsize(8) title("Scale linking simulations")
graph export stata/results/linking96.pdf, as(pdf) replace

*************************************
* nuts 2 maps and scale linking tests
*************************************
cd C:/asci/git/agricultural_sustainability/stata  // laptop

*** import csv files
import delimited raw/scale-linking-nuts2.csv, clear
tab nuts2
tab v7
rename nuts2 NUTS2
rename v7 missing
rename asi4_sln2 prob4_linking
drop junk
save dat/scale-linking-nuts2.dta, replace

import delimited raw/predprob-nuts2.csv, clear 
rename nuts2 NUTS2
drop v1
save dat/predprob-nuts2.dta, replace

*****************************************************************
* DO NOT REINSTATE THIS CODE UNLESS NECESSARY
* the maps do not always load correctly
*****************************************************************
*use shp/nuts2/germany, clear
*rename NUTS_CODE NUTS2
*sort NUTS2
*qui by NUTS2:  gen dup = cond(_N==1,0,_n)
*tab dup
*drop if dup == 2
*drop dup
*save shp/nuts2/germany2.dta, replace

*shp2dta using shp/nuts2/nuts2.shp, database(shp/nuts2/germany) ///
*coordinates(shp/nuts2/n2coord) genid(N2) replace
*****************************************************************

use dat/predprob-nuts2.dta, clear

merge 1:1 NUTS2 using shp/nuts2/germany2.dta
keep if _merge==3
drop _merge

*** generating maps for main pred probs
colorpalette viridis, n(20) ipolate(20, HCL power(1.5)) nograph reverse 
local colors `r(p)'

spmap prob4 using shp/nuts2/n2coord, clmethod(custom) ///
id(N2) fcolor("`colors'") clbreaks(0.05 (0.01) 0.25)  ///
ocolor(gs6 ..) osize(0.03 ..) ///
ndfcolor(gs14) ndocolor(gs6 ..) ndsize(0.01 ..)
graph save results/prob4_nuts2-CS, replace
graph export results/prob4-nuts2-CS.pdf, as(pdf) replace 

*** working with scale linking file
merge 1:m NUTS2 using dat/scale-linking-nuts2.dta
keep if _merge == 3
drop _merge

* creating loop for scale linking maps
levelsof missing, local(levels) 
foreach level of local levels {
	colorpalette viridis, n(20) ipolate(20, HCL power(1.5)) nograph reverse 
	local colors `r(p)'

	spmap prob4_linking using shp/nuts2/n2coord if missing == `level', /// 
	clmethod(custom) ///
	id(N2) fcolor("`colors'") clbreaks(0.05 (0.01) 0.25)  ///
	ocolor(gs6 ..) osize(0.03 ..) ///
	ndfcolor(gs14) ndocolor(gs6 ..) ndsize(0.01 ..) title(`level')
	graph save results/prob4_linking-`level', replace 
}

grc1leg results/prob4_linking-12.gph results/prob4_linking-13.gph ///
	results/prob4_linking-14.gph results/prob4_linking-15.gph ///
	results/prob4_linking-16.gph results/prob4_linking-17.gph, ///
	legendfrom(results/prob4_linking-12.gph) position(9) col(3)
graph export results/prob_linking-combine1.pdf, as(pdf) replace

grc1leg results/prob4_linking-18.gph results/prob4_linking-19.gph ///
	results/prob4_linking-23.gph results/prob4_linking-24.gph ///
	results/prob4_linking-25.gph results/prob4_linking-26.gph, ///
	legendfrom(results/prob4_linking-18.gph) position(9) col(3)
graph export results/prob_linking-combine2.pdf, as(pdf) replace

grc1leg results/prob4_linking-27.gph results/prob4_linking-28.gph ///
	results/prob4_linking-29.gph results/prob4_linking-34.gph ///
	results/prob4_linking-35.gph results/prob4_linking-36.gph, ///
	legendfrom(results/prob4_linking-27.gph) position(9) col(3)
graph export results/prob_linking-combine3.pdf, as(pdf) replace

grc1leg results/prob4_linking-37.gph results/prob4_linking-38.gph ///
	results/prob4_linking-39.gph results/prob4_linking-45.gph ///
	results/prob4_linking-46.gph results/prob4_linking-47.gph, ///
	legendfrom(results/prob4_linking-37.gph) position(9) col(3)
graph export results/prob_linking-combine4.pdf, as(pdf) replace

grc1leg results/prob4_linking-48.gph results/prob4_linking-49.gph ///
	results/prob4_linking-56.gph results/prob4_linking-57.gph ///
	results/prob4_linking-58.gph results/prob4_linking-59.gph, ///
	legendfrom(results/prob4_linking-48.gph) position(9) col(3)
graph export results/prob_linking-combine5.pdf, as(pdf) replace

grc1leg results/prob4_linking-67.gph results/prob4_linking-68.gph ///
	results/prob4_linking-69.gph results/prob4_linking-78.gph ///
	results/prob4_linking-79.gph results/prob4_linking-89.gph, ///
	legendfrom(results/prob4_linking-67.gph) position(9) col(3)
graph export results/prob_linking-combine6.pdf, as(pdf) replace

sdfg
gen prob_diff = 0
replace prob_diff = 1 if prob4_linking < prob95_l | prob4_linking > prob95_u

count if prob_diff == 1

sort missing NUTS2 

browse NUTS2 missing prob* if prob_diff == 1

*sort NUTS2
*browse

*gen prob_diff = prob4 - prob4_linking 

*sum prob4, de
*sum prob_diff, de
*hist prob_diff

*tabstat prob_diff, by(NUTS2) c(stat) stat(min max mean sd n) 
*tabstat prob_diff, by(missing) c(stat) stat(min max mean sd n)

*graph hbox prob_diff, over(NUTS2)

*** from here: look at differences (prob_diff) by each region




* this section saves the main pred probs as a tex file
*ssc install texsave
drop NUTS2 GF NUTS_LEVEL N2
order NUTS_NAME prob4 se4 p4 v5
rename NUTS_NAME Region
gen Est = round(prob4,0.0001)
gen Error = round(se4,0.0001)
gen Q10 = round(p4,0.0001)
gen Q90 = round(v5,0.0001)
drop prob4 se4 p4 v5
texsave using results/prob4-nuts2-CS.tex, frag replace