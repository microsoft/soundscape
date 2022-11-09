# Push Notifications

The iOS push service backend is the Azure Notification Hub.

Here are the options to send push notifications:

## Azure Portal (Test Only)

Currently, the Azure portal is able to send to a random 10 devices or to a tag expression.

1. Open `https://ms.portal.azure.com/`
2. Find and open the notification hub resource
3. In the right menu, select "Test Send"
4. Select "Platform" -> "Apple"
5. Add payload (see "Payload Example")

## HTTP `POST` Request (via Postman)

1. In Postman, Create a new request of type `POST`
2. Enter URL: `https://{NotificationHub}/messages/?api-version=2015-01`
3. Add header: `Content-Type`: `application/json;charset=utf-8`
4. Add header: `ServiceBusNotification-Format`: `apple`
5. Add header: `Authorization`: `{{azure-authorization}}`
6. Add header: `ServiceBusNotification-Tags`: `{single tag identifier}` (if needed)

### Creating a Soundscape Environment

You will notice in Postman that after entering the header `Authorization`: `{{azure-authorization}}` that it will display in the Value field in red. You now need to create a Soundscape environment as follows:

1. Select the Settings cog to the right of the Environment drop down (top right)
2. Select **Manage Environments**
3. Select the **Add** button
4. Enter the **Environment Name** e.g. 'Soundscape Environment'
5. Tap in the **New Key** field and enter **azure-authorization**
6. Enter the value *temp* (for now)
7. Select the **Add** button
8. Close the UI

Now on the main UI select the Environment drop-down and select the environment that you just created. You will now notice that `{{azure-authorization}}` will change to orange in color.

Open the "Pre-request Script" tab and add the following code:

```js
function generateAuthHeader(resourceUri, keyName, key) {
  const date = new Date();
  const sinceEpoch = Math.round(date.getTime() / 1000);
  const expiry = (sinceEpoch + 3600);

  const stringToSign = `${encodeURIComponent(resourceUri)}\n${expiry}`;

  const hash = CryptoJS.HmacSHA256(stringToSign, key);
  const hashInBase64 = CryptoJS.enc.Base64.stringify(hash);

  const sasToken = `SharedAccessSignature sr=${encodeURIComponent(resourceUri)}&sig=${encodeURIComponent(hashInBase64)}&se=${expiry}&skn=${keyName}`;

  return sasToken;
}

postman.setEnvironmentVariable('azure-authorization', generateAuthHeader(request['url'], "KEY_NAME", "KEY"));
```

Replace `KEY_NAME` and `KEY` with your credential (see "Finding your key and key name").

Open the "Body" tab, select "raw" and add payload (see "Payload Example").

If all goes well you should receive response with status `201 Created`.

## Sending Notifications to Specific Devices

While testing, sending a request with header `ServiceBusNotification-DeviceHandle` and the device token sends the notification to all devices.

Using header: `ServiceBusNotification-DeviceHandle`: `Enter device APNs token`  

<https://docs.microsoft.com/en-us/rest/api/notificationhubs/direct-send>

To get around that for testing, we can use `Tags`:

Tags allow sending push notifications to users who registered to specific tags, imaging a news app where the user registered to receive notifications only for tags `sports` and `politics`.

<https://docs.microsoft.com/en-us/azure/notification-hubs/notification-hubs-tags-segment-push-message>

Note about tags:

- A tag can be any string, up to 120 characters, containing alphanumeric and the following non-alphanumeric characters: `_`, `@`, `#`, `.`, `:`, `-`.  
- The Azure Notification Hubs supports a maximum of 60 tags per registration.

The iOS app has default global tags that can be used:

```text
device.model:{value}
device.os.version:{value}
device.voice_over:{value}

app.version:{value}
app.build:{value}
app.source:{value}

app.language:{value}
app.region:{value}
```

### Sending Notifications with tags

Using a POST request noted above, add the `ServiceBusNotification-Tags` header with the tag as the value.

For, one combination for the header can be:

```http
Header: ServiceBusNotification-Tags
Value: (app.language:en && app.region:us)
```

## Payload Example

```json
{
  "aps": {
    "alert": {
      "title": "Title",
      "subtitle": "Subtitle",
      "body": "Body"
    },
    "sound": "default"
  },
  "url": "https://example.com"
}
```

### Notes

- Only add what is need. `title`, `subtitle`, `body`, `sound` and `url` are optional, but you need at least one of `title`, `subtitle`, `body`.
- To send push with sound, use `"sound": "default"`, for push without sound don't add the `sound` object.
- Add `url` only if you want the app to show an alert with an "Open" button action to open the url in an in-app browser.

## Finding your key and key name

1. Open `https://ms.portal.azure.com/`
2. Find and open the notification hub resource
3. Access Policies
4. `SharedAccessKeyName` is the `KEY_NAME` and the `SharedAccessKey` is the `KEY`
