//
/****************************************************************************
* Copyright 2019, Optimizely, Inc. and contributors                        *
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
    

import Foundation


// session returns a download task that noop for resume.
// crafts a httpurlresponse with 304
// and returns that.
// the response also includes the url for the data download.
// the cdn url is used to get the datafile if the datafile is not in cache
class MockUrlSession : URLSession {
    var downloadCacheUrl:URL?
    let failureCode:Int
    let passError:Bool
    class MockDownloadTask : URLSessionDownloadTask {
        
        var task:()->Void
        
        init(_ task:@escaping ()->Void) {
            self.task = task
        }
        
        override func resume() {
            task()
        }
    }

    init (failureCode:Int, withError:Bool) {
        self.failureCode = failureCode
        self.passError = withError
    }
    
    convenience override init() {
        self.init(failureCode:0, withError:false)
    }
    
    override func downloadTask(with request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        
        return MockDownloadTask() {
            let statusCode = self.failureCode != 0 ? self.failureCode : (request.getLastModified() != nil ? 304 : 200)

            if (self.passError) {
                let error = OptimizelyError.datafileDownloadFailed("failure")
                completionHandler(self.downloadCacheUrl, nil, error )
            }
            else {
                let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)
                
                completionHandler(self.downloadCacheUrl, response, nil )
            }
        }
        
    }
}
