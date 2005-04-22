// Header file for the periodic series statistical forecast
// The file is a Scilab script and it is used to define some variables
// needed in the execution of the analysis script.

// Resetting the environment
clear;


// Insert the value of the debug variable. If setted to true (%T)
// the script will prompt useful information

_DEBUG_ = %F ;
 
// Insert the number of the main periodicity
// The value of the main periodicity of the hystorical series can be found
// using the Autocorrelation Analysis available also in the R programming language

Main_periodicity = 672;

// Insert path and file name of the file containing the data

File_name = 'cons_real_3.m';

// Insert the number of periods to use to perform the analysis
// It would be desirable to use the number of periods given by the 
// Partial Autocorrelation function. (????)

Num_periods_analysis = 7;

// Insert the number of point to forecast.
// It would be better use a multiple of the main period

Num_points_forecast = 672;
