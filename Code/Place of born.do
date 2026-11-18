
/* Place of Born */ 
use $raw_data/2015/Demographic_Background.dta, clear
keep bb001* ID householdID communityID
rename bb001 Born_2015
save $temp_data/2015_Place_of_Born.dta, replace 

use $working_data/2018_Background_combine.dta, clear 
merge m:1 ID using $temp_data/2015_Place_of_Born.dta
tab _merge
drop if _merge!=3
drop _merge
replace bb001=Born_2015 if bb001==.
save $working_data/2018_Background_combine_clean.dta, replace





//2011 
use $raw_data/2011/demographic_background.dta, clear 
replace householdID = householdID + "0"
replace ID = householdID + substr(ID,-2,2)
keep ID householdID communityID bb001 bb001_1 bb001_3 bb001_4
gen communityIDnew = communityID if bb001==1 | bb001==2
keep if bb001==1 | bb001==2 | bb001==3
