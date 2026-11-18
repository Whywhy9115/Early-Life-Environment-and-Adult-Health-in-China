
/*********** 2018- Combine & Clean ***********/

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

log using $logfiles/2018-Data_Combination.log, replace

/*********** 2018-combine-income ***********/

use $raw_data/Individual_Income.dta, clear
merge m:1 householdID using $raw_data/Household_Income.dta
tab _merge
drop if _merge!=3
drop _merge
drop ha*
save $temp_data/2018_Income_combine.dta, replace

/*********** 2018-combine-health ***********/

use $raw_data/Health_Care_and_Insurance.dta, clear 
merge m:1 ID using $raw_data/Health_Status_and_Functioning.dta
tab _merge
drop if _merge!=3
drop _merge
save $temp_data/2018_Health_combine.dta, replace

/*********** 2018-combine-background ***********/

use $raw_data/Demographic_Background.dta, clear
merge m:1 householdID using $raw_data/Family_Information.dta 
tab _merge
drop if _merge!=3
drop _merge
save $temp_data/2018_Background_combine.dta, replace
log close




/*********** 2018-income-clean ***********/
log using $logfiles/2018-CleanData.log, replace
use $temp_data/2018_Income_combine.dta, clear 
drop hc* xrtype 
drop ga008*
drop ga009* ga011* 
// ga001 Receive Wage and Bonus Income
replace ga001= . if mi(ga001)
//ga002 How Much Receive
replace ga002= . if mi(ga002)
replace ga002_min= . if mi(ga002_min)
replace ga002_max= . if mi(ga002_max)
forvalues i = 1(1)2 {
	replace ga002_w2_`i'= . if mi(ga002_w2_`i')
}
replace ga002_w2_2a= . if mi(ga002_w2_2a)
replace ga002_w2_2b= . if mi(ga002_w2_2b)
replace ga002_w2_2c= . if mi(ga002_w2_2c)
replace ga002_w2_2_min= . if mi(ga002_w2_2_min)
replace ga002_w2_2_max= . if mi(ga002_w2_2_max)
//ga003 Pension Amount
forvalues i = 1(1)9 {
	replace ga003_w4_s`i'= . if mi(ga003_w4_s`i')
	replace ga003_w4_`i'= . if mi(ga003_w4_`i')
}
replace ga003_w4_s10= . if mi(ga003_w4_s10)
//ga004 Buying resourses 
forvalues i = 1(1)8 {
	replace ga004_w4_3_1_s`i'= . if mi(ga004_w4_3_1_s`i')
}
replace ga004_w4_1_min= . if mi(ga004_w4_1_max)
replace ga004_w4_1_max= . if mi(ga004_w4_1_max)

// ga005 Wage and Bonus Income 
forvalues i = 1(1)12 {
	replace ga005_`i'_= . if mi(ga005_`i'_)
	replace ga005_`i'_= . if ga005_`i'_==997 | ga005_`i'_==999
}

//ga006 Amount HHMemberName
forvalues j = 1(1)8 {
	replace ga006_w4_`j'_ = . if mi(ga006_w4_`j'_ )
	replace ga006_w4_`j'__max= . if mi(ga006_w4_`j'__max)
	replace ga006_w4_`j'__min= . if mi(ga006_w4_`j'__min)
	replace ga006_w4_2_`j'__max= . if mi(ga006_w4_2_`j'__max)
	replace ga006_w4_2_`j'__min= . if mi(ga006_w4_2_`j'__min)
	forvalues k = 1(1)2{
		replace ga006_w4_`k'_`j'_= . if mi(ga006_w4_1_`j'_)
		replace ga006_w4_`k'_`j'_= . if ga006_w4_`k'_`j'_==997 |ga006_w4_`k'_`j'_== 999
	}
}
forvalues x = 1(1)5 {
	replace ga006_w4_2a_`x'_= . if mi(ga006_w4_2a_`x'_)
}
foreach z in 1 2 3 4 5 6 8{
	replace ga006_w4_2b_`z'_= . if mi(ga006_w4_2b_`z'_)
}
forvalues y = 1(1)3 {
	replace ga006_w4_2c_`y'_= . if mi(ga006_w4_2c_`y'_)
}

//ga007 Subsidy
forvalues i = 1(1)12 {
	forvalues j = 1(1)10 {
		replace ga007_w4_`i'__s`j'= . if mi(ga007_w4_`i'__s`j')
	}

}
foreach j in 4 5 {
	forvalues z = 1(1)4 {
		replace ga007_w4_`j'_`z'_= . if mi(ga007_w4_`j'_`z'_)
	} 
}
forvalues i = 1(1)7 {
	replace ga007_w4_1_`i'_= . if mi(ga007_w4_1_`i'_)
}
forvalues i = 1(1)3 {
	foreach j in 2 6 {
		replace ga007_w4_`j'_`i'_= . if mi(ga007_w4_`j'_`i'_)
	}
}
forvalues i = 1(1)2 {
	replace ga007_w4_3_`i'_= . if mi(ga007_w4_3_`i'_)
}
forvalues i = 1(1)5 {
	foreach j in 7 9 {
	replace ga007_w4_`j'_`i'_= . if mi(ga007_w4_`j'_`i'_)
	}
}
forvalues i = 1(1)6 {
	replace ga007_w4_8_`i'_= . if mi(ga007_w4_8_`i'_)
}

//ga012
forvalues i = 1(1)12{
	replace ga012_w4_1_`i'_= . if mi(ga012_w4_1_`i'_)
	replace ga012_w4_1_`i'_= . if ga012_w4_1_`i'_==997 |ga012_w4_1_`i'_== 999
}
forvalues i = 1(1)3{
	replace ga012_w4_1_1_`i'_= . if mi(ga012_w4_1_1_`i'_)
	replace ga012_w4_2_1_`i'_= . if mi(ga012_w4_2_1_`i'_)
	replace ga012_w4_2_2_`i'_= . if mi(ga012_w4_2_2_`i'_)
}

//gb001
replace gb001_w4= . if mi(gb001_w4)
//gb002
foreach i in 1 2 3 4 5 6 7 8 9 97 98{
	replace gb002_w4_s`i'= . if mi(gb002_w4_s`i')
}
//gb003
replace gb003= . if mi(gb003)
//gb004 Recent Harvest 
forvalues i = 1(1)2{
	replace gb004_`i'= . if mi(gb004_`i')
}
//gb005 Home Consumed 
forvalues i = 1(1)3{
	replace gb005_`i'= . if mi(gb005_`i')
}
replace gb005_min= . if mi(gb005_min)
replace gb005_max= . if mi(gb005_max)
replace gb005_w2_max= . if mi(gb005_w2_max)
replace gb005_w2_min= . if mi(gb005_w2_min)

//gb006 Total Cost of Producing Crops and Forestry
replace gb006= . if mi(gb006)
replace gb006_min= . if mi(gb006_min)
replace gb006_max= . if mi(gb006_max)

//gb007
replace gb007= . if mi(gb007)

//gb008
replace gb008= . if mi(gb008)
replace gb008_min= . if mi(gb008_min)
replace gb008_max= . if mi(gb008_max)

//gb009
replace gb009= . if mi(gb009)
replace gb009_min= . if mi(gb009_min)
replace gb009_max= . if mi(gb009_max)

//gb010
replace gb010= . if mi(gb010)

//gb011
forvalues i = 1(1)3{
	replace gb011_`i'= . if mi(gb011_`i')
}
replace gb011_min= . if mi(gb011_min)
replace gb011_max= . if mi(gb011_max)
replace gb011_w2_max= . if mi(gb011_w2_max)
replace gb011_w2_min= . if mi(gb011_w2_min)

//gb012 Self-Consumed 
forvalues i = 1(1)3{
	replace gb012_`i'= . if mi(gb012_`i')
}
replace gb012_min= . if mi(gb012_min)
replace gb012_max= . if mi(gb012_max)
replace gb012_w2_max= . if mi(gb012_w2_max)
replace gb012_w2_min= . if mi(gb012_w2_min)

//gb013
replace gb013= . if mi(gb013)

//gc001
replace gc001= . if mi(gc001)
//gc002
replace gc002= . if mi(gc002)

//gc003 HHMemberName Engage in Self-employed Activity
foreach i in 1 2 3 4 5 6 7 8 9 97 98{
	forvalues j = 1(1)4{
		replace gc003_`j'__s`i'= . if mi(gc003_`j'__s`i')
	}
}

//gc004 Activity is Which Type
forvalues i = 1(1)4 {
	replace gc004_`i'_= . if mi(gc004_`i'_)
}
//gc005 Net Income from Activity
forvalues i = 1(1)4 {
	replace gc005_`i'_= . if mi(gc005_`i'_)
	replace gc005_`i'__min= . if mi(gc005_`i'__min)
	replace gc005_`i'__max= . if mi(gc005_`i'__max)
}

//gd001
forvalues i = 1(1)3 {
	replace gd001_w4_`i'= . if mi(gd001_w4_`i')
}

//gd002  Social Subsidies
forvalues i = 1(1)10 {
	replace gd002_w4_s`i'= . if mi(gd002_w4_s`i')
	replace gd002_w4_`i'= . if mi(gd002_w4_`i')
}
replace gd002_w4_s11= . if mi(gd002_w4_s11)

//gd003
forvalues i = 1(1)2 {
	replace gd003_w4_`i'= . if mi(gd003_w4_`i')
}

//gd004
replace gd004_w4= . if mi(gd004_w4)

//ge000
replace ge000_w4= . if mi(ge000_w4)
//ge001
replace ge001= . if mi(ge001)
//ge002
replace ge002= . if mi(ge002)
//ge004
replace ge004= . if mi(ge004)
//ge005
replace ge005= . if mi(ge005)
//ge006
replace ge006_w4= . if mi(ge006_w4)
replace ge006_w2= . if mi(ge006_w2)
replace ge006_w2_1= . if mi(ge006_w2_1)
//ge007
replace ge007_w4= . if mi(ge007_w4)
//ge008
replace ge008= . if mi(ge008)
//ge009 Fees
forvalues i = 1(1)7{
	replace ge009_`i'= . if mi(ge009_`i')
}
forvalues i = 1(1)3{
	replace ge009_w4_4_s`i'= . if mi(ge009_w4_4_s`i')
}
//ge010 Fitness Expenditures / Taxes and Fees
forvalues i = 1(1)15{
	replace ge010_`i'= . if mi(ge010_`i')
}
//ge011
replace ge011= . if mi(ge011)

save $working_data/2018_Income_combine.dta, replace



/*********** 2018-health-clean ***********/

use $temp_data/2018_Health_combine.dta, replace
drop da008*


//ea001
forvalues i = 1(1)12 {
		replace ea001_w4_s`i'= . if mi(ea001_w4_s`i')
}
//ea002
replace ea002= . if mi(ea002)

//ea003
forvalues i = 1(1)11{
	replace ea003_w4_`i'_= . if mi(ea003_w4_`i'_)
}

//ea008
forvalues i = 1(1)11{
	forvalues j = 1(1)2{
		replace ea008_`j'_`i'_=. if mi(ea008_`j'_`i'_)
	}
}
//ea009 
forvalues i = 1(1)7{
	replace ea009_s`i'=. if mi(ea009_s`i')
}
//eb001 Some Insurance 
forvalues i = 1(1)12{
	replace eb001_w4_s`i'= . if mi(eb001_w4_s`i') 
}
//eb003 eb004
foreach i in 1 2 3 4 7 8 11 {
	replace eb003_1_`i'_= . if mi(eb003_1_`i'_)
	replace eb003_2_`i'_= . if mi(eb003_2_`i'_)
	replace eb004_w4_`i'_= . if mi(eb004_w4_`i'_)
}

//ec001
replace ec001= . if mi(ec001)
replace ec001_w4= . if mi(ec001_w4)
forvalues i = 1(1)2{
	replace ec001_`i'= . if mi(ec001_`i')
	replace ec001_w4_`i'= . if mi(ec001_w4_`i')
}
forvalues i = 1(1)15 {
	replace ec001_w3_1_s`i'= . if mi(ec001_w3_1_s`i')
}
//ed001
replace ed001= . if mi(ed001)
//ed004
forvalues i = 1(1)9{
	replace ed004_w4_s`i'= . if mi(ed004_w4_s`i')
}
//ed005
forvalues i = 1(1)8{
	replace ed005_`i'_= . if mi(ed005_`i'_)
	replace ed005_w4_`i'= . if mi(ed005_w4_`i')
}
//ed006
replace ed006_w4= . if mi(ed006_w4)
replace ed006_w4_1= . if mi(ed006_w4_1)
replace ed006_w4_max= . if mi(ed006_w4_max)
replace ed006_w4_min= . if mi(ed006_w4_min)
//ed007
replace ed007= . if mi(ed007)
replace ed007_1= . if mi(ed007_1)
replace ed007_max= . if mi(ed007_max)
replace ed007_min= . if mi(ed007_min)
//ed008
replace ed008_w4= . if mi(ed008_w4)
//ed009
replace ed009= . if mi(ed009)
//ed010
replace ed010= . if mi(ed010)
//ed012
replace ed012= . if mi(ed012)
//ed013
replace ed013= . if mi(ed013)
//ed017
forvalues i = 1(1)5{
	replace ed017_s`i'= . if mi(ed017_s`i')
}
//ed019
replace ed019= . if mi(ed019)
//ed020
replace ed019= . if mi(ed019)
//ed023
replace ed023_w4= . if mi(ed023_w4)
replace ed023_w4_1= . if mi(ed023_w4_1)
replace ed023_w4_max= . if mi(ed023_w4_max)
replace ed023_w4_min= . if mi(ed023_w4_min)
//ed024
replace ed024= . if mi(ed024)
replace ed024_1= . if mi(ed024_1)
replace ed024_max= . if mi(ed024_max)
replace ed024_min= . if mi(ed024_min)
//ed028 
forvalues i = 1(1)14{
	replace ed028_w4_s`i'= . if mi(ed028_w4_s`i')
}
//ed029
replace ed029= . if mi(ed029)
//ed030
replace ed030_w4= . if mi(ed030_w4)
//ee003
replace ee003= . if mi(ee003)
//ee004
replace ee004= . if mi(ee004)
replace ee004_w4= . if mi(ee004)
//ee005
replace ee005_w4= . if mi(ee005_w4)
replace ee005_w4_1= . if mi(ee005_w4_1)
replace ee005_w4_max= . if mi(ee005_w4_max)
replace ee005_w4_min= . if mi(ee005_w4_min)
//ee006
replace ee006= . if mi(ee006)
replace ee006_1= . if mi(ee006_1)
replace ed007_max= . if mi(ed007_max)
replace ed007_min= . if mi(ed007_min)
//ee007
replace ee007= . if mi(ee007)
//ee008
replace ee008_w4= . if mi(ee008_w4)
//ee009
replace ee009= . if mi(ee009)
//ee010
replace ee010= . if mi(ee010)
//ee012
replace ee012_w4= . if mi(ee012_w4)
//ee013
replace ee013= . if mi(ee013)
//ee016
replace ee016= . if mi(ee016)
//ee017
forvalues i = 1(1)3{
	replace ee017_`i'= . if mi(ee017_`i')
}

//ee018
replace ee018= . if mi(ee018)
forvalues i = 1(1)3{
	replace ee018_`i'= . if mi(ee018_`i')
}
//ee019
replace ee019= . if mi(ee019)
//ee024
replace ee024_w4= . if mi(ee024_w4)
replace ee024_w4_1= . if mi(ee024_w4_1)
replace ee024_w4_max= . if mi(ee024_w4_max)
replace ee024_w4_min= . if mi(ee024_w4_min)
//ee027
replace ee027= . if mi(ee027)
replace ee027_1= . if mi(ee027_1)
replace ee027_max= . if mi(ee027_max)
replace ee027_min= . if mi(ee027_min)
//ee031
forvalues i = 1(1)14{
	replace ee031_w4_s`i'= . if mi(ee031_w4_s`i')
}
//ee032
replace ee032= . if mi(ee032)
//ee003
replace ee033_w4= . if mi(ee033_w4)
//ef001
replace ef001_w4= . if mi(ef001_w4)
//ef002 
replace ef002_w4= . if mi(ef002_w4)
replace ef002_w4_1= . if mi(ef002_w4_1)
replace ef002_w4_max= . if mi(ef002_w4_max)
replace ef002_w4_min= . if mi(ef002_w4_min)
//ef003
replace ef003= . if mi(ef003)
replace ef003_1= . if mi(ef003_1)
replace ef003_max= . if mi(ef003_max)
replace ef003_min= . if mi(ef003_min)
//ef005 
forvalues i = 1(1)14{
	replace ef005_w4_s`i'= . if mi(ef005_w4_s`i')
}
//eh001
replace eh001_w4= . if mi(eh001_w4)
//eh002
forvalues i = 1(1)5 {
	replace eh002_w4_s`i'= . if mi(eh002_w4_s`i')
}
//eh003 
forvalues i = 1(1)2{
	replace eh003_w4_`i'= . if mi(eh003_w4_`i')
}
//eh004
replace eh004_w4= . if mi(eh004_w4)
//eh005
forvalues i = 1(1)9 {
	replace eh005_w4_s`i'= . if mi(eh005_w4_s`i')
}
//eh007
replace eh007_w3= . if mi(eh007_w3)
//eh008
replace eh008_w4= . if mi(eh008_w4)
//ef006
replace ef006= . if mi(ef006)
//ef007
replace ef007= . if mi(ef007)
//ef008 
replace ef008=. if mi(ef008)


save $working_data/2018_Health_Care_clean.dta, replace

/*********** 2018-background-clean ***********/

use $temp_data/2018_Background_combine.dta, clear 
drop ba001 xrtype xrgender zfrgender zfrzodiac zfrbirth ziwtime ///
	zbc004 zfredu 

//ba000
replace ba000_w2_3= . if mi(ba000_w2_3)
//ba004
replace ba004_w3= . if mi(ba004_w3)
forvalues i = 1(1)3 {
	replace ba004_w3_`i'= . if mi(ba004_w3_`i')
}
//ba005
replace ba005_w4= . if mi(ba005_w4)
//ba002
forvalues i = 1(1)3{
	replace ba002_`i'= . if mi(ba002_`i')
}
//ba003
replace ba003= . if mi(ba003)
//bb000
replace bb000_w3= . if mi(bb000_w3) 
forvalues i = 1(1)2{
	replace bb000_w3_`i'= . if mi(bb000_w3_`i')
}
//bb001
replace bb001_w3= . if mi(bb001_w3) 
forvalues i = 1(1)2{
	replace bb001_w3_`i'= . if mi(bb001_w3_`i')
}
replace bb001= . if mi(bb001)
//bb003
replace bb003= . if mi(bb003)
//bb004 
replace bb004= . if mi(bb004)
//bb005 
replace bb005= . if mi(bb005)
forvalues i = 1(1)2{
	replace bb005_w3_`i'= . if mi(bb005_w3_`i')
}
//bc001
forvalues i = 1(1)3{
	replace bc001_w3_`i'= . if mi(bc001_w3_`i')
}
//bc002
replace bc002_w3= . if mi(bc002_w3)
foreach i in 1 2 4 5 {
	replace bc002_w3_`i'= . if mi(bc002_w3_`i')
} 
foreach i in 3 6{
	replace bc002_w3_`i'_1= . if mi(bc002_w3_`i'_1)
	replace bc002_w3_`i'_2= . if mi(bc002_w3_`i'_2)
}
//bd001 
replace bd001_w2_4= . if mi(bd001_w2_4)
replace bd001_w3_1= . if mi(bd001_w3_1)
//bd002
replace bd002_w3= . if mi(bd002_w3)
//bd006
replace bd006= . if mi(bd006)
//bd007
forvalues i = 1(1)8 {
	replace bd007_w4_1_s`i'= . if mi(bd007_w4_1_s`i')
}
//bd008
replace bd008_w4_1 = . if mi(bd008_w4_1)
//bd009
replace bd009_w4_1 = . if mi(bd009_w4_1)
//bd011
replace bd011_w4= . if mi(bd011_w4)
//bd010
replace bd010_w4= . if mi(bd010_w4)
//bd007
forvalues i = 1(1)8{
	replace bd007_w2_1_s`i'= . if mi(bd007_w2_1_s`i')
}
//bd008 
replace bd008_w2_1= . if mi(bd008_w2_1)
//bd009
replace bd009_w2_1= . if mi(bd009_w2_1)
//bd011
replace bd011= . if mi(bd011)
//bd010
replace bd010= . if mi(bd010)
//bd012
replace bd012= . if mi(bd012)
replace bd012_w4= . if mi(bd012_w4)
//bd013
replace bd013= . if mi(bd013)
replace bd013_w4= . if mi(bd013_w4)
//bd014
replace bd014= . if mi(bd014)
replace bd014_w4= . if mi(bd014_w4)
//bd015
replace bd015_w4= . if mi(bd015_w4)
//bd017
replace bd017_w4= . if mi(bd017_w4)
//be001
replace be001= . if mi(be001)
//be002
replace be002= . if mi(be002)
//be003
replace be003_w4= . if mi(be003_w4)
//bf005
forvalues i = 1(1)3{
	replace bf005_w4_`i'= . if mi(bf005_w4_`i')
}
//bf006
foreach i in 1 2 3 5 7 8{
	replace bf006_w4_`i'= . if mi(bf006_w4_`i')
}
forvalues i = 1(1)2{
	replace bf006_w4_4_`i'= . if mi(bf006_w4_4_`i')
	replace bf006_w4_6_`i'= . if mi(bf006_w4_6_`i')
} 
//bg001
replace bg001_w4= . if mi(bg001_w4)
//bg002
replace bg002_w4= . if mi(bg002_w4)
//bg003
replace bg003_w4= . if mi(bg003_w4)
//bg004
replace bg004_w4= . if mi(bg004_w4)
replace bg004_w4_1= . if mi(bg004_w4_1)
//bg005
replace bg005_w4= . if mi(bg005_w4)
replace bg005_w4_1= . if mi(bg005_w4_1)
//bg006
replace bg006_w4= . if mi(bg006_w4)
replace bg006_w4_1= . if mi(bg006_w4_1)
//bf008
replace bf008= . if mi(bf008)

save $working_data/2018_Background_clean.dta, replace

log close


/*********** Combine Background and Helath ***********/
log using $logfiles/2018-Data_Combination.log, replace

use $working_data/2018_Background_clean.dta, clear
merge 1:1 ID using $working_data/2018_Health_Care_clean.dta
tab _merge
drop if _merge!=3
drop _merge
save $working_data/2018_Background_Health.dta, replace


/*********** Combine Background Helath and Income ***********/

use $working_data/2018_Background_Health.dta, clear 
merge m:1 ID using $working_data/2018_Income_combine.dta
tab _merge
drop if _merge!=3
drop _merge
save $working_data/2018_Background_Health_Income_Clean.dta, replace

log close 





















// 之前2018正式dofile 里的原内容


/*********** 2018 - Income ***********/

/* Combine data*/
use $raw_data/Individual_Income.dta, clear
merge m:1 householdID using $raw_data/Household_Income.dta
tab _merge
drop if _merge!=3
drop _merge
drop ha*
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

// ga001 Receive Wage and Bonus Income
replace ga001= . if mi(ga001)
//ga002 How Much Receive
replace ga002= 0 if mi(ga002) | ga002==. 
replace ga002_min= . if mi(ga002_min)
replace ga002_max= 0 if mi(ga002_max) | ga002_max==.
forvalues i = 1(1)2 {
	replace ga002_w2_`i'= . if mi(ga002_w2_`i')
}
replace ga002_w2_2a= . if mi(ga002_w2_2a)
replace ga002_w2_2b= . if mi(ga002_w2_2b)
replace ga002_w2_2c= . if mi(ga002_w2_2c)
replace ga002_w2_2_min= . if mi(ga002_w2_2_min)
replace ga002_w2_2_max= . if mi(ga002_w2_2_max)
//ga003 Pension Amount
forvalues i = 1(1)9 {
	replace ga003_w4_s`i'= . if mi(ga003_w4_s`i')
	replace ga003_w4_`i'= 0 if mi(ga003_w4_`i') | ga003_w4_`i'==.
}
replace ga003_w4_s10= . if mi(ga003_w4_s10)
//ga004 Buying resourses 
forvalues i = 1(1)8 {
	replace ga004_w4_3_1_s`i'= . if mi(ga004_w4_3_1_s`i')
}
replace ga004_w4_1_min= . if mi(ga004_w4_1_max)
replace ga004_w4_1_max= 0 if mi(ga004_w4_1_max) | ga004_w4_1_max==.

// ga005 Wage and Bonus Income 
forvalues i = 1(1)12 {
	replace ga005_`i'_= . if mi(ga005_`i'_)
	replace ga005_`i'_= . if ga005_`i'_==997 | ga005_`i'_==999
}

//ga006 Amount HHMemberName
forvalues j = 1(1)8 {
	replace ga006_w4_`j'_ = 0 if mi(ga006_w4_`j'_ ) | ga006_w4_`j'_==. 
	replace ga006_w4_`j'__max= 0 if mi(ga006_w4_`j'__max) | ga006_w4_`j'__max==.
	replace ga006_w4_`j'__min= . if mi(ga006_w4_`j'__min)
	replace ga006_w4_2_`j'__max= . if mi(ga006_w4_2_`j'__max)
	replace ga006_w4_2_`j'__min= . if mi(ga006_w4_2_`j'__min)
	forvalues k = 1(1)2{
		replace ga006_w4_`k'_`j'_= . if mi(ga006_w4_1_`j'_)
		replace ga006_w4_`k'_`j'_= . if ga006_w4_`k'_`j'_==997 |ga006_w4_`k'_`j'_== 999
	}
}
forvalues x = 1(1)5 {
	replace ga006_w4_2a_`x'_= . if mi(ga006_w4_2a_`x'_)
}
foreach z in 1 2 3 4 5 6 8{
	replace ga006_w4_2b_`z'_= . if mi(ga006_w4_2b_`z'_)
}
forvalues y = 1(1)3 {
	replace ga006_w4_2c_`y'_= . if mi(ga006_w4_2c_`y'_)
}

//ga007 Subsidy
forvalues i = 1(1)12 {
	forvalues j = 1(1)10 {
		replace ga007_w4_`i'__s`j'= . if mi(ga007_w4_`i'__s`j')
	}

}
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


//ga012
forvalues i = 1(1)12{
	replace ga012_w4_1_`i'_= . if mi(ga012_w4_1_`i'_)
	replace ga012_w4_1_`i'_= . if ga012_w4_1_`i'_==997 |ga012_w4_1_`i'_== 999
}
forvalues i = 1(1)3{
	replace ga012_w4_1_1_`i'_= . if mi(ga012_w4_1_1_`i'_)
	replace ga012_w4_2_1_`i'_= . if mi(ga012_w4_2_1_`i'_)
	replace ga012_w4_2_2_`i'_= . if mi(ga012_w4_2_2_`i'_)
}


// gb* Household  Agricultural  Income  and  Expenditure

//gb001
replace gb001_w4= . if mi(gb001_w4)
//gb002
foreach i in 1 2 3 4 5 6 7 8 9 97 98{
	replace gb002_w4_s`i'= . if mi(gb002_w4_s`i')
}
//gb003
replace gb003= . if mi(gb003)
//gb004 Recent Harvest 
forvalues i = 1(1)2{
	replace gb004_`i'= . if mi(gb004_`i')
}
//gb005 Home Consumed 
forvalues i = 1(1)3{
	replace gb005_`i'= 0 if mi(gb005_`i') | gb005_`i'==.
}
replace gb005_min= . if mi(gb005_min)
replace gb005_max= 0 if mi(gb005_max) | gb005_max==. 
replace gb005_w2_max= . if mi(gb005_w2_max)
replace gb005_w2_min= . if mi(gb005_w2_min)

//gb006 Total Cost of Producing Crops and Forestry
replace gb006= . if mi(gb006)
replace gb006_min= . if mi(gb006_min)
replace gb006_max= . if mi(gb006_max)

//gb007
replace gb007= . if mi(gb007)

//gb008
replace gb008= 0 if mi(gb008) | gb008==. 
replace gb008_min= 0 if mi(gb008_min) | gb008_min==.
replace gb008_max= 0 if mi(gb008_max) | gb008_max==.

//gb009
replace gb009= . if mi(gb009)
replace gb009_min= . if mi(gb009_min)
replace gb009_max= . if mi(gb009_max)

//gb010
replace gb010= . if mi(gb010)

//gb011
forvalues i = 1(1)3{
	replace gb011_`i'= . if mi(gb011_`i')
}
replace gb011_min= . if mi(gb011_min)
replace gb011_max= . if mi(gb011_max)
replace gb011_w2_max= . if mi(gb011_w2_max)
replace gb011_w2_min= . if mi(gb011_w2_min)

//gb012 Self-Consumed 
forvalues i = 1(1)3{
	replace gb012_`i'= . if mi(gb012_`i')
}
replace gb012_min= . if mi(gb012_min)
replace gb012_max= . if mi(gb012_max)
replace gb012_w2_max= . if mi(gb012_w2_max)
replace gb012_w2_min= . if mi(gb012_w2_min)

//gb013
replace gb013= . if mi(gb013)


// gc* Self-Employed  Activities  

//gc001
replace gc001= . if mi(gc001)
//gc002
replace gc002= . if mi(gc002)

//gc003 HHMemberName Engage in Self-employed Activity
foreach i in 1 2 3 4 5 6 7 8 9 97 98{
	forvalues j = 1(1)4{
		replace gc003_`j'__s`i'= . if mi(gc003_`j'__s`i')
	}
}

//gc004 Activity is Which Type
forvalues i = 1(1)4 {
	replace gc004_`i'_= . if mi(gc004_`i'_)
}
//gc005 Net Income from Activity
forvalues i = 1(1)4 {
	replace gc005_`i'_= 0 if mi(gc005_`i'_) | gc005_`i'_<0
	replace gc005_`i'__min= 0 if mi(gc005_`i'__min) | gc005_`i'__min <0
	replace gc005_`i'__max= 0 if mi(gc005_`i'__max) | gc005_`i'__max< 0
}

// gd* Household  Public  Transfer  Income
//gd001
forvalues i = 1(1)3 {
	replace gd001_w4_`i'= . if mi(gd001_w4_`i')
}
replace gd001_w4_3 = 0 if gd001_w4_3==.
//gd002  Social Subsidies
forvalues i = 1(1)10 {
	replace gd002_w4_s`i'= . if mi(gd002_w4_s`i')
	replace gd002_w4_`i'= 0 if mi(gd002_w4_`i') | gd002_w4_`i'==.
}
replace gd002_w4_s11= . if mi(gd002_w4_s11)

//gd003
forvalues i = 1(1)2 {
	replace gd003_w4_`i'= . if mi(gd003_w4_`i')
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

save $working_data/2018_Money_combine_clean.dta, replace

