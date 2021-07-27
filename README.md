# Delhi sms library to send sms with http/rest/json

This Delhi sms library enables you to **send** and **receive** sms messages with http request.
The library uses HTTP Post requests and JSON encoded content to send the text
messages to the mobile network1. It connects to the HTTP SMS API of 
[Ozeki SMS gateway](https://ozeki-sms-gateway.com). This repository is better
at implementing SMS solutions then other alternatives, because it is very user-friendly but also powerful enough 
to send 1000 SMS per second, while providing full service provider independence.

## What is Ozeki SMS Gateway 

Ozeki SMS Gateway is a powerful SMS Gateway software that you can download and install on your Windows or Linux computer or to your Android mobile phone. It provides an HTTP SMS API, that allows you to connect to it from local or remote programs. The reason why companies use Ozeki SMS Gateway as their first point of access to the mobile network, is because it provides service provider independence. When you use Ozeki, the SMS contact lists and sms data is safe, because Ozeki is installed in their own computer (physical or virutal), and Ozeki provides direct access to the mobile network through wireless connections.

Download: [Ozeki SMS Gateway download page](https://ozeki-sms-gateway.com/p_727-download-sms-gateway.html)

Tutorial: [Delhi send sms sample and tutorial](https://ozeki-sms-gateway.com/p_849-delphi-send-sms-with-the-http-rest-api-code-sample.html)

**To send sms from Delhi**
1. [Download Ozeki SMS Gateway](https://ozeki-sms-gateway.com/p_727-download-sms-gateway.html)
2. [Connect Ozeki SMS Gateway to the mobile network](https://ozeki-sms-gateway.com/p_70-mobile-network-connections.html)
3. [Create an HTTP SMS API user](https://ozeki-sms-gateway.com/p_2102-create-an-http-sms-api-user-account.html)
4. Checkout the Github send SMS from Delhi repository
5. Install Delphi extension pack
6. Open the Github SMS send example in Visual Studio
7. Compile the Send SMS console project
8. Check the logs in Ozeki SMS Gateway

## How to use the code

To use the code you need to import the Ozeki.Libs.Rest sms library. This sms library is also included in this repository with it's full source code. After the library is imported with the using statement, you need to define the username, password and the api url. You can create the username and password when you install an HTTP API user in your Ozeki SMS Gateway system.
The URL is the default http api URL to connect to your SMS gateway. If you run the SMS gateway on the same computer where your Delphi code is running, you can use 127.0.0.1 as the ip address. You need to change this if you install the sms gateway on a different computer (or mobile phone).

### How to use the Ozeki.Libs.Rest unit

In order to use the __Ozeki.Libs.Rest unit__ in your own project, you need to place the __Ozeki.Libs.Rest.pas__ file in your project.
After you've placed these two files _(what you can download from this github repository, together with 5 example projects)_, you can import it with this line:

```pascal
uses Ozeki.Libs.Rest in 'Ozeki.Libs.Rest.pas';
```
When you imported the header file, you are ready to use the __Ozeki.Libs.Rest unit__, to send, mark, delete and receive SMS messages.

#### Creating a Configuration

To send your SMS message to the built in API of the __Ozeki SMS Gateway__, your client application needs to know the details of your __Gateway__ and the __http_user__.
We can define a __Configuration__ instance with these lines of codes in Delphi:

```pascal
var configuration : Ozeki.Libs.Rest.Configuration := Ozeki.Libs.Rest.Configuration.Create;
configuration.Username := 'http_user';
configuration.Password := 'qwe123';
configuration.ApiUrl := 'http://127.0.0.1:9509/api';
```

#### Creating a Message

After you have initialized your configuration object you can continue by creating a Message object.
A message object holds all the needed data for message what you would like to send.
In Delphi we create a __Message__ instance with the following lines of codes:

```pascal
var msg : Ozeki.Libs.Rest.Message := Ozeki.Libs.Rest.Message.Create;
msg.ToAddress := '+36201111111';
msg.Text := 'Hello world!';
```

#### Creating a MessageApi

You can use the __MessageApi__ class of the __Ozeki.Libs.Rest unit__ to create a __MessageApi__ object which has the methods to send, delete, mark and receive SMS messages from the Ozeki SMS Gateway.
To create a __MessageApi__, you will need these lines of codes and a __Configuration__ instance.

```pascal
var api : Ozeki.Libs.Rest.MessageApi := Ozeki.Libs.Rest.MessageApi.Create(configuration);
```

After everything is ready you can begin with sending the previously created __Message__ object:

```pascal
var result : Ozeki.Libs.Rest.MessageSendResult := api.SendMessage( msg );

Writeln(result.ToString);
```

After you have done all the steps, you check the Ozeki SMS Gateway and you will see the message in the _Sent_ folder of the __http_user__.

## How to send sms through your Android mobile phone

If you wish to [send SMS through your Android mobile phone from Delhi](https://android-sms-gateway.com/), you need to [install Ozeki SMS Gateway on your Android](https://ozeki-sms-gateway.com/p_2847-how-to-install-ozeki-sms-gateway-on-android.html) mobile phone. It is recommended to use an Android mobile phone with a minimum of 4GB RAM and a quad core CPU. Most devices today meet these specs. The advantage of using your mobile, is that it is quick to setup and it often allows you to [send sms free of charge](https://android-sms-gateway.com/p_246-how-to-send-sms-free-of-charge.html).
[Android SMS Gateway](https://android-sms-gateway.com)

## Get started now

Don't waste any more time, send your first SMS!
