//
// Copyright 2023, Optimizely, Inc. and contributors 
// 
// Licensed under the Apache License, Version 2.0 (the "License");  
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at   
// 
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import XCTest
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
final class OptimizelyClientTests_Init_Async_Await: XCTestCase {
    let kUserId = "11111"
    let kExperimentKey = "exp_with_audience"
    let kFlagKey = "feature_1"
    let kVariationKey = "a"
    let kRevisionUpdated = "34"
    let kRevision = "241"
    
    func testInitAsyncAwait() async throws {
        let testSdkKey = OTUtils.randomSdkKey  // unique but consistent with registry + start
        
        let handler = FakeDatafileHandler(mode: .successWithData)
        let optimizely = OptimizelyClient(sdkKey: testSdkKey,
                                          datafileHandler: handler)
        
        try await optimizely.start()
        let user = OptimizelyUserContext(optimizely: optimizely, userId: self.kUserId)
        let decision = user.decide(key: self.kFlagKey)
        
        XCTAssert(decision.variationKey == self.kVariationKey)
    }
    
    func testInitAsyncAwait_fetchError() async throws {
        let testSdkKey = OTUtils.randomSdkKey  // unique but consistent with registry + start

        let handler = FakeDatafileHandler(mode: .failure)
        let optimizely = OptimizelyClient(sdkKey: testSdkKey,
                                          datafileHandler: handler)
        var _error: Error?
        do {
            try await optimizely.start()
        } catch {
            _error = error
        }

       XCTAssertNotNil(_error)
    }
    
    func testInitAsync_fetchNil_whenCacheLoadFailed() async {
        let testSdkKey = OTUtils.randomSdkKey  // unique but consistent with registry + start
        
        let handler = FakeDatafileHandler(mode: .failedToLoadFromCache)
        let optimizely = OptimizelyClient(sdkKey: testSdkKey,
                                          datafileHandler: handler)

        var _error: Error?
        do {
            try await optimizely.start()
        } catch {
            _error = error
        }

       XCTAssertNotNil(_error)
    }
    
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension OptimizelyClientTests_Init_Async_Await {
    
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
