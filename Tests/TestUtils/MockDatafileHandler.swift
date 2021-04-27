//
// Copyright 2021, Optimizely, Inc. and contributors 
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

import Foundation

class MockDatafileHandler: DefaultDatafileHandler {
    let failureCode: Int
    let passError: Bool
    let sdkKey: String
    let localUrl: URL?
    let lastModified: String?

    init(failureCode: Int = 0, passError: Bool = false, sdkKey: String, strData: String = "{}", lastModified: String? = nil) {
        self.failureCode = failureCode
        self.passError = passError
        self.sdkKey = sdkKey
        self.localUrl = OTUtils.saveAFile(name: sdkKey, data: strData.data(using: .utf8)!)
        self.lastModified = lastModified
    }
    
    public required init() {
        fatalError("init() has not been implemented")
    }
    
    override func getSession(resourceTimeoutInterval: Double?) -> URLSession {
        return MockUrlSession(failureCode: failureCode, withError: passError, localUrl: localUrl, lastModified: lastModified)
    }
    
}
