
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

open class DefaultURLSessionDelegate: NSObject, URLSessionDelegate, URLSessionDataDelegate {
    
    let logger = OPTLoggerFactory.getLogger()
    
    // delegate methods
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        <#code#>
    }
    
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        <#code#>
    }
    
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        guard let error = error else {
            logger.d("Explicit invalidation.")
            return
        }
        logger.d(OptimizelyError.eventDispatchFailed(error.localizedDescription))
    }
    
    // data delegate methods
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            logger.d(OptimizelyError.eventDispatchFailed(error.localizedDescription))
            // Should we continue/return/exit after error?
        }
        guard task.state == URLSessionTask.State.completed else {
            task.resume()
        }
        
        
    }
    
    
}
