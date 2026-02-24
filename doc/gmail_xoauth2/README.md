# Server-Side XOAuth2 with Mailer

This guide explains how to acquire the necessary credentials to use Gmail with the `mailer` package on a server (or any headless environment).

Unlike the "App Password" method, XOAuth2 is more secure and is the recommended way to access Gmail programmatically.

## Prerequisites

1. A Google Cloud Project.
2. The `mailer` package installed in your Dart project.

## Step 1: Google Cloud Console Setup

### 1. Create a Project

1. Go to the [Google Cloud Console](https://console.cloud.google.com/).  
   ![Console](screenshots/step1_console.png)

2. Click on the project dropdown and select **New Project**.  
   ![New Project](screenshots/step2_new_project.png)

3. Enter a project name and click **Create**.  
   ![Create Project](screenshots/step3_create.png)

4. Select your newly created project.  
   ![Select Project](screenshots/step4_select.png)

### 2. Enable Gmail API

1. Go to **APIs & Services > Dashboard**.  
   ![APIs Overview](screenshots/step5_apis_overview.png)

2. Click **Enable APIs and Services**.  
   ![Enable APIs](screenshots/step6_enable_apis.png)

3. Search for `Gmail API`.  
   ![Search Gmail API](screenshots/step7_gmail_api.png)

4. Select **Gmail API** from the results.  
   ![Select Gmail API](screenshots/step8_gmail_api2.png)

5. Click **Enable**.  
   ![Enable](screenshots/step9_enable.png)

### 3. Configure OAuth Consent Screen

1. Go to **APIs & Services > OAuth consent screen**.  
   ![OAuth Consent Screen](screenshots/step10_oauth_consent.png)

2. Click **Get Started** (or similar).
   ![Get Started](screenshots/step11_get_started.png)

3. Fill in the required fields (App name, User support email).  
   ![App Info](screenshots/step12_app_info.png)

4. Select **External** (unless you are a G Suite user and want to limit to your organization) if prompted.   
   ![External User Type](screenshots/step13_external.png)

5. Add Developer contact information.  
   ![Contact Info](screenshots/step14_contact.png)

6. Continue through the steps.  
   ![Finish Consent Screen](screenshots/step15_finish.png)

### 4. Create Credentials

1. Go to **APIs & Services > Credentials**.  
2. Click **Create Credentials** and select **OAuth client ID**.  
   ![Create OAuth Client](screenshots/step16_create_oauth_client.png)

3. Application type: **Desktop app**.  
4. Name: Give it a name (e.g., "Mailer Server").  
5. Click **Create**.  
   ![Create Desktop OAuth](screenshots/step17_create_desktop_oauth.png)

### 5. Finalize

1. Add **Test Users**: Add the email address you intend to use for sending emails. *This is critical if your app is in "Testing" mode.*  
   ![Add Test Users](screenshots/step18_add_users.png)

2. You will see a popup with your **Client ID** and **Client Secret**. Copy these or download the JSON file.

## Step 2: Acquire Refresh Token

You need a `refreshToken` to access Gmail without user interaction. The `accessToken` expires quickly (usually 1 hour), but the `refreshToken` works indefinitely (with some exceptions).

The `mailer` package includes a script to help you get this token.

Run the `obtain_credentials.dart` script with your Client ID and Client Secret:

```bash
dart example/gmail_xoauth2/obtain_credentials.dart \
  --id "YOUR_CLIENT_ID" \
  --secret "YOUR_CLIENT_SECRET" \
  --username "your.email@gmail.com" \
  --file "secrets.json"
```

The script will:
1. Print a URL and attempt to open it in your default browser.
2. Ask you to log in to your Google Account and grant permissions.
3. Once accepted, it will save the `refreshToken`, `identifier`, `secret`, and `username` to `secrets.json`.

> [!NOTE]
> If the browser doesn't open automatically, copy the URL printed in the terminal and open it manually.

## Step 3: Use in Your Application

Now you can load these credentials in your server application to send emails.

Check the [send_mail.dart](../../example/gmail_xoauth2/send_mail.dart) example file to see how to use the credentials
to send an email.

Run the example:
```bash
dart example/gmail_xoauth2/send_mail.dart --file secrets.json --to recipient@example.com
```
