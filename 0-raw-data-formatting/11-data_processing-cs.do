********************************************************************************
* cross section data: 4-category IRT model with subgroups for scale linking
* input file: 4-cat panel dataset
* author: Brian
* date: 19.06.22
********************************************************************************

cd C:/asci/git/agricultural_sustainability/stata // work laptop
*cd C:\Users\Beadle\Documents\GitHub\agricultural_sustainability\stata //personal

/* ************************************************************************* *\ 
 *   create master data
\* ************************************************************************* */ 

use dat/100-asi-ord4-panel.dta, clear

keep if YEAR == 2013
drop YEAR

rename profit4 y1
rename solvency4 y2
rename paid_wage4 y3 
rename e_diverse4 y4 
rename prov_employ4 y5 
rename pesticide4 y6 
rename ghg_emissions4 y7 
rename productivity4 y8 
rename land_quality4 y9

* dimensionality testing
*cor y*  // high correlations: profit and productivity, pesticide and land qual
*factor y*
*rotate
*sortl  // factor analysis shows 5 factors

reshape long y, i(idn) j(item)
saveold dat/200-asi-ord4-2013master.dta, replace version(12)
*export delimited using "C:\Users\Beadle\Documents\GitHub\agricultural_sustainability\stata\dat\200-asi-ord4-2013master.csv", replace

/* ************************************************************************* *\ 
 *   create group-specific data set with missing values
\* ************************************************************************* */ 

use dat/100-asi-ord4-panel.dta, clear

keep if YEAR == 2013
drop YEAR

rename profit4 y1
rename solvency4 y2
rename paid_wage4 y3 
rename e_diverse4 y4 
rename prov_employ4 y5 
rename pesticide4 y6 
rename ghg_emissions4 y7 
rename productivity4 y8 
rename land_quality4 y9

gen group = 1
replace group = 2 if NUTS2 == "DE80" | NUTS2 == "DE30" | NUTS2 == "DE40"  ///
| NUTS2 == "DEE0" | NUTS2 == "DED2" | NUTS2 == "DED3" | NUTS2 == "DED5"  ///
| NUTS2 == "DEG0"

tab group 

* this removes a set of vars from each group
*foreach var of varlist y2 y6 y3 {
*replace `var' = . if group == 1
*}

*foreach var of varlist y1 y8 y7 {
*replace `var' = . if group == 2
*}

foreach var of varlist y1 y2 y3 y4 y5 y6 y7 y8 y9 {
    count if `var' == .
	tab `var'
}  // no missing obs

reshape long y, i(idn) j(item)
saveold dat/200-asi-ord4-2013grouped.dta, replace version(12)
