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

struct ImpressionEvent: UserEvent, CustomStringConvertible {
    var userContext: UserContext
    var layerId: String
    var experimentKey: String
    var experimentId: String
    var variationKey: String
    var variationId: String
    
    var description: String {
        return "[ImpressionEvent](\(userContext), layerId:\(layerId), experimentId:\(experimentId), experimentKey:\(experimentKey), variationId:\(variationId), variationKey:\(variationKey))"
    }
    
    var batchEvent: BatchEvent {
        let decision = Decision(variationID: variationId,
                                 campaignID: layerId,
                                 experimentID: experimentId)
         
        let dispatchEvent = DispatchEvent(timestamp: timestamp,
                                          key: DispatchEvent.activateEventKey,
                                          entityID: layerId,
                                          uuid: uuid)
        
        return BatchEventBuilder.createBatchEvent(userContext: userContext,
                                                  decisions: [decision],
                                                  dispatchEvents: [dispatchEvent])
    }
}
