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

public typealias ProcessCompletionHandler = (OptimizelyResult<Data>) -> Void

/// The OPTEventProcessor processes events to be dispatched to the Optimizely backend.
public protocol OPTEventsProcessor {
    
    /// Process events to be dispatched to the Optimizely backend
    ///
    /// - Parameters:
    ///   - event: UserEvent object which contains event contents to send.
    ///   - completionHandler: Called when the event has been processed.
    func process(event: UserEvent, completionHandler: ProcessCompletionHandler?)
    
    /// Attempts to flush the event queue if there are any events to process.
    func flush()

    /// flush events in queue synchrnonous (optional for testing support)
    func clear()
}

public extension OPTEventsProcessor {
    // override this for testing support only
    func clear() {}
}
