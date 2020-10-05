# Optimizely Swift SDK Changelog

## 3.5.0
October 2, 2020

### New Features
* Add versioning that follows semantic version types and tests. ([#333](https://github.com/optimizely/swift-sdk/pull/333))

### Bug Fixes
* Fixing log messages for Targeted Rollouts and feature variable evaluation. ([#337](https://github.com/optimizely/swift-sdk/pull/337))

## 3.4.1
September 22, 2020

### Bug Fixes
* Fix a bucketing error at traffic allocation boundaries. ([#365](https://github.com/optimizely/swift-sdk/pull/365))
* Update DataStore directory on macOS. ([#355](https://github.com/optimizely/swift-sdk/pull/355))

## 3.4.0
July 9, 2020

### New Features
* Add support for JSON feature variables. ([#315](https://github.com/optimizely/swift-sdk/pull/315), [#317](https://github.com/optimizely/swift-sdk/pull/317), [#318](https://github.com/optimizely/swift-sdk/pull/318))
* Add macOS Compatibility. ([#332](https://github.com/optimizely/swift-sdk/pull/332))

### Bug Fixes
* Add more audience evaluation logs. ([#336](https://github.com/optimizely/swift-sdk/pull/336))

## 3.3.2
May 21, 2020

### Bug Fixes
* Fix a decision bug for multi-rule rollouts ([#323](https://github.com/optimizely/swift-sdk/pull/323))
* Fix to forward resourceTimeout to datafileHandler ([#320](https://github.com/optimizely/swift-sdk/pull/320))

## 3.3.1
March 30, 2020

### Bug Fixes
* When a datafile download for initialization returns connection errors, the SDK fails to initialize. This is fixed to continue initialization with a cached datafile. ([#308](https://github.com/optimizely/swift-sdk/pull/308))
* Events are not stored persistently in the tvOS devices. ([#310](https://github.com/optimizely/swift-sdk/pull/310), [#311](https://github.com/optimizely/swift-sdk/pull/311))

## 3.3.0
March 11, 2020

This release includes an enhancement of SDK initialization API to enable SDK updated on cached datafile change. It also fixes known bugs.

### New Features
* Add an option for **synchronous** initialization to enable SDK immediately updated when a new datafile is cached. Unless this feature is enabled, by default, the cached datafile will be used only when the SDK re-starts in the next session. Note that this option is for **synchronous** initialization only. ([#297](https://github.com/optimizely/swift-sdk/pull/297))

	```
    // enable SDK update when a new datafile is cached
    optimizelyClient.start(datafile: data, doUpdateConfigOnNewDatafile: true)
    
    // by default, this feature is disabled
    optimizelyClient.start(datafile: data)
	```

### Bug Fixes
* When a **synchronously**-initialized SDK enables background datafile polling and its datafile was changed in the server, the new datafile is cached but SDK is not dynamically updated. ([#297](https://github.com/optimizely/swift-sdk/pull/297))
* When background datafile polling is enabled and app goes to background and comes back to foreground after some delays, datafile fetching is called multiple times back-to-back. ([#301](https://github.com/optimizely/swift-sdk/pull/301))
* NotificationCenter can cause crashes when multiple threads add/call listeners simultaneously. ([#304](https://github.com/optimizely/swift-sdk/pull/304))


## 3.2.1
January 16, 2020

### Bug Fixes
- Swift Package Manager (SPM) spec changed to iOS10+/tvOS10+


## 3.2.0
January 15, 2020

This release includes a new API to access project configuration data and other feature enhancements. It also fixes known bugs.

### New Features
* OptimizelyConfig ([#274](https://github.com/optimizely/swift-sdk/pull/274)):
    * Call `getOptimizelyConfig()` to get a snapshot copy of project configuration static data.
    * It returns an `OptimizelyConfig` instance which includes a datafile revision number, all experiments, and feature flags mapped by their key values.
    * For details, refer to a documentation page: https://docs.developers.optimizely.com/full-stack/docs/optimizelyconfig-swift
* Add LogEvent Notification ([#263](https://github.com/optimizely/swift-sdk/pull/263)):
    * Register an event listener with `addLogEventNotificationListener()`
    * The lister will be called when events are dispatched to the server.
* Turn on "Allow app extensions only" flag in build settings ([#277](https://github.com/optimizely/swift-sdk/pull/277))

### Bug Fixes
- When timerInterval is set to a negative value, EventDispatcher is changed to use the default interval value for batching (instead of disabling batch). Batching is  disabled when the timerInterval is set to zero.  ([#268](https://github.com/optimizely/swift-sdk/pull/268))

### Breaking Changes
- Upgrade required platforms from iOS9+/tvOS9+ to iOS10+/tvOS10+ ([#284](https://github.com/optimizely/swift-sdk/pull/284))


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
