*version 10
set more off
capture log close
capture log using "$my_path\ReTrade\ReTrade2\Log\do-prep.log", replace

/* ReTrade Project (wave II)*/
/* Re-Trading, Price Discovery and Efficiency under Alternative Exchange Institutions */
/* Generates Global macros to be used in this project*/
/* by Diego Aycinena */
/* Created: 2017-05-23 */
/* Last modified: 2018-09-10 */
/* located in C:\...\Dropbox\Research\data\ReTrade\do */

*** Rutas archivos - File path for the current project
* Set main File Path [Establecer Rutas de archivos principales]
capture mkdir "$my_path\ReTrade\ReTrade2"
global path_main = "$my_path\ReTrade\ReTrade2"
	* $my_path is set up in the profile.do as the path with the folder where data is stored
	* $path_main is the main file path for the current project, where the main project folder is located

*global source_data = "$ServerData_path\ReTrade" 
	* "SourceData", where original data files are stored
	* $ServerData_path can be set up in the profile.do as the path with the folder where Server containing the data via FTPbox is stored

	
*Check if non standard packages are installed. If not, install
foreach package in estout fprank vioplot matchit freqindex  {
 		capture which `package'
 		if _rc==111 ssc install `package'
 	}
capture which ztree2stata
if _rc==111 {
	net from http://www.econ.hit-u.ac.jp/~kan/research/ztree2stata
	net install ztree2stata
	}

*		
	
* Set second-level file paths
		*** Insinde the main project folder (defined by path_main), there should be 4 additional folders: 

* "Data", where data files created by do-files will be stored
capture mkdir "$path_main\Data"
global path_data = "$path_main\Data" 

* "Do" where do files are stored:
capture mkdir "$path_main\Do"
global path_do = "$path_main\Do"

* "Log", where log files are stored:
capture mkdir "$path_main\Log"
global path_log = "$path_main\Log"

* "Graphs, where graphs are stored:
capture mkdir "$path_main\Graphs"
global path_graphs = "$path_main\Graphs"

* "Tables", where regression tables and tables of summary statistics are stored:
capture mkdir "$path_main\Tables"
global path_tables = "$path_main\Tables"

* In addition, this is a temporary file path -outside of dropbox- to perform different operations -if needed.
if c(username) == "diego" {  //personal computer
	global path_tempdata = "C:\data\temp"
}
else if c(username) == "diego.aycinena" { // Rosario user name
	global path_tempdata = "C:\data\temp"
}
else if c(username) == "aycinena" { // Chapman user name
	global path_tempdata = "C:\Users\aycinena\Documents\data\temp"
}
else {
capture mkdir "C:\data\temp"
capture global path_tempdata = "C:\data\temp"	
}

*List of paths and names for global files
global data_action = "$path_data\action.dta"		  /* Data from the Action_Data_date_time file  */
global data_parameters = "$path_data\parameters.dta"  /* Data from theParameters_Data_date_time file */
global data_replay = "$path_data\replay.dta"  /* Data from the Replay_Data_date_time file */
global data_summary= "$path_data\summary.dta"  /* Data from the Summary_Data_date_time file */



* Global List of Data files dates
global file_date_list  "5-8-2017_13_59_10 5-12-2017_10_59_33 5-15-2017_11_31_41 5-15-2017_13_30_21 5-17-2017_14_30_45 9-11-2017_14_28_52 9-11-2017_16_29_2 9-13-2017_9_58_43 9-13-2017_15_3_59 9-14-2017_14_31_58 9-14-2017_16_28_11 9-15-2017_10_28_34 9-15-2017_10_58_30 10-13-2017_11_29_34" //data files
global quest_file_list "s1_20170508_152057 s2_20170512_122305 s3_20170515_124730 s4_20170515_145203 s5_20170517_155822 s6_20170911_160324 s7_20170911_174958 s8_20170913_113208 s9_20170913_162922 s10_20170914_155323 s11_20170914_174646 s12_20170915_115101 s13_20170915_122846 s20_20171013_125522"  //ESI Psych survey results files

* List of simmulation files for Zero-Intelligence Agents (ZIA)
global zia_f_date_list "6-6-2017_15_31_1 6-6-2017_16_15_36 6-6-2017_17_19_9 6-6-2017_18_9_47 6-6-2017_19_27_23 6-6-2017_20_32_37 6-7-2017_8_20_9 6-7-2017_9_57_31 6-7-2017_10_47_33 6-7-2017_11_57_44 6-13-2017_15_29_27 6-13-2017_15_29_31 6-13-2017_16_2_28 6-13-2017_16_2_33 6-13-2017_17_4_50 6-13-2017_17_4_55 6-13-2017_17_59_26 6-13-2017_17_59_29 6-13-2017_19_10_6 6-13-2017_19_10_14 6-14-2017_8_34_36 6-14-2017_8_34_48 6-14-2017_10_16_6 6-14-2017_10_16_23 6-14-2017_11_15_57 6-14-2017_11_16_44 6-14-2017_12_21_18 6-14-2017_12_21_25 6-14-2017_13_33_21 6-14-2017_13_33_25 6-14-2017_14_43_52 6-14-2017_14_44_10 6-14-2017_15_37_56 6-14-2017_15_38_8 6-14-2017_17_22_15 6-14-2017_17_22_35 6-14-2017_19_28_44 6-14-2017_19_28_59 6-16-2017_20_38_39 6-16-2017_20_38_49 6-17-2017_0_36_30 6-17-2017_0_36_35 6-17-2017_13_28_18 6-17-2017_13_27_41"   

* List of simmulation files for minimal intelligence (non-Zero-Intelligence Agents, or nZIA) 
global nzia_f_date_list "6-9-2017_12_57_51 6-9-2017_13_1_18 6-9-2017_13_50_11 6-9-2017_13_52_21 6-9-2017_14_29_56 6-9-2017_14_31_4 6-9-2017_15_14_17 6-9-2017_15_14_29 6-9-2017_15_16_54 6-9-2017_15_21_20 6-9-2017_16_2_33 6-9-2017_16_2_45 6-9-2017_16_4_11 6-9-2017_16_4_14 6-9-2017_16_41_56 6-9-2017_16_41_59 6-9-2017_16_43_15 6-9-2017_16_43_18 6-9-2017_17_28_27 6-9-2017_17_28_32 6-9-2017_17_28_38 6-9-2017_17_28_42 6-9-2017_18_11_45 6-9-2017_18_11_51 6-9-2017_18_12_9 6-9-2017_18_12_31 6-9-2017_20_5_16 6-9-2017_20_5_29 6-9-2017_20_5_42 6-9-2017_20_5_54 6-9-2017_22_9_59 6-9-2017_22_10_7 6-9-2017_22_10_18 6-9-2017_22_10_22 6-10-2017_8_9_13 6-10-2017_8_9_17 6-10-2017_8_9_22 6-10-2017_8_9_26 6-10-2017_9_45_41 6-10-2017_9_45_48 6-10-2017_9_45_53 6-10-2017_9_45_57 6-10-2017_11_22_36 6-10-2017_11_22_39 6-10-2017_11_23_10 6-10-2017_11_23_14 6-10-2017_16_6_45 6-10-2017_16_7_17 6-10-2017_16_7_43 6-10-2017_16_8_3 6-10-2017_17_3_12 6-10-2017_17_3_18 6-11-2017_11_52_51 6-11-2017_11_52_58 6-11-2017_11_53_20 6-11-2017_11_53_52 6-11-2017_20_18_4 6-11-2017_20_18_44 6-11-2017_20_20_11 6-11-2017_20_20_39 6-12-2017_7_46_15 6-12-2017_7_46_20 6-12-2017_8_36_41 6-12-2017_15_8_29 6-12-2017_15_11_10 6-12-2017_16_1_24 6-12-2017_17_45_59 6-12-2017_17_46_8 6-12-2017_19_25_35 6-12-2017_19_25_39 6-13-2017_8_20_41 6-13-2017_8_21_3 6-13-2017_11_9_56 6-13-2017_11_10_17 6-17-2017_17_8_59 6-17-2017_17_8_45"

capture log close
