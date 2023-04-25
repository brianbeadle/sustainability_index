/* ************************************************************************* * 
 *   Creator: Christoph
 *   Project: AS and NFC
 *   Date: 2022-08-02
 *  -----------------------------------------------------------------------  * 
 *   The purpose of this file is to create a cross-sectional data set
 *   for the year 2013 to estimate an IRT model for ASI including
 *   covariates
** ************************************************************************* */ 

use "../stata/dat/200-forcw.dta", clear

rename profit4 y1
rename solvency4 y2
rename paid_wage4 y3 
rename e_diverse4 y4 
rename prov_employ4 y5 
rename pesticide4 y6 
rename ghg_emissions4 y7 
rename productivity4 y8 
rename land_quality4 y9

reshape long y, i(idn) j(item)
save ../data/master.dta, replace

