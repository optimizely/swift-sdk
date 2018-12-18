# SWIFT SDK
[![Apache 2.0](https://img.shields.io/github/license/nebula-plugins/gradle-extra-configurations-plugin.svg)](http://www.apache.org/licenses/LICENSE-2.0)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/carthage/carthage)

This repository houses the Optimizely Mobile and OTT experimentation SDKs.


## Getting Started

### Using the SDK

See the [Mobile developer documentation](https://developers.optimizely.com/x/solutions/sdks/reference/index.html?language=objectivec&platform=mobile) or [OTT developer documentation](https://developers.optimizely.com/x/solutions/sdks/reference/index.html?language=objectivec&platform=ott) to learn how to set
up an Optimizely X project and start using the SDK.

### Requirements
* iOS 8.0+ / tvOS 9.0+

### Installing the SDK
 
Please note below that _\<platform\>_ is used to represent the platform on which you are building your app. Currently, we support ```iOS``` and ```tvOS``` platforms.

#### Cocoapod 
1. Add the following lines to the _Podfile_:<pre>
    ```use_frameworks!```
    ```pod 'OptimizelySDK', :git => 'https://github.com/optimizely/swift-sdk.git', :branch => 'master'```
  ```pod 'OptimizelySDK', :path => '~/Development/swift-sdk'```
</pre>

2. Run the following command: <pre>``` pod install ```</pre>

Further installation instructions for Cocoapods: https://guides.cocoapods.org/using/getting-started.html

We haven't actually published to Cocoapods yet.  

#### Carthage
1. Add the following lines to the _Cartfile_:<pre> 
github "optimizely/swift-sdk" "master"
</pre>

2. Run the following command:<pre>```carthage update```</pre>

3. Link the frameworks to your project. Go to your project target's **Link Binary With Libraries** and drag over the following from the _Carthage/Build/\<platform\>_ folder: <pre> 
      OptimizelySDK.framework

4. To ensure that proper bitcode-related files and dSYMs are copied when archiving your app, you will need to install a Carthage build script:
      - Add a new **Run Script** phase in your target's **Build Phase**.</br>
      - In the script area include:<pre>
      ```/usr/local/bin/carthage copy-frameworks```</pre> 
      - Add the frameworks to the **Input Files** list:<pre>
            ```$(SRCROOT)/Carthage/Build/<platform>/OptimizelySDK.framework```
            </pre>

Futher installation instructions for Carthage: https://github.com/Carthage/Carthage

```
        let optimizely = OptimizelyManager.Builder().build()
        
        if let optimizely = optimizely?.initialize(datafile:json) {
            let variation = optimizely.activate(experimentKey: "background_experiment", userId: "userId", attributes: ["doubleKey":5])
            
            let basicVariation = optimizely.track(eventKey: "sample_conversion", userId: "userId")
            }
```
