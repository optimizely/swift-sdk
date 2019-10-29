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

extension Array where Element == EventForDispatch {
    
    // returns:
    
    /// Batch multiple events into a single big event
    ///
    /// - Returns:
    ///     (numEvents, eventForDispatch)
    ///
    ///      numEvents: number of events batched (so, should be removed after sent)
    ///
    ///      eventForDispatch: a batched event (can be invalid with nil url)
    ///
    ///      returns nil when no event to merge
    func batch() -> (numEvents: Int, eventForDispatch: EventForDispatch?) {
        if count == 0 {
            return (0, nil)
        }
        
        // do not validate a single event (common path so it'll impact performance. Server will check sanity anyway)
        if count == 1 {
            return (1, first)
        }
        
        var eventsBatched = [BatchEvent]()
        var visitors = [Visitor]()
        var url: URL?
        var sdkKey: String?
        var projectId: String?
        var revision: String?
        
        let checkUrl = { (event: EventForDispatch) -> Bool in
            if url == nil {
                url = event.url
                return url != nil
            }
            return url == event.url
        }
        
        let checkSdkKey = { (event: EventForDispatch) -> Bool in
            if sdkKey == nil {
                sdkKey = event.sdkKey
                return sdkKey != nil
            }
            return sdkKey == event.sdkKey
        }

        let checkProjectId = { (batchEvent: BatchEvent) -> Bool in
            if projectId == nil {
                projectId = batchEvent.projectID
                return projectId != nil
            }
            return projectId == batchEvent.projectID
        }
        
        let checkRevision = { (batchEvent: BatchEvent) -> Bool in
            if revision == nil {
                revision = batchEvent.revision
                return revision != nil
            }
            return revision == batchEvent.revision
        }

        for event in self {
            if let batchEvent = try? JSONDecoder().decode(BatchEvent.self, from: event.body) {
                if !checkUrl(event) ||
                    !checkSdkKey(event) ||
                    !checkProjectId(batchEvent) ||
                    !checkRevision(batchEvent) {
                    break
                }
                
                eventsBatched.append(batchEvent)
                
                // NOTE: an event can have multiple visistors
                visitors.append(contentsOf: batchEvent.visitors)
            } else {
                break
            }
        }
        
        guard eventsBatched.count > 0 else {
            // no batched event since the first event is invalid. notify so that it can be removed.
            return (1, nil)
        }

        return (eventsBatched.count, makeBatchEvent(base: eventsBatched.first!, visitors: visitors, url: url, sdkKey: sdkKey))
    }
    
    func makeBatchEvent(base: BatchEvent, visitors: [Visitor], url: URL?, sdkKey: String?) -> EventForDispatch? {
        let batchEvent = BatchEvent(revision: base.revision,
                                    accountID: base.accountID,
                                    clientVersion: base.clientVersion,
                                    visitors: visitors,
                                    projectID: base.projectID,
                                    clientName: base.clientName,
                                    anonymizeIP: base.anonymizeIP,
                                    enrichDecisions: true)
        
        guard let data = try? JSONEncoder().encode(batchEvent) else {
            return nil
        }
        
        guard let sdkKey = sdkKey else {
            return nil
        }
        
        return EventForDispatch(url: url, sdkKey: sdkKey, body: data)
    }
}
