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
    var events: [ODPEvent]
    let queue: DispatchQueue

    init() {
        self.queue = DispatchQueue(label: "event")
        self.events = []
    }
}


// MARK: - ODP

extension ODPEventManager {
    
    func registerVUID(vuid: String) {
        let identifiers = [
            "vuid": vuid
        ]
        
        queue.async {
            self.events.append(ODPEvent(kind: "experimentation:client_initialized", identifiers: identifiers, data: [:]))
        }
    }
    
    func identifyUser(vuid: String, userId: String) {
        let identifiers = [
            "vuid": vuid,
            "fs_user_id": userId
        ]

        queue.async {
            self.events.append(ODPEvent(kind: "experimentation:identified", identifiers: identifiers, data: [:]))
        }
    }
    
    func flush() {
        var events = [ODPEvent]()
        queue.sync {
            events = self.events
        }
        
        for event in events {
            sendODPEvent(event)
        }
    }
    
    func sendODPEvent(_ event: ODPEvent) {
        let odpApiKey: String = ""
        let odpApiHost: String = ""
        
        zaiusMgr.sendODPEvent(apiKey: odpApiKey,
                              apiHost: odpApiHost,
                              identifiers: event.identifiers,
                              kind: event.kind,
                              data: event.data) { error in
            //
        }
    }
    
}


