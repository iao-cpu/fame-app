function $base_year_calculation
argument local series input_series
argument scalar input_year
convert auto off

local new <frequency annual; date makedate(annual,input_year,1)> year_ave = average(input_series)

return <date *> input_series/year_ave*100

end function
