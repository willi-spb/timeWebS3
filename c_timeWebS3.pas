unit c_timeWebS3;
 (*
  *   Компонент - менеджер отправки файлов и загрузки объектов S3 timeWeb.cloud
  *   (Реализация начиная с XE10.1 - использованы возможности Indy)
  *  Завистомости:  1. простой класс обработки ошибок u_errHandler
                    2. модуль логирования с использованием pipe - u_wCodeTrace
                    3. dlg_Mess - модуль диалога сообщения (альтернатива стандартному MessageDlg)
                    4. u_timeWebS3AsyncClasses - взаимосвязанный модуль потоковой заглузки-выгрузки
                       для чего добавлены методы и возможность управления несколькими потоками загрузки
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


uses System.Classes, System.SysUtils, System.Generics.Collections,
Winapi.Windows,
u_errHandler;


type
  TtimeWebS3ProgressEvent = procedure(Sender:TObject; aType:Integer; AThreadID:TGUID; AProgress: Integer) of object;

  TtimeFinishLoadingEvent=procedure(Sender:TObject; aType:Integer; AThreadID:TGUID;
    aSuccess:Boolean; aResCode:integer; const aResText:string; aData:TObject) of object;

  TAfterTimeAllLoadingEvent=procedure(Sender:TObject; aSuccess:Boolean) of object;


  TimeWebOperationType=(opf_Upload,opf_Download,opf_All);
  TimeWebOperationTypes=set of TimeWebOperationType;

  TtimeWebS3Manager = class(TComponent)
  private
    { Private declarations }
    FserviceName,FrequestName:string;
    Fbucket:string;
    FHost, FAccessKey, FSecretKey,FRegion:string;
    FAsyncItems:TDictionary<TGUID,TObject>;
    FdirectWindowHandle:HWND;
    FOnFilesProgressEvent:TtimeWebS3ProgressEvent;
    FerrorHandler:TErrorHandler;
    FdlgMessVisible:Boolean;
    FOnFinishLoading:TtimeFinishLoadingEvent;
    FAfterTimeAllLoading:TAfterTimeAllLoadingEvent;
  protected
    { Protected declarations }
     procedure do_FilesProgress(aSender:TObject; AProgress: Integer);
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure setReqParams(const aHost,aBucket,access_Key,secret_key,aRegion:string); virtual;
    function isEnabled:Boolean; virtual;
    ///
    function getScope(aDate:TDateTime):string; virtual;
    /// <summary>
    ///    ключ для кодирования
    /// </summary>
    function calcSignKeyBytes(aDate:TDateTime):TBytes; virtual;
    /// <summary>
    ///    ключ для кодирования
    /// </summary>
    function calcCanonicalRequestHash(aDate:TDateTime; const ahttpMethod,aResourcePath,aPayloadHash: string):string; virtual;
    function getStringToSign(aDate:TDateTime; const aCanonicalRequestHash:string):string; virtual;
    /// <summary>
    ///     подпись после вычисления ключа и кононического url
    /// </summary>
    function calcSignature(aDate:TDateTime; const aCanonicalRequestHash:string; aSignKey:TBytes):string; virtual;
    /// <summary>
    ///     соединить в заголовок авторизации
    /// </summary>
    function getAuthHeader(aDate:TDateTime; const aSignature:string; aRegime:Integer=1):string; virtual;
    ///
    ///
    function uploadFile(aLocalFileName,aObjectAltName:string):Boolean; virtual;
    /// <summary>
    ///
    /// </summary>
    function downloadFile(aObjectName,aLocalFilePath:string; aMemDataFlag:Boolean=false):Boolean; virtual;
    /// <summary>
    ///       добавление в список птоков нового
    /// </summary>
    function addAsyncItem(aGUID:TGUID; aRef:TObject):Boolean;
    /// <summary>
    ///       удаление из списка потоков
    /// </summary>
    function removeAsyncItem(aGUID:TGUID):Boolean;
    function getAsyncItemForID(aGUID:TGUID):TObject;
    function getAsyncItemForString(const aGUIDStr:string):TObject;
    function getAsyncItemCount(aOperations:TimeWebOperationTypes=[opf_All]):Integer;
    /// <summary>
    ///    прервать выполенение потока
    /// </summary>
    function cancelAsyncItemForString(const aGUIDStr:string):Boolean;
    /// <summary>
    ///    прервать выполенение всех потоков
    /// </summary>
    function abortAsyncItems(aOperations:TimeWebOperationTypes=[opf_All]; abreakRg:Integer=1):Boolean;
    /// <summary>
    ///    загрузка файла в хранилище - в потоке
    /// </summary>
    function uploadFileAsync(aLocalFileName,aObjectAltName:string; AWindowHandle:HWND):TGUID; virtual;
    /// <summary>
    ///   выгрузка файла из хранилища - в потоке
    /// </summary>
    function downloadFileAsync(aObjectName,aLocalFilePath:string; AWindowHandle:HWND; aMemDataFlag:Boolean=false):TGUID; virtual;
    ///
    /// <summary>
    ///    использовать один ОБЩИЙ Хендл окна для вывода сообщений - если этот параметр не задан при запуске потока
    /// </summary>
    property directWindowHandle:HWND read FdirectWindowHandle write FdirectWindowHandle;
    ///
    property serviceName:string read FserviceName;
    property requestName:string read FrequestName;
    property bucket:string read Fbucket;
    property Host:string read FHost;
    property AccessKey:string read FAccessKey;
    property SecretKey:string read FSecretKey;
    property Region:string read FRegion;
    ///
    /// <summary>
    ///     обработчик ошибок - от режима
    /// </summary>
    property errorHandler:TErrorHandler read FerrorHandler;
    /// <summary>
    ///     показывать сообщения в случае ошибок или нет
    /// </summary>
    property dlgMessVisible:Boolean read FdlgMessVisible write FdlgMessVisible;
    ///
    property AsyncItems:TDictionary<TGUID,TObject> read FAsyncItems;
    /// <summary>
    ///     событие в прогрессе закачки-выгрузки - процент и ID потока
    /// </summary>
    property OnFilesProgressEvent:TtimeWebS3ProgressEvent read FOnFilesProgressEvent write FOnFilesProgressEvent;
    /// <summary>
    ///    событие при завершении (всегда) потока
    /// </summary>
    property OnFinishLoading:TtimeFinishLoadingEvent read FOnFinishLoading write FOnFinishLoading;
    /// <summary>
    ///    при завершении всех активных ранее потоков 1 раз
    /// </summary>
    property AfterTimeAllLoading:TAfterTimeAllLoadingEvent read FAfterTimeAllLoading write FAfterTimeAllLoading;
  published
    { Published declarations }
  end;

function idEncodeS3FileName(const aFileName: string): string;
function idDecodeS3FileName(const aEncodedFileName: string): string;
function idGetFileSHA2Hash(const FileName: string): string;
function idGetStreamSHA2Hash(aStr:TStream): string;
/// <summary>
///    строки даты
/// </summary>
function GetFormattedDate(aDt:TDatetime; aFullFlag:Boolean): string;
///
function HMAC_SHA256_Bytes(const Key, Data: TBytes): TBytes;

//procedure Register;
implementation

  uses System.Hash,           // Для SHA-256 и HMAC (в XE10.1 они есть)
  System.DateUtils,      // Для работы с датой
  System.StrUtils,
  Vcl.Dialogs, Vcl.Forms, Vcl.Controls,
  System.NetEncoding,
  IdGlobal,
  IdURI,
  IdHTTP,             // Компонент TIdHTTP
  IdSSLOpenSSL,       // Для работы с HTTPS (обязательно!)
  ///
  IdHashSHA, IdHashMessageDigest,
  ///
  ///  логирование и диалог сообщений
  u_wCodeTrace, dlg_Mess,
  ///
  u_timeWebS3AsyncClasses;
  ///

{
procedure Register;
begin
  RegisterComponents('Samples', [TtimeWebS3Manager]);
end;
 }

function idEncodeS3FileName(const aFileName: string): string;
  begin
   Result := TIdURI.ParamsEncode(aFileName,IndyTextEncoding_UTF8);
  end;

function idDecodeS3FileName(const aEncodedFileName: string): string;
begin
  Result := TIdURI.URLDecode(aEncodedFileName,IndyTextEncoding_UTF8);
end;

function idGetFileSHA2Hash(const FileName: string): string;
var
  SHA2: TIdHashSHA256; // или TIdHashSHA512 и т. д.
  FileStream: TFileStream;
begin
  SHA2 := TIdHashSHA256.Create;
  try
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    try
      // Indy умеет хешировать потоки напрямую
      Result := SHA2.HashStreamAsHex(FileStream);
    finally
      FileStream.Free;
    end;
  finally
    SHA2.Free;
  end;
end;

function idGetStreamSHA2Hash(aStr:TStream): string;
var
  SHA2: TIdHashSHA256; // или TIdHashSHA512 и т. д.
begin
  SHA2 := TIdHashSHA256.Create;
  try
   aStr.Seek(0,0);
   // Indy умеет хешировать потоки напрямую
   Result := SHA2.HashStreamAsHex(aStr);
   finally
    SHA2.Free;
  end;
end;

function idGetFileSHA256(const FileName: string): string;
const
  BufferSize = 1024 * 1024; // Читаем файл кусками по 1 МБ
var
  SHA256: TIdHashSHA256;
  FileStream: TFileStream;
  MemoryStream: TMemoryStream;
  Buffer: TBytes;
  BytesRead: Integer;
begin
  Result := '';
  SHA256 := TIdHashSHA256.Create;
  MemoryStream := TMemoryStream.Create;
  try
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    try
      SetLength(Buffer, BufferSize);
      // Читаем файл и пишем его содержимое в MemoryStream
      repeat
        BytesRead := FileStream.Read(Buffer[0], BufferSize);
        if BytesRead > 0 then
          MemoryStream.WriteBuffer(Buffer[0], BytesRead);
      until BytesRead < BufferSize;

      // Сбрасываем позицию потока на начало перед хешированием
      MemoryStream.Position := 0;

      // Хешируем весь поток целиком.
      // В старых версиях Indy есть перегрузка для TStream.
      Result := SHA256.HashStreamAsHex(MemoryStream);
    finally
      FileStream.Free;
    end;
  finally
    MemoryStream.Free;
    SHA256.Free;
  end;
end;

// Функция для получения даты в формате AWS
function GetFormattedDate(aDt:TDatetime; aFullFlag:Boolean): string;
begin
  // Формат: YYYYMMDD'T'HHMMSS'Z'
  if aFullFlag then
  //  Result := FormatDateTime('yyyymmdd"\T"hhnnss"Z"', TTimeZone.Local.ToUniversalTime(Now))
    Result := FormatDateTime('yyyymmdd"T"hhnnss"Z"', TTimeZone.Local.ToUniversalTime(aDt))
  else
    Result := FormatDateTime('yyyymmdd',TTimeZone.Local.ToUniversalTime(aDt));
end;

function HMAC_SHA256_Bytes(const Key, Data: TBytes): TBytes;
begin
  Result :=THashSHA2.GetHMACAsBytes(Data, Key, SHA256);
end;

//////////////////////////////////////////////////////////////////////
///
///
{ TtimeWebS3Manager }

function TtimeWebS3Manager.abortAsyncItems(aOperations:TimeWebOperationTypes; abreakRg: Integer): Boolean;
var L_Pair:TPair<TGUID,TObject>;
    L_op:TimeWebOperationTypes;
begin
 Result:=false;
 L_op:=aOperations;
 ///
 ///  недоделал выбор по типу потоков
 ///
  for L_Pair in FAsyncItems do
    begin
     if L_Pair.Value is TtwThread then
       with L_Pair.Value as TtwThread do
         try
            TtwThread(L_Pair.Value).Terminate;
            Result:=True;
             except on E:Exception do
               wLogE('TtimeWebS3Manager.abortAsyncItems th='+GUIDToString(L_Pair.Key),E);
         end;
     end;
  FAsyncItems.Clear;
end;

function TtimeWebS3Manager.addAsyncItem(aGUID: TGUID; aRef: TObject): Boolean;
begin
  Result:=false;
  if (FAsyncItems.ContainsKey(aGUID)=false) then
   begin
      FAsyncItems.Add(aGUID,aRef);
      Result:=True;
   end;
end;

function TtimeWebS3Manager.calcCanonicalRequestHash(aDate:TDateTime; const ahttpMethod,aResourcePath,aPayloadHash: string):string;
var L_CanonicalRequest:string;
begin
  // ahttpMethod= PUT
   L_CanonicalRequest :=
      UpperCase(ahttpMethod) + #10 + // HTTP Verb
      aResourcePath +  #10 + // Canonical URI
      '' +  #10 + // Canonical Query String (пусто)
    //  'host:s3.timeweb.cloud' + #10 +
     'host:'+Fhost+ #10 +
      'x-amz-content-sha256:' + aPayloadHash + #10 +
      'x-amz-date:' + GetFormattedDate(adate,True) + #10 +
      '' + #10 + // Пустая строка отделяет заголовки от списка подписанных заголовков
      'host;x-amz-content-sha256;x-amz-date' + #10 +
      aPayloadHash; // Hash of the payload
    // --- Шаг 2: Формируем String To Sign ---
    Result:=THashSHA2.GetHashString(UTF8Encode(L_CanonicalRequest));
end;

function TtimeWebS3Manager.calcSignature(aDate:TDateTime; const aCanonicalRequestHash:string; aSignKey:TBytes): string;
var L_StringToSign,L_Scope:string;
    L_SignatureBytes:TBytes;
begin
  L_StringToSign :='AWS4-HMAC-SHA256' + #10 +GetFormattedDate(aDate,true) + #10+getScope(aDate)+#10+aCanonicalRequestHash;
  // --- Шаг 4: Вычисляем итоговую подпись ---
  // Signature := THash.DigestAsString(HMACSHA256ToBytes(UTF8Encode(StringToSign), SigningKey));
  // Вычисляем HMAC-SHA256 от строки для подписи с помощью SigningKey
  L_SignatureBytes := HMAC_SHA256_Bytes(aSignKey, TEncoding.UTF8.GetBytes(L_StringToSign));
  // Преобразуем результат в шестнадцатеричную строку (нижний регистр)
   Result:=THash.DigestAsString(L_SignatureBytes).ToLower;
end;

function TtimeWebS3Manager.calcSignKeyBytes(aDate:TDateTime): TBytes;
var L_Key, L_DateKey, L_RegionKey, L_ServiceKey: TBytes;
begin
  L_Key := TEncoding.UTF8.GetBytes('AWS4' + FSecretKey);
  L_DateKey := HMAC_SHA256_Bytes(L_Key, TEncoding.UTF8.GetBytes(GetFormattedDate(aDate,false)));
  L_RegionKey := HMAC_SHA256_Bytes(L_DateKey, TEncoding.UTF8.GetBytes(FRegion));
  L_ServiceKey := HMAC_SHA256_Bytes(L_RegionKey, TEncoding.UTF8.GetBytes(FserviceName));
  Result:= HMAC_SHA256_Bytes(L_ServiceKey, TEncoding.UTF8.GetBytes(FrequestName));
end;

function TtimeWebS3Manager.cancelAsyncItemForString(
  const aGUIDStr: string): Boolean;
var L_ob:TObject;
begin
  Result:=False;
  L_ob:=getAsyncItemForString(aGUIDStr);
  if (L_ob<>nil) and (L_ob is TtwThread) then
   with L_ob as TtwThread do
    try
         Terminate;
      Result:=True;
      ///
     except on E:Exception do
       FerrorHandler.HandleError('TtimeWebS3Manager.cancelAsyncItemForString',E);
    end;
end;

constructor TtimeWebS3Manager.Create(AOwner: TComponent);
begin
  inherited;
 ///
 ///  uses IdSSLOpenSSLHeaders, /// нужно загрузить ssl библиотеки dll
 ///
 /// важно - вызывайте 1 раз -  IdSSLOpenSSLHeaders.Load;
 ///
 ///  либо используйте модуль u_SSLLoader;
 ///
  FAsyncItems:=TDictionary<TGUID,TObject>.Create(0);
  ///
  FserviceName:='s3';
  FrequestName:='aws4_request';
  FHost:='s3.twcstorage.ru';
  ///
  if AOwner is TWinControl then
    FdirectWindowHandle:=TWinControl(AOwner).Handle
  else
    FdirectWindowHandle:=0;
  FerrorHandler:=TErrorHandler.Create(erLogAndCollect);
  FdlgMessVisible:=True;
end;

destructor TtimeWebS3Manager.Destroy;
var il:integer;
    L_Pair:TPair<TGUID,TObject>;
begin
  il:=0;
  while (FAsyncItems.Count>0) and (il<30) do
   begin
     if abortAsyncItems([opf_All]) then ;
     if (FAsyncItems.Count>0) then
       begin
         Application.ProcessMessages;
         Sleep(1000);
         Inc(il);
       end;
   end;
   FreeAndNil(FAsyncItems);
   FreeAndNil(FerrorHandler);
  inherited;
end;

function TtimeWebS3Manager.downloadFileAsync(aObjectName, aLocalFilePath: string;
  AWindowHandle: HWND; aMemDataFlag: Boolean): TGUID;
var L_th:TtwDownloadFileThread;
    L_h:HWND;
begin
  if AWindowHandle=0 then
     L_h:=FdirectWindowHandle;
  L_th:=TtwDownloadFileThread.Create(Self,aObjectName,aLocalFilePath,aMemDataFlag,L_h,do_FilesProgress);
  Result:=L_th.UniqueID;
  L_th.Start;
end;

procedure TtimeWebS3Manager.do_FilesProgress(aSender:TObject; AProgress: Integer);
var L_Guid:TGUID;
    L_sign:integer;
begin
  if (Assigned(aSender)) and (Assigned(FOnFilesProgressEvent)) then
   begin
    with aSender as TtwThread do
     begin
       L_Guid:=UniqueID;
       L_sign:=Ord(twtype);
       FOnFilesProgressEvent(Self,L_sign,L_Guid,AProgress);
     end;
   end;
end;

function TtimeWebS3Manager.downloadFile(aObjectName,
  aLocalFilePath: string; aMemDataFlag:Boolean): Boolean;
var LS,L_fileName,L_destFileName,L_ResourcePath,L_host,L_url:string;
    LPayloadHash,L_CanonicalRequest_Hash,L_Signature,L_authHeader:string;
    IdHTTP: TIdHTTP;
    IdSSL: TIdSSLIOHandlerSocketOpenSSL;
    LFileStream:TStream;
    L_SigningKey:TBytes;
    L_date:TDateTime;
    L_MethName:string;
begin
  L_MethName:='TtimeWebS3Manager.downloadFile';
  L_fileName:=idDecodeS3FileName(aObjectName);
 ///
   Result:=False;
  // Инициализация компонентов
  IdHTTP := TIdHTTP.Create(nil);
  IdSSL := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  IdHTTP.IOHandler := IdSSL;
  IdHTTP.ReadTimeout := 60000;
  // Настройка SSL/TLS для работы с современным шифрованием
  //  IdSSL.SSLOptions.Method := sslvTLSv1_2;
  IdSSL.SSLOptions.SSLVersions := [sslvTLSv1_2];
  IdSSL.SSLOptions.VerifyMode :=[];//  [sslvrfPeer]; // Аутентификация
  L_destFileName:=aLocalFilePath+L_Filename;
  if aMemDataFlag then
     LFileStream := TMemoryStream.Create
  else
     LFileStream := TFileStream.Create(L_destFileName, fmCreate);
  try
    // --- Подготовка данных ---
    L_ResourcePath := '/' + Fbucket + '/' + aObjectName;
    L_host:=FHost;
    // Хэш пустой строки
    LPayloadHash :=LowerCase('e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
    /// именно тут выставим дату время
    L_date:=Now; // !
    ///
    // --- Шаг 1: Формируем Canonical Request ---
    L_CanonicalRequest_Hash:=calcCanonicalRequestHash(L_date,'GET',L_ResourcePath,LPayloadHash);
    // --- Шаг 3: Вычисляем Signing Key ---
    L_SigningKey:=calcSignKeyBytes(L_date);
    // --- Шаг 4: Вычисляем итоговую подпись ---
    L_Signature :=calcSignature(L_date,L_CanonicalRequest_Hash,L_SigningKey);
    // --- Шаг 5: Формируем заголовок Authorization ---
    L_authHeader:=getAuthHeader(L_date,L_Signature);
    // --- Шаг 6: Отправка запроса ---
    try
     with IdHTTP.Request.CustomHeaders do
      begin
        Clear;
        AddValue('Authorization', L_authHeader);
        AddValue('host', L_Host);
        AddValue('x-amz-content-sha256', LPayloadHash);
        AddValue('x-amz-date',GetFormattedDate(L_date,true));
      end;
      L_url:='https://'+FHost + L_ResourcePath;
      IdHTTP.Get(L_url,LFileStream);
      Result:=(IdHTTP.ResponseCode=200);
      if (Result) and (aMemDataFlag) then
       try
         TMemoryStream(LFileStream).SaveToFile(L_destFileName);
         except on E:Exception do
          begin
           FerrorHandler.HandleError(L_MethName+':saveFileERROR',E);
           if FdlgMessVisible then
            MessMngr.MessDlg(nil,'Ошибка записи файла','файл:'+L_destFileName+#13#10+E.ClassName+' : '+E.Message,mdtInfo,[mbnOk],1);
          end;
       end;
    except
      on E: EIdHTTPProtocolException do
       begin
         FerrorHandler.HandleError(L_MethName,E);
         if FdlgMessVisible then
            MessMngr.MessDlg(nil,'Ошибка протокола S3',E.ClassName+' : '+E.Message,mdtInfo,[mbnOk],1);
       end;
      on E: Exception do
       begin
         FerrorHandler.HandleError(L_MethName,E);
         if FdlgMessVisible then
            MessMngr.MessDlg(nil,'Ошибка сети S3',E.Message,mdtInfo,[mbnOk],1); // Показывает XML-ошибку от сервера (например, InvalidAccessKeyId)
       end;
    end;
  finally
    LFileStream.Free;
    IdHTTP.Free;
    IdSSL.Free;
  end;
  if (Result=false) and (FileExists(L_destFileName)) then
   try
    System.SysUtils.DeleteFile(L_destFileName);
    except on E:Exception do
       FerrorHandler.HandleError(L_MethName+':'+'DeleteFile_Error',E);
   end;
end;

function TtimeWebS3Manager.getAsyncItemCount(
  aOperations: TimeWebOperationTypes): Integer;
  var L_Pair:TPair<TGUID,TObject>;
    L_op:TimeWebOperationTypes;
begin
 Result:=0;
 L_op:=aOperations;
  for L_Pair in FAsyncItems do
    begin
     if L_Pair.Value is TtwThread then
       with L_Pair.Value as TtwThread do
         begin
            if (opf_All in L_op) or ((twtype=ttw_UploadFile) and (opf_Upload in L_op)) or
               ((twtype=ttw_UploadFile) and (opf_Download in L_op)) then
              Inc(Result);
         end;
     end;
end;

function TtimeWebS3Manager.getAsyncItemForID(aGUID: TGUID): TObject;
begin
  Result:=nil;
  if FAsyncItems.ContainsKey(aGUID) then
     Result:=FAsyncItems.Items[aGUID];
end;

function TtimeWebS3Manager.getAsyncItemForString(
  const aGUIDStr: string): TObject;
var LGuid:TGUID;
begin
  Result:=nil;
   try
    LGuid:=StringToGUID(aGUIDStr);
    if FAsyncItems.ContainsKey(LGUID) then
       Result:=FAsyncItems.Items[LGUID];
  except
    on E: EConvertError do
     FerrorHandler.HandleError('TtimeWebS3Manager.getAsyncItemForString'+':str_not_GUID',E);
  end;
end;

function TtimeWebS3Manager.getAuthHeader(aDate:TDateTime; const aSignature:string; aRegime:Integer):string;
begin
  Result:='AWS4-HMAC-SHA256 ' +
      'Credential=' + FAccessKey + '/' + getScope(aDate) + ', ' +
      'SignedHeaders=host;x-amz-content-sha256;x-amz-date, ' +
     // 'SignedHeaders=host;range;x-amz-date, ' +
      'Signature=' + aSignature;
end;

function TtimeWebS3Manager.getScope(aDate:TDateTime): string;
begin
  Result:=GetFormattedDate(aDate,false)+ '/' + FRegion + '/'+FserviceName+'/'+FrequestName;
end;

function TtimeWebS3Manager.getStringToSign(aDate:TDateTime; const aCanonicalRequestHash:string): string;
begin
  Result:='AWS4-HMAC-SHA256' + #10+GetFormattedDate(aDate,true)+#10+getScope(aDate)+#10+aCanonicalRequestHash;
end;


function TtimeWebS3Manager.isEnabled: Boolean;
begin
  Result:=(Length(Fbucket)>5) and (Length(FAccessKey)>0) and (Length(FSecretKey)>10) and (Length(FHost)>6) and (Length(FRegion)>0);
end;

function TtimeWebS3Manager.removeAsyncItem(aGUID: TGUID): Boolean;
begin
  Result:=false;
  if (FAsyncItems.ContainsKey(aGUID)) then
   try
      FAsyncItems.Remove(aGUID);
      Result:=True;
    except on E:Exception do
      FerrorHandler.HandleError('removeAsyncItem',E);
   end;
end;

procedure TtimeWebS3Manager.setReqParams(const aHost,aBucket, access_Key,
  secret_key,aRegion: string);
begin
  Fbucket:=aBucket;
  FAccessKey:=access_Key;
  FSecretKey:=secret_key;
  if Length(aHost)>1 then
     FHost:=aHost;
  if Length(aRegion)>1 then
     FRegion:=aRegion;
end;

function TtimeWebS3Manager.uploadFile(aLocalFileName,
  aObjectAltName: string): Boolean;
var LS,L_objectName,L_ResourcePath,L_host,L_url,LRespText:string;
    LPayloadHash,L_CanonicalRequest_Hash,L_Signature,L_authHeader:string;
    IdHTTP: TIdHTTP;
    IdSSL: TIdSSLIOHandlerSocketOpenSSL;
    LFileStream:TFileStream;
    L_SigningKey:TBytes;
    L_date:TDateTime;
    L_MethName:string;
begin
  L_MethName:='TtimeWebS3Manager.uploadFile';
  if Length(aObjectAltName)=0 then LS:=ExtractFileName(aLocalFileName)
  else LS:=Trim(aObjectAltName);
  L_objectName:=idEncodeS3FileName(LS);
 ///
   Result:=False;
  // Инициализация компонентов
  IdHTTP := TIdHTTP.Create(nil);
  IdSSL := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  IdHTTP.IOHandler := IdSSL;
  IdHTTP.ReadTimeout := 60000;
  // Настройка SSL/TLS для работы с современным шифрованием
  //  IdSSL.SSLOptions.Method := sslvTLSv1_2;
  IdSSL.SSLOptions.SSLVersions := [sslvTLSv1_2];
  IdSSL.SSLOptions.VerifyMode :=[];//  [sslvrfPeer]; // Аутентификация
  LFileStream := TFileStream.Create(aLocalFileName, fmOpenRead or fmShareDenyWrite);
  try
    // --- Подготовка данных ---
    L_ResourcePath := '/' + Fbucket + '/' + L_ObjectName;
    L_host:=FHost;
    // Хэш тела запроса (полезной нагрузки). Считаем его один раз для подписи и для заголовка.
    LPayloadHash :=LowerCase(idGetStreamSHA2Hash(LFileStream));
   ///// LPayloadHash :=LowerCase(idGetFileSHA2Hash(aLocalFileName));
    // Сбрасываем позицию потока для реальной отправки
    LFileStream.Position := 0;
    /// именно тут выставим дату время
    L_date:=Now; // !
    ///
    // --- Шаг 1: Формируем Canonical Request ---
    L_CanonicalRequest_Hash:=calcCanonicalRequestHash(L_date,'PUT',L_ResourcePath,LPayloadHash);
    // --- Шаг 3: Вычисляем Signing Key ---
    L_SigningKey:=calcSignKeyBytes(L_date);
    // --- Шаг 4: Вычисляем итоговую подпись ---
    L_Signature :=calcSignature(L_date,L_CanonicalRequest_Hash,L_SigningKey);
    // --- Шаг 5: Формируем заголовок Authorization ---
    L_authHeader:=getAuthHeader(L_date,L_Signature);
    // --- Шаг 6: Отправка запроса ---
    try
       with IdHTTP.Request.CustomHeaders do
      begin
        Clear;
        AddValue('Authorization', L_authHeader);
        AddValue('host', L_Host);
        AddValue('x-amz-content-sha256', LPayloadHash);
        AddValue('x-amz-date',GetFormattedDate(L_date,true));
      end;
      L_url:='https://'+FHost + L_ResourcePath;
      LRespText:=IdHTTP.Put(L_url,LFileStream);
      if (IdHTTP.Response.ContentStream<>nil) and (IdHTTP.Response.ContentStream.Size>0) then
         begin
          { L_Str:=TFileStream.Create('ggg.txt',fmCreate);
           L_Str.CopyFrom(IdHTTP.Response.ContentStream, IdHTTP.Response.ContentStream.Size);
           L_Str.Free;
           }
         end;
     // ShowMessage('Загрузка файла! Код ответа: ' + IntToStr(IdHTTP.ResponseCode)+' ответ '+LRespText+#13#10+IdHTTP.Response.ContentEncoding);
      Result:=(IdHTTP.ResponseCode=200);
    except
      on E: EIdHTTPProtocolException do
       begin
         FerrorHandler.HandleError(L_MethName,E);
         if FdlgMessVisible then
            MessMngr.MessDlg(nil,'Ошибка протокола S3',E.ClassName+' : '+E.Message,mdtInfo,[mbnOk],1);
       end;
      on E: Exception do
       begin
        FerrorHandler.HandleError(L_MethName,E);
        if FdlgMessVisible then
           MessMngr.MessDlg(nil,'Ошибка сети S3',E.Message,mdtInfo,[mbnOk],1); // Показывает XML-ошибку от сервера (например, InvalidAccessKeyId)
       end;
    end;
  finally
    LFileStream.Free;
    IdHTTP.Free;
    IdSSL.Free;
  end;
end;



function TtimeWebS3Manager.uploadFileAsync(aLocalFileName,
  aObjectAltName: string; AWindowHandle:HWND): TGUID;
var L_th:TtwUploadFileThread;
    L_h:HWND;
begin
  if AWindowHandle=0 then
     L_h:=FdirectWindowHandle;
  L_th:=TtwUploadFileThread.Create(Self,aLocalFileName, aObjectAltName,L_h,do_FilesProgress);
  Result:=L_th.UniqueID;
  L_th.Start;
end;

end.
