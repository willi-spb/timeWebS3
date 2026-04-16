unit dlg_Mess;
// Диалог вывода сообщений - аналог стандартного, но с возможностью заголовка, выравнивания и пр.
//
// тут выделены функции вызова + типы для вызова - см. Environ объект
 (*
  *
  * The MIT License (MIT)
  * Copyright (c) 2025 Willi - WilliSpb
  *
  *
  * Настоящим предоставляется разрешение бесплатно любому лицу,
  * получившему копию данного программного обеспечения и сопутствующей документации,
  * файлам (далее «Программное обеспечение»), использовать Программное обеспечение без ограничений,
  * включая, помимо прочего, право использовать, копировать, изменять,
  * объединять, публиковать, распространять, сублицензировать и/или продавать копии Программного обеспечения,
  * и разрешать лицам, которым предоставляется Программное обеспечение, делать это,
  * при соблюдении следующих условий:
  * Указанное выше уведомление об авторских правах и данное уведомление о разрешении должны
  * быть включены во все копии или существенные части Программного обеспечения.

  * ПРОГРАММНОЕ ОБЕСПЕЧЕНИЕ ПРЕДОСТАВЛЯЕТСЯ «КАК ЕСТЬ», БЕЗ КАКИХ-ЛИБО ГАРАНТИЙ,
  * ЯВНЫХ ИЛИ ПОДРАЗУМЕВАЕМЫХ, ВКЛЮЧАЯ, НО НЕ ОГРАНИЧИВАЯСЬ ГАРАНТИЯМИ ТОВАРНОЙ ПРИГОДНОСТИ,
  * ПРИГОДНОСТИ ДЛЯ ОПРЕДЕЛЕННОЙ ЦЕЛИ И ОТСУТСТВИЯ НАРУШЕНИЯ ПРАВ.
  * НИ ПРИ КАКИХ ОБСТОЯТЕЛЬСТВАХ АВТОРЫ ИЛИ ПРАВООБЛАДАТЕЛИ НЕ НЕСУТ ОТВЕТСТВЕННОСТИ ЗА КАКИЕ-ЛИБО ПРЕТЕНЗИИ,
  * УЩЕРБ ИЛИ ДРУГУЮ ОТВЕТСТВЕННОСТЬ, ВОЗНИКАЮЩИЕ В РЕЗУЛЬТАТЕ ДОГОВОРА, ДЕЛИКТА ИЛИ ИНЫМ ОБРАЗОМ,
  * ВЫТЕКАЮЩИЕ ИЗ ИЛИ В СВЯЗИ С ПРОГРАММНЫМ ОБЕСПЕЧЕНИЕМ ИЛИ ЕГО ИСПОЛЬЗОВАНИЕМ
  * ИЛИ ДРУГИМИ ДЕЙСТВИЯМИ С ПРОГРАММНЫМ ОБЕСПЕЧЕНИЕМ.
  *)


interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.ImageList,
  System.Generics.Collections,
  Vcl.ImgList, Vcl.Imaging.Pngimage, Vcl.ExtCtrls, Vcl.Buttons;


type

///  Типы для сообщений

  /// <summary>
  ///    тип сообщения (картинка диалога)
  /// </summary>
  TMessDlgType=(mdtUser,mdtInfo,mdtQuest,mdtError,mdtWarning,mdtSysError,mdtCheck);
  /// <summary>
  ///    кнопки диалога сообщения- заголовок по типу
  /// </summary>
  TMessDlgBtn=(mbnOk,mbnCancel,mbnYes,mbnNo,mbnContinue);
  /// <summary>
  ///    набор названий кнопок диалога [mbnOk,mbnCancel]
  /// </summary>
  TMessDlgBtns=set of TMessDlgBtn;

  TMessDlgBeforeShowEvent=procedure(AOwner:TComponent; var AContinueFlag:boolean) of object;
  TMessDlgAfterShowEvent=procedure(AOwner:TComponent; const aCapt,aText:string;aType:TMessDlgType; var ASuccessFlag:boolean) of object;
  TMessDlgAfterErrorEvent=procedure(E: Exception; const aComment: string) of object;

  TMessDlgLogRec=record
    callRegime:Integer;
    dlgType:TMessDlgType;
    Caption,Text,errInfo:string;
    dlgResult:Integer;
    dlgDate:TDateTime;
    ownerName:string;
  end;


  TMessDlgMngr=class
   private
     FVisible:Boolean;
     FlogEnabled:Boolean;
     FstartDate:TDateTime;
    // FcurrentPPI:integer;
     FBeforeShow:TMessDlgBeforeShowEvent;
     FAfterShow:TMessDlgAfterShowEvent;
     FAfterErrorShow:TMessDlgAfterErrorEvent;
     FstayOnTopRegime:integer;
      ///
     FLogList:TList<TMessDlgLogRec>;
     ///
     procedure setVisible(Value:Boolean);
     procedure setLogRecData(aOwner:TComponent; const aCapt,aText:string; aType:TMessDlgType; var aLogRec:TMessDlgLogRec);
   public
     messAppCaptionStr:string;
     constructor Create; virtual;
     destructor Destroy; virtual;
     function getLogLines(const aLines:TStrings; aLRegime:Integer):Boolean; virtual;
     function appendLogToFile(const aFileName:string; aLRegime:Integer):Boolean; virtual;
      function MessDlg(AOwner:TComponent; const aCapt,aText:string;
        aType:TMessDlgType=mdtInfo; aBtns:TMessDlgBtns=[mbnOk]; aDlgRegime:Integer=0):boolean;
      procedure MessDlgErr(E: Exception; const aComment: string);
    property BeforeShow:TMessDlgBeforeShowEvent read FBeforeShow write FBeforeShow;
    property AfterShow:TMessDlgAfterShowEvent read FAfterShow write FAfterShow;
    property AfterErrorShow:TMessDlgAfterErrorEvent read FAfterErrorShow write FAfterErrorShow;
      /// <summary>
    ///   W: доп. от 06.11.2025 - переключение на лог вместо показа сообщений - для режима внешнего вызова утилит
    /// </summary>
    property Visible:boolean read FVisible write setVisible default True;
    property logEnabled:boolean read FlogEnabled write FlogEnabled default false;
    property logList:TList<TMessDlgLogRec> read FLogList;
    property stayOnTopRegime:Integer read FstayOnTopRegime write FstayOnTopRegime;
  end;


  TMess_Dlg = class(TForm)
    pnlBottom: TPanel;
    btnOk: TBitBtn;
    btnCancel: TBitBtn;
    img1: TImage;
    imgList: TImageList;
    Lb_Desc: TLabel;
    tmrRestore: TTimer;
    tmrDelay: TTimer;
    mmoInfo: TMemo;
    procedure tmrRestoreTimer(Sender: TObject);
    procedure tmrDelayTimer(Sender: TObject);
  private
    { Private declarations }
    procedure PrepareShow(aShowRegime,aImgType:integer;
                               const aCapt,aText,aOkCapt,aCancelCapt:string);
  public
    { Public declarations }
  end;

var
  Mess_Dlg: TMess_Dlg;
  MessMngr:TMessDlgMngr;
  {$IFDEF DIRECT_MESS}
    var Environ:TMessDlgMngr=nil;
  {$ENDIF}

 /// <summary>
 ///    вызов диалога - промежут.
 /// </summary>
  function _SM_MessDlg(aRg,aImgType:integer; AOwner:TComponent; const aCapt,aText,aOkCapt,aCancelCapt:string;
   aDelaySec:Integer=0):boolean;

  function divTextToLines(const aText:string; aMaxLength:Integer; const adivStr:String=''):string;

  procedure msd_AssignImageFrom(aImagePicture:TPicture);

  /// <summary>
  ///   назначить заголовки кнопок по умолчанию для типов кнопок диалога
  ///   строка mbnOk=OK,mbnCancel=KKK,mbnYes=jjj
  /// </summary>
  procedure msd_SetBtnCaptions(const aBtnCaptCommaStr:string);

 var messDelaySec:integer=0;


    var msd_def_OkCaption:string='OK';
    var msd_def_CancelCaption:string='Отмена';
    var msd_def_YesCaption:string='Да';
    var msd_def_NoCaption:string='Нет';
    var msd_def_ContinueCaption:string='Продолжить';
    var msd_def_ExitCaption:string='Выйти';
    var msd_def_ErrorTitle:string='Ошибка программы';

    var msd_def_PPI:integer=96;
    var msd_currentPPI:integer=96;

implementation

{$R *.dfm}

 var _imgRef:TPicture=nil;

  function messDlgTypeToString(aItem:TMessDlgType):string;
  begin
    case aItem of
     mdtUser: Result:='user';
     mdtInfo: Result:='info';
     mdtQuest: Result:='quest';
     mdtError: Result:='error';
     mdtWarning: Result:='warning';
     mdtSysError: Result:='syserror';
     mdtCheck: Result:='check';
     else Result:='-';
    end;
  end;


 function _SM_MessDlg;
 var LC,L_Owner:TComponent;
  begin
    Result:=false;
    L_Owner:=AOwner;
    if Assigned(AOwner) then
     begin
       LC:=AOwner.FindComponent('Mess_Dlg');
       if (LC<>nil) and (LC is TMess_Dlg) then
          L_Owner:=nil;
     end;
     with TMess_Dlg.Create(AOwner) do
       try
        if AOwner=nil then
           Position:=poScreenCenter;
        ///
        PrepareShow(aRg,aImgType,aCapt,aText,aOkCapt,aCancelCapt);
        if aDelaySec>1 then
           begin
             tmrDelay.Interval:=aDelaySec*1000+1000;
             tmrDelay.Enabled:=True;
           end;
        ///
        result:=ShowModal=mrOk;
       finally
        Free;
       end;
  end;

function TMessDlgMngr.appendLogToFile(const aFileName: string;
  aLRegime: Integer): Boolean;
var L_LIst:TStrings;
begin
  Result:=False;
  if (FLogList.Count>0) then
   try
     L_LIst:=TStringList.Create;
     if (FileExists(aFileName)) then
       try
         L_LIst.LoadFromFile(aFileName);
        except
       end;
     L_LIst.Add('');
     L_LIst.Add('--execDate '+FormatDateTime('yyyy_mm_dd-hh_nn_ss',FstartDate));
     if getLogLines(L_LIst,aLRegime) then
      try
       L_LIst.SaveToFile(aFileName);
       Result:=True;
       except on E:Exception do
         Result:=False;
      end;
   finally
     L_LIst.Free;
   end;
end;

constructor TMessDlgMngr.Create;
begin
  FVisible:=True;
  FlogEnabled:=False;
  stayOnTopRegime:=0;
  FLogList:=TList<TMessDlgLogRec>.Create;
  FstartDate:=Now;
end;

destructor TMessDlgMngr.Destroy;
begin
  FreeAndNil(FLogList);
end;

function TMessDlgMngr.getLogLines(const aLines: TStrings;
  aLRegime: Integer): Boolean;
var LRec:TMessDlgLogRec;
    LLine,L_txt:string;
begin
  Result:=False;
  if FlogEnabled then
   for Lrec in FLogList do
    begin
     with Lrec do
      begin
       LLine:='';
       L_txt:=Text;
       if Length(errInfo)>0 then
          L_txt:=Trim(L_txt+' err: '+errInfo);
       if aLRegime<=1 then
        LLine:=Format('tm=%s :type=%s, capt=%s, txt=%s, other=%s, res=%d, (callRg=%d)',
         [FormatDatetime('yyyy_mm_dd-hh_nn_ss',dlgDate),messDlgTypeToString(dlgType),
          Caption,L_txt,ownerName,dlgResult,callRegime]);
       ///
       if Length(LLine)>0 then
        begin
          aLines.Add(LLine);
          Result:=True;
        end;
      end;
    end;
end;

function TMessDlgMngr.MessDlg(AOwner:TComponent; const aCapt,aText:string;
  aType:TMessDlgType=mdtInfo; aBtns:TMessDlgBtns=[mbnOk]; aDlgRegime:Integer=0):boolean;

  var LTypeIdx,L_dlgRegime:Integer;
    LCapt,LOkBtnCapt,LCancelBtnCapt:string;
    L_contFlag:Boolean;
     L_logRec:TMessDlgLogRec;
  begin
    LTypeIdx:=Ord(aType)-1;
    LOkBtnCapt:='';
    LCancelBtnCapt:='';
    if mbnOK in aBtns then
       LOkBtnCapt:=msd_def_OKCaption;
    if mbnCancel in aBtns then
       LCancelBtnCapt:=msd_def_CancelCaption;
    if mbnYes in aBtns then
       LOkBtnCapt:=msd_def_YesCaption;
    if mbnNo in aBtns then
       LCancelBtnCapt:=msd_def_NoCaption;
    if mbnContinue in aBtns then
       LOkBtnCapt:=msd_def_ContinueCaption;
    if messAppCaptionStr='' then
       if aCapt='' then LCapt:='App'
       else LCapt:=aCapt
    else
       if aCapt='' then LCapt:=messAppCaptionStr
       else LCapt:=messAppCaptionStr+' - '+aCapt;
   ///
   L_contFlag:=True;
   if Assigned(FBeforeShow) then
        FBeforeShow(AOwner,L_contFlag);
   if L_contFlag then
    try
     if FstayOnTopRegime=1 then
        case aDlgRegime of
         1: L_dlgRegime:=11
         else L_dlgRegime:=10;
        end
     else L_dlgRegime:=aDlgRegime;
     if FVisible then
        Result:=_SM_MessDlg(L_DlgRegime,LTypeIdx,AOwner,LCapt,aText,LOkBtnCapt,LCancelBtnCapt,messDelaySec)
     else
         Result:=true;
     if FlogEnabled then
      begin
        setLogRecData(aOwner,aCapt,aText,aType,L_logRec);
        if Result then
           L_logRec.dlgResult:=1;
        FLogList.Add(L_logRec);
      end;
     if Assigned(FAfterShow) then
        FAfterShow(AOwner,LCapt,aText,aType,Result);
    finally
     messDelaySec:=0;
   end;
end;

procedure TMessDlgMngr.MessDlgErr(E: Exception; const aComment: string);
var LCapt,LText:string;
    L_contFlag:Boolean;
    L_logRec:TMessDlgLogRec;
begin
  LCapt:=' '+msd_def_ErrorTitle;
  if Trim(aComment)='' then LText:=''
  else LText:=aComment+#13#10#13#10;
  LText:=Ltext+E.ClassName+' : '+E.Message;
  L_contFlag:=True;
  if Assigned(FBeforeShow) then
        FBeforeShow(nil,L_contFlag);
   if L_contFlag then
    try
      if FVisible then
        _SM_MessDlg(0,3,nil,LCapt,LText,'','',messDelaySec);
      if FlogEnabled then
       begin
        setLogRecData(nil,'',aComment,mdtError,L_logRec);
        L_logRec.callRegime:=10;
        L_logRec.errInfo:=E.ClassName+' : '+E.Message;
        FLogList.Add(L_logRec);
       end;
      if Assigned(FAfterErrorShow) then
          FAfterErrorShow(E,aComment);
    finally
     messDelaySec:=0;
    end;
end;
procedure TMessDlgMngr.setLogRecData(aOwner: TComponent; const aCapt,
  aText: string; aType: TMessDlgType; var aLogRec: TMessDlgLogRec);
begin
 aLogRec.callRegime:=1;
 if Assigned(aOwner) then aLogRec.ownerName:=aOwner.Name
 else aLogRec.ownerName:='';
 aLogRec.dlgType:=aType;
 aLogRec.Caption:=aCapt;
 aLogRec.Text:=aText;
 aLogRec.errInfo:='';
 aLogRec.dlgResult:=0;
 aLogRec.dlgDate:=Now;
end;

procedure TMessDlgMngr.setVisible(Value: Boolean);
begin
  if Value<>FVisible then
   begin
     FVisible:=Value;
     if FVisible=false then
        FlogEnabled:=True; // !
   end;
end;

{
  function TMessDlgMngr.MessDlg(AOwner:TComponent; const aCapt,aText:string;
  aType:TMessDlgType=mdtInfo; aBtns:TMessDlgBtns=[mbnOk]; aDlgRegime:Integer=0):boolean;
  var LmType:VCL.Dialogs.TMsgDlgType;
      LmBtns:VCL.Dialogs.TMsgDlgButtons;
      L_btn:TMessDlgBtn;
   begin
     case aType of
       mdtUser: LmType:=mtCustom;
       mdtInfo: LmType:=mtInformation;
       mdtQuest: LmType:=mtConfirmation;
       mdtError,mdtSysError: LmType:=mtError;
       mdtWarning: LmType:=mtWarning;
       mdtCheck: LmType:=mtInformation;
     end;
     LmBtns:=[];
     for L_btn:=Low(TMessDlgBtn) to High(TMessDlgBtn) do
       if L_btn in aBtns then
         case L_btn of
              mbnOk: LmBtns:=LmBtns+[TMsgDlgBtn.mbOK];
              mbnCancel: LmBtns:=LmBtns+[TMsgDlgBtn.mbCancel];
              mbnYes: LmBtns:=LmBtns+[TMsgDlgBtn.mbYes];
              mbnNo: LmBtns:=LmBtns+[TMsgDlgBtn.mbNo];
              mbnContinue: LmBtns:=LmBtns+[TMsgDlgBtn.mbIgnore];
         end;
     if LmBtns=[] then LmBtns:=[TMsgDlgBtn.mbOK];
     MessageDlg(aText,LmType,LmBtns,0);
   end;

procedure TMessDlgMngr.MessDlgErr(E: Exception; const aComment: string);
 begin
   MessDlg(nil,'',Concat(aComment,' ERROR: '+E.ClassName+' : '+E.Message),mdtError,[mbnOk],0);
 end;
}


function divTextToLines(const aText:string; aMaxLength:Integer; const adivStr:String=''):string;
var LDiv:string;
 begin
  Result:='';
  if adivStr='' then LDiv:=#13#10 else LDiv:=adivStr;
  Result:=WrapText(aText,LDiv,[',',';'],aMaxLength);
 end;


procedure msd_AssignImageFrom(aImagePicture:TPicture);
 begin
   _imgRef:=aImagePicture;
 end;

procedure msd_SetBtnCaptions(const aBtnCaptCommaStr:string);
var LList:TStrings;
    i:integer;
    LName:string;
 begin
  LList:=TStringList.Create;
  try
    LList.StrictDelimiter:=true;
    if aBtnCaptCommaStr<>'' then
       LList.CommaText:=aBtnCaptCommaStr
    else LList.CommaText:=
     'btn_ok=OK,btn_cancel=Отмена,btn_yes=Да,btn_no=Нет,btn_continue=Продолжить,btn_exit=Выйти,err_title=Ошибка программы';
    i:=0;
    while i<LList.Count do
     begin
       LName:=LowerCase(Trim(LList.Names[i]));
       if LName='btn_ok' then
          msd_def_OkCaption:=LList.ValueFromIndex[i];
       if LName='btn_cancel' then
          msd_def_CancelCaption:=LList.ValueFromIndex[i];
       if LName='btn_yes' then
          msd_def_YesCaption:=LList.ValueFromIndex[i];
       if LName='btn_no' then
          msd_def_NoCaption:=LList.ValueFromIndex[i];
       if LName='btn_continue' then
          msd_def_ContinueCaption:=LList.ValueFromIndex[i];
       if LName='btn_exit' then
          msd_def_ExitCaption:=LList.ValueFromIndex[i];
       if LName='err_title' then
          msd_def_ErrorTitle:=LList.ValueFromIndex[i];
       Inc(i);
     end;
  finally
    LList.Free;
  end;
 end;

////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////
procedure TMess_Dlg.PrepareShow(aShowRegime,aImgType:integer;
                               const aCapt,aText,aOkCapt,aCancelCapt:string);
 var LCaptW,LW,LH,LimgIndex,LLeft,LHeight,LTextRowCount,L_vi:Integer;
     LMaxWidth,LMaxHeight:Integer;
     LCustomImageFlag:boolean;
     LCenterFlag:Boolean;
     L_Memo:TMemo;
        ///
        function L_GetMaxTextLen:Integer;
        var LL_List:TStringList;
            ii,LL_W:Integer;
          begin
            Result:=0;
            LL_List:=TStringList.Create;
            try
              LL_List.Text:=aText; //!
              LTextRowCount:=LL_List.Count; // ! только для Lb_Desc!
              Lb_Desc.WordWrap:=False;
              Lb_Desc.Canvas.Font.Assign(Lb_Desc.Font);
              ii:=0;
              while ii<LL_List.Count do
               begin
                 LL_W:=Lb_Desc.Canvas.TextWidth(LL_List.Strings[ii]);
                 if LL_W>Result then
                         Result:=LL_W;
                 Inc(ii);
               end;
             Result:=MulDiv(Result,msd_currentPPI,msd_def_PPI);
            finally
              LL_List.Free;
            end;
          end;
  begin
   LCenterFlag:=False;
   LCustomImageFlag:=False;
   /// нет режима картинки
   if (aImgType<0) then begin
      img1.Visible:=False;
      if (_imgRef<>nil) and (Assigned(_imgRef)) then
       begin
        LCustomImageFlag:=True;
        img1.Visible:=True;
        img1.AutoSize:=True;
        img1.Picture.Assign(_imgRef);
        img1.AutoSize:=False;
        if img1.Width>80 then
           img1.Width:=80;
        if img1.Height>80 then
           img1.Height:=80;
       _imgRef:=nil;
       end;
     end;
   /// по режимам:
   case aShowRegime of
          1,11: begin
                  mmoInfo.Visible:=True;
                  Lb_Desc.Visible:=False;
                  /// нет режима картинки
                 if (aImgType<0) and (LCustomImageFlag=False) then
                  begin
                    mmoInfo.Left:=img1.Left+6;
                    mmoInfo.Width:=Width-18;
                  end
                 else
                  begin
                    mmoInfo.Left:=img1.Left+img1.Width+6;
                    mmoInfo.Width:=Width-mmoInfo.Left-10;
                    mmoInfo.Top:=4;
                  end;
                  LLeft:=mmoInfo.Left;
                  LMaxWidth:=MulDiv(900,msd_currentPPI,msd_def_PPI);
                  Lb_Desc.Font.Assign(mmoInfo.Font);
                  /// найти самую длинную строку
                  LW:=L_GetMaxTextLen+12;
                  if LW<250 then
                     LW:=250;
                end
     else
              begin
               mmoInfo.Visible:=False;
               Lb_Desc.Visible:=True;
               if (aImgType<0) and (LCustomImageFlag=False) then
                begin
                  Lb_Desc.Left:=img1.Left+4;
                  Lb_Desc.Width:=Width-16;
                end
               else
                begin
                  Lb_Desc.Left:=img1.Left+img1.Width+6;
                  Lb_Desc.Width:=Width-Lb_Desc.Left-6;
                end;
               Lb_Desc.Top:=8;
               LLeft:=Lb_Desc.Left;
               LMaxWidth:=MulDiv(800,msd_currentPPI,msd_def_PPI);
               /// найти самую длинную строку
               LW:=L_GetMaxTextLen+16; // 16 надо!
              end;
   end;
    if (aShowRegime>=10) then
       FormStyle:=fsStayOnTop; // !!
    ///
    /// вычислить ширину окна по длине тeкста и длине заголовка окна
    LCaptW:=MulDiv(Round(1.5*Canvas.TextWidth(aCapt)),msd_currentPPI,msd_def_PPI);
    if LCaptW>LMaxWidth then
           LCaptW:=LMaxWidth;
    if LW>LMaxWidth then
           LW:=LMaxWidth;
    if (LCaptW>LW+LLeft+4) then
           LW:=LCaptW
    else
         LW:=LW+LLeft+4;
    L_vi:=MulDiv(150,msd_currentPPI,msd_def_PPI);
    if (LW<L_vi) then
        LW:=L_vi;
    L_vi:=MulDiv(300,msd_currentPPI,msd_def_PPI);
    if (aCancelCapt<>'') and (LW<L_vi) then
      begin
        LCenterFlag:=True;
        Lb_Desc.Alignment:=taCenter;
        LW:=L_vi;
      end;
    ///
    Width:=LW;
    ///
    /// Height
    Caption:=aCapt;
    case aShowRegime of
     1: begin
          LMaxHeight:=MulDiv(800,msd_currentPPI,msd_def_PPI);
         { mmoInfo.ReadOnly:=False;
          mmoInfo.WordWrap:=True;
          mmoInfo.Font.Assign(mmoInfo.Font);
          mmoInfo.Parent:=Self;
          mmoInfo.Lines.Text:=aText;
          LHeight:=(Lb_Desc.Canvas.TextHeight('H'))*mmoInfo.Lines.Count+
                   Lb_Desc.Canvas.TextHeight('H') div 2+6;
         }
         /// баг Embarcadero - если шрифт в memo отличается от умолчвания - то неправильно рассчит. кол-во строк
         /// вместо этого выводит кол-во символов
         ///  поэтому заменил таким:
          L_Memo:=TMemo.Create(nil);
          try
           L_Memo.WordWrap:=True;
           L_Memo.Width:=mmoInfo.Width;
           L_Memo.Parent:=Self;
           L_Memo.Font.Assign(mmoInfo.Font);
           L_Memo.Lines.Text:=aText;
           LHeight:=MulDiv((Lb_Desc.Canvas.TextHeight('H'))*L_Memo.Lines.Count+
                   Lb_Desc.Canvas.TextHeight('H') div 2+6,msd_currentPPI,msd_def_PPI);
          finally
           L_Memo.Free;
          end;
          mmoInfo.Lines.Text:=aText;
          LH:=GetSystemMetrics(SM_CYCAPTION)+mmoInfo.Top+LHeight+6+pnlBottom.Height+12;
          if LH>LMaxHeight then
           begin
             LH:=LMaxHeight;
             mmoInfo.ScrollBars:=ssVertical; // !
           end;
        end
     else begin
            LMaxHeight:=MulDiv(900,msd_currentPPI,msd_def_PPI);
            Lb_Desc.WordWrap:=True;
            Lb_Desc.Caption:=aText;
            LHeight:=MulDiv((Lb_Desc.Canvas.TextHeight('RЙy'))*(LTextRowCount)+6,msd_currentPPI,msd_def_PPI);
            LH:=GetSystemMetrics(SM_CYCAPTION)+Lb_Desc.Top+LHeight+6+pnlBottom.Height+18;
            if LH>LMaxHeight then
             begin
               LH:=LMaxHeight;
               /// что делать если текст не влезет?
             end;
          end;
    end;
    if (LH<LMaxHeight) and (img1.Visible) and (LHeight<img1.Height+6) then
        LH:=img1.Height+6+
            GetSystemMetrics(SM_CYCAPTION)+img1.Top+pnlBottom.Height+12;
    ///
    L_vi:=MulDiv(165,msd_currentPPI,msd_def_PPI);
    if LH<L_vi then
       LH:=L_vi;
    Height:=LH;
   ///
    case aShowRegime of
     1: mmoInfo.Height:=ClientHeight-mmoInfo.Top-pnlBottom.Height-10;
     else Lb_Desc.Height:=ClientHeight-Lb_Desc.Top-pnlBottom.Height-8;
   end;
    ///
    /// picture set
    if aImgType>=0 then
     begin
      img1.Picture.Bitmap:= nil;
      img1.Picture.Bitmap.SetSize(48,48);
     end;
    LimgIndex:=aImgType mod 6;
    if aImgType>=0 then
           imgList.GetBitmap(LimgIndex,img1.Picture.Bitmap);
    /// caption buttons set
    if aOkCapt='' then btnOk.Caption:=msd_def_OkCaption
    else btnOk.Caption:=aOkCapt;
    if (UpperCase(aCancelCapt)='C') or  /// russ C
       (UpperCase(aCancelCapt)='С') then
           btnCancel.Caption:=msd_def_CancelCaption
    else
           btnCancel.Caption:=aCancelCapt;
    /// buttons Widths set
    LW:=MulDiv(8+Round(1.25*Canvas.TextWidth(btnOk.Caption)),msd_currentPPI,msd_def_PPI);
    if LW>btnOk.Width+8 then
       btnOk.Width:=LW;
    LW:=MulDiv(8+Round(1.25*Canvas.TextWidth(btnCancel.Caption)),msd_currentPPI,msd_def_PPI);
    if LW>btnCancel.Width+8 then
       btnCancel.Width:=LW;
    /// align buttons
    btnCancel.Left:=Width-btnOk.Left-btnCancel.Width;
    /// not Visible Cancel button
    if aCancelCapt='' then
         begin
           btnOk.Anchors:=[akRight,akTop];
           btnOk.Left:=btnCancel.Left;
           btnCancel.Visible:=false;
         end
    else
         begin
          if Width>(btnOk.Width+28)+30+(btnCancel.Width+28) then
           begin
             LLeft:=Width div 2-btnOk.Width-15;
             if LLeft>0 then btnOk.Left:=LLeft
             else btnOk.Left:=4;
             LLeft:=Width div 2+15;
             if LLeft+btnCancel.Width<Width-8 then
                btnCancel.Left:=LLeft
             else btnCancel.Left:=Width-btnCancel.Width-8;
           end;
           ///
           ///  для исключений НЕТ (Cancel) - это продолжение работы
           if (btnCancel.Caption=msd_def_ContinueCaption) or
              ((LimgIndex in [2,3,4]) and (btnCancel.Caption=msd_def_NoCaption)) then
               begin
                 btnCancel.TabOrder:=0;
                 btnCancel.Default:=True;
               end;
           ///
         end;
end;

procedure TMess_Dlg.tmrDelayTimer(Sender: TObject);
begin
 if btnCancel.Visible=true then
    ModalResult:=mrCancel
 else
    ModalResult:=mrCancel;
end;

procedure TMess_Dlg.tmrRestoreTimer(Sender: TObject);
begin
 { if tmrRestore.Tag=0 then
     begin
       tmrRestore.Tag:=1;
       Application.MainForm.BringToFront;
     end
  else }
   Self.BringToFront;
end;

initialization

    MessMngr:=TMessDlgMngr.Create;
    msd_currentPPI:=Screen.PixelsPerInch;
  if msd_currentPPI<=10 then
     msd_currentPPI:=msd_def_PPI;

finalization

    MessMngr.Free;

end.

