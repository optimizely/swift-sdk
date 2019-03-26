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
    var userId = "11111"

    override func setUp() {
        self.datafileOn = OTUtils.loadJSONDatafile("feature_rollout_toggle_on")
        
        self.datafileOff = OTUtils.loadJSONDatafile("feature_rollout_toggle_off")
        
        self.optimizely = OptimizelyManager(sdkKey: "12345",
                                            userProfileService: OTUtils.createClearUserProfileService(),
                                            datafileHandler:makeDatafileHandler(),
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

    func testTwoInstances() {
        let datafile = OTUtils.loadJSONDatafile("typed_audience_datafile")
        
        let optimizely2 = OptimizelyManager(sdkKey: "123123",
                                            //userProfileService: OTUtils.createClearUserProfileService(),
                                            //datafileHandler:makeDatafileHandler(),
                                            periodicDownloadInterval:0
        )
        try? optimizely2.initializeSDK(datafile: datafile!)
        
        let enabled = try? optimizely2.isFeatureEnabled(featureKey: "feat", userId: self.userId, attributes: ["house": "Gryffindor"])
        XCTAssertTrue(enabled!)
    }

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
            //datafileHandler:makeDatafileHandler(),
            periodicDownloadInterval:0
        )
        let optimizely3 = OptimizelyManager(sdkKey: "999999",
                                            userProfileService: NoOpUserProfileService(),
            //datafileHandler:makeDatafileHandler(),
            periodicDownloadInterval:0
        )
        try? optimizely2.initializeSDK(datafile: datafile!)
        try? optimizely3.initializeSDK(datafile: OTUtils.loadJSONDatafile("ab_experiments")!)
        
        let enabled = try? optimizely2.isFeatureEnabled(featureKey: "feat", userId: self.userId, attributes: ["house": "Gryffindor"])
        let variation = try? optimizely3.activate(experimentKey: "ab_running_exp_untargeted", userId: self.userId)
        XCTAssertTrue(enabled!)
        XCTAssertNotNil(variation)
    }

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
            //datafileHandler:makeDatafileHandler(),
            periodicDownloadInterval:0
        )
        let optimizely3 = OptimizelyManager(sdkKey: "999999",
                                            userProfileService: NoOpUserProfileService(),
            //datafileHandler:makeDatafileHandler(),
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
                                            datafileHandler:makeDatafileHandler(),
            periodicDownloadInterval:0
        )
        let optimizely3 = OptimizelyManager(sdkKey: "concurrent2",
                                            eventDispatcher: makeEventHandler(),
                                            userProfileService: NoOpUserProfileService(),
                                            datafileHandler:makeDatafileHandler(),
            periodicDownloadInterval:0
        )
        try? optimizely2.initializeSDK(datafile: datafile!)
        try? optimizely3.initializeSDK(datafile: OTUtils.loadJSONDatafile("ab_experiments")!)
        
        let expectationBackground = XCTestExpectation(description: "waiting for background thread")
        let backgroundQueue = DispatchQueue(label: "mybackground", qos: DispatchQoS.default, attributes: DispatchQueue.Attributes.concurrent)
        let atomicBackground = AtomicProperty<[(enabled:Bool?, variation:String?)]>(property: [(enabled:Bool?, variation:String?)]())
        
        for _ in 0...100 {
            backgroundQueue.async  {
                let enabled = try? optimizely2.isFeatureEnabled(featureKey: "feat", userId: self.userId, attributes: ["house": "Gryffindor"])
                let variation = try? optimizely3.activate(experimentKey: "ab_running_exp_untargeted", userId: self.userId)
                
                atomicBackground.property!.append((enabled: enabled!, variation: variation!))
                
                //XCTAssertTrue(enabled!)
                //XCTAssertNotNil(variation)
            }
            
        }
        
        let enabled = try? optimizely2.isFeatureEnabled(featureKey: "feat", userId: self.userId, attributes: ["house": "Gryffindor"])
        let variation = try? optimizely3.activate(experimentKey: "ab_running_exp_untargeted", userId: self.userId)
        XCTAssertTrue(enabled!)
        XCTAssertNotNil(variation)

        backgroundQueue.asyncAfter(deadline: .now() + 30.0) {
            expectationBackground.fulfill()
        }
        
        wait(for: [expectationBackground], timeout: 90.0)
        
        //XCTAssert(atomicBackground.property!.count == 101)
        
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
