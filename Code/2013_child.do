/******************** 2013 Child ***************************/ 

use $raw_data/2013/Child.dta, clear // 31348

//alive 

merge m:1 householdID using $working_data/bornplace_2013
keep if _merge==3
drop _merge


merge m:1 ID using $working_data/2013_unique.dta
keep if _merge==3 
drop _merge 


// Income Y
gen ah_income=(cb069==5|cb069==6|cb069==7|cb069==8|cb069==9|cb069==10|cb069==11) if !mi(cb069)
lab var ah_income "Adult Income is high?"
lab def ah_income 0 "Poor" 1 "Good"
lab values ah_income ah_income
tablist ah_income,sort(v) 
tab ah_income,m


// schooling 

gen education = cb060
recode education (1=1) (2=2) (4=3) (5=4) (6/11=5),gen(education_group)
label define label_education 1 "Illiterate" 2 "Did not finish primary" 3 "Finished primary" 4 "Middle school" 5 "High school and above"
label values education_group label_education
tab education_group, m
label variable education_group "Education Group"


/* Age */
replace age = 2013-cb051_1 if age==.
gen age_2 = age*age

/* Gender */

gen female=(gender-1)

// d5 
//d5- childhood environment
merge m:1 ID using $raw_data/2014/family_information.dta, keepusing(ID d5 c4_a) 
drop _merge //remain 2186
//keep all+d5
gen child_environment= 1 if d5 == 4
replace child_environment = 2 if d5==3
replace child_environment = 3 if d5==2
replace child_environment = 4 if d5==1

tab d5
lab var child_environment "Self-reported Child Environment"
lab def child_environment 1 "Poor" 2 "Not Good" 3 "Good" 4 "Very Good" 
lab values child_environment child_environment
tab child_environment, m


gen ce_good=(d5==1|d5==2) if !mi(d5)
lab var ce_good "Child Health Good or VG?"
lab def ce_good 0 "NG P" 1 "G VG", replace
lab values ce_good ce_good
tablist ce_good,sort(v)
// 
gen ce_financial=(c4_a==1|c4_a==2|c4_a==3) if !mi(d5)
lab var ce_financial "Childhood financial Good or VG?"
lab def ce_financial 0 "NG P" 1 "G VG", replace
lab values ce_financial ce_financial 



// PSU TSP

//merge m:1 communityID using $raw_data/charls_community_tsp.dta
//merge m:1 communityID using $raw_data/charls_community_tsp_quartic.dta
merge m:1 communityID using $raw_data/charls_community_tsp_cubic.dta
//merge m:1 communityID using $raw_data/charls_community_tsp_quadratic.dta

drop _merge
gen TSP=.
gen birthyear = 2013-age
forvalues i = 1981(1)1995{
	replace TSP = pollution_`i' if birthyear==`i'
}

gen TSP_total =. 
replace TSP_total = 0 if TSP !=. 
forvalues i = 1981(1)1995{
	replace TSP_total = TSP_total + (pollution_`i')*(1/(1996-`i')) if birthyear<=`i'
}



save $working_data/2013_child_TSP.dta, replace 

// Meteorological data
use $working_data/meteo_annual_average_360_fix.dta, clear // all 316
duplicates drop city_eng, force
merge 1:m city_eng using $working_data/2013_child_TSP.dta
drop _merge
gen temperature=.
gen sea_level = .
gen wind_speed = .
forvalues i = 1981(1)1995{
	replace temperature = air_temperature_ave`i' if birthyear==`i'
	replace sea_level = sea_level_pressure_ave`i' if birthyear==`i'
	replace wind_speed = wind_speed_ave`i' if birthyear==`i'
}



gen temperature_total=0 if temperature !=. 
gen sea_level_total = 0 if sea_level !=. 
gen wind_speed_total = 0 if wind_speed !=. 

forvalues i = 1981(1)1995{
	replace temperature_total = temperature_total + (air_temperature_ave`i')*(1/(1996-`i')) if birthyear<=`i'
	replace sea_level_total = sea_level_total + (sea_level_pressure_ave`i')*(1/(1996-`i')) if birthyear<=`i'
	replace wind_speed_total = wind_speed_total + (wind_speed_ave`i')*(1/(1996-`i')) if birthyear<=`i'
	
}



gen year =2013
save $working_data/2013_Child_All.dta, replace 
/*

/******************** Rehression - 2013_Child ***************************/ 

use $working_data/2013_Child_All.dta, clear 

xi: probit ah_income ce_good i.education_group age age_2 female 
mfx
est store childhood1

outreg2 [childhood1] using "$tables\2013_ah_good_ce_good.xls",replace


xi: probit ah_income TSP_total i.education_group age age_2 female temperature_total urban_nbs, cluster(communityID)
mfx
est store TSP1


xi: probit ah_income TSP_total i.education_group age age_2 female temperature_total urban_nbs, cluster(city)
mfx
est store TSP22
outreg2 [TSP1] using "$tables\2013_ah_good_TSP.xls",replace


xi: ivreg ah_income (TSP_total= sea_level_total wind_speed_total) i.education_group age age_2 female temperature_total urban_nbs, cluster(communityID)
est store iv1 


outreg2 [iv1] using "$tables\2013_ah_good_TSP_iv.xls",replace


