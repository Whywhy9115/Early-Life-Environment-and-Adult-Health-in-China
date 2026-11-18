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

use $raw_data/2011/demographic_background_temp.dta, clear 

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
tablist ah_good,sort(v) 

gen health_status_group1=(health_status==3|health_status==4|health_status==5) if !mi(health_status_group)
gen health_status_group2=(health_status==4|health_status==5) if !mi(health_status_group)
gen health_status_group3=(health_status==5) if !mi(health_status_group)


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


/* Age */ 
gen year=2011
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
replace age=. if age==.d | age==.r 
gen age_2 = age*age


gen age_group1 = age
recode age_group1 (min/44=.)(45/54=1)(55/64=2)(65/200=3)
label define age_grou1_label 1 "45-54" 2 "55-64" 3 "65+",replace
label values age_group1 age_grou1_label
label variable age_group1 "Age_group"

/* Education */ 

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
label values edu_midabove edu_midabove_lab 


/* Gender */
replace rgender=. if rgender==.r
gen gender=rgender 
gen female=gender-1


keep ID communityID householdID age gender female ah_good health_status health_status_group  education education_group age_2 optimistic birthyear optimistic_group_mean optimistic_group1 optimistic_group2 optimistic_group3 optimistic_group4 optimistic_group5 province city city_eng urban_nbs year health_status_group1 health_status_group2 health_status_group3 health_status_group age_group1
save $working_data/2011_main_y_control.dta, replace 



//d5
merge 1:1 ID using $raw_data/2014/family_information.dta, keepusing(ID d5 c4_a) 
keep if _merge==3 
drop _merge 

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
lab var ce_good "Child environment Good or VG?"
lab def ce_good 0 "NG P" 1 "G VG", replace
lab values ce_good ce_good
tablist ce_good,sort(v)


save $working_data/2011_main_y_x_control.dta, replace // remain 60 

