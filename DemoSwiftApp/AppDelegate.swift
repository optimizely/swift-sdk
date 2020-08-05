/****************************************************************************
* Copyright 2019-2020, Optimizely, Inc. and contributors                   *
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
import BackgroundTasks
import Optimizely

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let logLevel = OptimizelyLogLevel.debug

    let sdkKey = "FCnSegiEkRry9rhVMroit4"
    let datafileName = "demoTestDatafile"
    let experimentKey = "background_experiment"
    let eventKey = "sample_conversion"

    let userId = String(Int.random(in: 0..<100000))
    let attributes: [String: Any?] = ["browser_type": "safari", "bool_attr": false]

    var window: UIWindow?
    var optimizely: OptimizelyClient!
    var storyboard: UIStoryboard {
        #if os(iOS)
        return UIStoryboard(name: "iOSMain", bundle: nil)
        #else
        return UIStoryboard(name: "tvOSMain", bundle: nil)
        #endif
    }
    
    let fetchTaskId = "com.optimizely.bgfetch"

    func applicationDidFinishLaunching(_ application: UIApplication) {
        
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: fetchTaskId, using: nil) { task in
                self.handleBackgroundDatafileFetchTask(task: task as! BGAppRefreshTask)
            }
        }

        // initialize SDK in one of these two ways:
        // (1) asynchronous SDK initialization (RECOMMENDED)
        //     - fetch a JSON datafile from the server
        //     - network delay, but the local configuration is in sync with the server experiment settings
        // (2) synchronous SDK initialization
        //     - initialize immediately with the given JSON datafile or its cached copy
        //     - no network delay, but the local copy is not guaranteed to be in sync with the server experiment settings
        
        initializeOptimizelySDKWithCustomization()
    }

    // MARK: - Initialization Examples

    func initializeOptimizelySDKAsynchronous() {
        optimizely = OptimizelyClient(sdkKey: sdkKey, defaultLogLevel: logLevel)

        addNotificationListeners()

        optimizely.start { result in
            switch result {
            case .failure(let error):
                print("Optimizely SDK initiliazation failed: \(error)")
            case .success:
                print("Optimizely SDK initialized successfully!")
            }

            self.startWithRootViewController()
        }
    }

    func initializeOptimizelySDKSynchronous() {
        guard let localDatafilePath = Bundle.main.path(forResource: datafileName, ofType: "json") else {
            fatalError("Local datafile cannot be found")
        }

        optimizely = OptimizelyClient(sdkKey: sdkKey, defaultLogLevel: logLevel)
        
        addNotificationListeners()

        do {
            let datafileJSON = try String(contentsOfFile: localDatafilePath, encoding: .utf8)
            try optimizely.start(datafile: datafileJSON)
            
            print("Optimizely SDK initialized successfully!")
        } catch {
            print("Optimizely SDK initiliazation failed: \(error)")
        }

        startWithRootViewController()
    }

    func initializeOptimizelySDKWithCustomization() {
        // customization example (optional)

        // You can enable background datafile polling by setting periodicDownloadInterval (polling is disabled by default)
        // 60 sec interval may be too frequent. This is for demo purpose. (You can set this to nil to use the recommended value of 600 secs).
        let downloadIntervalInSecs: Int? = 60

        // You can turn off event batching with 0 timerInterval (this means that events are sent out immediately to the server instead of saving in the local queue for batching)
        let eventDispatcher = DefaultEventDispatcher(timerInterval: 0)

        // customize logger
        let customLogger = CustomLogger()
        
        optimizely = OptimizelyClient(sdkKey: sdkKey,
                                       logger: customLogger,
                                       eventDispatcher: eventDispatcher,
                                       periodicDownloadInterval: downloadIntervalInSecs,
                                       defaultLogLevel: logLevel)
    
        addNotificationListeners()
        
        // initialize SDK
        optimizely!.start { result in
            switch result {
            case .failure(let error):
                print("Optimizely SDK initiliazation failed: \(error)")
            case .success:
                print("Optimizely SDK initialized successfully!")
            }
            self.startWithRootViewController()
            
            // For sample codes for APIs, see "Samples/SamplesForAPI.swift"
            //SamplesForAPI.checkOptimizelyConfig(optimizely: self.optimizely)
        }
    }
    
    func addNotificationListeners() {
        // notification listeners
        let notificationCenter = optimizely.notificationCenter!
            
        _ = notificationCenter.addDecisionNotificationListener(decisionListener: { (type, userId, attributes, decisionInfo) in
            print("Received decision notification: \(type) \(userId) \(String(describing: attributes)) \(decisionInfo)")
        })
        
        _ = notificationCenter.addTrackNotificationListener(trackListener: { (eventKey, userId, attributes, eventTags, event) in
            print("Received track notification: \(eventKey) \(userId) \(String(describing: attributes)) \(String(describing: eventTags)) \(event)")
        })

        _ = notificationCenter.addDatafileChangeNotificationListener(datafileListener: { (_) in
            DispatchQueue.main.async {
                #if os(iOS)
                if let controller = self.window?.rootViewController {
                    let alert = UIAlertController(title: "Datafile Changed", message: nil, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default))
                    controller.present(alert, animated: true)
                }
                #else
                print("Datafile changed")
                #endif

                if let controller = self.window?.rootViewController as? VariationViewController {
                    //controller.showCoupon = toggle == FeatureFlagToggle.on ? true : false;
                    controller.showCoupon = self.optimizely.isFeatureEnabled(featureKey: "show_coupon",
                                                                             userId: self.userId)
                }
            }
            
            if let optConfig = try? self.optimizely.getOptimizelyConfig() {
                print("[OptimizelyConfig] revision = \(optConfig.revision)")
            }
        })
        
        _ = notificationCenter.addLogEventNotificationListener(logEventListener: { (url, event) in
            print("Received logEvent notification: \(url) \(event)")
        })
    }

    // MARK: - ViewControl

    func startWithRootViewController() {
        DispatchQueue.main.async {
            do {
                let variationKey = try self.optimizely.activate(experimentKey: self.experimentKey,
                                                           userId: self.userId,
                                                           attributes: self.attributes)
                self.openVariationView(variationKey: variationKey)
            } catch OptimizelyError.variationUnknown(self.userId, self.experimentKey) {
                print("Optimizely SDK activation cannot map this user to experiemnt")
                self.openVariationView(variationKey: nil)
            } catch {
                print("Optimizely SDK activation failed: \(error)")
                self.openFailureView()
            }
        }
    }

    func openVariationView(variationKey: String?) {
        if let variationViewController = storyboard.instantiateViewController(withIdentifier: "VariationViewController")
            as? VariationViewController {

            variationViewController.showCoupon = optimizely.isFeatureEnabled(featureKey: "show_coupon",
                                                                         userId: userId)
            variationViewController.optimizely = optimizely
            variationViewController.userId = userId
            variationViewController.variationKey = variationKey
            variationViewController.eventKey = eventKey

            window?.rootViewController = variationViewController
        }
    }

    func openFailureView() {
        window?.rootViewController = storyboard.instantiateViewController(withIdentifier: "FailureViewController")
    }

    // MARK: - AppDelegate

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        if #available(iOS 13.0, *) {
            scheduleBackgroundDatafileFetch()
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }

    func application(_ application: UIApplication,
                     performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {

        // add background fetch task here

        completionHandler(.newData)
    }
}

// MARK: - background-mode fetch

@available(iOS 13.0, *)
extension AppDelegate {
    
    func handleBackgroundDatafileFetchTask(task: BGAppRefreshTask) {
        scheduleBackgroundDatafileFetch()

        // fetch datafile
        NSLog("[BGPoll] fetching datafile")

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
            //PokeManager.urlSession.invalidateAndCancel()
        }
        
        
        //task.setTaskCompleted(success: true)
    }
    
    func scheduleBackgroundDatafileFetch() {
        let fetchTask = BGAppRefreshTaskRequest(identifier: fetchTaskId)
        fetchTask.earliestBeginDate = Date(timeIntervalSinceNow: 5)

        do {
            try BGTaskScheduler.shared.submit(fetchTask)
            NSLog("[BGPoll] scheduling background task: \(fetchTaskId)")
        } catch {
            NSLog("[BGPoll] Unable to submit task: \(error.localizedDescription)")
        }
    }
    
    func downloadDatafileSilent(sdkKey: String,
                                       resourceTimeoutInterval: Double?,
                                       completionHandler: @escaping (Bool) -> Void) {
                
        //        downloadQueue.async {
        //            let session = self.getSession(resourceTimeoutInterval: resourceTimeoutInterval)
        //
        //            guard let request = self.getRequest(sdkKey: sdkKey) else {
        //                self.logger.e("[PushExp] OptimizelyMessage update is failed with getRequest error")
        //                completionHandler(false)
        //                return
        //            }
        //
        //            let task = session.downloadTask(with: request) { (url, response, error) in
        //                var result = false
        //
        //                if error != nil {
        //                    self.logger.e(error.debugDescription)
        //                } else if let response = response as? HTTPURLResponse {
        //                    switch response.statusCode {
        //                    case 200:
        //                        if let data = self.getResponseData(sdkKey: sdkKey, response: response, url: url) {
        //                            result = true
        //                            let datafile = String(bytes: data, encoding: .utf8)
        //                            self.logger.d("[PushExp] datafile revision downloaded silently for sdkKey: \(sdkKey): [\(datafile)]")
        //                        }
        //                    case 304:
        //                        self.logger.d("[PushExp] The datafile was not modified and won't be downloaded again")
        //                        result = true
        //                    default:
        //                        self.logger.i("[PushExp] got response code \(response.statusCode)")
        //                    }
        //                }
        //
        //                completionHandler(result)
        //            }
        //
        //            task.resume()
        //        }
    }


}
