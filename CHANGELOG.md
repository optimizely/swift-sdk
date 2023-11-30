# Optimizely Swift SDK Changelog

## 3.10.3
November 30, 2023

### Bug Fixes
* Remove redundant post request body in upload task. ([#521](https://github.com/optimizely/swift-sdk/pull/521/)).

### Ehancement
* Add privacy manifest file ([#522](https://github.com/optimizely/swift-sdk/pull/522/)).
* Handle duplicate keys in experiment ([#523](https://github.com/optimizely/swift-sdk/pull/523/)).

## 4.0.0-beta
May 1, 2023

### New Features  

The 4.0.0-beta release introduces a new primary feature, [Advanced Audience Targeting]( https://docs.developers.optimizely.com/feature-experimentation/docs/optimizely-data-platform-advanced-audience-targeting) enabled through integration with [Optimizely Data Platform (ODP)](https://docs.developers.optimizely.com/optimizely-data-platform/docs) ([#455](https://github.com/optimizely/swift-sdk/pull/455), [#470](https://github.com/optimizely/swift-sdk/pull/470), [#471](https://github.com/optimizely/swift-sdk/pull/471), [#477](https://github.com/optimizely/swift-sdk/pull/477)). 

You can use ODP, a high-performance [Customer Data Platform (CDP)]( https://www.optimizely.com/optimization-glossary/customer-data-platform/), to easily create complex real-time segments (RTS) using first-party and 50+ third-party data sources out of the box. You can create custom schemas that support the user attributes important for your business, and stitch together user behavior done on different devices to better understand and target your customers for personalized user experiences. ODP can be used as a single source of truth for these segments in any Optimizely or 3rd party tool.  

With ODP accounts integrated into Optimizely projects, you can build audiences using segments pre-defined in ODP. The SDK will fetch the segments for given users and make decisions using the segments. For access to ODP audience targeting in your Feature Experimentation account, please contact your Customer Success Manager. 

This version includes the following changes: 

* New API added to `OptimizelyUserContext`: 

	- `fetchQualifiedSegments()`: this API will retrieve user segments from the ODP server. The fetched segments will be used for audience evaluation. The fetched data will be stored in the local cache to avoid repeated network delays. 

	- When an `OptimizelyUserContext` is created, the SDK will automatically send an identify request to the ODP server to facilitate observing user activities. 

* New APIs added to `OptimizelyClient`: 

	- `sendOdpEvent()`: customers can build/send arbitrary ODP events that will bind user identifiers and data to user profiles in ODP. 

	- `createUserContext()` with anonymous user IDs: user-contexts can be created without a userId. The SDK will create and use a persistent `VUID` specific to a device when userId is not provided. 

For details, refer to our documentation pages:  

* [Advanced Audience Targeting](https://docs.developers.optimizely.com/feature-experimentation/docs/optimizely-data-platform-advanced-audience-targeting)  

* [Client SDK Support](https://docs.developers.optimizely.com/feature-experimentation/v1.0/docs/advanced-audience-targeting-for-client-side-sdks) 

* [Initialize Swift SDK](https://docs.developers.optimizely.com/feature-experimentation/docs/initialize-sdk-swift) 

* [OptimizelyUserContext Swift SDK](https://docs.developers.optimizely.com/feature-experimentation/docs/optimizelyusercontext-swift) 

* [Advanced Audience Targeting segment qualification methods](https://docs.developers.optimizely.com/feature-experimentation/docs/advanced-audience-targeting-segment-qualification-methods-swift) 

* [Send Optimizely Data Platform data using Advanced Audience Targeting](https://docs.developers.optimizely.com/feature-experimentation/docs/send-odp-data-using-advanced-audience-targeting-swift) 

### Breaking Changes 

* `ODPManager` in the SDK is enabled by default. Unless an ODP account is integrated into the Optimizely projects, most `ODPManager` functions will be ignored. If needed, `ODPManager` can be disabled when `OptimizelyClient` is instantiated. 

 

## 3.10.2
March 14, 2023

* We updated our README.md and other non-functional code to reflect that this SDK supports both Optimizely Feature Experimentation and Optimizely Full Stack. ([#479](https://github.com/optimizely/swift-sdk/pull/479)).

## 3.10.1
April 8, 2022

### Bug Fixes
* Remove sources of race conditions in ProjectConfig ([#449](https://github.com/optimizely/swift-sdk/pull/449)).
* Clean up URLSession after tasks are completed ([#446](https://github.com/optimizely/swift-sdk/pull/446)).

## 3.10.0
January 6, 2022

### New Features
* Add a set of new APIs for overriding and managing user-level flag, experiment and delivery rule decisions. These methods can be used for QA and automated testing purposes. They are an extension of the OptimizelyUserContext interface ([#431](https://github.com/optimizely/swift-sdk/pull/431), [#442](https://github.com/optimizely/swift-sdk/pull/442), [#443](https://github.com/optimizely/swift-sdk/pull/443)):
	- setForcedDecision
	- getForcedDecision
	- removeForcedDecision
	- removeAllForcedDecisions

	For details, refer to our documentation pages: [OptimizelyUserContext](https://docs.developers.optimizely.com/full-stack/v4.0/docs/optimizelyusercontext-swift) and [Forced Decision methods](https://docs.developers.optimizely.com/full-stack/v4.0/docs/forced-decision-methods-swift).

* Add reachability checking for datafile fetch and event dispatching ([#439](https://github.com/optimizely/swift-sdk/pull/439)).

## 3.9.0
September 15, 2021

### New Features
* Add new public properties to `OptimizelyConfig`. ([#417](https://github.com/optimizely/swift-sdk/pull/417), [#418](https://github.com/optimizely/swift-sdk/pull/418))
	- sdkKey
 	- environmentKey
	- attributes
	- audiences
	- events
	- experimentRules and deliveryRules to `OptimizelyFeature`
	- audiences to `OptimizelyExperiment`
* For details, refer to our documentation page: [https://docs.developers.optimizely.com/full-stack/v4.0/docs/optimizelyconfig-swift](https://docs.developers.optimizely.com/full-stack/v4.0/docs/optimizelyconfig-swift).

### Deprecated

* `OptimizelyFeature.experimentsMap` of `OptimizelyConfig` is deprecated as of this release. Please use `OptimizelyFeature.experimentRules` and `OptimizelyFeature.deliveryRules`. ([#418](https://github.com/optimizely/swift-sdk/pull/418))


## 3.8.1
August 6, 2021

### Bug Fixes
* Remove lazy initializations for thread safety. ([#422](https://github.com/optimizely/swift-sdk/pull/422))


## 3.8.0
June 2, 2021

### New Features
* Fix to support multiple clients (sdkKeys). ([#401](https://github.com/optimizely/swift-sdk/pull/401), [#402](https://github.com/optimizely/swift-sdk/pull/402), [#405](https://github.com/optimizely/swift-sdk/pull/405), [#406](https://github.com/optimizely/swift-sdk/pull/406), [#407](https://github.com/optimizely/swift-sdk/pull/407), [#408](https://github.com/optimizely/swift-sdk/pull/408), [#409](https://github.com/optimizely/swift-sdk/pull/409), [#410](https://github.com/optimizely/swift-sdk/pull/410))

   - Full thread-safety for additional concurrency requirements
   - No resource conflicts for multiple sdkKeys support

### Bug Fixes
* BUILD\_LIBRARY\_FOR\_DISTRIBUTION is turned on to support ABI when clients build own binaries and share within the team. ([#403](https://github.com/optimizely/swift-sdk/pull/403))


## 3.7.1
April 14, 2021

### New Features
* DatafileHandler can be customized and set when OptimizelyClient is instantiated. ([#384](https://github.com/optimizely/swift-sdk/pull/384))
* Add watchOS Compatibility. ([#390](https://github.com/optimizely/swift-sdk/pull/390))

### Bug Fixes
* Clean up build and lint warnings. ([#397](https://github.com/optimizely/swift-sdk/pull/397))


## 3.7.0
February 23, 2021

### New Features
* Introducing a new primary interface for retrieving feature flag status, configuration and associated experiment decisions for users ([#373](https://github.com/optimizely/swift-sdk/pull/373), [#386](https://github.com/optimizely/swift-sdk/pull/386)). The new `OptimizelyUserContext` class is instantiated with `createUserContext` and exposes the following APIs to get `OptimizelyDecision`:

	- setAttribute
	- decide
	- decideAll
	- decideForKeys
	- trackEvent

* For details, refer to our documentation page: [https://docs.developers.optimizely.com/full-stack/v4.0/docs/swift-sdk](https://docs.developers.optimizely.com/full-stack/v4.0/docs/swift-sdk).

### Bug Fixes
* Fix a synchronization bug with logger injection (the binder is being updated every inject), which caused rare app crashes. ([#387](https://github.com/optimizely/swift-sdk/pull/387))


## 3.6.1
November 19, 2020

### New Features
* Add "enabled" field to decision metadata structure. ([#376](https://github.com/optimizely/swift-sdk/pull/376))

## 3.6.0
November 4, 2020

### New Features
* Add support for upcoming application-controlled introduction of tracking for non-experiment Flag decisions. ([#370](https://github.com/optimizely/swift-sdk/pull/370))

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
