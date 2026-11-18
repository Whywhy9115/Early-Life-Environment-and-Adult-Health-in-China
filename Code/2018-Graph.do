
/*********** 2018 - Graph ***********/

clear
clear matrix
set more off
capture log close

global root= "/Users/jy/Desktop/Qiu"
global dofiles= "$root/Dofiles"
global logfiles= "$root/Logfiles"
global raw_data= "$root/Raw_data/2018"
global working_data= "$root/Working_data/2018"
global temp_data= "$root/Temp_data"
global tables= "$root\Tables"
global figures= "$root/Figures/2018"

log using $logfiles/2018-Graph.log, replace
use $working_data/2018_Background_Health_Income_Construction.dta, clear 


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
codebook education

label define bd001_w2_4 1 "No Education" 2 "Under Primary" 3 "Sishu" 4 "Elementary" ///
                  5 "Middle" 6 "High" 7 "Vocational" 8 "2/3y College" 9 "4y College" ///
				  10 "Master" 11 "Doctoral",modify //redefine label
//histogram		  
histogram education,percent start(1.0) width(0.5) ylabel(0.0(2.0)28.0) xlabel(#10,valuelabel angle(stdarrow)) /// 
          discrete addlabels title("The Distribution of Education") ///
          note("Source: CHARLS 2018")
graph export $figures/education_hist.png, replace


//Age 

/* Box plot */
graph box age, title("Age of Respondent") note("Source: CHARLS 2018") // 

graph export $figures/age_box.png, replace

/* Pie chart */
graph pie, over(age_group4)  plabel(_all perc, format(%3.1f)) ///
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


histogram diseases_group,percent start(0.0) width(0.4) ylabel(, grid) xlabel(#6,valuelabel angle(forty_five) labsize(3)) addlabopts(mlabsize(3)) lcolor(black) ///
          discrete addlabels title("The Distribution of Diseases") ///
          note("Source: CHARLS 2018")
graph export $figures/diseases_group_hist.png, replace



log close

