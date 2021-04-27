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
    var statusCode: Int = 0
    var passError: Bool = false
    var localResponseData: String?
    var settingsMap: [String: (Int, Bool)]?

    init(statusCode: Int = 0, passError: Bool = false, localResponseData: String? = nil) {
        self.statusCode = statusCode
        self.passError = passError
        self.localResponseData = localResponseData
    }
    
    init(settingsMap: [String: (Int, Bool)]) {
        self.settingsMap = settingsMap
    }
    
    public required init() {}
    
    override func getSession(resourceTimeoutInterval: Double?) -> URLSession {
        if let settingsMap = settingsMap {
            return MockUrlSession(settingsMap: settingsMap)
        } else {
            return MockUrlSession(failureCode: statusCode, withError: passError, localResponseData: localResponseData)
        }
    }
    
    // MARK: - helpers
    
    static func getDatafile(sdkKey: String) -> String {
        return "datafile-for-\(sdkKey)"
    }
    
    static func getLastModified(sdkKey: String) -> String {
        return "date-for-\(sdkKey)"
    }
    
}
