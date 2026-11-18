
/*********************************** 2018 -  Variables ***************************************/

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


// TSP 
use $raw_data/2013/PSU.dta ,clear // 450 observations
keep communityID province city urban_nbs
replace city="哈尔滨市" if  city=="哈尔滨" 
merge m:1 city using $working_data/TSP_100.dta 
drop _merge 
drop if communityID=="" // drop 43 (_merge==2)
save $working_data/PSU_TSP.dta, replace 
keep communityID province city urban_nbs
save $working_data/province_city.dta, replace 


use $working_data/PSU_TSP.dta, clear 
reshape long y_@ /*
*/ , i(communityID) j(m)
label var m "year order from 1981 to 1995"
tostring m,replace
//gen K = city+communityID+m 
gen K = communityID+city+m
keep communityID K y_ urban_nbs
//duplicates drop M, force
save $working_data/city_TSP.dta, replace // 6750
drop if y_==. // drop 4107


use $raw_data/2013/PSU.dta ,clear
keep communityID urban_nbs
save $working_data/urban_nbs.dta, replace 



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

use $raw_data/2011/demographic_background.dta, clear //17705
replace householdID = householdID + "0"
replace ID = householdID + substr(ID,-2,2)
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

// Education variable 
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

//2011 education
use $raw_data/2011/demographic_Background.dta, clear
replace householdID = householdID + "0"
replace ID = householdID + substr(ID,-2,2)
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







/***********2011 main part (childhood environment + TSP) ***********/


//real born city/province

use $raw_data/2011/PSU.dta, clear
keep communityID province 
gen province_number=""
replace province_number = substr(communityID,1,2)
duplicates drop province, force 
gen real_province=province
keep province_number real_province
save $working_data/2011_real_province.dta, replace

// born place-bb001 / PSU

use $raw_data/2011/demographic_background.dta, clear //17705
merge 1:1 ID using $raw_data/2011/biomarkers.dta, keepusing(ID pa002 qa003 qa007 qa011 qa017 qb002-qb005 qa004 qa008 qa012)
drop _merge
replace qa003=. if qa003==993 | qa003==.d | qa003== .r
replace qa007=. if qa007==993 | qa007==.d | qa007== .r
replace qa011=. if qa011==993 | qa011==.d | qa011== .r

replace qa004=. if qa004==.e | qa004==.d | qa004== .r
replace qa008=. if qa008==.e | qa008==.d | qa008== .r
replace qa012=. if qa012==.e | qa012==.d | qa012== .r

gen mean_systolic = (qa003+qa007+qa011)/3
gen mean_diastolic = (qa004+qa008+qa012)/3
gen max_systolic = max(qa003, qa007,qa011)
gen max_diastolic = max(qa004, qa008,qa012)

//replace mean_systolic=. if qa017!= 5
gen breathing= qb002
replace breathing = qb003 if qb003>qb002 & qb003>qb004
replace breathing = qb004 if qb004>qb002 & qb004>qb003
replace breathing=. if qb005!=1 | breathing==999 |breathing==993 | breathing==.d | breathing==.e
replace householdID = householdID + "0"
replace ID = householdID + substr(ID,-2,2)
merge 1:1 ID using $working_data/2011_unique.dta
keep if _merge==3 // drop 16447
drop _merge
save $working_data/2011_main_temp.dta, replace // remian 1258 

use $raw_data/2011/health_status_and_functioning.dta, clear //17596
replace householdID = householdID + "0"
replace ID = householdID + substr(ID,-2,2)
save $working_data/health_status_and_functioning_2011_change.dta, replace 
merge m:1 communityID using $working_data/urban_nbs.dta 
drop _merge
merge 1:1 ID using $working_data/2011_unique.dta
keep if _merge==3 // drop 16408
drop _merge
merge 1:1 ID using $working_data/2011_main_temp.dta
drop _merge // remain 1258


/* Born-place */ 

replace bb001=. if bb001==.d | bb001==.r
gen province_number=bb001_3 // real province
merge m:1 province_number using $working_data/2011_real_province.dta, keepusing(province_number real_province)
drop if _merge==2
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

/* Words recall */ // max: 20 points
gen cognitive_level = 0
forvalues i = 1(1)10 {
	replace cognitive_level=cognitive_level+1 if dc006s`i'==`i'
}
replace cognitive_level=. if dc006s11 == 11

forvalues i = 1(1)10 {
	replace cognitive_level=cognitive_level+1 if dc027s`i'==`i'
}
gen mean_cognitive_level = cognitive_level/20
/* Math Problems */ // max 5 points
gen Math_score = 0 
replace Math_score = Math_score+1 if dc019 == 93
replace Math_score = Math_score+1 if dc020 == 86
replace Math_score = Math_score+1 if dc021 == 79
replace Math_score = Math_score+1 if dc022 == 72
replace Math_score = Math_score+1 if dc023 == 65

gen mean_Math_score = Math_score/5

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

// schooling 
tab bd001,m 
replace bd001=. if bd001==.d | bd001==.r
gen education = bd001

recode education (1=1) (2=2) (3/4=3) (5=4) (6/11=5),gen(education_group)
label define label_education 1 "Illiterate" 2 "Did not finish primary" 3 "Finished primary" 4 "Middle school" 5 "High school and above"
label values education_group label_education
tab education_group, m
label variable education_group "Education Group"

**Define Education dummy: Middle school and above

gen edu_midabove=(education_group>=4) if !mi(education_group)
label var edu_midabove "Middle School and Above"
label def edu_midabove_lab 0 "Below Middle School" 1 "Middle school and above"
label values edu_midabove edu_midabove_lab // totall 1243 have value


/* Gender */
replace rgender=. if rgender==.r
gen gender=rgender 
gen female=gender-1

/* smoke drink*/
gen smoke=1 if da059==1
replace smoke=0 if da059==2 // totall 1212 have value

gen drink= 0 if da069==1
replace drink=1 if da069==2 | da069==3 | da067==1 | da067==2 // totall 1211 have value


keep ID communityID householdID age gender female ah_good health_status health_status_group  education education_group smoke drink age_2 optimistic hypertension real_province birthyear breathing urban_nbs mean_systolic qa017 max_systolic max_diastolic mean_diastolic optimistic_group2 optimistic_group1 optimistic_group3 cognitive_level Math_score mean_Math_score mean_cognitive_level
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


// PSU
use $working_data/2011_main_y_control.dta, clear // 1258
merge m:1 communityID using  $raw_data/2013/PSU.dta, keepusing(communityID province province_eng city city_eng)
keep if _merge==3
drop _merge
gen year = birthyear
replace year = year-1980
order year, after(birthyear)
replace year=. if year<=0 | year>=16
tostring year, replace 
gen K = communityID + city + year
merge m:1 K using $working_data/city_TSP.dta 
keep if _merge==3 // 0 observation 
//merge m:1 city using $(TSP)
save $working_data/2011_main_TSP.dta, replace // remain 0




/***********2011 family part (childhood environment + TSP) ***********/

use $raw_data/2011/hhmember.dta, clear // xdzm 17989
replace householdID = householdID + "0"
replace ID = householdID + substr(ID,-2,2)
//merge m:1 ID using $working_data/2011_unique.dta
//keep if _merge==3 // drop 17603
//drop _merge
merge m:1 ID using $raw_data/2014/family_information.dta, keepusing(ID d5) //d5 (xdzm)
keep if _merge ==3 //drop 21557
drop _merge
save $working_data/2011_childhood_environment.dta, replace //remain 65 (15065)

drop d5
gen year = a003_1-1980
replace year=. if year<=0 | year>=16
tostring year, replace 
merge m:1 communityID using  $raw_data/2013/PSU.dta, keepusing(communityID province province_eng city city_eng)
gen K = communityID + city + year
drop _merge
merge m:1 K using $working_data/city_TSP.dta
keep if _merge==3 
drop _merge
save $working_data/2011_xdzm_TSP.dta, replace 
// remain 26 -13 useful TSP (remain 6142 - 1910 useful TSP)


use $raw_data/2011/child.dta, clear // offspring 27398
replace householdID = householdID + "0"
replace ID = householdID + substr(ID,-2,2)
//merge m:1 ID using $working_data/2011_unique.dta
//keep if _merge==3 // drop 25877
//drop _merge
gen year = cb051_1-1980
replace year=. if year<=0 | year>=16
tostring year, replace 
merge m:1 communityID using  $raw_data/2013/PSU.dta, keepusing(communityID province province_eng city city_eng) // remain 2182
gen K = communityID + city + year
drop _merge
merge m:1 K using $working_data/city_TSP.dta
keep if _merge==3 // drop 8077
drop _merge
save $working_data/2011_offspring_TSP.dta, replace // remain 448

// Combine all  TSP data
use $working_data/2011_xdzm_TSP, clear 
append using $working_data/2011_offspring_TSP.dta
save $working_data/2011_TSP.dta, replace // 474 -165 useful TSP

// Construction Part ce_good
use $working_data/2011_childhood_environment.dta, clear //65

// Self Comment of Your Life ?

/* Childhood Environment */
gen child_environment= 1 if d5 == 4
replace child_environment = 2 if d5==3
replace child_environment = 3 if d5==2
replace child_environment = 4 if d5==1

gen ce_good=(d5==1|d5==2) if !mi(d5)

// schooling 

forvalues i = 1(1)6{
	replace a015=2 if a014==`i' & a015==. 
}
forvalues i = 7(1)10{
	replace a015=5 if a014==`i' & a015==. 
}

forvalues i = 11(1)13{
	replace a015=6 if a014==`i' & a015==. 
}
forvalues i = 14(1)16{
	replace a015=7 if a014==`i' & a015==. 
}
forvalues i = 17(1)21{
	replace a015=8 if a014==`i' & a015==. 
}
replace a015=10 if a014==23 & a015==. 
replace a015=11 if a014==24 & a015==. 

gen education = a015
replace education =. if education==999 | education==997
recode education (1=1) (2=2) (3/4=3) (5=4) (6/11=5),gen(education_group)
label define label_education 1 "Illiterate" 2 "Did not finish primary" 3 "Finished primary" 4 "Middle school" 5 "High school and above"
label values education_group label_education
tab education_group, m
label variable education_group "Education Group"

/* Age */

gen age= 2011-a003_1

gen age_2 = age*age

/* Gender */
gen gender=a002
gen female=(gender-1)
save $working_data/2011_childhood_environment_construction.dta, replace 

// Construction Part TSP
use $working_data/2011_TSP.dta, clear // 474 

// Self Comment of Your Life ?

// schooling 

forvalues i = 1(1)6{
	replace a015=2 if a014==`i' & a015==. 
	replace cb060=2 if cb059==`i' & cb060==. 
}
forvalues i = 7(1)10{
	replace a015=5 if a014==`i' & a015==. 
	replace cb060=5 if cb059==`i' & cb060==. 
}

forvalues i = 11(1)13{
	replace a015=6 if a014==`i' & a015==. 
	replace cb060=6 if cb059==`i' & cb060==. 
}
forvalues i = 14(1)16{
	replace a015=7 if a014==`i' & a015==. 
	replace cb060=7 if cb059==`i' & cb060==. 
}
forvalues i = 17(1)21{
	replace a015=8 if a014==`i' & a015==. 
	replace cb060=8 if cb059==`i' & cb060==. 
}
replace cb060=8 if cb059==22  & cb060==. 
replace a015=10 if a014==23 & a015==. 
replace cb060=10 if cb059==23  & cb060==. 
replace a015=11 if a014==24 & a015==. 
replace cb060=11 if cb059==24  & cb060==. 

gen education = a015
replace education=cb060 if education==. 
replace education =. if education==999 | education==997
recode education (1=1) (2=2) (3/4=3) (5=4) (6/11=5),gen(education_group)
label define label_education 1 "Illiterate" 2 "Did not finish primary" 3 "Finished primary" 4 "Middle school" 5 "High school and above"
label values education_group label_education
tab education_group, m
label variable education_group "Education Group"



/* Age */

gen age= 2011-a003_1
replace age = 2011-cb051_1 if age==.

gen age_2 = age*age

/* Gender */
gen gender=a002
replace gender=cb049 if gender==. 
gen female=(gender-1)

save $working_data/2011_TSP_construction.dta, replace // 474


/*********************** Combine all 2011 *****************************/ 

use $working_data/2011_main_y_x_control.dta, clear
append using $working_data/2011_childhood_environment_construction.dta
save $working_data/2011_all_childhood_environment, replace // remian 138 (15138)


use $working_data/2011_main_TSP.dta, clear 
append using $working_data/2011_TSP_construction.dta
rename y_ TSP
save $working_data/2011_all_TSP, replace // remain 474-165 useful TSP (15433-4680 useful)


/***********2013 main part (childhood environment + TSP) ***********/

// /  /  /  / born place-bb001 / (self-hyper) / PSU

// real measure of hypertension

use $raw_data/2013/Demographic_Background.dta, clear // 18605
merge 1:1 ID using $raw_data/2013/Biomarker.dta, keepusing(ID pa002 qa003 qa007 qa011 qa017 qb002-qb005 qa004 qa008 qa012)
gen mean_systolic = (qa003+qa007+qa011)/3
gen max_systolic = max(qa003, qa007,qa011 )
gen mean_diastolic = (qa004+qa008+qa012)/3
gen max_diastolic = max(qa004, qa008,qa012)
gen breathing= qb002
replace breathing = qb003 if qb003>qb002 & qb003>qb004
replace breathing = qb004 if qb004>qb002 & qb004>qb003
replace breathing=. if qb005!=1 | breathing==999 |breathing==993 | breathing==.d | breathing==.e
drop _merge
merge 1:1 ID using $raw_data/2013/Health_Status_and_Functioning.dta
drop _merge
merge m:1 communityID using $working_data/urban_nbs.dta 
keep if _merge==3
drop _merge
merge 1:1 ID using $working_data/2013_unique.dta
keep if _merge==3 // 17062 drop
drop _merge // remain 1548

/* Born place */

/* Type of born place */

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


/* Self-reported Hypertension */

//gen hypertension = 1 if da007_1_==1
//replace hypertension=0 if da007_1_==2
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
gen optimistic_group1 = 1 if optimistic>=5 & optimistic!=. 
replace optimistic_group1=0 if optimistic<5
gen optimistic_group2= 1 if optimistic>=4 & optimistic!=. 
replace optimistic_group2 =0 if optimistic<4
gen optimistic_group3= 1 if optimistic>=6 & optimistic!=. 
replace optimistic_group3 =0 if optimistic<6



/* Words recall */ // max: 20 points
gen cognitive_level = .
replace cognitive_level=0 if dc006_1_s11 != 11 & dc027s11 != 11 
forvalues i = 1(1)10 {
	replace cognitive_level=cognitive_level+1 if dc006_1_s`i'==`i'
}

forvalues i = 1(1)10 {
	replace cognitive_level=cognitive_level+1 if dc027s`i'==`i' 
}

gen mean_cognitive_level = cognitive_level/20

/* Math Problems */ // max 5 points
gen Math_score = 0 
replace Math_score = Math_score+1 if dc019 == 93
replace Math_score = Math_score+1 if dc020 == 86
replace Math_score = Math_score+1 if dc021 == 79
replace Math_score = Math_score+1 if dc022 == 72
replace Math_score = Math_score+1 if dc023 == 65

gen mean_Math_score = Math_score/5



/* Age */
gen birthyear = zba002_1 
replace birthyear=ba002_1 if ba002_1 !=. 

gen age = 2013-birthyear

order age, after(communityID)

gen age_2 = age*age



/* Education */ // bd001

// schooling 

gen education = bd001_w2_4 
replace education = bd001_w2_3 if bd001_w2_4==12
replace education = zbd001 if bd001_w2_4==. | bd001_w2_3==.

recode education (1=1) (2=2) (3/4=3) (5=4) (6/11=5),gen(education_group)
label define label_education 1 "Illiterate" 2 "Did not finish primary" 3 "Finished primary" 4 "Middle school" 5 "High school and above"
label values education_group label_education
tab education_group, m
label variable education_group "Education Group"

merge 1:1 ID using $working_data/edu_from2011
drop if _merge==2
drop _merge 

replace education=education_2011 if zbd001==.
replace education_group=education_group_2011 if zbd001==.

replace education=. if education==.d
replace education_group=. if education_group==.d //472 missing



**Define Education dummy: Middle school and above

gen edu_midabove=(education_group>=4) if !mi(education_group)
label var edu_midabove "Middle School and Above"
label def edu_midabove_lab 0 "Below Middle School" 1 "Middle school and above"
label values edu_midabove edu_midabove_lab


/* Gender */
gen gender=xrgender 
gen female=gender-1



/* smoke drink*/
gen smoke =1 if da059==1
replace smoke=0 if da059==2

gen drink= 0 if da069==1
replace drink=1 if da069==2 | da069==3 | da067==1 | da067==2

keep ID communityID householdID age gender female ah_good health_status health_status_group  education education_group smoke drink age_2 optimistic hypertension birthyear breathing urban_nbs mean_systolic qa017 max_systolic max_diastolic mean_diastolic optimistic_group2 optimistic_group1 optimistic_group3 cognitive_level Math_score mean_Math_score mean_cognitive_level

save $working_data/2013_main_y_control.dta, replace // 1548 



//d5
merge 1:1 ID using $raw_data/2014/family_information.dta, keepusing(ID d5) 
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
save $working_data/2013_main_y_x_control.dta, replace //remain 591 (374 in regression)




// PSU
use $working_data/2013_main_y_control.dta, clear 
merge m:1 communityID using  $raw_data/2013/PSU.dta, keepusing(communityID province province_eng city city_eng)
keep if _merge==3 // drop 52
drop _merge
gen year = birthyear
replace year = year-1980
order year, after(birthyear)
replace year=. if year<=0 | year>=16
tostring year, replace 
gen K = communityID + city+ year
merge m:1 K using $working_data/city_TSP.dta 
keep if _merge==3 // 0 observation 
//merge m:1 city using $(TSP)
save $working_data/2013_main_TSP.dta, replace // remain 2(1 useful TSP)


/***********2013 family part (childhood environment + TSP) ***********/

use $raw_data/2013/Other_HHmember.dta, clear //xdzm - 9410
//merge m:1 ID using $working_data/2013_unique.dta
//keep if _merge==3 // drop 9936
//drop _merge
merge m:1 ID using $raw_data/2014/family_information.dta, keepusing(ID d5) //d5 (xdzm)
keep if _merge ==3 // drop 20727 (17696)
drop _merge
save $working_data/2013_childhood_environment.dta, replace //remain 295 (8448)


drop d5
gen byear=za003_1
replace byear=a003_1 if byear==. 
gen year = byear-1980
replace year=. if year<=0 | year>=16
tostring year, replace 
merge m:1 communityID using  $raw_data/2013/PSU.dta, keepusing(communityID province province_eng city city_eng)
gen K = communityID + city + year
drop _merge
merge m:1 K using $working_data/city_TSP.dta
keep if _merge==3 // remain 74 (2128)
drop _merge
save $working_data/2013_xdzm_TSP.dta, replace 


use $raw_data/2013/Child.dta, clear // 31348
//merge m:1 ID using $working_data/2013_unique.dta
//keep if _merge==3 // drop 29184 remain 2818
//drop _merge
gen year = cb051_1-1980
replace year=. if year<=0 | year>=16
tostring year, replace 
merge m:1 communityID using  $raw_data/2013/PSU.dta, keepusing(communityID province province_eng city city_eng)
gen K = communityID + city + year
drop _merge
merge m:1 K using $working_data/city_TSP.dta
keep if _merge==3 // drop 8586 
//remain 563 (10232)
drop _merge
save $working_data/2013_offspring_TSP.dta, replace 


// Combine all  TSP data
use $working_data/2013_xdzm_TSP, clear 
append using $working_data/2013_offspring_TSP.dta
save $working_data/2013_TSP.dta, replace // 637 (230 useful)


// Construction Part ce_good
use $working_data/2013_childhood_environment.dta, clear

// Self Comment of Your Life  ???

/* Childhood Environment */
gen child_environment= 1 if d5 == 4
replace child_environment = 2 if d5==3
replace child_environment = 3 if d5==2
replace child_environment = 4 if d5==1

gen ce_good=(d5==1|d5==2) if !mi(d5)

// schooling 

forvalues i = 1(1)6{
	replace a015=4 if a014==`i' & a015==. 
}

forvalues i = 7(1)9{
	replace a015=5 if a014==`i' & a015==. 
}

forvalues i = 17(1)19{
	replace a015=8 if a014==`i' & a015==. 
}

replace a015=6 if a014==11 & a015==. 
replace a015=6 if a014==13 & a015==. 

gen education = a015
replace education =. if education==999 | education==997
recode education (1=1) (2=2) (4=3) (5=4) (6/9=5),gen(education_group)
label define label_education 1 "Illiterate" 2 "Did not finish primary" 3 "Finished primary" 4 "Middle school" 5 "High school and above"
label values education_group label_education
tab education_group, m
label variable education_group "Education Group"


/* Age */

gen age= 2013-za003_1
replace age = 2013-a003_1 if age==.
gen age_2 = age*age

/* Gender */
gen gender=a002
replace gender=za002 if gender==.
gen female=(gender-1)

save $working_data/2013_childhood_environment_construction.dta, replace 



// Construction Part TSP
use $working_data/2013_TSP.dta, clear



// schooling 

forvalues i = 1(1)6{
	replace a015=4 if a014==`i' & a015==. 
}

forvalues i = 7(1)9{
	replace a015=5 if a014==`i' & a015==. 
}

forvalues i = 17(1)19{
	replace a015=8 if a014==`i' & a015==. 
	replace cb060=8 if cb059==`i' & cb060==. 
}

replace a015=6 if a014==11 & a015==. 
replace a015=6 if a014==13 & a015==. 
replace cb060=6 if cb059==13 & cb060==. 
replace cb060=7 if cb059==15 & cb060==. 
replace cb060=7 if cb059==16 & cb060==. 
replace cb060=8 if cb059==20 & cb060==. 
replace cb060=8 if cb059==22 & cb060==. 
replace cb060=10 if cb059==23 & cb060==. 
replace cb060=11 if cb059==24 & cb060==. 

gen education = a015
replace education=cb060 if education==. 
replace education =. if education==999 | education==997
recode education (1=1) (2=2) (4=3) (5=4) (6/11=5),gen(education_group)
label define label_education 1 "Illiterate" 2 "Did not finish primary" 3 "Finished primary" 4 "Middle school" 5 "High school and above"
label values education_group label_education
tab education_group, m
label variable education_group "Education Group"




/* Age */

replace age= 2013-za003_1 if age==.
replace age = 2013-a003_1 if age==.

gen age_2 = age*age

/* Gender */
replace gender=a002 if gender==.
replace gender=za002 if gender==.

gen female=(gender-1)

save $working_data/2013_TSP_construction.dta, replace 


/*********************** Combine all 2013 *****************************/ 

use $working_data/2013_main_y_x_control.dta, clear
append using $working_data/2013_childhood_environment_construction.dta
save $working_data/2013_all_childhood_environment, replace //remain 886 (9039)


use $working_data/2013_main_TSP.dta, clear 
append using $working_data/2013_TSP_construction.dta
rename y_ TSP
save $working_data/2013_all_TSP, replace // remain 639 (12362)


/***********2015 main part (childhood environment + TSP) ***********/

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

gen mean_systolic = (qa003+qa007+qa011)/3
gen max_systolic = max(qa003, qa007,qa011 )
gen mean_diastolic = (qa004+qa008+qa012)/3
gen max_diastolic = max(qa004, qa008,qa012)

gen breathing= qb002
replace breathing = qb003 if qb003>qb002 & qb003>qb004
replace breathing = qb004 if qb004>qb002 & qb004>qb003
replace breathing=. if qb005!=1 | breathing==999 |breathing==993 | breathing==.d | breathing==.e
drop _merge
merge m:1 communityID using $working_data/urban_nbs.dta 
drop _merge
merge 1:1 ID using $working_data/2015_unique.dta
keep if _merge==3 // drop 18150 
drop _merge // remain 2961

/* Born place */ 


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
gen optimistic_group1 = 1 if optimistic>=5 & optimistic!=. 
replace optimistic_group1=0 if optimistic<5
gen optimistic_group2 = 1 if optimistic>=5 & optimistic!=. 
replace optimistic_group2=0 if optimistic<5
gen optimistic_group3= 1 if optimistic>=6 & optimistic!=. 
replace optimistic_group3 =0 if optimistic<6


/* Words recall */ // max: 20 points
gen cognitive_level = .
replace cognitive_level=0 if dc006s11 != 11 & dc027s11 != 11 

forvalues i = 1(1)10 {
	replace cognitive_level=cognitive_level+1 if dc006s`i'==`i'
}

forvalues i = 1(1)10 {
	replace cognitive_level=cognitive_level+1 if dc027s`i'==`i' 
}

gen mean_cognitive_level = cognitive_level/20


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

destring Math_score, replace
gen mean_Math_score = Math_score/21


/* Age */ 
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
gen smoke=1 if da059==1
replace smoke=0 if da059==2

gen drink= 0 if da069==1
replace drink=1 if da069==2 | da069==3 | da067==1 | da067==2


keep ID communityID householdID age gender female ah_good health_status health_status_group  education education_group smoke drink age_2 optimistic hypertension birthyear breathing urban_nbs mean_systolic qa017 max_systolic max_diastolic mean_diastolic optimistic_group1 optimistic_group2 optimistic_group3 Math_score mean_Math_score cognitive_level mean_cognitive_level

save $working_data/2015_main_y_control.dta, replace //2961

//d5
merge 1:1 ID using $raw_data/2014/family_information.dta, keepusing(ID d5) 
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
save $working_data/2015_main_y_x_control.dta, replace 


// PSU
use $working_data/2015_main_y_control.dta, clear // 2961
merge m:1 communityID using  $raw_data/2013/PSU.dta, keepusing(communityID province province_eng city city_eng)
keep if _merge==3 // drop 6
drop _merge
gen year = birthyear
replace year = year-1980
order year, after(birthyear)
replace year=. if year<=0 | year>=16
tostring year, replace 
gen K = communityID + city + year
merge m:1 K using $working_data/city_TSP.dta 
keep if _merge==3 // 5 remain (2 useful)
//merge m:1 city using $(TSP)
save $working_data/2015_main_TSP.dta, replace 


/***********2015 family part (childhood environment + TSP) ***********/


use $raw_data/2015/Sibling.dta, clear // xdzm 46242
//merge m:1 ID using $working_data/2015_unique.dta
//keep if _merge==3 // remain 6163
//drop _merge
merge m:1 ID using $raw_data/2014/family_information.dta, keepusing(ID d5) //d5 (xdzm)
keep if _merge ==3 // remain 5042 (42709)
drop _merge
save $working_data/2015_childhood_environment.dta, replace 

drop d5
gen year = byear-1980
replace year=. if year<=0 | year>=16
tostring year, replace 
merge m:1 communityID using  $raw_data/2013/PSU.dta, keepusing(communityID province province_eng city city_eng)
gen K = communityID + city + year
drop _merge
merge m:1 K using $working_data/city_TSP.dta
keep if _merge==3 //remain 18 (205)
drop _merge
save $working_data/2015_xdzm_TSP.dta, replace 


use $raw_data/2015/Child.dta, clear // offspring 34844
//merge m:1 ID using $working_data/2015_unique.dta
//keep if _merge==3 //remain 5177
//drop _merge
gen year = byear-1980
replace year=. if year<=0 | year>=16
tostring year, replace 
merge m:1 communityID using  $raw_data/2013/PSU.dta, keepusing(communityID province province_eng city city_eng)
gen K = communityID + city + year
drop _merge
merge m:1 K using $working_data/city_TSP.dta
keep if _merge==3 //remain 1578 (13051)
drop _merge
save $working_data/2015_offspring_TSP.dta, replace 

// Combine all  TSP data
use $working_data/2015_xdzm_TSP, clear 
append using $working_data/2015_offspring_TSP.dta
save $working_data/2015_TSP.dta, replace // 1596 (13069-3932 useful)


// Construction Part ce_good
use $working_data/2015_childhood_environment.dta, clear

// Self Comment of Your Life 

gen health_status=1 if cc012_w3==5
replace health_status=2 if cc012_w3==4
replace health_status=3 if cc012_w3==3
replace health_status=4 if cc012_w3==2
replace health_status=5 if cc012_w3==1 

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

/* Childhood Environment */
gen child_environment= 1 if d5 == 4
replace child_environment = 2 if d5==3
replace child_environment = 3 if d5==2
replace child_environment = 4 if d5==1

gen ce_good=(d5==1|d5==2) if !mi(d5)


// schooling 
gen education = cc003_w3
replace education =. if education==999 | education==997
recode education (1=1) (2=2) (3/4=3) (5=4) (6/11=5),gen(education_group)
label define label_education 1 "Illiterate" 2 "Did not finish primary" 3 "Finished primary" 4 "Middle school" 5 "High school and above"
label values education_group label_education
tab education_group, m
label variable education_group "Education Group"


/* Age */

gen age= 2015-byear

gen age_2 = age*age

/* Gender */

gen female=(gender-1)
save $working_data/2015_childhood_environment_construction.dta, replace


// Construction Part TSP
use $working_data/2015_TSP.dta, clear

// Self Comment of Your Life 

gen health_status=1 if cc012_w3==5 | cb063_w3_1==5
replace health_status=2 if cc012_w3==4 | cb063_w3_1==4
replace health_status=3 if cc012_w3==3 | cb063_w3_1==3
replace health_status=4 if cc012_w3==2 | cb063_w3_1==2
replace health_status=5 if cc012_w3==1 | cb063_w3_1==1

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

// schooling 
gen education = cc003_w3
replace education=cb052_w3 if education==. 
replace education =. if education==999 | education==997
recode education (1=1) (2=2) (3/4=3) (5=4) (6/11=5),gen(education_group)
label define label_education 1 "Illiterate" 2 "Did not finish primary" 3 "Finished primary" 4 "Middle school" 5 "High school and above"
label values education_group label_education
tab education_group, m
label variable education_group "Education Group"


/* Age */

replace age= 2015-byear

gen age_2 = age*age

/* Gender */

gen female=(gender-1)

save $working_data/2015_TSP_construction.dta, replace 

/*********************** Combine all 2015 *****************************/ 

use $working_data/2015_main_y_x_control.dta, clear
append using $working_data/2015_childhood_environment_construction.dta
save $working_data/2015_all_childhood_environment, replace //7228 (44895)


use $working_data/2015_main_TSP.dta, clear 
append using $working_data/2015_TSP_construction.dta
rename y_ TSP
save $working_data/2015_all_TSP, replace //1601-549 useful TSP (13261-3959 useful TSP)




/***********2018 main part (childhood environment + TSP) ***********/

use $raw_data/2018/Demographic_Background.dta, clear

merge 1:1 ID using $raw_data/2018/Cognition.dta
tab _merge
drop _merge
 
merge 1:1 ID using $raw_data/2018/Health_Status_and_Functioning
tab _merge
drop _merge
merge m:1 communityID using $working_data/urban_nbs.dta 
drop _merge
 

// Self Comment of Your Life 

gen health_status=1 if da002==5 
replace health_status=2 if da002==4 
replace health_status=3 if da002==3
replace health_status=4 if da002==2 
replace health_status=5 if da002==1 

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


/*********************************** Cognitive Function  ******************************/

/****** Words recall - 40 points total -- cognitive_level *******/

gen cognitive_level = 0
forvalues i = 1(1)10 {
	replace dc028_w4_s`i' = 0 if dc028_w4_s`i'==.
	replace dc029_w4_s`i' = 0 if dc029_w4_s`i'==.
	replace dc030_w4_s`i' = 0 if dc030_w4_s`i'==.
	replace dc047_w4_s`i' = 0 if dc047_w4_s`i'==. 
	replace cognitive_level = cognitive_level+1 if dc028_w4_s`i' !=0
	replace cognitive_level = cognitive_level+1 if dc029_w4_s`i' !=0
	replace cognitive_level = cognitive_level+1 if dc030_w4_s`i' !=0
	replace cognitive_level = cognitive_level+1 if dc047_w4_s`i' !=0
}

//wr101_intro = 1yes 2no.  dc028_w4_s1-dc028_w4_s12.   dc029_w4_s1-dc029_w4_s12. dc030_w4_s1-dc030_w4_s12

replace cognitive_level = . if wr101_intro==2
tab cognitive_level


replace cognitive_level=. if dc028_w4_s12==12 | dc029_w4_s12==12 | dc030_w4_s12==12
/*. group 
gen cognitive_group = 1 if wr101_intro== 1
replace cognitive_group = 0 if cognitive_level > 5
tab cognitive_group
*/

gen mean_cognitive_level = cognitive_level/40

/***************** MAth problems --- Math_score ****************/ 
gen Math_score = 0 


replace Math_score = Math_score+1 if dc029_w3_1 == 6
replace Math_score = Math_score+1 if  dc030_w3_1 == 5

replace Math_score = Math_score+1 if  dc031_w3_1 == 9
replace Math_score = Math_score+1 if  dc031_w3_2 == 10 
replace Math_score = Math_score+1 if  dc031_w3_3 ==4

replace Math_score = Math_score+1 if  dc032_w3_1 == 4
replace Math_score = Math_score+1 if  dc032_w3_2 == 3
replace Math_score = Math_score+1 if  dc032_w3_3 == 14

replace Math_score = Math_score+1 if  dc033_w3_1 == 4
replace Math_score = Math_score+1 if  dc033_w3_2 == 13
replace Math_score = Math_score+1 if  dc033_w3_3 == 2

replace Math_score = Math_score+1 if  dc034_w3_1 == 9
replace Math_score = Math_score+1 if  dc034_w3_2 == 5
replace Math_score = Math_score+1 if  dc034_w3_3 == 15

replace Math_score = Math_score+1 if  dc035_w3_1 == 6
replace Math_score = Math_score+1 if  dc035_w3_2 == 12
replace Math_score = Math_score+1 if  dc035_w3_3_1 == 9
replace Math_score = Math_score+1 if  dc035_w3_3_2 == 9
 

replace Math_score=. if dc031_w4_0!= 1
replace Math_score=. if dc029_w4_1 == 6 | dc029_w4_1==9

gen mean_Math_score = Math_score/18

gen Math_series_score=0
replace Math_series_score=18 if dc035_w3_3_2 == 9 & Math_series_score==0
replace Math_series_score=17 if dc035_w3_3_1 == 9 & Math_series_score==0
replace Math_series_score=16 if dc035_w3_2 == 12 & Math_series_score==0
replace Math_series_score=15 if dc035_w3_1 == 6 & Math_series_score==0
replace Math_series_score=14 if dc034_w3_3 == 15 & Math_series_score==0
replace Math_series_score=13 if dc034_w3_2 == 5 & Math_series_score==0
replace Math_series_score=12 if dc034_w3_1 == 9 & Math_series_score==0
replace Math_series_score=11 if dc033_w3_3 == 2 & Math_series_score==0
replace Math_series_score=10 if dc033_w3_2 == 13 & Math_series_score==0
replace Math_series_score=9 if dc033_w3_1 == 4 & Math_series_score==0
replace Math_series_score=8 if dc032_w3_3 == 14 & Math_series_score==0
replace Math_series_score=7 if dc032_w3_2 == 3 & Math_series_score==0
replace Math_series_score=6 if dc032_w3_1 == 4 & Math_series_score==0

replace Math_series_score=5 if dc031_w3_3 == 4 & Math_series_score==0
replace Math_series_score=4 if dc031_w3_2 == 10 & Math_series_score==0
replace Math_series_score=3 if dc031_w3_1 == 9 & Math_series_score==0
replace Math_series_score=2 if dc030_w3_1 == 5 & Math_series_score==0
replace Math_series_score=1 if dc029_w3_1 == 6 & Math_series_score==0


 
 
// Wordlist  Recognition
//wrong: 48 50 53 55 56 59 61 62 64.  --5 no
//right: 49 51 52 54 57 58 60 63 65 66 ---1 yes
gen word_recognition = 0
foreach i in 49 51 52 54 57 58 60 63 65 66{
	replace word_recognition = word_recognition+1 if dc0`i'_w4 ==1
}
foreach i in 48 50 53 55 56 59 61 62 64{
	replace word_recognition = word_recognition+1 if dc0`i'_w4 ==5
}
replace word_recognition=. if wre_intro == 2
 
 



/* Depression / Optimistic*/

gen depression = 0
replace depression= depression+1 if dc009==1
foreach i in 10 11 12 14 15 17 18{
	replace depression= depression+1 if dc0`i'==1
}
replace depression=depression+1 if dc013==4
replace depression=depression+1 if dc016==4

gen optimistic = depression
gen optimistic_group1 = 1 if optimistic>=5 & optimistic!=. 
replace optimistic_group1 =0 if optimistic<5
gen optimistic_group2 = 1 if optimistic>=4 & optimistic!=. 
replace optimistic_group2 =0 if optimistic<4
gen optimistic_group3= 1 if optimistic>=6 & optimistic!=. 
replace optimistic_group3 =0 if optimistic<6

/* disabilities */
gen disabilities=0
forvalues i=1(1)5 {
	replace disabilities = disabilities+1 if da005_`i'_==1
}
gen disabilities_group = 1 // 1 is no disabilities
replace disabilities_group = 0 if disabilities!=0

/*Diseases  */
gen disease_level = 0
forvalues i = 1(1)14 {
	replace disease_level = disease_level + 1 if da007_`i'_== 1
}
gen disease_group = 1 // 1 is no diseases
replace disease_group = 0 if  disease_level!=0


/* Hypertension */
rename da007_1_ da007_1_2018
merge 1:1 ID using $working_data/health_status_and_functioning_2011_change.dta, keepusing(ID da007_1_)
drop if _merge==2
drop _merge
rename da007_1_ da007_1_2011

merge 1:1 ID using $raw_data/2013/Health_Status_and_Functioning.dta, keepusing(ID da007_1_)
drop if _merge==2
drop _merge
rename da007_1_ da007_1_2013

merge 1:1 ID using $raw_data/2015/Health_Status_and_Functioning.dta, keepusing(ID da007_1_)
drop if _merge==2
drop _merge
rename da007_1_ da007_1_2015

gen hypertension=0 if da007_1_2015==2 | da007_1_2013==2 | da007_1_2011==2 | da007_1_2018==2
replace hypertension = 1 if da007_1_2015==1 | da007_1_2013==1 | da007_1_2011==1 | da007_1_2018==1

// total 19239 have value 



//gen hypertension_3 = 1 if da007_1_ == 1 | mean_systolic>=140 


// schooling 
tab bd001_w2_4,m 
gen education = bd001_w2_4

replace education =. if education==999 | education==997
recode education (1=1) (2=2) (3/4=3) (5=4) (6/11=5),gen(education_group)
label define label_education 1 "Illiterate" 2 "Did not finish primary" 3 "Finished primary" 4 "Middle school" 5 "High school and above"
label values education_group label_education
tab education_group, m
label variable education_group "Education Group"


**Define Education dummy: Middle school and above

gen edu_midabove=(education_group>=4) if !mi(education_group)
label var edu_midabove "Middle School and Above"
label def edu_midabove_lab 0 "Below Middle School" 1 "Middle school and above"
label values edu_midabove edu_midabove_lab


/* Age */
rename ba004_w3_1 birthyear  
rename ba004_w3_2 birthmonth 
rename ba003 birth_type 

replace birthyear = ba002_1 if ba002_1 !=.
replace birthmonth = ba002_2 if ba002_2 !=.


gen age=.
gen surveymonth=7
gen surveyyear=2018
replace age=round((surveyyear-birthyear)+(surveymonth-birthmonth)/12) if !mi(birthyear) & !mi(birthmonth) & birth_type==1 //solar calendar
replace age=round((surveyyear-birthyear)+(surveymonth-birthmonth-1)/12) if !mi(birthyear) & !mi(birthmonth) & birth_type==2 //lunar calendar
replace age=round((surveyyear-birthyear)+(surveymonth-birthmonth)/12) if !mi(birthyear) & !mi(birthmonth) & mi(birth_type) //birth type missing

order age, after(communityID)

/* Age Group */
//1
replace age=. if age>150
recode age (0/40=1)(41/50=2)(51/60=3)(61/70=4)(71/200=5), gen (age_group2)
label define age_group_label1  1 "40-" 2 "41-50" 3 "51-60" 4 "61-70" 5 "71+" , replace
label values age_group2 age_group_label1
label variable age_group2 "age_group"
tab age_group2, m
//2
gen age_group3=age
recode age_group3 (0/44=.) (45/47=1) (48/50=2) (51/53=3) (54/56=4) (57/59=5) (60/62=6) (63/65=7) (66/68=8) ///
           (69/71=9) (72/74=10) (75/77=11) (78/80=12) (81/120=13)
label define age_3  1 "45-47" 2 "48-50" 3 "51-53" 4 "54-56" 5 "57-59" 6 "60-62" 7 "63-65" ///
                       8 "66-68" 9 "69-71" 10 "72-74" 11 "75-77" 12 "78-80" 13 "81+"
label values age_group3 age_3
tab age_group3,m
label variable age_group3 "Age Group"
//3 
gen age_group1 = age
recode age_group1 (min/44=.)(45/54=1)(55/64=2)(65/200=3)
label define age_grou1_label 1 "45-54" 2 "55-64" 3 "65+",replace
label values age_group1 age_grou1_label
label variable age_group1 "Age_group"
// age_sqare
gen age_2 = age*age


/* Gender */
rename ba000_w2_3 gender

bysort householdID: egen gender_max=max(gender)
list householdID gender gender_max in 1/6
replace gender=1 if gender_max==2 & mi(gender)
replace gender=2 if gender_max==1 & mi(gender)
tab gender,m


gen female=(gender-1)
order female, after(age)
drop gender_max ba*

keep ID communityID householdID age gender female ah_good health_status health_status_group  education education_group age_2 optimistic hypertension cognitive_level Math_score Math_series_score word_recognition birthyear urban_nbs optimistic_group1 optimistic_group2 optimistic_group3 mean_Math_score mean_cognitive_level

save $working_data/2018_main_y_control.dta, replace // 19817

//d5
merge 1:1 ID using $raw_data/2014/family_information.dta, keepusing(ID d5) 
keep if _merge==3 // drop 5621
drop _merge // remain 17324
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
save $working_data/2018_main_y_x_control.dta, replace // 17324


// PSU
use $working_data/2018_main_y_control.dta, clear 
merge m:1 communityID using  $raw_data/2013/PSU.dta, keepusing(communityID province province_eng city city_eng)
keep if _merge==3
drop _merge
gen year = birthyear
replace year = year-1980
order year, after(birthyear)
replace year=. if year<=0 | year>=16
tostring year, replace 
gen K = communityID + city + year
merge m:1 K using $working_data/city_TSP.dta 
keep if _merge==3 // remain 24 (9 useful) 
//merge m:1 city using $(TSP)
drop _merge
save $working_data/2018_main_TSP.dta, replace 



/***********2018 family part (childhood environment + TSP) ***********/


// Sisters Brothers
use $raw_data/2018/Family_Information.dta, clear 
//use $working_data/2018_Background_combine.dta, clear 
keep ID householdID communityID xsibgender* xsibbirth* cc003_w3_1_-cc003_w3_13_ cc012_w3_1_-cc012_w3_14_ cc006_w3_2_1_-cc006_w3_2_14_ 
drop xsibgender_s_* xsibbirth_s_*
save $working_data/2018_xdzm_temp1.dta, replace //11628


use $raw_data/2018/Family_Information.dta, clear 
//use $working_data/2018_Background_combine.dta, clear 
keep ID householdID communityID xsibgender_s_* xsibbirth_s_* cc003_w3_s_* cc012_w3_s_* cc006_w3_2_s_*
save $working_data/2018_xdzm_temp2.dta, replace //11628

//Offspring 
use $raw_data/2018/Family_Information.dta, clear 
//use $working_data/2018_Background_combine.dta, clear 
keep ID householdID communityID cb052_w3_1_-cb052_w3_15_ cb053_*  cb069_* ///
	cb063_w3_1_* cb063_w3_6_* xchildbirth* xchildgender* zchildedu* cb052_w4_* 
//cb063_w3_1_i (ah_good) // xchildbirth_i_ birth year (age)
forvalue i = 1(1)14 {
	replace zchildedu_`i'_ = cb052_w3_`i'_ if cb052_w4_`i'_==2
}
save $working_data/2018_offspring_temp.dta, replace //11628



// xdzm1 merge with childhood environment / TSP
use $working_data/2018_xdzm_temp1.dta, clear
merge 1:1 ID using $raw_data/2014/family_information.dta, keepusing(ID d5) //d5 (xdzm)
keep if _merge ==3 // remain 10347
drop _merge
reshape long xsibgender_@_ xsibbirth_@_ cc003_w3_@_ cc012_w3_@_ cc006_w3_2_@_  /*
*/ ,i(householdID) j(xdzmID)
label var xdzmID "ID of Respondents‘ Sibling"
save $working_data/2018_xdzm_d5_1.dta, replace //144858

drop d5
gen year = xsibbirth__-1980
replace year=. if year<=0 | year>=16
tostring year, replace 
merge m:1 communityID using  $raw_data/2013/PSU.dta, keepusing(communityID province province_eng city city_eng)
gen K = communityID + city + year
drop _merge
merge m:1 K using $working_data/city_TSP.dta
keep if _merge==3 // drop 151153 
drop _merge
save $working_data/2018_xdzm_TSP_1.dta, replace //remain 238


// xdzm2 merge with childhood environment / TSP
use $working_data/2018_xdzm_temp2.dta, clear
merge 1:1 ID using $raw_data/2014/family_information.dta, keepusing(ID d5) //d5 (xdzm)
keep if _merge ==3 //drop 11386
drop _merge
reshape long xsibgender_s_@_ xsibbirth_s_@_ cc003_w3_s_@_ cc012_w3_s_@_ cc006_w3_2_s_@_ /*
*/ ,i(householdID) j(xdzmID)
label var xdzmID "ID of Respondents‘ Sibling"
save $working_data/2018_xdzm_d5_2.dta, replace // remain 156205

drop d5
gen year = xsibbirth_s__-1980
replace year=. if year<=0 | year>=16
tostring year, replace 
merge m:1 communityID using  $raw_data/2013/PSU.dta, keepusing(communityID province province_eng city city_eng)
gen K = communityID + city + year
drop _merge
merge m:1 K using $working_data/city_TSP.dta
keep if _merge==3 // remain 291 (42 useful TSP)
drop _merge 
save $working_data/2018_xdzm_TSP_2.dta, replace 



// offspring merge with TSP 
use $working_data/2018_offspring_temp.dta, replace 
drop cb052_w4_* cb052_w3_1_-cb052_w3_15_
reshape long  cb053_@_ cb063_@_ cb091_w4_@_ zchildedu_@_ /*
*/ cb069_@_ cb063_w3_1_@_ cb063_w3_6_@_ xchildbirth_@_ xchildgender_@_ /*
*/ , i(householdID) j(childID)
label var childID "ID of Respondents‘ offspring" //186048
gen year = xchildbirth__-1980
replace year=. if year<=0 | year>=16
tostring year, replace 
merge m:1 communityID using  $raw_data/2013/PSU.dta, keepusing(communityID province province_eng city city_eng)
gen K = communityID + city + year
drop _merge
merge m:1 K using $working_data/city_TSP.dta 
keep if _merge==3 //drop 174674 
drop _merge
save $working_data/2018_offspring_TSP.dta, replace //13089 (3844 useful TSP)


// Combine all ce_good & TSP data
use $working_data/2018_xdzm_d5_1.dta, clear
append using $working_data/2018_xdzm_d5_2.dta
save $working_data/2018_childhood_environment.dta, replace // 300063


use $working_data/2018_xdzm_TSP_1, clear 
append using $working_data/2018_xdzm_TSP_2
append using $working_data/2018_offspring_TSP
save $working_data/2018_TSP.dta, replace // 13618 (3919 useful information)

// Construction Part ce_good
use $working_data/2018_childhood_environment.dta, clear

// Self Comment of Your Life 

gen health_status=1 if cc012_w3_s__==5 | cc012_w3__==5
replace health_status=2 if cc012_w3_s__==4 | cc012_w3__==4
replace health_status=3 if cc012_w3_s__==3 | cc012_w3__==3
replace health_status=4 if cc012_w3_s__==2 | cc012_w3__==2
replace health_status=5 if cc012_w3_s__==1 | cc012_w3__==1 

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

/* Childhood Environment */
gen child_environment= 1 if d5 == 4
replace child_environment = 2 if d5==3
replace child_environment = 3 if d5==2
replace child_environment = 4 if d5==1

gen ce_good=(d5==1|d5==2) if !mi(d5)


// schooling 
gen education = .
replace education = cc003_w3__ if education==.
replace education = cc003_w3_s__ if education==.
replace education =. if education==999 | education==997
recode education (1=1) (2=2) (3/4=3) (5=4) (6/11=5),gen(education_group)
label define label_education 1 "Illiterate" 2 "Did not finish primary" 3 "Finished primary" 4 "Middle school" 5 "High school and above"
label values education_group label_education
tab education_group, m
label variable education_group "Education Group"


/* Age */

gen age=.
replace age=(2018-xsibbirth_s__) if age==.
replace age=(2018-xsibbirth__) if age==.
gen age_2 = age*age

/* Gender */
gen gender=.
replace gender=xsibgender_s__ if gender==. 
replace gender=xsibgender__ if gender==. 
gen female=(gender-1)

save $working_data/2018_childhood_environment_construction.dta, replace 


// Construction Part TSP
use $working_data/2018_TSP.dta, clear

// Self Comment of Your Life 
gen health_status=1 if cc012_w3__==5 | cb063_w3_1__==5 | cc012_w3_s__==5 
replace health_status=2 if cc012_w3__==4 | cb063_w3_1__==4 | cc012_w3_s__==4 
replace health_status=3 if cc012_w3__==3 | cb063_w3_1__==3 | cc012_w3_s__==3
replace health_status=4 if cc012_w3__==2 | cb063_w3_1__==2 | cc012_w3_s__==2
replace health_status=5 if cc012_w3__==1 | cb063_w3_1__==1 | cc012_w3_s__==1 

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


// schooling 
gen education = .
replace education = cc003_w3__ if education==.
replace education = zchildedu__ if education==.
replace education = cc003_w3_s__ if education==.
replace education =. if education==999 | education==997
recode education (1=1) (2=2) (3/4=3) (5=4) (6/11=5),gen(education_group)
label define label_education 1 "Illiterate" 2 "Did not finish primary" 3 "Finished primary" 4 "Middle school" 5 "High school and above"
label values education_group label_education
tab education_group, m
label variable education_group "Education Group"

/* Age */

gen age=.
replace age=(2018-xchildbirth__) if age==.
replace age=(2018-xsibbirth_s__) if age==.
replace age=(2018-xsibbirth__) if age==.
gen age_2 = age*age

/* Gender */
gen gender=.
replace gender=xchildgender__ if gender==. 
replace gender=xsibgender_s__ if gender==. 
replace gender=xsibgender__ if gender==. 
gen female=(gender-1)
save $working_data/2018_TSP_construction.dta, replace 

/*********************** Combine all 2018 *****************************/ 

use $working_data/2018_main_y_x_control.dta, clear
append using $working_data/2018_childhood_environment_construction.dta
save $working_data/2018_all_childhood_environment, replace // 317387

use $working_data/2018_main_TSP.dta, clear 
append using $working_data/2018_TSP_construction.dta
rename y_ TSP
save $working_data/2018_all_TSP, replace //13642(3928 useful TSP)


/*************************** Combine ALL ****************************/ 

use $working_data/2018_all_childhood_environment, clear
append using $working_data/2015_all_childhood_environment
append using $working_data/2013_all_childhood_environment
append using $working_data/2011_all_childhood_environment
save $working_data/All_childhood_environment, replace //386459

use $working_data/2018_all_TSP, clear
append using $working_data/2015_all_TSP
append using $working_data/2013_all_TSP
append using $working_data/2011_all_TSP
save $working_data/All_TSP, replace // 16356-4873 useful TSP (54698-16235 useful TSP )


/********************************* Regression ********************************/

use $working_data/All_childhood_environment, clear  


/******************** Breathing Function ***********/ 
gen b=0 if breathing<300
replace b=1 if breathing>=300 & breathing!=. // the higher the value the better

xi: probit b i.female*i.ce_good age age_2 i.education_group 
mfx
est store breath1
xi: probit b ce_good age age_2 i.education_group female
mfx
est store breath2
outreg2 [breath1 breath2] using "$tables\breath_ce.xls",replace


/******************** Hypertension Function *****************/ 

// 3 times real measure -- mean & max
gen high=1 if mean_systolic>=140 & mean_systolic !=. 
replace high=0 if mean_systolic<140
replace high=1 if mean_diastolic>=90 & mean_diastolic !=. 
replace high=0 if mean_diastolic<90

gen high2=1 if max_systolic>=140 & max_systolic !=.
replace high2=0 if max_systolic<140
replace high2=1 if max_diastolic>=90 & max_diastolic !=. 
replace high2=0 if max_diastolic<90

// both real measure and self-report = yes == 1 (max)
gen both = 1 if hypertension==1 & high2==1
replace both=0 if hypertension==0 | high2==0
replace both= 1 if hypertension==1 & high2==. //2018 

// both real measure and self-report = no == 0 (max)
gen both2 = 0 if hypertension==0 & high2==0
replace both2 =1 if hypertension==1 | high2==1
replace both2= 0 if hypertension==0 & high2==. //2018


xi: probit hypertension ce_good age age_2 i.education_group female smoke drink urban_nbs // only self-reported 
mfx
est store hyper
xi: probit high ce_good age age_2 i.education_group female smoke drink urban_nbs // only real- measure: mean of three
mfx
est store hyper1
xi: probit high2 ce_good age age_2 i.education_group female smoke drink urban_nbs // only real- measure: max of three
mfx
est store hyper2
xi: probit both ce_good age age_2 i.education_group female smoke drink urban_nbs // both have = yes
mfx
est store hyper3
xi: probit both2 ce_good age age_2 i.education_group female smoke drink urban_nbs // both no = no
mfx
est store hyper4
outreg2 [hyper hyper1 hyper2 hyper3 hyper4] using "$tables\hyper_.xls",replace


/******************** Cognitive Function *****************/ 

gen math = 1 if mean_Math_score>= 0.25 & mean_Math_score!=.
replace math = 0 if mean_Math_score < 0.25

gen word = 1 if mean_cognitive_level>= 0.41 & mean_cognitive_level!=.
replace word = 0 if mean_cognitive_level < 0.41

gen con_good1 = 1 if math==1 & word==1
replace con_good1 = 0 if math == 0 | word==0

gen con_good2 = 1 if math==1 | word==1
replace con_good2 = 0 if math == 0 & word==0


xi: reg cognitive_level ce_good age age_2 i.education_group female 
est store cognitive1
xi: reg Math_score ce_good age age_2 i.education_group female 
est store cognitive2
xi: reg mean_cognitive_level ce_good age age_2 i.education_group female 
est store cognitive3
xi: reg mean_Math_score ce_good age age_2 i.education_group female 
est store cognitive4

xi: probit word ce_good age age_2 i.education_group female 
mfx
est store cognitive5
xi: probit math ce_good age age_2 i.education_group female
mfx 
est store cognitive6

xi: probit con_good1 ce_good age age_2 i.education_group female 
mfx
est store cognitive7
xi: probit con_good2 ce_good age age_2 i.education_group female
mfx 
est store cognitive8

outreg2 [cognitive1 cognitive2 cognitive3 cognitive4 cognitive5 cognitive6 cognitive7 cognitive8] using "$tables\ah_good_ce_cognitive.xls",replace





/************* Self-reported health outcome****************/

gen hh = 1 if health_status==1 | health_status==2 | health_status==3
replace hh=2 if health_status==4
replace hh = 3 if health_status==5

//Table 2
xi: probit ah_good ce_good age age_2 i.education_group //2
mfx
est store self1

outreg2 [self1]using $tables\1_self_reported.xls, cttop(mfx2) replace excel dec(5)

//Table 3
xi: ologit hh ce_good age age_2 i.education_group female //3
mfx, predict(p outcome(1)) 
forvalues i = 2/3 {
    mfx, predict(p outcome(`i'))
}
mfx2,replace //mfx2 
est store self2

outreg2 [self2]using $tables\3_self_reported2.xls, cttop(mfx2) replace excel dec(5)


// Table 4
xi: ologit health_status ce_good age age_2 i.education_group female //5
mfx, predict(p outcome(1)) 
forvalues i = 2/5 {
    mfx, predict(p outcome(`i'))
}
mfx2,replace //mfx2 
est store self3

outreg2 [self3 ]using $tables\5_self_reported.xls, cttop(mfx2) replace excel dec(5)


/************* Optimistic emotion level ****************/
// Table 5
// Robustness check 
xi: reg optimistic ce_good age age_2 i.education_group female i.urban_nbs
est store depression1


xi: oprobit optimistic_group1 ce_good age age_2 i.education_group female i.urban_nbs
mfx
est store depression2

xi: oprobit optimistic_group2 ce_good age age_2 i.education_group female i.urban_nbs
mfx
est store depression3

xi: oprobit optimistic_group3 ce_good age age_2 i.education_group female i.urban_nbs
mfx
est store depression4

outreg2 [depression1 depression2 depression3 depression4] using "$tables\depression_2.xls",replace


/*
//Congnitive function //Table6

gen cognitive = cognitive_level+Math_series_score+word_recognition // Three aspects

bysort education_group: egen con_edu_group=mean(Math_series_score)
bysort education_group: egen con_edu_group2=sd(Math_series_score)

//bysort age_group2: egen con_edu_group3=mean(cognitive)
//bysort age_group2: egen con_edu_group4=sd(cognitive)

bysort education_group: egen con_edu_group5=mean(cognitive_level)
bysort education_group: egen con_edu_group6=sd(cognitive_level)


gen cog_score1 = (cognitive-con_edu_group)/con_edu_group2  // three with education_group
//gen cog_score2 = (cognitive-con_edu_group3)/con_edu_group4 // threev with age_group2
gen cog_score3 = (cognitive-con_edu_group5)/con_edu_group6 // words only with age_group2


xi: reg cognitive_level ce_good female age age_2 i.education_group // Total 3 parts
est store co1
xi: reg cognitive_level ce_good female age age_2 i.education_group i.optimistic // Total 3 parts
est store co2
/*
xi: reg cognitive_level ce_good female age age_2 i.education_group i.city // Total 3 parts
est store co3
xi: reg cognitive_level ce_good female age age_2 i.education_group i.province // Total 3 parts
est store co4
*/


reg Math_series_score ce_good age age_2 i.education_group female urban_nbs // only math 
est store co1
outreg2[co1] using "$tables\cognitive_function_struction.xls",replace



xi: reg cog_score1 i.child_environment female age age_2 i.education_group  // Total by - mean / sd .. eudcation group
est store co2

xi: reg cog_score2 ce_good female age age_2 i.education_group   // Total by - mean / sd .. age group
est store co3

xi: reg cog_score3 ce_good female age age_2 i.education_group   // Words only by - mean / sd .. age group
est store co4


outreg2[co1 co2 co3] using "$tables\cognitive_function_struction.xls",replace



// Table 7
xi: reg cognitive ce_good age age_2 i.education_group female
est store cogni1
/*
xi: reg cognitive ce_good age age_2 i.education_group female i.city_pinyin
est store cogni2
*/

outreg2 [cogni1 cogni2] using "$tables\.xls",replace

*/



use $working_data/All_TSP, clear 

// Table 8
xi: probit ah_good TSP age age_2 i.education_group female i.urban_nbs
mfx
est store TSP_self1

outreg2 [TSP_self1] using "$tables\ah_good__TSP.xls",replace








/*


/************* Disability ****************/

xi: reg disabilities ce_good age age_2 i.education_group female 
est store No_disability1

xi: probit disabilities_group ce_good age age_2 i.education_group female 
mfx
est store No_disability2

outreg2 [No_disability1 No_disability2 depression2 depression3 depression4] using "$tables\disability.xls",replace


xi: probit ah_good TSP age age_2 i.education_group female
mfx
est store TSP_self1
xi: probit ah_good TSP age age_2 i.education_group female i.city_pinyin
mfx
est store TSP_self2

outreg2 [TSP_self1 TSP_self2] using "$tables\ah_good__TSP.xls",replace



// Interaction with female grouup
xi: probit ah_good i.ce_good*female age age_2 i.education_group
mfx
est store intersect1 
xi: reg cognitive_level_3 i.ce_good*female age age_2 i.education_group
est store intersect3

outreg2 [intersect1 intersect3 ] using "$tables\ah_good_female*ch_good.xls",replace


// Interaction with female 
xi: reg health_status i.ce_good*female age age_2 i.education_group   
est store WA1

xi: reg depression i.ce_good*female age age_2 i.education_group  
est store WA2

outreg2[WA1 WA2] using "$tables\ah_good_age*ch_good.xls",replace





log close
