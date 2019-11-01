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

struct ConversionEvent: UserEvent, CustomStringConvertible {
    var userContext: UserContext
    var eventId: String
    var eventKey: String
    var revenue: AttributeValue?
    var value: AttributeValue?
    var tags: OptimizelyEventTags?
        
    var description: String {
        return "[ConversionEvent](\(userContext), eventId:\(eventId), eventKey:\(eventKey), revenue:\(String(describing: revenue)), value:\(String(describing: value)), tags:\(String(describing: tags)))"
    }
    
    init?(userContext: UserContext, eventKey: String, tags: OptimizelyEventTags?) {
        guard let event = userContext.config.getEvent(key: eventKey) else {
            return nil
        }

        self.userContext = userContext
        self.eventKey = eventKey
        self.eventId = event.id
        self.tags = tags
        
        // should not pass tags of invalid types to the server (which will drop entire event if so)
        let filteredTags = filterEventTags(tags)
        
        // {revenue, value} keys are special - must be copied as separate properties
        self.value = extractValueEventTag(filteredTags)
        self.revenue = extractRevenueEventTag(filteredTags)
    }
    
    var batchEvent: BatchEvent {
        let dispatchEvent = DispatchEvent(timestamp: timestamp,
                                          key: eventKey,
                                          entityID: eventId,
                                          uuid: uuid,
                                          tags: filterEventTags(tags),
                                          value: value,
                                          revenue: revenue)
        
        return BatchEventBuilder.createBatchEvent(userContext: userContext,
                                                  decisions: nil,
                                                  dispatchEvents: [dispatchEvent])
    }

}

// MARK: - Event Tags

extension ConversionEvent {
    
    func filterEventTags(_ eventTags: [String: Any]?) -> [String: AttributeValue] {
        let filteredTags = eventTags?.mapValues { AttributeValue(value: $0) }.filter { $0.value != nil } as? [String: AttributeValue]
        return filteredTags ?? [:]
    }
    
    func extractValueEventTag(_ eventTags: [String: AttributeValue]) -> AttributeValue? {
        guard let valueFromTags = eventTags[DispatchEvent.valueKey] else { return nil }
        
        // export {value, revenue} only for {double, int64} types
        var value: AttributeValue?
        
        switch valueFromTags {
        case .double:
            // valid value type
            value = valueFromTags
        case .int(let int64Value):
            value = AttributeValue(value: Double(int64Value))
        default:
            value = nil
        }
        
        return value
    }
    
    func extractRevenueEventTag(_ eventTags: [String: AttributeValue]) -> AttributeValue? {
        guard let revenueFromTags = eventTags[DispatchEvent.revenueKey] else { return nil }
        
        // export {value, revenue} only for {double, int64} types
        var revenue: AttributeValue?
        
        switch revenueFromTags {
        case .int:
            // valid revenue type
            revenue = revenueFromTags
        case .double(let doubleValue):
            // not accurate but acceptable ("3.14" -> "3")
            revenue = AttributeValue(value: Int64(doubleValue))
        default:
            revenue = nil
        }
        
        return revenue
    }

}
