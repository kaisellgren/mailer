# How to use XOAUTH2 authentication in the [mailer](https://github.com/kaisellgren/mailer) lib (version ^3.0.0)

This example uses the [googleapis_auth](https://github.com/dart-lang/googleapis_auth) library.

OAuth2 google credentials are explained [here](https://developers.google.com/identity/protocols/OAuth2)


## Get an app id

Go to the [API & Services dashboard](https://console.developers.google.com/apis/credentials) and
"create credentials" with type other.

You will get an app-`id` and an app-`secret`.

It should also be possible to create a service account.  However AFAIK only google apps accounts
are allowed to do that.  For more information see [googleapis_auth → Autonomous Application / Service Account](https://github.com/dart-lang/googleapis_auth)


## You want to send mails with your account.

This is acceptable if you are using `mailer` in a server (command line) app.

**Do not use your account in flutter apps.**  It is possible to extract credentials
from apps and an attacker would be able to send spam using your account.

I unfortunately don't know how to find out which account has been used when asking for permissions.
You therefore have to specify the username (`--username`) manually.  They obviously have to match.

First retrieve the credentials using [obtain_credentials.dart](obtain_credentials.dart):  
`dart bin/obtain_credentials.dart --username 'yourAddress@gmail.com' --file '/tmp/secrets.json --id 'YOUR_ID.apps.googleusercontent.com' --secret 'YOUR_SECRET'`

You can then send mails using:
`dart bin/send_mail.dart --file '/tmp/secrets.json --to 'someTestAddress@test.com'`

Again don't store your credentials in any mobile app!


## Send mail in flutter apps.

You will need to ask the user.

Write your own `prompt` function ([obtain_credentials.dart](obtain_credentials.dart)) which
displays the homepage to the user.

Then ask the user for its email-address and store the credentials somewhere.
