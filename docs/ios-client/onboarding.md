# Soundscape iOS App

This document describes how to build and run the Soundscape iOS app.

## Supported Tooling Versions

As of Soundscape version 5.3.1 (October 2022):

* macOS 12.6.1
* Xcode 13.4.1
* iOS 14.1
* CocoaPods 1.11.3
* CocoaPods Patch 1.0.2

## Install Xcode

The Soundscape iOS app is developed on the Xcode IDE.

Download Xcode from the [App Store](https://apps.apple.com/us/app/xcode/id497799835?mt=12) or the [Apple Developer website](http://developer.apple.com).

## Install Xcode Command Line Tools

Open Xcode and you should be prompted with installing the command line tools, or  run this in a Terminal window:

```sh
xcode-select --install
```

## Install CocoaPods and CocoaPods-Patch

Soundscape uses [CocoaPods](https://cocoapods.org/) as a dependency managers along with [Swift Package Manager](https://www.swift.org/package-manager/), and [CocoaPods-Patch](https://github.com/DoubleSymmetry/cocoapods-patch) to add changes to a third party CocoaPods framework.

_Note:_ before the next step, make sure you have [Ruby](https://www.ruby-lang.org/) installed on your machine.

In the iOS project folder, run the following command to install the dependencies from the `Gemfile`:

```sh
bundle install
```

## Install CocoaPods Dependencies

Install the CocoaPods dependencies by running the following command in Terminal:

```sh
pod install
```

## Opening the Project

At this point, you can open the `GuideDogs.xcworkspace` file, which is the main entry point to the Xcode project.

## Add Azure Notification Hub Secrets

Soundscape uses Azure Notification Hub to send push notifications to users. In order for this to work in your app, you will need to create an account in [Azure](https://azure.microsoft.com).

In your Azure account:

1. Setup a Notification Hubs service (you can have one for Production and one for AdHoc)
2. Copy the connection strings and paths
3. Open the project file at `/Soundscape/Assets/PropertyLists/Info.plist`
4. Copy the to the following keys and values:
   1. `SOUNDSCAPE_AZURE_NH_CONNECTION_STRING` - The production connection string
   2. `SOUNDSCAPE_AZURE_NH_PATH` - The production Notification Hub path
   3. `SOUNDSCAPE_AZURE_DF_NH_CONNECTION_STRING` - The adhoc connection string
   4. `SOUNDSCAPE_AZURE_DF_NH_PATH` - The adhoc Notification Hub path

If these values are not set, receiving push notifications will not work.

## Add Your Services URLs

Soundscape uses a backend service to download map tiles and other information. In the following files, replace the static URL properties with the address of your services.

* `ServiceModel.swift`
* `UniversalLinkComponents.swift`

## Building and Running

At this point, you should be able to build and run the `Soundsacpe` target on an iOS simulator. In order to run the app on a real device, you will need to add your Apple Developer account signing info in the _Signing & Capabilities_ section of the project settings.

## Additional Personalization

Additional personalization options:

* In the _General_ section of the project settings, you can change the following properties:
  * `Display Name`
  * `Bundle Identifier`
* In the _Build Settings_ section of the project settings, you can change the following properties:
  * `Primary App Icon Set Name`
  * `BUNDLE_SPOKEN_NAME`
* In `AppContext.swift` you can change the following properties:
  * `appDisplayName`
  * `appStoreId`
* Do a general search and replace instances of `CompanyName` and `AppName`.
* Do a general search for `TODOs` and make changes as needed.
