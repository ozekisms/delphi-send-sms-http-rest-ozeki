program SendMultipleSms;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Ozeki.Libs.Rest in '../Ozeki.Libs.Rest/Ozeki.Libs.Rest.pas';

var configuration : Ozeki.Libs.Rest.Configuration;
var msg1, msg2, msg3 : Ozeki.Libs.Rest.Message;
var api : Ozeki.Libs.Rest.MessageApi;
var result : MessageSendResults;
var read : string;

begin
  try
    configuration := Ozeki.Libs.Rest.Configuration.Create;
    configuration.Username := 'http_user';
    configuration.Password := 'qwe123';
    configuration.ApiUrl := 'http://127.0.0.1:9509/api';

    msg1 := Ozeki.Libs.Rest.Message.Create;
    msg1.ToAddress := '+36201111111';
    msg1.Text := 'Hello world 1';

    msg2 := Ozeki.Libs.Rest.Message.Create;
    msg2.ToAddress := '+36202222222';
    msg2.Text := 'Hello world 2';

    msg3 := Ozeki.Libs.Rest.Message.Create;
    msg3.ToAddress := '+36203333333';
    msg3.Text := 'Hello world 3';

    api := Ozeki.Libs.Rest.MessageApi.Create(configuration);

    result := api.SendMessages([ msg1, msg2, msg3 ]);

    Writeln(result.ToString());

    Readln(read);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
