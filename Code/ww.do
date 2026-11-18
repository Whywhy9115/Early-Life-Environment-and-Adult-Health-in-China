

//1:1 part
use $raw_data/2013/PSU.dta, clear
duplicates drop city,force 
rename city_eng location_pinyin

duplicates drop location_pinyin,force 

merge 1:1 location_pinyin using $raw_data/meteo_annual_average_360_fix, // all 


$raw_data/meteo_annual_average_360_temp
gen match=.
replace match = 1 if _merge==3
keep if _merge==1 // charls 中有的 但没有merge上的

keep city location_pinyin match province

save $raw_data/not_match_charls, replace // 354 city 是PSU的







//1:1 part
use $raw_data/2013/PSU.dta, clear
duplicates drop city,force 
rename city_eng location_pinyin

duplicates drop location_pinyin,force 

merge 1:1 location_pinyin using $raw_data/meteo_annual_average_360_temp
gen match=.
replace match = 1 if _merge==3
keep if _merge==2 // charls 中有的 但没有merge上的

keep city location_pinyin match province

merge 1:1 location_pinyin using $raw_data/meteo_annual_average_360_temp
keep if _merge==3
keep location location_pinyin province match 

save $raw_data/not_match_me, replace // 272 city 是me的 







// merge option 
use $raw_data/meteo_annual_average_360, clear // all 
duplicates drop location_pinyin,force 
save $raw_data/meteo_annual_average_360_temp, replace // all 




use $raw_data/2013/PSU.dta, clear
duplicates drop city, force
save $raw_data/2013/PSU_unique.dta, replace // 125 city 




// 更新内容
use $raw_data/meteo_annual_average_360_fix, replace // all 272 原始两个数据集没有match上的，现在match上了。match=2
save $raw_data/meteo_annual_average_360_fix, replace // all 

use $raw_data/meteo_annual_average_360, clear
rename location_pinyin city_eng
merge 1:1 location using $raw_data/meteo_annual_average_360_fix
replace city_eng = location_pinyin if match== 2
drop _merge
drop location_pinyin match
save $working_data/meteo_annual_average_360_fix.dta, replace // 272


//测
use $working_data/meteo_annual_average_360_fix.dta, clear // all 316
duplicates drop city_eng, force
merge 1:m city_eng using $raw_data/2013/PSU_unique.dta // 最原本是42 （83）

use $raw_data/2013/PSU_unique.dta, clear // all 316
merge m:1 communityID using $raw_data/charls_community_tsp_quartic.dta




// ah_good mean
use $raw_data/2011/health_status_and_functioning_temp.dta, clear

gen health_status_2011=1 if da002==5 | da001==5
replace health_status_2011=2 if da002==4 | da001==4
replace health_status_2011=3 if da002==3 | da001==3
replace health_status_2011=4 if da002==2 |  da001==2
replace health_status_2011=5 if da002==1 | da001==1
keep ID health_status_2011

merge 1:1 ID using $raw_data/2013/health_status_and_functioning.dta
keep if _merge==3
drop _merge 

gen health_status_2013=1 if da002==5 | da001==5
replace health_status_2013=2 if da002==4 | da001==4
replace health_status_2013=3 if da002==3 | da001==3
replace health_status_2013=4 if da002==2 |  da001==2
replace health_status_2013=5 if da002==1 | da001==1

keep ID health_status_2011 health_status_2013

merge 1:1 ID using $raw_data/2015/health_status_and_functioning.dta
keep if _merge==3
drop _merge 

gen health_status_2015=1 if da002==5 | da001==5
replace health_status_2015=2 if da002==4 | da001==4
replace health_status_2015=3 if da002==3 | da001==3
replace health_status_2015=4 if da002==2 |  da001==2
replace health_status_2015=5 if da002==1 | da001==1
keep ID health_status_2011 health_status_2013 health_status_2015

merge 1:1 ID using $raw_data/2018/health_status_and_functioning.dta
keep if _merge==3
drop _merge 

gen health_status_2018=1 if da002==5 
replace health_status_2018=2 if da002==4 
replace health_status_2018=3 if da002==3
replace health_status_2018=4 if da002==2 
replace health_status_2018=5 if da002==1 

keep ID health_status_2011 health_status_2013 health_status_2015 health_status_2018

gen ah_good_total = (health_status_2011 + health_status_2013 + health_status_2015+ health_status_2018)/4

// 这里算的是四年都在且都回答的

gen ah_good_mean=1 if ah_good_total>=2.6 & ah_good_total!=. 
replace ah_good_mean=0 if ah_good_total<2.6 & ah_good_total!=.



use $working_data/Child_2015.dta, clear
keep ID cb063_w3_1
rename cb063_w3_1 cb063_w3_1_2015

merge 1:1 ID using $working_data/Child_2018.dta, keepusing(ID cb063_w3_1__)
rename cb063_w3_1 cb063_w3_1_2018


// Self Comment of Your Life 
gen health_status=1 if cb063_w3_1__==5 
replace health_status=2 if cb063_w3_1__==4 
replace health_status=3 if cb063_w3_1__==3 
replace health_status=4 if cb063_w3_1__==2 
replace health_status=5 if cb063_w3_1__==1 

gen ah_good=(health_status==5|health_status==4|health_status==3) if !mi(health_status_group)
lab var ah_good "Adult Health is Good?"
lab def ah_good 0 "B" 1 "F G"
lab values ah_good ah_good
tablist ah_good,sort(v)




// tu

use $raw_data/charls_community_tsp_quartic.dta, clear 
duplicates drop city,force
reshape long  pollution_@/*
*/ , i(communityID) j(cityID)
keep if city=="北京" | city=="上海市" | city=="杭州市" | city=="山西市" 
gen k=1 if city=="北京"

// satisfaction with age group.   /* scatter and lowess */					   
twoway scatter pollution_ k
, connect(l) 




twoway scatter (line pollution_ cityID, ), by(city)
			  lpatter(dash dash_dot ) 
			  lwidth(thin thick))
              , 
			  title("U.S. Life Expectancy") subtitle("Males") 
	          legend( order(1 "White men" 2 "Black men")) ;










sort || lowess satisfaction age_group3, ///
                       xlabel(1 "45-47" 2 "48-50" 3 "51-53" 4 "54-56" 5 "57-59" 6 "60-62"  7 "63-65" ///
						8 "66-68" 9 "69-71" 10 "72-74" 11 "75-77" 12 "78-80" 13 "81+",labsize(small)) ///
					   ytitle("satisfaction") title("Satisfaction by Age")  ///
					   legend(label(1 "Mean satisfaction") label(2 "Lowess curve")) ///
					   caption("Data Source: CHARLS 2018 baseline")

graph export $figures\msatisfaction_age_group_lowess.png, replace




// TSP iv robustness :

// table 9 - TSP ordered probit
xi: ologit health_status TSP_total age age_2 female i.education_group urban_nbs temperature_total, cluster(communityID) //5
mfx, predict(p outcome(1)) 
forvalues i = 2/5 {
    mfx, predict(p outcome(`i'))
}
mfx2,replace //mfx2 
est store TSP3

outreg2 [TSP3] using "$tables\All_ah_good_TSP_robustnes1.xls",replace

xi: probit health_status_group1 TSP_total age age_2 female i.education_group urban_nbs temperature_total, cluster(communityID)
mfx 
est store TS4
xi: probit health_status_group2 TSP_total age age_2 female i.education_group urban_nbs temperature_total, cluster(communityID)
mfx 
est store TS5
xi: probit health_status_group3 TSP_total age age_2 female i.education_group urban_nbs temperature_total, cluster(communityID)
mfx 
est store TS6

outreg2 [TS4 TS5 TS6] using "$tables\ecwecqvqec.xls",replace



// table 12 - TSP_total ordered probit
xi: ologit health_status TSP_total age age_2 female i.education_group urban_nbs temperature_total, cluster(communityID) //5
mfx, predict(p outcome(1)) 
forvalues i = 2/5 {
    mfx, predict(p outcome(`i'))
}
mfx2,replace //mfx2 
est store TSP4

outreg2 [TSP4] using "$tables\All_ah_good_TSP_total_robustnes2.xls",replace


// cut off // 全是 - 的 

xi: probit health_status_group1 TSP age age_2 female i.education_group urban_nbs temperature, cluster(communityID)
mfx 
est store TS1
xi: probit health_status_group2 TSP age age_2 female i.education_group urban_nbs temperature, cluster(communityID)
mfx 
est store TS2
xi: probit health_status_group3 TSP age age_2 female i.education_group urban_nbs temperature, cluster(communityID)
mfx 
est store TS3 

outreg2 [TS1 TS2 TS3] using "$tables\deewcwe.xls",replace






// optimistic optimistic_level ah_good health_status
// ce_good TSP TSP_total 
// age age_2 female education_group temperature temperature_total urban_nbs  
// sea_level wind_speed sea_level_total wind_speed_total

