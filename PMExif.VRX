/*:VRX         Main
*/
/*  Main
*/
Main:
/*  Process the arguments.
    Get the parent window.
*/
    parse source . calledAs .
    parent = ""
    argCount = arg()
    argOff = 0
    if( calledAs \= "COMMAND" )then do
        if argCount >= 1 then do
            parent = arg(1)
            argCount = argCount - 1
            argOff = 1
        end
    end; else do
        call VROptions 'ImplicitNames'
    end
    InitArgs.0 = argCount
    if( argCount > 0 )then do i = 1 to argCount
        InitArgs.i = arg( i + argOff )
    end
    drop calledAs argCount argOff

/*  Load the windows
*/
    call VRInit
    parse source . . spec
    _VREPrimaryWindowPath = ,
        VRParseFileName( spec, "dpn" ) || ".VRW"
    _VREPrimaryWindow = ,
        VRLoad( parent, _VREPrimaryWindowPath )
    drop parent spec
    if( _VREPrimaryWindow == "" )then do
        call VRMessage "", "Cannot load window:" VRError(), ,
            "Error!"
        _VREReturnValue = 32000
        signal _VRELeaveMain
    end

/*  Process events
*/
    call Init
    signal on halt
    do while( \ VRGet( _VREPrimaryWindow, "Shutdown" ) )
        _VREEvent = VREvent()
        interpret _VREEvent
    end
_VREHalt:
    _VREReturnValue = Fini()
    call VRDestroy _VREPrimaryWindow
_VRELeaveMain:
    call VRFini
exit _VREReturnValue

VRLoadSecondary:
    __vrlsWait = abbrev( 'WAIT', translate(arg(2)), 1 )
    if __vrlsWait then do
        call VRFlush
    end
    __vrlsHWnd = VRLoad( VRWindow(), VRWindowPath(), arg(1) )
    if __vrlsHWnd = '' then signal __vrlsDone
    if __vrlsWait \= 1 then signal __vrlsDone
    call VRSet __vrlsHWnd, 'WindowMode', 'Modal' 
    __vrlsTmp = __vrlsWindows.0
    if( DataType(__vrlsTmp) \= 'NUM' ) then do
        __vrlsTmp = 1
    end
    else do
        __vrlsTmp = __vrlsTmp + 1
    end
    __vrlsWindows.__vrlsTmp = VRWindow( __vrlsHWnd )
    __vrlsWindows.0 = __vrlsTmp
    do while( VRIsValidObject( VRWindow() ) = 1 )
        __vrlsEvent = VREvent()
        interpret __vrlsEvent
    end
    __vrlsTmp = __vrlsWindows.0
    __vrlsWindows.0 = __vrlsTmp - 1
    call VRWindow __vrlsWindows.__vrlsTmp 
    __vrlsHWnd = ''
__vrlsDone:
return __vrlsHWnd

/*:VRX         CN_1_ContextMenu
*/
CN_1_ContextMenu: 

HndRec = VRInfo("Record");

DynMenuName = "MM_SortCols2";

if hndRec = "" then do
   Call ZCre_Menu;
/* ok = VRMethod( DynMenuName,  "PopUp");       ++ alt ++ */
   ok = VRMethod( "MM_SortCols",  "PopUp");
end;
else;
   ok = VRMethod("Menu", "PopUp");


return;

/*:VRX         CN_1_DoubleClick
*/
CN_1_DoubleClick: 

HndRec = VRInfo("Record");

if HndRec = "" then RETURN -1;

CN_1_DoubleClick_Entry2:    /* <== bringt HndRec mit <====   */

ImgFS = VRMethod("CN_1", "GetFieldData", HndRec, HndImgFS );

CN_1_DoubleClick_Entry3:    /* <== bringt ImgFS  mit <====   */

/* -----------------------------------        */
/* Externes Graphik-Programm besorgen:        */
/* -----------------------------------        */
ExtImgPgm = SysINI(INIFile, "Settings", "ExtImgPgm");

if ExtImgPgm = "ERROR:" then do

   ExtImgPgm = VRFileDialog( VRWindow(), "Select external editor program:", "OPEN", "*.exe" );

   ok = SysINI(INIFile, "Settings", "ExtImgPgm", ExtImgPgm)

   ExtImgPgm = SysINI(INIFile, "Settings", "ExtImgPgm");    /* nochmal...   */

end;

if ExtImgPgm = "ERROR:" then RETURN -1;


ExtImgPgm '"'ImgFS'"';

return;

/*:VRX         CN_1_DragDrop
*/
CN_1_DragDrop: 

if(0) then do
   say "=>" VRInfo("ContainerName");
   say "=>" VRInfo("SourceName");

   say "=>" VRInfo("ContainerName") || VRInfo("SourceName")"!";
end;

ImgFile = VRInfo("ContainerName") || VRInfo("SourceName");

ok = VRSet("CN_1", "Painting", 0 );

Call ZSingleImage ImgFile;

ok = VRSet("CN_1", "Painting", 1 );

return;

/*:VRX         CN_Browser_Click
*/
CN_Browser_Click: 

!CurRec = VRInfo("Record");
if !CurRec = "" then RETURN -1;

/* -----------------------------------------------          */
/* Selektieren ('Markieren') mehrere File-Entries:          */
/* -----------------------------------------------          
   oder:
 * -----------------------------------------------          */
/* Anzeigen Img-Data eines gespeicherten Images:            */
/* -----------------------------------------------          */

/* Das funktioniert nur mit CN_Browser: List:               */
/* 'ExtendedSelect=1, MultiSelect=0'                        */

/* Problem: Abfangen der automatisch (unerlaubt) intern     */
/*          ausgelîsten Click-Events durch MMImg_Next_Click */
if !MMImg_Next = 1 then do
   !MMImg_Next = 0;
   RETURN -1;
end;

if VRMethod("CN_Browser", "GetFieldData", !CurRec, hndBrsType ) = YGlob.QRecType_File then do
   /* nur fÅr File-Entries (z.Zt.):                         */

   if VRInfo("CtrlPressed") = 1 then do
      Call ZSet_RecordTag !CurRec, "S", "Auto";
   end;

   if VRInfo("ShiftPressed") = 1 then do

        From_Rec = YGlob.YCurRec;
        From_Seq = YGlob.YCurSeq;
        To_Rec   = !CurRec;
        To_Seq   = VRMethod("CN_Browser", "GetFieldData", !CurRec, hndBrsSeq );

        if (From_Seq - To_Seq) > 0 then
           What = "Previous";       /* rÅckwÑrts lesen:         */
        else;
           What = "Next";           /* vorwÑrts lesen:          */

        ok = VRMethod("CN_Browser", "GetRecordList", "ALL", "Recs." );
        do i = 1 to Recs.0
           if Recs.i = From_Rec then do
              !CurRec = Recs.i;
              do forever
                 PrevRec = VRMethod("CN_Browser", "GetRecordAttr", !CurRec, What );
                 !Seq    = VRMethod("CN_Browser", "GetFieldData",  !CurRec, hndBrsSeq );
                 ok = VRMethod("CN_Browser", "SetRecordAttr", !CurRec, YGlob.YTag_Selected, 1 ); /* Set InUse */
                 if !Seq = To_Seq then
                    LEAVE;
                 !CurRec = PrevRec;     /* nÑchste Runde         */
              end;
              i = Recs.0;               /* beende Ñussere Loop   */
           end;
        end;
   end;

   if \ ( VRInfo("ShiftPressed") ) then do

        /* also einfacher oder <CTRL> Click:                */
        YGlob.YCurRec = !CurRec;
        YGlob.YCurSeq = VRMethod("CN_Browser", "GetFieldData", !CurRec, hndBrsSeq );

   end;

   if \ ( VRInfo("ShiftPressed") | VRInfo("CtrlPressed") ) then do 

        /* also einfacher Click:                */
        Call ZReset_All YGlob.YTag_Selected;

   end;

end;

return;
-----------
ZReset_All: Procedure
Attr = arg(1);
ok = VRMethod("CN_Browser", "GetRecordList", Attr, "Recs.");
do i = 1 to Recs.0
   ok = VRMethod("CN_Browser", "SetRecordAttr", Recs.i, Attr, 0);
end;
return 0;
/*:VRX         CN_Browser_DoubleClick
*/
CN_Browser_DoubleClick: 

/* Doubleclick:
   Entweder Expand Directory
   Oder:    File zum Edit bereitstellen
*/

Rec = VRInfo("Record");

CN_Browser_DoubleClick_2:   /* bringt 'Rec' mit            */
 
if Rec = "" then RETURN -1;

!CurRec = Rec;

/* --------------           */
/* (1) Drive:               */
/* --------------           */
if VRMethod("CN_Browser", "GetFieldData", Rec, hndBrsType) = YGlob.QRecType_Drive then do
   Call XSay ZZMess(,YGlob.YPGMName,,YGlob.YLang, 61 ); /* "Drive-Level already resolved - select 'Refresh' from context-menu"   */
   RETURN -1;
end;

/* --------------           */
/* (2) Directory:           */
/* --------------           */
if VRMethod("CN_Browser", "GetFieldData", Rec, hndBrsType) = YGlob.QRecType_Dir   then do
   Dir = VRMethod("CN_Browser", "GetRecordAttr", Rec, "Filename" );

   !ImgDir = Dir;           /* versorgen fÅr spÑter Save-INI        */

   Ret = ZFill_Browser( "DIR", Rec );

   if Ret = -2 then do      /* schon resolved                               */
                            /* mark all records under Dir as 'selected'     */      
      ok = VRMethod("CN_Browser", "GetRecordList", "ALL", "Recs.");
      do i = 1 to Recs.0
         if !CurRec = VRMethod("CN_Browser", "GetRecordAttr", Recs.i, "PARENT") then do
            ok = VRMethod("CN_Browser", "SetRecordAttr", Recs.i, YGlob.YTag_Selected, 1);   /* "InUse"      */
         end;
      end;
   end;

   ok = ZSet_Wait( "Off" ); /* Ende "Bitte warten ... "             */

   RETURN 0;
end;

/* --------------           */
/* (3) File:                */
/* --------------           */
if VRMethod("CN_Browser", "GetFieldData", Rec, hndBrsType) = YGlob.QRecType_File    ,
 | VRMethod("CN_Browser", "GetFieldData", Rec, hndBrsType) = YGlob.QRecType_Detail  then do

   NOP;     /* hier nix tun!            */

   RETURN 0;

end;

/* ?? */    Call XSay "Something's wrong with my baby,...";

return

/*:VRX         Fini
*/
Fini:
    window = VRWindow()
    call VRSet window, "Visible", 0
    drop window
return 0

/*:VRX         GB_Pegel_DragDrop
*/
GB_Pegel_DragDrop: 

Left   = VRInfo("Left");
Top    = VRInfo("Top");     /* nicht zu gebrauchen .... */
Bottom = VRInfo("Bottom");

Top = VRGet("GB_Pegel", "Height") - Bottom;

Top = Top - ( VRGet(!PgMk,"Height") % 2 );

say "Bottom="Bottom",Top="Top",Left="Left"!";

TopImgNo = ( Top / VRGet("GB_Pegel", "Height") * VRGet("EF_Limit","Value" ) ) %1;

say "TopImgNo="TopImgNo"!";


OldTopNo = VRGet("EF_TopImgNo","Value" );
ok = VRSet("EF_TopImgNo","Value", TopImgNo );
Call ZSL_Change ,(TopImgNo - OldTopNo);

return;

/*:VRX         Halt
*/
Halt:
    signal _VREHalt
return

/*:VRX         Init
*/
Init:

nok = RxFuncAdd("SysLoadFuncs",  "RexxUtil", "SysLoadFuncs") ;  rc = SysLoadFuncs();
nok = RxFuncAdd("FileLoadFuncs", "FILEREXX", "FileLoadFuncs");rc = FileLoadFuncs();
nok = RxFuncAdd("RxExtra",       "RxExtras", "RxExtra")      ;  rc = RxExtra("LOAD");
nok = RxFuncAdd("CGT_GetLJCmnd", "CigTools", "CGT_GetLJCmnd");

/* Load RXEXIF.DLL */
CALL RXFuncAdd 'rxEXIFLoadFuncs', 'RXEXIF', 'rxEXIFLoadFuncs'
CALL rxEXIFLoadFuncs;
rc = rxEXIFDllVersion();
if(0) then SAY "rxEXIF.DLL version is: " || rc

if 1 then ok = VRRedirectStdIO("OFF"); /* Makes console invisible (sichtbar machen mit <alt><click> auf Exit)  */

INIFile = "PMExif.ini";

CrLf = "0D0A"x;

YGlob.QRecType_Drive  = "V";    /* Drive-Records in xxxxTree-View       */
YGlob.QRecType_Dir    = "D";    /* Dir-Records   in xxxxTree-View       */
YGlob.QRecType_File   = "F";    /* File-Records  in xxxxTree-View       */
YGlob.QRecType_Detail = "T";    /* File-Records  in Detaile-View        */

YGlob.YTag_Selected  = "InUse"; /* kein echter Tag, sondern RecordAttr  */

YGlob.YDefManyFiles = 50;       /* soviele Files in einem Dir verursachen 'Wait'-Message    */

YGlob.YDrivRecs.  = "";     /* Drive-Records, to be set invisible in Query-View     */
YGlob.YDrivRecs.0 = 0;

YGlob.YDetRecs.   = "";     /* Detail-Records, to be removed (instead of CLEAR ALL) */
YGlob.YDetRecs.0  = 0;

/* --------------------------           */
/* Feststellen Landessprache:           */
/* --------------------------           */
rc  = RxQueryCountryInfo( "Countrydata." )
CountryCode = Countrydata.Country_Code;
if CountryCode = 40 ,   /* Schweiz      */
 | CountryCode = 41 ,
 | CountryCode = 43 ,
 | CountryCode = 49
then;do;
   YLang.Ger = 1;YLang.Eng = 0;
end;
else;do;
   YLang.Eng = 1;YLang.Ger = 0;
end;
YLang.Suffx.Eng = "E";
YLang.Suffx.Ger = "D";

if YLang.Eng then   YLang.Suffix = YLang.Suffx.Eng;   /* Suffix fÅr ...                 */
else;               YLang.Suffix = YLang.Suffx.Ger;   /* ... die externen Help-Files    */    


if ( YLang.Ger ) then do
   ImageFS      = "Bild-Pfad";
   Image        = "Bildname";
   Aperture     = "Blende";
   ExpTime      = "Zeit";
   ExpProgram   = "Programm";
   FocalLength  = CrLf|| "Brennweite";
   MtrMod       = "Entfernungs-" ||CrLf|| "Messung";
   Flash        = "Blitz";
   TimeStmp     = "Datum/Uhrzeit";
   Maker        = "Hersteller";
   Model        = "Modell";
   Scene_Type   = "Szenen-Typus";
end;
else;do
   ImageFS      = "Image-Path";
   Image        = "Image-Name";
   Aperture     = "Aperture";
   ExpTime      = "Time";
   ExpProgram   = "Program";
   FocalLength  = "Focal" ||CrLf|| "Length";
   MtrMod       = "Metering" ||CrLf|| "Mode";
   Flash        = "Flash";
   TimeStmp     = "Date/Time";
   Maker        = "Maker";
   Model        = "Model";
   Scene_Type   = "Scene-Type";
end;

New_CN = "CN_1";
HndImgFS  = VRMethod( New_CN, "AddField","String", CrLf|| ImageFS":",      ""  );
HndImgNm  = VRMethod( New_CN, "AddField","String", CrLf|| Image":",        ""  );
HndScene  = VRMethod( New_CN, "AddField","String", CrLf|| Scene_Type":",   ""  );
HndAprt   = VRMethod( New_CN, "AddField","String", CrLf|| Aperture":",     ""  );
HndExpTm  = VRMethod( New_CN, "AddField","String", CrLf|| ExpTime":",      ""  );
HndISO    = VRMethod( New_CN, "AddField","String", CrLf||"ISO:",           ""  );
HndFocLn  = VRMethod( New_CN, "AddField","String", FocalLength":",         ""  );
HndExpPr  = VRMethod( New_CN, "AddField","String", CrLf|| ExpProgram":",   ""  );
HndMtrMod = VRMethod( New_CN, "AddField","String", MtrMod":",              ""  );
HndFlash  = VRMethod( New_CN, "AddField","String", CrLf|| Flash":",        ""  );
HndTimest = VRMethod( New_CN, "AddField","String", CrLf|| TimeStmp":",     ""  );
HndMaker  = VRMethod( New_CN, "AddField","String", CrLf|| Maker":",        ""  );
HndModel  = VRMethod( New_CN, "AddField","String", CrLf|| Model":",        ""  );

ok = VRMethod( New_CN, "SetFieldAttr", HndImgFS, "Visible", 0 );
ok = VRMethod( New_CN, "SetFieldAttr", HndFocLn, "TitleVertJustification", "Bottom" );

/* ------------------------         */
/* Farben wiederherstellen:         */
/* ------------------------         */
Val = SysINI(INIFile, "BackColor", "CN_1");
if Val <> "ERROR:" then ok = VRSet("CN_1",   "BackColor", Val);
Val = SysINI(INIFile, "ForeColor", "CN_1");
if Val <> "ERROR:" then ok = VRSet("CN_1",   "ForeColor", Val);

Val = SysINI(INIFile, "BackColor", "GB_2");
if Val <> "ERROR:" then ok = VRSet("GB_2",   "BackColor", Val);
Val = SysINI(INIFile, "ForeColor", "GB_2");
if Val <> "ERROR:" then ok = VRSet("GB_2",   "ForeColor", Val);

Val = SysINI(INIFile, "BackColor", "GB_3");
if Val <> "ERROR:" then ok = VRSet("GB_3",   "BackColor", Val);
Val = SysINI(INIFile, "ForeColor", "GB_3");
if Val <> "ERROR:" then ok = VRSet("GB_3",   "ForeColor", Val);

Val = SysINI(INIFile, "BackColor", "PB_Exit");
if Val <> "ERROR:" then ok = VRSet("PB_Exit",   "BackColor", Val);
Val = SysINI(INIFile, "ForeColor", "PB_Exit");
if Val <> "ERROR:" then ok = VRSet("PB_Exit",   "ForeColor", Val);

Val = SysINI(INIFile, "BackColor", "PB_SelDir");
if Val <> "ERROR:" then ok = VRSet("PB_SelDir",   "BackColor", Val);
Val = SysINI(INIFile, "ForeColor", "PB_SelDir");
if Val <> "ERROR:" then ok = VRSet("PB_SelDir",   "ForeColor", Val);

/* ---------------------------------------      */
/* Column-Einstellungen wiederherstellen:       */
/* ---------------------------------------      */

ok = SysINI(INIFile, "ColVis", "ALL:", "Cols." );
if Cols.0 > 0 then do
   ok = VRMethod("CN_1", "GetFieldList", "Flds." );
   do i = 1 to Flds.0
      ok = VRMethod("CN_1","SetFieldAttr", Flds.i, "Visible",  ,
                    (SysINI(INIFile, "ColVis", VRMethod("CN_1","GetFieldAttr", Flds.i, "Title"))=1)   ,
                   );
   end;
end;

ValidDrives = "";
Call ZValidDrives;


ok = VRSet("CB_AllDrives", "Set", (SysIni(INIFile, "Settings", "ImgDir") = "ERROR:") );


/* --------------------         */
/* Hilfs-Fenster laden:         */
/* --------------------         */
Call VRLoadSecondary "WIN_Wait";

    window = VRWindow()
    call VRSet window, "UserData", VRGet(window, "Width") VRGet(window, "Height");
    call VRMethod window, "CenterWindow"
    call VRSet window, "Visible", 1
    call VRMethod window, "Activate"
    drop window
return

/* ----------------- */

XSay:
return 0;

ZZMess:
return 0;
/*:VRX         IPB_ArrDn_Click
*/
IPB_ArrDn_Click: 
Call ZSL_Change ,1;
return

/*:VRX         IPB_ArrUp_Click
*/
IPB_ArrUp_Click: 
Call ZSL_Change ,-1;
return

/*:VRX         MM_Display_Click
*/
MM_Display_Click: 

/* HndRec ist gesetzt       */

Call CN_1_DoubleClick_Entry2;

return

/*:VRX         MM_Print_Click
*/
MM_Print_Click: 

YPrint_Object = "CN_1";
Call VRLoadSecondary "WIN_Print";

return;

/*:VRX         MM_RemNoExif_Click
*/
MM_RemNoExif_Click: 


ok = VRSet("CN_1", "Painting", 0);

ok = VRMethod("CN_1", "GetRecordList", "ALL", "Recs.");

do i = 1 to Recs.0
   if words( VRMethod("CN_1", "GetFieldData", Recs.i, HndAPrt ) ) > 1 then
      ok = VRMethod("CN_1", "RemoveRecord", Recs.i );
end;

/* Neue Bild-Zahl anzeigen:                  */
ok = VRMethod("CN_1", "GetRecordList", "ALL", "Recs.");
ok = VRSet("DT_NumImgs", "Caption", Recs.0 );

ok = VRSet("CN_1", "Painting", 1);

return;

/*:VRX         MM_RemSel_Click
*/
MM_RemSel_Click: 

ok = VRSet("CN_1", "Painting", 0);

ok = VRMethod("CN_1", "GetRecordList", "Selected", "Recs.");

do i = 1 to Recs.0
   ok = VRMethod("CN_1", "RemoveRecord", Recs.i );
end;

/* Neue Bild-Zahl anzeigen:                  */
ok = VRMethod("CN_1", "GetRecordList", "ALL", "Recs.");
ok = VRSet("DT_NumImgs", "Caption", Recs.0 );

ok = VRSet("CN_1", "Painting", 1);

return;

/*:VRX         MM_ResetExtImg_Click
*/
MM_ResetExtImg_Click: 

   ok = SysINI(INIFile, "Settings", "ExtImgPgm", "");
   if ok = 1 then
      Call XSay "External Image Editor program now reset";
   else;
      Call XSay "Error resetting External Image Editor program, code="ok;

return

/*:VRX         MM_Sett1_Click
*/
MM_Sett1_Click: 

Call VRLoadSecondary "WIN_Sett", "WAIT";

return

/*:VRX         MM_Sett2_Click
*/
MM_Sett2_Click: 
Call VRLoadSecondary "WIN_Sett", "WAIT";
return

/*:VRX         MM_ThmbView_Click
*/
MM_ThmbView_Click: 

Call VRLoadSecondary "WIN_ThView", "WAIT";

return

/*:VRX         PB_BrowCanc_Click
*/
PB_BrowCanc_Click: 

    Files.0 = 0;
    Call WIN_Browser_Close;
return

/*:VRX         PB_BrowOK_Click
*/
PB_BrowOK_Click: 


Files.0 = 0;
ok = VRMethod("CN_Browser","GetRecordList", YGlob.YTag_Selected, "Sels.");
do i = 1 to Sels.0
   FS = VRMethod("CN_Browser","GetRecordAttr", Sels.i, "FileName");
   
say "FS="FS"!";

   j = Files.0 +1;
   Files.j = FS;
   Files.0 = j;

end;

/* Files.  is set:              */

Call WIN_Browser_Close;
return

/*:VRX         PB_Exit_Click
*/
PB_Exit_Click: 

if VRInfo("AltPressed") = 1 then do
   ok =  VRRedirectStdIO("ON");  /* Show console!     */
   say "Console made visible by explicit request!";
   return;
end;

if VRInfo("ShiftPressed") = 1 then do
   ok =  VRRedirectStdIO("OFF");  /* Make Show console invisibl!     */
   Call Xsay "Console made invisible by explicit request!";
   return;
end;

if VRInfo("CtrlPressed") = 1 then do
   !YSay = 1;  /* make debugging-info visible     */
   Call XSay "debugging-info made visible by explicit request!";
   return;
end;

    Call Quit;
return

/*:VRX         PB_Print_Close_Click
*/
PB_Print_Close_Click: 

    Call WIN_Print_Close;

return

/*:VRX         PB_Print_DoIt_Click
*/
PB_Print_DoIt_Click: 

if VRGet("RB_Print_PCL","Set") &    ,
   VRGet("RB_Print_File","Set")     then do
   ok = VRMessage( VRWindow(), "Please select only one target for printing", "Either Printer or File" );
   RETURN -1;
end;
if \VRGet("RB_Print_PCL","Set") &    ,
   \VRGet("RB_Print_File","Set")     then do
   ok = VRMessage( VRWindow(), "No target for printing selected", "Please select Printer or File" );
   RETURN -1;
end;

if VRGet("RB_Print_PCL","Set") then do

   /* ------------------------             */
   /*  Ausgabe auf Laserjet                */
   /* ------------------------             */
   /*  Drucker initialisieren:             */
   /* ------------------------             */

   Orient   = translate(left(VRGet("SPIN_Print_Orient","Value"),5));
   YPrinter = VRGet("SPIN_Print_Device","Value")||":";

   ok = lineout(YPrinter, CGT_GetLJCmnd("LEFT=04") );
   ok = lineout(YPrinter, CGT_GetLJCmnd( Orient ) );   /* "PORTR | "LANDS"    */

   ok = lineout(YPrinter, CGT_GetLJCmnd("SMALL") );

   /* -----------------------              */
end;
else;do

   /* ------------------------             */
   /*  Ausgabe auf File:                   */
   /* ------------------------             */

   YPrinter = VRGet("EF_Print_Filename","Value");

end;
Align = PB_Print_DoIt_SetAlign(); /* Title-Align    */

Call ZPrint_Container   ,
     YPrint_Object      ,                  /* gesetzt dort, wo VRLoadSecondary("WIN_Print")     */
    ,VRGet("SPIN_Print_NumPages"  ,"Value"),
    ,VRGet("CB_Print_OnlyVisible" ,"Set"  ),
    ,VRGet("EF_MaxColWidth"       ,"Value"),
    ,VRGet("EF_Print_Title"       ,"Value"),
    ,Align;

/* und gleich speichern:                       */
ok = SysINI( INIFile, "Print", "AlignTitle", Align );              
ok = SysINI( INIFile, "Print", "ColWidth", VRGet("EF_MaxColWidth" ,"Value") );

return;
--------------------------

PB_Print_DoIt_SetAlign:
if VRGet("RB_AlignTitle_L" ,"Set") then return "L";
if VRGet("RB_AlignTitle_C" ,"Set") then return "C";
if VRGet("RB_AlignTitle_R" ,"Set") then return "R";

systemfehler 
/*:VRX         PB_SelDir_Click
*/
PB_SelDir_Click: 

/* Directory zum Import aus INI holen:                          */
!ImgDir = SysIni(INIFile, "Settings", "ImgDir");

if !ImgDir = "ERROR:" then !ImgDir = "";

ok = VRLoadSecondary("WIN_Browser","WAIT");

if Files.0 = 0 then do
   ok = VRMessage( VRWindow(), "No image-files selected",, "E" );
   RETURN -1;
end;

ok = SysIni(INIFile, "Settings", "ImgDir", !ImgDir );

if \VRGet("CB_AddToList","Set") then
   ok = VRMethod("CN_1", "RemoveRecord", "ALL" );

ImgDir = filespec("drive",files.1) || filespec("path",files.1);
ok = VRSet("EF_ImgDir", "Value", ImgDir );
ok = VRSet("DT_NumTotal", "Caption", files.0 );
ok = VRSet("GB_3", "Visible", 1 );

/* ---------------------------      */
/* Progressbar initialisieren:      */
/* ---------------------------      */

ProgbarIncr = VRGet("GB_Progress", "Width" ) % files.0;

ok = VRSet("GB_Progress", "Width", 0 );
ok = VRSet("GB_Progress", "Visible", 1 );

/* ---------------------------      */

Rec.1 = VRMethod("CN_1", "AddRecord");
Rec.2 = VRMethod("CN_1", "AddRecord");
Rec.3 = VRMethod("CN_1", "AddRecord");
Rec.0 = 3;
if ( YLang.Ger ) then 
   WaitText = "Einen Moment bitte...";
else;
   WaitText = "Please wait....";
ok    = VRMethod("CN_1", "SetFieldData", Rec.3, HndAprt, WaitText );

ok = VRSet("CN_1", "Painting", 0 );

do i = 1 to Rec.0
   ok = VRMethod("CN_1", "RemoveRecord", Rec.i );
end;

NumImgs = 0;   /* lfd. kumulierte Anzahl       */

do i = 1 to files.0 while \VRGet("CB_Stop","Set")
   Call ZSingleImage files.i;
   NumImgs = NumImgs +1;
   ok = VRSet("DT_NumImgs", "Caption", NumImgs );

   ok = VRSet("GB_Progress", "Painting", 0 );
   ok = VRSet("GB_Progress", "Width", VRGet("GB_Progress", "Width" ) + ProgbarIncr );
   ok = VRSet("GB_Progress", "Painting", 1 );
end;
ok = VRSet("CB_Stop","Set", 0);     /* Reset    */

ok = VRSet("CN_1", "Painting", 1 );
return;

/*:VRX         PB_Sett_Brow1_Click
*/
PB_Sett_Brow1_Click: 

SpUpDir = SysINI(INIFile, "Settings", "SpUpDir");


SpUpDir = VRFileDialog( VRWindow(), "Select a path on a RAM-disk:", "OPEN", "*.*" );

if SpUpDir = "" then
   SpUpDir = "NONE";
else;do
   if \VrIsDir( SpUpDir ) then
      SpUpDir = filespec("drive",SpUpDir) || filespec("path",SpUpDir);
   SpUpDir = strip(SpUpDir,"T","\") || "\";    /* immer terminate with Slash   */
end;

ok = VRSet("EF_Sett_SpUpDir","Value", SpUpDir );

return;

/*:VRX         PB_Sett_Canc_Click
*/
PB_Sett_Canc_Click: 
Call WIN_Sett_Close;
RETURN;
/*:VRX         PB_Sett_Close_Click
*/
PB_Sett_Close_Click: 

ok = SysINI( INIFile, "Settings", "SpUpDir", VRGet("EF_Sett_SpUpDir","Value") );

Call WIN_Sett_Close;
RETURN;
/*:VRX         PB_ShowAll_Click
*/
PB_ShowAll_Click: 

   ok = VRMethod("CN_1", "GetFieldList", "Flds." );
   do i = 1 to Flds.0
      if VRGet("PB_ShowAll", "Caption" ) = "Show all columns" then
         Visib = 1;
      else;
         Visib = (SysINI(INIFile, "ColVis", VRMethod("CN_1","GetFieldAttr", Flds.i, "Title"))=1);
      ok = VRMethod("CN_1","SetFieldAttr", Flds.i, "Visible", Visib );
   end;


if VRGet("PB_ShowAll", "Caption" ) = "Show all columns" then
   ok = VRSet("PB_ShowAll", "Caption", "Reset to previous setting" );
else;
   ok = VRSet("PB_ShowAll", "Caption", "Show all columns" );

return

/*:VRX         PB_Thview_Close_Click
*/
PB_Thview_Close_Click: 
Call WIN_ThView_Close;
RETURN;
/*:VRX         Quit
*/
Quit:

/* ---------------------------------------      */
/* Farb- und andere Einstellungen sichern:      */
/* ---------------------------------------      */

ok = SysINI(INIFile, "ForeColor", "CN_1",      VRGet("CN_1", "ForeColor") );
ok = SysINI(INIFile, "BackColor", "CN_1",      VRGet("CN_1", "BackColor") );
ok = SysINI(INIFile, "ForeColor", "GB_2",      VRGet("GB_2", "ForeColor") );
ok = SysINI(INIFile, "BackColor", "GB_2",      VRGet("GB_2", "BackColor") );
ok = SysINI(INIFile, "ForeColor", "GB_3",      VRGet("GB_3", "ForeColor") );
ok = SysINI(INIFile, "BackColor", "GB_3",      VRGet("GB_3", "BackColor") );

ok = SysINI(INIFile, "ForeColor", "PB_Exit",   VRGet("PB_Exit", "ForeColor") );
ok = SysINI(INIFile, "BackColor", "PB_Exit",   VRGet("PB_Exit", "BackColor") );

ok = SysINI(INIFile, "ForeColor", "PB_SelDir", VRGet("PB_SelDir", "ForeColor") );
ok = SysINI(INIFile, "BackColor", "PB_SelDir", VRGet("PB_SelDir", "BackColor") );

/* ---------------------------------------      */
/* Column-Einstellungen sichern:                */
/* ---------------------------------------      */

ok = VRMethod("CN_1", "GetFieldList", "Flds." );
do i = 1 to Flds.0
   ok = SysINI(INIFile, "ColVis", VRMethod("CN_1","GetFieldAttr", Flds.i, "Title"),  (VRMethod("CN_1","GetFieldAttr", Flds.i, "Visible")=1) );
end;

    window = VRWindow()
    call VRSet window, "Shutdown", 1
    drop window
return

/*:VRX         WIN_Browser_Close
*/
WIN_Browser_Close: 

/* --------------------------       */
/* INI-Werte sichern:               */
/* --------------------------       */
ok = SysINI( INIFile, "Settings", "FileTypes", VRGet("EF_FileTypes", "Value") );

call VRDestroy "WIN_Browser";

return

/*:VRX         WIN_Browser_Create
*/
WIN_Browser_Create: 


/* --------------------------                       */
/* Container 'Browser' bauen:                       */
/* --------------------------                       */

hndBrsFN   = VRMethod("CN_Browser", "AddField", "string", "Image-Name:" );
hndBrsFS   = VRMethod("CN_Browser", "AddField", "string", "FilePath:" ); /* im Search-Mode: nur Path        */
hndBrsType = VRMethod("CN_Browser", "AddField", "string", "Type"   );   /* dri"V"e | "D"irectory | "F"ile   */
hndBrsDate = VRMethod("CN_Browser", "AddField", "string", "Date:"  );
hndBrsStat = VRMethod("CN_Browser", "AddField", "string", "Status" );   /* "1": schon expanded              */
hndBrsSeq  = VRMethod("CN_Browser", "AddField", "string", "SeqNo:" );
hndBrsNxt  = VRMethod("CN_Browser", "AddField", "string", "Next Img" );


FTs = SysINI( INIFile, "Settings", "FileTypes" );
if FTs = "ERROR:" then  FTs = "JPG TIF BMP GIF";
ok = VRSet("EF_FileTypes", "Value", FTs);


if !ImgDir <> "" then do
   /* zuletztes Dir wieder einloggen (als erstes):           */

   ExpandImmed = 1;

   !ImgDir = strip(!ImgDir,"T","\");

   DriveRec = ZIns_DriveRecord( filespec("drive",!ImgDir) );
   ok = VRMethod("CN_Browser", "SetFieldData",   DriveRec, hndBrsStat, 1 );
 
   Parent = DriveRec;
   Rec = ZIns_DirRecord( Parent, !ImgDir );
   Call CN_Browser_DoubleClick_2; 

   if (ExpandImmed) then
     ok = VRMethod("CN_Browser", "SetRecordAttr",  DriveRec, "Expanded", 1 );

end;

/* danach alle Laufwerke nochmal:       */

if VRGet("CB_AllDrives","Set") then
   Call ZFill_Browser "Drives",, "KEEP";

   
call WIN_Browser_Init;
return 0;

/*:VRX         WIN_Browser_Init
*/
WIN_Browser_Init: 
    window = VRInfo( "Object" )
    if( \VRIsChildOf( window, "Notebook" ) ) then do
        call VRMethod window, "CenterWindow"
        call VRSet window, "Visible", 1
        call VRMethod window, "Activate"
    end
    drop window
return

/*:VRX         WIN_Print_Close
*/
WIN_Print_Close: 
    call WIN_Print_Fini
return

/*:VRX         WIN_Print_Create
*/
WIN_Print_Create: 
    call WIN_Print_Init
return

/*:VRX         WIN_Print_Fini
*/
WIN_Print_Fini: 
    window = VRInfo( "Window" )
    call VRDestroy window
    drop window
return
/*:VRX         WIN_Print_Init
*/
WIN_Print_Init: 
    window = VRInfo( "Object" )
    if( \VRIsChildOf( window, "Notebook" ) ) then do
        call VRMethod window, "CenterWindow"
        call VRSet window, "Visible", 1
        call VRMethod window, "Activate"
    end
    drop window
return

/*:VRX         WIN_Sett_Close
*/
WIN_Sett_Close: 
    window = VRInfo( "Window" )
    call VRDestroy window
    drop window
return

/*:VRX         WIN_Sett_Create
*/
WIN_Sett_Create: 


/* ------------------------     */
/* alte INI-Werte anzeigen:     */
/* ------------------------     */
SpUpDir = SysINI(INIFile, "Settings", "SpUpDir");

if SpUpDir = "ERROR:" then SpUpDir = "NONE";    /* default: er will kein SpeedUp-Dir        */

ok = VRSet("EF_Sett_SpUpDir", "Value", SpUpDir );



    call WIN_Sett_Init
return

/*:VRX         WIN_Sett_Init
*/
WIN_Sett_Init: 
    window = VRInfo( "Object" )
    if( \VRIsChildOf( window, "Notebook" ) ) then do
        call VRMethod window, "CenterWindow"
        call VRSet window, "Visible", 1
        call VRMethod window, "Activate"
    end
    drop window
return

/*:VRX         WIN_ThView_Close
*/
WIN_ThView_Close: 
    window = VRInfo( "Window" )
    call VRDestroy window
    drop window
return

/*:VRX         WIN_ThView_Create
*/
WIN_ThView_Create: 

/* -------------------------------------    */
/* Prelude (eigentlich in MM_ThmbView):     */
/* -------------------------------------    */

/* Parameter:                               */

ThmbDir = SysIni( INIFile, "Settings", "SpUpDir" );
if ThmbDir = "ERROR:"           ,
 | translate(ThmbDir) = "NONE"  then do
   ThmbDir = directory() || "\_temp";
   ok = VRMkDir( ThmbDir );
   ThmbDir = ThmbDir || "\";
end;

ImgsPerWin  = 6;
Target_X    = 150;    /* Width in Pixels    */

Bild_Height = ( VRGet("GB_Thmb", "Height") -10 ) % ImgsPerWin;  /* != Konstant! */

Target_Y    = VRMethod("Screen", "TwipsToPixels", Bild_Height );
Bild_Width  = Target_X * VRMethod("Screen", "PixelsToTwips",1);  /* dies ist nur die Ñussere Begrenzung! */

Marg_Top = 40;   /* Twips                   */

/* -------------------------------------    */

ok = VRMethod("CN_1", "GetRecordList", "ALL", "Recs." );

!Imgs.0 = 0;          /* öbergabe-Variable          */

do i = 1 to Recs.0

   ImgFS = VRMethod("CN_1", "GetFieldData", Recs.i, HndImgFS );

   /* -----------------------------------------     */
   /* Dimens des zu erstellenden BMP ermitteln:     */
   /* -----------------------------------------     */
   ImgDim = ZGet_ImgSize( ImgFS );
   X_Size = word(ImgDim,1);
   Y_Size = word(ImgDim,2);

   Aux = ZResize_Dimens( X_Size, Y_Size, Target_X, Target_Y, "P" );
   New_X = word(Aux,1);
   New_Y = word(Aux,2);

   /* ---------------------         */
   /* Umwandeln nach *.bmp:         */
   /* ---------------------         */
   ImgName = filespec("name", ImgFS );
   Posi = LastPos(".", ImgName);
   ImgName = left(ImgName,Posi-1);

   ThmbFS = ThmbDir || ImgName || ".bmp";

   Cmd = "gbmsize -w "New_X "-h "Target_Y '"'ImgFS'"' '"' || ThmbFS || '"';
say "cmd="cmd;
   Cmd;

   !Imgs.i = ThmbFS
   !Imgs.i.!Hnd = Recs.i;
end;
!Imgs.0 = Recs.0;


/* !Imgs. is set!      */

ok = VRSet("EF_Limit", "Value", !Imgs.0 );

BackColor = "(255,241,221)";
/* --------------------------------  */
/* Create Pegel-Marker in GrpBox:    */
/* --------------------------------  */
!PgMk = VRCreate("GB_Pegel","PictureBox",    ,
        "Name", "PegMark",                   ,
        "Top", 10, "Left", 10,               ,
        "Width", VRGet("GB_Pegel","Width"),  , 
        "Height", 0,                         ,  /* initial Height       */
        "AllowDrag", 1,                      ,
        "BackColor", BackColor );

ok = VRSet( !PgMk, "Border", 0 );

/* --------------------------------  */

Gpbx_Width  = VRGet("GB_Thmb", "Width");
GpArr_Width = VRGet("GB_Slider", "Width");

Marg_Vert   = 4 * VRMethod("Screen", "PixelsToTwips",1);

Top = Marg_Top;     /* Initiales Top        */

NumImgs = VRGet("EF_Limit", "Value" );

ok = VRSet("EF_TopImgNo", "Value", 1);  /* Initialize PegelMark-Verwaltung  */

do i = 1 to !Imgs.0 until i >= VRGet("EF_Limit", "Value" );

   /* ----------------------------------   */
   /* PegelMarker: Hîhe gleitend setzen:   */
   /* ----------------------------------   */
   ok = VRSet( !PgMk, "Height", ( (ImgsPerWin-1) / Min(i, (NumImgs) ) ) * VRGet("GB_Pegel","Height") %1 );


   Bild = !Imgs.i;
   /* --------------------------------  */
   /* Create GROUP-BOX in GROUP-BOX:    */
   /* --------------------------------  */
   GB = VRCreate("GB_Thmb","Groupbox",  ,
        "Name", "GRPBOX_"i,             ,
        "BorderType", "None",           , 
        "Width",Gpbx_Width-96, "Height",Bild_Height-Marg_Vert, ,
        "Top", Top,                     , 
        "Left", 40);

   /* --------------------------------  */
   /* Create PICTURE-BOX in GROUP-BOX:  */
   /* --------------------------------  */
   PB = VRCreate( GB,"Picturebox",      ,
        "PicturePath", Bild,            ,
        "Name", "PICBOX_"i,             ,
        "Click", "Call Thmb_Click "i,   ,
        "Width",VRMethod("Screen", "PixelsToTwips",New_X), "Height",Bild_Height-Marg_Vert, ,
        "Top", 0, "Left", 0);

   /* ------------------------------------  */
   /* Create DescriptiveText in GROUP-BOX:  */
   /* ------------------------------------  */
   DT = VRCreate( GB,"DescriptiveText",   ,
        "Name", "DscTxt_"i,               ,
        "Caption", ZBuild_Caption( i ),   ,
        "Font", "8.Courier",              ,
        "Height", 222, "Width",Gpbx_Width - Bild_Width - GpArr_Width,           ,
        "Top", (Bild_Height % 2)-46, "Left", Bild_Width+36 );

   Top = Top + Bild_Height;

end;
/* Pegelmarker-Increment: Schon mal errechnen und hier merken:      */
if VRGet("EF_Limit", "Value") - ImgsPerWin > 0 then
   !PgMk_Incr = (( VRGet("GB_Pegel","Height") - VRGet( !PgMk, "height" ) )     ,
               / ( VRGet("EF_Limit", "Value") - ImgsPerWin ) ) %1;
else;do
   /* weniger Bilder als raufpassen: kein Bedarf fÅr Slider:        */
   !PgMk_Incr = 0;
   ok = VRSet("GB_Pegel", "Visible", 0 );
   ok = VRSet("GB_Slider","Visible", 0 );
end;

   call WIN_ThView_Init;
return

------------------------------
Thmb_Click: Procedure Expose !Imgs. INIFile HndImgFS;
ImgNo = arg(1);

ImgFS = VRMethod("CN_1", "GetFieldData", !Imgs.ImgNo.!Hnd, HndImgFS );

Call CN_1_DoubleClick_Entry3;

return;
------------------------------
ZBuild_Caption: /* Procedure Expose !Imgs. HndISO HndAprt HndExpTm HndFocLn;   */
ImgNo = arg(1);

Rec = !Imgs.ImgNo.!Hnd;

say "Rec="Rec"!";

ISO = strip( VRMethod("CN_1", "GetFieldData", Rec, HndISO   ));
Apt = strip( VRMethod("CN_1", "GetFieldData", Rec, HndAprt  ));
Shu = strip( VRMethod("CN_1", "GetFieldData", Rec, HndExpTm ));
Foc = strip( VRMethod("CN_1", "GetFieldData", Rec, HndFocLn ));

Caption = left(ISO,6) || left(Apt,7) || left(Shu,9) || left(Foc,9) || "<";
return Caption;
/*:VRX         WIN_ThView_Init
*/
WIN_ThView_Init: 
    window = VRInfo( "Object" )
    if( \VRIsChildOf( window, "Notebook" ) ) then do
        call VRMethod window, "CenterWindow"
        call VRSet window, "Visible", 1
        call VRMethod window, "Activate"
    end
    drop window
return

/*:VRX         WIN_Wait_Close
*/
WIN_Wait_Close: 
    call VRDestroy "WIN_Wait";
return

/*:VRX         WIN_Wait_Create
*/
WIN_Wait_Create: 
    call WIN_Wait_Init
return

/*:VRX         WIN_Wait_Init
*/
WIN_Wait_Init: 
        call VRMethod WIN_Wait, "CenterWindow"
        call VRMethod WIN_Wait, "Activate"
return

/*:VRX         Window1_Close
*/
Window1_Close:
    call Quit
return

/*:VRX         Window1_ContextMenu
*/
Window1_ContextMenu: 

ok = VRMethod("MM_Misc", "Popup" );

return

/*:VRX         Window1_Resize
*/
Window1_Resize: 
ok = VRSet("Window1", "Painting", 0 );


OldWidth  = word( VRGet("Window1", "UserData"), 1 );
OldHeight = word( VRGet("Window1", "UserData"), 2 );

NewWidth  = VRGet("Window1", "Width");
NewHeight = VRGet("Window1", "Height");

DiffWidth  = NewWidth  - OldWidth;
DiffHeight = NewHeight - OldHeight;

/* --------------------------       */
/* Resizen abhÑngige Objekte:       */
/* --------------------------       */
ok = VRSet("GB_1", "Width",  VRGet("GB_1", "Width")  + DiffWidth );
ok = VRSet("GB_1", "Height", VRGet("GB_1", "Height") + DiffHeight );

ok = VRSet("CN_1", "Width",  VRGet("CN_1", "Width")  + DiffWidth );
ok = VRSet("CN_1", "Height", VRGet("CN_1", "Height") + DiffHeight );

ok = VRSet("GB_3",        "Width",  VRGet("GB_3",        "Width")  + DiffWidth );
ok = VRSet("GB_Progress", "Width",  VRGet("GB_Progress", "Width")  + DiffWidth );

/* ------------------------------   */
/* Verschieben abhÑngige Objekte:   */
/* ------------------------------   */
ok = VRSet("GB_Unten", "Width",  VRGet("GB_Unten", "Width")  + DiffWidth );
ok = VRSet("GB_Unten", "Top",    VRGet("GB_Unten", "Top")    + DiffHeight );

ok = VRSet("PB_Exit",  "Left",   VRGet("PB_Exit",  "Left")   + DiffWidth );

/* Merken neue Windows-Dimens:      */
ok = VRSet("Window1", "UserData", NewWidth NewHeight );

ok = VRSet("Window1", "Painting", 1 );
return;

/*:VRX         ZCre_Menu
*/
ZCre_Menu: 

if VRIsValidObject( DynMenuName ) then RETURN 0;    /* verhindere Mehrfach-Erzeugung        */

MenHnd = VRCreate("MM_SortCols", "MENU",    ,
                 "Caption", "Set Columns",  ,
                 "Visible",1,               ,
                 "Name", DynMenuName        ,
                 );

MenuParent = MenHnd;

ok = VRMethod("CN_1", "GetFieldList", "Flds." );

do i = 1 to Flds.0

   ColName = VRMethod("CN_1", "GetFieldAttr", Flds.i, "Title" );
   ColName = space( translate(ColName,"","0D0A"x), 0);
   if strip(ColName) <> "" then do
      MenHnd = VRCreate( MenuParent, "MENU",   ,
                        "Caption", ColName,    ,
                        "Click", "NOP;"        ,
                       );


      MIt1Hnd = VRCreate( MenHnd, "MENUITEM",   ,
                         "Caption", "Sort",     ,
                         "UserData", Flds.i,    ,
                         "Click", "Call ZCre_Menu_Click 'SORT';"  ,
                        );

      MIt2Hnd = VRCreate( MenHnd, "MENUITEM",   ,
                         "Caption", "Show",     ,
                         "UserData", Flds.i,    ,
                         "Click", "Call ZCre_Menu_Click 'SHOW';"  ,
                        );

      MIt3Hnd = VRCreate( MenHnd, "MENUITEM",   ,
                         "Caption", "Hide",     ,
                         "UserData", Flds.i,    ,
                         "Click", "Call ZCre_Menu_Click 'HIDE';"  ,
                        );
   end;
end;

return;
----------------------
ZCre_Menu_Click: Procedure
What   = arg(1);    /* [ "D(isplay)" | "H(ide)" | "S(ort)" ]        */

FldHnd  = VRGet( VRInfo("Object"), "Userdata" );
Visible = ( Left( What,1 ) = "S" );  /* true bei 'SORT' und 'SHOW'  */
Sort    = ( Left( What,2 ) = "SO" );
ok = VRMethod("CN_1", "SetFieldAttr", FldHnd, "Visible", Visible );

if (Sort) then do
   ok = VRSet("CN_1", "DetailSort", FldHnd);
   ok = VRMethod("CN_1", "SortRecords" );
end;
return 0;

/*:VRX         ZFill_Browser
*/
ZFill_Browser: Procedure Expose                 ,
                         ImgDBName. Rexxbase.   ,
                         YGlob. INIFile         ,
                         ValidDrives            ,
                         hndBrsID hndBrsFS hndBrsType hndBrsStat hndBrsSeq hndBrsNxt;


What = arg(1);      /* [ "Drives" | "DIR" | "DOMAINS" ]        */
Rec  = arg(2);      /* Dir-Record                              */
Keep = ( arg(3)="KEEP" );      /* Container nicht lîschen      */

if translate(What) = "DRIVES"  ,
 | translate(What) = "DOMAINS" then do
   /* Prepare for Root-Level-Things:                           */

   ok = ZSet_Wait( "On" );      /* "Bitte warten ... "         */

   ok = VRSet("CN_Browser", "Painting", 0 );
   if \(Keep) then
      ok = ZRemove_All( "DRIVES" ); /* alten Schrott entfernen */
end;

if What = "Drives" then do

   do i = 1 to words( ValidDrives )
      CurDrive =  word( ValidDrives, i );
      hndRec = ZIns_DriveRecord(CurDrive);

      /* Gleich die Dirs 1. Ebene mit auflîsen:              */

      ok = SysFileTree( CurDrive"\", "dirs.", "D");
      Parent = HndRec;
      do j = 1 to dirs.0
         DirName = Subword(dirs.j,5);
         ok = ZIns_DirRecord( Parent, DirName );
      end;

   end;
end;

if What = "DIR" then do
   Dir  = VRMethod("CN_Browser", "GetRecordAttr",  Rec, "FileName" );
   Stat = VRMethod("CN_Browser", "GetFieldData",   Rec, hndBrsStat );

   if Stat = "1" then RETURN -2;   /* schon resolved       */

   Parent = Rec;

   ok = VRSet("CN_Browser", "Painting", 0 );

   /* --------------------------------   */
   /* 1.: Directories im Dir auflîsen:   */
   /* --------------------------------   */
   ok = SysFileTree( strip(Dir,"T","\")||"\*", "dirs.", "D");
   do j = 1 to dirs.0
      hndRec = VRMethod("CN_Browser", "AddRecord", Parent, "LAST" );
      DirName = Subword(dirs.j,5);
      ok = VRMethod("CN_Browser", "SetRecordAttr", hndRec, "Filename", DirName );
      ok = VRMethod("CN_Browser", "SetRecordAttr", hndRec, "Caption",  filespec("name",DirName) );

      ok = VRMethod("CN_Browser", "SetFieldData",  hndRec, hndBrsType, YGlob.QRecType_Dir );   /* Type = Dir    */
      ok = VRMethod("CN_Browser", "SetFieldData",  hndRec, hndBrsStat, "0" );
      ok = VRMethod("CN_Browser", "SetFieldData",  hndRec, hndBrsSeq, j    );
      ok = VRMethod("CN_Browser", "SetRecordAttr", hndRec, "Visible",   1  );
   end;

   /* --------------------------------   */
   /* 2.: Files im Dir auflîsen:         */
   /* --------------------------------   */

   ok = ZIns_FileRecord( Parent, Dir );  /* alle records        */

   ok = VRSet("CN_Browser", "Painting", 1 );
   RETURN 0;
end;

if translate(What) = "DOMAINS" then do
    
   /* PrÑmisse: Combo_ImgDoms ist gefÅllt + sortiert!           */

   do i = 1 to VRGet("Combo_ImgDoms", "Count")
      ImgDom = VRMethod("Combo_ImgDoms", "GetString", i);

      CurDrive =  filespec( "drive", ImgDom );
      hndRec = ZIns_DriveRecord(CurDrive);

      CurPath = CurDrive || filespec( "Path", ImgDom );

      /* Gleich die Dirs 1. Ebene mit auflîsen:                 */

      Parent = hndRec;
      DirName = strip(CurPath,"T","\");

      if CurDrive = DirName then
         Parent = hndRec;       /* Sonderfall: die ganze Platte ist als Domain bestimmt    */
      else;
         Parent = ZIns_DirRecord( Parent, DirName );

      ok = SysFileTree( CurPath"*", "dirs.", "D");
      do j = 1 to dirs.0
         DirName = Subword(dirs.j,5);
         ok = ZIns_DirRecord( Parent, DirName );
      end;


      /* -------------------------------------------            */
      /* und gleich die Files 1. Ebene mit auflîsen:            */
      /* -------------------------------------------            */
      ok = ZIns_FileRecord( Parent, strip(CurPath,"T","\") );

      /* nun Drive-Ebene expanden:                              */
      ok = VRMethod("CN_Browser", "SetRecordAttr", hndRec, "Expanded", "1" );

   end;
end;

if translate(What) = "DRIVES"  ,
 | translate(What) = "DOMAINS" then do

   /* Finish Root-Level-Things:                                 */

   ok = VRSet("CN_Browser", "Painting", 1 );
   Call ZSet_Wait "Off";
   RETURN 0;
end;

return 0;

/* ------------------   */
ZFill_Browser_CheckFT: Procedure Expose INIFile;
FS = arg(1);

Posi = LastPos(".",FS);
if Posi = 0 then RETURN 0;  

FT = right(FS, length(FS) - Posi);

FileTypes = VRGet("EF_FileTypes","Value");
do i = 1 to words( FileTypes )
   CurFT = strip( word(FileTypes,i),"T","?" );
   if translate(CurFT) = translate(left(FT, length(CurFT))) then
      return 1;   /* ja, dieser Filetype ist gewÅnscht    */
end;
return 0;   /* nein, dieser Filetype ist nicht in der Wortliste enthalten    */

/*:VRX         ZGet_ImgSize
*/
ZGet_ImgSize: procedure

FileSpec = arg(1);  /* must be .BMP (?no!)      */

Default_X = 222;
Default_Y = 190;

say "ZGet_ImgSize: FileSpec="FileSpec"!";

if \VRFileExists(FileSpec) then RETURN Default_X Default_Y; /* return standard image-dimensions */

Posi = Lastpos( ".", FileSpec );
Ext = translate(right(FileSpec, length(FileSpec) - Posi));

if Ext = "BMP" then do
   X_x = Charin(FileSpec, 17, 4);
   Y_x = Charin(FileSpec, 21, 4);
   ok=stream(FileSpec,"c","close");

   X_d = c2x(X_x);
   Y_d = c2x(Y_x);

   /* richtig rum drehen: */

   XSize = x2d( substr(X_d,7,2)||substr(X_d,5,2) );
   YSize = x2d( substr(Y_d,7,2)||substr(Y_d,5,2) );

   RETURN XSize YSize;
end;
else;do
   ImgDim = X_GetImgSize( FileSpec, directory() ); /* ++ Version fÅr non-BMPs ++ */
   X_x = word(ImgDim,1);
   Y_x = word(ImgDim,2);

   if translate( X_x ) = "ERROR" then do
      ok = beep(211,444);
      Call XSay "Image '"FileSpec"' cannot be displayed, probably file not found";
      RETURN Default_X Default_Y; /* return standard image-dimensions */
   end;
   RETURN X_x Y_x;
end;

RETURN "?";

/*:VRX         ZGetExif
*/
ZGetExif: Procedure Expose      ,
                    HndAprt     ,
                    HndExpTm    ,
                    HndISO      ,
                    HndExpPr    ,
                    HndFocLn    ,
                    HndMtrMod   ,
                    HndFlash    ,
                    HndTimest   ,
                    HndMaker    ,
                    HndModel;

InFile = arg(1);
Rec    = arg(2);

Imgfile = InFile;

exifdat.0 = 0
rc = rxEXIFRead(Imgfile, 'exifdat')

i=1;
Meanings.i = "010F Maker";		i=i+1;
Meanings.i = "0110 Model";		i=i+1;
Meanings.i = "0112 Orientation";	i=i+1;
Meanings.i = "011A Res.X";		i=i+1;
Meanings.i = "011B Res.Y";		i=i+1;
Meanings.i = "0128 unit";		i=i+1;
Meanings.i = "0132 timestamp";		i=i+1;
Meanings.i = "0213 Alignment";		i=i+1;
Meanings.i = "829A ExposureTime";	i=i+1;
Meanings.i = "829D Blende";		i=i+1;	/* 'F-Number'	*/
Meanings.i = "8822 ExposureProgram";	i=i+1;
Meanings.i = "8827 ISO";	       i=i+1;
Meanings.i = "9000 ExifVersion";	i=i+1;
Meanings.i = "9003 DateTimeOrig";	i=i+1;
Meanings.i = "9004 DateTimeDigitized";	i=i+1;
Meanings.i = "9101 ComponentsConfig";	i=i+1;
Meanings.i = "9204 0/6";		i=i+1;
Meanings.i = "9205 MaxApertureValue";	i=i+1;
Meanings.i = "9207 MeteringMode";	i=i+1;
Meanings.i = "9209 Flash";		i=i+1;  /* 'Flash fired,...' | 'Flash did not fire, ...'    */
Meanings.i = "920A FocalLength";	i=i+1;
Meanings.i = "9286 ASCII";		i=i+1;
Meanings.i = "A000 0100";		i=i+1;
Meanings.i = "A001 ColorSpace";	i=i+1;
Meanings.i = "A002 PixelX";		i=i+1;
Meanings.i = "A003 PixelY";		i=i+1;
Meanings.i = "A300 FilenameStub";	i=i+1;
Meanings.i = "A301 SceneType";	i=i+1;

Meanings.i = "A20E FocalPlaneXResolution";      i=i+1;
Meanings.i = "A20F FocalPlaneYResolution";      i=i+1;
Meanings.i = "A210 FocalPlaneResolutionUnit";   i=i+1;

Meanings.0 = i-1;

/* nur die wichtigsten:	*/
i=1;
Shorts.i = "010F Maker" HndMaker;		 i=i+1;
Shorts.i = "0110 Model" HndModel;		 i=i+1;
Shorts.i = "829A ExposureTime" HndExpTm;	 i=i+1;
Shorts.i = "829D Blende" HndAprt;		 i=i+1;	/* 'F-Number'	*/
Shorts.i = "8822 ExposureProgram" HndExpPr; i=i+1;
Shorts.i = "8827 ISO"   HndISO;		 i=i+1;
Shorts.i = "9003 DateTimeOrig" HndTimest;	 i=i+1;
Shorts.i = "9207 MeteringMode" HndMtrMod;   i=i+1;
Shorts.i = "9209 Flash" HndFlash;		 i=i+1;
Shorts.i = "920A FocalLength" HndFocLn;	 i=i+1;
Shorts.i = "A301 SceneType" HndScene;	 i=i+1;

Shorts.0 = i-1;

if exifdat.0 = 0 then do
   RETURN 0;
end;

BackGround = VRGet("CB_BackGround","Set");

DO i = 1 TO exifdat.0
  Meaning = word( GetMeaning( word(exifdat.i,1) ), 1);
  Hndl    = word( GetMeaning( word(exifdat.i,1) ), 2);
  if \(Meaning = "<unknown>") then do
     ID   = word(exifdat.i,1);
     What = Subword(exifdat.i,2, words(exifdat.i)-1 );

     if(BackGround) then ok = SysSleep( 0.05 );

     /* ausrechnen Blende, Brennweite:	*/
     if Meaning = "Blende"	,
      |	Meaning = "FocalLength"	then do
        Z = "What="What;	interpret z;	
     end;

     ok  = VRMethod("CN_1", "SetFieldData", Rec, Hndl, What );

     if(0) then say left(Meaning,26," ") "=" What;
  end;
END

RETURN 1;

/* -----------------------------------	*/

GetMeaning: Procedure Expose Shorts.;
ID = arg(1);

What = "<unknown>";

do i = 1 to Shorts.0
   if ID = word(Shorts.i,1) then do
      What = Subword(Shorts.i,2, words(Shorts.i)-2);
      Hndl = word(Shorts.i, words(Shorts.i));
      LEAVE;
   end;
end;
return What Hndl;

/*:VRX         ZIns_xxxRecord
*/
ZIns_xxxRecord: 
nop;
return;

/* -------------------------------------------- */
/* -------------------------------------------- */

ZIns_DriveRecord: Procedure Expose INIFile YGlob.   ,
                                   hndBrsFS hndBrsType hndBrsStat hndBrsSeq hndBrsNxt;

CurDrive = arg(1);

CurDrive = strip(CurDrive,"T","\") || "\";

Parent = "";
hndRec = VRMethod("CN_Browser", "AddRecord", Parent, "LAST" );
ok = VRMethod("CN_Browser", "SetRecordAttr", hndRec, "Filename", CurDrive );
ok = VRMethod("CN_Browser", "SetRecordAttr", hndRec, "Caption",  "Drive "strip(CurDrive,"T","\") );
ok = VRMethod("CN_Browser", "SetRecordAttr", hndRec, "Icon",     "Drive.ico" );

ok = VRMethod("CN_Browser", "SetFieldData",  hndRec, hndBrsType, YGlob.QRecType_Drive );   /* Type = DriVe */
ok = VRMethod("CN_Browser", "SetFieldData",  hndRec, hndBrsStat, "0" );
ok = VRMethod("CN_Browser", "SetRecordAttr", hndRec, "Visible",   1  );

i = YGlob.YDrivRecs.0 +1;
YGlob.YDrivRecs.i = hndRec;   /* merken fÅr ausblenden    */
YGlob.YDrivRecs.0 = i;

say "YGlob.YDrivRecs."i"="YGlob.YDrivRecs.i"!";

return hndRec;

/* -------------------------------------------- */
/* -------------------------------------------- */

ZIns_DirRecord: Procedure Expose YGlob.   ,
                hndBrsType hndBrsStat;
Parent  = arg(1);
DirName = arg(2);   /* endet ohne '\'           */

hndRec = VRMethod("CN_Browser", "AddRecord", Parent, "LAST" );
ok = VRMethod("CN_Browser", "SetRecordAttr", hndRec, "Filename", DirName );
ok = VRMethod("CN_Browser", "SetRecordAttr", hndRec, "Caption",  filespec("name",DirName) );

ok = VRMethod("CN_Browser", "SetFieldData",  hndRec, hndBrsType, YGlob.QRecType_Dir );   /* Type = Dir    */
ok = VRMethod("CN_Browser", "SetFieldData",  hndRec, hndBrsStat, "0" );
ok = VRMethod("CN_Browser", "SetRecordAttr", hndRec, "Visible",   1  );

return hndRec;

/* -------------------------------------------- */
/* -------------------------------------------- */

ZIns_FileRecord: Procedure Expose       ,
                 ImgDBName. Rexxbase.   ,
                 INIFile YGlob.         ,
                 hndBrsID hndBrsFS hndBrsFN hndBrsType hndBrsStat hndBrsSeq hndBrsNxt;

Parent  = arg(1);
Dir     = arg(2);   /* endet ohne '\'           */

/* FÅllt ALLE Files in dem Directory ein:       */
/*       ^^^^                                   */

   ok = SysFileTree( Dir"\*", "files.", "F");

   if files.0 > YGlob.YDefManyFiles then
      ok = ZSet_Wait( "On" );            /* "Bitte warten ... "              */

   if VRMethod("CN_Browser", "ValidateRecord", Parent) then do
      /* Anzahl Files im Dir-Record anzeigen:      */
      OldCap = VRMethod("CN_Browser", "GetRecordAttr",  Parent, "Caption" );
      ok = VRMethod("CN_Browser", "SetRecordAttr",  Parent, "Caption", OldCap "("files.0")"  );
   end;

   do j = 1 to files.0
      FS = Subword(files.j,5);

      if \ZFill_Browser_CheckFT( FS ) then ITERATE;

      hndRec = VRMethod("CN_Browser", "AddRecord", Parent, "LAST" );
      ok = VRMethod("CN_Browser", "SetRecordAttr", hndRec, "Filename",  FS );
      ok = VRMethod("CN_Browser", "SetRecordAttr", hndRec, "Caption",  filespec("Name", FS ) );

      ok = VRMethod("CN_Browser", "SetFieldData",  hndRec, hndBrsType, YGlob.QRecType_File );   /* Type = File   */
      ok = VRMethod("CN_Browser", "SetFieldData",  hndRec, hndBrsStat, "0"  );
      ok = VRMethod("CN_Browser", "SetFieldData",  hndRec, hndBrsSeq,   j   );
      ok = VRMethod("CN_Browser", "SetFieldData",  hndRec, hndBrsNxt, "EOR" );  /* vorlÑufig (EOR = EndOfRecords)  */
      ok = VRMethod("CN_Browser", "SetRecordAttr", hndRec, "Visible",   1   );

      /* aktuellen Record als 'Next' im VorgÑnger verankern:        */
      Prev = VRMethod("CN_Browser", "GetRecordAttr", hndRec, "Previous" );
      if translate(Prev) <> "FIRST" then do
         ok = VRMethod("CN_Browser", "SetFieldData", Prev, hndBrsNxt, hndRec );
      end;

/* +++
      if (ImgScho) then do
         Call ZSet_RecordTag hndRec, "F", "On";  /* dann File taggen ('FileExist'):    */

         ok = VRMethod("CN_Browser", "SetFieldData", hndRec, hndBrsID, strip(ImgDBName.ImgID) );
      end;
+++ */

   end;

   if VRMethod("CN_Browser", "ValidateRecord", Parent) then do
      /* nun expanden:              */
      ok = VRMethod("CN_Browser", "SetRecordAttr", Parent, "Expanded", "1" );
      ok = VRMethod("CN_Browser", "SetFieldData",  Parent, hndBrsStat, "1" );   /* Markiere 'schon resolved'    */
   end;

return 0;


/*:VRX         ZPrint_Container
*/
ZPrint_Container: procedure Expose  YGlob. ,
                                    YPrinter ,  /* zeigt auf Datei oder LPT1   */
                                    Orient;
CN_Objct          = arg(1);
MaxPages          = arg(2);
Print_OnlyVisible = arg(3);
Max_ColWidth      = arg(4);     /* [ default: 52/96  | optional ]      */
ListTitle         = arg(5);     /* [ default: ""     | optional ]      */
Title_Align       = arg(6);     /* [ default: "Left" | optional ]      */

if MaxPages = "ALL" | Datatype(MaxPages) <> "NUM" then
   MaxPages = 999999;

if Max_ColWidth = "" then do
   if Orient = "PORTR" then 
      Max_ColWidth = 96;
   else;
      Max_ColWidth = 52;
end;

if ListTitle <> "" then do 1
   ListTitle = CGT_GetLJCmnd("BOLD=4")||ListTitle||CGT_GetLJCmnd("ENDBOLD")
   if Title_Align = "" | Title_Align = "L" then ITERATE;
   if Title_Align = "C" then ListTitle = center( ListTitle );
   if Title_Align = "R" then ListTitle = left("",110-length(ListTitle)," ")||ListTitle;
end;

LineCount = 999;
PageCount = 0;
PageLen   = 66;if Orient <> "PORTR" then PageLen = 48;
RecHndls. = "";

LeftIndent =  2;     /* wo erste Spalte beginnt     */

CurrPath = OldPath;  /* de-activate GruWe           */

/* ----------------------------                     */
/* Zuerst alle Felder besorgen:                     */
/* ----------------------------                     */

Header_Line = left("",LeftIndent);  /* init         */
YPrint.YCol.0 = 0;
ok = VRMethod( CN_Objct, "GetFieldList", "FldHndls.");
do i = 1 to FldHndls.0
   if VRMethod( CN_Objct, "GetFieldAttr", FldHndls.i, "Visible" ) then do
      /* nur die Sichtbaren Spalten werden verarbeitet:  */
      j = YPrint.YCol.0 + 1;
      YPrint.YCol.j.YTitle   = VRMethod( CN_Objct, "GetFieldAttr", FldHndls.i, "Title" );
      YPrint.YCol.j.YTitle   = Translate(YPrint.YCol.j.YTitle, "",  "0D"x);
      YPrint.YCol.j.YTitle   = Translate(YPrint.YCol.j.YTitle, " ", "0A"x);
      YPrint.YCol.j.YTitle   = strip(YPrint.YCol.j.YTitle,"L");

      YPrint.YCol.j.YHnd     = FldHndls.i;
      YPrint.YCol.j.YMxWidth = Max( ZGet_MaxFldWidth( CN_Objct,FldHndls.i, Max_ColWidth),  ,
                                    length(YPrint.YCol.j.YTitle) , /* Der Spalten-Header passt immer rein!  */
                                  );
      if Max_ColWidth > 0 then
         YPrint.YCol.j.YMxWidth = Min( Max_ColWidth, YPrint.YCol.j.YMxWidth );


      YPrint.YCol.0 = j;

      /* Header-Line aufbauen:                      */
      Header_Line = Header_Line" "  ,
                  ||left( YPrint.YCol.j.YTitle, Max(length(YPrint.YCol.j.YTitle),YPrint.YCol.j.YMxWidth) );
   end;
end;

/* -------------------------------------------------    */
WhatRecs = "ALL";
if Print_OnlyVisible then
   WhatRecs = "Visible";    /* Ñquivalent zu 'Not-Dirs' */

ok = VRMethod( CN_Objct, "GetRecordList", WhatRecs, "RecHndls.");

do i = 1 to RecHndls.0
   KumLine = left("",LeftIndent);
   do j = 1 to YPrint.YCol.0
      !Data = VRMethod( CN_Objct, "GetFieldData", RecHndls.i, YPrint.YCol.j.YHnd );

      !Data = Translate(!Data, "!!", "0D0A"x);
      KumLine = KumLine" "left(!Data,YPrint.YCol.j.YMxWidth);
   end;

   ok = ZPrint_Container_SingleLine(  KumLine, ListTitle );
   if ok = -1 then
      LEAVE;

end;
if ok >= 0 then 
   Call ZPrint_Container_PageNo;        /* letzte Seite beziffern           */

/* Anzahl Lines auf letzter Seite drucken:      */
ok = VRMethod( CN_Objct, "GetRecordList", ""Visible"", "Aux." );
ok = lineout(YPrinter, "*** End of list - number of lines: "Aux.0 );

ok = lineout(YPrinter, CGT_GetLJCmnd("RESET") );    /* flush buffer (?)     */
if 1 then ok = stream(YPrinter, "c", "Close");

return 0;

/* -----------------------                 */
/* Einzelne Zeile drucken:                 */
/* -----------------------                 */
ZPrint_Container_SingleLine:
What      = arg(1);
ListTitle = arg(2);

   /* Seitenwechsel prÅfen:                         */

   if LineCount > PageLen then do
      /* noch Abschlu·arbeiten auf voriger Seite?   */
      if PageCount > 0 then do
         Call ZPrint_Container_PageNo;
      end;

      /* Neue Seite vorbereiten:                    */
      LineCount = 0;
      PageCount = PageCount+1;
      if PageCount > MaxPages then
         RETURN -1;

      CN_Caption = VRGet( CN_Objct, "Caption" );
      CN_MoreTxt = VRGet( CN_Objct, "UserData" );

      ok = lineout(YPrinter, CGT_GetLJCmnd("NEWPAGE") );
      ok = lineout(YPrinter, center( CN_Caption||" - Date: "date()" -", 110) );
      ok = lineout(YPrinter, ListTitle );
      if CN_MoreTxt <> "" then
         ok = lineout(YPrinter, CN_MoreTxt );
      ok = lineout(YPrinter, left("",110,"-") );
      ok = lineout(YPrinter, Header_Line );
      ok = lineout(YPrinter, left("",110,"-") );
   end;

   /* Zeile ausgeben:                       */

   ok = LineOut(YPrinter, What);
   LineCount = LineCount +1;
return 0;

ZPrint_Container_PageNo:
   ok = lineout(YPrinter, "");             /* Leerzeile vor Seitenzahl   */
   ok = lineout(YPrinter, left("",110,"-") );
   ok = lineout(YPrinter, center("Page "PageCount, 110) );
return;

---------------------------
ZGet_MaxFldWidth: Procedure

/* Durchlesen Container gem. arg(1), nur Spalet gem. arg(2)
   feststellen die hîchste Breite der Field-Daten
*/

Container = arg(1);     /* Name     */
Spalte    = arg(2);     /* Handle   */
LimitWid  = arg(3);     /* opt. limit to this width */

MaxWidth = 0;
ok = VRMethod( Container, "GetRecordList", "Visible", recHndls. );
do i = 1 to recHndls.0
   WhatData = VRMethod( Container, "GetFieldData", recHndls.i, Spalte );
   MaxWidth = Max( length(WhatData), MaxWidth );
end;

if LimitWid <> "" then
   MaxWidth = Min( LimitWid, MaxWidth );

return MaxWidth;


/*:VRX         ZRemove_All
*/
ZRemove_All: Procedure Expose YGlob.
What = arg(1);

if What = "DRIVES" then do
   do i = 1 to YGlob.YDrivRecs.0
      ok = VRMethod("CN_Browser", "RemoveRecord", YGlob.YDrivRecs.i);

      if \ok then ok = beep(333,111);

   end;
   YGlob.YDrivRecs.0 = 0;
end;

if What = "DETAIL" then do
   do i = 1 to YGlob.YDetRecs.0
      ok = VRMethod("CN_Browser", "RemoveRecord", YGlob.YDetRecs.i);

      if \ok then ok = beep(633,111);

   end;
   YGlob.YDetRecs.0 = 0;
end;

return ok;

/*:VRX         ZResize_Dimens
*/
ZResize_Dimens: Procedure

/* -------------------------------------------------------  */
/* Diese Function liefert X und Y so, dass ein Image mit    */
/* Original-Y und -Y 'X_Size' und 'Y_Size' in ein Rechteck  */
/* (Target) in jedem Fall reinpasst, unter Beibehaltung     */
/* des korrekten SeitenverhÑltnisses.                       */
/* -------------------------------------------------------  */

/* alles in Pixels !!                     */

X_Size    = arg(1);   /* Source-Width     */
Y_Size    = arg(2);   /* Source-Height    */
Target_X  = arg(3);   /* Target-Width     */
Target_Y  = arg(4);   /* Target-Height    */
Scale     = arg(5);   /* ["P(ixels)" | "T(wips)" ]  Scala fÅr RÅckgabe */

Source_Ratio = X_Size   % Y_Size;
Target_Ratio = Target_X % Target_Y;

X_Ratio = X_Size / Target_X;
Y_Ratio = Y_Size / Target_Y;

Ratio = Max( X_Ratio, Y_Ratio );

if Scale = "T" then
        Fak = VRMethod("Screen","PixelsToTwips",1);
else;   Fak = 1;

New_X = (( X_Size / Ratio )%1) * Fak;
New_Y = (( Y_Size / Ratio )%1) * Fak;

return New_X New_Y;

/*:VRX         ZSet_Recordtag
*/
ZSet_RecordTag: Procedure Expose YGlob. INIFile;

/* ++ abgespeckte Version ++    */

Rec  = arg(1);
What = arg(2);  /* [ "P(rocessed)" | "F(ileExist)" | "(Selected)"]  */
Mode = arg(3);  /* [ "On" | "Off" | "Auto" ]                        */

/* Sicherheitsabfrage (gegen unbekannte Gefahr!):                   */
if \(VRMethod("CN_Browser", "ValidateRecord", Rec )) then do
   ok = beep(333,400);
   Call XSay "Sysfail in ZSet_RecordTag() - invalid record '"Rec"' passed; Tag not set";
   RETURN -1;
end;

if left( What,1 ) = "S" then do
   /* Mode=Auto implizit:               */
   OldStat = strip( VRMethod("CN_Browser", "GetRecordAttr", Rec, YGlob.YTag_Selected ) );   /* InUse    */
   if (OldStat) then
      ok = VRMethod("CN_Browser", "SetRecordAttr", Rec, YGlob.YTag_Selected, 0 );
   else;
      ok = VRMethod("CN_Browser", "SetRecordAttr", Rec, YGlob.YTag_Selected, 1 );

end;

return 0;

/*:VRX         ZSet_Wait
*/
ZSet_Wait: Procedure;
OnOff = arg(1);     /* [ "On" | "Off" ]      */

if translate( OnOff ) = "ON" then do
   if VRGet("WIN_Wait", "Visible")   then RETURN 0;
   Vis  = 1;
   Sibl = 1;
end;
else;do
   if \VRGet("WIN_Wait",  "Visible") then RETURN 0;
   Vis  = 0;
   Sibl = 9;
end;

ok = VRSet("WIN_Wait", "Visible", Vis );        /* "Bitte warten ... "              */
ok = VRSet("WIN_Wait", "SiblingOrder", Sibl );  /* "Bitte warten ... "              */

ok = VRSet( VRGet("WIN_Wait","Parent"),  "SiblingOrder", 1 );     /* Hauptfenster nach vorn bringen   */

return ok;

/*:VRX         ZSingleImage
*/
ZSingleImage:       ,
          Procedure Expose YGlob. YLang. ,
                    HndImgFS    ,
                    HndImgNM    ,
                    HndAprt     ,
                    HndISO      ,
                    HndExpTm    ,
                    HndMtrMod   ,
                    HndExpPr    ,
                    HndFocLn    ,
                    HndFlash    ,
                    HndTimest   ,
                    HndMaker    ,
                    HndModel;


ImgFile = arg(1);

Rec = VRMethod("CN_1", "AddRecord" );
ok  = VRMethod("CN_1", "SetFieldData", Rec, HndImgFS, ImgFile );
ok  = VRMethod("CN_1", "SetFieldData", Rec, HndImgNM, filespec("name", ImgFile) );

if \ZGetExif( ImgFile, Rec ) then do
   if VRGet("CB_OnlyExif", "Set") then
      ok = VRMethod("CN_1", "RemoveRecord", Rec );
   else;do
      if YGlob.YLang = "D" then
         What = "Keine Exif-Daten";
      else;
         What = "No Exif-data";
      ok  = VRMethod("CN_1", "SetFieldData", Rec, HndAprt, What );
   end;
end;

return 0;

/*:VRX         ZSL_Change
*/
ZSL_Change: Procedure Expose Bild_Height ImgsPerWin !PgMk !PgMk_Incr;

Slider = arg(1);
Step   = arg(2);    /* [ 1 | -1 ]  */

NoSlider = ( Slider = "" );

if (NoSlider) then do
   nop;    /* Step schon Åbergeben         */
end;
else;do
   OldTickIndex = VRGet( Slider, "Userdata" )
   NewTickIndex = VRGet( Slider, "TickIndex" )
   Step = NewTickIndex - OldTickIndex;     /* [ -1 | +1 ]      */
end;

/* -----------------------------------      */
/* Verhindern Oben / Unten rauslaufen:      */
/* -----------------------------------      */
if ( Step + VRGet("EF_TopImgNo", "Value") ) <= 0 then do; ok=beep(444,111); RETURN -1;  end;
if ( Step + VRGet("EF_TopImgNo", "Value") + ImgsPerWin ) > ( VRGet("EF_Limit", "Value") +1 ) then do; ok=beep(111,222); RETURN -1;   end;
/* -----------------------------------      */

ok = VRSet("GB_Thmb","Painting", 0);

ok = VRMethod( "GB_Thmb", "ListChildren", "Childs." );

do j = 1 to Childs.0
   Child = VRGet( Childs.j, "Name" );
   if left(Child,7) = "GRPBOX_" then do
       ok = VRSet( Child, "Top", VRGet( Child, "Top") - ( Bild_Height * Step ) );
   end;
end;

if \(NoSlider) then
   ok = VRSet( Slider, "Userdata", NewTickIndex );

/* -----------------------------------   */
/* PegelMarker: Top-Position anpassen:   */
/* -----------------------------------   */

NewTop = VRGet( !PgMk, "Top" ) + ( !PgMk_Incr * Step );
ok = VRSet( !PgMk, "Top", NewTop );
ok = VRSet("EF_TopImgNo", "Value", VRGet("EF_TopImgNo", "Value")+Step );     /* zÑhlen       */


ok = VRSet("GB_Thmb","Painting", 1);

return 0;


/*:VRX         ZValidDrives
*/
ZValidDrives: procedure expose ValidDrives;
ValidDrives = "";

Drives = SysDriveMap();     /* hole alle Drives in Wordlist         */
do DriveNo = 1 to words(Drives);
   DriveLetter = word(Drives,DriveNo);
   err = FileDevInfo("Info", DriveLetter);
   if err=0 then do
      ValidDrives = ValidDrives DriveLetter;
   end;
end;

return 0;

