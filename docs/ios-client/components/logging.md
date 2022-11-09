# Logging

The Guide Dogs iOS client contains a logging framework build on top of [CocoaLumberjack](https://github.com/CocoaLumberjack/CocoaLumberjack).

## Usage and Log Levels

To use the framework, replace `NSLog` (Objective-C) and `print` (Swift) statements with one of the following:

* Specific Modules
  * `GDLogNetwork` For network logging
  * `GDLogSound` For audio logging
  * See more in `LoggingContext.swift`
* Others
  * `DDLogVerbose`
  * `DDLogDebug`
  * `DDLogInfo`
  * `DDLogWarn`
  * `DDLogError`

## Loggers

When logging a message, it is sent to all available [*loggers*](https://github.com/CocoaLumberjack/CocoaLumberjack/blob/master/Documentation/Architecture.md). These currently include:

* Xcode Console
* Apple System
* File
* Bluetooth

### Xcode Console

Logs to the Xcode debug console.

### Apple System

Logs to the Apple System. Logs can be viewed in the *Console* app, Xcode *Devices* and other supported applications.

### File

Persists logs to files on the device.

## Log Formatter

Each logger contains a *log formatter* to format the log's output message. We use a custom formatter *LogFormatter.swift* and we can customize it in order to change the logs output style.

Current log format: <br>
**[date] [flag] [function] [line]: [message]**
> 2016-12-02 18:39:33:967 Ⓥ open()(40): file opened
