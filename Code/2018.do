
/***************************** 2015 *****************************/ 

use $raw_data/2018/Demographic_Background.dta, clear 
gen bornplace = .
replace bornplace = bb001
keep householdID ID bornplace

merge 1:1 ID using $raw_data/2015/Demographic_Background.dta, keepusing(ID householdID bb001)
drop if _merge==2
replace bornplace = bb001 if mi(bornplace) & !mi(bb001)
keep householdID bornplace ID
tab bornplace,m 

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
save $working_data/bornplace_2018, replace

/***************************** 2015 Main *****************************/ 

use $raw_data/2018/Demographic_Background.dta, clear
merge 1:1 ID using $raw_data/2018/Health_Status_and_Functioning
drop _merge
merge 1:1 ID using $raw_data/2018/Cognition.dta
drop _merge
merge 1:1 ID using $raw_data/2018/Health_Status_and_Functioning
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
lab def ah_good 0 "Poor" 1 "Good"
lab values ah_good ah_good
tablist ah_good,sort(v)


/****************** Cognitive Function  ***********************/

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

replace cognitive_level = . if wr101_intro==2
tab cognitive_level

replace cognitive_level=. if dc028_w4_s12==12 | dc029_w4_s12==12 | dc030_w4_s12==12
gen mean_cognitive_level = cognitive_level/40

/***************** MAth problems --- Math_score ****************/ 

gen Math_score = 0

//dc029_w3_1 == 6
//dc030_w3_1 == 5

replace Math_score = Math_score+1 if  dc031_w3_1 == 9
replace Math_score = Math_score+1 if  dc031_w3_2 == 10 
replace Math_score = Math_score+1 if  dc031_w3_3 ==4

replace Math_score = Math_score+1 if  dc032_w3_1 == 4
replace Math_score = Math_score+1 if  dc032_w3_2 == 3
replace Math_score = Math_score+1 if  dc032_w3_3 == 14

replace Math_score = Math_score+2 if  dc033_w3_1 == 4
replace Math_score = Math_score+2 if  dc033_w3_2 == 13
replace Math_score = Math_score+2 if  dc033_w3_3 == 2

replace Math_score = Math_score+3 if  dc034_w3_1 == 9
replace Math_score = Math_score+3 if  dc034_w3_2 == 5
replace Math_score = Math_score+3 if  dc034_w3_3 == 15

replace Math_score = Math_score+4 if  dc035_w3_1 == 6
replace Math_score = Math_score+4 if  dc035_w3_2 == 12
replace Math_score = Math_score+4 if  dc035_w3_3_1 == 9
replace Math_score = Math_score+4 if  dc035_w3_3_2 == 9

replace Math_score=. if mi(dc031_w3_1) & mi(dc031_w3_2) & mi(dc031_w3_3) & mi(dc032_w3_1) & mi(dc032_w3_2) & mi(dc032_w3_3) & mi(dc033_w3_1) & mi(dc033_w3_2) & mi(dc033_w3_3) & mi(dc034_w3_1) & mi(dc034_w3_2) & mi(dc034_w3_3) & mi(dc035_w3_1) & mi(dc035_w3_2) & mi(dc035_w3_3_1) & mi(dc035_w3_3_2) 



gen Math_1=0
replace Math_1 = Math_1+1 if dc031_w3_1==9
replace Math_1 = Math_1+1 if dc031_w3_2==10
replace Math_1 = Math_1+1 if dc031_w3_3==4

gen Math_2=0 if Math_1==0
replace Math_2 = Math_2+1 if  dc032_w3_1 == 4
replace Math_2 = Math_2+1 if  dc032_w3_2 == 3
replace Math_2 = Math_2+1 if  dc032_w3_3 == 14

gen Math_3=0 if Math_1==1
replace Math_3 = Math_3+2 if  dc033_w3_1 == 4
replace Math_3 = Math_3+2 if  dc033_w3_2 == 13
replace Math_3 = Math_3+2 if  dc033_w3_3 == 2

gen Math_4=0 if Math_1==2
replace Math_4 = Math_4+3 if  dc034_w3_1 == 9
replace Math_4 = Math_4+3 if  dc034_w3_2 == 5
replace Math_4 = Math_4+3 if  dc034_w3_3 == 15

gen Math_5=0 if Math_1==3
replace Math_5 = Math_5+4 if  dc035_w3_1 == 6
replace Math_5 = Math_5+4 if  dc035_w3_2 == 12
replace Math_5 = Math_5+4 if  dc035_w3_3_1 == 9
replace Math_5 = Math_5+4 if  dc035_w3_3_2 == 9

gen MM =.
forvalues i =2(1)5{
	replace MM = Math_1+Math_`i' if !mi(Math_`i')
}


forvalues i = 1(1)5{
	replace Math_`i'=0 if Math_`i'==.
}

gen Ma_Max = max(Math_1, Math_2, Math_3, Math_4, Math_5)

gen Ma_Total = Math_1+ Math_2+ Math_3+ Math_4+ Math_5




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
 
 

// Optimistic

gen optimistic = 0
replace optimistic= optimistic+1 if dc009==1
foreach i in 10 11 12 14 15 17 18{
	replace optimistic= optimistic+1 if dc0`i'==1
}
replace optimistic=optimistic+1 if dc013==4
replace optimistic=optimistic+1 if dc016==4


replace optimistic = . if mi(dc009) & mi(dc010) & mi(dc011) & mi(dc012) & mi(dc013) & mi(dc014) & mi(dc015) & mi(dc016) & mi(dc017) & mi(dc018)

gen optimistic_group1 = 1 if optimistic>=5 & optimistic!=. 
replace optimistic_group1 =0 if optimistic<5
gen optimistic_group2 = 1 if optimistic>=4 & optimistic!=. 
replace optimistic_group2 =0 if optimistic<4
gen optimistic_group3= 1 if optimistic>=6 & optimistic!=. 
replace optimistic_group3 =0 if optimistic<6


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


/* smoke drink*/
gen smoking =1 if da059==1 
replace smoking=0 if da059==2
replace smoking = 1 if zsmoke==1 // (83 missing)


gen drinking= 0 if da069==1 // 11425 missing
replace drinking=1 if da069==2 | da069==3 | da067==1 | da067==2

replace drinking =0 if zda069==1 
replace drinking =1 if zda069==2 | zda069==3 // 75 missing

save $working_data/2018_main_y_control.dta, replace 



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
save $working_data/2018_main_y_x_control.dta, replace 



// TSP & Meteorological
use $working_data/2018_main_y_x_control.dta, clear

//merge m:1 communityID using $raw_data/charls_community_tsp.dta
//merge m:1 communityID using $raw_data/charls_community_tsp_quartic.dta
merge m:1 communityID using $raw_data/charls_community_tsp_cubic.dta
//merge m:1 communityID using $raw_data/charls_community_tsp_quadratic.dta
drop _merge

gen TSP=.
forvalues i = 1981(1)1995{
	replace TSP = pollution_`i' if birthyear==`i'
}
rename city_eng location_pinyin
save $working_data/2018_main_TSP.dta, replace 

// Meteorological data
use $raw_data/meteo_annual_average.dta, clear
duplicates drop location_pinyin, force // drop 1 : Yichun
merge 1:m location_pinyin using $working_data/2018_main_TSP.dta
drop _merge
gen temperature=.
gen sea_level = .
gen wind_speed = .
forvalues i = 1981(1)1995{
	replace temperature = air_temperature_ave`i' if birthyear==`i'
	replace sea_level = sea_level_pressure_ave`i' if birthyear==`i'
	replace wind_speed = wind_speed_ave`i' if birthyear==`i'
}

save $working_data/2018_Main_All.dta, replace // all sh ce TSP Met data




/****************************** 2018 Child *****************************/ 

//Offspring 
use $raw_data/2018/Family_Information.dta, clear 
keep ID householdID communityID cb052_w3_1_-cb052_w3_15_ cb053_*  cb069_* ///
	cb063_w3_1_* cb063_w3_6_* xchildbirth* xchildgender* zchildedu* cb052_w4_* 
forvalue i = 1(1)14 {
	replace zchildedu_`i'_ = cb052_w3_`i'_ if cb052_w4_`i'_==2
}
merge m:1 householdID using $working_data/bornplace_2018
keep if _merge==3
drop _merge
save $working_data/Child_2018.dta, replace

// reshape
use $working_data/Child_2018.dta, replace 
drop cb052_w4_* cb052_w3_1_-cb052_w3_15_
reshape long  cb053_@_ cb063_@_ cb091_w4_@_ zchildedu_@_ /*
*/ cb069_@_ cb063_w3_1_@_ cb063_w3_6_@_ xchildbirth_@_ xchildgender_@_ /*
*/ , i(householdID) j(childID)
label var childID "ID of Respondents‘ offspring" //186048


/*********** 2018 Child-Construction *************/ 


// Self Comment of Your Life 
gen health_status=1 if cb063_w3_1__==5 
replace health_status=2 if cb063_w3_1__==4 
replace health_status=3 if cb063_w3_1__==3 
replace health_status=4 if cb063_w3_1__==2 
replace health_status=5 if cb063_w3_1__==1 

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


//d5- childhood environment
merge m:1 ID using $raw_data/2014/family_information.dta, keepusing(ID d5) 
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

// schooling 
gen education = .
replace education = zchildedu__ if education==.
replace education =. if education==999 | education==997
recode education (1=1) (2=2) (3/4=3) (5=4) (6/11=5),gen(education_group)
label define label_education 1 "Illiterate" 2 "Did not finish primary" 3 "Finished primary" 4 "Middle school" 5 "High school and above"
label values education_group label_education
tab education_group, m
label variable education_group "Education Group"

/* Age */

gen age=.
replace age=(2018-xchildbirth__) if age==.

gen age_2 = age*age

/* Gender */
gen gender=.
replace gender=xchildgender__ if gender==. 
gen female=(gender-1)
save $working_data/2018_child_d5.dta, replace 



// PSU TSP

//merge m:1 communityID using $raw_data/charls_community_tsp.dta
//merge m:1 communityID using $raw_data/charls_community_tsp_quartic.dta
merge m:1 communityID using $raw_data/charls_community_tsp_cubic.dta
//merge m:1 communityID using $raw_data/charls_community_tsp_quadratic.dta

drop _merge

gen TSP=.
forvalues i = 1981(1)1995{
	replace TSP = pollution_`i' if xchildbirth__==`i'
}

rename city_eng location_pinyin
save $working_data/2018_child_TSP.dta, replace 

// Meteorological data
use $raw_data/meteo_annual_average.dta, clear
duplicates drop location_pinyin, force // drop 1 : Yichun
merge 1:m location_pinyin using $working_data/2018_child_TSP.dta
drop _merge
gen temperature=.
gen sea_level = .
gen wind_speed = .
forvalues i = 1981(1)1995{
	replace temperature = air_temperature_ave`i' if xchildbirth__==`i'
	replace sea_level = sea_level_pressure_ave`i' if xchildbirth__==`i'
	replace wind_speed = wind_speed_ave`i' if xchildbirth__==`i'
}

save $working_data/2018_Child_All.dta, replace 



/******************** Rehression - 2018_Child ***************************/ 

use $working_data/2018_Child_All.dta, clear 

xi: probit ah_good ce_good i.education_group age age_2 female 
mfx
est store childhood1
outreg2 [childhood1] using "$tables\2018_ah_good_ce_good.xls",replace


xi: probit ah_good TSP i.education_group age age_2 female temperature, cluster(city) 
mfx
est store TSP1
outreg2 [TSP1] using "$tables\2018_ah_good_TSP.xls",replace


xi: ivreg ah_good (TSP= sea_level wind_speed) i.education_group age age_2 female temperature
est store iv1
outreg2 [iv1] using "$tables\2018_ah_good_TSP_iv.xls",replace

