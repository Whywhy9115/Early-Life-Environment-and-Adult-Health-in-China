/* ========================================================================
 * Program: Lecture1.do
 * Data:	CHARLS 2011 National baseline
 * Aim:   	STATA 基础口令
 * Revised: 2022/02
 * ======================================================================= */

clear

set more off
capture log close

/* global命令: 可以省去每次都写长路径 */

global root= "/Users/jy/Desktop/未命名文件夹" 
global dofiles= "$root\Dofiles"
global logfiles= "$root\Logfiles"
global raw_data= "$root\Raw_data"
global working_data= "$root\Working_data"
global temp_data= "$root\Temp_data"
global tables= "$root\Tables"
global figures= "$root\Figures"

/* log命令: 记录所有运行过程 */

log using $logfiles\Lecture1.log, replace // 开始记录log文件

/* use命令: 读取数据 */

use $raw_data\demographic_background.dta, clear 

/* 浏览数据常用命令 */
describe
// edit
browse
order ba002_1 rgender
list in 1/5
list ba002_1 rgender in 1/5
sort ba002_1
list ba002_1 rgender in 1/5

/* 浏览变量 */
codebook rgender
describe rgender
sum
sum rgender
tab  ba001
tab ba001, m // 显示missing value，推荐使用

/* 给变量或者数值加或者改标签 */

/* 变量标签 */
tab rgender, m
label variable rgender "gender of respondant"

tab rgender, m

/* 数值标签 */
label define lrgender 1 "Male" 2 "Female"

/* 派数值标签给变量 */
label values rgender lrgender

tab rgender, m

/* 从数据库 drop 变量 */

drop bf*

keep bd*

/* 在数据库中保留变量 */

/* save命令: 储存数据 */
save $working_data\from_demographic_background.dta, replace 
log close   //保存log文件

/* help and search 命令 */
help des

