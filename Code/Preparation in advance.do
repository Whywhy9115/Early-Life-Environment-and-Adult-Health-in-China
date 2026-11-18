
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

log using $logfiles/Data.log, replace


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

use $raw_data/2011/child.dta, clear
replace householdID = householdID + "0"
replace ID = householdID + substr(ID,-2,2)
save $raw_data/2011/child_temp.dta, replace 

/* Unique */
/* Combine data*/
use $raw_data/2018/Demographic_Background.dta, clear 
merge 1:1 ID using $raw_data/2015/Demographic_Background.dta, keepusing(ID householdID communityID)
keep if _merge==2 
keep ID householdID communityID
save $working_data/2015_unique_temp.dta, replace 

use $raw_data/2018/Demographic_Background.dta, clear
merge 1:1 ID using $raw_data/2013/Demographic_Background.dta, keepusing(ID householdID communityID)
keep if _merge==2 
keep ID householdID communityID
save $working_data/2013_unique_temp.dta, replace 

use $raw_data/2011/demographic_background_temp.dta, clear
merge 1:1 ID using $raw_data/2018/Demographic_background.dta, keepusing(ID householdID communityID)
keep if _merge==1 
keep ID householdID communityID
save $working_data/2011_unique_temp.dta, replace 

use $working_data/2015_unique_temp.dta, clear 
merge 1:1 ID using $working_data/2013_unique_temp.dta 
drop if _merge==2 
drop _merge
save $working_data/2015_unique.dta, replace

use $working_data/2013_unique_temp.dta, clear 
merge 1:1 ID using $working_data/2011_unique_temp.dta
drop if _merge==2 
drop _merge
merge 1:1 ID using $working_data/2015_unique.dta
keep if _merge==1 
drop _merge
save $working_data/2013_unique.dta, replace 

use $working_data/2011_unique_temp.dta, clear 
merge 1:1 ID using $working_data/2013_unique.dta
keep if _merge==1 
drop _merge
merge 1:1 ID using $working_data/2015_unique.dta
keep if _merge==1 
drop _merge
save $working_data/2011_unique.dta, replace 


//2011 education
use $raw_data/2011/demographic_background_temp.dta, clear
keep ID bd001
gen education= bd001
recode education (1=1) (2=2) (3/4=3) (5=4) (6/11=5),gen(education_group)
label define label_edu 1 "Illiterate" 2 "Did not finish primary" 3 "Finished primary" 4 "Middle school" 5 "High school and above"
label values education_group label_edu
tab education_group, m
label variable education_group "Education Group"
keep ID education_group education
rename education education_2011
rename education_group education_group_2011
save $working_data/edu_from2011, replace 


//2013 education
use $raw_data/2013/Demographic_Background.dta, clear
keep ID bd001_w2_3
gen education= bd001_w2_3
recode education (1=1) (2=2) (3/4=3) (5=4) (6/11=5),gen(education_group)
label define label_edu 1 "Illiterate" 2 "Did not finish primary" 3 "Finished primary" 4 "Middle school" 5 "High school and above"
label values education_group label_edu
tab education_group, m
label variable education_group "Education Group"
keep ID education_group education 
rename education education_2013
rename education_group education_group_2013
save $working_data/edu_from2013, replace 


//2014 education 
use $raw_data/2014/Education_History.dta, clear 
keep ID e000s1-e000s12
gen education=1 if e000s12==12
replace education=3 if e000s1==1
replace education=2 if e000s2==2 | e000s3==3
forvalues i = 4(1)11{
	replace education=`i' if e000s`i'==`i'
}
recode education (1=1) (2=2) (3/4=3) (5=4) (6/11=5),gen(education_group)
label define label_education 1 "Illiterate" 2 "Did not finish primary" 3 "Finished primary" 4 "Middle school" 5 "High school and above"
label values education_group label_education
tab education_group, m
label variable education_group "Education Group"
keep ID education education_group
rename education education_2014
rename education_group education_group_2014
save $working_data/edu_from2014, replace 


