//
// Copyright 2019, 2021, Optimizely, Inc. and contributors
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


// session returns a download task that noop for resume.
// crafts a httpurlresponse with 304
// and returns that.
// the response also includes the url for the data download.
// the cdn url is used to get the datafile if the datafile is not in cache
class MockUrlSession: URLSession {
    var failureCode: Int
    var passError: Bool
    var localResponseData: String?
    var settingsMap: [String: (Int, Bool)]?
    
    class MockDownloadTask: URLSessionDownloadTask {
        var task: () -> Void
        
        init(_ task: @escaping () -> Void) {
            self.task = task
        }
        
        override func resume() {
            task()
        }
    }

    init(failureCode: Int = 0, withError: Bool = false, localResponseData: String? = nil) {
        self.failureCode = failureCode
        self.passError = withError
        self.localResponseData = localResponseData
    }
   
    init(settingsMap: [String: (Int, Bool)]) {
        self.failureCode = 0
        self.passError = false
        self.settingsMap = settingsMap
    }
    
    override func downloadTask(with request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        var headers = [String: String]()
        let sdkKey = request.url!.path.split(separator: "/").last!.replacingOccurrences(of: ".json", with: "")

        if let settings = settingsMap?[sdkKey] {
            (failureCode, passError) = settings
        }

        if localResponseData == nil {
            let datafile = MockDatafileHandler.getDatafile(sdkKey: sdkKey)
            let lastModifiedResponse = MockDatafileHandler.getLastModified(sdkKey: sdkKey)

            localResponseData = datafile
            headers["Last-Modified"] = lastModifiedResponse
        }
        
        // this filename should be different from sdkKey (to avoid conflict with datafile cache)
        let fileName = "\(sdkKey)-for-response"
        let downloadCacheUrl = OTUtils.saveAFile(name: fileName, data: localResponseData!.data(using: .utf8)!)
        
        return MockDownloadTask() {
            let statusCode = self.failureCode != 0 ? self.failureCode : (request.getLastModified() != nil ? 304 : 200)

            if (self.passError) {
                let error = OptimizelyError.datafileDownloadFailed("failure")
                completionHandler(downloadCacheUrl, nil, error)
            } else {
                let response = HTTPURLResponse(url: request.url!,
                                               statusCode: statusCode,
                                               httpVersion: nil,
                                               headerFields: headers)
                completionHandler(downloadCacheUrl, response, nil)
            }
        }
        
    }
}
