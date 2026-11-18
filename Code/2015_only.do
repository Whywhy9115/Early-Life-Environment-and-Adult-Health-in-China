 /***************************** 2015 *****************************/ 

// born place 
use $raw_data/2015/Demographic_Background.dta, clear 
gen bornplace = .
replace bornplace = bb001
keep householdID ID bornplace

merge 1:1 ID using $raw_data/2013/Demographic_Background.dta, keepusing(ID householdID bb001)
drop if _merge==2
replace bornplace = bb001 if mi(bornplace) & !mi(bb001)
keep householdID bornplace ID
tab bornplace,m 

merge 1:1 ID using $raw_data/2011/Demographic_Background_temp.dta, keepusing(ID householdID bb001)
drop if _merge==2
replace bornplace = bb001 if mi(bornplace) & !mi(bb001)
keep householdID ID bornplace
tab bornplace,m 
keep if bornplace==1 | bornplace==2
duplicates drop householdID, force
tab bornplace,m 
save $working_data/bornplace_2015, replace

/***************************** 2015 Main *****************************/ 


// real measure of hypertension
use $raw_data/2015/Demographic_Background.dta, clear //21095
merge 1:1 ID using $raw_data/2015/Health_Status_and_Functioning.dta
drop _merge
merge 1:1 ID using $raw_data/2015/Biomarker.dta, keepusing (ID pa002 qa003 qa007 qa011 qa017 qa016 qb002-qb005 qa004 qa008 qa012)
replace qa003=. if qa003==993 | qa003==.d | qa003== .r
replace qa007=. if qa007==993 | qa007==.d | qa007== .r
replace qa011=. if qa011==993 | qa011==.d | qa011== .r
replace qa004=. if qa004==.e | qa004==.d | qa004== .r
replace qa008=. if qa008==.e | qa008==.d | qa008== .r
replace qa012=. if qa012==.e | qa012==.d | qa012== .r

egen mean_systolic = rowmean(qa003 qa007 qa011)
gen max_systolic = max(qa003, qa007,qa011 )
egen mean_diastolic = rowmean(qa004 qa008 qa012)
gen max_diastolic = max(qa004, qa008,qa012)

gen max_breathing = max(qb002, qb003,qb004)
replace max_breathing=. if max_breathing==999 |max_breathing==993 
drop _merge

merge m:1 householdID using $working_data/bornplace_2015
keep if _merge==3
drop _merge

merge m:1 communityID using $raw_data/2013/PSU.dta, keepusing(communityID urban_nbs)
drop if _merge==2
drop _merge


merge 1:1 ID using $working_data/2015_unique.dta
keep if _merge==3 // drop 18150 
drop _merge // remain 2961


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

rename da007_1_ da007_1_2015
merge 1:1 ID using $working_data/health_status_and_functioning_2011_change.dta, keepusing(ID da007_1_)
drop if _merge==2
rename da007_1_ da007_1_2011
drop _merge 
merge 1:1 ID using $raw_data/2013/Health_Status_and_Functioning.dta, keepusing(ID da007_1_)
drop if _merge==2
rename da007_1_ da007_1_2013
drop _merge 

gen hypertension=0 if da007_1_2015==2 | da007_1_2013==2 | da007_1_2011==2 
replace hypertension = 1 if da007_1_2015==1 | da007_1_2013==1 | da007_1_2011==1
// total 2272 have value


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
replace cognitive_level1=0 if dc006s11 != 11 & dc027s11 != 11 

forvalues i = 1(1)10 {
	replace cognitive_level1=cognitive_level1+1 if dc006s`i'==`i'
}

replace cognitive_level1=0 if dc006s11 == 11
replace cognitive_level1=. if mi(dc006s1) & mi(dc006s2) & mi(dc006s3) & mi(dc006s4) & mi(dc006s5) & mi(dc006s6) & mi(dc006s7) & mi(dc006s8) & mi(dc006s9) & mi(dc006s10) & mi(dc006s11)


gen cognitive_level2=0
forvalues i = 1(1)10 {
	replace cognitive_level2=cognitive_level2+1 if dc027s`i'==`i' 
}

replace cognitive_level2=. if mi(dc027s1) & mi(dc027s2) & mi(dc027s3) & mi(dc027s4) & mi(dc027s5) & mi(dc027s6) & mi(dc027s7) & mi(dc027s8) & mi(dc027s9) & mi(dc027s10)
egen cognitive_level = rowmean(cognitive_level1 cognitive_level2) 

tab cognitive_level,m


/* Math Problems */ // max 5+16 points
gen Math_score = 0 
replace Math_score = Math_score+1 if dc019 == 93
replace Math_score = Math_score+1 if dc020 == 86
replace Math_score = Math_score+1 if dc021 == 79
replace Math_score = Math_score+1 if dc022 == 72
replace Math_score = Math_score+1 if dc023 == 65


replace Math_score = Math_score+1 if dc031_w3_1=="5"
replace Math_score = Math_score+1 if dc031_w3_2=="10"
replace Math_score = Math_score+1 if dc031_w3_3=="4"


replace Math_score = Math_score+1 if dc032_w3_1=="4"
replace Math_score = Math_score+1 if dc032_w3_2=="3"
replace Math_score = Math_score+1 if dc032_w3_3=="14"


replace Math_score = Math_score+1 if dc033_w3_1=="4"
replace Math_score = Math_score+1 if dc033_w3_2=="13"
replace Math_score = Math_score+1 if dc033_w3_3=="2"


replace Math_score = Math_score+1 if dc034_w3_1=="9"
replace Math_score = Math_score+1 if dc034_w3_2=="5"
replace Math_score = Math_score+1 if dc034_w3_3=="15"


replace Math_score = Math_score+1 if dc035_w3_1=="6"
replace Math_score = Math_score+1 if dc035_w3_2=="12"
replace Math_score = Math_score+1 if dc035_w3_3_1=="9"
replace Math_score = Math_score+1 if dc035_w3_3_2=="9"


gen Math_1=0
replace Math_1 = Math_1+1 if dc031_w3_1=="5"
replace Math_1 = Math_1+1 if dc031_w3_2=="10"
replace Math_1 = Math_1+1 if dc031_w3_3=="4"

gen Math_2=0 if Math_1==0
replace Math_2 = Math_2+1 if  dc032_w3_1 == "4"
replace Math_2 = Math_2+1 if  dc032_w3_2 == "3"
replace Math_2 = Math_2+1 if  dc032_w3_3 == "14"

gen Math_3=0 if Math_1==1
replace Math_3 = Math_3+2 if  dc033_w3_1 == "4"
replace Math_3 = Math_3+2 if  dc033_w3_2 == "13"
replace Math_3 = Math_3+2 if  dc033_w3_3 == "2"

gen Math_4=0 if Math_1==2
replace Math_4 = Math_4+3 if  dc034_w3_1 == "9"
replace Math_4 = Math_4+3 if  dc034_w3_2 == "5"
replace Math_4 = Math_4+3 if  dc034_w3_3 == "15"

gen Math_5=0 if Math_1==3
replace Math_5 = Math_5+4 if  dc035_w3_1 == "6"
replace Math_5 = Math_5+4 if  dc035_w3_2 == "12"
replace Math_5 = Math_5+4 if  dc035_w3_3_1 == "9"
replace Math_5 = Math_5+4 if  dc035_w3_3_2 == "9"

destring dc032_w3_1, replace 
destring dc032_w3_2, replace 
destring dc032_w3_3, replace 

replace Math_2 =. if mi(dc032_w3_1) & mi(dc032_w3_2) & mi(dc032_w3_3)

gen MM =.
forvalues i =2(1)5{
	replace MM = Math_1+Math_`i' if !mi(Math_`i')
}


destring Math_score, replace



/* Age */ 
gen year=2015
gen birthyear = ba004_w3_1
replace birthyear= ba002_1 if  ba002==2

gen birthmonth = ba004_w3_2
replace birthmonth = ba002_2 if ba002==2

rename ba003 birth_type 

gen age=.
gen surveymonth=7
gen surveyyear=2015
replace age=round((surveyyear-birthyear)+(surveymonth-birthmonth)/12) if !mi(birthyear) & !mi(birthmonth) & birth_type==1 //solar calendar
replace age=round((surveyyear-birthyear)+(surveymonth-birthmonth-1)/12) if !mi(birthyear) & !mi(birthmonth) & birth_type==2 //lunar calendar
replace age=round((surveyyear-birthyear)+(surveymonth-birthmonth)/12) if !mi(birthyear) & !mi(birthmonth) & mi(birth_type) //birth type missing

order age, after(communityID)

gen age_group1 = age
recode age_group1 (min/44=.)(45/54=1)(55/64=2)(65/200=3)
label define age_grou1_label 1 "45-54" 2 "55-64" 3 "65+",replace
label values age_group1 age_grou1_label
label variable age_group1 "Age_group"

gen age_2 = age*age

/* Education */ 

// bd001_w2_4 
drop bd014
gen education = bd001_w2_4

recode education (1=1) (2=2) (3/4=3) (5=4) (6/11=5),gen(education_group)
label define label_education 1 "Illiterate" 2 "Did not finish primary" 3 "Finished primary" 4 "Middle school" 5 "High school and above"
label values education_group label_education
tab education_group, m
label variable education_group "Education Group"

merge 1:1 ID using $working_data/edu_from2014 
drop if _merge==2
drop _merge
merge 1:1 ID using $working_data/edu_from2013
drop if _merge==2
drop _merge
merge 1:1 ID using $working_data/edu_from2011
drop if _merge==2
drop _merge


replace education=education_2011 if bd001_w2_4==12 
replace education=education_2013 if bd001_w2_4==12 & education_2013!=.
replace education=education_2014 if bd001_w2_4==12 & education_2014!=.

replace education_group=education_group_2011 if bd001_w2_4==12 
replace education_group=education_group_2013 if bd001_w2_4==12 & education_2013!=.
replace education_group=education_group_2014 if bd001_w2_4==12 & education_2014!=.

replace education=. if education==.d
replace education_group=. if education_group==.d


**Define Education dummy: Middle school and above

gen edu_midabove=(education_group>=4) if !mi(education_group)
label var edu_midabove "Middle School and Above"
label def edu_midabove_lab 0 "Below Middle School" 1 "Middle school and above"
label values edu_midabove edu_midabove_lab


/* Gender */
gen gender=ba000_w2_3
gen female=gender-1


/* smoke drink*/
gen smoking=1 if da059==1 
replace smoking=0 if da059==2
gen drinking= 0 if da069==1 // 104 missing
replace drinking=1 if da069==2 | da069==3 | da067==1 | da067==2

replace smoking =1 if zda059==1 
replace smoking =0 if zda059==2 //93 missing


keep ID communityID householdID age gender female ah_good health_status health_status_group  education education_group smoking drinking age_2 optimistic hypertension birthyear max_breathing mean_systolic qa017 max_systolic max_diastolic mean_diastolic optimistic_group_mean optimistic_group1 optimistic_group2 optimistic_group3 optimistic_group4 optimistic_group5 Math_score cognitive_level MM year urban_nbs health_status_group1 health_status_group2 health_status_group3 health_status_group age_group1

save $working_data/2015_main_y_control.dta, replace //2961


//d5
merge 1:1 ID using $raw_data/2014/family_information.dta, keepusing(ID d5 c4_a) 
keep if _merge==3 // drop 19041
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

save $working_data/2015_main_y_x_control.dta, replace 


keep ID smoking drinking
rename smoking smoking_2015
rename drinking drinking_2015
save $working_data/2015_smoking_drinking.dta, replace  


// TSP & Meteorological
use $working_data/2015_main_y_x_control.dta, clear

//merge m:1 communityID using $raw_data/charls_community_tsp.dta
merge m:1 communityID using $raw_data/charls_community_tsp_quartic.dta
//merge m:1 communityID using $raw_data/charls_community_tsp_cubic.dta
//merge m:1 communityID using $raw_data/charls_community_tsp_quadratic.dta

drop _merge

gen TSP=.
forvalues i = 1981(1)1995{
	replace TSP = pollution_`i' if birthyear==`i'
}

gen TSP_total =. 
replace TSP_total = 0 if TSP !=. 
forvalues i = 1981(1)1995{
	replace TSP_total = TSP_total + (pollution_`i')*(1/(1996-`i')) if birthyear<=`i'
}


save $working_data/2015_main_TSP.dta, replace 

// Meteorological data
use $working_data/meteo_annual_average_360_fix.dta, clear // all 316
duplicates drop city_eng, force // drop 1 : Yichun
merge 1:m city_eng using $working_data/2015_main_TSP.dta
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

save $working_data/2015_Main_All.dta, replace // all sh ce TSP Met data



/****************************** 2015 Child *****************************/ 
use $raw_data/2015/Child.dta, clear // offspring 34844
gen sample=.
replace sample= 1 if cb081==1 | cb081==2
replace sample= 0 if cb081!=1 & cb081!=2
tostring childID, replace
replace childID = householdID + childID
merge 1:1 childID using $working_data/ChildID_2013.dta
drop if _merge==2 
drop _merge
replace sample = 1 if sample_2013==1 & cb081==1 
replace sample = 1 if sample_2013==1 & mi(cb081)
replace sample = 1 if cb081==3
keep if sample == 1

merge m:1 householdID using $working_data/bornplace_2015
keep if _merge==3
drop _merge

merge m:1 communityID using $raw_data/2013/PSU.dta, keepusing(communityID urban_nbs)
drop if _merge==2
drop _merge

save $working_data/Child_2015.dta, replace

use $working_data/2015_unique.dta, clear
duplicates drop householdID, force
merge 1:m householdID using $working_data/Child_2015.dta
keep if _merge==3
drop _merge //5116 useful


/*********** 2015 Child-Construction *************/ 

// Self Comment of Your Life  

// alive  cb063_w3_1 
//  cb063_w3_3 少数民族 (cb063_w3_4)// 具体


// cb069 income

gen health_status=1 if cb063_w3_1==5
replace health_status=2 if cb063_w3_1==4
replace health_status=3 if cb063_w3_1==3
replace health_status=4 if cb063_w3_1==2
replace health_status=5 if cb063_w3_1==1

recode health_status (1/2=1) (3=2) (4/5=3), gen(health_status_group)
label define label_health 1 "Bad" 2 "Fine" 3 "Good" 
label values health_status_group label_health
tab health_status_group,m 
label variable health_status Adult_health_status

gen ah_good=(health_status==5|health_status==4) if !mi(health_status_group)
lab var ah_good "Adult Health is Good?"
lab def ah_good 0 "Poor" 1 "Good"
lab values ah_good ah_good
tablist ah_good,sort(v) 
tab ah_good,m

gen health_status_group1=(health_status==3|health_status==4|health_status==5) if !mi(health_status_group)
gen health_status_group2=(health_status==4|health_status==5) if !mi(health_status_group)
gen health_status_group3=(health_status==5) if !mi(health_status_group)



// Income Y
gen ah_income=(cb069==5|cb069==6|cb069==7|cb069==8|cb069==9|cb069==10|cb069==11|cb069==12) if !mi(cb069)
lab var ah_income "Adult Income is high?"
lab def ah_income 0 "Poor" 1 "Good"
lab values ah_income ah_income
tablist ah_income,sort(v) 
tab ah_income,m


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
lab var ce_good "Child Environment Good or VG?"
lab def ce_good 0 "NG P" 1 "G VG", replace
lab values ce_good ce_good
tablist ce_good,sort(v)

// 
gen ce_financial=(c4_a==1|c4_a==2|c4_a==3) if !mi(d5)
lab var ce_financial "Childhood financial Good or VG?"
lab def ce_financial 0 "NG P" 1 "G VG", replace
lab values ce_financial ce_financial



// education group 
gen education = cb052_w3
recode education (1=1) (2=2) (3/4=3) (5=4) (6/11=5),gen(education_group)
label define label_education 1 "Illiterate" 2 "Did not finish primary" 3 "Finished primary" 4 "Middle school" 5 "High school and above"
label values education_group label_education
tab education_group, m
label variable education_group "Education Group"

// age

replace age= 2015-byear
gen age_2 = age*age
gen year=2015
// gender
gen female=(gender-1)

gen age_group1 = age
recode age_group1 (min/44=.)(45/54=1)(55/64=2)(65/200=3)
label define age_grou1_label 1 "45-54" 2 "55-64" 3 "65+",replace
label values age_group1 age_grou1_label
label variable age_group1 "Age_group"

keep ID householdID communityID ah_good health_status education_group age age_2 female byear ce_good ce_financial ah_income year urban_nbs health_status_group1 health_status_group2 health_status_group3 health_status_group
save $working_data/2015_child_d5.dta, replace 

// PSU TSP
//merge m:1 communityID using $raw_data/charls_community_tsp.dta
merge m:1 communityID using $raw_data/charls_community_tsp_quartic.dta
//merge m:1 communityID using $raw_data/charls_community_tsp_cubic.dta
//merge m:1 communityID using $raw_data/charls_community_tsp_quadratic.dta

drop _merge

gen TSP=.
forvalues i = 1981(1)1995{
	replace TSP = pollution_`i' if byear==`i'
}

gen TSP_total =. 
replace TSP_total = 0 if TSP !=. 
forvalues i = 1981(1)1995{
	replace TSP_total = TSP_total + (pollution_`i')*(1/(1996-`i')) if byear<=`i'
}



save $working_data/2015_child_TSP.dta, replace 

// Meteorological data
use $working_data/meteo_annual_average_360_fix.dta, clear // all 316
duplicates drop city_eng, force // drop 1 : Yichun
merge 1:m city_eng using $working_data/2015_child_TSP.dta
drop _merge
gen temperature=.
gen sea_level = .
gen wind_speed = .
forvalues i = 1981(1)1995{
	replace temperature = air_temperature_ave`i' if byear==`i'
	replace sea_level = sea_level_pressure_ave`i' if byear==`i'
	replace wind_speed = wind_speed_ave`i' if byear==`i'
}



gen temperature_total=0 if temperature !=. 
gen sea_level_total = 0 if sea_level !=. 
gen wind_speed_total = 0 if wind_speed !=. 

forvalues i = 1981(1)1995{
	replace temperature_total = temperature_total + (air_temperature_ave`i')*(1/(1996-`i')) if byear<=`i'
	replace sea_level_total = sea_level_total + (sea_level_pressure_ave`i')*(1/(1996-`i')) if byear<=`i'
	replace wind_speed_total = wind_speed_total + (wind_speed_ave`i')*(1/(1996-`i')) if byear<=`i'
	
}



save $working_data/2015_Child_All.dta, replace 
/*

/******************** Rehression - 2015_Child ***************************/ 

use $working_data/2015_Child_All.dta, clear 

xi: probit ah_income ce_good i.education_group age age_2 female 
mfx
est store childhood1
xi: probit ah_good ce_good i.education_group age age_2 female 
mfx
est store childhood2 
outreg2 [childhood1 childhood2] using "$tables\2015_ah_good_ce_good.xls",replace


xi: probit ah_good TSP_total i.education_group age age_2 female temperature_total urban_nbs, cluster(communityID) 
mfx
est store TSP1

xi: probit ah_income TSP_total i.education_group age age_2 female temperature_total, cluster(communityID) 
mfx
est store TSP2
outreg2 [TSP1 TSP2] using "$tables\2015_ah_good_TSP.xls",replace


xi: ivprobit ah_good (TSP_total= sea_level_total wind_speed_total) i.education_group age age_2 female temperature_total urban_nbs
est store iv1

xi: ivreg health_status (TSP_total= sea_level_total wind_speed_total) i.education_group age age_2 female temperature_total urban_nbs, cluster(communityID)
est store iv2

outreg2 [iv1 iv2] using "$tables\2015_ah_good_TSP_iv.xls",replace




