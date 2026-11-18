/********** Hypertension Records from 2015 **********/
use $raw_data/2015/Biomarker.dta, clear
keep ID pa002 qa003 qa007 qa011 qa017 qa016
gen mean_systolic = (qa003+qa007+qa011)/3
replace mean_systolic= . if pa002==2
replace mean_systolic=. if qa017 != 5
replace mean_systolic=. if qa016 != 2
save $working_data/Hypertension_measure_2015.dta, replace 



/************* Age Edu Gender  ************/
use $raw_data/2015/Demographic_Background, clear
keep ID communityID householdID ba000_w2_3 ba004_w3_1 bd001_w2_4
// ba000_w2_3 gender // ba004_w3_1出生 // bd001_w2_4 edu(12. No changing 没有变化)
gen age=2015-ba004_w3_1 
gen female = ba000_w2_3-1 
gen age_2=age*age

// schooling 
gen education= bd001_w2_4
gen missing=1 if bd001_w2_4==12
recode education (1=1) (2=2) (3/4=3) (5=4) (6/10=5),gen(education_group)
label define label_education 1 "Illiterate" 2 "Did not finish primary" 3 "Finished primary" 4 "Middle school" 5 "High school and above"
label values education_group label_education
tab education_group, m
label variable education_group "Education Group"
replace education_group=. if missing==1
save $working_data/Hyper_age_gender_edu_2015, replace 
drop if missing==1
save $working_data/edu_2015only, replace 


use $working_data/Hyper_age_gender_edu_2015, clear
keep if missing==1 
keep ID 
save $working_data/2015_missing, replace 

//2014
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
keep ID education_group
merge 1:1 ID using $working_data/2015_missing
keep if _merge==3
drop _merge 
save $working_data/edu_2014only, replace 


// 2013
use $working_data/2015_missing, clear
merge 1:1 ID using $raw_data/2013/Demographic_Background.dta 
keep ID bd001_w2_3 bd001_w2_4 _merge 
keep if _merge==3

replace bd001_w2_3= bd001_w2_4 if bd001_w2_4!=12 
gen missing =1 if bd001_w2_4==12 &bd001_w2_3==. 
drop bd001_w2_4 _merge
save $working_data/hyper_2013all, replace 

drop if missing==1 | bd001_w2_3==. 
gen education= bd001_w2_3
recode education (1=1) (2=2) (3/4=3) (5=4) (6/11=5),gen(education_group)
label define label_edu 1 "Illiterate" 2 "Did not finish primary" 3 "Finished primary" 4 "Middle school" 5 "High school and above"
label values education_group label_edu
tab education_group, m
label variable education_group "Education Group"
keep ID education_group
save $working_data/edu_2013only, replace 

/*
use $working_data/hyper_2013all, clear
keep if missing==1 
drop bd001_w2_3
save $working_data/hyper_2013missing, replace 

use $raw_data/2012/Demographic_background, clear 
replace householdID = householdID + "0"
replace ID = householdID + substr(ID,-2,2)
keep ID bd001

merge 1:1 ID using $working_data/hyper_2013missing
drop if _merge!=3
*/


use $working_data/edu_2014only, clear 
merge 1:1 ID using $working_data/edu_2013only
drop _merge 
merge 1:1 ID using $working_data/Hyper_age_gender_edu_2015
drop if education_group ==.  // 956 observations deleted
drop _merge 
save $working_data/2015_basic, replace




/*********** self-reported *********/
use $raw_data/2015/Health_Status_and_Functioning, clear
keep ID da001 da002 da007_1_ xrtype


// Self Comment of Your Life 

gen adult_health = da001
replace adult_health = da002 if adult_health==. 


gen health_status=1 if adult_health==5
replace health_status=2 if adult_health==4 
replace health_status=3 if adult_health==3 
replace health_status=4 if adult_health==2 
replace health_status=5 if adult_health==1 

recode health_status (1/2=1) (3=2) (4/5=3), gen(health_status_group)
label define label_health 1 "Bad" 2 "Fine" 3 "Good" 
label values health_status_group label_health
tab health_status_group,m 
label variable health_status Adult_health_status

gen ah_good=(health_status==5|health_status==4|health_status==3) if !mi(health_status_group)
lab var ah_good "Adult Health is Good?"
lab def ah_good 0 "B" 1 "F G"
lab values ah_good ah_good
tablist ah_good,sort(v)

// Self-value Hypertension 
//keep if xrtype == 1
gen hypertension=1 if da007_1_==1
replace hypertension=0 if da007_1_==2
save $working_data/2015new_hypertension_ah_good, replace 


use $raw_data/2013/Health_Status_and_Functioning.dta, clear
keep ID xrtype da007_1_
keep if xrtype==1 
replace da007_1_= 2 if da007_1_==. 
gen hypertension=1 if da007_1_==1
replace hypertension=0 if da007_1_==2
keep ID hypertension 
save $working_data/2013new_hypertension_ah_good, replace 

use $raw_data/2012/Health_Status_and_Functioning.dta, replace 
keep ID da007_1_
replace da007_1_= 2 if da007_1_==. 
gen hypertension=1 if da007_1_==1
replace hypertension=0 if da007_1_==2
save $working_data/2012new_hypertension_ah_good, replace 



use $working_data/2015new_hypertension_ah_good, clear 
merge 1:1 ID using $working_data/2013new_hypertension_ah_good
drop if _merge==2
drop _merge 
merge 1:1 ID using $working_data/2012new_hypertension_ah_good 


save $working_data/Hyper_ah_good_, replace 






/****** Together *****/
use $working_data/2015_basic, clear 
merge 1:1 ID using $working_data/Hyper_ah_good_  
drop if _merge !=3 //1,006 observations deleted
drop _merge 
save $working_data/2015_hyper_seif_only, replace 
merge 1:1 ID using $working_data/Hypertension_measure_2015.dta 
drop if _merge !=3 // observations deleted
drop _merge 
save $working_data/2015_hyper_both, replace 



use $working_data/2015_hyper_both, clear 
gen hyper1 = 1 if hypertension==1 
replace  hyper1 = 0 if hypertension==0 // only 2015 self

gen hyper2=1 if mean_systolic>=140 & mean_systolic !=. 
replace hyper2 = 0 if mean_systolic< 140  // only 2015 test 

gen hyper3=1 if hypertension==1 & mean_systolic>=140 & mean_systolic !=. 
replace hyper3=0 if hypertension==0 | mean_systolic< 140  // both 

gen hyper4=1 if hypertension==1 | mean_systolic>=140 & mean_systolic !=. 
replace hyper4=0 if hypertension==0 & mean_systolic< 140  // both 


merge m:1 householdID using $temp_data/d5.dta
drop _merge 

gen ce_good=(d5==1|d5==2) if !mi(d5)
lab var ce_good "Child Health Good or VG?"
lab def ce_good 0 "NG P" 1 "G VG", replace
lab values ce_good ce_good
tablist ce_good,sort(v)




// Table 5
xi: probit hyper1 ce_good i.education_group age age_2 female // both
mfx 
est store Hyper_1

xi: probit hyper2 ce_good i.education_group age age_2 female // one only
mfx 
est store Hyper_2

xi: probit hyper3 ce_good i.education_group age age_2 female //choice only
mfx 
est store Hyper_3

xi: probit hyper4 ce_good i.education_group age age_2 female // measure only
mfx
est store Hyper_4

outreg2 [Hyper_1 Hyper_2 Hyper_3 Hyper_4] using "$tables\Hyper_ce_good.xls",replace
