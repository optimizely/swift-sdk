# Optimizely Swift SDK Changelog

## 3.1.0-beta
May 29, 2019

This is the initial release of the Swift SDK. It is a pure Swift implementation which takes complete advantage of language features and performance.  It supports Objective-C applications as well. It uses Swift 4.2 but we will be upgrading to 5.0 soon.

This modernized version of the SDK is meant to replace the Objective-C SDK.

### New Features
* By default the datafile handler does updates every 10 minutes when the application is in the foreground.  To disable this, set the periodicUpdateInterval to zero.  If you do allow for polling, the project will update automatically when a new datafile change is received. 
* On top of the above functionality, the developer may register for a datafile change notification.  This notification will be called anytime a new datafile is downloaded to cache and is used to reinitialize the optimizely client automatically.
* The event handler batches events and will run every 5 minutes in the foreground to send events. 

### Bug Fixes:

### Breaking Changes
