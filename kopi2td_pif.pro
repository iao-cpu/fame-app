----------------------------------------------------------------------
-- kopi2td.pro  : prosedyre-pakke for overføring/kopiering av serier
--                fra en FAME-base til en annen
-- Merknad      : $open og $lukke skal kun benyttes i fbm overføring 
--                fra produksjonsbaser til TD.

----------------------------------------------------------------------

procedure $opne
-- Prosedyre som kopierer og åpner orginalbasen
argument utbase
  over on
  close all
  /utnavn = utbase
  local scalar rc:string

  type "Sjekker skrivetilgang til basen $REFERTID/data/"+utbase+".db..."
  /test1 = system("test -w $REFERTID/data/"+utbase+".db ; echo $?")   -- Filen er skrivbar.

  if substring(test1,1) eq "0" -- Skrivetilgang OK
    -- Gruppen til basen leses inn til /stgrp
    /tull = iniscan(system("ls -l $REFERTID/data/"+utbase+".db | awk '{print $4}'"))
    /stgrp = scan

    set rc = xsystem("rm -f $REFERTID/wk1/"+utbase+".odb; echo $?")
    set rc = xsystem("cp -f $REFERTID/data/"+utbase+".db $REFERTID/wk1/"+utbase+".odb; echo $?")
    set rc = xsystem("chgrp -f "+lower(stgrp)+" $REFERTID/wk1/"+utbase+".odb; echo $?")
    set rc = xsystem("chmod -f 660 $REFERTID/wk1/"+utbase+".odb; echo $?")
    execute "open "+QUOTE+"$REFERTID/wk1/"+utbase+".odb"+ QUOTE+" as UT"

    -- Legger inn egendefinert attributt desc_en for engelsk beskrivelse
    -- myfame/build.pc vil som attributt nr legge inn desc_2... 
    if not exists(!ut'string_attribute_names)
      scalar <store ut> !string_attribute_names:namelist = {desc_en}
    else if {extract(ut'string_attribute_names,1)} ne {desc_en}
      signal error:"string_attribute_names="+string(!ut'string_attribute_names)
    end if

    type utbase+" kopiert til $REFERTID/wk1/"+utbase+".odb og åpnet"
    search none -- UT-basen må ikke med i søkestien

  else if substring(test1,1) eq "1"   -- Alt er IKKE i orden.
    /test2 = system("test -f $REFERTID/data/"+utbase+".db; echo $?")
    if substring(test2,1) eq "0"
      signal error:"Basen "+utbase+".db eksisterer men er ikke skrivbar for deg."
    else
      signal error:"Basen "+utbase+" finnes ikke. Du kastes ut."
    end if  
  else  -- Feil-situasjon,skal aldri oppstå...
    signal error: test1 
  end if

  item alias off
  item class scalar off
  item type string off 
end procedure

function xsystem
-- Kalles av $lukke
argument kommando
local scalar rc:string
--  type "Kommando="+kommando
  set rc=system(kommando)
  if missing(rc) 
    signal error:"usjomusj" 
    return 0
  else if substring(rc,1,1) ne "0" 
     if systemerror eq ND
         signal error: kommando+" ga exit uten melding:"
      else
    signal error: kommando+" ga følgende exit-status:"  +rc+&&
         "og følgende meldinger til STDERR:"+systemerror
   end if
  end if
--  type "utf komm"
return rc
end function

procedure $lukke
-- Prosedyre som sikrer compress og back-up
-- og lukker basene
argument a_tiden
-/tiden=a_tiden
  close all
  local scalar rc:string

  type "Indekserer den oppdaterte basen (.odb) vha build..."
  execute "$build "+QUOTE + "$REFERTID/wk1/"+utnavn+".odb"+QUOTE


  set rc = xsystem("rm -f $REFERTID/wk1/"+utnavn+".db; echo $?")
  type "Komprimerer den oppdaterte basen (.odb -> .db)..."
  set rc = system("$FAME/compress -N 0,0 $REFERTID/wk1/"+utnavn+".odb $REFERTID/wk1/"+utnavn+".db; echo $?")
  if not missing(systemerror)
    signal error: rc
  end if
  set rc = xsystem("chgrp -f "+lower(stgrp)+" $REFERTID/wk1/"+utnavn+".db; echo $?")
  set rc = xsystem("chmod -f 660"+" $REFERTID/wk1/"+utnavn+".db; echo $?")
  set rc = xsystem("rm -f $REFERTID/wk1/"+utnavn+".odb; echo $?")
  --set rc = xsystem("cp $HOME/test_pif/wk1/"+utnavn+".db $HOME/timeiq/; echo $?")
end procedure

procedure $desc
-- Kopierer over seriebeskrivelser mm for serier, vanlig overføring
-- Kalles av: $kopi og $kopi_avrund
argument i
  desc(ut'i)=desc(i)                 -- norsk beskrivelse
  docu(ut'i)=docu(i)                 -- norsk fotnote-informasjon på serien
  attribute desc_en(ut'i)=desc_en(i) -- engelsk beskrivelse

  alias(ut'i)=alias(i)
end procedure

procedure $desc_2
-- Kopierer beskrivelse fra gml serie når serien konverteres
-- Kalles av: $kopi_avrund_convert
argument nyserie, gmlserie
  desc(nyserie)=desc(gmlserie)          -- norsk beskrivelse
  docu(nyserie)=docu(gmlserie)          -- norsk fotnote-informasjon på serien
  attribute desc_en(nyserie)=desc_en(gmlserie) -- engelsk beskrivelse

-- trenger bl.a. en test på alias-navnene...
--  alias(utserie)=crosslist(alias(nyserie),id(name(substr(@freq,1,1))))
end procedure


procedure $kopi
-- Styrer kopiering fra base IN til base UT
-- Hvis orginalserien er en formel blir den ekspandert
-- beskrivelser etc. kopiert
argument liste

type ""
type "$kopi: Eventuelle formler ekspanderes til serier med "+&&
     "følgende egenskaper:"
type "Observed= " + @observed
if @convert.automatic eq TRUE
  -- Kunne kanskje gitt en feilmelding i steden?
  type "Freq    = " + @freq
  type "Convert.technique= "+@convert.technique
end if
type "Overfører kun eksisterende data i tidsspennet " + @date

local scalar eksist:string

if firstdate ne NC and lastdate ne NC  
  loop for i in liste
    if exists(ut'i) 
      set eksist=""
    else
      set eksist="NY"
    end if
    type "Update "+eksist+" "+class(i)+" "+name(i)+" alias:",!alias(i)

    if exists(ut'i)    
       set ut'i=i
     else
       if class(i) eq "FORMULA"
	 ut'i=i
       else
         copy i to ut
       end if -- Formula/serie
    end if -- Eksisterer/ny i ref.basen

    $desc i 
  end loop
else  -- Datointervall åpent eller halvåpent
  loop for i in liste
    if exists(ut'i) 
      set eksist=""
    else
      set eksist="NY"
    end if
    type "Kopierer "+eksist+" "+class(i)+" "+name(i)+" alias:",!alias(i)

    if class(i) eq "FORMULA"
    ut'i=i
    else 
      copy i to ut
    end if  -- Eksisterer/ny i ref.basen

    $desc i -- Utføres på alle serier (selv om beskr er overført vha copy)
  end loop
end if
end procedure





procedure $kopi_avrund_convert
-- Styrer kopiering fra produksjonsbase til base UT
-- Konverterer serier til den frekvens satt ved @freq
-- Forutsetter alle opsjoner riktig satt.
argument desi, del_med, liste
block
  local scalar serienavn:string
  local scalar suff:string=substring(@freq,1,1)
  local scalar nystr:string

  convert on
  convert.technique discrete
  
  type ""
  type "$kopi_avrund_convert: Serier og formler konverteres til "+&&
       "serier med følgende egenskaper:"
  type "Freq    = " + @freq
  type "Observed= " + @observed
  type "Convert.technique= "+@convert.technique
  type "Convert.automatic= "+string(@convert.automatic)
  type "Overfører kun eksisterende data i tidsspennet " + @date

  loop for i in liste
    -- create new series name
    if substring(name(i),length(name(i))-2,2) eq ".W" &&
    or substring(name(i),length(name(i))-2,2) eq ".M" &&
    or substring(name(i),length(name(i))-2,2) eq ".B" &&
    or substring(name(i),length(name(i))-2,2) eq ".Q" &&
    or substring(name(i),length(name(i))-2,2) eq ".A" 
      set serienavn=substring(name(i),1,length(name(i))-2)+suff
    else
      set serienavn=name(i)+"."+suff
    end if

    if exists(ut'id(serienavn)) 
      set nystr=""
      if freq(ut'id(serienavn)) ne @freq
        signal error:"freq(serienavn)="+freq(serienavn)+" @freq="+@freq
      end if
    else
      set nystr="NY"
    end if

    type class(i)+" "+name(i)+" update "+nystr+" serie "+serienavn

    if firstdate ne NC and lastdate ne NC and exists(ut'id(serienavn))
    -- Lukket dato-intervall	
      set ut'id(serienavn)= round(i/del_med, desi)
    else
    -- Datointervall åpent eller halvåpent, eller
    -- serien eksisterer ikke fra før
        ut'id(serienavn)= round(i/del_med, desi)
    end if -- eksisterer/ny i ref.base

    $desc_2 ut'id(serienavn), i
  end loop

end block
end procedure



procedure $kopi_avrund
-- Styrer kopiering fra produksjonsbase til base UT
-- Hvis orginalserien er en formel blir den ekspandert
-- Alle serier og formler divideres med angitt verdi (kan være 1)
--  og avrundes til oppgitt antall desimaler 
-- Beskrivelser etc. kopieres.
-- him (k203) 03.04.98 og jfi litt seinere
--
-- MERK at avrunding skjer med round som bruker NUMERIC/PRECISION 
-- avhengig av hva utrykket som skal avrundes er. 
-- 
argument desi,del_med, liste

  type ""
  type "$kopi_avrund: Eventuelle formler ekspanderes til serier "+&&
       "med følgende egenskaper:"
  if @convert.automatic eq TRUE
    -- Kunne kanskje gitt en feilmelding i steden?
    type "Freq    = " + @freq
    type "Convert.technique= "+@convert.technique
  end if
  type "Observed= " + @observed
  type "Overfører kun eksisterende data i tidsspennet " + @date

  local scalar eksist:string

  IF firstdate ne NC and lastdate ne NC
  -- Dato-intervall er lukket
    loop for i in liste
      if class(i) ne "FORMULA" and firstvalue(i) eq NC and lastvalue(i) eq NC
        type "ADVARSEL: tom serie "+name(i)+", er derfor IKKE overført" 
      else
	if exists(ut'i) 
	  set eksist=""
	else
	  set eksist="NY"
	end if
	type "Oppdaterer "+eksist+" "+class(i)+" "+name(i)+&&
	     " alias:",!alias(i),&&
	     ", delt med "+string(del_med)+&&
	     " , avrundet til "+string(desi)+" desimaler"

	if exists(ut'i)
	  set ut'i= round(i/del_med, desi)
	else
	  if class(i) eq "FORMULA"
	    ut'i= round(i/del_med, desi)
	  else
	    copy i to ut
	    block
	      date firstvalue(i) to lastvalue(i)
	      set ut'i=round(ut'i/del_med, desi)
	    end block
	  end if -- formula/serie
	end if -- eksisterer/ny i ref.base

	$desc i
      end if -- tom serie
    end loop
  ELSE

  -- Datointervall åpent eller halvåpent
    loop for i in liste
      if class(i) ne "FORMULA" and firstvalue(i) eq NC and lastvalue(i) eq NC
        type "ADVARSEL: tom serie "+name(i)+", er derfor IKKE overført" 
      else
	if exists(ut'i) 
	  set eksist=""
	else
	  set eksist="NY"
	end if
	type "Kopierer "+eksist+" "+class(i)+" "+name(i)+&&
	     " alias:",!alias(i),&&
	     ", deles med "+string(del_med)+&&
	     ", avrundes til "+string(desi)+" desimaler"

	if class(i) eq "FORMULA"
	  ut'i=round((i /del_med),desi)
	else
          copy i to ut
          block
	    date firstvalue(i) to lastvalue(i)
	    set ut'i=round(ut'i/del_med,desi)
	  end block
	end if -- formula/serie

        $desc i
      end if -- tom serie
    end loop
  END IF
end procedure

-- 6/12-2007


procedure $kopi_ur
-- Styrer kopiering fra base IN til base UT
-- Hvis orginalserien er en formel blir den ekspandert
-- beskrivelser etc. kopiert
argument liste

type ""
type "$kopi: Eventuelle formler ekspanderes til serier med "+&&
     "følgende egenskaper:"
type "Observed= " + @observed
if @convert.automatic eq TRUE
  -- Kunne kanskje gitt en feilmelding i steden?
  type "Freq    = " + @freq
  type "Convert.technique= "+@convert.technique
end if
type "Overfører kun eksisterende data i tidsspennet " + @date

local scalar eksist:string

if firstdate ne NC and lastdate ne NC  -- Date satt
  loop for i in liste
    if exists(ut'i) 
      set eksist=""
    else
      set eksist="NY"
    end if
    type "Oppdaterer "+eksist+" "+class(i)+" "+name(i)+" alias:",!alias(i)

    if exists(ut'i)    
       set ut'i=i
     else
       if class(i) eq "FORMULA"
	 ut'i=i
       else
         copy i to ut
       end if -- Formula/serie
    end if -- Eksisterer/ny i ref.basen

    $desc i 
  end loop
else  -- Datointervall åpent eller halvåpent
  loop for i in liste
    if exists(ut'i) 
      set eksist=""
    else
      set eksist="NY"
    end if
    type "Kopierer "+eksist+" "+class(i)+" "+name(i)+" alias:",!alias(i)

    date firstvalue(i) to lastvalue(i) 

    if class(i) eq "FORMULA"
    -- Endret PET, 4/12-2007 pga problemer med NC hver gang UR publiseres
    -- ut'i=i
      ut'i=overlay(i,series(0))
    else 
      copy i to ut
      set ut'i=overlay(i,series(0))
    end if  -- Eksisterer/ny i ref.basen

    $desc i -- Utføres på alle serier (selv om beskr er overført vha copy)
  end loop
end if
end procedure
