# Optimizely Swift SDK
[![Apache 2.0](https://img.shields.io/github/license/nebula-plugins/gradle-extra-configurations-plugin.svg)](http://www.apache.org/licenses/LICENSE-2.0)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/carthage/carthage)
[![Build Status](https://github.com/optimizely/swift-sdk/actions/workflows/swift.yml/badge.svg?branch=master)](https://github.com/optimizely/swift-sdk/actions)
[![Coverage Status](https://coveralls.io/repos/github/optimizely/swift-sdk/badge.svg?branch=master)](https://coveralls.io/github/optimizely/swift-sdk?branch=master)
[![Platforms](https://img.shields.io/cocoapods/p/OptimizelySwiftSDK.svg)](https://img.shields.io/cocoapods/p/OptimizelySwiftSDK.svg)
[![Podspec](https://img.shields.io/cocoapods/v/OptimizelySwiftSDK.svg)](https://cocoapods.org/pods/OptimizelySwiftSDK)

This repository houses the Swift SDK for use with Optimizely Feature Experimentation and Optimizely Full Stack (legacy) for Mobile and OTT.

Optimizely Feature Experimentation is an A/B testing and feature management tool for product development teams, enabling you to experiment at every step. Using Optimizely Feature Experimentation allows for every feature on your roadmap to be an opportunity to discover hidden insights. Learn more at [Optimizely.com](https://www.optimizely.com/products/experiment/feature-experimentation/), or see the [developer documentation](https://docs.developers.optimizely.com/experimentation/v4.0.0-full-stack/docs/welcome).

Optimizely Rollouts is [free feature flags](https://www.optimizely.com/free-feature-flagging/) for development teams. You can easily roll out and roll back features in any application without code deploys, mitigating risk for every feature on your roadmap.


## Get started

### Use the Swift SDK

Refer to the [Swift SDK's developer documentation](https://docs.developers.optimizely.com/experimentation/v4.0.0-full-stack/docs/swift-sdk) for detailed instructions on getting started with using the SDK.

### Requirements
* iOS 10.0+ / tvOS 10.0+ / watchOS 3.0+
* Swift 5+

### Install the SDK
 
Please note below that _\<platform\>_ is used to represent the platform on which you are building your app. Currently, we support ```iOS```, ```tvOS```, and ```watchOS``` platforms.

#### Swift Package Manager
Add the dependency on the Optimizely Swift SDK with Swift Package Manager in `Xcode`

1. `File` -> `Swift Packages` -> `Add Package Dependency`
2. Enter `https://github.com/optimizely/swift-sdk`.
3. Accept the default rules (`Version: 'Up to Next Major'`).

If you have a name conflict with other swift packages when you add the Optimizely swift-sdk dependency to Xcode, you can also try with its aliased repo: "https://github.com/optimizely/optimizely-swift-sdk.git".

#### CocoaPods 
1. Add the following lines to the _Podfile_:<pre>
```use_frameworks!```
```pod 'OptimizelySwiftSDK', '~> 5.1.1'```
</pre>

2. Run the following command: <pre>``` pod install ```</pre>

Further installation instructions for Cocoapods: https://guides.cocoapods.org/using/getting-started.html

#### Carthage
1. Add the following lines to the _Cartfile_:<pre>```github "optimizely/swift-sdk" ~> 4.1.0```</pre>

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

### Feature Management Access

To access the Feature Management configuration in the Optimizely dashboard, please contact your Optimizely customer success manager.

## Use the Swift SDK

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

See the Optimizely Feature Experimentation [developer documentation](https://docs.developers.optimizely.com/experimentation/v4.0-full-stack/docs/swift-sdk) to learn how to set up your first Swift project and use the SDK.


### Contributing
Please see [CONTRIBUTING](CONTRIBUTING.md).

### Credits

First-party code (under OptimizelySwiftSDK is copyright Optimizely, Inc. and contributors, licensed under Apache 2.0.)

### Additional Code

This software incorporates code from the following open source projects:

MurmurHash3:https://github.com/jpedrosa/sua/blob/master/Sources/murmurhash3.swift License (Apache 2.0):https://github.com/jpedrosa/sua/blob/master/LICENSE.txt
Ported to Swift4.

SwiftLint:https://github.com/realm/SwiftLint License (MIT):https://github.com/realm/SwiftLint/blob/master/LICENSE
Used to enforce Swift style and conventions.

### Other Optimizely SDKs

- Agent - https://github.com/optimizely/agent

- Android - https://github.com/optimizely/android-sdk

- C# - https://github.com/optimizely/csharp-sdk

- Flutter - https://github.com/optimizely/optimizely-flutter-sdk

- Go - https://github.com/optimizely/go-sdk

- Java - https://github.com/optimizely/java-sdk

- JavaScript - https://github.com/optimizely/javascript-sdk

- PHP - https://github.com/optimizely/php-sdk

- Python - https://github.com/optimizely/python-sdk

- React - https://github.com/optimizely/react-sdk

- Ruby - https://github.com/optimizely/ruby-sdk
  
