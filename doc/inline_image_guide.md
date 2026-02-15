# Using Inline Images

Sending HTML emails with inline images requires embedding the image as an attachment and referencing it in the HTML using a Content-ID (CID).

## Steps

1.  **Create an Attachment**: Create a `FileAttachment` or `StreamAttachment` for your image.
2.  **Set the Content-ID (`cid`)**: Assign a unique ID to the attachment's `cid` property.
3.  **Set the Location**: Ensure the attachment's `location` is set to `Location.inline`. The default is `Location.attachment`, so you must set this explicitly.
4.  **Reference in HTML**: Use `<img src="cid:YOUR_ID">` in your HTML body.

## Example

```dart
import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

main() async {
  var smtpServer = localhost(); // Replace with your server

  // Create the message
  var message = Message()
    ..from = Address('sender@example.com', 'Sender Name')
    ..recipients.add('recipient@example.com')
    ..subject = 'Inline Image Test'
    ..html = '''
      <h1>Look at this image!</h1>
      <img src="cid:my-image-id">
    ''';

  // Create the attachment
  var file = File('test/exploits_of_a_mom.png'); // Path to your image
  var attachment = FileAttachment(file)
    ..location = Location.inline
    ..cid = '<my-image-id>'; // The specific CID to reference in the HTML.
                             // The library automatically adds angle brackets < > around the CID if they are missing.  The id must contain an '@' symbol.
                             
  // Add attachment to message
  message.attachments.add(attachment);

  // Send
  await send(message, smtpServer);
}
```

## Notes

-   **CID Format**: The Content-ID should be globally unique. A common practice is `part1.timestamp@domain.com`.
    RFC 2392 requires a valid `addr-spec` which includes an `@` symbol. The library does not enforce this, but stricter clients might reject CIDs without an `@`.
-   **Angle Brackets**: The library automatically adds angle brackets `<` and `>` to the `Content-ID` header if they are missing. For example setting `cid` to `my-id` results in the header `Content-ID: <my-id>`.


