/* neu: via gbmrx.dll    */

X_GetImgSize:
Img_FileSpec = arg(1);
GBM_Dir      = arg(2);   /* 'F:\GBM' (ohne '\')     */

rc = GBM_FileHeader(Img_FileSpec, '', 'header.')
if rc = "0" then  do
   XSize = header.width;
   YSize = header.height;
   ReturnText = "";
end;
else;do
   XSize = 0;
   YSize = 0;
   ReturnText = "Error";
end;

return XSize YSize ReturnText;

call RxFuncAdd 'GBM_LoadFuncs', 'GBMRX', 'GBM_LoadFuncs'
call GBM_LoadFuncs;

/* ++ auch in e:\common  ++       */


/* ---------------------------------------------    */
/* Ermitteln X-/Y-Size eines GIF/JPG/...-Images:    */
/* ---------------------------------------------    */
X_GetImgSize:

/* einfachere L”sung (nur BMP): 'ZGet_ImgSize()'   */

Img_FileSpec = arg(1);
GBM_Dir      = arg(2);   /* 'F:\GBM' (ohne '\')     */

if words(Img_FileSpec) > 1 | pos(",",Img_FileSpec) > 0 then
   Img_FileSpec = '"\"'Img_FileSpec'\""'; /* put in doublequtes ++ extended syntax - requires gbm version > 1.38 ++++	*/

BakDir = directory();
ok     = directory( GBM_Dir );
cmd = "gbmhdr "Img_FileSpec" > $log.txt";
cmd;

Logtxt = linein("$log.txt");ok=stream("$log.txt","c","close");
Dimens = word(strip(Logtxt),1);
parse value Dimens with XSize "x" YSize;
if datatype(XSize) <> "NUM" | datatype(YSize) <> "NUM" then
   ReturnText = "Error retrieving X/YSize: "Logtxt;    /* should not occur     */
else;
   ReturnText = Img_FileSpec" hat X/Y-Size="XSize"/"YSize;

ok = directory(BakDir);	/* Return to current Dir	*/
return XSize YSize ReturnText;
