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
    func batch() -> EventForDispatch? {
        if count < 2 {
            return first
        }
        
        var visitors: [Visitor] = [Visitor]()
        var url: URL?
        var projectId: String?
        
        let checkUrl = { (event: EventForDispatch) -> Bool in
            if url == nil {
                url = event.url
                return true
            }
            return url == event.url
        }
        
        let checkProjectId = { (batchEvent: BatchEvent) -> Bool in
            if projectId == nil {
                projectId = batchEvent.projectID
                return true
            }
            return projectId == batchEvent.projectID
        }

        var firstBatchEvent: BatchEvent?
        
        for event in self {
            if let batchEvent = try? JSONDecoder().decode(BatchEvent.self, from: event.body) {
                if !checkUrl(event) || !checkProjectId(batchEvent) {
                    return nil
                }
                visitors.append(contentsOf: batchEvent.visitors)
                if firstBatchEvent != nil {
                } else {
                    firstBatchEvent = batchEvent
                }
            }
        }
        
        guard let first = firstBatchEvent, let tmpUrl = url else {
            return nil
        }
        
        let batchEvent = BatchEvent(revision: first.revision,
                                    accountID: first.accountID,
                                    clientVersion: first.clientVersion,
                                    visitors: visitors,
                                    projectID: first.projectID,
                                    clientName: first.clientName,
                                    anonymizeIP: first.anonymizeIP,
                                    enrichDecisions: true)
        
        if let data = try? JSONEncoder().encode(batchEvent) {
            return EventForDispatch(url: tmpUrl, body: data)
        }
        return nil
    }
}
