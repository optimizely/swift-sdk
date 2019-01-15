/****************************************************************************
 * Copyright 2017-2018, Optimizely, Inc. and contributors                   *
 *                                                                          *
 * Licensed under the Apache License, Version 2.0 (the "License");          *
 * you may not use this file except in compliance with the License.         *
 * You may obtain a copy of the License at                                  *
 *                                                                          *
 *    http://www.apache.org/licenses/LICENSE-2.0                            *
 *                                                                          *
 * Unless required by applicable law or agreed to in writing, software      *
 * distributed under the License is distributed on an "AS IS" BASIS,        *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
 * See the License for the specific language governing permissions and      *
 * limitations under the License.                                           *
 ***************************************************************************/

import UIKit
import OptimizelySwiftSDK
#if os(iOS)
    import Amplitude_iOS
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var optimizely: OPTManager?
    
    // generate random user ID on each app load
    let userId = String(Int(arc4random_uniform(300000)))
    
    // customizable settings
    let datafileName = "demoTestDatafile"
    let experimentKey = "background_experiment"
    let eventKey = "sample_conversion"
    let attributes = ["browser_type": "safari"]
    let sdkKey = "AqLkkcss3wRGUbftnKNgh2"
    
    
    func applicationDidFinishLaunching(_ application: UIApplication) {
        // (1) asynchronous SDK initialization
        //     - fetch a JSON datafile from the server
        //     - network delay, but the local configuration is in sync with the server experiment settings
        initializeOptimizelySDKAsynchronous()
        
        // (2) synchronous SDK initialization
        //     - initialize immediately with the given JSON datafile or its cached copy
        //     - no network delay, but the local copy is not guaranteed to be in sync with the server experiment settings
  ////      initializeOptimizelySDKSynchronous()
    }
    
    func initializeOptimizelySDKAsynchronous() {
        optimizely = OPTManager(sdkKey: sdkKey)
        
        // initialize Optimizely Client from a datafile download
        optimizely!.initializeSDK { result in
            switch result {
            case .failure(let error):
                print("Optimizely SDK initiliazation failed: \(error)")
                self.optimizely = nil
            case .success:
                print("Optimizely SDK initialized successfully!")
            }
            
            self.startAppWithExperimentActivated()
        }
    }
    
    func initializeOptimizelySDKSynchronous() {
        // customization example (optional)
        let customNotificationCenter = makeCustomNotificationCenter()
        
        optimizely = OPTManager(sdkKey: sdkKey,
                                notificationCenter: customNotificationCenter)

        guard let localDatafilePath = Bundle(for: self.classForCoder).path(forResource: datafileName, ofType: "json") else {
            fatalError("Local datafile cannot be found")
        }

        do {
            let datafileJSON = try String(contentsOfFile: localDatafilePath, encoding: .utf8)
            try optimizely!.initializeSDK(datafile: datafileJSON)
            print("Optimizely SDK initialized successfully!")
        } catch is DecodingError {
            fatalError("Invalid JSON format")
        } catch {
            print("Optimizely SDK initiliazation failed: \(error)")
            optimizely = nil
        }
        
        startAppWithExperimentActivated()
    }
    
    func startAppWithExperimentActivated() {
        var variationKey: String?
        
        do {
            variationKey = try self.optimizely?.activate(experimentKey: experimentKey,
                                                         userId: userId,
                                                         attributes: attributes)
        } catch {
            print("Optimizely SDK activation failed: \(error)")
            self.optimizely = nil
        }
        
        self.setRootViewController(optimizelyManager: self.optimizely, bucketedVariation: variationKey)
    }
    

    func makeCustomNotificationCenter() -> OPTNotificationCenter {
        #if os(tvOS)
            return CustomNotificationCenter()
        #else
        
        
        // most of the third-party integrations only support iOS, so the sample code is only targeted for iOS builds
        Amplitude.instance().initializeApiKey("YOUR_API_KEY_HERE")
        
        let notificationCenter = CustomNotificationCenter()
        
        notificationCenter.addActivateNotificationListener { (experiment, userId, attributes, variation, event) in
            Amplitude.instance().logEvent("[Optimizely] \(experiment.key) - \(variation.key)")
        }
        
        notificationCenter.addTrackNotificationListener { (eventKey, userId, attributes, eventTags, event) in
            Amplitude.instance().logEvent("[Optimizely] " + eventKey)
        }

        return notificationCenter
        
        #endif
    }
    
    func setRootViewController(optimizelyManager: OPTManager?, bucketedVariation:String?) {
        DispatchQueue.main.async {
            var storyboard : UIStoryboard
            
            #if os(tvOS)
            storyboard = UIStoryboard(name: "tvOSMain", bundle: nil)
            #elseif os(iOS)
            storyboard = UIStoryboard(name: "iOSMain", bundle: nil)
            #endif
            
            var rootViewController = storyboard.instantiateViewController(withIdentifier: "FailureViewController")
            
            if let optimizelyManager = optimizelyManager,
                let variationKey = bucketedVariation,
                let variationViewController = storyboard.instantiateViewController(withIdentifier: "VariationViewController") as? VariationViewController
            {
                variationViewController.eventKey = self.eventKey
                variationViewController.optimizelyManager = optimizelyManager
                variationViewController.userId = self.userId
                variationViewController.variationKey = variationKey
                
                rootViewController = variationViewController
            }
            
            self.window?.rootViewController = rootViewController
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        NotificationCenter.default.post(name: NSNotification.Name("OPTLYbackgroundFetchDone"), object: nil)
        completionHandler(.newData)
    }
}

