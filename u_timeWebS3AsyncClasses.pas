unit u_timeWebS3AsyncClasses;
 (*
  *   Потоковая отправка и получение файлов S3 timeWeb.cloud - два класса со ссылкой на менеджер обмена S3
  *
  * The MIT License (MIT)
  * Copyright (c) 2026 Willi - WilliSpb
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

 uses System.Classes, System.SysUtils, Winapi.Windows,
    IdComponent,        // Компонент TIdHTTP
    u_errHandler,
  c_timeWebS3;

 type
  TtwProgressEvent = procedure(ASender:TObject; AProgress: Integer) of object;

  TtwType=(ttw_GetObjectName,ttw_UploadFile,ttw_DownloadFile);
  TwmRegime=(wmr_Guid,wmr_GuidString);

  TtwThread = class(TThread)
  private
    Ftwtype:TtwType;
    FwMessRegime:TwmRegime;
    FResult: Boolean;
    FUniqueID:TGUID;
    FUniqueString:string;
    Fwm_MessID:Cardinal;
    F_closethFlag:Boolean;
    ///
    FTWMngrRef:TtimeWebS3Manager;
    FLocalFileName: string;
    FObjectName: string;
    FWindowHandle: HWND;
    F_FileStream: TStream;
    FOnProgress: TtwProgressEvent;
   protected
    procedure DoProgress(AProgress: Integer); virtual;
    ///
    procedure do_IdHTTPWorkBegin(ASender: TObject; AWorkMode: TWorkMode; AWorkCountMax: Int64); virtual;
    procedure do_IdHTTPWorkEnd(ASender: TObject; AWorkMode: TWorkMode); virtual;
    procedure do_IdHTTPWork(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64); virtual;
    ///
    procedure setTwParams(atwH:TtwType; aTWMngrRef:TtimeWebS3Manager; const ALocalFileName, AObjectAltName: string;
       AWindowHandle: HWND; AOnUploadProgress: TtwProgressEvent; aMessRegime:TwmRegime=wmr_GuidString);
   public
    property ResultSuccess: Boolean read FResult;
    property UniqueID:TGUID read FUniqueID;
    property twtype:TtwType read Ftwtype;
    property wMessRegime:TwmRegime read FwMessRegime write FwMessRegime;
  end;


  TtwUploadFileThread = class(TtwThread)
  private
    procedure do_IdHTTPWork(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64); override;
    ///
  protected
    procedure Execute; override;
  public
    constructor Create(aTWMngrRef:TtimeWebS3Manager; const ALocalFileName, AObjectAltName: string;
      AWindowHandle: HWND; AOnUploadProgress: TtwProgressEvent);
  end;

  TtwDownloadFileThread = class(TtwThread)
  private
    FMemDataFlag: Boolean;
    procedure do_IdHTTPWork(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64); override;
  protected
    procedure Execute; override;
  public
    constructor Create(aTWMngrRef:TtimeWebS3Manager; const AObjectName, ALocalFilePath: string;
      AMemDataFlag: Boolean; AWindowHandle: HWND; AOnDownloadProgress: TtwProgressEvent);
  end;





  /// WM_USER=1024
  const wm_TWMess=1024 + 520;

implementation

 uses// System.Hash,           // Для SHA-256 и HMAC (в XE10.1 они есть)
  IdGlobal,
  IdURI,
  IdHTTP,
  IdSSLOpenSSL,       // Для работы с HTTPS (обязательно!)
  ///
  u_wCodeTrace;

  {
  procedure TTimeWebS3Manager.UploadFileAsync(const aLocalFileName,
  aObjectAltName: string; AWindowHandle: HWND);
begin
  TUploadFileThread.Create(aLocalFileName, aObjectAltName, Fbucket, FHost,
    AWindowHandle,
    procedure(AProgress: Integer)
    begin
      // Можно добавить обработку прогресса здесь (в главном потоке)
    end).Start;
end;


procedure TMyForm.WndProc(var Message: TMessage);
begin
   if Message.Msg = WM_USER + 20 then
   begin
     ProgressBar1.Position := Message.WParam; // Message.WParam содержит процент загрузки
   end else inherited WndProc(Message);
end;
  }

{ TtwThread }

procedure TtwThread.DoProgress(AProgress: Integer);
var LP: PChar;
begin
 if Assigned(FOnProgress) then
    Synchronize(procedure begin FOnProgress(Self,AProgress); end);
 ///
  if FWindowHandle <> 0 then
   case FwMessRegime of
      wmr_Guid: PostMessage(FWindowHandle,Fwm_MessID, WPARAM(AProgress), LPARAM(@FUniqueID));
      wmr_GuidString: begin
                        LP:=StrNew(PChar(FUniqueString));
                        PostMessage(FWindowHandle,Fwm_MessID, WPARAM(AProgress), LPARAM(LP));
                      end;
   end;
end;

procedure TtwThread.do_IdHTTPWork(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCount: Int64);
begin
 if Terminated then
  begin
    F_closethFlag:=True;
    Abort;
  end;
end;

procedure TtwThread.do_IdHTTPWorkBegin(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCountMax: Int64);
begin
 DoProgress(0);
end;

procedure TtwThread.do_IdHTTPWorkEnd(ASender: TObject; AWorkMode: TWorkMode);
begin
 DoProgress(100);
end;

procedure TtwThread.setTwParams(atwH:TtwType; aTWMngrRef: TtimeWebS3Manager;
  const ALocalFileName, AObjectAltName: string; AWindowHandle: HWND;
  AOnUploadProgress: TtwProgressEvent; aMessRegime:TwmRegime=wmr_GuidString);
begin
  F_closethFlag:=False;
 // FreeOnTerminate := True;
  FLocalFileName := ALocalFileName;
  FObjectName := AObjectAltName;
  FTWMngrRef:=aTWMngrRef;
  FWindowHandle := AWindowHandle;
  FOnProgress := AOnUploadProgress;
  FUniqueID:=TGuid.NewGuid;
  FUniqueString:=GUIDToString(FUniqueID);
  FtwType:=atwH;
  case atwH of
    ttw_GetObjectName: Fwm_MessID:=wm_TWMess;
    ttw_UploadFile: Fwm_MessID:=wm_TWMess+1;
    ttw_DownloadFile: Fwm_MessID:=wm_TWMess+2;
  end;
  FwMessRegime:=aMessRegime;
end;


////////////////////////////////////
///  TtwUploadFileThread
///




constructor TtwUploadFileThread.Create(aTWMngrRef:TtimeWebS3Manager; const ALocalFileName, AObjectAltName: string;
  AWindowHandle: HWND; AOnUploadProgress: TtwProgressEvent);
begin
  inherited Create(True); // Создаём приостановленным
  FreeOnTerminate := True; // Поток удалит себя сам после выполнения
  setTwParams(ttw_UploadFile,aTWMngrRef,ALocalFileName,AObjectAltName,AWindowHandle,AOnUploadProgress);
end;

procedure TtwUploadFileThread.do_IdHTTPWork(ASender: TObject;
  AWorkMode: TWorkMode; AWorkCount: Int64);
var
  Progress: Integer;
begin
  if Terminated then
   begin
     F_closethFlag:=True; // Прерываем операцию, если поток остановлен
     Abort;
   end
  else
   begin
      if AWorkMode = wmWrite then
      begin
        // Проверка на размер файла, чтобы избежать деления на ноль
        if F_FileStream.Size > 0 then
        begin
          Progress := Round((AWorkCount / F_FileStream.Size) * 100);
          DoProgress(Progress);
        end;
      end;
   end;
end;

procedure TtwUploadFileThread.Execute;
var
  LrespCode:integer;
  LS, LObjectName, LResourcePath, LHost, LUrl, LRespText: string;
  LPayloadHash, LCanonicalRequest_Hash, LSignature, LAuthHeader: string;
  IdHTTP: TIdHTTP;
  IdSSL: TIdSSLIOHandlerSocketOpenSSL;
  LSigningKey: TBytes;
  LDate: TDateTime;
  L_methName:string;
begin
  L_methName:='TtwUploadFileThread.Execute';
  NameThreadForDebugging('S3_Upload_Thread');
  LrespCode:=0;
  LrespText:='';
  FResult := False;
  if Length(FObjectName) = 0 then
    LS := ExtractFileName(FLocalFileName)
  else
    LS := Trim(FObjectName);
  LObjectName := idEncodeS3FileName(LS);
    IdHTTP := TIdHTTP.Create(nil);
    IdSSL := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
    try
      ///
      FTWMngrRef.addAsyncItem(FUniqueID,Self);
      F_closethFlag:=False;
      ///
      IdHTTP.IOHandler := IdSSL;
      IdHTTP.ReadTimeout := 60000;
      IdSSL.SSLOptions.SSLVersions := [sslvTLSv1_2];
      IdSSL.SSLOptions.VerifyMode := [];

      F_FileStream := TFileStream.Create(FLocalFileName, fmOpenRead or fmShareDenyWrite);
      try
        LResourcePath := '/' + FTWMngrRef.bucket + '/' + LObjectName;
        LHost := FTWMngrRef.host;
        LPayloadHash := LowerCase(idGetStreamSHA2Hash(F_FileStream));
        if Terminated=False then
         begin
            F_FileStream.Position := 0;
            LDate := Now;
            ///
            LCanonicalRequest_Hash :=FTWMngrRef.calcCanonicalRequestHash(LDate, 'PUT', LResourcePath, LPayloadHash);
            LSigningKey :=FTWMngrRef.calcSignKeyBytes(LDate);
            LSignature :=FTWMngrRef.calcSignature(LDate, LCanonicalRequest_Hash, LSigningKey);
            LAuthHeader :=FTWMngrRef.getAuthHeader(LDate, LSignature);
            ///
            with IdHTTP.Request.CustomHeaders do
            begin
              Clear;
              AddValue('Authorization', LAuthHeader);
              AddValue('host', LHost);
              AddValue('x-amz-content-sha256', LPayloadHash);
              AddValue('x-amz-date', GetFormattedDate(LDate, true));
            end;

            // Для отслеживания прогресса используем событие OnWork/OnWorkBegin/OnWorkEnd
            IdHTTP.OnWork :=do_IdHTTPWork;
            IdHTTP.OnWorkBegin:=do_IdHTTPWorkBegin;
            IdHTTP.OnWorkEnd :=do_IdHTTPWorkEnd;
            LUrl := 'https://' + FTWMngrRef.host + LResourcePath;
            try
              LRespText := IdHTTP.Put(LUrl, F_FileStream);
              LrespCode:=IdHTTP.ResponseCode;
              if (Terminated=false) and (F_closethFlag=False) then
               begin
                  FResult :=(IdHTTP.ResponseCode=200);
               end;
            except on EAbort do
              begin
               // Exit; // Поток был прерван пользователем через Terminate. Просто выходим.
               if Assigned(FTWMngrRef) then
                    FTWMngrRef.errorHandler.HandleMess(L_methName,'break_th','nil')
               else
                  wLog('-',L_methName+':break_th');
              end;
              on E: Exception do
               begin
                 if Assigned(FTWMngrRef) then
                    FTWMngrRef.errorHandler.HandleError(L_methName+':PUT',E)
                 else wLogE(L_methName+'_PUT',E);
               end;
            end;
         end;
      finally
        F_FileStream.Free;
        F_FileStream:=nil;
      end;
    finally
     try
      IdHTTP.Free;
      IdSSL.Free;
      except on E:Exception do
        if Assigned(FTWMngrRef) then
                    FTWMngrRef.errorHandler.HandleError(L_methName+':Free_Error',E)
        else
          wLogE(L_methName+' Free Error',E);
     end;
      ///
      if Assigned(FTWMngrRef) then
         try
           if Assigned(FTWMngrRef.OnFinishLoading) then
            Synchronize(procedure
            begin
             FTWMngrRef.OnFinishLoading(FTWMngrRef,Ord(Ftwtype),FUniqueID,FResult,LrespCode,LRespText,nil);
            end);
         finally
           FTWMngrRef.removeAsyncItem(FUniqueID);
       end;
    end;
  if (Assigned(FTWMngrRef)) and (Assigned(FTWMngrRef.AfterTimeAllLoading)) then
   if (FTWMngrRef.AsyncItems.Count=0) then
      Synchronize(procedure
            begin
             FTWMngrRef.AfterTimeAllLoading(FTWMngrRef,True);
            end);
end;

///////////////////
///
///
{ TtwDownloadFileThread }

constructor TtwDownloadFileThread.Create(aTWMngrRef:TtimeWebS3Manager; const AObjectName, ALocalFilePath: string;
  AMemDataFlag: Boolean; AWindowHandle: HWND; AOnDownloadProgress: TtwProgressEvent);
var L_filePath:string;
begin
  inherited Create(True); // Создаем в приостановленном состоянии
  FreeOnTerminate := True; // Поток удалит себя сам после выполнения
  L_filePath:=ExtractFilePath(ALocalFilePath);
  setTwParams(ttw_DownloadFile,aTWMngrRef,L_filePath,AObjectName,AWindowHandle,AOnDownloadProgress);
  FMemDataFlag := AMemDataFlag;
  FResult := False;
end;

procedure TtwDownloadFileThread.Execute;
var
  LrespCode:integer;
  LS, L_fileName, L_destFileName, L_ResourcePath, L_host, L_url, LRespText: string;
  LPayloadHash, L_CanonicalRequest_Hash, L_Signature, L_authHeader: string;
  IdHTTP: TIdHTTP;
  IdSSL: TIdSSLIOHandlerSocketOpenSSL;
  L_SigningKey: TBytes;
  L_date: TDateTime;
  L_methName,L_errS:string;
begin
  L_methName:='TtwDownloadFileThread.Execute';
  NameThreadForDebugging('S3_Download_Thread');
  FResult := False;
  LrespCode:=0;
  LRespText:='';
  try
    FTWMngrRef.addAsyncItem(FUniqueID,Self);
    F_closethFlag:=False;
    // --- Подготовка ---
    LS := idDecodeS3FileName(FObjectName);
    L_fileName := LS; // Используем декодированное имя для сохранения
    IdHTTP := TIdHTTP.Create(nil);
    IdSSL := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
    IdHTTP.IOHandler := IdSSL;
    IdHTTP.ReadTimeout := 60000;
    IdSSL.SSLOptions.SSLVersions := [sslvTLSv1_2];
    IdSSL.SSLOptions.VerifyMode := [];
    if Length(FLocalFileName)>0 then
       L_destFileName := IncludeTrailingPathDelimiter(FLocalFileName) + L_fileName
    else L_destFileName :=L_fileName;
    if FMemDataFlag then
        F_FileStream := TMemoryStream.Create
    else
        F_FileStream := TFileStream.Create(L_destFileName, fmCreate);
      try
        // --- Подготовка данных ---
        L_ResourcePath := '/' + FTWMngrRef.bucket + '/' + FObjectName;
        L_host :=FTWMngrRef.Host;
        /// пустой строки
        LPayloadHash := LowerCase('e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
        L_date := Now;
        L_CanonicalRequest_Hash := FTWMngrRef.calcCanonicalRequestHash(L_date, 'GET', L_ResourcePath, LPayloadHash);
        L_SigningKey := FTWMngrRef.calcSignKeyBytes(L_date);
        L_Signature := FTWMngrRef.calcSignature(L_date, L_CanonicalRequest_Hash, L_SigningKey);
        L_authHeader := FTWMngrRef.getAuthHeader(L_date, L_Signature);
        // --- Настройка событий прогресса ---
        IdHTTP.OnWork := do_IdHTTPWork;
        IdHTTP.OnWorkBegin :=do_IdHTTPWorkBegin;
        IdHTTP.OnWorkEnd :=do_IdHTTPWorkEnd;
        // --- Отправка запроса ---
        with IdHTTP.Request.CustomHeaders do
        begin
          Clear;
          AddValue('Authorization', L_authHeader);
          AddValue('host', L_host);
          AddValue('x-amz-content-sha256', LPayloadHash);
          AddValue('x-amz-date', GetFormattedDate(L_date, true));
        end;

        L_url := 'https://' + FTWMngrRef.host + L_ResourcePath;
        try
          IdHTTP.Get(L_url, F_FileStream);
          // Проверка результата HTTP
          LrespCode:=IdHTTP.ResponseCode;
          LRespText:=IdHTTP.ResponseText;
          if LrespCode = 200 then
          begin
            // Если данные качались в память, сохраняем их в файл
            if FMemDataFlag then
            begin
              try
                TMemoryStream(F_FileStream).SaveToFile(L_destFileName);
              except
                on E: Exception do
                begin
                  wLogE('downloadFile - saveFile Error', E);
                  raise; // Пробрасываем исключение, чтобы оно попало в общий блок except и удалила файл ниже.
                end;
              end;
            end;
            FResult := True; // Успех!
          end
          else
           begin
            // raise Exception.CreateFmt('Ошибка HTTP %d', [IdHTTP.ResponseCode]);
            L_errS:=Format('code=%d, Mess=%s',[LrespCode,LRespText]);
            if Assigned(FTWMngrRef) then
                    FTWMngrRef.errorHandler.HandleMess(L_methName,'GET',L_errS)
                 else wLog('w',L_methName+'_GET : '+L_errS);
           end;
         except on EAbort do
              begin
               // Exit; // Поток был прерван пользователем через Terminate. Просто выходим.
               if Assigned(FTWMngrRef) then
                    FTWMngrRef.errorHandler.HandleMess(L_methName,'break_th','nil')
               else
                  wLog('-',L_methName+':break_th');
              end;
              on E: Exception do
               begin
                 if Assigned(FTWMngrRef) then
                    FTWMngrRef.errorHandler.HandleError(L_methName+':GET',E)
                 else wLogE(L_methName+'_GET',E);
               end;
        end
      finally
        F_FileStream.Free;
        F_FileStream:=nil;
      end;
    finally
      try
        IdHTTP.Free;
        IdSSL.Free;
        except on E:Exception do
                if Assigned(FTWMngrRef) then
                    FTWMngrRef.errorHandler.HandleError(L_methName+':Free_Error',E)
        else
          wLogE(L_methName+' Free Error',E);
     end;
      ///
      if Assigned(FTWMngrRef) then
       try
        if Assigned(FTWMngrRef.OnFinishLoading) then
          Synchronize(procedure
           begin
             FTWMngrRef.OnFinishLoading(FTWMngrRef,Ord(Ftwtype),FUniqueID,FResult,LrespCode,LRespText,nil);
           end);
        finally
         FTWMngrRef.removeAsyncItem(FUniqueID);
       end;
    end;
end;

// --- Реализация обработчиков событий Indy ---
procedure TtwDownloadFileThread.do_IdHTTPWork(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
var
  Progress: Integer;
begin
  if Terminated then
   begin
    F_closethFlag:=True;
    Abort; // Проверка на отмену
   end
  else
    if (AWorkMode = wmRead) and (TIdHTTP(ASender).Response.ContentLength > 0) then
    begin
      Progress := Round((AWorkCount / TIdHTTP(ASender).Response.ContentLength) * 100);
      DoProgress(Progress);
    end;
end;



end.
