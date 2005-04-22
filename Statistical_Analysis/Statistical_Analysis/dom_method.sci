tic();

// Executing the Header File

exec('Header.sci');

// Loading the hystorical series

Series = read(File_name, -1,1);

// Calculating the periodicity of the analysis

Analysis_periodicity = ceil(Num_points_forecast/Main_periodicity)*Main_periodicity;

// Verifying that there are enough samples for the analysis

Starting_index= length(Series) - ((Num_periods_analysis+1)*Analysis_periodicity+Num_points_forecast)+1;

if  Starting_index <= 0 then
	printf("\n Not enough data for the desired analysis. \n Use a lower number of points for forecast or a lower number of analysis'' periods\n\n");
	Execution_time=toc();
else

	// Performing a test of the prevision method

	for period= 1: Num_periods_analysis + 1,
		for index= 1: Analysis_periodicity,
			X1(index,period)=Series(Starting_index+index-1+Analysis_periodicity*(period-1));
		,end;
	,end;

	X=X1(:,1:Num_periods_analysis);
	y=X1(:,Num_periods_analysis+1);

	b=inv(X'*X)*X'*y; // Vector of the Num_periods_analysis coefficients

	X2=X1(:,2:Num_periods_analysis+1);
	y_tmp = X2*b;
	y_verification=y_tmp(1:Num_points_forecast);

	subplot(211);
	plot2d(1:Num_points_forecast,[Series(length(Series)-Num_points_forecast+1:1:length(Series)), y_verification],[2, 5]);

	// Performing the prevision

	Starting_index=Starting_index+Num_points_forecast;

	for period= 1: Num_periods_analysis + 1,
		for index= 1: Analysis_periodicity,
			X1(index,period)=Series(Starting_index+index-1+Analysis_periodicity*(period-1));
		,end;
	,end;

	X=X1(:,1:Num_periods_analysis);
	y=X1(:,Num_periods_analysis+1);

	b=inv(X'*X)*X'*y; // Vector of the Num_periods_analysis coefficients

	X2=X1(:,2:Num_periods_analysis+1);
	y_tmp = X2*b;
	y_forecast=y_tmp(1:Num_points_forecast);

	subplot(212);
	plot2d(1:Num_points_forecast,[y_forecast],[5]);

	stacksize(10000000);

	Execution_time=toc();
end

Execution_time