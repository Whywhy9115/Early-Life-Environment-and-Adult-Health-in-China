
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

/********************************** 2018 - Income **********************************/

/* Combine data*/
use $raw_data/2018/Individual_Income.dta, clear
merge m:1 householdID using $raw_data/2018/Household_Income.dta
tab _merge
drop if _merge!=3
drop _merge
save $working_data/2018_Money_combine.dta, replace

use $working_data/2018_Money_combine.dta, clear
merge m:1 householdID using $raw_data/2018/Housing.dta
tab _merge
drop if _merge!=3
drop _merge
save $working_data/2018_Money_combine.dta, replace

/* Clean data */
use $working_data/2018_Money_combine.dta, clear 
drop hd*
drop ga000_w4
order versionID, after(communityID)

/* Income database */ 
//drop consumption 
drop ge* z*

// ga* Household  Wage  Income  and  Individual-based  Transfers
//ga002 How Much Receive
replace ga002=0 if ga002==.
replace ga002_max=0 if ga002_max==.
forvalues i = 1(1)2 {
	replace ga002_w2_`i'= . if ga002_w2_`i' ==997 | ga002_w2_`i' == 999
}
replace ga002_w2_2= 4 if ga002_w2_2 == 997 | ga002_w2_2== 999 | ga002_w2_2==.
replace ga002_w2_2a=0 if ga002_w2_2a==.
replace ga002_w2_2b=0 if ga002_w2_2b==.
replace ga002_w2_2c=0 if ga002_w2_2c==.
replace ga002_w2_2_max=0 if ga002_w2_2_max==.
//ga003
forvalues i = 1(1)9 {
	replace ga003_w4_`i'=0 if ga003_w4_`i'==.
}
//ga004
replace ga004_w4_1_max=0 if ga004_w4_1_max==.
// ga005 Wage and Bonus Income 
forvalues i = 1(1)12 {
	replace ga005_`i'_= . if ga005_`i'_==997 | ga005_`i'_==999
}
//ga006 Amount HHMemberName
forvalues j = 1(1)8 {
	replace ga006_w4_`j'_ = 0 if mi(ga006_w4_`j'_ ) | ga006_w4_`j'_==. 
	replace ga006_w4_`j'__max= 0 if mi(ga006_w4_`j'__max) | ga006_w4_`j'__max==.
	replace ga006_w4_`j'__min= . if mi(ga006_w4_`j'__min)
	replace ga006_w4_2_`j'__max= 0 if mi(ga006_w4_2_`j'__max) | ga006_w4_2_`j'__max==. 
	replace ga006_w4_2_`j'__min= . if mi(ga006_w4_2_`j'__min)
	forvalues k = 1(1)2{
		replace ga006_w4_`k'_`j'_= . if mi(ga006_w4_1_`j'_)
		replace ga006_w4_`k'_`j'_= . if ga006_w4_`k'_`j'_==997 |ga006_w4_`k'_`j'_== 999
	}
}
forvalues i = 1(1)5{
	replace ga006_w4_2a_`i'_= 0 if ga006_w4_2a_`i'_==.
}
foreach i in 1 2 3 4 5 6 8{
	replace ga006_w4_2b_`i'_= 0 if ga006_w4_2b_`i'_==.
}
forvalues i = 1(1)3{
	replace ga006_w4_2c_`i'_= 0 if ga006_w4_2c_`i'_==. 
}
//ga007 Subsidy
foreach j in 4 5 {
	forvalues z = 1(1)4 {

		replace ga007_w4_`j'_`z'_= 0 if mi(ga007_w4_`j'_`z'_) | ga007_w4_`j'_`z'_==. 
	} 
}
forvalues i = 1(1)7 {
	replace ga007_w4_1_`i'_= 0 if mi(ga007_w4_1_`i'_) | ga007_w4_1_`i'_==.

}
forvalues i = 1(1)3 {
	foreach j in 2 6 {
		replace ga007_w4_`j'_`i'_= 0 if mi(ga007_w4_`j'_`i'_) | ga007_w4_`j'_`i'_==.
	}
}
forvalues i = 1(1)2 {
	replace ga007_w4_3_`i'_= 0 if mi(ga007_w4_3_`i'_) | ga007_w4_3_`i'_==.
}
forvalues i = 1(1)5 {
	foreach j in 7 9 {
	replace ga007_w4_`j'_`i'_= 0 if mi(ga007_w4_`j'_`i'_) | ga007_w4_`j'_`i'_==.
	}
}
forvalues i = 1(1)6 {
	replace ga007_w4_8_`i'_= 0 if mi(ga007_w4_8_`i'_) | ga007_w4_8_`i'_==.
}
// ga008 
forvalues i = 1(1)3{
	replace ga008_w4_1_`i'__max= 0 if ga008_w4_1_`i'__max== . 
} 
//ga012 Have inherited
forvalues i = 1(1)12{
	replace ga012_w4_1_`i'_= . if mi(ga012_w4_1_`i'_)
	replace ga012_w4_1_`i'_= . if ga012_w4_1_`i'_==997 |ga012_w4_1_`i'_== 999
}
// gb* Household  Agricultural  Income  and  Expenditure
//gb005 Home Consumed 
forvalues i = 1(1)3{
	replace gb005_`i'= 0 if mi(gb005_`i') | gb005_`i'==. | gb005_`i'<1
}
replace gb005_max = 0 if gb005_max==.
replace gb005_w2_max = 0 if gb005_w2_max==.
//gb008
replace gb008= 0 if mi(gb008) | gb008==. 
replace gb008_min= 0 if mi(gb008_min) | gb008_min==.
replace gb008_max= 0 if mi(gb008_max) | gb008_max==.
//gb009
replace gb009= 0 if mi(gb009) | gb009==. 
replace gb009_min= 0 if mi(gb009_min) | gb009_min==.
replace gb009_max= 0 if mi(gb009_max) | gb009_max==.
//gb010 Buy livestock and aquatic products
replace gb010=0  if gb010==.
//gb011 aquatic products
forvalues i = 1(1)3{
	replace gb011_`i'= 0 if gb011_`i'==.
}
replace gb011_min= 0 if gb011_min ==. 
replace gb011_max= 0 if gb011_max== .
replace gb011_w2_max= 0 if gb011_w2_max== .
replace gb011_w2_min= 0 if gb011_w2_min== .
//gb012 Self-Consumed 
forvalues i = 1(1)3{
	replace gb012_`i'= 0 if gb012_`i'==.
}
replace gb012_min= 0 if gb012_min==.
replace gb012_max= 0 if gb012_max==.
replace gb012_w2_max= 0 if gb012_w2_max==.
replace gb012_w2_min= 0 if gb012_w2_min==.
//gb013
replace gb013=0 if gb013==.
// gc* Self-Employed  Activities  
//gc005 Net Income from Activity
forvalues i = 1(1)4 {
	replace gc005_`i'_= 0 if gc005_`i'_==. | gc005_`i'_<0
	replace gc005_`i'__min= 0 if gc005_`i'__min==. | gc005_`i'__min <0
	replace gc005_`i'__max= 0 if gc005_`i'__max==. | gc005_`i'__max< 0
}
// gd* Household  Public  Transfer  Income
//gd001
forvalues i = 1(1)3 {
	replace gd001_w4_`i'= . if mi(gd001_w4_`i') | gd001_w4_1 ==999
}
replace gd001_w4_3 = 0 if gd001_w4_3==.
//gd002  Social Subsidies
forvalues i = 1(1)10 {
	replace gd002_w4_`i'= 0 if mi(gd002_w4_`i') | gd002_w4_`i'==.
}
//gd003
forvalues i = 1(1)2 {
	replace gd003_w4_`i'= . if gd003_w4_1 ==997 | gd003_w4_1 ==999
}


//gd004
replace gd004_w4= 0 if mi(gd004_w4) | gd004_w4==.
// hc* Financial Assets
foreach i in 01 05 07 08 10 13 15 18 20 21 22 27 28 30 31 33 34 {
	replace hc0`i'= . if hc0`i'== 999
	replace hc0`i'= 0 if hc0`i'==.
}
foreach i in 02 06 09 14 19 29 32 35 {
	replace hc0`i'_min= . if mi(hc0`i'_min)
	replace hc0`i'_max= . if mi(hc0`i'_max)
	replace hc0`i'_max= 0 if hc0`i'_max==. 
	replace hc0`i'_min= 0 if hc0`i'_min==.
}
foreach i in 03 16 17{
	replace hc0`i'_w4= . if hc0`i'_w4==999
	replace hc0`i'_w4= 0 if hc0`i'_w4==.
}
foreach i in 04 17{
	replace hc0`i'_w4_min= . if mi(hc0`i'_w4_min)
	replace hc0`i'_w4_max= . if mi(hc0`i'_w4_max)
	replace hc0`i'_w4_min= 0 if hc0`i'_w4_min==. 
	replace hc0`i'_w4_max= 0 if hc0`i'_w4_max==. 
}
replace hc039_w3=0 if hc039_w3==999 
replace hc040_w3=0 if mi(hc040_w3) 
replace hc041_w3_min= . if hc041_w3_min==. 
replace hc041_w3_max= . if hc041_w3_max==.
replace hc041_w3_min=0 if hc041_w3_min==.
replace hc041_w3_max=0 if hc041_w3_max==.
//ha* House Property 
//ha006 The monthly rent for the house
forvalues j = 1(1)4 {
	replace ha006_w4_`j'_= ha006_w4_`j'__max if ha006_w4_`j'_==0
	foreach i in 1 2 3 4 5 7{
	replace ha006_w4_`i'_= 0 if ha006_w4_`i'_<0 | ha006_w4_`i'_==.
	}
}
save $working_data/2018_Money_combine_clean.dta, replace


/*********** 2018 -  Health ***********/

/* Combine data*/
use $raw_data/2018/Health_Care_and_Insurance.dta, clear 
merge m:1 ID using $raw_data/2018/Health_Status_and_Functioning.dta
tab _merge
drop if _merge!=3
drop _merge
save $working_data/2018_Health_combine.dta, replace

/* Clean data */

use $working_data/2018_Health_combine.dta, replace
drop da008*
drop e*
replace da048=. if da048==997
save $working_data/2018_Health_combine.dta, replace


/*********** 2018 -  Education ***********/

use $raw_data/2014/Family_Information.dta, clear
keep ID householdID communityID d*
save $working_data/Family_Information_from2014.dta, replace

/* Combine data*/
use $raw_data/2018/Demographic_Background.dta, clear
merge m:1 householdID using $raw_data/2018/Family_Information.dta 
tab _merge
drop if _merge!=3
drop _merge

merge m:1 ID using $raw_data/2018/Cognition.dta
tab _merge
drop if _merge!=3
drop _merge

merge m:m householdID using $working_data/Family_Information_from2014.dta
tab _merge
drop if _merge!=3
drop _merge
save $working_data/2018_Background_combine.dta, replace

/* Place of Born */
use $raw_data/2015/Demographic_Background.dta, clear
keep bb001 ID householdID communityID
rename bb001 Born_2015
save $temp_data/2015_Place_of_Born.dta, replace 

use $working_data/2018_Background_combine.dta, clear 
merge m:1 ID using $temp_data/2015_Place_of_Born.dta
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


use $raw_data/2008/Demographics_20101118.dta , clear 
keep ID householdID communityID city city_pinyin province



// Enlarge dataset
use $working_data/2018_Background_combine.dta, clear 
keep householdID d5 
duplicates drop householdID, force
save $temp_data/d5.dta, replace  



// Sisters Brothers
use $working_data/2018_Background_combine.dta, clear 
keep ID householdID xsibgender* xsibbirth*
drop xsibgender_s_* xsibbirth_s_*
duplicates drop householdID, force
reshape long xsibgender_@_ xsibbirth_@_ /*
*/ ,i(householdID) j(parentID)
tostring parentID, replace
gen mer1 = householdID + parentID
save $raw_data/xdzm_1.dta, replace 

use $working_data/2018_Background_combine.dta, clear 
keep ID householdID xsibgender_s_* xsibbirth_s_*
duplicates drop householdID, force
reshape long xsibgender_s_@_ xsibbirth_s_@_ /*
*/ ,i(householdID) j(parentID)
tostring parentID, replace
gen mer2 = householdID + parentID
save $raw_data/xdzm_2.dta, replace 

use $working_data/2018_Background_combine.dta, clear 
keep ID householdID cc003_w3_1_-cc003_w3_13_ cc012_w3_1_-cc012_w3_14_ cc006_w3_2_1_-cc006_w3_2_14_
duplicates drop householdID, force
reshape long cc003_w3_@_ cc012_w3_@_ cc006_w3_2_@_ /*
*/ , i(householdID) j(parentID)
label var parentID "ID of Respondents‘ Parents"
tostring parentID, replace
gen mer1 = householdID + parentID
save $raw_data/xdzm_1-2.dta, replace 

use $working_data/2018_Background_combine.dta, clear 
keep ID householdID cc003_w3_s_* cc012_w3_s_* cc006_w3_2_s_*
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
use $working_data/2018_Background_combine.dta, clear 
keep ID householdID cb052_w3_1_-cb052_w3_15_ cb053_* cb063_1_-cb063_15_ cb091_w4_* cb069_* ///
	cb063_w3_1_* cb063_w3_6_* xchildbirth* xchildgender* zchildedu* cb052_w4_* 
duplicates drop householdID, force
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


// Father's Parents 
use $working_data/2018_Background_combine.dta, clear 
gen gend=2 if ba000_w2_3==2
keep if gend==2
duplicates drop householdID, force


keep ID householdID ca000_w3_1_* ca001_w3_1_* ca001_w4_1_* ca006_w3_2_* ca006_w4_3_* ca006_w3_3_* ///
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
save $working_data/Parents_F.dta, replace



// Mother's Parents
use $working_data/2018_Background_combine.dta, clear 
gen gend=1 if ba000_w2_3==1
keep if gend==1
duplicates drop householdID, force

keep ID householdID ca000_w3_1_* ca001_w3_1_* ca001_w4_1_* ca006_w3_2_* ca006_w4_3_* ca006_w3_3_* ///
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
save $working_data/Parents_M.dta, replace


/************************************ Add enlarge part *************************************/
use $working_data/2018_Background_Health_Income_Clean.dta, clear
append using $working_data/xdzm_all.dta 
append using $working_data/Parents_F.dta
append using $working_data/Parents_M.dta
append using $working_data/Offspring.dta
save $working_data/2018_All.dta, replace 


/************************************ Construction *************************************/
use $working_data/2018_All, clear

/*
/* health satisfaction */
gen health_status2 = dc042_w3


recode health_status2 (1/2=1) (3=2) (4/5=3), gen(health_status_group_2)
label define label_health_2 1 "Good" 2 "Fine" 3 "Bad" 

gen ah_good_2=(health_status_group_2==1|health_status_group_2==2) if !mi(health_status_group_2)
lab def ah_good_2 0 "B" 1 "F G"
tablist ah_good_2,sort(v)
*/
// Self Comment of Your Life 


gen health_status=1 if da002==5 | cc012_w3__==5 | cb063_w3_1__==5 | cc012_w3_s__==5 | cc012_w3__==5
replace health_status=2 if da002==4 | cc012_w3__==4 | cb063_w3_1__==4 | cc012_w3_s__==4 | cc012_w3__==4
replace health_status=3 if da002==3 | cc012_w3__==3 | cb063_w3_1__==3 | cc012_w3_s__==3 | cc012_w3__==3
replace health_status=4 if da002==2 | cc012_w3__==2 | cb063_w3_1__==2 | cc012_w3_s__==2 | cc012_w3__==2
replace health_status=5 if da002==1 | cc012_w3__==1 | cb063_w3_1__==1 | cc012_w3_s__==1 | cc012_w3__==1 

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


/* Cognitive Function - words */
gen cognitive_level = 0
forvalues i = 1(1)10 {
	replace dc028_w4_s`i' = 0 if dc028_w4_s`i'==.
	replace dc029_w4_s`i' = 0 if dc029_w4_s`i'==.
	replace dc030_w4_s`i' = 0 if dc030_w4_s`i'==.
	replace cognitive_level = cognitive_level+1 if dc028_w4_s`i' !=0
	replace cognitive_level = cognitive_level+1 if dc029_w4_s`i' !=0
	replace cognitive_level = cognitive_level+1 if dc030_w4_s`i' !=0
}
replace cognitive_level = . if wr101_intro==2
tab cognitive_level
gen cognitive_group = 1 if wr101_intro== 1
replace cognitive_group = 0 if cognitive_level > 5
tab cognitive_group

/* Cognitive Function - number */ //the smaller the better ---- Math problem
gen cognitive_level_2 = 0
replace cognitive_level_2 = cognitive_level_2 +1 if dc029_w4_1==8
replace cognitive_level_2 = cognitive_level_2 +1 if dc030_w4_1 == 8 
forvalues i = 1(1)4 { 
	forvalues j = 1(1)3{
		replace cognitive_level_2 = cognitive_level_2 +1 if dc03`i'_w3_`j' == 8
		replace cognitive_level_2 = cognitive_level_2 +1 if dc03`i'_w4_`j' == 8
	}
} // dc035 
gen cognitive_group_2 = 1
replace cognitive_group_2 = 0 if cognitive_level_2 !=0


//For only last 10Q 
gen cognitive_level_3 = 0
forvalue i = 1(1)10{
	replace cognitive_level_3 = cognitive_level_3+1 if dc030_w4_s`i' !=0
}
tab cognitive_level_3
replace cognitive_level_3 = . if wr101_intro==2


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




/************** Total Financial Assets ****************/
gen total_cash = hc001
replace total_cash = hc002_max if hc001== 0

gen total_ele = hc003_w4
replace total_ele = hc004_w4_max if hc003_w4== 0

gen total_bank = hc005
replace total_bank = hc006_max if hc005== 0

gen total_bond = hc008
replace total_bond = hc009_max if hc008== 0

gen total_stock = hc013
replace total_stock= hc014_max if hc013==0

gen total_fund = hc018
replace total_fund= hc019_max if hc018==0 

gen total_others = hc017_w4
replace total_others= hc017_w4_max if hc017_w4==0

gen total_other_members = hc022 

gen total_house_fund = hc028
replace total_house_fund= hc029_max if hc028==0

gen total_jizikuan = hc031
replace total_jizikuan = hc032_max if total_jizikuan==0

gen total_unpaied_salary = hc034
replace total_unpaied_salary= hc035_max if hc034==0

gen total_unpaied_others = hc040_w3
replace total_unpaied_others= hc041_w3_max if hc040_w3==0

gen house_rent = ha006_w4_1_ + ha006_w4_2_ + ha006_w4_3_ + ///
	ha006_w4_4_ + ha006_w4_5_ + ha006_w4_7_

gen total_assets = total_cash + total_ele + total_bank + total_bond + total_stock + total_fund + total_others ///
			+total_other_member + total_house_fund + total_jizikuan + total_unpaied_salary + total_unpaied_others + house_rent

label variable total_assets "Total asset"
			
/******************** Total Income ************************/	
	
// Self -- Household  Wage  Income  

gen total_wage = ga002 + ga002_max
gen wage_deducted = ga002_w2_2a + 12*ga002_w2_2b + (total_wage/100)*ga002_w2_2c 

gen total_household_wage = total_wage + wage_deducted + ga002_w2_2_max*12

forvalues i = 1(1)9 {
	replace total_household_wage = total_household_wage + ga003_w4_`i'
}
replace total_household_wage = total_household_wage + ga004_w4_1_max 
		
// Other members --   Wage  Income   
gen total_wage_others = 0
forvalues i = 1(1)8{
	replace total_wage_others = total_wage_others + ga006_w4_`i'_ + ga006_w4_`i'__max
}

gen wage_deducted_others = 0
forvalues i = 1(1)5{
	replace wage_deducted_others = wage_deducted_others +ga006_w4_2a_`i'_
}

foreach i in 1 2 3 4 5 6 8{
	replace wage_deducted_others = 12*ga006_w4_2b_`i'_ + wage_deducted_others
}

replace wage_deducted_others = wage_deducted_others + (ga006_w4_1_+ga006_w4_1__max/100)*ga006_w4_2c_1_ +(ga006_w4_2_+ga006_w4_2__max/100)*ga006_w4_2c_2_ + (ga006_w4_3_+ga006_w4_3__max/100)*ga006_w4_2c_3_

gen total_others_wage = total_wage_others + wage_deducted_others

forvalues i = 1(1)7{
	replace total_others_wage = total_others_wage + ga007_w4_1_`i'
}
forvalues i = 1(1)3{
	replace total_others_wage = total_others_wage + ga007_w4_2_`i'
	replace total_others_wage = total_others_wage + ga007_w4_6_`i'
}
forvalues i = 1(1)2{
	replace total_others_wage = total_others_wage + ga007_w4_3_`i'
}
forvalues i = 1(1)4{
	replace total_others_wage = total_others_wage + ga007_w4_4_`i'
	replace total_others_wage = total_others_wage + ga007_w4_5_`i'
}
forvalues i = 1(1)5{
	replace total_others_wage = total_others_wage + ga007_w4_7_`i'
	replace total_others_wage = total_others_wage + ga007_w4_9_`i'
}
forvalues i = 1(1)6{
	replace total_others_wage = total_others_wage + ga007_w4_8_`i'
}

replace total_others_wage = total_others_wage + ga008_w4_1_1__max + ga008_w4_1_2__max + ga008_w4_1_3__max

// Household  Agricultural  Income  and  Expenditure	
gen total_forestry = gb005_1 + gb005_max - gb005_2 - gb005_w2_max
gen total_livestock_fisheries = gb008 + gb008_max-gb009-gb009_max
replace total_livestock_fisheries = 0 if total_livestock_fisheries <0
gen livestock_fisheries_income = gb011_1 + gb011_max + gb012_1 + gb012_max
gen total_agricultural_income = total_forestry + total_livestock_fisheries + livestock_fisheries_income

// Self-Employed  Activities  
gen total_selfemployed_income = 0
forvalues i = 1(1)4 {
	replace total_selfemployed_income = total_selfemployed_income + gc005_`i'_
	replace total_selfemployed_income = total_selfemployed_income + gc005_`i'__max
}
// Household  Public  Transfer  Income
gen total_transfer_income = gd001_w4_3
forvalues i = 1(1)10 {
	replace total_transfer_income = total_transfer_income + gd002_w4_`i'
}
replace total_transfer_income = total_transfer_income + gd004_w4

// House rent
gen total_house_rent = 0
foreach i in 1 2 3 4 5 7 {
	replace total_house_rent = total_house_rent + ha006_w4_`i'_
}

//Total income
gen total_income = total_household_wage + total_others_wage + total_agricultural_income + total_selfemployed_income + total_transfer_income + total_house_rent
replace total_income=0 if total_income<0 | total_income>10000000
label variable total_income "Total income in a year"

/******************** Income Group ************************/	

egen income_data = cut(total_income), at (0,5000,20000,45000,10000000)
egen income_group = group(income_data)
label define income_group_label 1 "0-5000" 2 "5000-20000" 3 "20000-45000" 4"45000+", replace
label values income_group income_group_label
label variable income_group "Income group"
tab income_group,m 


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

replace age=(2018-ca000_w3_1__) if age==.
replace age=(2018-ca001_w3_1__) if age==.
replace age=(2018-ca006_w3_3__) if age==.
replace age=(2018-ca007_w3_3__) if age==.
replace age=(2018-xsibbirth_s__) if age==.
replace age=(2018-xsibbirth__) if age==.
replace age=(2018-xchildbirth__) if age==.

order age, after(communityID)
drop birthyear birthmonth birth_type surveymonth surveyyear 

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
lab var ch_good "Child Health Good or VG?"
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
replace ba000_w2_3=xsibgender_s__ if ba000_w2_3==. 
replace ba000_w2_3=xsibgender__ if ba000_w2_3==. 
replace ba000_w2_3=xchildgender__ if ba000_w2_3==. 
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
replace be001=cb063__ if be001==. 
gen married = inlist(be001,1,2) if inlist(be001,1,2,3,4,5,6)
label define married 0 "UnMarried" 1 "Married" ,modify
drop be001
tab married,m

save $working_data/2018_All_combine, replace 


/******************************* Graph ************************************/
/*

use $working_data/2018_All_combine, clear 


// Adult health against child environment situations
gen adult_health_1 = 0
replace adult_health_1=1 if health_status_group==1
gen adult_health_2 = 0
replace adult_health_2=1 if health_status_group==2
gen adult_health_3 = 0
replace adult_health_3=1 if health_status_group==3

graph bar (mean) adult_health_1 (mean) adult_health_2 (mean) adult_health_3, ///
        over(ce_good) percentages stack blabel(bar, format(%9.1f)) ymtick(, labels valuelabel) ytitle("Proportion of adult health in children's environment group") title("Adult health against child environment conditions") ///
		note(Source: CHARLS 2018 database) legend(label(1 "Very Good") label(2 "Good") label(3 "Not Good") label(4 "Poor"))

graph export $figures/adult_environment_child_environment.png, replace


// 3d-- ah_good\ce_good with age_group1

graph bar (mean) ah_good,  ///
  over(ce_good, descend label(labsize(*.75))) ///
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
  over(ce_good, label(labsize(*.65))) ///
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


// Disease
// 3d-- disease \ ch with age_group1

graph bar (mean)has_hypertension_dyslipidemia,  ///
  over(ce_good, label(labsize(*.65))) ///
  over(age_group1) ///
  bargap(-30) nofill ///
  ytitle("Proportion of people with diseases") ///
  title("Hypertension and Dyslipidemia") ///
  subtitle("by childhood environment and age") ///
  note("Source: CHARLS 2018 Database") 
graph save $figures/has_hypertension_dyslipidemia.png, replace

graph bar (mean)has_cancer,  ///
  over(ce_good, label(labsize(*.65))) ///
  over(age_group1) ///
  bargap(-30) nofill ///
  ytitle("Proportion of people with diseases") ///
  title("Cancer") ///
  subtitle("by childhood environment and age") ///
  note("Source: CHARLS 2018 Database") 
graph save $figures/has_cancer.png, replace

graph bar (mean)has_heart_disease,  ///
  over(ce_good, label(labsize(*.65))) ///
  over(age_group1) ///
  bargap(-30) nofill ///
  ytitle("Proportion of people with diseases") ///
  title("Heart disease") ///
  subtitle("by childhood environment and age") ///
  note("Source: CHARLS 2018 Database") 
graph save $figures/has_heart_disease.png, replace

graph bar (mean)has_respiratory_disease ,  ///
  over(ce_good, label(labsize(*.65))) ///
  over(age_group1) ///
  bargap(-30) nofill ///
  ytitle("Proportion of people with diseases") ///
  title("Respiratory disease") ///
  subtitle("by childhood environment and age") ///
  note("Source: CHARLS 2018 Database") 
graph save $figures/has_respiratory_disease.png, replace

ggplot(health_status, aes(x = `State or Province`)) +
        geom_bar() +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))
/************* Table *************/


use $working_data/2018_Background_Health_Income_Construction.dta, clear 

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

//check-- // Table 4
xi: probit ah_good ce_good age age_2 i.education_group female 
mfx
est store Self_reported

//xi:reg qk002 ce_good age age_2 i.education_group married female
//est store Knee_high

xi: reg cognitive_level_3 ce_good age age_2 i.education_group female 
est store cognitive

outreg2 [Self_reported cognitive] using "$tables\for_ah_good.xls",replace

// Interaction with female grouup
xi: probit ah_good i.ce_good*female age age_2 i.education_group
mfx
est store intersect1
xi: reg cognitive_level_3 i.ce_good*female age age_2 i.education_group
est store intersect3

outreg2 [intersect1 intersect3 ] using "$tables\ah_good_female*ch_good.xls",replace

//Table 5
// Interaction with age grouup
xi: probit ah_good i.ce_good*i.age_group1 i.education_group female married 
mfx
est store WA1

//xi: reg BMI i.ce_good*i.age_group1 i.education_group  married female
//est store WA2

xi: reg cognitive_level_3 i.ce_good*i.age_group1 i.education_group female married 
est store WA2

outreg2[WA1 WA2] using "$tables\ah_good_age*ch_good.xls",replace


/* With community / province fixed effects */ //Table 6
xi i.communityID
forvalues i = 2(1)449{
	gen _Icomm_`i' = _Icommunity_`i'
}
xi i.education_group
forvalues i = 2(1)5{
	gen _Iedu_`i'=_Ieducation_`i'
}
//health_status2
xi: reg health_status2 ce_good i.education_group female age age_2 married
est store woCommFE1

xi: reg health_status2 ce_good i.education_group female age age_2 married i.communityID
est store wCommFE2

xi: reg cognitive_level_3 ce_good i.education_group female age age_2 married
est store woCommFE3 

xi: reg cognitive_level_3 ce_good i.education_group female age age_2 married i.communityID
est store wCommFE4

outreg2 [woCommFE1 wCommFE2 woCommFE3 wCommFE4] using "$tables\fixed_effect.xls", stat(coef se) bdec(2) sdec(3) replace label 
//_Icomm_2-_Icomm_449

/* Prohit and Logit */ //Table 7

//OLS_robust_SE
xi:reg ah_good ce_good age age_2 i.education_group female married, vce(robust)
est store OLS_robust_SE

//Probit 
xi:probit ah_good ce_good age age_2 i.education_group female married
mfx
est store Probit

outreg2 [ OLS_robust_SE Probit ] using $tables/ah_good_reg.xls, replace

gen hs = 1 if health_status==1 | health_status==2
replace hs = 2 if health_status==3 
replace hs = 3 if health_status==4 | health_status==5
// ordered probit Table 9
xi: ologit hs ce_good female age age_2 i.education_group married
mfx, predict(p outcome(1)) 
forvalues i = 2/3 {
    mfx, predict(p outcome(`i'))
}
mfx2,replace //mfx2 
outreg2 using $tables\srh_reg_mfx2.xls, cttop(mfx2) replace excel dec(5)





//
xi: reg ah_good age age_2 i.education_group
outreg2 using $tables\ah_good_edu.xls, replace

log close

*/





