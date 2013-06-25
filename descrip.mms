 FACILITY = ZK   + BACKUP = BACKUP/INTERCHANGE/BLOCK_SIZE=8192  ECHO = WRITE SYS$OUTPUT    .FIRST :E 	@ ROOT = F$PARSE(F$ENVIRONMENT("DEFAULT"),,,"DEVICE","NO_CONCEAL") - H 	       + F$PARSE(F$ENVIRONMENT("DEFAULT"),,,"DIRECTORY","NO_CONCEAL") -: 	       - "][" - ".000000" - "000000." - ".]" - "]" + ".]"5 	@ DEFINE/JOB/NOLOG/TRANSLATION=CONCEALED BLD$ 'ROOT' 3 	@ DEFINE/JOB/NOLOG EXE$ BLD$:[$(MMSARCH_NAME).EXE] 3 	@ DEFINE/JOB/NOLOG LIB$ BLD$:[$(MMSARCH_NAME).LIB] 3 	@ DEFINE/JOB/NOLOG OBJ$ BLD$:[$(MMSARCH_NAME).OBJ]  	@ CREATE/NOLOG/DIRECTORY EXE$:  	@ CREATE/NOLOG/DIRECTORY LIB$:  	@ CREATE/NOLOG/DIRECTORY OBJ$: $ 	@ DEFINE/JOB/NOLOG IFC$LIBRARY LIB$   ALL :  .IFDEF __MMK__# 	$(MMS)$(MMSQUALIFIERS)/WORK=[.ENV] # 	$(MMS)$(MMSQUALIFIERS)/WORK=[.IFC] " 	$(MMS)$(MMSQUALIFIERS)/WORK=[.ZK] .ELSE  	SET DEFAULT [.ENV]  	$(MMS)$(MMSQUALIFIERS)  	SET DEFAULT [-.IFC] 	$(MMS)$(MMSQUALIFIERS)  	SET DEFAULT [-.ZK]  	$(MMS)$(MMSQUALIFIERS)  .ENDIF   CLEAN : 2 	- DELETE [.$(MMSARCH_NAME)...]*.*;*/EXCLUDE=*.DIR .IFDEF __MMK__3 	- $(MMS)$(MMSQUALIFIERS)/WORK=[.ENV] $(MMS$TARGET) 3 	- $(MMS)$(MMSQUALIFIERS)/WORK=[.IFC] $(MMS$TARGET) 2 	- $(MMS)$(MMSQUALIFIERS)/WORK=[.ZK] $(MMS$TARGET) .ELSE  	SET DEFAULT [.ENV] % 	$(MMS)$(MMSQUALIFIERS) $(MMS$TARGET)  	SET DEFAULT [-.IFC]% 	$(MMS)$(MMSQUALIFIERS) $(MMS$TARGET)  	SET DEFAULT [-.ZK] % 	$(MMS)$(MMSQUALIFIERS) $(MMS$TARGET)  .ENDIF   .IFDEF VERSION KIT : VERSION 7 	@ DEFINE/JOB/NOLOG KIT$ BLD$:[KIT.'F$TRNLNM("$VMI$")']  	@ CREATE/NOLOG/DIRECTORY KIT$: > 	$(BACKUP) BLD$:[ZK]KITINSTAL.COM,ZK$CLD.CLD,ZK$DCL_HELP.HLP -% 		KIT$:'F$TRNLNM("$VMI$")'.A/SAVE_SET H 	$(BACKUP) BLD$:[VAX.EXE]ZK$MAIN.EXE KIT$:'F$TRNLNM("$VMI$")'.B/SAVE_SETJ 	$(BACKUP) BLD$:[ALPHA.EXE]ZK$MAIN.EXE KIT$:'F$TRNLNM("$VMI$")'.C/SAVE_SETI 	$(BACKUP) BLD$:[IA64.EXE]ZK$MAIN.EXE KIT$:'F$TRNLNM("$VMI$")'.D/SAVE_SET > 	$(BACKUP) BLD$:[000000]DESCRIP.MMS,[ENV...]*.*,[IFC...]*.*, -7 			[ZK...]*.* KIT$:'F$TRNLNM("$VMI$")'_SRC.BCK/SAVE_SET   	 VERSION : 9 	@ TYPE = F$EDIT(F$EXTRACT(0, 1, "$(VERSION)"), "UPCASE") 2 	@ IF (F$TYPE(TYPE) .NES. "STRING") THEN TYPE = "", 	@ ED = F$ELEMENT(1, "-", "$(VERSION)"-TYPE)! 	@ IF (ED .EQS. "-") THEN ED = "" , 	@ MAJ=F$ELEMENT(0, "-" , "$(VERSION)"-TYPE)! 	@ IF (MAJ .EQS. "") THEN MAJ="1"  	@ MIN=F$ELEMENT(1, ".", MAJ) $ 	@ IF (MIN .EQS. ".") THEN MIN = "0" 	@ MAJ=F$ELEMENT(0, ".", MAJ) % 	@ IF (TYPE .EQS. "") THEN TYPE = "X" # 	@ VERSION = TYPE + MAJ + "." + MIN 5 	@ IF (ED .NES. "") THEN VERSION = VERSION + "-" + ED F 	@ PCSI = TYPE + F$FAO("!2ZL", F$INT(MAJ)) + F$FAO("!2ZL", F$INT(MIN))N 	@ VMI = "$(FACILITY)" + F$FAO("!2ZL", F$INT(MAJ)) + F$FAO("!1ZL", F$INT(MIN))/ 	@ IF (ED .NES. "") THEN PCSI = PCSI + "-" + ED 2 	@ IF (TYPE .EQS. "E") THEN TYPE = "EARLY-ADOPTER"/ 	@ IF (TYPE .EQS. "T") THEN TYPE = "FIELD-TEST" , 	@ IF (TYPE .EQS. "V") THEN TYPE = "RELEASE"1 	@ IF (TYPE .EQS. "X") THEN TYPE = "EXPERIMENTAL" / 	@ IF (F$LENGTH(TYPE) .LE. 1) THEN TYPE="OTHER" $ 	@ DEFINE/JOB/NOLOG $PCSI$ "''PCSI'"$ 	@ DEFINE/JOB/NOLOG $TYPE$ "''TYPE'"' 	@ DEFINE/JOB/NOLOG $VERS$ "''VERSION'" # 	@ DEFINE/JOB/NOLOG $VMI$  "''VMI'"  .ELSE  KIT : , 	@ $(ECHO) "%W, VERSION macro not specified" 	@ $(ECHO) "" 3 	@ $(ECHO) "The KIT target must be called like so:"  	@ $(ECHO) "" 3 	@ $(ECHO) "    $$(MMS) KIT/MACRO=""VERSION=V1.1"""  	@ $(ECHO) ""  .ENDIF