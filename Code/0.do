
// Unique database
// 2011 rename 
// Total regression 


clear 
clear mata
clear matrix  
set maxvar 32767
set more off
capture log close

global root= "/Users/jy/Desktop/Qiu"
global dofiles= "$root/Dofiles"
global logfiles= "$root/Logfiles"
global raw_data= "$root/Raw_data"
global working_data= "$root/Working_data"
global temp_data= "$root/Temp_data"
global tables= "$root/Tables"
global figures= "$root/Figures"

log using $logfiles/2018-Data.log, replace


// 2011 database rename ID & householdID
use $raw_data/2011/demographic_background.dta, clear
replace householdID = householdID + "0"
replace ID = householdID + substr(ID,-2,2)
save $raw_data/2011/demographic_background_temp.dta, replace

use $raw_data/2011/biomarkers.dta, clear 
replace householdID = householdID + "0"
replace ID = householdID + substr(ID,-2,2)
save $raw_data/2011/biomarkers_temp.dta, replace 

use $raw_data/2011/health_status_and_functioning.dta, clear 
replace householdID = householdID + "0"
replace ID = householdID + substr(ID,-2,2)
save $raw_data/2011/health_status_and_functioning_temp.dta, replace 

/* Unique */
/* Combine data*/
use $raw_data/2018/Demographic_Background.dta, clear // 19816
merge 1:1 ID using $raw_data/2015/Demographic_Background.dta, keepusing(ID householdID communityID)
keep if _merge==2 // drop 19816
keep ID householdID communityID
save $working_data/2015_unique_temp.dta, replace // remain 2961 

use $raw_data/2018/Demographic_Background.dta, clear
merge 1:1 ID using $raw_data/2013/Demographic_Background.dta, keepusing(ID householdID communityID)
keep if _merge==2 // drop 19816 
keep ID householdID communityID
save $working_data/2013_unique_temp.dta, replace // remain 3526

use $raw_data/2011/demographic_background_temp.dta, clear //17705
merge 1:1 ID using $raw_data/2018/Demographic_background.dta, keepusing(ID householdID communityID)
keep if _merge==1 // drop 19816 
keep ID householdID communityID
save $working_data/2011_unique_temp.dta, replace // remain 4139

use $working_data/2015_unique_temp.dta, clear // 2961
merge 1:1 ID using $working_data/2013_unique_temp.dta 
drop if _merge==2 // drop 1548
drop _merge
save $working_data/2015_unique.dta, replace //remain 2961

use $working_data/2013_unique_temp.dta, clear // 3526
merge 1:1 ID using $working_data/2011_unique_temp.dta
drop if _merge==2 // drop 1487
drop _merge
merge 1:1 ID using $working_data/2015_unique.dta
keep if _merge==1 // drop 2961
drop _merge
save $working_data/2013_unique.dta, replace // remain 1548

use $working_data/2011_unique_temp.dta, clear // 4139
merge 1:1 ID using $working_data/2013_unique.dta
keep if _merge==1 // drop 1548
drop _merge
merge 1:1 ID using $working_data/2015_unique.dta
keep if _merge==1 // drop 2961
drop _merge
save $working_data/2011_unique.dta, replace // remain 1258



/*********************** Combine from 4 years ******************************/ 

use $working_data/2011_main_y_x_control.dta, clear
append using $working_data/2013_main_y_x_control.dta, // 13 main 
append using $working_data/2015_main_y_x_control.dta, // 15 main  
append using $working_data/2015_child_d5.dta,  // 15 child
append using $working_data/2018_main_y_x_control.dta, // 18 main  
save $working_data/All_main_y_x_control.dta, replace



use $working_data/2015_Child_All.dta, clear // 15 child 
append using $working_data/2015_Main_All.dta, // 15 main
append using $working_data/2018_Main_All.dta, // 18 main
append using $working_data/2018_Child_All.dta, // 18 child 
save $working_data/All_TSP_Meteor.dta, replace 

/*********************** Rehression from 4 years ******************************/ 


use $working_data/All_TSP_Meteor.dta, clear 

xi: probit ah_good TSP i.education_group age age_2 female temperature, cluster(city) 
mfx
est store TSP1
outreg2 [TSP1] using "$tables\All_ah_good_TSP.xls",replace


xi: ivreg ah_good (TSP= sea_level wind_speed) i.education_group age age_2 female temperature
est store iv1
outreg2 [iv1] using "$tables\All_ah_good_TSP_iv.xls",replace



use $working_data/All_main_y_x_control.dta, clear

// Self-reported health 

xi: probit ah_good ce_good i.education_group age age_2 female 
mfx
est store self1
outreg2 [self1] using "$tables\All_ah_good_ce_good1.xls",replace

gen hh = 1 if health_status==1 | health_status==2 | health_status==3
replace hh=2 if health_status==4
replace hh = 3 if health_status==5


//Table
xi: ologit hh ce_good age age_2 i.education_group female //3
mfx, predict(p outcome(1)) 
forvalues i = 2/3 {
    mfx, predict(p outcome(`i'))
}
mfx2,replace //mfx2 
est store self2

outreg2 [self2]using "$tables\All_ah_good_ce_good2.xls", cttop(mfx2) replace excel dec(5)


// Table 
xi: ologit health_status ce_good age age_2 i.education_group female //5
mfx, predict(p outcome(1)) 
forvalues i = 2/5 {
    mfx, predict(p outcome(`i'))
}
mfx2,replace //mfx2 
est store self3

outreg2 [self3]using "$tables\All_ah_good_ce_good3.xls", cttop(mfx2) replace excel dec(5)

/******************** Optimistic ***********/ 

xi: reg optimistic ce_good age age_2 i.education_group female
est store optimistic1

xi: oprobit optimistic_group1 ce_good age age_2 i.education_group female 
mfx
est store optimistic2

xi: oprobit optimistic_group2 ce_good age age_2 i.education_group female 
mfx
est store optimistic3

xi: oprobit optimistic_group3 ce_good age age_2 i.education_group female 
mfx
est store optimistic4

outreg2 [optimistic1 optimistic2 optimistic3 optimistic4] using "$tables\All_optimistic_ce_good.xls",replace

/******************** Breathing Function ***********/ 
gen b=0 if max_breathing<300
replace b=1 if max_breathing>=300 & max_breathing!=. // the higher the value the better

xi: reg max_breathing ce_good age age_2 i.education_group female urban_nbs, vce(cluster communityID)
est store breath1
xi: probit b ce_good age age_2 i.education_group female urban_nbs, vce(cluster communityID)
mfx
est store breath2
outreg2 [breath1 breath2] using"$tables\All_breathing_ce_good.xls",replace

