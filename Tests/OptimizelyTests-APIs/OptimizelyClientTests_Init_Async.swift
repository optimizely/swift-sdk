/****************************************************************************
* Copyright 2020, Optimizely, Inc. and contributors                        *
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
    

import XCTest

class OptimizelyClientTests_Init_Async: XCTestCase {

    // MARK: - Constants

    static let JSONfilename = "api_datafile"
    let kRevision = "241"
    let kExperimentKey = "exp_with_audience"
    
    let kVariationKey = "a"
    let kVariationOtherKey = "b"
    
    let kFeatureKey = "feature_1"
    let kFeatureOtherKey = "feature_2"
    
    let kVariableKeyString = "s_foo"
    let kVariableKeyInt = "i_42"
    let kVariableKeyDouble = "d_4_2"
    let kVariableKeyBool = "b_true"
    
    let kVariableValueString = "foo"
    let kVariableValueInt = 42
    let kVariableValueDouble = 4.2
    let kVariableValueBool = true
    
    let kEventKey = "event1"
    
    let kUserId = "11111"
    let kSDKKey = "anyKey"
    
    static let JSONfilenameUpdated = "feature_variables"
    let kRevisionUpdated = "34"

    override func setUp() {
    }
    
    func testInitAsync() {
        let testSdkKey = OTUtils.randomSdkKey  // unique but consistent with registry + start
        
        let handler = FakeDatafileHandler(mode: .successWithData)
        HandlerRegistryService.shared.registerBinding(binder: Binder(service: OPTDatafileHandler.self).sdkKey(key: testSdkKey).using(instance: handler).to(factory: FakeDatafileHandler.init).reInitializeStrategy(strategy: .reUse).singetlon())
        
        let optimizely = OptimizelyClient(sdkKey: testSdkKey)

        let exp = expectation(description: "x")
        optimizely.start { result in
            let variationKey: String = try! optimizely.activate(experimentKey: self.kExperimentKey, userId: self.kUserId)
            XCTAssert(variationKey == self.kVariationKey)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 10)
    }
    
    func testInitAsync_fetchError() {
        let testSdkKey = OTUtils.randomSdkKey  // unique but consistent with registry + start
        
        let handler = FakeDatafileHandler(mode: .failure)
        HandlerRegistryService.shared.registerBinding(binder: Binder(service: OPTDatafileHandler.self).sdkKey(key: testSdkKey).using(instance: handler).to(factory: FakeDatafileHandler.init).reInitializeStrategy(strategy: .reUse).singetlon())
        
        let optimizely = OptimizelyClient(sdkKey: testSdkKey)

        let exp = expectation(description: "x")
        optimizely.start { result in
            if case .failure = result {
                XCTAssert(true)
            } else {
                XCTAssert(false)
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 10)
    }
    
    func testInitAsync_fetchNil_whenCacheLoadFailed() {
        let testSdkKey = OTUtils.randomSdkKey  // unique but consistent with registry + start
        
        let handler = FakeDatafileHandler(mode: .failedToLoadFromCache)
        HandlerRegistryService.shared.registerBinding(binder: Binder(service: OPTDatafileHandler.self).sdkKey(key: testSdkKey).using(instance: handler).to(factory: FakeDatafileHandler.init).reInitializeStrategy(strategy: .reUse).singetlon())
        
        let optimizely = OptimizelyClient(sdkKey: testSdkKey)

        let exp = expectation(description: "x")
        optimizely.start { result in
            if case .failure = result {
                XCTAssert(true)
            } else {
                XCTAssert(false)
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 10)
    }

    func testInitAsync_enablePeriodicPolling() {
        let testSdkKey = OTUtils.randomSdkKey  // unique but consistent with registry + start
        
        let handler = FakeDatafileHandler(mode: .successWithData)
        HandlerRegistryService.shared.registerBinding(binder: Binder(service: OPTDatafileHandler.self).sdkKey(key: testSdkKey).using(instance: handler).to(factory: FakeDatafileHandler.init).reInitializeStrategy(strategy: .reUse).singetlon())
        
        let optimizely = OptimizelyClient(sdkKey: testSdkKey,
                                          periodicDownloadInterval: 1)
        
        let exp = expectation(description: "x")

        let notifId = optimizely.notificationCenter!.addDatafileChangeNotificationListener { _ in
            let optConfig = try! optimizely.getOptimizelyConfig()
            XCTAssertEqual(optConfig.revision, self.kRevisionUpdated)
            exp.fulfill()
        }

        optimizely.start { result in
            let optConfig = try! optimizely.getOptimizelyConfig()
            XCTAssertEqual(optConfig.revision, self.kRevision)
        }
        
        wait(for: [exp], timeout: 10)
        
        // disconnect the listener so exp not fulfilled redundantly
        optimizely.notificationCenter!.removeNotificationListener(notificationId: notifId!)
    }
}

extension OptimizelyClientTests_Init_Async {
    
    enum DataFileResponse {
        case successWithData
        case failedToLoadFromCache
        case failure
    }
    
    class FakeDatafileHandler: DefaultDatafileHandler {
        var mode: DataFileResponse
        var fileFlag: Bool = true
                
        init(mode: DataFileResponse) {
            self.mode = mode
        }
        
        required init() {
            fatalError("init() has not been implemented")
        }
        
        override func downloadDatafile(sdkKey: String,
                                       returnCacheIfNoChange: Bool,
                                       resourceTimeoutInterval: Double?,
                                       completionHandler: @escaping DatafileDownloadCompletionHandler) {
            
            switch mode {
            case .successWithData:
                let filename = fileFlag ? OptimizelyClientTests_Init_Async.JSONfilename : OptimizelyClientTests_Init_Async.JSONfilenameUpdated
                fileFlag.toggle()
                
                let data = OTUtils.loadJSONDatafile(filename)
                completionHandler(.success(data))
            case .failedToLoadFromCache:
                completionHandler(.success(nil))
            case .failure:
                completionHandler(.failure(.dataFileInvalid))
            }
        }
    }
}
