PROCEDURE $ny_basis_aar2
--Denne prosedyren omregner alle indekser til 2015=100
--Oppdaterer detoms.db med de nye tallene

close all

open <acc overwrite> detoms_ny as detoms_ny
open<acc r> bak1_detoms as bak1_detoms

ITEM TYPE OFF, NUMERIC ON, PRECISION ON

loop for lcv in wildlist(bak1_detoms, "?")
	new detoms_ny'lcv = $base_year_calculation(bak1_detoms'lcv, 2015)
	description(detoms_ny'lcv) = string(description(bak1_detoms'lcv))
end loop

copy bak1_detoms'BUILD.DESC to detoms_ny
copy bak1_detoms'BUILD.DESC_EN to detoms_ny
copy bak1_detoms'BUILD.DOC to detoms_ny
copy bak1_detoms'BUILD.KEY to detoms_ny
copy !bak1_detoms'STRING_ATTRIBUTE_NAMES to detoms_ny

close all

END PROCEDURE

function $base_year_calculation
argument local series input_series
--argument series input_series
argument scalar input_year

local new <frequency annual; date makedate(annual,input_year,1)> year_ave = average(input_series)fu

return <date *> input_series/year_ave*100

end function
