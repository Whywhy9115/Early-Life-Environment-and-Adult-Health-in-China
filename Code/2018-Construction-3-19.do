
/*********** 2018 - Constructed Variables ***********/

clear
clear matrix
set more off
capture log close

global root= "/Users/jy/Desktop/Qiu"
global dofiles= "$root/Dofiles"
global logfiles= "$root/Logfiles"
global raw_data= "$root/Raw_data/2018"
global working_data= "$root/Working_data/2018"
global temp_data= "$root/Temp_data/2018"
global tables= "$root\Tables"
global figures= "$root\Figures"

log using $logfiles/2018-Data_Construction.log, replace
use $working_data/2018_Background_Health_Income_Clean.dta, clear



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
drop birthyear birthmonth birth_type surveymonth surveyyear 
tab age, m


/* Age Group */
egen age_45up2 = cut(age), at(45,55,65,75,200)
egen age_group4 = group(age_45up2)
label define age_group_label2  1 "45-54" 2 "55-64" 3 "65-74" 4"75+", replace 
label values age_group4 age_group_label2
tab age_group4, m
order age_group4, after(age)
drop age_45up2


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
tab female, m
drop gender_max ba*


/* Married */ 
tab be001,m
gen married = inlist(be001,1,2) if inlist(be001,1,2,3,4,5,6)
label define married 0 "UnMarried" 1 "Married" ,modify
drop be001
tab married,m

/* Education */ 
tab bd001_w2_4,m 
gen education = bd001_w2_4
recode education (1=1) (2=2) (3/4=3) (5=4) (6/11=5),gen(education_group)
label define label_education 1 "Illiterate" 2 "Did not finish primary" 3 "Finished primary" 4 "Middle school" 5 "High school and above"
label values education_group label_education
tab education_group, m

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
drop schooling_group


/* Health Status */ 

gen health_status =  da002 
recode health_status (1/2=3) (3=2) (4/5=1), gen(health_status_group)
label define label_health 3 "Good" 2 "Fine" 1 "Bad" 
label values health_status_group label_health
tab health_status_group,m 


/* Kinds of Diseases */  dda007 
gen diseases =. 
replace diseases = 1 if da007_1_==1
replace diseases = 2 if da007_2_==1
replace diseases = 3 if da007_3_==1
replace diseases = 7 if da007_4_==1
replace diseases = 8 if da007_5_==1
replace diseases = 4 if da007_6_==1
replace diseases = 10 if da007_7_==1
replace diseases = 11 if da007_8_==1
replace diseases = 5 if da007_9_==1
replace diseases = 6 if da007_10_==1
replace diseases = 12 if da007_11_==1
replace diseases = 13 if da007_12_==1
replace diseases = 14 if da007_13_==1
replace diseases = 9 if da007_14_==1
replace diseases = 0 if diseases== . 
tab diseases, m
gen kinds_of_diseases = diseases
recode kinds_of_diseases (0=0) (1/2=1) (3/6=2) (7=3) (8/9=4) (10=5) (11/14=6), gen(diseases_group)
label define label_diseases 0 "No diseases" 1 "Hypertension and Dyslipidemia" ///
							2 "Digestive tract disease" 3 "Cancer" ///
							4 "Respiratory disease" 5 "Heart Diseases" 6 "Others"
label values diseases_group label_diseases
tab diseases_group, m





//个人满意度 Self Comment of Your Life

save $working_data/2018_Background_Health_Income_Construction.dta, replace
log close
