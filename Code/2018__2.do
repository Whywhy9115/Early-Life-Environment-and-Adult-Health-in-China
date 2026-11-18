
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


/*********** 2018 -  Health ***********/
/*
/* Combine data*/
use $raw_data/2018/Health_Status_and_Functioning.dta, clear

drop da008*
drop e*
replace da048=. if da048==997
save $working_data/2018_Health_combine.dta, replace
*/

/*********** 2018 -  Sample construction ***********/


// Background
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

use $raw_data/2011/demographic_background.dta, clear
replace householdID = householdID + "0"
replace ID = householdID + substr(ID,-2,2)
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


//age / ah_good / female / edu / born place-bb001 / (self-hyper) / PSU

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

use $raw_data/2011/demographic_background.dta, clear
replace householdID = householdID + "0"
replace ID = householdID + substr(ID,-2,2)
merge 1:1 ID using $working_data/2011_unique.dta
keep if _merge==3 
drop _merge
save $working_data/2011_main_temp.dta, replace

use $raw_data/2011/health_status_and_functioning.dta, clear
replace householdID = householdID + "0"
replace ID = householdID + substr(ID,-2,2)
merge 1:1 ID using $working_data/2011_unique.dta
keep if _merge==3 
drop _merge
merge 1:1 ID using $working_data/2011_main_temp.dta
keep if _merge==3 
drop _merge



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
tablist ah_good,sort(v)

/* Self-reported Hypertension */
replace da007_1_=. if da007_1_==.d | da007_1_==.r
gen hypertension = 1 if da007_1_==1
replace hypertension=0 if da007_1_==2

/* Optimistic */ 

gen optimistic = 0
replace optimistic= optimistic+1 if dc009==1
foreach i in 10 11 12 14 15 17 18{
	replace optimistic= optimistic+1 if dc0`i'==1
}
replace optimistic=optimistic+1 if dc013==4
replace optimistic=optimistic+1 if dc016==4
gen optimistic_group = 1 if optimistic>=5 & optimistic!=. 
replace optimistic_group=0 if optimistic<5


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
label values edu_midabove edu_midabove_lab


tab education, m
gen schooling=.
replace schooling=0 if education==1
replace schooling=4 if education==2
replace schooling=3 if education==3
replace schooling=6 if education==4
replace schooling=9 if education==5
replace schooling=12 if education==6
replace schooling=11 if education==7
replace schooling=14.5 if education==8
replace schooling=16 if education==9
replace schooling=18 if education==10
replace schooling=20 if education==11

egen schooling_group = cut(schooling), at(0,5,10,20)
egen schooling_group_3 = group(schooling_group)
label define schooling_group_label  1 "0-5" 2 "5-10" 3 "10+" , replace 
label values schooling_group_3 schooling_group_label
tab schooling_group_3, m
label var schooling_group_3 "Schooling year"
drop schooling_group

/* Gender */
replace rgender=. if rgender==.r
gen gender=rgender 
gen female=gender-1

/* smoke drink*/
gen smoke=1 if da059==1
replace smoke=0 if da059==2

gen drink= 0 if da069==1
replace drink=1 if da069==2 | da069==3 | da067==1 | da067==2


save $working_data/2011_main_y_control.dta, replace 


//d5
merge 1:1 ID using $raw_data/2014/family_information.dta, keepusing(ID d5) 
keep if _merge==3 
drop _merge
//keep all+d5
save $working_data/2011_main_y_x_control.dta, replace 


// PSU
use $working_data/2011_main_y_control.dta, clear 
merge m:1 communityID using  $raw_data/2013/PSU.dta, keepusing(communityID province province_eng city city_eng)
keep if _merge==3
drop _merge
gen year = birthyear
replace year = year-1980
order year, after(birthyear)
replace year=. if year<=0 | year>=16
tostring year, replace 
gen K = communityID + city_eng+ year
merge m:1 K using $working_data/city_TSP.dta 
keep if _merge==3 // 0 observation 
//merge m:1 city using $(TSP)
save $working_data/2011_main_TSP.dta, replace 



/***********2011 family part (childhood environment + TSP) ***********/



//2011 family offspring + family members
use $raw_data/2011/family_information.dta, clear
replace householdID = householdID + "0"
replace ID = householdID + substr(ID,-2,2)
merge 1:1 ID using $working_data/2011_unique.dta
keep if _merge==3 //offspring + xdzm(ce_good)
//age / ah_good / female / edu / born place-bb001 / (self-hyper) / PSU
save $working_data/2011_children_y_control.dta, replace 
//age / ah_good / female / edu / born place-bb001 / (self-hyper) / PSU
save $working_data/2011_xdzm_y_control.dta, replace 




// combine child environment
use $working_data/2011_xdzm_y_control.dta, clear 
merge 1:1 ID using $raw_data/2014/family_information.dta //d5 (xdzm)
//keep all+d5
reshape long
save $working_data/2011_family_x.dta, replace 



// combine TSP data
//TSP (children+xdzm)
use $working_data/2011_family_all_y_control.dta, clear 
merge m:1 city using $TSP

reshape long
save $working_data/2011_family_TSP.dta, replace 



// 2011 combine all //
// childhood environment
use $working_data/2011_main_y_x_control.dta
append using $working_data/2011_family_x.dta
save $working_data/2011_childhood_environment.dta

use $working_data/2011_main_TSP.dta, replace 
append using $working_data/2011_family_TSP.dta
save $working_data/2011_TSP.dta

/*
/***********2013 main part (childhood environment + TSP) ***********/

// /  /  /  / born place-bb001 / (self-hyper) / PSU


use $raw_data/2013/Demographic_Background.dta, clear
merge 1:1 ID using $working_data/2013_unique.dta
keep if _merge==3 
drop _merge
save $working_data/2013_main_temp.dta, replace

use $raw_data/2013/health_status_and_functioning.dta, clear
merge 1:1 ID using $working_data/2013_unique.dta
keep if _merge==3 
drop _merge
merge 1:1 ID using $working_data/2013_main_temp.dta
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


/* Self-reported Hypertension */

gen hypertension = 1 if da007_1_==1
replace hypertension=0 if da007_1_==2


/* Age */
gen birthyear = zba002_1 
replace birthyear=ba002_1 if ba002_1 !=. 

gen age = 2013-birthyear

order age, after(communityID)

gen age_2 = age*age



/* Education */ // bd001

// schooling 

gen education = zbd001

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


tab education, m
gen schooling=.
replace schooling=0 if education==1
replace schooling=4 if education==2
replace schooling=3 if education==3
replace schooling=6 if education==4
replace schooling=9 if education==5
replace schooling=12 if education==6
replace schooling=11 if education==7
replace schooling=14.5 if education==8
replace schooling=16 if education==9
replace schooling=18 if education==10
replace schooling=20 if education==11

egen schooling_group = cut(schooling), at(0,5,10,20)
egen schooling_group_3 = group(schooling_group)
label define schooling_group_label  1 "0-5" 2 "5-10" 3 "10+" , replace 
label values schooling_group_3 schooling_group_label
tab schooling_group_3, m
label var schooling_group_3 "Schooling year"
drop schooling_group



/* Gender */
gen gender=xrgender 
gen female=gender-1
save $working_data/2013_main_y_control.dta, replace 


//d5
merge 1:1 ID using $raw_data/2014/family_information.dta, keepusing(ID d5) 
keep if _merge==3 
drop _merge
//keep all+d5
save $working_data/2013_main_y_x_control.dta, replace 


// PSU
use $working_data/2013_main_y_control.dta, clear 
merge m:1 communityID using  $raw_data/2013/PSU.dta, keepusing(communityID province province_eng city city_eng)
keep if _merge==3
drop _merge
gen year = birthyear
replace year = year-1980
order year, after(birthyear)
replace year=. if year<=0 | year>=16
tostring year, replace 
gen K = communityID + city_eng+ year
merge m:1 K using $working_data/city_TSP.dta 
keep if _merge==3 // 0 observation 
//merge m:1 city using $(TSP)
save $working_data/2013_main_TSP.dta, replace 








/***********2015 main part (childhood environment + TSP) ***********/



/***********2018 main part (childhood environment + TSP) ***********/

*/



use $raw_data/2018/Demographic_Background.dta, clear
merge m:1 householdID using $raw_data/2018/Family_Information.dta 
tab _merge
drop if _merge!=3
drop _merge

merge 1:1 ID using $raw_data/2018/Cognition.dta
tab _merge
drop if _merge!=3
drop _merge

merge 1:1 ID using $working_data/Family_Information_from2014.dta // 5627 missing d5
tab _merge
drop if _merge!=3
drop _merge
save $working_data/2018_Background_combine.dta, replace

/* Place of Born */ 
use $raw_data/2015/Demographic_Background.dta, clear
keep bb001* ID householdID communityID
rename bb001 Born_2015
save $temp_data/2015_Place_of_Born.dta, replace 

use $working_data/2018_Background_combine.dta, clear 
merge 1:1 ID using $temp_data/2015_Place_of_Born.dta
tab _merge
drop if _merge!=3
drop _merge
replace bb001=Born_2015 if bb001==.
save $working_data/2018_Background_combine_clean.dta, replace


/*********** Combine Background Helath and Income (Family)***********/
use $working_data/2018_Background_combine_clean.dta, clear
merge m:1 ID using $working_data/2018_Health_combine.dta
tab _merge
drop if _merge!=3
drop _merge

merge m:1 ID using $working_data/2018_Money_combine_clean.dta
tab _merge
drop if _merge!=3
drop _merge
save $working_data/2018_Background_Health_Income_Clean.dta, replace


/* BMI */ //1 is better
use $raw_data/2015/Biomarker.dta, replace
keep ID householdID communityID qi002 ql002 qk002
replace qi002=. if qi002 == 993 | qi002<=150 | qi002>=170
replace ql002=. if ql002 == 993 | ql002<=40 | ql002>=75
gen BMI = ql002/(qi002/100)^2
gen BMI_group = 0 if BMI<18.5 | BMI>24
replace BMI_group=1 if BMI_group!=0 
replace BMI_group=. if BMI==.
replace qk002=. if qk002>=60 | qk002 <=30
save $working_data/2015_Weight_Height_data, replace

use $working_data/2018_Background_Health_Income_Clean.dta, clear
merge m:1 ID using $working_data/2015_Weight_Height_data
drop _merge
save $working_data/2018_Background_Health_Income_Clean.dta, replace

/*
use $raw_data/2008/2018.dta , clear 
keep ID householdID communityID city city_pinyin province

//replace householdID = householdID + "0"
//replace ID = householdID + substr(ID,-2,2)

save $working_data/Demographics_PSU_2008.dta, replace 
*/



// Enlarge dataset
use $working_data/2018_Background_combine.dta, clear 
keep householdID d5 
duplicates drop householdID, force
save $temp_data/d5.dta, replace  

// Sisters Brothers
use $raw_data/2018/Family_Information.dta, clear 
//use $working_data/2018_Background_combine.dta, clear 
keep ID householdID communityID xsibgender* xsibbirth*
drop xsibgender_s_* xsibbirth_s_*
duplicates drop householdID, force
reshape long xsibgender_@_ xsibbirth_@_ /*
*/ ,i(householdID) j(parentID)
tostring parentID, replace
gen mer1 = householdID + parentID
save $raw_data/xdzm_1.dta, replace 

use $raw_data/2018/Family_Information.dta, clear 
//use $working_data/2018_Background_combine.dta, clear 
keep ID householdID communityID xsibgender_s_* xsibbirth_s_*
duplicates drop householdID, force
reshape long xsibgender_s_@_ xsibbirth_s_@_ /*
*/ ,i(householdID) j(parentID)
tostring parentID, replace
gen mer2 = householdID + parentID
save $raw_data/xdzm_2.dta, replace 

use $raw_data/2018/Family_Information.dta, clear 
//use $working_data/2018_Background_combine.dta, clear 
keep ID householdID communityID cc003_w3_1_-cc003_w3_13_ cc012_w3_1_-cc012_w3_14_ cc006_w3_2_1_-cc006_w3_2_14_ 
duplicates drop householdID, force
reshape long cc003_w3_@_ cc012_w3_@_ cc006_w3_2_@_ /*
*/ , i(householdID) j(parentID)
label var parentID "ID of Respondents‘ Parents"
tostring parentID, replace
gen mer1 = householdID + parentID
save $raw_data/xdzm_1-2.dta, replace 

use $raw_data/2018/Family_Information.dta, clear 
//use $working_data/2018_Background_combine.dta, clear 
keep ID householdID communityID cc003_w3_s_* cc012_w3_s_* cc006_w3_2_s_*
duplicates drop householdID, force
reshape long cc003_w3_s_@_ cc012_w3_s_@_ cc006_w3_2_s_@_ /*
*/ , i(householdID) j(parentID)
label var parentID "ID of Respondents‘ Parents"
tostring parentID, replace
gen mer2 = householdID + parentID
save $raw_data/xdzm_2-2.dta, replace 

use $raw_data/xdzm_1.dta, clear
merge 1:1 mer1 using $raw_data/xdzm_1-2.dta
drop _merge 
save $working_data/xdzm-1.dta, replace 

use $raw_data/xdzm_2.dta, clear
merge 1:1 mer2 using $raw_data/xdzm_2-2.dta
drop _merge 
save $working_data/xdzm-2.dta, replace 

use $working_data/xdzm-1.dta, clear 
append using $working_data/xdzm-2.dta
merge m:1 householdID using $temp_data/d5.dta
drop _merge 
save $working_data/xdzm_all.dta, replace 

//Offspring 
use $raw_data/2018/Family_Information.dta, clear 
//use $working_data/2018_Background_combine.dta, clear 
keep ID householdID communityID cb052_w3_1_-cb052_w3_15_ cb053_* cb063_1_-cb063_15_ cb091_w4_* cb069_* ///
	cb063_w3_1_* cb063_w3_6_* xchildbirth* xchildgender* zchildedu* cb052_w4_* cb057_1_-cb057_15_
//cb063_w3_1_i (ah_good) // xchildbirth_i_ birth year (age)
duplicates drop householdID, force // 8,454 observations deleted
forvalue i = 1(1)14 {
	replace zchildedu_`i'_ = cb052_w3_`i'_ if cb052_w4_`i'_==2
}
reshape long  cb053_@_ cb063_@_ cb091_w4_@_ zchildedu_@_ /*
*/ cb069_@_ cb063_w3_1_@_ cb063_w3_6_@_ xchildbirth_@_ xchildgender_@_ /*
*/ , i(householdID) j(parentID)
label var parentID "ID of Respondents‘ Parents"
tostring parentID, replace
save $working_data/Offspring.dta, replace 


merge m:1 householdID using $temp_data/d5.dta
drop _merge 
replace cb063_w3_1__=. if cb063_w3_1__==997 | cb063_w3_1__==999
save $working_data/Offspring.dta, replace 






// Males' Parents 
use $raw_data/2018/Family_Information.dta, clear 
//use $working_data/2018_Background_combine.dta, clear 
duplicates drop householdID, force
gen gend=2 if ba000_w2_3==2
keep if gend==2

keep ID householdID communityID ca000_w3_1_* ca001_w3_1_* ca001_w4_1_* ca006_w3_2_* ca006_w4_3_* ca006_w3_3_* ///
	ca007_w3_2_* ca007_w3_3_* ca007_w3_5_* ca009_1_-ca009_8_ ca016_1_-ca016_8_ ca026_w3_* 

replace ca000_w3_1_1_=ca000_w3_1_2_ if ca000_w3_1_1_==.
replace ca001_w3_1_1_=ca001_w3_1_2_ if ca001_w3_1_1_==.
gen sex_fp= 1 if ca000_w3_1_1_!=. | ca000_w3_1_2_!=. 
replace sex_fp =2 if ca001_w3_1_1_!=.| ca001_w3_1_2_!=.

reshape long ca000_w3_1_@_ ca001_w3_1_@_ /*
*/ ca001_w4_1_@_ ca006_w3_2_@_ ca006_w4_3_@_ ca006_w3_3_@_ /*
*/ ca007_w3_2_@_ ca007_w3_3_@_ ca007_w3_5_@_ ca009_@_ /*
*/ ca016_w3_@_ ca016_@_ ca026_w3_@_ /*
*/ , i(householdID) j(parentID)
label var parentID "ID of Respondents‘ Parents"
tostring parentID, replace
merge m:1 householdID using $temp_data/d5.dta
drop _merge 
save $working_data/Parents_F.dta, replace

// Females' Parents
use $raw_data/2018/Family_Information.dta, clear 
//use $working_data/2018_Background_combine.dta, clear 
gen gend=1 if ba000_w2_3==1
keep if gend==1
duplicates drop householdID, force

keep ID householdID communityID ca000_w3_1_* ca001_w3_1_* ca001_w4_1_* ca006_w3_2_* ca006_w4_3_* ca006_w3_3_* ///
	ca007_w3_2_* ca007_w3_3_* ca007_w3_5_* ca009_1_-ca009_8_ ca016_1_-ca016_8_ ca026_w3_* 

replace ca000_w3_1_1_=ca000_w3_1_2_ if ca000_w3_1_1_==.
replace ca001_w3_1_1_=ca001_w3_1_2_ if ca001_w3_1_1_==.
gen sex_mp= 1 if ca000_w3_1_1_!=. | ca000_w3_1_2_!=. 
replace sex_mp =2 if ca001_w3_1_1_!=.| ca001_w3_1_2_!=.

reshape long ca000_w3_1_@_ ca001_w3_1_@_ /*
*/ ca001_w4_1_@_ ca006_w3_2_@_ ca006_w4_3_@_ ca006_w3_3_@_ /*
*/ ca007_w3_2_@_ ca007_w3_3_@_ ca007_w3_5_@_ ca009_@_ /*
*/ ca016_w3_@_ ca016_@_ ca026_w3_@_ /*
*/ , i(householdID) j(parentID)
label var parentID "ID of Respondents‘ Parents"
tostring parentID, replace
merge m:1 householdID using $temp_data/d5.dta
drop _merge 
save $working_data/Parents_M.dta, replace


/********** Hypertension Records from 2015 **********/
use $raw_data/2015/Biomarker.dta, clear
keep ID pa002 qa003 qa007 qa011 qa017 qa016
gen mean_systolic = (qa003+qa007+qa011)/3
replace mean_systolic= . if pa002==2
replace mean_systolic=. if qa017 != 5
replace mean_systolic=. if qa016 != 2
save $working_data/Hypertension_measure_2015.dta, replace 

/************************* Original-Construction ***************************/
use $working_data/2018_Background_Health_Income_Clean.dta, clear

/* health satisfaction */
gen health_status2 = dc042_w3


recode health_status2 (1/2=1) (3=2) (4/5=3), gen(health_status_group_2)
label define label_health_2 1 "Good" 2 "Fine" 3 "Bad" 

gen ah_good_2=(health_status_group_2==1|health_status_group_2==2) if !mi(health_status_group_2)
lab def ah_good_2 0 "B" 1 "F G"
tablist ah_good_2,sort(v)

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
replace Math_score=. if dc029_w4_1 == 6 | Math_score==9
 
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
gen optimistic_group = 1 if optimistic>=5 & optimistic!=. 
replace optimistic_group=0 if optimistic<5

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

duplicates drop ID, force
merge 1:1 ID using $working_data/Hypertension_measure_2015.dta 
drop _merge 
gen hypertension_1 = 1 if da007_1_ == 1 & mean_systolic>=140 // both
replace hypertension_1=0 if da007_1_==2 & mean_systolic<140
replace hypertension_1=0 if da007_1_==2 & mean_systolic==. 
replace hypertension_1=0 if mean_systolic <140 & da007_1_==.

gen hypertension_2 = 1 if da007_1_ == 1 | mean_systolic>=140 // one
replace hypertension_2=0 if da007_1_==2 & mean_systolic<140 

gen hypertension_3 = 1 if da007_1_==1
replace hypertension_3 = 0 if da007_1_==2

gen mean_systolic1=1 if mean_systolic>140 & mean_systolic!=. 
replace mean_systolic1=0 if mean_systolic<140 & mean_systolic!=. 

//gen hypertension_3 = 1 if da007_1_ == 1 | mean_systolic>=140 

/* Childhood Environment */


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


tab education, m
gen schooling=.
replace schooling=0 if education==1
replace schooling=4 if education==2
replace schooling=3 if education==3
replace schooling=6 if education==4
replace schooling=9 if education==5
replace schooling=12 if education==6
replace schooling=11 if education==7
replace schooling=14.5 if education==8
replace schooling=16 if education==9
replace schooling=18 if education==10
replace schooling=20 if education==11

egen schooling_group = cut(schooling), at(0,5,10,20)
egen schooling_group_3 = group(schooling_group)
label define schooling_group_label  1 "0-5" 2 "5-10" 3 "10+" , replace 
label values schooling_group_3 schooling_group_label
tab schooling_group_3, m
label var schooling_group_3 "Schooling year"
drop schooling_group

// self satisfaction
tab dc028,m
gen satisfaction=.
replace satisfaction = 3. if dc028== 1 | dc028== 2
replace satisfaction = 2. if dc028== 3
replace satisfaction = 1. if dc028== 4 | dc028== 5



// Diseases
				
gen has_hypertension_dyslipidemia = 1 if da007_1_==1 | da007_2_==1 
replace has_hypertension_dyslipidemia = 0 if has_hypertension_dyslipidemia==.

gen has_cancer = 1 if da007_4_== 1 
replace has_cancer = 0 if has_cancer==.


gen has_heart_disease = 1  if da007_7_==1
replace has_heart_disease = 0 if has_heart_disease==.


gen has_digestiveTract_disease = 1 if da007_3_==1 | da007_10_==1
replace has_digestiveTract_disease = 0 if has_digestiveTract_disease==. 


gen has_respiratory_disease = 1 if da007_5_==1 | da007_14_==1
replace has_respiratory_disease = 0 if has_respiratory_disease==.


gen has_other_disease = 1 if da007_8_==1 | da007_11_==1 | da007_12_==1 | da007_13_==1 
replace has_other_disease = 0 if has_other_disease==.

gen disease =1 if has_hypertension_dyslipidemia==1 | has_cancer==1 |has_heart_disease==1 |has_digestiveTract_disease==1 | has_respiratory_disease==1 | has_other_disease==1


replace disease =0 if has_hypertension_dyslipidemia==0 & has_cancer==0 & has_heart_disease==0 &has_digestiveTract_disease==0 & has_respiratory_disease==0 & has_other_disease==0






/* Age */
rename ba004_w3_1 birthyear  
rename ba004_w3_2 birthmonth 
rename ba003 birth_type 
gen age=.
gen surveymonth=7
gen surveyyear=2018
replace age=round((surveyyear-birthyear)+(surveymonth-birthmonth)/12) if !mi(birthyear) & !mi(birthmonth) & birth_type==1 //solar calendar
replace age=round((surveyyear-birthyear)+(surveymonth-birthmonth-1)/12) if !mi(birthyear) & !mi(birthmonth) & birth_type==2 //lunar calendar
replace age=round((surveyyear-birthyear)+(surveymonth-birthmonth)/12) if !mi(birthyear) & !mi(birthmonth) & mi(birth_type) //birth type missing

order age, after(communityID)
gen year = .
replace year = birthyear
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


// Child Health status 
gen child_health=da048 if !mi(da048)
lab var child_health "Self-reported Child Health Status"
lab def child_health 5 "Poor" 4 "Not Good" 3 "Good" 2 "Very Good" 1"Excelent"
lab values child_health child_health
tab child_health, m

gen ch_good=(da048==1|da048==2|da048==3) if !mi(da048)
lab var ch_good "Childhood environment is Good"
lab def ch_good 0 "NG P" 1 "G VG Ex", replace
lab values ch_good ch_good
tablist ch_good,sort(v)



/* Calculate household size & children size */

tablist a005_w3_1_ //Familymember's gender
tablist a006_1_  //child's relationship  Childr=8
gen childin=0
gen householdnum=0
forvalues i =1/10 { 
	replace householdnum= householdnum + (!mi(a005_w3_`i'_))
}
forvalues i = 1/9 {
	replace childin = childin + ((a006_`i'_ == 8)) 
}

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


/* Married */ 
tab be001,m
gen married = inlist(be001,1,2) if inlist(be001,1,2,3,4,5,6)
label define married 0 "UnMarried" 1 "Married" ,modify
drop be001
tab married,m


save $working_data/origincal_construction.dta, replace 



/******************* Append enlarge part *****************/
use $working_data/xdzm_all.dta, clear

append using $working_data/Parents_F.dta
append using $working_data/Parents_M.dta
append using $working_data/Offspring.dta

save $working_data/enlarge.dta, replace 
 
/******************* Construction - enlarge *****************/
use $working_data/enlarge.dta, clear

// Self Comment of Your Life 

gen health_status=1 if cc012_w3__==5 | cb063_w3_1__==5 | cc012_w3_s__==5 | cc012_w3__==5
replace health_status=2 if cc012_w3__==4 | cb063_w3_1__==4 | cc012_w3_s__==4 | cc012_w3__==4
replace health_status=3 if cc012_w3__==3 | cb063_w3_1__==3 | cc012_w3_s__==3 | cc012_w3__==3
replace health_status=4 if cc012_w3__==2 | cb063_w3_1__==2 | cc012_w3_s__==2 | cc012_w3__==2
replace health_status=5 if cc012_w3__==1 | cb063_w3_1__==1 | cc012_w3_s__==1 | cc012_w3__==1 

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

///gen ce_good=(d5==1|d5==2|d5==3) if !mi(d5)


// schooling 
gen education = .
replace education = ca009__ if education==.
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
replace age=(2018-ca000_w3_1__) if age==.
replace age=(2018-ca001_w3_1__) if age==.
replace age=(2018-ca006_w3_3__) if age==.
replace age=(2018-ca007_w3_3__) if age==.
replace age=(2018-xsibbirth_s__) if age==.
replace age=(2018-xsibbirth__) if age==.
gen age_2 = age*age

gen year = .
replace year = xchildbirth__ if year ==.
replace year = ca000_w3_1__ if year ==.
replace year = ca001_w3_1__ if year ==.	
replace year = ca006_w3_3__ if year ==.
replace year = ca007_w3_3__ if year ==.	
replace year = xsibbirth_s__ if year ==.
replace year = xsibbirth__ if year ==.


/* Gender */
gen gender=.
replace gender=xchildgender__ if gender==. 
replace gender=xsibgender_s__ if gender==. 
replace gender=xsibgender__ if gender==. 

/*
bysort householdID: egen gender_max=max(gender)
list householdID gender gender_max in 1/6
replace gender=1 if gender_max==2 & mi(gender)
replace gender=2 if gender_max==1 & mi(gender)
tab gender,m
drop gender_max 

*/
gen female=(gender-1)
order female, after(age)

save $working_data/enlarge_construction.dta, replace 

/**************Combine Orginial and Enlarge parts ********************/
use $working_data/origincal_construction.dta, clear 
append using $working_data/enlarge_construction.dta
replace year = year-1980
order year, after(birthyear)
replace year=. if year<=0 | year>=16
tostring year, replace 
save $working_data/2018_original_enlarge_construction.dta, replace 

/**************Combine all parts with PSU and TSP********************/  
//use $working_data/TSP.dta ,clear
//save $working_data/TSP.dta , replace 
use $raw_data/2013/PSU.dta ,clear
keep communityID province city urban_nbs
replace city="哈尔滨市" if  city=="哈尔滨" 
merge m:1 city using $working_data/TSP.dta
drop if _merge==2
drop _merge
save $working_data/PS——SP.dta, replace 

use $working_data/PS——SP.dta, clear 
reshape long y_@ /*
*/ , i(communityID) j(m)
label var m "year order from 1981 to 1995"
tostring m,replace
gen M = city_pinyin + m
gen K = communityID +city_pinyin+m 
replace M="." if northsouth==.
replace K="." if northsouth==.
keep communityID M K y_ city_pinyin province city urban_nbs
//duplicates drop M, force
save $working_data/city_TSP.dta, replace 

use $working_data/PS——SP.dta, clear
merge 1:m communityID using $working_data/2018_original_enlarge_construction.dta
drop if _merge!=3
drop _merge
gen M = city_pinyin + year
gen K = communityID + city_pinyin+ year
save $working_data/2018_all.dta, replace 


use $working_data/2018_all.dta, clear
//keep communityID y_ M K
merge m:1 K using $working_data/city_TSP.dta 
gen TSP = y_
save $working_data/2018_all_TSP.dta, replace


/******************************* Graph ************************************/

use $working_data/2018_all_TSP.dta, clear 

// Adult health against child environment situations
gen adult_health_1 = 0
replace adult_health_1=1 if health_status_group==3
gen adult_health_2 = 0
replace adult_health_2=1 if health_status_group==2
gen adult_health_3 = 0
replace adult_health_3=1 if health_status_group==1


label define ce_good_name  0 "Poor" 1 "Good"
label values ce_good ce_good_name


graph bar (mean) adult_health_1 (mean) adult_health_2 (mean) adult_health_3, plotregion(margin(thirty)) ///
        over(ce_good) percentages stack blabel(bar, format(%9.1f)) ylabel(30(10)) ymtick(, labels valuelabel) ytitle("Proportion of adult health in children's environment group") title("Adult health against child environment conditions") ///
		note(Source: CHARLS 2018 database) legend(label(1 "Very Good") label(2 "Good") label(3 "Not Good") label(4 "Poor"))

graph export $figures/adult_environment_child_environment.png, replace


// 3d-- ah_good\ce_good with age_group1


graph bar (mean) ah_good,  ///
  over(ce_good, label(labsize(*.75))) ///
  over(age_group1) ///
  bargap(-30) nofill ///
  ytitle("Adult health") ///
  title("Adult health") ///
  subtitle("by childhood environment and age") ///
  note("Source: CHARLS 2018 database") 
graph save $figures/ah_ce_age.png,replace


/* Income */

// 3d Adult health by childhood education   
graph bar (mean) ah_good,  ///
  over(ce_good, label(labsize(*.85))) ///
  over(edu_midabove) ///
  bargap(-30) nofill ///
  ytitle("Adult health") ///
  title("Adult health") ///
  subtitle("by childhood environment situation and education") ///
  note("Source: CHARLS 2018 Database") 
graph save $figures/ah_ce_edu.png,replace

// 3d Adult health by Total income
graph bar (mean) ah_good,  ///
  over(ce_good, label(labsize(*.65))) ///
  over(income_group) ///
  bargap(-30) nofill ///
  ytitle("Adult health") ///
  title("Adult health") ///
  subtitle("by childhood environment situation and total income") ///
  note("Source: CHARLS 2018 Database") 
graph save $figures/ah_ce_income.png,replace

graph hbox age		

/*********** TSP graph ***********/
use $working_data/TSP.dta, clear  
forvalues i = 1(1)15{
	bysort northsouth : egen Total_`i' = sum(y_`i')
	gen Num_`i'=0
	bysort northsouth : replace Num_`i'= Num_`i'+1 if y_`i' !=.
	bysort northsouth : egen TotalNum_`i' = sum(Num_`i')
	bysort northsouth : gen Mean_value_`i' = Total_`i'/TotalNum_`i'
}
keep Mean_value_* northsouth
duplicates drop northsouth, force 
reshape long Mean_value_@ /*
*/ , i(northsouth) j(Year)
drop if northsouth==. 
replace Year= Year+1980

label variable Mean_value_ "Mean TSP concentration(ug/m3)"
label value 

lab def northsouth 0 "Southern" 1 "Northern", replace
lab values northsouth northsouth


xtline Mean_value_ , overlay t(Year) i(northsouth) ///
	ytitle("TSP concentration(ug/m3)") ///
	title("Average Concentration of TSP in Northern and Southern of China ") ///
	caption("Data Source: China National Environmental Monitoring Station and China's National Environment Protection Agency")
graph export $figures\TSP_N_S.png, replace



use $working_data/TSP.dta, clear  
keep if  city_pinyin=="Harbin" | city_pinyin=="Dalian" ///
		| city_pinyin=="Chongqing" | city_pinyin=="Guiyang" 
reshape long y_@ /*
*/ , i(city_pinyin) j(Year)
replace Year= Year+1980


xtline y_ , overlay t(Year) i(city_pinyin) ///
	ytitle("TSP concentration(ug/m3)") ///
	title("Concentration of TSP in typical cities of China ") ///
	caption("Data Source: China National Environmental Monitoring Station ")
graph export $figures\TSP_city.png, replace


  
  
// satisfaction with age group.   /* scatter and lowess */					   


/************* Table *************/

use $working_data/2018_all_TSP.dta, clear 

label variable health_status_group Adult_health
tabulate health_status_group child_environment  

tabulate health_status_group child_environment,cell //use
tabout using $tables/1.xls, c(row) f(0c) clab(Col_%) npos(col) rep


tabout health_status_group child_health using $tables/2.xls, c(row) f(0c) clab(Col_%) npos(col) rep //use
   

   
tabulate ce_good health_status_group , nofreq row
tabulate health_status_group ce_good , nofreq col

** Three dimentional table
gen ce_good_1 = ce_good if age_group1==1
label variable ce_good_1 "45-54"
label define ce_good_1_lab  0 "NG P" 1 "G VG"
label values ce_good_1 ce_good_1_lab

gen ce_good_2 = ce_good if age_group1==2
label variable ce_good_2 "55-64"
label define ce_good_2_lab  0 "NG P" 1 "G VG"
label values ce_good_2 ce_good_2_lab

gen ce_good_3 = ce_good if age_group1==3
label variable ce_good_3 "65+"
label define ce_good_3_lab  0 "NG P" 1 "G VG"
label values ce_good_3 ce_good_3_lab
sum ce_good_1 ce_good_2 ce_good_3

label variable health_status_group Adult_health_status
tabout ce_good_1 ce_good_2 ce_good_3 health_status_group using $tables/ch_ah_age1.xls, ///
       c(row) f(0c) clab(Col_%) npos(col) ///
       rep

/*************** Regression **************/

//use $working_data/origincal_construction.dta, clear 
use $working_data/2018_all_TSP.dta, clear   

/*
xi: reg cognitive_group ce_good age age_2 i.education_group female 
est store cognitive
outreg2 [cognitive] using "$tables\ah_good_ce.xls",replace
*/

gen hh = 1 if health_status==1 | health_status==2 | health_status==3
replace hh=2 if health_status==4
replace hh = 3 if health_status==5

/************* Self-reported health outcome****************/
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


/************* Hypertension ****************/ 
// Table 5
xi: probit hypertension_1 ce_good i.education_group age age_2 female // both
mfx 
est store Hyper_1

xi: probit hypertension_2 ce_good i.education_group age age_2 female // one only
mfx 
est store Hyper_2

xi: probit hypertension_3 ce_good i.education_group age age_2 female //choice only
mfx 
est store Hyper_3

xi: probit mean_systolic1 ce_good i.education_group age age_2 female // measure only
mfx
est store Hyper_4

outreg2 [Hyper_4] using "$tables\Hyper_ce_good.xls",replace


/************* Optimistic emotion level ****************/
// Table 5
xi: reg optimistic ce_good age age_2 i.education_group female 
est store depression1

xi: oprobit optimistic_group ce_good age age_2 i.education_group female 
mfx
est store depression2

xi: reg optimistic ce_good female age age_2 i.education_group i.city
est store depression3


outreg2 [depression1 depression2 depression3] using "$tables\depression_2.xls",replace



//Congnitive function //Table6

gen cognitive = cognitive_level+Math_series_score+word_recognition // Three aspects

bysort education_group: egen con_edu_group=mean(Math_series_score)
bysort education_group: egen con_edu_group2=sd(Math_series_score)

bysort age_group2: egen con_edu_group3=mean(cognitive)
bysort age_group2: egen con_edu_group4=sd(cognitive)

bysort education_group: egen con_edu_group5=mean(cognitive_level)
bysort education_group: egen con_edu_group6=sd(cognitive_level)


gen cog_score1 = (cognitive-con_edu_group)/con_edu_group2  // three with education_group
gen cog_score2 = (cognitive-con_edu_group3)/con_edu_group4 // threev with age_group2
gen cog_score3 = (cognitive-con_edu_group5)/con_edu_group6 // words only with age_group2


xi: reg cognitive_level ce_good female age age_2 i.education_group // Total 3 parts
est store co1
xi: reg cognitive_level ce_good female age age_2 i.education_group i.optimistic // Total 3 parts
est store co2
xi: reg cognitive_level ce_good female age age_2 i.education_group i.city // Total 3 parts
est store co3
xi: reg cognitive_level ce_good female age age_2 i.education_group i.province // Total 3 parts
est store co4


xi: reg Math_series_score ce_good female age age_2 i.education_group // only math 
est store co1
xi: reg cog_score1 ce_good female age age_2 i.education_group  // math with c
est store co2

outreg2[co1 co2] using "$tables\cognitive_function_struction.xls",replace



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
xi: reg cognitive ce_good age age_2 i.education_group female i.city_pinyin
est store cogni2

outreg2 [cogni1 cogni2] using "$tables\.xls",replace






// Table 8
xi: probit ah_good TSP age age_2 i.education_group female
mfx
est store TSP_self1
xi: probit ah_good TSP age age_2 i.education_group  
mfx
est store TSP_self2

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
