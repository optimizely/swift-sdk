//
// Copyright 2022, Optimizely, Inc. and contributors 
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

struct ODPEvent {
    let kind: String
    let identifiers: [String: Any]
    let data: [String: Any]
}

class ODPEventManager {
    let odpConfig: OptimizelyODPConfig
    var events: [ODPEvent]
    let queue: DispatchQueue
    let zaiusMgr: ZaiusRestApiManager
    
    let logger = OPTLoggerFactory.getLogger()

    init(odpConfig: OptimizelyODPConfig) {
        self.odpConfig = odpConfig
        self.events = []
        self.queue = DispatchQueue(label: "event")
        self.zaiusMgr = ZaiusRestApiManager()
    }
    
    // MARK: - ODP API
    
    func registerVUID(vuid: String) {
        let identifiers = [
            "vuid": vuid
        ]
        
        queue.async {
            self.events.append(ODPEvent(kind: "experimentation:client_initialized", identifiers: identifiers, data: [:]))
            self.flushEvents(self.events)
        }
    }
    
    func identifyUser(vuid: String, userId: String) {
        let identifiers = [
            "vuid": vuid,
            "fs_user_id": userId
        ]

        queue.async {
            self.events.append(ODPEvent(kind: "experimentation:identified", identifiers: identifiers, data: [:]))
            self.flushEvents(self.events)
        }
    }
    
    // MARK: - Events
    
    func flush() {
        queue.async {
            self.flushEvents(self.events)
        }
    }
    
    private func flushEvents(_ events: [ODPEvent]) {
        guard let odpApiKey = odpConfig.apiKey else {
            logger.d("ODP event cannot be dispatched since apiKey not defined")
            return
        }
        
        for event in events {
            sendODPEvent(event, apiKey: odpApiKey, apiHost: odpConfig.apiHost)
        }
    }
    
    func sendODPEvent(_ event: ODPEvent, apiKey: String, apiHost: String) {
        zaiusMgr.sendODPEvent(apiKey: apiKey,
                              apiHost: apiHost,
                              identifiers: event.identifiers,
                              kind: event.kind,
                              data: event.data) { error in
            if error != nil {
                self.logger.w("ODP event dispatch failed: \(error!)")
            }
        }
    }
    
}


