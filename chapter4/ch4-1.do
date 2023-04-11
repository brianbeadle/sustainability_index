* recode this to measure from the first point of transitioning (A32==3)

* Brian's directories
*cd C:/asci/git/paper3-organic_farming/stata  // laptop
cd C:/Users/Beadle/Documents/GitHub/paper3-organic_farming/stata  // office

********************************************************************************
* importing and merging data
********************************************************************************
/*
import delimited raw/asi-ord4-long.csv, clear 
rename id idn
rename asi zasi4
lab var zasi4 "ASI score"
rename year YEAR

merge m:m idn YEAR using dat/000-basic_indicators_papers2-3.dta
keep if _merge == 3
drop _merge 

save dat/unnecessary_intermediate.dta, replace // stata in my office is a bummer
*/

*****************************
* defining the organic groups
*****************************
use dat/unnecessary_intermediate.dta, clear
*keep idn YEAR zasi4 TF8 A26 A32 // getting rid of all unnecessary vars

* generating new vars
egen id_count = count(idn), by(idn) // min obs per farm
drop if id_count < 5  // *CHANGE and rerun to adjust sample requirements
*browse YEAR idn id_count
drop id_count

* standardizing theta
capture drop zasi4
egen zasi4 = std(asi4)
lab var zasi4 "{&theta}{&prime}"

bysort idn (YEAR): gen year = _n  // generic year var to remove gaps
gen org1 = .                  // just to reorder organic var
replace org1 = 1 if A32 == 1  // conventional
replace org1 = 2 if A32 == 3  // partial/transitioning
replace org1 = 3 if A32 == 2  // fully organic

*** defining time series organic classifications
by idn: egen min_org1 = min(org1) // minimum org value per farm
by idn: egen max_org1 = max(org1) // maximum org value per farm

gen all_conv = 1 if max_org1 == 1 | max_org1 == 2 // farm is never full org
gen all_org = 1 if min_org1 == 2 | min_org1 == 3 // farm is never full conv
gen switch = 1 if min_org1 == 1 & max_org1 == 3 // farm has all 3 classes

lab var all_conv "AC"
lab var all_org "AO"
lab var switch "Starter"

* checking the groupings
count if all_conv == . & all_org == . & switch == .  // checking for missing
egen check = rowtotal(all_* switch) 
tab check // 10 obs in more than 1 group 
list if check == 2  // 2 farms are always partial 
replace all_org = 1 if idn == 5747  // changing them to all_org
replace all_conv = 0 if idn == 5747
replace all_org = 1 if idn == 9234
replace all_conv = 0 if idn == 9234

foreach var of varlist all_org all_conv switch {
replace `var' = 0 if `var' == .  // making all missing vars = 0
}

drop min_org1 max_org1 check 

****************************************************************
* identifying time trends and treatment time in the switch group 
****************************************************************
sort idn year
tsset idn year 

* identifying treatment times (t=0)
bysort idn (year): gen time = cond((org1 == 2 & L1.org1 == 1), ///
year, .) if switch == 1 // first year farm is partial after conv
replace time = YEAR if time != .
tab time  // we now have 51 farms with a full correct transition
bysort idn (year): egen treat = min(time)  // expands t=0 to all obs/farm
replace treat = 0 if treat == .  // so there are no missing obs

* ALL REMAINING OBS ARE EITHER QUITTERS OR W/O A TRANSITION, SO DROPPING
drop if switch == 1 & treat == 0
distinct idn  				  // 64102 obs from 8170 farms
distinct idn if switch == 1   // 429 obs from 49 farms with a treatment

* counter for time periods pre and post treatment
gen prepost = .  // 
bysort idn (year): replace prepost = -1 if time == . & F1.time != .
forvalues i = 1/10 {
	bysort idn (year): replace prepost = (F1.prepost - 1) if ///
	time == . & F1.prepost < 0
}
replace prepost = 0 if L1.prepost == -1
replace prepost = 1 if L1.prepost == 0
forvalues i = 1/10 {
	bysort idn (year): replace prepost = (L1.prepost + 1) if ///
	prepost == . & L1.prepost > 0
}

* categorical variable for the org groups, with diff for pre/post switch
gen switch2 = .
replace switch2 = 0 if switch ==1 & prepost < 0
replace switch2 = 1 if switch ==1 & prepost > 0

gen org = .
replace org = 1 if all_conv == 1
replace org = 2 if switch == 1 & switch2 == 0 
replace org = 3 if switch2 == 1 
replace org = 4 if all_org == 1

lab define orgcat 1 "AC" 2 "pre-S" 3 "post-S" 4 "AO" 
lab value org orgcat

*************************************************
* preliminary analysis
* testing org/conv on individual continuous vars
*************************************************

* checking for changes in the control variables for the switch group
sort idn YEAR
by idn (TF8), sort: gen changed1 = (TF8[1] != TF8[_N])
by idn (A26), sort: gen changed2 = (A26[1] != A26[_N])

sort idn YEAR
list idn YEAR org TF8 A26 changed* ///
if switch == 1 & (changed1 == 1 | changed2 == 1)

distinct idn if switch == 1 & changed1 == 1

ttest A26 if switch == 1, by(switch2)

xtreg A26 i.switch2, fe

* labeling continuous vars
lab var profit "Prof"
lab var solvency "Solv"
lab var e_diverse "ED"
lab var pesticide "EP"
lab var ghg_emissions "GHG"
lab var land_quality "LEQ"
lab var paid_wage "WR"
lab var prov_employ "PE"
lab var productivity "MFP"

lab define sizecat 6 "25,000 - <50,000" 7 "50,000 - <100,000"  ///
	8 "100,000 - <250,000" 9 "250,000 - <500,000" 10 "500,000 - <750,000"  ///
	11 "750,000 - <1,000,000" 12 "1,000,000 - <1,500,000"  ///
	13 "1,500,000 - <3,000,000" 14 ">= 3,000,000"
lab value A26 sizecat

*ssc install corrtex

*est clear

*local vars profit solvency e_diverse pesticide ghg_emissions ///
*land_quality paid_wage prov_employ productivity

*corrtex `vars', file(results/corr_vars) replace longtable 

*foreach var of varlist `vars' {
*	tabstat `var', c(stat) stat(mean sd)
*}

*foreach var of varlist `vars' {
*	xtreg `var' i.org i.TF8 i.A26, vce(robust)
*	est store `var'
*}

*esttab _all using results/var_regressions.tex, replace ///
*b(3) se(3) label star(* 0.10 ** 0.05 *** 0.01) ///
*booktabs longtable

*foreach var of varlist `vars' {
*	hist `var', percent lcolor(black) color(gray)
*	graph save results/hist-`var'.gph, replace
*}

*graph combine results/hist-profit.gph results/hist-solvency.gph  ///
*	results/hist-e_diverse.gph results/hist-pesticide.gph ///
*	results/hist-ghg_emissions.gph results/hist-land_quality.gph ///
*	results/hist-paid_wage.gph results/hist-prov_employ.gph ///
*	results/hist-productivity.gph  ///
*	ysize(11) xsize(8) title("Sustainability variables")
*graph export results/hist-combine.pdf, as(pdf) replace

*******************************
* descriptive stats and visuals
*******************************
/* checking representativeness of the sample
merge m:m idn YEAR using "C:\asci\stata\dat\110-raw_indicators-panel.dta"
keep if _merge==3
drop _merge

bysort YEAR: egen tuaa = sum(SE025) // total UAA in sample
bysort YEAR: egen cuaa = sum(SE025) if org < 3
bysort YEAR: egen ouaa = sum(SE025) if org > 2
bysort YEAR: gen organicUAA = (ouaa/tuaa)*100
tab organicUAA
lab var organicUAA "% UAA organic: sample"

gen eurostat_org = .  // all numbers from eurostat
replace eurostat_org = 4.5 if YEAR == 2004
replace eurostat_org = 4.7 if YEAR == 2005
replace eurostat_org = 4.9 if YEAR == 2006
replace eurostat_org = 5.1 if YEAR == 2007
replace eurostat_org = 5.4 if YEAR == 2008
replace eurostat_org = 5.6 if YEAR == 2009
replace eurostat_org = 5.9 if YEAR == 2010
replace eurostat_org = 6.1 if YEAR == 2011
replace eurostat_org = 5.76 if YEAR == 2012
replace eurostat_org = 6.04 if YEAR == 2013 
lab var eurostat_org "% UAA organic: actual"

tsset idn YEAR
tsline organicUAA eurostat_org, ///
yscale(range(0 6)) ylabel(0(0.5)6) ///
lcolor(black black) lpattern(solid dash) xtitle("Year") ytitle("% of total UAA") legend(pos(6) rows(1))
graph export results/organicuaa_test.pdf, as(pdf) replace

tsset idn year
*/

* hist of standardized asi 
hist zasi, percent lcolor(black) color(gray)
graph export results/hist-zasi4.pdf, as(pdf) replace

* farm counts by type and size class
bysort TF8: distinct idn if switch == 1
bysort TF8: distinct idn if all_conv == 1
bysort TF8: distinct idn if all_org == 1

bysort A26: distinct idn if switch == 1
bysort A26: distinct idn if all_conv == 1
bysort A26: distinct idn if all_org == 1

bysort TF8: distinct idn
bysort A26: distinct idn
distinct idn

distinct idn if switch == 1
distinct idn if all_conv == 1
distinct idn if all_org == 1

tab org YEAR

*** diffs in conventional, pre-S, and org: full sample
xtreg zasi4 i.org i.TF8 i.A26, vce(robust)  // regression with asi
est store regmain

esttab regmain using results/main_regression.tex, replace ///
b(4) se(4) label star(* 0.10 ** 0.05 *** 0.01) ///
booktabs longtable

*** 2004: diffs in conventional, pre-S, and org: 2004, by type and size 
oneway zasi4 org if YEAR == 2004, tab
pwmean zasi4 if YEAR == 2004, over(org) mcompare(tukey) effects

twoway kdensity zasi4 if YEAR == 2004 & org == 1 || ///
kdensity zasi4 if YEAR == 2004 & org == 2 || ///
kdensity zasi4 if YEAR == 2004 & org == 4, ///
legend( pos(3) rows(3) bmargin(large) ///
order (1 "AC" 2 "Pre-S" 3 "AO")) xtitle("{&theta}{&prime}") ///
ytitle("Kernel density") //xsize(6) ysize(7)
graph save results/descstats_overall.gph, replace
graph export results/descstats_overall.pdf, as(pdf) replace

graph hbox zasi4 if YEAR == 2004, over(org) over(TF8)  ///
ytitle({&theta}{&prime}) ylabel(-2(1)2) ///
asyvars legend(pos(6) rows(1)) xsize(9) ysize(7)
graph save results/descstats_tf8.gph, replace
graph export results/descstats_tf8.pdf, as(pdf) replace

graph hbox zasi4 if YEAR == 2004, over(org) over(A26) ///
ytitle({&theta}{&prime}) ylabel(-2(1)2) ///
asyvars legend(pos(6) rows(1)) xsize(9) ysize(7)
graph save results/descstats_a26.gph, replace
graph export results/descstats_a26.pdf, as(pdf) replace

graph combine results/descstats_tf8.gph results/descstats_a26.gph, ///
altshrink iscale(0.7) imargin(zero)
graph export results/descstats_combine.pdf, as(pdf) replace

* farm type
levelsof TF8, local(tf8cat) 
foreach z of local tf8cat {
	oneway zasi4 org if TF8 == `z' & YEAR == 2004, tab
	pwmean zasi4 if TF8 == `z' & YEAR == 2004, ///
	over(org) mcompare(tukey) effects
}

* farm size
levelsof A26, local(a26cat) 
foreach z of local a26cat {
	oneway zasi4 org if A26 == `z' & YEAR == 2004, tab
	pwmean zasi4 if A26 == `z' & YEAR == 2004, ///
	over(org) mcompare(tukey) effects
}
xx
save dat/asi_w-orgcat_reduced4.dta, replace

**************************
*** the DiD model ********
**************************
use dat/asi_w-orgcat_reduced4.dta, clear

drop if all_org == 1  // excluding farms that are always organic (treated)

est clear

*ssc install drdid, all replace
*ssc install csdid, all replace   
*csdid zasi4 i.TF8, cluster(A26) time(YEAR) gvar(treat) method(dripw) 
csdid zasi4, time(YEAR) gvar(treat) method(dripw) 
estat all
estat event, estore(event1)

event_plot event1, default_look together plottype(connected) ///
graph_opt(xtitle("Number of time periods since organic transition") ///
ytitle("ATT on {&theta}{&prime}") ///title("Min obs/farm: 10") ///
xlabel(-6(1)8)) stub_lag(Tp#) stub_lead(Tm#) 
graph save results/csdid_plot_ac5.gph, replace
graph export results/csdid_plot_ac5.pdf, as(pdf) replace

esttab event1 using results/event1-5.tex, replace  ///
b(3) ci(3) label star(* 0.10 ** 0.05 *** 0.01) ///
booktabs alignment(D{.}{.}{-1})  ///
collabels("ATT")

csdid zasi4, time(YEAR) gvar(treat) method(dripw) notyet
estat all
estat event, estore(event2)

event_plot event2, default_look together plottype(connected) ///
graph_opt(xtitle("Number of time periods since organic transition") ///
ytitle("ATT on {&theta}{&prime}") ///title("Min obs/farm: 10") ///
xlabel(-6(1)8)) stub_lag(Tp#) stub_lead(Tm#) 
graph save results/csdid_plot_ny5.gph, replace
graph export results/csdid_plot_ny5.pdf, as(pdf) replace

esttab event2 using results/event2-5.tex, replace  ///
b(3) ci(3) label star(* 0.10 ** 0.05 *** 0.01) ///
booktabs alignment(D{.}{.}{-1})  ///
collabels("ATT") 
fgh
graph combine results/csdid_plot_ac5.gph results/csdid_plot_ac6.gph  ///
	results/csdid_plot_ac7.gph results/csdid_plot_ac8.gph  ///
	results/csdid_plot_ac9.gph results/csdid_plot_ac10.gph,  ///
	col(2) ysize(11) xsize(8) title("AC control group")
graph export results/csdid_plot_combine-ac.pdf, as(pdf) replace

graph combine results/csdid_plot_ny5.gph results/csdid_plot_ny6.gph  ///
	results/csdid_plot_ny7.gph results/csdid_plot_ny8.gph  ///
	results/csdid_plot_ny9.gph results/csdid_plot_ny10.gph,  ///
	col(2) ysize(11) xsize(8) title("NYT control group")
graph export results/csdid_plot_combine-ny.pdf, as(pdf) replace

* did on individual vars
lab var profit "Profitability"
lab var solvency "Solvency"
lab var e_diverse "Economic diversity"
lab var pesticide "Expenditure on pesticides"
lab var ghg_emissions "GHG emissions"
lab var land_quality "Land ecosystem quality"
lab var paid_wage "Wage ratio"
lab var prov_employ "Provision of employment"
lab var productivity "Multi-factor productivity"

foreach var of varlist profit solvency e_diverse pesticide ///
ghg_emissions land_quality paid_wage prov_employ productivity {
csdid `var' i.TF8 i.A26, time(YEAR) gvar(treat) method(dripw)
estat all
estat event, estore(event_`var')

local vtext: variable label `var' 
if `"`vtext'"' == "" local vtext "`v'"

event_plot event_`var', default_look together plottype(connected) ///
graph_opt(xtitle("Number of time periods since organic transition") ///
ytitle("ATT") title(`"`vtext'"') ///
xlabel(-6(1)8)) stub_lag(Tp#) stub_lead(Tm#) 
graph save results/csdid_plot-`var'.gph, replace
graph export results/csdid_plot-`var'.pdf, as(pdf) replace

esttab event_prod using results/event-`var'.tex, replace  ///
b(3) ci(3) label star(* 0.10 ** 0.05 *** 0.01) ///
booktabs alignment(D{.}{.}{-1}) longtable ///
collabels("ATT") 
}
