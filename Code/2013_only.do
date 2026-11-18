/***************************** 2013 *****************************/ 

// born place 
use $raw_data/2013/Demographic_Background.dta, clear 
gen bornplace = .
replace bornplace = bb001
keep householdID ID bornplace

merge 1:1 ID using $raw_data/2011/Demographic_Background_temp.dta, keepusing(ID householdID bb001)
drop if _merge==2
replace bornplace = bb001 if mi(bornplace) & !mi(bb001)
keep householdID bornplace ID
tab bornplace,m 

keep if bornplace==1 | bornplace==2
duplicates drop householdID, force
tab bornplace,m 
save $working_data/bornplace_2013, replace

/***************************** 2013 Main *****************************/ 


use $raw_data/2013/Demographic_Background.dta, clear // 18605

// real measure of hypertension
merge 1:1 ID using $raw_data/2013/Biomarker.dta, keepusing(ID pa002 qa003 qa007 qa011 qa017 qb002-qb005 qa004 qa008 qa012)
egen mean_systolic = rowmean(qa003 qa007 qa011)
gen max_systolic = max(qa003, qa007,qa011 )
egen mean_diastolic = rowmean(qa004 qa008 qa012)
gen max_diastolic = max(qa004, qa008,qa012)

gen max_breathing = max(qb002, qb003,qb004)
replace max_breathing=. if max_breathing==999 |max_breathing==993 

drop _merge
merge 1:1 ID using $raw_data/2013/Health_Status_and_Functioning.dta
drop _merge

merge m:1 householdID using $working_data/bornplace_2013
keep if _merge==3
drop _merge

merge m:1 communityID using $raw_data/2013/PSU.dta
drop if _merge==2
drop _merge

merge 1:1 ID using $working_data/2013_unique.dta
keep if _merge==3 
drop _merge 



/* Self-reported health */ 

gen health_status=1 if da002==5 | da001==5
replace health_status=2 if da002==4 | da001==4
replace health_status=3 if da002==3 | da001==3
replace health_status=4 if da002==2 |  da001==2
replace health_status=5 if da002==1 | da001==1

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

gen health_status_group1=(health_status==3|health_status==4|health_status==5) if !mi(health_status_group)
gen health_status_group2=(health_status==4|health_status==5) if !mi(health_status_group)
gen health_status_group3=(health_status==5) if !mi(health_status_group)


/* Self-reported Hypertension */


rename da007_1_ da007_1_2013
merge 1:1 ID using $working_data/health_status_and_functioning_2011_change.dta, keepusing(ID da007_1_)
drop if _merge==2 // remain 1548
drop _merge

replace da007_1_=. if da007_1_==.r | da007_1_==.d 

gen hypertension=0 if da007_1_==2 | da007_1_2013==2 
replace hypertension = 1 if da007_1_==1 | da007_1_2013==1
// total 1407 have value


/* Optimistic */

gen optimistic = 0
replace optimistic= optimistic+1 if dc009==1
foreach i in 10 11 12 14 15 17 18{
	replace optimistic= optimistic+1 if dc0`i'==1
}
replace optimistic=optimistic+1 if dc013==4
replace optimistic=optimistic+1 if dc016==4

replace optimistic=. if mi(dc009) & mi(dc010) & mi(dc011) & mi(dc012) & mi(dc013) & mi(dc014) & mi(dc015) & mi(dc016) & mi(dc017) & mi(dc018) 


gen optimistic_group_mean = 1 if optimistic>=5.4 & optimistic!=. 
replace optimistic_group_mean =0 if optimistic<5.4

gen optimistic_group1 = 1 if optimistic>=2 & optimistic!=. 
replace optimistic_group1 =0 if optimistic<2

gen optimistic_group2 = 1 if optimistic>=4 & optimistic!=. 
replace optimistic_group2 =0 if optimistic<4

gen optimistic_group3= 1 if optimistic>=6 & optimistic!=. 
replace optimistic_group3 =0 if optimistic<6

gen optimistic_group4= 1 if optimistic>=8 & optimistic!=. 
replace optimistic_group4 =0 if optimistic<8

gen optimistic_group5= 1 if optimistic>=9 & optimistic!=. 
replace optimistic_group5 =0 if optimistic<9





/* Words recall */ // max: 20 points
gen cognitive_level1 = 0
forvalues i = 1(1)10 {
	replace cognitive_level1=cognitive_level1+1 if dc006_1_s`i'==`i'
}

gen cognitive_level2 = 0
forvalues i = 1(1)10 {
	replace cognitive_level2=cognitive_level2+1 if dc027s`i'==`i' 
}

replace cognitive_level1=0 if dc006_1_s11 == 11

replace cognitive_level1=. if mi(dc006_1_s1) & mi(dc006_1_s2) & mi(dc006_1_s3) & mi(dc006_1_s4) & mi(dc006_1_s5) & mi(dc006_1_s6) & mi(dc006_1_s7) & mi(dc006_1_s8) & mi(dc006_1_s9) & mi(dc006_1_s10)

replace cognitive_level2=. if mi(dc027s1) & mi(dc027s2) & mi(dc027s3) & mi(dc027s4) & mi(dc027s5) & mi(dc027s6) & mi(dc027s7) & mi(dc027s8) & mi(dc027s9) & mi(dc027s10)

egen cognitive_level = rowmean(cognitive_level1 cognitive_level2) 

tab cognitive_level,m 



/* Math Problems */ // max 5 points
gen Math_score = 0 
replace Math_score = Math_score+1 if dc019 == 93
replace Math_score = Math_score+1 if dc020 == 86
replace Math_score = Math_score+1 if dc021 == 79
replace Math_score = Math_score+1 if dc022 == 72
replace Math_score = Math_score+1 if dc023 == 65

replace Math_score =. if mi(dc019) & mi(dc020) & mi(dc021) & mi(dc022) & mi(dc023) 
tab Math_score,m

/* Age */
gen year=2013
gen birthyear = zba002_1 
replace birthyear=ba002_1 if ba002_1 !=. 

gen age = 2013-birthyear

order age, after(communityID)


gen age_group1 = age
recode age_group1 (min/44=.)(45/54=1)(55/64=2)(65/200=3)
label define age_grou1_label 1 "45-54" 2 "55-64" 3 "65+",replace
label values age_group1 age_grou1_label
label variable age_group1 "Age_group"

gen age_2 = age*age



/* Education */ // bd001

// schooling 

gen education_2013 = bd001_w2_4 
merge 1:1 ID using $working_data/edu_from2011, keepusing(ID education_2011)
drop if _merge==2
drop _merge 
replace education_2013 = education_2011 if education_2013==12 & !mi(education_2011)
replace education_2013 = bd001 if mi(education_2013) & !mi(bd001)
replace education_2013 = zbd001 if mi(education_2013) & !mi(zbd001)


recode education_2013 (1=1) (2=2) (3/4=3) (5=4) (6/12=5),gen(education_group)
label define label_education 1 "Illiterate" 2 "Did not finish primary" 3 "Finished primary" 4 "Middle school" 5 "High school and above"
label values education_group label_education
tab education_group, m
label variable education_group "Education Group"



**Define Education dummy: Middle school and above

gen edu_midabove=(education_group>=4) if !mi(education_group)
label var edu_midabove "Middle School and Above"
label def edu_midabove_lab 0 "Below Middle School" 1 "Middle school and above"
label values edu_midabove edu_midabove_lab


/* Gender */
gen gender=xrgender 
gen female=gender-1


/* smoke drink*/
gen smoking =1 if da059==1 // 232-1 (1781)
replace smoking=0 if da059==2

gen drinking= 0 if da069==1 // 655-1 (1345)
replace drinking=1 if da069==2 | da069==3 | da067==1 | da067==2

merge 1:1 ID using $working_data/2011_smoking_drinking.dta
drop if _merge==2
drop _merge
replace smoking = smoking_2011 if smoking==.
replace drinking = drinking_2011 if drinking==. 


keep ID communityID householdID age gender female ah_good health_status health_status_group education_group smoking drinking age_2 optimistic hypertension birthyear max_breathing mean_systolic qa017 max_systolic max_diastolic mean_diastolic optimistic_group_mean optimistic_group1 optimistic_group2 optimistic_group3 optimistic_group4 optimistic_group5 cognitive_level Math_score province city city_eng urban_nbs year health_status_group1 health_status_group2 health_status_group3 health_status_group age_group1

save $working_data/2013_main_y_control.dta, replace //


//d5
merge 1:1 ID using $raw_data/2014/family_information.dta, keepusing(ID d5 c4_a) 
keep if _merge==3 // drop 20818 
drop _merge 
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

save $working_data/2013_main_y_x_control, replace //

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

keep ID smoking drinking
rename smoking smoking_2013
rename drinking drinking_2013
save $working_data/2013_smoking_drinking.dta, replace  


/*
/***************************** 2013 Child *****************************/ 

use $raw_data/2013/Child.dta, clear
gen sample_2013=.
replace sample_2013= 1 if cb081==1 | cb081==2 
replace sample_2013= 0 if cb081!=1 & cb081!=2
tostring childID, replace
replace childID = householdID + childID
keep childID sample_2013
save $working_data/ChildID_2013.dta, replace


/******************** Rehression - 2013_Main ***************************/ 

use $working_data/2013_main_y_x_control.dta, clear 

xi: probit ah_good ce_good i.education_group age age_2 female, cluster(city) 
mfx
est store childhood1

outreg2 [childhood1] using "$tables\2013_ah_good_ce_good.xls",replace

