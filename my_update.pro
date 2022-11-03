PROCEDURE $myupdate
open <access overwrite> destination
open <access read> source

loop for lcv in wildlist(source,"?")
  new dest'lcv = $base_year_calculation(source'lcv, 2005)
end loop

END