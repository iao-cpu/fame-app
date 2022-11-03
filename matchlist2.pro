FUNCTION $matchlist2
argument %mydb, %match

-/ ser1 = SL(wildlist(id(%mydb),%match))
local series ser_str:string by case
loop for i = firstvalue(ser1) to lastvalue(ser1)
 -- Object name 
 set ser_str[i] = ser1[i]
end loop
return ser_str
END 
