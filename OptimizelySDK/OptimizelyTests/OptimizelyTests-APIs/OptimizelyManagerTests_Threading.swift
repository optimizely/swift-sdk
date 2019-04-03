//
//  OptimizelyManagerTests_Threading.swift
//  OptimizelyTests-APIs-iOS
//
//  Created by Thomas Zurkan on 3/22/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class OptimizelyManagerTests_Threading: XCTestCase {

    var datafileOn: Data!
    var datafileOff: Data!
    var optimizely: OptimizelyManager!
    let userId = "11111"
    let sdkKey = "12345"

    /// Setup a local datafile handler that uses a timer to constantly switch datafiles
    /// toggling feature flag on or off.
    override func setUp() {
        self.datafileOn = OTUtils.loadJSONDatafile("feature_rollout_toggle_on")
        
        self.datafileOff = OTUtils.loadJSONDatafile("feature_rollout_toggle_off")
        // datafile handler that uses two datafiles on/off
        let datafileHandler = makeDatafileHandler()
        // register our datafile handler for this sdk key
        HandlerRegistryService.shared.registerBinding(binder:Binder<OPTDatafileHandler>(service: OPTDatafileHandler.self).singetlon().reInitializeStrategy(strategy: .reUse).to(factory: type(of:datafileHandler).init).using(instance: datafileHandler).sdkKey(key: "12345"))
        
        self.optimizely = OptimizelyManager(sdkKey: "12345",
                                            userProfileService: OTUtils.createClearUserProfileService(),
                                            periodicDownloadInterval:1
        )
        do {
            try self.optimizely.initializeSDK(datafile: datafileOff)
        }
        catch {
            print(error)
            XCTAssert(false)
        }

    }

    override func tearDown() {
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        self.optimizely.datafileHandler.stopPeriodicUpdates()
        self.optimizely = nil
    }

    /// This test is testing the feature flag rollout toggle.  It uses a custom datafile handler
    /// that switches between datafiles with the same project and feature.  one has the feature flag
    /// toggled on, another has it toggled off.
    func testFeatureToggle() {
        let _ = self.optimizely.notificationCenter.addFeatureFlagRolloutChangeListener { (featureKey, toggle) in
            do {
                let value = try self.optimizely.isFeatureEnabled(featureKey: "show_coupon", userId: self.userId)
                XCTAssertNotNil(value)
            }
            catch {
                print(error)
                XCTAssert(false)
            }
        }
        let expectation = XCTestExpectation(description: "waiting for long test")
    
        for _ in 0...1000 {
            DispatchQueue.main.async {
                do {
                    let value = try self.optimizely.isFeatureEnabled(featureKey: "show_coupon", userId: self.userId)
                    XCTAssertNotNil(value)
                }
                catch {
                    print(error)
                    XCTAssert(false)
                }
            }
        }
        
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 100.0)
    }

    /// Here we are testing two instances, the default instance created in setup is getting updates at 1
    /// second intervals.  Our second is just calling features and is a different project.
    func testTwoInstances() {
        let datafile = OTUtils.loadJSONDatafile("typed_audience_datafile")
        
        let optimizely2 = OptimizelyManager(sdkKey: "123123",
                                            //userProfileService: OTUtils.createClearUserProfileService(),
                                            periodicDownloadInterval:0
        )
        try? optimizely2.initializeSDK(datafile: datafile!)
        
        let enabled = try? optimizely2.isFeatureEnabled(featureKey: "feat", userId: self.userId, attributes: ["house": "Gryffindor"])
        XCTAssertTrue(enabled!)
    }

    /// Here we are testing 3 instances and calling activate and isFeature enabled on those instances.
    func testThreeInstances() {
        class NoOpUserProfileService :OPTUserProfileService {
            required init() {
                
            }
            func lookup(userId: String) -> NoOpUserProfileService.UPProfile? {
                return nil
            }
            
            func save(userProfile: NoOpUserProfileService.UPProfile) {
            }
        }
        
        let datafile = OTUtils.loadJSONDatafile("typed_audience_datafile")
        
        let optimizely2 = OptimizelyManager(sdkKey: "123123",
                                            userProfileService: NoOpUserProfileService(),
            periodicDownloadInterval:0
        )
        let optimizely3 = OptimizelyManager(sdkKey: "999999",
                                            userProfileService: NoOpUserProfileService(),
            periodicDownloadInterval:0
        )
        try? optimizely2.initializeSDK(datafile: datafile!)
        try? optimizely3.initializeSDK(datafile: OTUtils.loadJSONDatafile("ab_experiments")!)
        
        let enabled = try? optimizely2.isFeatureEnabled(featureKey: "feat", userId: self.userId, attributes: ["house": "Gryffindor"])
        let variation = try? optimizely3.activate(experimentKey: "ab_running_exp_untargeted", userId: self.userId)
        XCTAssertTrue(enabled!)
        XCTAssertNotNil(variation)
    }

    /// Here we are creating 3 instances and calling activate/isFeatureEnabled 101 times on each using
    /// a dispatch queue for each.
    func testThreeInstancesThreads() {
        class NoOpUserProfileService :OPTUserProfileService {
            required init() {
                
            }
            func lookup(userId: String) -> NoOpUserProfileService.UPProfile? {
                return nil
            }
            
            func save(userProfile: NoOpUserProfileService.UPProfile) {
            }
        }

        let datafile = OTUtils.loadJSONDatafile("typed_audience_datafile")
        
        let optimizely2 = OptimizelyManager(sdkKey: "123123",
                                            userProfileService: NoOpUserProfileService(),
            periodicDownloadInterval:0
        )
        let optimizely3 = OptimizelyManager(sdkKey: "999999",
                                            userProfileService: NoOpUserProfileService(),
            periodicDownloadInterval:0
        )
        try? optimizely2.initializeSDK(datafile: datafile!)
        try? optimizely3.initializeSDK(datafile: OTUtils.loadJSONDatafile("ab_experiments")!)
        
        let expectation = XCTestExpectation(description: "waiting for main thread")
        let expectationBackground = XCTestExpectation(description: "waiting for background thread")
        let expectationMyQueue = XCTestExpectation(description: "waiting for my queue")
        let myQueue = DispatchQueue(label: "myQueue")
        let backgroundQueue = DispatchQueue(label: "mybackground", qos: DispatchQoS.default, attributes: DispatchQueue.Attributes(), autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, target: nil)
        var mainResponse = [(enabled:Bool, variation:String)]()
        var backgroundResponse = [(enabled:Bool, variation:String)]()
        var myResponse = [(enabled:Bool, variation:String)]()
        for _ in 0...100 {
            backgroundQueue.async  {
                let enabled = try? optimizely2.isFeatureEnabled(featureKey: "feat", userId: self.userId, attributes: ["house": "Gryffindor"])
                let variation = try? optimizely3.activate(experimentKey: "ab_running_exp_untargeted", userId: self.userId)
                
                backgroundResponse.append((enabled: enabled!, variation: variation!))
                XCTAssertTrue(enabled!)
                XCTAssertNotNil(variation)
            }
            
            DispatchQueue.main.async {
                let enabled = try? optimizely2.isFeatureEnabled(featureKey: "feat", userId: self.userId, attributes: ["house": "Gryffindor"])
                let variation = try? optimizely3.activate(experimentKey: "ab_running_exp_untargeted", userId: self.userId)
                mainResponse.append((enabled: enabled!, variation: variation!))
                XCTAssertTrue(enabled!)
                XCTAssertNotNil(variation)
            }

            myQueue.async  {
                let enabled = try? optimizely2.isFeatureEnabled(featureKey: "feat", userId: self.userId, attributes: ["house": "Gryffindor"])
                let variation = try? optimizely3.activate(experimentKey: "ab_running_exp_untargeted", userId: self.userId)
                XCTAssertTrue(enabled!)
                XCTAssertNotNil(variation)
                myResponse.append((enabled: enabled!, variation: variation!))
            }
        }

        let enabled = try? optimizely2.isFeatureEnabled(featureKey: "feat", userId: self.userId, attributes: ["house": "Gryffindor"])
        let variation = try? optimizely3.activate(experimentKey: "ab_running_exp_untargeted", userId: self.userId)
        XCTAssertTrue(enabled!)
        XCTAssertNotNil(variation)
        
        DispatchQueue.main.async {
            expectation.fulfill()
        }

        myQueue.async {
            expectationMyQueue.fulfill()
        }
        
        backgroundQueue.async {
            expectationBackground.fulfill()
        }
        
        wait(for: [expectation, expectationBackground, expectationMyQueue], timeout: 220.0)

        XCTAssertTrue(myResponse.count == 101)
        XCTAssertTrue(backgroundResponse.count == 101)
        XCTAssertTrue(mainResponse.count == 101)
        
        for index in 0...100 {
            XCTAssertTrue(myResponse[index].enabled)
            XCTAssertNotNil(myResponse[index].variation)
            XCTAssertTrue(backgroundResponse[index].enabled)
            XCTAssertNotNil(backgroundResponse[index].variation)
            XCTAssertTrue(mainResponse[index].enabled)
            XCTAssertNotNil(mainResponse[index].variation)

        }
    }

    /// Concurrent testing.  We don't wrap all our entities so concurrent testing is not approved.  However, we should not crash.  We might want a concurrent option in which case we wrap every method with a lock
    func testConcurrentThreads() {
        class NoOpUserProfileService :OPTUserProfileService {
            required init() {
                
            }
            func lookup(userId: String) -> NoOpUserProfileService.UPProfile? {
                return nil
            }
            
            func save(userProfile: NoOpUserProfileService.UPProfile) {
            }
        }
        
        let datafile = OTUtils.loadJSONDatafile("typed_audience_datafile")
        
        let optimizely2 = OptimizelyManager(sdkKey: "concurrent1",
                                            eventDispatcher: makeEventHandler(),
                                            userProfileService: NoOpUserProfileService(),
            periodicDownloadInterval:0
        )
        let optimizely3 = OptimizelyManager(sdkKey: "concurrent2",
                                            eventDispatcher: makeEventHandler(),
                                            userProfileService: NoOpUserProfileService(),
            periodicDownloadInterval:0
        )
        try? optimizely2.initializeSDK(datafile: datafile!)
        try? optimizely3.initializeSDK(datafile: OTUtils.loadJSONDatafile("ab_experiments")!)
        
        //let expectationBackground = XCTestExpectation(description: "waiting for background thread")
        let backgroundQueue = DispatchQueue(label: "mybackground", qos: DispatchQoS.default, attributes: DispatchQueue.Attributes.concurrent)
        let atomicBackground = AtomicProperty<[(enabled:Bool?, variation:String?)]>(property: [(enabled:Bool?, variation:String?)]())
        let appendLock = DispatchQueue(label: "appendLock")
        
        let dispatchGroup = DispatchGroup()
        
        for _ in 0...100 {
            dispatchGroup.enter()
            backgroundQueue.async  {
                let enabled = try? optimizely2.isFeatureEnabled(featureKey: "feat", userId: self.userId, attributes: ["house": "Gryffindor"])
                let variation = try? optimizely3.activate(experimentKey: "ab_running_exp_untargeted", userId: self.userId)
                
                appendLock.async {
                    atomicBackground.property!.append((enabled: enabled!, variation: variation!))
                }
                
                defer {
                    dispatchGroup.leave()
                }
                //XCTAssertTrue(enabled!)
                //XCTAssertNotNil(variation)
            }
            
        }
        
        let enabled = try? optimizely2.isFeatureEnabled(featureKey: "feat", userId: self.userId, attributes: ["house": "Gryffindor"])
        let variation = try? optimizely3.activate(experimentKey: "ab_running_exp_untargeted", userId: self.userId)
        XCTAssertTrue(enabled!)
        XCTAssertNotNil(variation)

        dispatchGroup.wait()
        
        XCTAssertTrue(atomicBackground.property!.count == 101, "Count should be 101 but was \(atomicBackground.property!.count)")
        
        for index in 0...100 where index < atomicBackground.property!.count {
            XCTAssertTrue(atomicBackground.property![index].enabled!)
            XCTAssertNotNil(atomicBackground.property![index].variation)
        }
    }

    

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func makeDatafileHandler() -> OPTDatafileHandler {
        class DatafileHandler: DefaultDatafileHandler {
            var toggle = FeatureFlagToggle.off;
            let on:Data
            let off:Data
            init(on:Data, off:Data) {
                self.on = on
                self.off = off
            }
            
            required init() {
                fatalError("init() has not been implemented")
            }
            
            override func downloadDatafile(sdkKey: String, completionHandler: @escaping (Result<Data?, DatafileDownloadError>) -> Void) {
                switch toggle {
                case .on:
                    toggle = .off
                    completionHandler(Result.success(self.off))
                case .off:
                    toggle = .on
                    completionHandler(Result.success(self.on))
                }
            }
        }
        
        return DatafileHandler(on: self.datafileOn, off: self.datafileOff)
    }
    
    func makeEventHandler() -> OPTEventDispatcher {
        class NoOpEventHandler : OPTEventDispatcher {
            func dispatchEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
                
            }
            
            func flushEvents() {
                
            }
            
            
        }
        
        return NoOpEventHandler()
    }
}
