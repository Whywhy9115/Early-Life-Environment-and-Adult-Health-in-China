/***************************** 2011 *****************************/ 

// born place 
use $raw_data/2011/Demographic_Background_temp.dta, clear 
gen bornplace = .
replace bornplace = bb001
keep householdID ID bornplace

keep if bornplace==1 | bornplace==2
duplicates drop householdID, force
tab bornplace,m 
save $working_data/bornplace_2011, replace

/***************************** 2011 Main *****************************/ 


use $raw_data/2011/demographic_background_temp.dta, clear //17705

// real measure of hypertension
merge 1:1 ID using $raw_data/2011/biomarkers_temp.dta, keepusing(ID pa002 qa003 qa007 qa011 qa017 qb002-qb005 qa004 qa008 qa012)
drop _merge
replace qa003=. if qa003==993 | qa003==.d | qa003== .r
replace qa007=. if qa007==993 | qa007==.d | qa007== .r
replace qa011=. if qa011==993 | qa011==.d | qa011== .r

replace qa004=. if mi(qa004)
replace qa008=. if mi(qa008)
replace qa012=. if mi(qa012)

egen mean_systolic = rowmean(qa003 qa007 qa011)
egen mean_diastolic = rowmean(qa004 qa008 qa012)
gen max_systolic = max(qa003, qa007,qa011)
gen max_diastolic = max(qa004, qa008,qa012)

gen max_breathing = max(qb002, qb003,qb004)

replace max_breathing=. if max_breathing==999 |max_breathing==993 


merge 1:1 ID using $raw_data/2011/health_status_and_functioning_temp.dta
drop _merge

merge m:1 householdID using $working_data/bornplace_2011
keep if _merge==3
drop _merge

merge m:1 communityID using $raw_data/2013/PSU.dta
drop if _merge==2
drop _merge

merge 1:1 ID using $working_data/2011_unique.dta
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
tablist ah_good,sort(v) //totall 1217 have value

/* Self-reported Hypertension */
replace da007_1_=. if da007_1_==.d | da007_1_==.r
gen hypertension = 1 if da007_1_==1
replace hypertension=0 if da007_1_==2 // totall 1209 have value

/* Optimistic */ 

gen optimistic = 0
replace optimistic= optimistic+1 if dc009==1
foreach i in 10 11 12 14 15 17 18{
	replace optimistic= optimistic+1 if dc0`i'==1
}
replace optimistic=optimistic+1 if dc013==4
replace optimistic=optimistic+1 if dc016==4
gen optimistic_group1 = 1 if optimistic>=5 & optimistic!=. 
replace optimistic_group1=0 if optimistic<5
gen optimistic_group2 = 1 if optimistic>=4 & optimistic!=. 
replace optimistic_group2=0 if optimistic<4
gen optimistic_group3= 1 if optimistic>=6 & optimistic!=. 
replace optimistic_group3 =0 if optimistic<6 

replace optimistic=. if mi(dc009) & mi(dc010) & mi(dc011) & mi(dc012) & mi(dc013) & mi(dc014) & mi(dc015) & mi(dc016) & mi(dc017) & mi(dc018) 

/* Words recall */ // max: 20 points
gen cognitive_level1 = 0
forvalues i = 1(1)10 {
	replace cognitive_level1=cognitive_level1+1 if dc006s`i'==`i'
}
replace cognitive_level1=0 if dc006s11 == 11
replace cognitive_level1=. if mi(dc006s1) & mi(dc006s2) & mi(dc006s3) & mi(dc006s4) & mi(dc006s5) & mi(dc006s6) & mi(dc006s7) & mi(dc006s8) & mi(dc006s9) & mi(dc006s10) & mi(dc006s11)

gen cognitive_level2 = 0
forvalues i = 1(1)10 {
	replace cognitive_level2=cognitive_level2+1 if dc027s`i'==`i'
}
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


/* Age */ //ba002_1
rename ba002_1 birthyear  
rename ba002_2 birthmonth 
rename ba003 birth_type 
gen age=.
gen surveymonth=7
gen surveyyear=2011
replace age=round((surveyyear-birthyear)+(surveymonth-birthmonth)/12) if !mi(birthyear) & !mi(birthmonth) & birth_type==1 //solar calendar
replace age=round((surveyyear-birthyear)+(surveymonth-birthmonth-1)/12) if !mi(birthyear) & !mi(birthmonth) & birth_type==2 //lunar calendar
replace age=round((surveyyear-birthyear)+(surveymonth-birthmonth)/12) if !mi(birthyear) & !mi(birthmonth) & mi(birth_type) //birth type missing
replace age = ba004 if age==. 
order age, after(communityID)
replace age=. if age==.d | age==.r // totall 1251 have value
gen age_2 = age*age


/* Education */ // bd001

// schooling // 5 groups
tab bd001,m 
replace bd001=. if bd001==.d | bd001==.r
gen education = bd001

recode education (1=1) (2=2) (3/4=3) (5=4) (6/11=5),gen(education_group)
label define label_education 1 "Illiterate" 2 "Did not finish primary" 3 "Finished primary" 4 "Middle school" 5 "High school and above"
label values education_group label_education
tab education_group, m
label variable education_group "Education Group"

**Define Education dummy: Middle school and above // 2 groups

gen edu_midabove=(education_group>=4) if !mi(education_group)
label var edu_midabove "Middle School and Above"
label def edu_midabove_lab 0 "Below Middle School" 1 "Middle school and above"
label values edu_midabove edu_midabove_lab // totall 1243 have value


/* Gender */
replace rgender=. if rgender==.r
gen gender=rgender 
gen female=gender-1


/* smoke drink*/
gen smoking=1 if da059==1
replace smoking=0 if da059==2 // totall 1212 have value

gen drinking= 0 if da069==1
replace drinking=1 if da069==2 | da069==3 | da067==1 | da067==2 // totall 1211 have value


keep ID communityID householdID age gender female ah_good health_status health_status_group  education education_group smoking drinking age_2 optimistic hypertension birthyear max_breathing mean_systolic qa017 max_systolic max_diastolic mean_diastolic optimistic_group2 optimistic_group1 optimistic_group3 cognitive_level Math_score province city city_eng urban_nbs
save $working_data/2011_main_y_control.dta, replace  //remain 1258



//d5
merge 1:1 ID using $raw_data/2014/family_information.dta, keepusing(ID d5) 
keep if _merge==3 // drop 21564
drop _merge // remain 73 (67 in regression)


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
save $working_data/2011_main_y_x_control.dta, replace // remain 73 (67 in regression)

keep ID smoking drinking
rename smoking smoking_2011
rename drinking drinking_2011
save $working_data/2011_smoking_drinking.dta, replace  



/******************** Rehression - 2011_Main ***************************/ 

use $working_data/2011_main_y_x_control.dta, clear 

xi: probit ah_good ce_good i.education_group age age_2 female 
mfx
est store childhood1
outreg2 [childhood1] using "$tables\2011_ah_good_ce_good.xls",replace

