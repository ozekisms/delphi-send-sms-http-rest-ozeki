program SendSms;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Ozeki.Libs.Rest in '../Ozeki.Libs.Rest/Ozeki.Libs.Rest.pas';

var configuration : Ozeki.Libs.Rest.Configuration;
var msg : Ozeki.Libs.Rest.Message;
var api : Ozeki.Libs.Rest.MessageApi;
var result : MessageSendResult;
var read : string;

begin
  try
    configuration := Ozeki.Libs.Rest.Configuration.Create;
    configuration.Username := 'http_user';
    configuration.Password := 'qwe123';
    configuration.ApiUrl := 'http://127.0.0.1:9509/api';

    msg := Ozeki.Libs.Rest.Message.Create;
    msg.ToAddress := '+36201111111';
    msg.Text := 'Hello world!';

    api := Ozeki.Libs.Rest.MessageApi.Create(configuration);

    result := api.SendMessage(msg);

    Writeln(result.ToString());

    Readln(read);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
