function $matchlist1
argument %dbname1, %match1

-/ ser1 = SL(SELECTNAMES(WILDLIST(ID(%dbname1),"?"), NOT MISSING(LOCATION(UPPER(DESCRIPTION(@NAME)),%match1))))
local series ser_str:string by case
IF NOT MISSING(FIRSTVALUE(ser1))
loop for i = firstvalue(ser1) to lastvalue(ser1)
-- Object name and description are seperated by a "|" below.
-- You can use a space or tab or any other character as per your requirement.
set ser_str[i] = ser1[i]+ "   " + "|" + "   " +description(id(ser1[i]))
end loop
END IF
return ser_str
end function
