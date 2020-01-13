# Optimizely Swift SDK Changelog

## 3.2.0
January 14, 2020

This release includes a new API to access project configuration data and other feature enhancements. it also fixes a few small bugs.

### New Features
* OptimizelyConfig ([#274](https://github.com/optimizely/swift-sdk/pull/274)):
    * Call `getOptimizelyConfig()` to get a snapshot copy of project configuration static data.
    * It returns an `OptimizelyConfig` instance which includes a datafile revision number, all experiments, and feature flags mapped by their key values.
    * For details, refer to a documention page: https://docs.developers.optimizely.com/full-stack/docs/optimizelyconfig-swift
* Add LogEvent Notification ([#263](https://github.com/optimizely/swift-sdk/pull/263)):
    * Register an event listner with `addLogEventNotificationListener()`
    * The lister will be called when events are dispatched to the server.
* Turn on "Allow app extensions only" flag in build settings to support App Extension ([#277](https://github.com/optimizely/swift-sdk/pull/277))

### Bug Fixes
- When timerInterval is set to a negative value, EventDispatcher is changed to use the default interval value for batching (instead of disabling batch). Batching is  disabled when the timerInterval is set to zero.  ([#268](https://github.com/optimizely/swift-sdk/pull/268))

### Breaking Changes


## 3.1.0
July 31, 2019

This release is the GA launch of the Swift SDK. It is a pure Swift implementation which takes complete advantage of language features and performance.  It supports Objective-C applications as well. 

This modernized version of the SDK is meant to replace the Objective-C SDK.

### New Features
In addition to all features and APIs support of the Objective-C SDK, this new SDK also adds the following new features:

* By default the datafile handler does updates every 10 minutes when the application is in the foreground.  To disable this, set the periodicUpdateInterval to zero.  If you do allow for polling, the project will update automatically when a new datafile change is received. 
* On top of the above functionality, the developer may register for a datafile change notification.  This notification will be called anytime a new datafile is downloaded to cache and is used to reinitialize the optimizely client automatically.
* The event handler batches events and will run every minute in the foreground to send events.  If there are no events in the queue it will not reschedule.

### Bug Fixes

### Breaking Changes


## 3.1.0-beta
May 30, 2019

This is the initial release of the Swift SDK. It is a pure Swift implementation which takes complete advantage of language features and performance.  It supports Objective-C applications as well. It uses Swift 4.2 but we will be upgrading to 5.0 soon.

This modernized version of the SDK is meant to replace the Objective-C SDK.

### New Features
* By default the datafile handler does updates every 10 minutes when the application is in the foreground.  To disable this, set the periodicUpdateInterval to zero.  If you do allow for polling, the project will update automatically when a new datafile change is received. 
* On top of the above functionality, the developer may register for a datafile change notification.  This notification will be called anytime a new datafile is downloaded to cache and is used to reinitialize the optimizely client automatically.
* The event handler batches events and will run every minute in the foreground to send events.  If there are no events in the queue it will not reschedule.

### Bug Fixes

### Breaking Changes
