program ReceiveSms;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Ozeki.Libs.Rest in '../Ozeki.Libs.Rest/Ozeki.Libs.Rest.pas';

var configuration : Ozeki.Libs.Rest.Configuration;
var api : Ozeki.Libs.Rest.MessageApi;
var result : MessageReceiveResult;
var message : Ozeki.Libs.Rest.Message;
var read : string;

begin
  try
    configuration := Ozeki.Libs.Rest.Configuration.Create;
    configuration.Username := 'http_user';
    configuration.Password := 'qwe123';
    configuration.ApiUrl := 'http://127.0.0.1:9509/api';

    api := Ozeki.Libs.Rest.MessageApi.Create(configuration);

    result := api.DownloadIncoming;

    Writeln(result.ToString);

    for message in result.Messages do
    begin
      Writeln(message.ToString);
    end;

    Readln(read);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
