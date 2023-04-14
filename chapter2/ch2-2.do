/* ************************************************************************* *\ 
 * 	Creating 4-category ordinal scales from the continuous sustainability vars
 *   Date created: 14.02.22
 *   Author: Brian Beadle

 * notes:
 * there is a mix of absolute, quasi-absolute, and relative thresholds
 * absolute vars have clearly defined boundaries from external sources:
 * profit: Thunen institute data (adjusted for inflation and averaged over time)
 * solvency: categories defined by University of Minnesota report (see paper)
 * paid_wage: OECD classifications
 * pesticide: the recommended max is 3.6kg/ha, so this is the upper threshold
 * kg/ha is calculated using an estimate of 20eur/kg: 3.6*20=72eur/ha

 * quasi-absolute vars use theoretically logical boundaries:
 * e_diverse and prov_employ should theoretically be in the range of [0,1]
 * all other vars are relative and based on the total range in the observations
 * in the case of ghg_emissions, the range is reduced because of extreme values
** ************************************************************************** */

cd C:/asci/stata // work laptop

use dat/110-raw_indicators-panel.dta, clear

* absolute thresholds
gen profit4 = .
replace profit4 = 0 if profit < 0
replace profit4 = 1 if profit >= 0 & profit < pppepawu_p25
replace profit4 = 2 if profit >= pppepawu_p25 & profit < pppepawu_p75
replace profit4 = 3 if profit >= pppepawu_p75

gen solvency4 = .
replace solvency4 = 0 if solvency >= 1 // insolvent 
replace solvency4 = 1 if solvency >= 0.6 & solvency < 1 // vulnerable
replace solvency4 = 2 if solvency >= 0.3 & solvency < 0.6 // caution
replace solvency4 = 3 if solvency < 0.3  // strong

gen paid_wage4 = .  
replace paid_wage4 = 0 if paid_wage < 0.5  // classified as poor
replace paid_wage4 = 1 if paid_wage >= 0.5 & paid_wage < 0.75  // lower income
replace paid_wage4 = 2 if paid_wage >= 0.75 & paid_wage < 2  // middle income
replace paid_wage4 = 3 if paid_wage >= 2  // upper income

gen pesticide4 = .
replace pesticide4 = 0 if pesticide > 144  // more than 2x recommended max
replace pesticide4 = 1 if pesticide <= 144 & pesticide > 72  // 1-2x recommended  
replace pesticide4 = 2 if pesticide <= 72 & pesticide > 36 // more than 1/2 max
replace pesticide4 = 3 if pesticide <= 36  // no use or less than 1/2 max 

* quasi-absolute thresholds
gen e_diverse4 = .
replace e_diverse4 = 0 if e_diverse >= 0.75
replace e_diverse4 = 1 if e_diverse >= 0.5 & e_diverse < 0.75
replace e_diverse4 = 2 if e_diverse >= 0.25 & e_diverse < 0.5
replace e_diverse4 = 3 if e_diverse < 0.25

gen prov_employ4 = .
replace prov_employ4 = 0 if prov_employ < 0.25
replace prov_employ4 = 1 if prov_employ >= 0.25 & prov_employ < 0.5
replace prov_employ4 = 2 if prov_employ >= 0.5 & prov_employ < 0.75
replace prov_employ4 = 3 if prov_employ >= 0.75

gen productivity4 = .
replace productivity4 = 0 if productivity <= 0  // negative productivity 
replace productivity4 = 1 if productivity > 0 & productivity <= 0.5  // 
replace productivity4 = 2 if productivity > 0.5 & productivity <= 1
replace productivity4 = 3 if productivity > 1  // 

gen land_quality4 = .
replace land_quality4 = 0 if land_quality < 0.1  // less than 10% quality
replace land_quality4 = 1 if land_quality >= 0.1 & land_quality < 0.25
replace land_quality4 = 2 if land_quality >= 0.25 & land_quality < 0.4 
replace land_quality4 = 3 if land_quality >= 0.4

* relative thresholds
egen ghg_emissionsmed = median(ghg_emissions)
gen ghg_emissions4 = .
replace ghg_emissions4 = 0 if ghg_emissions > 2*ghg_emissionsmed  
replace ghg_emissions4 = 1 if ghg_emissions <= 2*ghg_emissionsmed ///
	& ghg_emissions > ghg_emissionsmed
replace ghg_emissions4 = 2 if ghg_emissions <= ghg_emissionsmed ///
	& ghg_emissions > 0
replace ghg_emissions4 = 3 if ghg_emissions <= 0  // net zero or negative

keep YEAR idn profit4 solvency4 paid_wage4 e_diverse4 prov_employ4 ///
pesticide4 productivity4 ghg_emissions4 land_quality4  ///
NUTS2 TF8 TF14 A26 SE005 SE025 SE085

save dat/100-asi-ord4-panel.dta, replace 
