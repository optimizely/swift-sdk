/****************************************************************************
* Copyright 2020-2021, Optimizely, Inc. and contributors                   *
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

class OptimizelyClientTests_Init_Sync: XCTestCase {

    // MARK: - Constants

    let kJSONfilename = "api_datafile"
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
    
    let kRevisionUpdated = "34"
    static let JSONfilenameUpdated = "feature_variables"

    // MARK: - Properties

    var datafile: Data!

    override func setUp() {
        self.datafile = OTUtils.loadJSONDatafile(kJSONfilename)
    }
    
    func testInitSync() {
        let optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)

        try! optimizely.start(datafile: datafile)
        
        let variationKey: String = try! optimizely.activate(experimentKey: kExperimentKey, userId: kUserId)
        XCTAssert(variationKey == kVariationKey)
    }
    
    func testInitSync_doBackgroundFetch_update() {
        let testSdkKey = OTUtils.randomSdkKey  // unique but consistent with registry + start
        
        let handler = FakeDatafileHandler(mode: .successWithData)
        let optimizely = OptimizelyClient(sdkKey: testSdkKey,
                                          datafileHandler: handler)

        try! optimizely.start(datafile: datafile,
                              doUpdateConfigOnNewDatafile: true)
        
        let optConfig = try! optimizely.getOptimizelyConfig()
        XCTAssertEqual(optConfig.revision, kRevisionUpdated)
    }
    
    func testInitSync_doBackgroundFetch_updateButNilReturned() {
        let testSdkKey = OTUtils.randomSdkKey  // unique but consistent with registry + start
        
        let handler = FakeDatafileHandler(mode: .successWithNil)
        let optimizely = OptimizelyClient(sdkKey: testSdkKey,
                                          datafileHandler: handler)

        try! optimizely.start(datafile: datafile,
                              doUpdateConfigOnNewDatafile: true)
        
        let optConfig = try! optimizely.getOptimizelyConfig()
        XCTAssertEqual(optConfig.revision, kRevision)
    }

    func testInitSync_doBackgroundFetch_updateButErrorReturned() {
        let testSdkKey = OTUtils.randomSdkKey  // unique but consistent with registry + start
        
        let handler = FakeDatafileHandler(mode: .failure)
        let optimizely = OptimizelyClient(sdkKey: testSdkKey,
                                          datafileHandler: handler)

        try! optimizely.start(datafile: datafile,
                              doUpdateConfigOnNewDatafile: true)
        
        let optConfig = try! optimizely.getOptimizelyConfig()
        XCTAssertEqual(optConfig.revision, kRevision)
    }
    
    func testInitSync_doBackgroundFetch_noUpdate() {
        let testSdkKey = OTUtils.randomSdkKey  // unique but consistent with registry + start
        
        let handler = FakeDatafileHandler(mode: .successWithData)
        let optimizely = OptimizelyClient(sdkKey: testSdkKey,
                                          datafileHandler: handler)

        try! optimizely.start(datafile: datafile,
                              doUpdateConfigOnNewDatafile: false)
        
        let optConfig = try! optimizely.getOptimizelyConfig()
        XCTAssertEqual(optConfig.revision, kRevision)
    }
    
    func testInitSync_doNotBackgroundFetch() {
        let testSdkKey = OTUtils.randomSdkKey  // unique but consistent with registry + start
        
        let handler = FakeDatafileHandler(mode: .successWithData)
        let optimizely = OptimizelyClient(sdkKey: testSdkKey,
                                          datafileHandler: handler)

        try! optimizely.start(datafile: datafile,
                              doUpdateConfigOnNewDatafile: true,
                              doFetchDatafileBackground: true)
        
        let optConfig = try! optimizely.getOptimizelyConfig()
        XCTAssertEqual(optConfig.revision, kRevisionUpdated)
    }

    
    func testInitSync_doBackgroundFetch_noUpdate_overridenByPolling() {
        let testSdkKey = OTUtils.randomSdkKey  // unique but consistent with registry + start
        
        let handler = FakeDatafileHandler(mode: .successWithData)
        let optimizely = OptimizelyClient(sdkKey: testSdkKey,
                                          datafileHandler: handler,
                                          periodicDownloadInterval: 10)

        try! optimizely.start(datafile: datafile,
                              doUpdateConfigOnNewDatafile: false)
        
        let optConfig = try! optimizely.getOptimizelyConfig()
        XCTAssertEqual(optConfig.revision, kRevisionUpdated)
    }

    func testInitSync_multi() {
        let testSdkKey = OTUtils.randomSdkKey  // unique but consistent with registry + start
        
        let handler = FakeDatafileHandler(mode: .successWithData)
        let optimizely = OptimizelyClient(sdkKey: testSdkKey,
                                          datafileHandler: handler,
                                          periodicDownloadInterval: 10)

        try! optimizely.start(datafile: datafile,
                              doUpdateConfigOnNewDatafile: false)

        try! optimizely.start(datafile: datafile,
                              doUpdateConfigOnNewDatafile: false)

        try! optimizely.start(datafile: datafile,
                              doUpdateConfigOnNewDatafile: false)

        let optConfig = try! optimizely.getOptimizelyConfig()
        XCTAssertEqual(optConfig.revision, kRevisionUpdated)
    }

    func testInitSync_asnync() {
        let testSdkKey = OTUtils.randomSdkKey  // unique but consistent with registry + start
        
        let handler = FakeDatafileHandler(mode: .successWithData)
        let optimizely = OptimizelyClient(sdkKey: testSdkKey,
                                          datafileHandler: handler,
                                          periodicDownloadInterval: 10)

        try! optimizely.start(datafile: datafile,
                              doUpdateConfigOnNewDatafile: false)

        let exp = expectation(description: "x")
        optimizely.start { result in
            if case .success = result {
                XCTAssert(true)
            } else {
                XCTAssert(false)
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 10)

        let enabled = optimizely.isFeatureEnabled(featureKey: "no_key", userId: "userId")
        
        XCTAssertEqual(enabled, false)
        
        let optConfig = try! optimizely.getOptimizelyConfig()
        XCTAssertEqual(optConfig.revision, kRevisionUpdated)
    }

}

extension OptimizelyClientTests_Init_Sync {
    
    enum DataFileResponse {
        case successWithData
        case successWithNil
        case failure
    }
    
    class FakeDatafileHandler: DefaultDatafileHandler {
        var mode: DataFileResponse
                
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
                let data = OTUtils.loadJSONDatafile(OptimizelyClientTests_Init_Sync.JSONfilenameUpdated)
                completionHandler(.success(data))
            case .successWithNil:
                completionHandler(.success(nil))
            case .failure:
                completionHandler(.failure(.dataFileInvalid))
            }
        }
    }
}

