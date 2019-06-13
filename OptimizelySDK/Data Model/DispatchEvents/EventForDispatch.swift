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

@objcMembers public class EventForDispatch: NSObject, Codable {
    static let eventEndpoint = "https://logx.optimizely.com/v1/events"
    
    public let url: URL
    public let body: Data

    public init(url: URL? = nil, body: Data) {
        self.url = url ?? URL(string: EventForDispatch.eventEndpoint)!
        self.body = body
    }
    
    // override NSObject Equatable ('==' overriding not working for NSObject)
    override public func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? EventForDispatch else { return false }
        return url == object.url && body == object.body
    }
}

extension EventForDispatch {
    override public var description: String {
        return "[url] \(url) (" + (String(data: body, encoding: .utf8) ?? "UNKNOWN") + ")"
    }
}
