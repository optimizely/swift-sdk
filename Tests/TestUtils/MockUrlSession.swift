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
    static var validSessions = 0
    var statusCode: Int
    var withError: Bool
    var localResponseData: String?
    var settingsMap: [String: (Int, Bool)]?
    var handler: MockDatafileHandler?
    
    class MockDownloadTask: URLSessionDownloadTask {
        var task: () -> Void
        
        init(_ task: @escaping () -> Void) {
            self.task = task
        }
        
        override func resume() {
            task()
        }
    }
    
    class MockUploadTask: URLSessionUploadTask {
        var task: () -> Void
        
        init(_ task: @escaping () -> Void) {
            self.task = task
        }
        
        override func resume() {
            task()
        }
    }

    init(handler: MockDatafileHandler? = nil, statusCode: Int = 0, withError: Bool = false, localResponseData: String? = nil) {
        Self.validSessions += 1
        self.handler = handler
        self.statusCode = statusCode
        self.withError = withError
        self.localResponseData = localResponseData
    }
   
    init(handler: MockDatafileHandler? = nil, settingsMap: [String: (Int, Bool)]) {
        Self.validSessions += 1
        self.handler = handler
        self.statusCode = 0
        self.withError = false
        self.settingsMap = settingsMap
    }
    
    override func downloadTask(with request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        var headers = [String: String]()
        let sdkKey = request.url!.path.split(separator: "/").last!.replacingOccurrences(of: ".json", with: "")

        if let settings = settingsMap?[sdkKey] {
            (statusCode, withError) = settings
        }

        let datafile = handler?.getDatafile(sdkKey: sdkKey) ?? "invalid-mock-handler"
        let lastModifiedResponse = handler?.getLastModified(sdkKey: sdkKey) ?? "invalid-mock-handler"

        headers["Last-Modified"] = lastModifiedResponse
        
        // this filename should be different from sdkKey (to avoid conflict with datafile cache)
        let fileName = "\(sdkKey)-for-response"
        let downloadCacheUrl = OTUtils.saveAFile(name: fileName, data: datafile.data(using: .utf8)!)
        
        return MockDownloadTask() {
            let statusCode = self.statusCode != 0 ? self.statusCode : 200

            if (self.withError) {
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
    
    override func uploadTask(with request: URLRequest, from bodyData: Data?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask {
        return MockUploadTask() {
            if (self.withError) {
                completionHandler(nil, nil, OptimizelyError.eventDispatchFailed("mock error"))
            } else {
                completionHandler(nil, nil, nil)
            }
        }
    }

    override func finishTasksAndInvalidate() {
        Self.validSessions -= 1
    }
}
