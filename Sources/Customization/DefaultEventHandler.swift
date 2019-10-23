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

open class DefaultEventHandler: OPTEventHandler {

    lazy var logger = OPTLoggerFactory.getLogger()

    public init() {
    }
    
    open func dispatch(event: EventForDispatch, completionHandler: DispatchCompletionHandler? = nil) {
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)
        var request = URLRequest(url: event.url)
        request.httpMethod = "POST"
        request.httpBody = event.body
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = session.uploadTask(with: request, from: event.body) { (_, response, error) in
            self.logger.d(response.debugDescription)
            
            if let error = error {
                completionHandler?(.failure(.eventDispatchFailed(error.localizedDescription)))
            } else {
                self.logger.d("Event Sent")
                completionHandler?(.success(event.body))
            }
        }
        
        task.resume()
    }
    
}
