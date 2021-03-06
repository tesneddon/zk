PENVFLAGS   = /NOOBJECT/ENVIRONMENT=$(MMS$TARGET)/NOLIST

.SUFFIXES : .MESSAGE .OBJECT .ROOM

.MESSAGE.PEN :
.IFDEF __MMK__
	MCR EXE$:IFC COMPILE MESSAGE $(MMS$SOURCE) -
		/MACRO=NLA0:/DEFINITIONS=$(MMS$TARGET:.PEN=.PAS)
	$(PASCAL) $(PENVFLAGS) $(MMS$TARGET:.PEN=.PAS)
.ELSE
	MCR EXE$:IFC COMPILE MESSAGE $(MMS$SOURCE) -
		/MACRO=NLA0:/DEFINITION=$(SUBST .PEN,.PAS,$(MMS$TARGET))
	$(PASCAL) $(PENVFLAGS) $(SUBST .PEN,.PAS,$(MMS$TARGET))
.ENDIF

.MESSAGE.OBJ :
.IFDEF __MMK__
	MCR EXE$:IFC COMPILE MESSAGE $(MMS$SOURCE) -
		/MACRO=$(MMS$TARGET:.OBJ=.MAR)/DEFINITIONS=NLA0:
	$(MACRO) $(MFLAGS) $(MMS$TARGET:.OBJ=.MAR)
.ELSE
	MCR EXE$:IFC COMPILE MESSAGE $(MMS$SOURCE) -
		/MACRO=$(SUBST .OBJ,.MAR,$(MMS$TARGET))/DEFINITION=NLA0:
	$(MACRO) $(MFLAGS) $(SUBST .OBJ,.MAR,$(MMS$TARGET))
.ENDIF

.OBJECT.PEN :
.IFDEF __MMK__
	MCR EXE$:IFC COMPILE OBJECT $(MMS$SOURCE) -
		/MACRO=NLA0:/DEFINITIONS=$(MMS$TARGET:.PEN=.PAS)
	$(PASCAL) $(PENVFLAGS) $(MMS$TARGET:.PEN=.PAS)
.ELSE
	MCR EXE$:IFC COMPILE OBJECT $(MMS$SOURCE) -
		/MACRO=NLA0:/DEFINITION=$(SUBST .PEN,.PAS,$(MMS$TARGET))
	$(PASCAL) $(PENVFLAGS) $(SUBST .PEN,.PAS,$(MMS$TARGET))
.ENDIF

.OBJECT.OBJ :
.IFDEF __MMK__
	MCR EXE$:IFC COMPILE OBJECT $(MMS$SOURCE) -
		/MACRO=$(MMS$TARGET:.OBJ=.MAR)/DEFINITIONS=NLA0:
	$(MACRO) $(MFLAGS) $(MMS$TARGET:.OBJ=.MAR)
.ELSE
	MCR EXE$:IFC COMPILE OBJECT $(MMS$SOURCE) -
		/MACRO=$(SUBST .OBJ,.MAR,$(MMS$TARGET))/DEFINITION=NLA0:
	$(MACRO) $(MFLAGS) $(SUBST .OBJ,.MAR,$(MMS$TARGET))
.ENDIF

.ROOM.PEN :
.IFDEF __MMK__
	MCR EXE$:IFC COMPILE ROOM $(MMS$SOURCE) -
		/MACRO=NLA0:/DEFINITIONS=$(MMS$TARGET:.PEN=.PAS)
	$(PASCAL) $(PENVFLAGS) $(MMS$TARGET:.PEN=.PAS)
.ELSE
	MCR EXE$:IFC COMPILE ROOM $(MMS$SOURCE) -
		/MACRO=NLA0:/DEFINITION=$(SUBST .PEN,.PAS,$(MMS$TARGET))
	$(PASCAL) $(PENVFLAGS) $(SUBST .PEN,.PAS,$(MMS$TARGET))
.ENDIF

.ROOM.OBJ :
.IFDEF __MMK__
	MCR EXE$:IFC COMPILE ROOM $(MMS$SOURCE) -
		/MACRO=$(MMS$TARGET:.OBJ=.MAR)/DEFINITIONS=NLA0:
	$(MACRO) $(MFLAGS) $(MMS$TARGET:.OBJ=.MAR)
.ELSE
	MCR EXE$:IFC COMPILE ROOM $(MMS$SOURCE) -
		/MACRO=$(SUBST .OBJ,.MAR,$(MMS$TARGET))/DEFINITION=NLA0:
	$(MACRO) $(MFLAGS) $(SUBST .OBJ,.MAR,$(MMS$TARGET))
.ENDIF

ALL : ENV_FILES MAIN
	@ CONTINUE

ENV_FILES : LIB$:ZK$LEX_DEF.PEN LIB$:ZK$PARSE_DEF.PEN -
            LIB$:ZK$PARSE_OBJ_DEF.PEN LIB$:ZK$AST_DEF.PEN -
            LIB$:ZK$ACTION_DEF.PEN LIB$:ZK$ROUTINES_DEF.PEN -
            LIB$:ZK$WIZARD_DEF.PEN LIB$:ZK$OBJECT_DEF.PEN LIB$:ZK$INIT_DEF.PEN
	@ CONTINUE

MAIN : EXE$:ZK$LINK_TIME.EXE EXE$:MAKE_VERSION.EXE EXE$:ZK$MAIN.EXE
	@ CONTINUE

EXE$:ZK$LINK_TIME.EXE : OBJ$:ZK$LINK_TIME.OBJ
	LINK/EXECUTABLE=$(MMS$TARGET) $(MMS$SOURCE)

EXE$:MAKE_VERSION.EXE : OBJ$:MAKE_VERSION.OBJ
	LINK/EXECUTABLE=$(MMS$TARGET) $(MMS$SOURCE)

EXE$:ZK$MAIN.EXE : OBJ$:ZK$TEXT.OBJ OBJ$:ZK$DESC.OBJ OBJ$:ZK$OBJ.OBJ -
                   OBJ$:ZK$ROOM.OBJ OBJ$:ZK$MAIN.OBJ OBJ$:ZK$PARSE.OBJ -
                   OBJ$:ZK$LEX.OBJ OBJ$:ZK$AST.OBJ OBJ$:ZK$PARSE_OBJ.OBJ -
                   OBJ$:ZK$ACTION.OBJ OBJ$:ZK$ROUTINES.OBJ OBJ$:ZK$ROOM.OBJ -
                   OBJ$:ZK$WIZARD.OBJ OBJ$:ZK$OBJECT.OBJ OBJ$:ZK$INIT.OBJ -
                   OBJ$:ZK$OBJ.OBJ OBJ$:ZK$TEXT.OBJ OBJ$:ZK$DESC.OBJ
	RUN EXE$:ZK$LINK_TIME
.IFDEF VERSION
	PIPE ( WRITE SYS$OUTPUT "ZKVERSION.OPT" ; -
	       WRITE SYS$OUTPUT "$(VERSION)" ) -
	     | RUN EXE$:MAKE_VERSION
	LINK/EXECUTABLE=$(MMS$TARGET)/NOTRACEBACK ZKMAIN_LNK/OPT,-
		ZKLINK_TIME/OPT,ZKVERSION/OPT
.ELSE
	PIPE ( WRITE SYS$OUTPUT "ZKVERSION.OPT" ; -
	       WRITE SYS$OUTPUT "X0.0" ) -
	     | RUN EXE$:MAKE_VERSION
	LINK/EXECUTABLE=$(MMS$TARGET) ZKMAIN_LNK/OPT,ZKLINK_TIME/OPT, -
		ZKVERSION/OPT
.ENDIF

OBJ$:ZK$MAIN.OBJ : ZKMAIN.PAS LIB$:ZK$DEF.PEN LIB$:ZK$CONTEXT_DEF.PEN -
                   LIB$:ZK$PARSE_DEF.PEN LIB$:ZK$LEX_DEF.PEN -
                   LIB$:ZK$AST_DEF.PEN LIB$:ZK$TEXT.PEN LIB$:ZK$INIT_DEF.PEN -
                   LIB$:ZK$ACTION_DEF.PEN
OBJ$:ZK$PARSE.OBJ : ZKPARSE.PAS LIB$:ZK$DEF.PEN LIB$:ZK$LEX_DEF.PEN -
                    LIB$:ZK$PARSE_OBJ_DEF.PEN LIB$:ZK$CONTEXT_DEF.PEN
OBJ$:ZK$PARSE_OBJ.OBJ : ZKPARSE_OBJ.PAS LIB$:ZK$DEF.PEN LIB$:ZK$OBJ.PEN -
                        LIB$:ZK$TEXT.PEN LIB$:ZK$LEX_DEF.PEN
OBJ$:ZK$LEX.OBJ : ZKLEX.PAS LIB$:ZK$DEF.PEN
OBJ$:ZK$AST.OBJ : ZKAST.PAS LIB$:ZK$DEF.PEN LIB$:ZK$CONTEXT_DEF.PEN -
                  LIB$:ZK$OBJ.PEN LIB$:ZK$TEXT.PEN LIB$:ZK$ACTION_DEF.PEN -
                  LIB$:ZK$WIZARD_DEF.PEN LIB$:ZK$OBJECT_DEF.PEN -
                  LIB$:ZK$ROUTINES_DEF.PEN LIB$:ZK$INIT_DEF.PEN
OBJ$:ZK$ACTION.OBJ : ZKACTION.PAS LIB$:ZK$CONTEXT_DEF.PEN LIB$:ZK$ROOM.PEN -
                     LIB$:ZK$OBJ.PEN LIB$:ZK$ROUTINES_DEF.PEN -
                     LIB$:ZK$OBJECT_DEF.PEN LIB$:ZK$TEXT.PEN LIB$:ZK$DESC.PEN
OBJ$:ZK$OBJECT.OBJ : ZKOBJECT.PAS LIB$:ZK$CONTEXT_DEF.PEN LIB$:ZK$ROOM.PEN -
                     LIB$:ZK$OBJ.PEN  LIB$:ZK$ROUTINES_DEF.PEN -
                     LIB$:ZK$TEXT.PEN LIB$:ZK$ACTION_DEF.PEN
OBJ$:ZK$ROUTINES.OBJ : ZKROUTINES.PAS LIB$:ZK$CONTEXT_DEF.PEN -
                       LIB$:ZK$OBJ.PEN LIB$:ZK$ROOM.PEN LIB$:ZK$TEXT.PEN -
                       LIB$:ZK$ROUTINES_DEF.PEN
OBJ$:ZK$WIZARD.OBJ : ZKWIZARD.PAS LIB$:ZK$CONTEXT_DEF.PEN LIB$:ZK$OBJ.PEN -
                     LIB$:ZK$ROOM.PEN LIB$:ZK$TEXT.PEN -
                     LIB$:ZK$ACTION_DEF.PEN LIB$:ZK$ROUTINES_DEF.PEN
OBJ$:ZK$INIT.OBJ : ZKINIT.PAS LIB$:ZK$CONTEXT_DEF.PEN LIB$:ZK$OBJ.PEN -
                   LIB$:ZK$ROOM.PEN LIB$:ZK$ROUTINES_DEF.PEN -
                   LIB$:ZK$TEXT.PEN LIB$:ZK$ACTION_DEF.PEN

OBJ$:ZK$LINK_TIME.OBJ : ZKLINK_TIME.PAS
OBJ$:MAKE_VERSION.OBJ : MAKE_VERSION.PAS

LIB$:ZK$LEX_DEF.PEN : ZKLEX_DEF.PAS LIB$:ZK$DEF.PEN
LIB$:ZK$PARSE_DEF.PEN : ZKPARSE_DEF.PAS LIB$:ZK$DEF.PEN LIB$:ZK$CONTEXT_DEF.PEN
LIB$:ZK$PARSE_OBJ_DEF.PEN : ZKPARSE_OBJ_DEF.PAS LIB$:ZK$DEF.PEN
LIB$:ZK$AST_DEF.PEN : ZKAST_DEF.PAS LIB$:ZK$DEF.PEN LIB$:ZK$CONTEXT_DEF.PEN
LIB$:ZK$ACTION_DEF.PEN : ZKACTION_DEF.PAS LIB$:ZK$CONTEXT_DEF.PEN
LIB$:ZK$OBJECT_DEF.PEN : ZKOBJECT_DEF.PAS LIB$:ZK$CONTEXT_DEF.PEN
LIB$:ZK$ROUTINES_DEF.PEN : ZKROUTINES_DEF.PAS LIB$:ZK$CONTEXT_DEF.PEN
LIB$:ZK$WIZARD_DEF.PEN : ZKWIZARD_DEF.PAS LIB$:ZK$CONTEXT_DEF.PEN
LIB$:ZK$INIT_DEF.PEN : ZKINIT_DEF.PAS LIB$:ZK$CONTEXT_DEF.PEN
LIB$:ZK$CONTEXT_DEF.PEN : ZKCONTEXT_DEF.PAS LIB$:ZK$OBJ.PEN LIB$:ZK$ROOM.PEN
LIB$:ZK$DEF.PEN : ZKDEF.PAS

OBJ$:ZK$DESC.OBJ : ZKDESC.MESSAGE
OBJ$:ZK$OBJ.OBJ : ZKOBJ.OBJECT
OBJ$:ZK$ROOM.OBJ : ZKROOM.ROOM
OBJ$:ZK$TEXT.OBJ : ZKTEXT.MESSAGE

LIB$:ZK$DESC.PEN : ZKDESC.MESSAGE
LIB$:ZK$OBJ.PEN : ZKOBJ.OBJECT
LIB$:ZK$ROOM.PEN : ZKROOM.ROOM
LIB$:ZK$TEXT.PEN : ZKTEXT.MESSAGE

CLEAN :
	@ CONTINUE
