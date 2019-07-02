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

public struct OptimizelyClientConfig {
    
    /// Default logger level (.error, .warning, .info, .debug)
    public var defaultLogLevel: OptimizelyLogLevel = .info
    
    /// Custom interval for periodic background datafile download (seconds)
    /// If set to 0, background polling is disabled
    public var periodicDownloadInterval: TimeInterval = 10*60
    /// Timeout for datafile download completion (seconds)
    /// If not set, `URLSessionConfiguration.timeoutIntervalForResource` default value is used (7 days)
    public var fetchDatafileResourceTimeout: TimeInterval?
    /// Timout for datafile request (seconds)
    /// If not set, `URLSessionConfiguration.timeoutIntervalForRequest` default value is used (60 secs)
    public var fetchDatafileRequestTimeout: TimeInterval?
    /// This is for debugging purposes when you don't want to download the datafile.
    /// In practice, you should allow the background thread to update the cache copy
    public var doFetchDatafileBackground: Bool = false

    /// URL endpoint for event dispatch
    /// If not overriden, all events are sent to the default optimizely server url (https://logx.optimizely.com/v1/events).
    public var customEventEndPoint: String?
    /// Custom Interval for periodic dispatch of batched events (seconds)
    /// If set to 0, events are dispatched immediately (no batching)
    public var eventBatchInterval: TimeInterval = 1*60
    /// Maximum number of events to be batched into a single batch event
    public var eventBatchSize: Int = 10
    /// Maximum number of events that can be queued
    /// If overflowed, the oldest events are discarded
    public var eventQueueMaxSize: Int = 30000
    
    /// Enable certficate pinning for extra security
    public var optInForCertficatePinning: Bool = false
    
    public init() {}
    
}
