

/*********************** Combine  ******************************/ 

use $working_data/2011_main_y_x_control.dta, clear    // 11 main
append using $working_data/2013_main_y_x_control.dta, // 13 main 
append using $working_data/2015_main_y_x_control.dta, // 15 main  
append using $working_data/2015_child_d5.dta          // 15 child
append using $working_data/2018_main_y_x_control.dta, // 18 main  
append using $working_data/2018_child_d5.dta,         // 18 child
save $working_data/Main_y_x_control.dta, replace


use  $working_data/2015_Child_All.dta, clear    // 15 child 
append using $working_data/2015_Main_All.dta,   // 15 main
append using $working_data/2018_Child_All.dta,  // 18 child 
append using $working_data/2018_Main_All.dta,   // 18 main
save $working_data/All_TSP_Meteor.dta, replace 



/******************** Regression *******************/ 

/******************** Life satisfaction & Self-reported health *******************/ 

use $working_data/Main_y_x_control.dta, clear

/******************** life satisfaction *******************/ 

// Table 2
xi: reg optimistic ce_good age age_2 female i.education_group urban_nbs, cluster(communityID)
est store optimistic1

xi: probit optimistic_group_mean ce_good age age_2 female i.education_group urban_nbs, cluster(communityID)
mfx 
est store optimistic2

outreg2 [optimistic1 optimistic2] using "$tables\optimistic_ce_good_main.xls",replace



// Table 3 robustness check 

xi: probit optimistic_group1 ce_good age age_2 female i.education_group urban_nbs, cluster(communityID)
mfx 
est store optimistic3

xi: probit optimistic_group2 ce_good age age_2 female i.education_group urban_nbs, cluster(communityID)
mfx 
est store optimistic4

xi: probit optimistic_group3 ce_good age age_2 female i.education_group urban_nbs, cluster(communityID)
mfx 
est store optimistic5

xi: probit optimistic_group4 ce_good age age_2 female i.education_group urban_nbs, cluster(communityID)
mfx 
est store optimistic6

xi: probit optimistic_group5 ce_good age age_2 female i.education_group urban_nbs, cluster(communityID)
mfx 
est store optimistic7

outreg2 [optimistic3 optimistic4 optimistic5 optimistic6 optimistic7] using "$tables\optimistic_ce_good_robustness1.xls",replace



// Table 4 robustness check - ordered

gen optimistic_level = 1 if optimistic==0 | optimistic==1 | optimistic==2
replace optimistic_level = 2 if optimistic==3 | optimistic==4
replace optimistic_level = 3 if optimistic==5 | optimistic==6
replace optimistic_level = 4 if optimistic==7 | optimistic==8
replace optimistic_level = 5 if optimistic==9 | optimistic==10


xi: ologit optimistic_level ce_good age age_2 female i.education_group urban_nbs, cluster(communityID) 
mfx, predict(p outcome(1)) 
forvalues i = 2/5 {
    mfx, predict(p outcome(`i'))
}
mfx2,replace //mfx2 
est store optimistic8

outreg2 [optimistic8]using "$tables\optimistic_ce_good_robustness2.xls", cttop(mfx2) replace excel dec(5)



/******************** self-reported health *******************/ 

// Table 5
xi: probit ah_good ce_good age age_2 female i.education_group urban_nbs, cluster(communityID)
mfx
est store self2
outreg2 [self2] using "$tables\All_ah_good_ce_good1.xls",replace


//Table 6 --  3 groups
xi: probit health_status_group1 ce_good age age_2 female i.education_group urban_nbs, cluster(communityID)
mfx
est store self3

xi: probit health_status_group2 ce_good age age_2 female i.education_group urban_nbs, cluster(communityID)
mfx
est store self4

xi: probit health_status_group3 ce_good age age_2 female i.education_group urban_nbs, cluster(communityID)
mfx
est store self5

outreg2 [self3 self4 self5]using "$tables\All_ah_good_ce_good2.xls", cttop(mfx2) replace excel dec(5)


// Table 7 - ordered
xi: ologit health_status ce_good age age_2 i.education_group female urban_nbs, cluster(communityID) //5
mfx, predict(p outcome(1)) 
forvalues i = 2/5 {
    mfx, predict(p outcome(`i'))
}
mfx2,replace //mfx2 
est store self3

outreg2 [self3]using "$tables\All_ah_good_ce_good3.xls", cttop(mfx2) replace excel dec(5)



/******************** TSP / IV *******************/ 

use $working_data/All_TSP_Meteor.dta, clear 


// Table 8

xi: probit ah_good TSP age age_2 female i.education_group urban_nbs temperature, cluster(communityID)
mfx
est store TSP1

xi: probit ah_good TSP_total age age_2 female i.education_group urban_nbs temperature_total, cluster(communityID) 
mfx
est store TSP2

xi: probit ah_good TSP_total2 age age_2 female i.education_group urban_nbs temperature_total2, cluster(communityID) 
mfx
est store TSP3

outreg2 [TSP1 TSP2 TSP3] using "$tables\All_ah_good_TSP.xls",replace


// Table 9 -- IV


xi: ivprobit ah_good (TSP= sea_level wind_speed) age age_2 female i.education_group urban_nbs temperature, vce(cluster communityID)
mfx
est store iv1

xi: ivprobit ah_good (TSP_total= sea_level_total wind_speed_total) age age_2 female i.education_group urban_nbs temperature_total, vce(cluster communityID)
mfx
est store iv2

xi: ivprobit ah_good (TSP_total2= sea_level_total2 wind_speed_total2) age age_2 female i.education_group urban_nbs temperature_total2, vce(cluster communityID)
mfx
est store iv3

outreg2 [iv1 iv2 iv3]  using "$tables\All_ah_good_TSP_total_iv.xls", replace


/*
xi:reg TSP_total i.education_group, cluster(communityID)
est store only
xi:reg TSP_total2 i.education_group, cluster(communityID)
est store only2
outreg2 [only only2] using "$tables\only.xls", replace
