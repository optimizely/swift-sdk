# SWIFT SDK
[![Apache 2.0](https://img.shields.io/github/license/nebula-plugins/gradle-extra-configurations-plugin.svg)](http://www.apache.org/licenses/LICENSE-2.0)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/carthage/carthage)
[![Build Status](https://travis-ci.com/optimizely/swift-sdk.svg?branch=master)](https://travis-ci.com/optimizely/swift-sdk)
[![Coverage Status](https://coveralls.io/repos/github/optimizely/swift-sdk/badge.svg?branch=master)](https://coveralls.io/github/optimizely/swift-sdk?branch=master)

This repository houses the Swift SDK for use with Optimizely Full Stack and Optimizely Rollouts for Mobile and OTT.

Optimizely Full Stack is A/B testing and feature flag management for product development teams. Experiment in any application. Make every feature on your roadmap an opportunity to learn. Learn more at https://www.optimizely.com/platform/full-stack/, or see the [documentation](https://docs.developers.optimizely.com/full-stack/docs).

Optimizely Rollouts is free feature flags for development teams. Easily roll out and roll back features in any application without code deploys. Mitigate risk for every feature on your roadmap. Learn more at https://www.optimizely.com/rollouts/, or see the [documentation](https://docs.developers.optimizely.com/rollouts/docs).


## Getting Started

### Using the SDK

See the [Mobile developer documentation](https://docs.developers.optimizely.com/full-stack/docs/install-the-swift-sdk) to learn how to set
up an Optimizely X project and start using the SDK.

### Requirements
* iOS 9.0+ / tvOS 9.0+
* Swift 5+

### Installing the SDK
 
Please note below that _\<platform\>_ is used to represent the platform on which you are building your app. Currently, we support ```iOS``` and ```tvOS``` platforms.

#### CocoaPods 
1. Add the following lines to the _Podfile_:<pre>
	```use_frameworks!```
    ```pod 'OptimizelySwiftSDK', '~> 3.1.0'```
    </pre>

2. Run the following command: <pre>``` pod install ```</pre>

Further installation instructions for Cocoapods: https://guides.cocoapods.org/using/getting-started.html

#### Carthage
1. Add the following lines to the _Cartfile_:<pre>```github "optimizely/swift-sdk" ~> 3.1.0```</pre>

2. Run the following command:<pre>```carthage update```</pre>

3. Link the frameworks to your project. Go to your project target's **Link Binary With Libraries** and drag over the following from the _Carthage/Build/\<platform\>_ folder: <pre>```Optimizely.framework```</pre>

4. To ensure that proper bitcode-related files and dSYMs are copied when archiving your app, you will need to install a Carthage build script:
      - Add a new **Run Script** phase in your target's **Build Phase**.</br>
      - In the script area include:<pre>
      ```/usr/local/bin/carthage copy-frameworks```</pre>
      - Add the frameworks to the **Input Files** list:<pre>
      ```$(SRCROOT)/Carthage/Build/<platform>/Optimizely.framework```</pre>
      - Add the paths to the copied frameworks to the Output Files list:<pre>
      ```$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/Optimizely.framework```</pre>

Futher installation instructions for Carthage: https://github.com/Carthage/Carthage

#### Swift Package Manager
 Add the following line to the dependencies value of your _Package.swift_:

```
dependencies: [
    .package(url: "https://github.com/optimizely/swift-sdk.git", "3.1.0"..<"3.2.0")
]
```

### Samples

A sample code for SDK initialization and experiments:

```
let optimizely = OptimizelyClient(sdkKey:"somesdkkey")

optimizely.start{ result in
    do {
        let variation = try optimizely.activate(experimentKey: "background_experiment", userId: "userId", attributes: ["doubleKey":5])
        try optimizely.track(eventKey: "sample_conversion", userId: "userId")
    } catch {
        print(error)
    }
}
```


### Contributing
Please see [CONTRIBUTING](CONTRIBUTING.md).

### Credits

First-party code (under OptimizelySwiftSDK is copyright Optimizely, Inc. and contributors, licensed under Apache 2.0.

### Additional Code

This software incorporates code from the following open source repo:

For the SDK:
MurmurHash3:https://github.com/jpedrosa/sua/blob/master/Sources/murmurhash3.swift License (Apache 2.0):https://github.com/jpedrosa/sua/blob/master/LICENSE.txt
Ported to Swift4.

SwiftLint:https://github.com/realm/SwiftLint License (MIT):https://github.com/realm/SwiftLint/blob/master/LICENSE
Used to enforce Swift style and conventions.

