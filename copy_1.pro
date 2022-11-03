PROCEDURE $COPY_1

BLOCK 
	over on
	close all
	Glue "."
	date 2009 to 2011
	Freq M
	
	try
		open<acc s>"c:\javafame\famedb\kpi_matvarer_analyse" as analyse
	otherwise
		type lasterror
		return
	end try
	
ITEM CLASS OFF, SERIES ON
scalar !tmp_lst_1:namelist = wildlist(analyse, "K?.IMP_NYDUMP_C.IPR")

new names = sl(!tmp_lst_1)
--disp names

series ser_str : string by case
series ser_str_1: string by case
local s_search = "."
scalar pos:numeric


LOOP FOR item = firstvalue(names) to lastvalue(names)

pos = location(names[item], s_search, 1)

set ser_str[item] = substring(names[item], 1, pos-1)

set ser_str_1[item] = ser_str[item]+"."+"PUBL.IPR"

--disp ser_str_1[item]


scalar s2: string  = ser_str_1

series id(s2) : numeric  by date 

set id(s2) = id(ser_str[item]+"."+"IMP_NYDUMP_C.IPR")

disp id(s2)


END LOOP

close all

END BLOCK

END PROCEDURE
	
	
