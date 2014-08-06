/* Install PMExif 
*/

nok = RxFuncAdd("SysLoadFuncs",  "RexxUtil", "SysLoadFuncs") ;rc = SysLoadFuncs();

HomePath = directory();

say "Install to "HomePath"? (Y/N)";

if Translate( SysGetKey('NoEcho') ) = "Y" then NOP;
else;do
   say "No installation";
   exit;
end;

ok = SysFileTree("PMExif.exe","files.","F");
if files.0 = 1 then NOP;
else;do
   say "PMExif.exe missing - installation abandoned";
   exit;
end;

/* --------------------------------------  */
/* Create PMExif folder on WPS-desktop:    */
/* --------------------------------------  */

FolderID = "<PMExif Objects>";

ok = SysCreateObject(   "WPFolder",           ,
                        "PMExif",             ,
                        "<WP_DESKTOP>",       ,
                        "OBJECTID="FolderID";ICONFILE=Folder1.ico",  ,
                        "Replace"             ,
                    );

if ok then
   say "Folder-object successfully created";
else;
   say "Error creating Folder-object: Code="ok;

/* --------------------------------------  */
/* Create PMExif program-object:           */
/* --------------------------------------  */

ok = SysCreateObject(   "WpProgram",                                             ,
                        "PMExif"||"0D0A"x||"Display EXIF-Data", ,
                        FolderID,                                                ,
                        "EXENAME="HomePath"\PMExif.exe;ICONFILE="HomePath"\PMExif.ico;"||       ,
                        "STARTUPDIR="HomePath"\",                        ,
                        "Replace"                                       ,
                    );

if ok then
   say "Program-object successfully created";
else;
   say "Error creating program-object: Code="ok;


say "PMExif installation successfully completed";

exit;
