-- $build tar et område navn som argument og forventer at det finnes en
-- database fil med suffikset 01 som innholder serier. Fame level 1 standard.
-- eksempel :    $build "kpi01"    => opdatering av kpi01.db
-- $build genererer tre paralelle case serier: .key, .desc_no, desc_en, der
-- henholdsvis objektnavn, norsk og engelsk beskrivelse blir lagret.
-- Dersom databasen innholder aliaser eller globale aliaser vi også disse bli
-- lagt inn i den såkalte database dictionaryen.


procedure $build
argument db_arg 

block
glue dot
over on
confirm off


local series <store work> en_desc: string by case  
local series <store work> d_desc: string by case  
local series <store work> d_doc: string by case  

close all
try 
open <acces shared> db_arg AS cur_db 
otherwise
type "1. Cannot open "+db_arg 
type lasterror 
return 
end try

local scalar < over on> my_string_attribute_names:namelist ={desc_en}

store cur_db
over on
	
if (exists (string_attribute_names)) and (not missing(string_attribute_names))
set cur_db'string_attribute_names = unique(string_attribute_names + &&
my_string_attribute_names )
else 
cur_db'string_attribute_names = my_string_attribute_names 
end if

close cur_db

ITEM CLASS ON, SERIES ON, FORMULAS ON, GLFORMULA OFF, GLNAME OFF, SCALAR OFF
ITEM TYPE STRING OFF, NAMELIST OFF, DATE OFF, BOOLEAN OFF
ITEM TYPE PRECISION ON, NUMERIC ON 
ITEM ALIAS ON

case *

try
open <access shared> db_arg as cur_db
otherwise
type "3. Cannot open "+db_arg 
type"Database does not exist or you do not have update/shared access " 
return 
end try
store cur_db 
confirm off
local scalar pos :numeric = 0;

series build&key : string by case
series build&desc_en : string by case
series build&desc : string by case
series build&doc : string by case

LOOP FOR i in  wildlist(cur_db, "?") 
	set pos = pos + 1
	set build&key[pos] = name(i)

if desc_en(i) EQ ND
 attribute desc_en(i) = ""
end if
	set build&desc_en[pos] = UPPER(desc_en(i))
	--set build&desc_2[pos] = build&desc_en[pos]
	set build&desc[pos] = UPPER(desc(i))
	set build&doc[pos] = UPPER(doc(i))
END LOOP
CLOSE ALL
END BLOCK
END PROCEDURE

