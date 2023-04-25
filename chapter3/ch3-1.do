********************************************************************************
* Code for paper: non-food crops and AS 
* Beadle
* 25.03.2022; updated 07.2022
* Notes:
* 	- Uses the 4-category GRM (asi4)
* 	- Will use 2013 data (cross-sectional)
* 	- Note: LFA variable is important!
*		- A lot of literature suggests using marginal land for NFCs
*		- LFA = less favored area
********************************************************************************

cd C:/asci/git/nfc-asi/stata

********************************************************************************
* importing and merging data
********************************************************************************

import delimited raw/asi-ord4-long.csv, clear 
rename id idn
rename asi asi4
rename year YEAR

merge m:m idn YEAR using dat/000-basic_indicators_papers2-3.dta
keep if _merge == 3
drop _merge 
lab var asi4 "ASI score"

merge m:m idn YEAR using  ///
"C:/asci/git/agricultural_sustainability/stata/dat/100-asi-ord4-panel.dta"
keep if _merge == 3
drop _merge

keep if YEAR == 2013
drop YEAR

********************************************************************************
* generating vars and graphs 
********************************************************************************
*******************************
* cronbach alpha with sum score
*******************************
gen sumscore = profit4 + solvency4 + paid_wage4 + e_diverse4 + prov_employ4  ///
+ pesticide4 + productivity4 + land_quality4 + ghg_emissions4 

alpha sumscore asi4, std
bysort TF8: alpha sumscore asi4, std

***************
* nfc variables
***************
sum SE146, de  // energy crop output
count if SE146 < 0 
drop if SE146 < 0   // dropping observations with negative output

sum SE165, de  // industrial crop output
count if SE165 < 0
drop if SE165 < 0  // same as above

sum SE131, de  // total output

count if SE165==SE146 & SE146 > 0  // checking for double counting

gen ec = SE146/SE131 // ratio of energy crops/total output
replace ec = 1 if ec > 1 // correcting outliers

gen ic = SE165/SE131 // ratio of industrial crops/total output
replace ic = 1 if ic > 1 // correcting outliers

gen nfc = (ec + ic)*100 // var for identifying farms with nfcs; not used in regs

count if ic > 0 & ec > 0  // only 16 obs with both
*browse ec ic nfc if ic > 0 & ec > 0  // only 1 is close to the same proportion

gen energy = 0
replace energy = ec*100 if ec > ic  // grouped by proportion if farm has both
lab var energy "ener"

gen energy2 = energy^2
lab var energy2 "ener^2"

gen denergy = 0 
replace denergy = 1 if energy > 0
lab var denergy "ener(0/1)"

gen industrial = 0
replace industrial = ic*100 if ic > ec // same as above
lab var industrial "ind" 

gen industrial2 = industrial^2
lab var industrial2 "ind^2"

gen dindustrial = 0
replace dindustrial = 1 if industrial > 0
lab var dindustrial "ind(0/1)"

************************
* recoding lfa var
************************
gen lfa = .
replace lfa = 0 if A39 == 1
replace lfa = 1 if A39 != 1
count if lfa == .  // no missing values

*************************
* descriptive stats
*************************
gen non_stat_0 = .
replace non_stat_0 = 0 if nfc == 0 & lfa == 0 // no nfcs and not in lfa
lab var non_stat_0 "No NFCs"
gen non_stat_1 = .
replace non_stat_1 = 0 if nfc == 0 & lfa == 1 // no nfcs and not in lfa
lab var non_stat_1 "No NFCs"

gen ec_stat_0 = energy if energy > 0 & lfa == 0 
lab var ec_stat_0 "Energy crop output"
gen ec_stat_1 = energy if energy > 0 & lfa == 1
lab var ec_stat_1 "Energy crop output"

gen ic_stat_0 = industrial if industrial > 0 & lfa == 0
lab var ic_stat_0 "Industrial crop output"
gen ic_stat_1 = industrial if industrial > 0 & lfa ==1
lab var ic_stat_1 "Industrial crop output"

est clear

estpost tabstat non_stat_0 ec_stat_0 ic_stat_0  ///
non_stat_1 ec_stat_1 ic_stat_1, ///
c(stat) stat(mean sd min max n)

esttab using results/desc_stats.tex, replace  ///
refcat(ec_stat_0 "\emph{Not in LFA}" ec_stat_1  ///
"\vspace{0.1em} \\ \emph{In LFA}", nolabel) ///
cells("mean(fmt(%15.2fc %15.2fc %15.2fc %15.2fc  2)) sd min max count(fmt(0))") ///
nostar unstack nonumber ///
compress nomtitle nonote noobs gap label booktabs f ///
collabels("Mean" "SD" "Min" "Max" "N")

drop *_stat_*

*************************
* re-scaling asi variable
*************************
egen min_asi4 = min(asi4)
egen max_asi4 = max(asi4)
gen asi4_ln = ((asi4 - min_asi4)/(max_asi4 - min_asi4))*100

* visuals
hist asi4_ln, percent xtitle(Re-scaled sustainability index (rASI))  ///
ytitle(Percent of observations (%))
graph export results/asi_hist.pdf, as(pdf) replace
scatter asi4_ln energy, xtitle(Ratio of energy crop output to total output) ///
ytitle(rASI)  // appears roughly linear so can leave as continuous variable

scatter asi4_ln energy, xtitle(Energy crop output to total output (%/%)) ///
ytitle(Re-scaled ASI)  
graph save results/energy_scatter.gph, replace

scatter asi4_ln industrial,   ///
xtitle(Industrial crop output to total output (%/%)) ytitle(Re-scaled ASI) 
graph save results/industrial_scatter.gph, replace

graph combine results/energy_scatter.gph results/industrial_scatter.gph
graph export results/nfc_scatterplots.pdf, as(pdf) replace

*****************************
* saving intermediate files
*****************************
save dat/200-asi-nfc-intermediate.dta, replace // current file 

* file for Christoph
keep idn energy industrial lfa *4
drop TF14 *asi*

save dat/200-forcw.dta, replace  // for Christoph

********************************************************************************
* cross section analysis
********************************************************************************
use dat/200-asi-nfc-intermediate.dta, clear

est clear

* test regression with linear, quadratic, and dummy vars for both nfc types
reg asi4_ln c.energy##c.energy i.denergy c.industrial##c.industrial  ///
i.dindustrial i.TF8 i.A26 if lfa == 0  // quadratic energy is not useful here
est store reg0

***** two regressions, (1) not in lfa and (2) in lfa
***** running regs, checking residual plots, and predicting values
* reg 1
reg asi4_ln energy i.denergy c.industrial##c.industrial  ///
i.dindustrial i.TF8 i.A26 if lfa == 0

rvfplot, yline(0)
test energy 1.denergy industrial 1.dindustrial
est store reg1
predict reg1
margins, at(energy = (0 11.62 50 75) denergy == 1) level(95) ///
saving(dat/margins_ener1, replace)
*marginsplot, recastci(rarea)
*graph save results/ener_margins1.gph, replace
est store ener_margins1
margins, at(industrial = (0 35.89 50 75) dindustrial = 1) level(95)  ///
saving(dat/margins_ind1, replace)
*marginsplot, recastci(rarea)
*graph save results/ind_margins1.gph, replace
est store ind_margins1

* reg 2
reg asi4_ln energy i.denergy c.industrial##c.industrial  ///
i.dindustrial i.TF8 i.A26 if lfa == 1 

rvfplot, yline(0)
test energy 1.denergy industrial 1.dindustrial
est store reg2
predict reg2
margins, at(energy = (0 11.8 50 75) denergy == 1) level(95)  ///
saving(dat/margins_ener2, replace)
*marginsplot, recastci(rarea)
*graph save results/ener_margins2.gph, replace
est store ener_margins2
margins, at(industrial = (0 21.53 50 75) dindustrial == 1) level(95) ///
saving(dat/margins_ind2, replace)
*marginsplot, recastci(rarea)
*graph save results/ind_margins2.gph, replace
est store ind_margins2

**************** tables from regressions
* table for reg 0 (with quadratic energy var)
esttab reg0 using results/cross_section_reg0.tex,  ///
keep(_cons *energy* 1.denergy *industrial* 1.dindustrial) replace ///
b(3) ci(3) label star(* 0.10 ** 0.05 *** 0.01) ///
booktabs alignment(D{.}{.}{-1}) ///
title(Cross-sectional regressions with 2013 data. \label{reg0})  ///
addnotes("Dependent variable: Re-scaled ASI"  ///
"Source: Author's calculations")  

* table for results with confidence intervals, and margins plots
esttab reg1 reg2 using results/cross-section_regs.tex, /// main regressions
keep(_cons energy 1.denergy *industrial* 1.dindustrial) replace ///
b(3) ci(3) label star(* 0.10 ** 0.05 *** 0.01) ///
booktabs alignment(D{.}{.}{-1}) ///
title(Cross-sectional regressions with 2013 data. \label{reg2})  ///
addnotes("Dependent variable: Re-scaled ASI"  ///
"Source: Author's calculations")  ///
mtitles ("Not in LFA" "In LFA") 
asd
******************* figures and tables for predicted margins
* energy crops
use dat/margins_ener2, clear  
keep _at _margin _ci_lb _ci_ub _at1
rename _margin lfa1_margin
rename _ci_* lfa1_ci_*
rename _at1 lfa1_at1
save dat/margins_ener2, replace

use dat/margins_ener1.dta, clear
keep _at _margin _ci_lb _ci_ub _at1
rename _margin lfa0_margin
rename _ci_* lfa0_ci_*
rename _at1 lfa0_at1

merge 1:1 _at using dat/margins_ener2.dta
keep if _merge == 3
drop _merge

twoway (rarea lfa0_ci_lb lfa0_ci_ub lfa0_at1, xline(11.62, lpattern(dash)) /// 
xline(11.8, lpattern(solid)) color(gs12%30))  ///
(rarea lfa1_ci_lb lfa1_ci_ub lfa0_at1, color(gs12%30))  ///
(line lfa0_margin lfa0_at1, lcolor(black) lpattern(dash)) ///
(line lfa1_margin lfa1_at1, lcolor(black)  ///
leg(off)  ///
xtitle("Proportion of energy crop output to total output")  ///
ytitle("Predicted ASI score"))  
graph save results/margins1.gph, replace
graph export results/margins1.pdf, as(pdf) replace

* industrial crops
use dat/margins_ind2, clear  
keep _at _margin _ci_lb _ci_ub _at3
rename _margin lfa1_margin
rename _ci_* lfa1_ci_*
rename _at3 lfa1_at3
save dat/margins_ind2, replace

use dat/margins_ind1.dta, clear
keep _at _margin _ci_lb _ci_ub _at3
rename _margin lfa0_margin
rename _ci_* lfa0_ci_*
rename _at3 lfa0_at3

merge 1:1 _at using dat/margins_ind2.dta
keep if _merge == 3
drop _merge

twoway (rarea lfa0_ci_lb lfa0_ci_ub lfa0_at3, xline(21.53, lpattern(solid)) ///
xline(35.89, lpattern(dash)) color(gs12%30))  ///
(rarea lfa1_ci_lb lfa1_ci_ub lfa0_at3, color(gs12%30))  ///
(line lfa0_margin lfa0_at3, lcolor(black) lpattern(dash)) ///
(line lfa1_margin lfa1_at3, lcolor(black)  ///
leg(off)  ///
xtitle("Proportion of industrial crop output to total output")  ///
ytitle("Predicted ASI score"))  
graph save results/margins2.gph, replace
graph export results/margins2.pdf, as(pdf) replace

graph combine results/margins1.gph results/margins2.gph
graph export results/margins_combined.pdf, as(pdf) replace

* testing if coefficients are different across regressions 
suest reg1 reg2
test [reg1_mean = reg2_mean] 
est store suest 

