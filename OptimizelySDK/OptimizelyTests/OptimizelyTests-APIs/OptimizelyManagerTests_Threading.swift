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
}
