unit Ozeki.Libs.Rest;


interface

  uses
    Generics.Collections,
    System.DateUtils,
    System.NetEncoding,
    System.JSON,
    Rest.Json,
    Variants,
    IdHTTP,
    System.Classes,
    System.SysUtils;

  { The declaration
  of the Configuration class }

  type Configuration = class(TObject)
    public
      Username : string;
      Password : string;
      ApiUrl : string;
  end;

  { The declaration
  of the Message class }

  type Message = class(TObject)
    public
      ID : string;
      FromConnection : string;
      FromAddress : string;
      FromStation : string;
      ToConnection : string;
      ToAddress : string;
      ToStation : string;
      Text : string;
      CreateDate : TDateTime;
      ValidUntil : TDateTime;
      TimeToSend : TDateTime;
      IsSubmitReportRequested : Boolean;
      IsDeliveryReportRequested : Boolean;
      IsViewReportRequested : Boolean;
      Tags : TDictionary<string, string>;
      constructor Create();
      function ToString(): string; override;
      procedure addTag(name:string; value:string);
    private
      function getTags() : TJSONArray;
      function getJSON() : TJSONObject;
  end;

  { The declaration
  of the DeliveryStatus enum }

  type DeliveryStatus = (Success, Failed);

  { The declaration
  of the Folder enum }

  type Folder = (Inbox, Outbox, Sent, NotSent, Deleted);

  { The declaration
  of the MessageSendResult class }

  type MessageSendResult = class(TObject)
    public
      Message : Message;
      Status : DeliveryStatus;
      ResponseMessage : string;
      constructor Create(message:Message; Status:DeliveryStatus; ResponseMessage:string);
      function ToString() : string; override;
  end;

  { The declaration
  of the MessageDeleteResult class }

  type MessageDeleteResult = class(TObject)
    public
      Folder : Folder;
      MessageIdsRemoveSucceeded : TArray<string>;
      MessageIdsRemoveFailed : TArray<string>;
      TotalCount : integer;
      SuccessCount : Integer;
      FailedCount : Integer;
      constructor Create(folder:Folder);
      procedure AddMessageRemoveSucceededId(message_id:string);
      procedure AddMessageRemoveFailedId(message_id:string);
      function ToString() : string; override;
  end;

  { The declaration
  of the MessageMarkResult class }

  type MessageMarkResult = class(TObject)
    public
      Folder : Folder;
      MessageIdsMarkSucceeded : TArray<string>;
      MessageIdsMarkFailed : TArray<string>;
      TotalCount : integer;
      SuccessCount : Integer;
      FailedCount : Integer;
      constructor Create(folder:Folder);
      procedure AddMessageMarkSucceededId(message_id:string);
      procedure AddMessageMarkFailedId(message_id:string);
      function ToString() : string; override;
  end;

  { The declaration
  of the MessageSendResults class }

  type MessageSendResults = class(TObject)
    public
      TotalCount : integer;
      SuccessCount : integer;
      FailedCount : integer;
      Results : TArray<MessageSendResult>;
      constructor Create(TotalCount:integer; SuccessCount:integer; FailedCount:integer);
      function ToString() : string; override;
    private
      procedure Add(result:MessageSendResult);
  end;

  { The declaration
  of the MessageReceiveResult class }

  type MessageReceiveResult = class(TObject)
    public
      Folder : Folder;
      Limit : string;
      Messages : TArray<Message>;
      constructor Create(Folder:Folder; Limit:string);
      function ToString(): string; override;
    private
      procedure Add(message:Message);
  end;

  { The declaration
  of the MessageApi class }

  type MessageApi = class(TObject)
    public
      constructor Create(confgiuration:Configuration);
      function SendMessage(message:Message) : MessageSendResult;
      function SendMessages(messages: array of Message) : MessageSendResults;
      function DeleteMessage(Folder : Folder; message:Message) : Boolean;
      function DeleteMessages(Folder : Folder; messages: TArray<Message>) : MessageDeleteResult;
      function MarkMessage(Folder : Folder; message:Message) : Boolean;
      function MarkMessages(Folder : Folder; messages: TArray<Message>) : MessageMarkResult;
      function DownloadIncoming() : MessageReceiveResult;
    private
      configuration : Configuration;
      function createAuthorizationHeader(username:string; password:string) : string;
      function createRequestBody(messages : Array of Message) : string;
      function createRequestBodyToManipulate(Folder : Folder; messages : Array of Message) : string;
      function createUriToSendSms(url:string) : string;
      function createUriToDeleteSms(url:string) : string;
      function createUriToMarkSms(url:string) : string;
      function createUriToReceiveSms(Folder: Folder; url:string) : string;
      function getResponseDelete(response:string; messages:TArray<Message>):MessageDeleteResult;
      function getResponseMark(response:string; messages: TArray<Message>) : MessageMarkResult;
      function getResponseSend(response:string) : MessageSendResults;
      function getResponseReceive(response:string) : MessageReceiveResult;
      function doRequestPOST(url:string; authorizationHeader:string; requestBody:string) : string;
      function doRequestGET(url:string; authorizationHeader:string) : string;
  end;

implementation

  { The procedures and
    functions of the
    Message class }

  constructor Message.Create;
  begin
    self.ID := stringreplace(stringreplace(TGUID.NewGuid.ToString().ToLower(), '{', '', [rfReplaceAll, rfIgnoreCase]), '}', '', [rfReplaceAll, rfIgnoreCase]);
    self.CreateDate := Now();
    self.ValidUntil :=  IncDay(self.CreateDate, 7);
    self.TimeToSend := Now();
    self.IsSubmitReportRequested := true;
    self.IsDeliveryReportRequested := true;
    self.IsViewReportRequested := true;
    self.Tags := TDictionary<string, string>.Create;
  end;

  function Message.ToString() : string;
  begin
    result := string.Format('%s->%s ''%s''', [self.FromAddress, self.ToAddress, self.Text]);
  end;

  procedure Message.addTag(name:string; value:string);
  begin
    self.Tags.Add(name, value);
  end;

  function Message.getTags() : TJSONArray;
  begin
    var tags : TJSONArray := TJSONArray.Create;

    var key : string;
    var Obj : TJSONObject;

    for key in self.Tags.Keys do
      Obj := TJSONObject.Create;
      Obj.AddPair('name', key);
      Obj.AddPair('value', self.Tags.Items[key]);
      tags.Add(Obj);

    result := tags;
  end;

  function Message.getJSON() : TJSONObject;
  begin
    var Obj := TJSONObject.Create;

    if self.ID <> Null then
      Obj.AddPair('message_id', self.ID);
    if self.FromConnection <> Null then
      Obj.AddPair('from_connection', self.FromConnection);
    if self.FromAddress <> Null then
      Obj.AddPair('from_address', self.FromAddress);
    if self.FromStation <> Null then
      Obj.AddPair('from_station', self.FromStation);
    if self.ToConnection <> Null then
      Obj.AddPair('to_connection', self.ToConnection);
    if self.ToAddress <> Null then
      Obj.AddPair('to_address', self.ToAddress);
    if self.ToStation <> Null then
      Obj.AddPair('to_station', self.ToStation);
    if self.Text <> Null then
      Obj.AddPair('text', self.Text);
    if self.CreateDate <> Null then
      Obj.AddPair('create_date', FormatDateTime('yyyy-mm-dd"T"hh:mm:ss', self.CreateDate));
    if self.ValidUntil <> Null then
      Obj.AddPair('valid_until', FormatDateTime('yyyy-mm-dd"T"hh:mm:ss', self.ValidUntil));
    if self.TimeToSend <> Null then
      Obj.AddPair('time_to_send', FormatDateTime('yyyy-mm-dd"T"hh:mm:ss', self.TimeToSend));
    if self.IsSubmitReportRequested then
      Obj.AddPair('submit_report_requested', TJSONTrue.Create)
    else
      Obj.AddPair('submit_report_requested', TJSONFalse.Create);
    if self.IsDeliveryReportRequested <> Null then
      Obj.AddPair('delivery_report_requested', TJSONTrue.Create)
    else
      Obj.AddPair('delivery_report_requested', TJSONFalse.Create);
    if self.IsViewReportRequested <> Null then
      Obj.AddPair('view_report_requested', TJSONTrue.Create)
    else
      Obj.AddPair('view_report_requested', TJSONFalse.Create);
    if Length(self.Tags.Keys.ToArray) > 0 then
      Obj.AddPair('tags', self.getTags);
    result := Obj;
  end;

 { The procedures and
  functions of the
  MessageSendResult class }

  constructor MessageSendResult.Create(message:Message; Status:DeliveryStatus; ResponseMessage:string);
  begin
    self.Message := Message;
    self.Status := Status;
    self.ResponseMessage := ResponseMessage;
  end;

  function MessageSendResult.ToString() : string;
  begin
    var status : string;
  
    if self.Status = Success then
      status := 'Success'
    else
      status := 'Failed';
    
    result := Format('%s, %s', [status, self.Message.ToString]);
  end;

  { The procedures and
  functions of the
  MessageDeleteResult class }

  constructor MessageDeleteResult.Create(folder:Folder);
  begin
    self.Folder := folder;
  end;

  procedure MessageDeleteResult.AddMessageRemoveSucceededId(message_id:string);
  begin
    self.MessageIdsRemoveSucceeded := self.MessageIdsRemoveSucceeded + [message_id];
    self.TotalCount := self.TotalCount + 1;
    self.SuccessCount := self.SuccessCount + 1;
  end;

  procedure MessageDeleteResult.AddMessageRemoveFailedId(message_id:string);
  begin
    self.MessageIdsRemoveFailed := self.MessageIdsRemoveFailed + [message_id];
    self.TotalCount := self.TotalCount + 1;
    self.FailedCount := self.FailedCount + 1;
  end;

  function MessageDeleteResult.ToString() : string;
  begin
    result := Format('Total: %d. Success: %d. Failed: %d.', [self.TotalCount, self.SuccessCount, self.FailedCount]);
  end;

  { The procedures and
  functions of the
  MessageMarkResult class }

  constructor MessageMarkResult.Create(folder:Folder);
  begin
    self.Folder := folder;
  end;

  procedure MessageMarkResult.AddMessageMarkSucceededId(message_id:string);
  begin
    self.MessageIdsMarkSucceeded := self.MessageIdsMarkSucceeded + [message_id];
    self.TotalCount := self.TotalCount + 1;
    self.SuccessCount := self.SuccessCount + 1;
  end;

  procedure MessageMarkResult.AddMessageMarkFailedId(message_id:string);
  begin
    self.MessageIdsMarkFailed := self.MessageIdsMarkFailed + [message_id];
    self.TotalCount := self.TotalCount + 1;
    self.FailedCount := self.FailedCount + 1;
  end;

  function MessageMarkResult.ToString() : string;
  begin
    result := Format('Total: %d. Success: %d. Failed: %d.', [self.TotalCount, self.SuccessCount, self.FailedCount]);
  end;

  { The procedures and
  functions of the
  MessageSendResults class }

  constructor MessageSendResults.Create(TotalCount:integer; SuccessCount:integer; FailedCount:integer);
  begin
    self.TotalCount := TotalCount;
    self.SuccessCount := SuccessCount;
    self.FailedCount := FailedCount;
    self.Results := [];
  end;

  procedure MessageSendResults.Add(result:MessageSendResult);
  begin
    self.Results := self.Results + [result];
  end;

  function MessageSendResults.ToString() : string;
  begin
    result := Format('Total: %d. Success: %d. Failed: %d.', [self.TotalCount, self.SuccessCount, self.FailedCount]);
  end;

  { The procedures and
  function of the
  MessageReceiveResult class }

  constructor MessageReceiveResult.Create(Folder: Folder; Limit: string);
  begin
    self.Folder := Folder;
    self.Limit := Limit;
    self.Messages := [];
  end;

  function MessageReceiveResult.ToString : string;
  begin
      result := Format('Message count: %d.', [Length(self.Messages)]);
  end;

  procedure MessageReceiveResult.Add(message:Message);
  begin
      self.Messages := self.Messages + [message];
  end;

 { The procedures and
  functions of the
  MessageApi class }

  constructor MessageApi.Create(confgiuration:Configuration);
  begin
    self.configuration := confgiuration;
  end;

  function MessageApi.createAuthorizationHeader(username:string; password:string) : string;
  begin
    var usernamePassword := username + ':' + password;
    var Encoder := TBase64Encoding.Create();
    var usernamePasswordEncoded := Encoder.Encode(usernamePassword);
    result := Format('Basic %s', [usernamePasswordEncoded]);
  end;

  function MessageApi.createRequestBody(messages : Array of Message) : string;
  begin
      var Obj : TJSONObject := TJSONObject.Create;
      var ArrayOfMessages : TJSONArray := TJSONArray.Create;

      var message : Message;

      for message in messages do
        ArrayOfMessages.Add(message.getJSON);

      Obj.AddPair('messages', ArrayOfMessages);

      result :=  Obj.ToString;
  end;

  function MessageApi.createRequestBodyToManipulate(Folder : Folder; messages : Array of Message) : string;
  begin
      var Obj : TJSONObject := TJSONObject.Create;
      var ArrayOfMessages : TJSONArray := TJSONArray.Create;
      var FolderName : string;

      var message : Message;

      for message in messages do
        ArrayOfMessages.Add(message.ID);

      case integer(Folder) of
       0 : FolderName := 'inbox';
       1 : FolderName := 'outbox';
       2 : FolderName := 'sent';
       3 : FolderName := 'notsent';
       4 : FolderName := 'deleted';
      end;

      Obj.AddPair('folder', FolderName);
      Obj.AddPair('message_ids', ArrayOfMessages);

      result :=  Obj.ToString;
  end;

  function MessageApi.createUriToSendSms(url:string) : string;
  begin
    var baseUrl : string := url.Split(['?'])[0];
    result := Format('%s?action=sendmsg', [baseUrl]);
  end;

  function MessageApi.createUriToDeleteSms(url:string) : string;
  begin
    var baseUrl : string := url.Split(['?'])[0];
    result := Format('%s?action=deletemsg', [baseUrl]);
  end;

  function MessageApi.createUriToMarkSms(url:string) : string;
  begin
    var baseUrl : string := url.Split(['?'])[0];
    result := Format('%s?action=markmsg', [baseUrl]);
  end;

  function MessageApi.createUriToReceiveSms(Folder: Folder; url:string) : string;
  begin
    var FolderName : string;

    var baseUrl : string := url.Split(['?'])[0];

    case integer(Folder) of
       0 : FolderName := 'inbox';
       1 : FolderName := 'outbox';
       2 : FolderName := 'sent';
       3 : FolderName := 'notsent';
       4 : FolderName := 'deleted';
    end;

    result := Format('%s?action=receivemsg&folder=%s', [baseUrl, FolderName]);
  end;

  function MessageApi.getResponseSend(response:string) : MessageSendResults;
  begin
    var message_id, from_connection, from_address, from_station, to_connection,
    to_address, to_station, text, status, name, value : string;
    var submit_report_requested, delivery_report_requested, view_report_requested : Boolean;
    var create_date, valid_until, time_to_send : TDateTime;
    var total_count, success_count, failed_count : integer;
    var tags, messages : TJSONArray;
    var data : TJSONObject;
    var i, j : integer;
    var m : Message;

    var response_json := TJSONObject.ParseJSONValue(response);

     if response_json.TryGetValue('data', data) then
     begin

      data.TryGetValue('total_count', total_count);
      data.TryGetValue('success_count', success_count);
      data.TryGetValue('failed_count', failed_count);

      var results := MessageSendResults.Create(total_count, success_count, failed_count);

      data.TryGetValue('messages', messages);

      for i := 0 to (success_count-1) do
      begin

        m := Message.Create;

        if messages.Get(i).TryGetValue('message_id', message_id) then
        begin
          m.ID := message_id;
        end;

        if messages.Get(i).TryGetValue('from_connection', from_connection) then
        begin
          m.FromConnection := from_connection;
        end;
      
        if messages.Get(i).TryGetValue('from_address', from_address) then
        begin
          m.FromAddress := from_address;
        end;
      
        if messages.Get(i).TryGetValue('from_station', from_station) then
        begin
          m.FromStation := from_station;
        end;
      
        if messages.Get(i).TryGetValue('to_connection', to_connection) then
        begin
          m.ToConnection := to_connection;
        end;
      
        if messages.Get(i).TryGetValue('to_address', to_address) then
        begin
          m.ToAddress := to_address;
        end;

        if messages.Get(i).TryGetValue('to_station', to_station) then
        begin
          m.ToStation := to_station;
        end;
      
        if messages.Get(i).TryGetValue('text', text) then
        begin
          m.Text := text;
        end;
      
        if messages.Get(i).TryGetValue('create_date', create_date) then
        begin
          m.CreateDate := create_date;
        end;
      
        if messages.Get(i).TryGetValue('valid_until', valid_until) then
        begin
          m.ValidUntil := valid_until;
        end;
      
        if messages.Get(i).TryGetValue('time_to_send', time_to_send) then
        begin
          m.TimeToSend := time_to_send;
        end;
      
        if messages.Get(i).TryGetValue('submit_report_requested', submit_report_requested) then
        begin
          m.IsSubmitReportRequested := submit_report_requested;
        end;
      
        if messages.Get(i).TryGetValue('delivery_report_requested', delivery_report_requested) then
        begin
          m.IsDeliveryReportRequested := delivery_report_requested;
        end;
      
        if messages.Get(i).TryGetValue('view_report_requested', view_report_requested) then
        begin
          m.IsViewReportRequested := view_report_requested;
        end;

        if messages.Get(i).TryGetValue('tags', tags) and (tags.Count > 0) then
        begin
          for j := 0 to (tags.Count - 1) do
          begin
            if tags.Get(j).TryGetValue('name', name) and tags.Get(j).TryGetValue('value', value) then
            begin
              m.addTag(name, value);
            end;
          end;

        end;

        if messages.Get(i).TryGetValue('status', status) and (status = 'SUCCESS') then
        begin
          results.Add(MessageSendResult.Create(m, Success, ''));
          result := results;
        end
        else
        begin
          results.Add(MessageSendResult.Create(m, Failed, status));
          result := results;
        end
        end;
     end
     else
     begin
        result := MessageSendResults.Create(0, 0, 0);
     end
  end;

  function MessageApi.getResponseDelete(response:string; messages:TArray<Message>) : MessageDeleteResult;
  begin
    var data : TJSONObject;
    var folder : string;
    var message_ids : TJSONArray;
    var i, j : integer;
    var delete_result : MessageDeleteResult;
    var success : Boolean;

    var response_json :=  TJSONObject.ParseJSONValue(response);
    if response_json.TryGetValue('data', data) then
    begin
      if data.TryGetValue('folder', folder) and data.TryGetValue('message_ids', message_ids) then
      begin

        if folder = 'inbox' then
        begin
          delete_result := MessageDeleteResult.Create(Inbox);
        end
        else if folder = 'outbox' then
        begin
          delete_result := MessageDeleteResult.Create(Outbox);
        end
        else if folder = 'sent' then
        begin
          delete_result := MessageDeleteResult.Create(Sent);
        end
        else if folder = 'notsent' then
        begin
          delete_result := MessageDeleteResult.Create(NotSent);
        end
        else
        begin
          delete_result := MessageDeleteResult.Create(Deleted);
        end;

        for i := 0 to (Length(messages) - 1) do
        begin
          success := false;
          for j := 0 to (message_ids.Count - 1) do
          begin
              if (Format('"%s"', [messages[i].ID]) =  message_ids.Items[j].ToString) then
              begin
                success := true;
              end;
          end;
          if success then
          begin
            delete_result.AddMessageRemoveSucceededId(messages[i].ID);
          end
          else
          begin
            delete_result.AddMessageRemoveFailedId(messages[i].ID);
          end;
        end;
      end;

      result := delete_result;

    end
    else
    begin
      result := MessageDeleteResult.Create(Inbox);
    end;
  end;

  function MessageApi.getResponseMark(response:string; messages: TArray<Message>) : MessageMarkResult;
  begin
    var data : TJSONObject;
    var folder : string;
    var message_ids : TJSONArray;
    var i, j : integer;
    var mark_result : MessageMarkResult;
    var success : Boolean;

    var response_json :=  TJSONObject.ParseJSONValue(response);
    if response_json.TryGetValue('data', data) then
    begin
      if data.TryGetValue('folder', folder) and data.TryGetValue('message_ids', message_ids) then
      begin

        if folder = 'inbox' then
          begin
            mark_result := MessageMarkResult.Create(Inbox);
          end
        else if folder = 'outbox' then
          begin
            mark_result := MessageMarkResult.Create(Outbox);
          end
        else if folder = 'sent' then
          begin
            mark_result := MessageMarkResult.Create(Sent);
          end
        else if folder = 'notsent' then
          begin
            mark_result := MessageMarkResult.Create(NotSent);
          end
        else
          begin
            mark_result := MessageMarkResult.Create(Deleted);
        end;

        for i := 0 to (Length(messages) - 1) do
        begin
          success := false;
          for j := 0 to (message_ids.Count - 1) do
          begin
            if (Format('"%s"', [messages[i].ID]) =  message_ids.Items[j].ToString) then
            begin
              success := true;
            end;
          end;
          if success then
          begin
            mark_result.AddMessageMarkSucceededId(messages[i].ID);
          end
          else
          begin
            mark_result.AddMessageMarkFailedId(messages[i].ID);
          end;
        end;
      end;

      result := mark_result;

    end
    else
    begin
      result := MessageMarkResult.Create(Inbox);
    end;
  end;

  function MessageApi.getResponseReceive(response:string) : MessageReceiveResult;
  begin
    var message_id, from_connection, from_address, from_station, to_connection,
    to_address, to_station, text, status, name, value, folder, limit : string;
    var submit_report_requested, delivery_report_requested, view_report_requested : Boolean;
    var create_date, valid_until, time_to_send : TDateTime;
    var tags, inner_data : TJSONArray;
    var data : TJSONObject;
    var i, j : integer;
    var receive_result : MessageReceiveResult;
    var m : Message;

    var response_json := TJSONObject.ParseJSONValue(response);

     if response_json.TryGetValue('data', data) then
     begin

      data.TryGetValue('folder', folder);
      data.TryGetValue('limit', limit);

      if folder = 'inbox' then
        begin
          receive_result := MessageReceiveResult.Create(Inbox, limit);
        end
      else if folder = 'outbox' then
        begin
          receive_result := MessageReceiveResult.Create(Outbox, limit);
        end
      else if folder = 'sent' then
        begin
          receive_result := MessageReceiveResult.Create(Sent, limit);
        end
      else if folder = 'notsent' then
        begin
          receive_result := MessageReceiveResult.Create(NotSent, limit);
        end
      else
        begin
          receive_result := MessageReceiveResult.Create(Deleted, limit);
      end;

      data.TryGetValue('data', inner_data);

      for i := 0 to (inner_data.Count - 1) do
      begin

        m := Message.Create;

        if inner_data.Get(i).TryGetValue('message_id', message_id) then
        begin
          m.ID := message_id;
        end;

        if inner_data.Get(i).TryGetValue('from_connection', from_connection) then
        begin
          m.FromConnection := from_connection;
        end;

        if inner_data.Get(i).TryGetValue('from_address', from_address) then
        begin
          m.FromAddress := from_address;
        end;

        if inner_data.Get(i).TryGetValue('from_station', from_station) then
        begin
          m.FromStation := from_station;
        end;

        if inner_data.Get(i).TryGetValue('to_connection', to_connection) then
        begin
          m.ToConnection := to_connection;
        end;

        if inner_data.Get(i).TryGetValue('to_address', to_address) then
        begin
          m.ToAddress := to_address;
        end;

        if inner_data.Get(i).TryGetValue('to_station', to_station) then
        begin
          m.ToStation := to_station;
        end;

        if inner_data.Get(i).TryGetValue('text', text) then
        begin
          m.Text := text;
        end;

        if inner_data.Get(i).TryGetValue('create_date', create_date) then
        begin
          m.CreateDate := create_date;
        end;

        if inner_data.Get(i).TryGetValue('valid_until', valid_until) then
        begin
          m.ValidUntil := valid_until;
        end;

        if inner_data.Get(i).TryGetValue('time_to_send', time_to_send) then
        begin
          m.TimeToSend := time_to_send;
        end;

        if inner_data.Get(i).TryGetValue('submit_report_requested', submit_report_requested) then
        begin
          m.IsSubmitReportRequested := submit_report_requested;
        end;

        if inner_data.Get(i).TryGetValue('delivery_report_requested', delivery_report_requested) then
        begin
          m.IsDeliveryReportRequested := delivery_report_requested;
        end;

        if inner_data.Get(i).TryGetValue('view_report_requested', view_report_requested) then
        begin
          m.IsViewReportRequested := view_report_requested;
        end;

        if inner_data.Get(i).TryGetValue('tags', tags) and (tags.Count > 0) then
        begin
          for j := 0 to (tags.Count - 1) do
          begin
            if tags.Get(j).TryGetValue('name', name) and tags.Get(j).TryGetValue('value', value) then
            begin
              m.addTag(name, value);
            end;
          end;

        end;
          receive_result.Add(m);
        end;

        self.DeleteMessages(Inbox, receive_result.Messages);
        result := receive_result;

     end
     else
     begin
        result := MessageReceiveResult.Create(Inbox, '1000');
     end
  end;

  function MessageApi.SendMessage(message : Message) : MessageSendResult;
  begin
    var authorizationHeader := self.createAuthorizationHeader(self.configuration.Username, self.configuration.Password);
    var requestBody := self.createRequestBody([message]);
    result := self.getResponseSend(self.doRequestPOST(self.createUriToSendSms(self.configuration.ApiUrl), authorizationHeader, requestBody)).Results[0];
  end;

  function MessageApi.SendMessages(messages: array of Message) : MessageSendResults;
  begin
    var authorizationHeader := self.createAuthorizationHeader(self.configuration.Username, self.configuration.Password);
    var requestBody := self.createRequestBody(messages);
    result := self.getResponseSend(self.doRequestPOST(self.createUriToSendSms(self.configuration.ApiUrl), authorizationHeader, requestBody));
  end;

  function MessageApi.DeleteMessage(Folder : Folder; message:Message) : Boolean;
  begin
    var authorizationHeader := self.createAuthorizationHeader(self.configuration.Username, self.configuration.Password);
    var requestBody := self.createRequestBodyToManipulate(Folder, [message]);
    var response : MessageDeleteResult := self.getResponseDelete(self.doRequestPOST(self.createUriToDeleteSms(self.configuration.ApiUrl), authorizationHeader, requestBody), [message]);
    if ((response.TotalCount = 1) and (response.TotalCount = response.SuccessCount)) then
    begin
      result := true;
    end
    else
    begin
      result:= false;
    end;
  end;

  function MessageApi.DeleteMessages(Folder : Folder; messages: TArray<Message>) : MessageDeleteResult;
  begin
    var authorizationHeader := self.createAuthorizationHeader(self.configuration.Username, self.configuration.Password);
    var requestBody := self.createRequestBodyToManipulate(Folder, messages);
    result := self.getResponseDelete(self.doRequestPOST(self.createUriToDeleteSms(self.configuration.ApiUrl), authorizationHeader, requestBody), messages);
  end;

  function MessageApi.MarkMessage(Folder : Folder; message:Message) : Boolean;
  begin
    var authorizationHeader := self.createAuthorizationHeader(self.configuration.Username, self.configuration.Password);
    var requestBody := self.createRequestBodyToManipulate(Folder, [message]);
    var response : MessageMarkResult := self.getResponseMark(self.doRequestPOST(self.createUriToMarkSms(self.configuration.ApiUrl), authorizationHeader, requestBody), [message]);
    if ((response.TotalCount = 1) and (response.TotalCount = response.SuccessCount)) then
    begin
      result := true;
    end
    else
    begin
      result:= false;
    end;
  end;

  function MessageApi.MarkMessages(Folder : Folder; messages: TArray<Message>) : MessageMarkResult;
  begin
    var authorizationHeader := self.createAuthorizationHeader(self.configuration.Username, self.configuration.Password);
    var requestBody := self.createRequestBodyToManipulate(Folder, messages);
    result := self.getResponseMark(self.doRequestPOST(self.createUriToMarkSms(self.configuration.ApiUrl), authorizationHeader, requestBody), messages);
  end;

  function MessageApi.DownloadIncoming() : MessageReceiveResult;
  begin
    var authorizationHeader := self.createAuthorizationHeader(self.configuration.Username, self.configuration.Password);
    result := self.getResponseReceive(self.doRequestGET(self.createUriToReceiveSms(Inbox, self.configuration.ApiUrl), authorizationHeader));
  end;

  function MessageApi.doRequestPOST(url:string; authorizationHeader:string; requestBody:string) : string;
  begin
    var body := TStringStream.Create(requestBody);
    var http : TIdHttp := TIdHttp.Create();
    http.Request.CustomHeaders.AddValue('Authorization', authorizationHeader);
    http.Request.ContentType := 'application/json';
    http.Request.Accept := 'application/json';
    result := http.Post(url, body);
  end;

  function MessageApi.doRequestGET(url:string; authorizationHeader:string) : string;
  begin
    var http : TIdHttp := TIdHttp.Create();
    http.Request.CustomHeaders.AddValue('Authorization', authorizationHeader);
    http.Request.Accept := 'application/json';
    result := http.GET(url);
  end;
end.
