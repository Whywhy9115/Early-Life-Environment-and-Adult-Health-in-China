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

// Graph 


// TSP
// Urban Rural 
use $raw_data/charls_community_tsp_quartic.dta, clear 
duplicates drop city, force 
reshape long pollution_@ /*
*/,i(city) j(year)

bysort year urban_nbs: egen pollution_type = mean(pollution_)

tabstat pollution_type if urban_nbs == 0, by(year) s(mean)
tabstat pollution_type if urban_nbs == 1, by(year) s(mean)

xtline pollution_type, overlay t(year) i(urban_nbs)
graph save $figures/TSP_urban_rural.png, replace


// cities 
use $raw_data/charls_community_tsp_quartic.dta, clear 
duplicates drop city, force 
reshape long pollution_@ /*
*/,i(city) j(year)

keep if city=="北京" | city=="哈尔滨市" | city=="重庆市" | city=="上海市"

bysort year city: egen pollution_type = mean(pollution_)

xtline pollution_type, overlay t(year) i(city_eng)

graph save $figures/TSP_city.png, replace



// Main part

use $working_data/Main_y_x_control.dta, clear

label define label_ce_good 0 "Poor" 1 "Good"
label values ce_good label_ce_good

gen adult_health_1 = 0
replace adult_health_1=1 if health_status_group==1
gen adult_health_2 = 0
replace adult_health_2=1 if health_status_group==2
gen adult_health_3 = 0
replace adult_health_3=1 if health_status_group==3

graph bar (mean) adult_health_1 (mean) adult_health_2 (mean) adult_health_3, ///
        over(ce_good) percentages stack blabel(bar, format(%9.1f)) ymtick(, labels valuelabel) title("Adult health against child environment situations") ///
		note(Data: CHARLS) legend(label(1 "Bad") label(2 "Fine") label(3 "Good"))

graph save $figures/adult_environment_child_environment.png, replace


// Adult health by childhood environment and age 


graph bar (mean) ah_good,  ///
  over(ce_good, descend label(labsize(*.75))) ///
  over(age_group1) ///
  bargap(-30) nofill ///
  ytitle("Adult health") ///
  title("Adult health") ///
  subtitle("by childhood environment quality and age") ///
  note("Source: CHARLS") 
graph save $figures/ah_ch_age.png,replace, replace


// Adult health by childhood education  
gen edu_midabove = (education_group ==4 | education_group ==5) if education_group !=. 

label define label_edu_midabove 0 "Below Middle School" 1 "Middle School and Above"
label values edu_midabove label_edu_midabove

graph bar (mean) ah_good,  ///
  over(ce_good, label(labsize(*.65))) ///
  over(edu_midabove) ///
  bargap(-30) nofill ///
  ytitle("Adult health") ///
  title("Adult health") ///
  subtitle("by childhood environment quality and education") ///
  note("Source: CHARLS") 
graph save $figures/ah_ch_edu.png,replace, replace 
