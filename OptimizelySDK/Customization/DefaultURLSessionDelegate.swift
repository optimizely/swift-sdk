
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

// delegate used for URLSessions, methods called during sendEvent
open class DefaultURLSessionDelegate: NSObject, URLSessionDelegate, URLSessionDataDelegate {
    
    var event: EventForDispatch
    var completionHandler: DispatchCompletionHandler
    
    public init(_ event: EventForDispatch, _ completionHandler: @escaping DispatchCompletionHandler) {
        self.event = event
        self.completionHandler = completionHandler
    }
    
    // URLSessionDelegate Methods //
    
    // performDefaultHandling so didCompleteWithError is called later
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
    }
    
    // not called
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    }
    
    // not called
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
    }
    
    
    // URLSessionDataDelegate Methods //
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            completionHandler(.failure(.eventDispatchFailed(error.localizedDescription)))
        } else {
            completionHandler(.success(event.body))
        }
    }
}
