unit u_errHandler;
 (*
  *  Простой класс-обработчик ошибок - подразумевает достраивание
  *
  *  Зависимости: u_wCodeTrace - модуль логирования
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

uses
  System.Classes, System.SysUtils;

type
  TErrorRegime = (erLogOnly, erCollect, erLogAndCollect);

  TErrorHandler = class
  private
    FErrorList: TStringList;
    FErrorRegime: TErrorRegime;
    procedure AddToErrorList(const AErrorPlace,AErrorType, AMessage: string);
  public
    constructor Create(ARegime: TErrorRegime);
    destructor Destroy; override;
    procedure HandleError(const AErrorPlace: string; E: Exception);
    procedure HandleMess(const AErrorPlace,AErrorName,AErrorMess: string);
    property ErrorList: TStringList read FErrorList;
    property ErrorRegime: TErrorRegime read FErrorRegime write FErrorRegime;
  end;

implementation

 uses u_wCodeTrace;
{ TErrorHandler }

constructor TErrorHandler.Create(ARegime: TErrorRegime);
begin
  inherited Create;
  FErrorRegime := ARegime;
  FErrorList := TStringList.Create;
end;

destructor TErrorHandler.Destroy;
begin
  FErrorList.Free;
  inherited;
end;

procedure TErrorHandler.AddToErrorList(const AErrorPlace,AErrorType, AMessage: string);
var LS:string;
begin
  if Length(AErrorPlace)>0 then
     LS:=Format('%s: [%s] %s', [AErrorPlace,AErrorType, AMessage])
  else
     LS:=Format('0[%s] %s', [AErrorType, AMessage]);
  FErrorList.Add(LS);
end;

procedure TErrorHandler.HandleError(const AErrorPlace: string; E: Exception);
var
 L_exName,L_exText: string;
begin
 if E<>nil then
  begin
   L_exName:=E.ClassName;
   L_exText:=E.Message;
  end
 else
   begin
    L_exName:='';
    L_exText:='';
   end;
 HandleMess(AErrorPlace,L_exName,L_exText);
end;

procedure TErrorHandler.HandleMess(const AErrorPlace, AErrorName,
  AErrorMess: string);
var LMsg: string;
begin
   if Length(AErrorPlace)>0 then
      LMsg := Format('%s: [%s] %s', [AErrorPlace,AErrorName,AErrorMess])
   else
      LMsg := Format('[%s] %s', [AErrorName,AErrorMess]);
   if FErrorRegime in [erCollect, erLogAndCollect] then
      AddToErrorList(AErrorPlace,AErrorName,AErrorMess);
  ///
  if FErrorRegime in [erLogOnly, erLogAndCollect] then
    wLog('e',LMsg);
end;

end.
