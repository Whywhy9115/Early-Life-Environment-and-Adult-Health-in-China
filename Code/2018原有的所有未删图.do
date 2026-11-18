
/*******************ç*********** Graph ************************************/


use $working_data/2018_Background_Health_Income_Construction.dta, clear 


// Adult health against child environment situations
gen adult_health_1 = 0
replace adult_health_1=1 if health_status_group==1
gen adult_health_2 = 0
replace adult_health_2=1 if health_status_group==2
gen adult_health_3 = 0
replace adult_health_3=1 if health_status_group==3



graph bar (mean) adult_health_1 (mean) adult_health_2 (mean) adult_health_3, ///
        over(child_health) percentages stack blabel(bar, format(%9.1f)) ymtick(, labels valuelabel) title("Adult health against child environment situations") ///
		note(Data: CHARLS 2018 Baseline) legend(label(1 "Very Good") label(2 "Good") label(3 "Not Good") label(4 "Poor"))

graph export $figures/adult_environment_child_environment.png, replace


// 3d-- ah_good\ch_good with age_group1

graph bar (mean) ah_good,  ///
  over(ch_good, descend label(labsize(*.75))) ///
  over(age_group1) ///
  bargap(-30) nofill ///
  ytitle("Adult health") ///
  title("Adult health") ///
  subtitle("by childhood health and age") ///
  note("Source: CHARLS 2018 Baseline") 
graph save $figures/ah_ch_age.png,replace


/* Income */
// income with age

egen mincome_age_group = mean(total_income), by(age_group3)
twoway scatter mincome_age_group age_group3, connect(l) sort ///
                       xlabel(1 "45-47" 2 "48-50" 3 "51-53" 4 "54-56" 5 "57-59" 6 "60-62" 7 "63-65" ///
                       8 "66-68" 9 "69-71" 10 "72-74" 11 "75-77" 12 "78-80" 13 "81+",labsize(small)) ///
				ytitle("Total income") title("Total income by Age")  ///
					   caption("Data Source: CHARLS 2018 baseline")

graph export $figures/income_age_group.png, replace

// income with edcation
egen mincome_education_group = mean(total_income), by(education_group)
twoway scatter mincome_education_group education_group, connect(l) sort ///
                       xlabel( 1 "Illiterate" 2 "Did not finish primary" 3 "Finished primary" 4 "Middle school" 5 "High school and above",labsize(small)) ///
				ytitle("Total income") title("Total income by education")  ///
					   caption("Data Source: CHARLS 2018 baseline")

graph export $figures/income_education_group.png, replace


// 3d -- income education age
graph bar income_data2,  ///
  over(age_group1, descend label(labsize(*.75))) ///
  over(edu_midabove) ///
  bargap(-30) nofill ///
  ytitle("Adult income") ///
  title("Adult income") ///
  subtitle("by schooling and age") ///
  note("Source: CHARLS 2018 Baseline") 
graph save $figures/income_age_education.png, replace



// satisfaction with age group.   /* scatter and lowess */					   
twoway scatter msatisfaction_age_group age_group3, connect(l) sort || lowess satisfaction age_group3, ///
                       xlabel(1 "45-47" 2 "48-50" 3 "51-53" 4 "54-56" 5 "57-59" 6 "60-62"  7 "63-65" ///
						8 "66-68" 9 "69-71" 10 "72-74" 11 "75-77" 12 "78-80" 13 "81+",labsize(small)) ///
					   ytitle("satisfaction") title("Satisfaction by Age")  ///
					   legend(label(1 "Mean satisfaction") label(2 "Lowess curve")) ///
					   caption("Data Source: CHARLS 2018 baseline")

graph export $figures\msatisfaction_age_group_lowess.png, replace


// schooling with age group  /* scatter and lowess */	

egen mschooling_age_group = mean(schooling), by(age_group3)
					   
twoway scatter mschooling_age_group age_group3, connect(l) sort || lowess schooling age_group3, ///
                       xlabel(1 "45-47" 2 "48-50" 3 "51-53" 4 "54-56" 5 "57-59" 6 "60-62"  7 "63-65" ///
						8 "66-68" 9 "69-71" 10 "72-74" 11 "75-77" 12 "78-80" 13 "81+",labsize(small)) ///
					   ytitle("Schooling") title("Schooling by Age")  ///
					   legend(label(1 "Mean Schooling") label(2 "Lowess curve")) ///
					   caption("Data Source: CHARLS 2018 baseline")

graph export $figures\schooling_age_scatter_lowess.png, replace


// 3d Adult health by childhood education  
graph bar (mean) ah_good,  ///
  over(ch_good, label(labsize(*.65))) ///
  over(edu_midabove) ///
  bargap(-30) nofill ///
  ytitle("Adult health") ///
  title("Adult health") ///
  subtitle("by childhood health and education") ///
  note("Source: CHARLS 2018 Baseline") 
graph save $figures/ah_ch_edu.png,replace

// Disease

egen mhas_hypertension_dyslipidemia = mean(has_hypertension_dyslipidemia), by(age_group3)
twoway scatter mhas_hypertension_dyslipidemia age_group3, connect(l) sort ///
                       xlabel(1 "45-47" 2 "48-50" 3 "51-53" 4 "54-56" 5 "57-59" 6 "60-62" ///
					   7 "63-65" ///
					 8 "66-68" 9 "69-71" 10 "72-74" 11 "75-77" 12 "78-80" 13 "81+", labsize(small)) ///
				ytitle("Incidence rate") title("Incidence rate of hypertension and dyslipidemia by Age")  ///
					   caption("Data Source: CHARLS 2018 baseline")
graph save gr1 
graph export $figures/has_hypertension_dyslipidemia.png, replace

egen mhas_cancer = mean(has_cancer), by(age_group3)
twoway scatter mhas_cancer age_group3, connect(l) sort ///
                       xlabel(1 "45-47" 2 "48-50" 3 "51-53" 4 "54-56" 5 "57-59" 6 "60-62" ///
					   7 "63-65" ///
					 8 "66-68" 9 "69-71" 10 "72-74" 11 "75-77" 12 "78-80" 13 "81+", labsize(small)) ///
					   ytitle("Incidence rate") title("Incidence rate of cancer by Age")  ///
					   caption("Data Source: CHARLS 2018 baseline")
graph save gr2 
graph export $figures/has_cancer.png, replace


egen mhas_heart_disease = mean(has_heart_disease), by(age_group3)
twoway scatter mhas_heart_disease age_group3, connect(l) sort ///
                       xlabel(1 "45-47" 2 "48-50" 3 "51-53" 4 "54-56" 5 "57-59" 6 "60-62" ///
					   7 "63-65" ///
					 8 "66-68" 9 "69-71" 10 "72-74" 11 "75-77" 12 "78-80" 13 "81+", labsize(small)) ///
					   ytitle("Incidence rate") title("Incidence rate of heart disease by Age")  ///
					   caption("Data Source: CHARLS 2018 baseline")
graph save gr3 
graph export $figures/has_heart_disease.png, replace


egen mhas_digestiveTract_disease = mean(has_digestiveTract_disease), by(age_group3)
twoway scatter mhas_digestiveTract_disease age_group3, connect(l) sort ///
                       xlabel(1 "45-47" 2 "48-50" 3 "51-53" 4 "54-56" 5 "57-59" 6 "60-62" ///
					   7 "63-65" ///
					 8 "66-68" 9 "69-71" 10 "72-74" 11 "75-77" 12 "78-80" 13 "81+", labsize(small)) ///
					   ytitle("Incidence rate") title("Incidence rate of digestive tract disease by Age")  ///
					   caption("Data Source: CHARLS 2018 baseline")
graph save gr4 
graph export $figures/has_digestiveTract_disease.png, replace


egen mhas_respiratory_disease = mean(has_respiratory_disease), by(age_group3)
twoway scatter mhas_respiratory_disease age_group3, connect(l) sort ///
                       xlabel(1 "45-47" 2 "48-50" 3 "51-53" 4 "54-56" 5 "57-59" 6 "60-62" ///
					   7 "63-65" ///
					 8 "66-68" 9 "69-71" 10 "72-74" 11 "75-77" 12 "78-80" 13 "81+", labsize(small)) ///
					   ytitle("Incidence rate") title("Incidence rate of respiratory disease by Age")  ///
					   caption("Data Source: CHARLS 2018 baseline")
graph save gr5 
graph export $figures/has_respiratory_disease.png, replace


egen mhas_other_disease = mean(has_other_disease), by(age_group3)
twoway scatter mhas_other_disease age_group3, connect(l) sort ///
                       xlabel(1 "45-47" 2 "48-50" 3 "51-53" 4 "54-56" 5 "57-59" 6 "60-62" ///
					   7 "63-65" ///
					 8 "66-68" 9 "69-71" 10 "72-74" 11 "75-77" 12 "78-80" 13 "81+", labsize(small)) ///
					   ytitle("Incidence rate") title("Incidence rate of other diseases by Age")  ///
					   caption("Data Source: CHARLS 2018 baseline")
graph save gr6 
graph export $figures/has_other_disease.png, replace


// 3d-- disease \ ch with age_group1

graph bar (mean)has_hypertension_dyslipidemia (mean)has_cancer (mean)has_heart_disease (mean)has_digestiveTract_disease (mean)has_respiratory_disease (mean)has_other_disease ,  ///
  over(ch_good, label(labsize(*.65))) ///
  over(age_group1) ///
  bargap(-30) nofill ///
  ytitle("Percentage of diseases") ///
  title("Diseasea") ///
  subtitle("by childhood health and education") ///
  note("Source: CHARLS 2018 Baseline") 
graph save $figures/mm.png,replace

//Gender /* Pie */
graph pie if gender~=0, over(gender)  plabel(_all perc, format(%3.1f)) ///
		   title("Sex Composition of CHARLS Respondents") ///
		   note("Source: CHARLS 2018")
graph export $figures/gender_pie.png, replace


//Marital status

/* Histogram */	   	
histogram married,percent start(0.0) width(0.5) ylabel(, grid) xlabel(#2,valuelabel angle(forty_five)) /// 
          discrete addlabels title("Marital Status") ///
          note("Source: CHARLS 2018")
graph export $figures/Mstatus_hist.png, replace

//Education 

//histogram		  
histogram education_group,percent start(0) width(0.5) ylabel(0.0(2.0)28.0) xlabel(#5,valuelabel angle(stdarrow)) /// 
          discrete addlabels title("The Distribution of Education") ///
          note("Source: CHARLS 2018")
graph export $figures/education_hist.png, replace

//Age 

/* Box plot */
graph box age, title("Age of Respondent") note("Source: CHARLS 2018") // 

graph export $figures/age_box.png, replace

/* Pie chart */
graph pie, over(age_group2)  plabel(_all perc, format(%3.1f)) ///
		   title("The Distribution of Age") ///
		   note("Source: CHARLS 2018")
graph export $figures/Age_pie.png, replace

/* Compare with normal distribution */
histogram age if age~=0, percent width(1.0) ///
          normal title("The Distribution of Age") ///
          note("Source: CHARLS 2018")
graph export $figures/Age_normal_hist.png, replace


histogram age if age~=0, percent width(1.0) ///
          kdensity title("The Distribution of Birth Year") ///
          note("Source: CHARLS 2011=8")
graph export $figures/Age_Kernel_hist.png, replace

/* Schooling */
graph pie, over(schooling_group_3)  plabel(_all perc, format(%3.1f)) ///
		   title("The Distribution of Years of Schooling") ///
		   note("Source: CHARLS 2018")
graph export $figures/Schooling_pie.png, replace

/* Health Status */ 
graph pie, over(health_status_group)  plabel(_all perc, format(%3.1f)) ///
		   title("The Distribution of Health Status") ///
		   note("Source: CHARLS 2018")
graph export $figures/health_status_pie.png, replace


label variable diseases_group "Kinds of diseases"

histogram diseases_group,percent start(0.0) width(0.4) ylabel(, grid) xlabel(#6,valuelabel angle(forty_five) labsize(3)) addlabopts(mlabsize(3)) lcolor(black) ///
          discrete addlabels title("The Distribution of Diseases") ///
          note("Source: CHARLS 2018")
graph export $figures/diseases_group_hist.png, replace


//Childhood environment changing with age
egen mch_good = mean(ch_good) if age>=45 & age<=85 , by(age)
label variable mch_good "Good childhood environment"

twoway scatter mch_good age if age>=45 & age<=85, connect(l) sort || lfit mch_good age if age>=45 & age<=85, ///
                       ylabel(0.4(0.1)0.9, gmax angle(horizontal)) ///
					   xlabel(45(5)85) ///
					   legend(order(1 "Childhood health")) ///
                       title("Percentage Reporting Good/Good Childhood Environment", size(medium ))  ///
					   caption("Data Source: CHARLS 2018 baseline")			
graph save gra1 
graph save $figures/ch_good_age.png,replace

//Adult health changing with age
egen mah_good = mean(ah_good) if age>=45 & age<=85 , by(age)
label variable mah_good "Good adult health"

twoway scatter mah_good age if age>=45 & age<=85, connect(l) sort || lfit mah_good age if age>=45 & age<=85, ///
                       ylabel(0.4(0.1)1.0, gmax angle(horizontal)) ///
					   xlabel(45(5)85) ///
					   legend(order(1 "Adult health")) ///
                       title("Percentage Reporting Good/Good Adult Health", size(medium))  ///
					   caption("Data Source: CHARLS 2018 baseline")		
graph save gra2
graph save $figures/ah_good_age.png,replace

graph combine gra1.gph gra2.gph

// 3d-- child environment _ adult health
twoway scatter mch_good age if age>=45 & age<=85, connect(l) sort || scatter mah_good age if age>=45 & age<=85, connect(l) sort ///
                       || lfit mch_good age if age>=45 & age<=85 || lfit mah_good age if age>=45 & age<=85, ///
                       ylabel(0.4(0.1)1.0, gmax angle(horizontal)) ///
					   xlabel(45(5)85) ///
					   legend(order(1 "Childhood environment" 2 "Adult health")) ///
                       title("Percentage Reporting Better Health", size(medium))  ///
					   caption("Data Source: CHARLS 2018 baseline")					   
graph save $figures/ch_ah_age.png,replace

**Adult health varies by gender**
egen mah_good_male = mean(ah_good) if female==0 & age>45 & age<=85, by(age)
label variable mah_good_male "mean adult health of male at each age"

egen mah_good_female = mean(ah_good) if female==1 & age>45 & age<=85, by(age)
label variable mah_good_female "mean adult health of female at each age"

 
twoway scatter mah_good_male age if age>45 & age<=85, connect(l) sort ///
               || scatter mah_good_female age if age>45 & age<=85, connect(l) sort ///
                        ylabel(0.5(0.05)1.0, gmax angle(horizontal)) ///
					   xlabel(45(5)85) ///
					   legend(order(1 "male" 2 "female")) ///
                       title("Percentage Reporting Very Good/Good Adult Health", size(medium ))  ///
					   caption("Data Source: CHARLS 2018 baseline")					   
graph save $figures/ah_good_age_gender.png,replace







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
drop ge*

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

