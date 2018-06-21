{ ***************************************************************************

  Copyright (c) 2016-2018 Kike P�rez

  Unit        : Quick.Logger.Provider.Email
  Description : Log Email Provider
  Author      : Kike P�rez
  Version     : 1.24
  Created     : 15/10/2017
  Modified    : 21/06/2018

  This file is part of QuickLogger: https://github.com/exilon/QuickLogger

 ***************************************************************************

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

 *************************************************************************** }

unit Quick.Logger.Provider.Email;

{$i QuickLib.inc}

interface

uses
  Classes,
  SysUtils,
  Quick.Commons,
  Quick.SMTP,
  Quick.Logger;

type

  TSMTPConfig = class
  private
    fHost : string;
    fUserName : string;
    fPassword : string;
    fUseSSL : Boolean;
  public
    property Host : string read fHost write fHost;
    property UserName : string read fUserName write fUserName;
    property Password : string read fPassword write fPassword;
    property UseSSL : Boolean read fUseSSL write fUseSSL;
  end;

  TMailConfig = class
  private
    fSenderName : string;
    fFrom : string;
    fRecipient : string;
    fSubject : string;
    fBody : string;
    fCC : string;
    fBCC : string;
    fBodyFromFile : Boolean;
  public
    property SenderName : string read fSenderName write fSenderName;
    property From : string read fFrom write fFrom;
    property Recipient : string read fRecipient write fRecipient;
    property Subject : string read fSubject write fSubject;
    property Body : string read fBody write fBody;
    property CC : string read fCC write fCC;
    property BCC : string read fBCC write fBCC;
  end;

  TLogEmailProvider = class (TLogProviderBase)
  private
    fSMTP : TSMTP;
    fMail : TMailMessage;
    fSMTPConfig : TSMTPConfig;
    fMailConfig : TMailConfig;
  public
    constructor Create; override;
    destructor Destroy; override;
    property SMTP : TSMTPConfig read fSMTPConfig write fSMTPConfig;
    property Mail : TMailConfig read fMailConfig write fMailConfig;
    procedure Init; override;
    procedure Restart; override;
    procedure WriteLog(cLogItem : TLogItem); override;
  end;

var
  GlobalLogEmailProvider : TLogEmailProvider;

implementation

constructor TLogEmailProvider.Create;
begin
  inherited;
  LogLevel := LOG_ALL;
  fSMTPConfig := TSMTPConfig.Create;
  fMailConfig := TMailConfig.Create;
  fSMTP := TSMTP.Create;
  IncludedInfo := [iiAppName,iiHost,iiUserName,iiOSVersion];
end;

destructor TLogEmailProvider.Destroy;
begin
  fMail := nil;
  if Assigned(fSMTP) then fSMTP.Free;
  if Assigned(fSMTPConfig) then fSMTPConfig.Free;
  if Assigned(fMailConfig) then fMailConfig.Free;
  inherited;
end;

procedure TLogEmailProvider.Init;
begin
  inherited;
  fSMTP.Host := fSMTPConfig.fHost;
  fSMTP.Username := fSMTPConfig.fUserName;
  fSMTP.Password := fSMTPConfig.Password;
  fSMTP.UseSSL := fSMTPConfig.fUseSSL;
  fSMTP.Mail.SenderName := fMailConfig.SenderName;
  fSMTP.Mail.From := fMailConfig.From;
  fSMTP.Mail.Recipient := fMailConfig.Recipient;
  fSMTP.Mail.Subject := fMailConfig.Subject;
  fSMTP.Mail.Body := fMailConfig.Body;
  fSMTP.Mail.CC := fMailConfig.CC;
  fSMTP.Mail.BCC := fMailConfig.BCC;
end;

procedure TLogEmailProvider.Restart;
begin
  Stop;
  Init;
end;

procedure TLogEmailProvider.WriteLog(cLogItem : TLogItem);
var
  subject : string;
begin
  if fSMTP.Mail.Subject = '' then fSMTP.Mail.Subject := Format('%s [%s] %s',[SystemInfo.AppName,EventTypeName[cLogItem.EventType],Copy(cLogItem.Msg,1,50)]);

  if CustomMsgOutput then fSMTP.Mail.Body := cLogItem.Msg
    else fSMTP.Mail.Body := LogItemToHtml(cLogItem);

  fSMTP.SendMail;
end;

initialization
  GlobalLogEmailProvider := TLogEmailProvider.Create;

finalization
  if Assigned(GlobalLogEmailProvider) and (GlobalLogEmailProvider.RefCount = 0) then GlobalLogEmailProvider.Free;

end.
