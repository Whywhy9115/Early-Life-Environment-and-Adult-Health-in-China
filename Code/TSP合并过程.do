// Add value process part of TSP data

use $working_data/TSP_100.dta ,clear 




use $raw_data/2013/PSU.dta ,clear
keep communityID province city urban_nbs
replace city="哈尔滨市" if  city=="哈尔滨" 
merge m:1 city using $working_data/TSP_100.dta 
drop _merge 
drop if communityID==""
save $working_data/PSU_TSP.dta, replace 
keep communityID province city
save $working_data/province_city.dta, replace 


/*
use $working_data/PSU_TSP.dta, clear 
drop y_*
merge 1:m communityID using $working_data/2018_original_enlarge_construction.dta
drop _merge
gen K = city+communityID+year
save $working_data/2018_all.dta, replace 
*/

use $working_data/PSU_TSP.dta, clear 
reshape long y_@ /*
*/ , i(communityID) j(m)
label var m "year order from 1981 to 1995"
tostring m,replace
gen K = city+communityID+m 
keep communityID K y_ 
//duplicates drop M, force
save $working_data/city_TSP.dta, replace 








/*
use $working_data/2018_all.dta, clear
//keep communityID y_ M K
merge m:1 K using $working_data/city_TSP.dta 
gen TSP = y_
drop _merge
save $working_data/2018_all_TSP.dta, replace
*/



// all province
drop if province=="山西省"
drop if province=="江西省"
drop if province=="广东省"
drop if province=="河北省"
drop if province=="河南省"
drop if province=="山东省"
drop if province=="江苏省"
drop if province=="安徽省"
drop if province=="浙江省"
drop if province=="湖北省"
drop if province=="湖南省"
drop if province=="福建省"
drop if province=="贵州省"
drop if province=="四川省"
drop if province=="甘肃省"
drop if province=="云南省"
drop if province=="内蒙古自治区"
drop if province=="黑龙江省"
drop if province=="吉林省"
drop if province=="辽宁省"
drop if province=="青海省"
drop if province=="上海市"
drop if province=="北京"
drop if province=="天津"
drop if province=="广西省"
drop if province=="新疆维吾尔自治区"
drop if province=="重庆市"
drop if province=="陕西省"
