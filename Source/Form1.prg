/*
 * Proyecto: jpgreducer
 * Fichero: Form1.prg
 * Descripción: JPG size reducer
 * Autor: Ignacio Ortiz de Zúñiga
 * Fecha: 05/05/2015
 */

#include "Xailer.ch"
#include "directry.ch"

CLASS TForm1 FROM TForm

   DATA lWorking INIT .F.
   DATA lStop    INIT .F.
   DATA lPaPedro INIT .F.

   DATA lPana INIT .F.

   COMPONENT oGroupBox1
   COMPONENT oEdSource
   COMPONENT oLabelBuddy1
   COMPONENT oLabelBuddy2
   COMPONENT oEdTarget
   COMPONENT oChkRecur
   COMPONENT oGroupBox2
   COMPONENT oBtnStart
   COMPONENT oGroupBox3
   COMPONENT oLabelBuddy3
   COMPONENT oEdFile
   COMPONENT oLblCounter
   COMPONENT oEdWidth
   COMPONENT oLabelBuddy4
   COMPONENT oBrowseForFolderDlg1
   COMPONENT oBrowseForFolderDlg2
   COMPONENT oChkExclude
   COMPONENT oProgress
   COMPONENT oImage1
   COMPONENT oHyperLink1
   COMPONENT oNotifyIcon1
   COMPONENT oChkEqualDate

   METHOD CreateForm()
   METHOD EditBtn1BtnClick( oSender, Value )
   METHOD BtnStartClick( oSender )
   METHOD FormClose( oSender, @lClose )
   METHOD EdTargetBtnClick( oSender, Value )
   METHOD FormInitialize( oSender )

ENDCLASS

#include "Form1.xfm"

//------------------------------------------------------------------------------

METHOD EditBtn1BtnClick( oSender, Value ) CLASS TForm1

   WITH OBJECT ::oBrowseForFolderDlg1
      IF :Run()
         oSender:Value := :cRoot
      ENDIF
   END WITH

RETURN Nil

//------------------------------------------------------------------------------

METHOD EdTargetBtnClick( oSender, Value ) CLASS TForm1

   WITH OBJECT ::oBrowseForFolderDlg2
      IF :Run()
         oSender:Value := :cRoot
      ENDIF
   END WITH

RETURN Nil

//------------------------------------------------------------------------------

METHOD BtnStartClick( oSender ) CLASS TForm1

   LOCAL aFiles := {}
   LOCAL tFile, tCapture
   LOCAL cFile, cLen, cStream, cDir, cTarget
   LOCAL nWidth, nOff, nDim, nLen
   LOCAL lExc

   IF ::lWorking
      ::lStop := .T.
      RETURN NIL
   ENDIF

   ::lStop := .f.

   IF !HB_DirExists( ::oEdSource:Value )
      MsgInfo( "Source directory invalid" )
      RETURN NIL
   ENDIF

   IF !HB_DirExists( ::oEdTarget:Value ) .AND. HB_DirCreate( ::oEdTarget:Value ) > 0
      MsgInfo( "Target directory invalid" )
      RETURN NIL
   ENDIF

   ::oGroupBox1:lEnabled := .f.
   ::oGroupBox2:lEnabled := .f.
   ::oGroupBox3:lEnabled := .f.
   ::oBtnStart:cText     := "Cancel"

   Application:lBusy := .t.

   ::lWorking := .t.

   AddFiles( @aFiles, ::oEdSource:Value, ::oChkRecur:lChecked )

   nLen := Len( aFiles )
   cLen := LTrim( Str( nLen ) )
   lExc := ::oChkExclude:lChecked
   cDir := ::oEdTarget:Value
   nOff := Len( Trim( ::oEdSource:Value ) )

   nWidth  := ::oEdWidth:Value

   Application:lBusy := .f.

   ::oLblCounter:cText := "0/" + cLen
   ::oProgress:nMax := Len( aFiles )
   ::oProgress:nValue := 0

   FOR EACH cFile IN aFiles
      cTarget := cDir + SubStr( cFile, nOff + 1 )
      IF !File( cTarget )
         WITH OBJECT TPicture():Create()
            :LoadFromFile( cFile,, .f. )
            IF !:IsPicture() .OR. :nWidth == 0
               :End()
               MsgInfo( "Load from file error:" + CRLF + CRLF + cFile )
               EXIT
            ENDIF
            nDim := Max( :nWidth, :nHeight )
            IF nDim > nWidth
               cStream := :MakeThumbnail( nWidth, nWidth )
               IF Empty( cStream )
                  :End()
                  MsgInfo( "Make thumbnail error:" + CRLF + CRLF + cFile )
                  EXIT
               ENDIF
               cTarget := cDir + SubStr( cFile, nOff + 1 )
               IF MakePath( cTarget )
                  IF ! HB_MemoWrit( cTarget, cStream, .f. )
                     :End()
                     MsgInfo( "File write error:" + CRLF + CRLF + cTarget )
                     EXIT
                  ENDIF
               ELSE
                  EXIT
               ENDIF
            ELSEIF !lExc
               IF !MakePath( cTarget ) .OR. !CopyFile( cFile, cTarget )
                  :End()
                  MsgInfo( "File write error:" + CRLF + CRLF + cTarget )
                  EXIT
               ENDIF
            ENDIF
            tCapture := HB_CToT( :GetCaptureDateTime(), "YYYY:MM:DD", "HH:MM:SS" )
            SetFileDateTime( cTarget, tCapture )
            :End()
         END WITH
//      ELSEIF ::oChkEqualDate:lChecked
//         IF HB_FGetDateTime( cTarget, @tFile )
//            WITH OBJECT TPicture():Create()
//               :LoadFromFile( cTarget,, .t. )
//               IF :IsPicture()
//                  tCapture := HB_CToT( :GetCaptureDateTime(), "YYYY:MM:DD", "HH:MM:SS" )
//                  IF tCapture != tFile
//                     SetFileDateTime( cTarget, tCapture )
//                  ENDIF
//               ENDIF
//               :End()
//            END WITH
//         ENDIF
      ENDIF
      ::oEdFile:Value := cFile
      ::oLblCounter:cText := LTrim( Str( cFile:__EnumIndex() ) ) + "/" + cLen
      ::oProgress:nValue := cFile:__EnumIndex()
      Application:SetProgress( 1, cFile:__EnumIndex(), nLen )
      ProcessMessages()
      IF ::lStop
         MsgInfo( "Processs aborted!" )
         ::oProgress:nValue := 0
         EXIT
      ENDIF
   NEXT

   ::oGroupBox1:lEnabled := .t.
   ::oGroupBox2:lEnabled := .t.
   ::oGroupBox3:lEnabled := .t.
   ::oBtnStart:cText     := "Start"

   ::lWorking := .f.

   Application:SetProgress( 0, 0, 100 )

RETURN Nil

//------------------------------------------------------------------------------

METHOD FormClose( oSender, lClose ) CLASS TForm1

   lClose := !::lWorking

   IF lClose
      WITH OBJECT TIni():Create( FileSetExtension( Application:cFileName, "ini" ) )
         :SetEntry( "main", "source", ::oEdSource:Value )
         :SetEntry( "main", "target", ::oEdTarget:Value )
         :SetEntry( "main", "recursive", ::oChkRecur:lChecked )
         :SetEntry( "main", "max dimension", ::oEdWidth:Value )
         :SetEntry( "main", "exclude images", ::oChkExclude:lChecked )
         :SetEntry( "main", "equal date", ::oChkEqualDate:lChecked )
         :End()
      END WITH
   ENDIF

RETURN Nil

//------------------------------------------------------------------------------

STATIC FUNCTION AddFiles( aFiles, cDir, lRecurse )

   LOCAL aFile
   LOCAL cFile

   // First we load files

   FOR EACH aFile IN Directory( cDir + "\*.JPG" )
      Aadd( aFiles, cDir + "\" + aFile[ F_NAME ] )
   NEXT

   FOR EACH aFile IN Directory( cDir + "\*.JPEG" )
      Aadd( aFiles, cDir + "\" + aFile[ F_NAME ] )
   NEXT

   // Then we load directories

   IF lRecurse
      FOR EACH aFile IN Directory( cDir + "\*.*", "D" )
         cFile := aFile[ F_NAME ]
         IF "D" $ aFile[ F_ATTR ] .AND. cFile != "." .AND. cFile != ".."
            AddFiles( @aFiles, cDir + "\" + cFile, lRecurse )
         ENDIF
      NEXT
   ENDIF

RETURN NIL

//------------------------------------------------------------------------------

STATIC FUNCTION MakePath( cFile )

   LOCAL cTmp
   LOCAL nAt

   nAt  := 0

   DO WHILE ( nAt := hb_At( "\", cFile, nAt ) ) > 0
      cTmp := Left( cFile, nAt - 1 )
      IF ("\" $ cTmp) .AND. !HB_DirExists ( cTmp )
         IF HB_DirCreate( cTmp ) > 0
            MsgInfo( "Error creating directory: " + CRLF + CRLF + cTmp )
            RETURN .F.
         ENDIF
      ENDIF
      nAt ++
   END WITH

RETURN .T.

//------------------------------------------------------------------------------

METHOD FormInitialize( oSender ) CLASS TForm1

   WITH OBJECT TIni():Create( FileSetExtension( Application:cFileName, "ini" ) )
      ::oEdSource:Value        := :GetEntry( "main", "source")
      ::oEdTarget:Value        := :GetEntry( "main", "target" )
      ::oChkRecur:lChecked     := :GetEntry( "main", "recursive", .t.)
      ::oEdWidth:Value         := :GetEntry( "main", "max dimension", 2048 )
      ::oChkExclude:lChecked   := :GetEntry( "main", "exclude images", .f. )
      ::oChkEqualDate:lChecked := :GetEntry( "main", "equal date", .t. )
      :End()
   END WITH

RETURN Nil

//------------------------------------------------------------------------------

FUNCTION Pana()
RETURN NIL
