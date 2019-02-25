//
//  BatchEvent.swift
//  OptimizelySDK
//
//  Created by Thomas Zurkan on 12/3/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

struct BatchEvent: Codable {
    let revision, accountID, clientVersion: String
    let visitors: [Visitor]
    let projectID, clientName: String
    let anonymizeIP: Bool
    
    enum CodingKeys: String, CodingKey {
        case revision
        case accountID = "account_id"
        case clientVersion = "client_version"
        case visitors
        case projectID = "project_id"
        case clientName = "client_name"
        case anonymizeIP = "anonymize_ip"
    }
}

struct Visitor: Codable {
    let attributes: [EventAttribute]
    let snapshots: [Snapshot]
    let visitorID: String
    
    enum CodingKeys: String, CodingKey {
        case attributes, snapshots
        case visitorID = "visitor_id"
    }
}

struct EventAttribute: Codable {
    let value: AttributeValue
    let key: String
    let shouldIndex: Bool
    let type, entityID: String
    
    enum CodingKeys: String, CodingKey {
        case value, key, shouldIndex, type
        case entityID = "entity_id"
    }
}

struct Snapshot: Codable {
    let decisions: [Decision]
    let events: [DispatchEvent]
}

struct Decision: Codable {
    let variationID, campaignID, experimentID: String
    
    enum CodingKeys: String, CodingKey {
        case variationID = "variation_id"
        case campaignID = "campaign_id"
        case experimentID = "experiment_id"
    }
}

struct DispatchEvent: Codable {
    static let revenueKey = "revenue"
    static let valueKey = "value"
    static let activateEventKey = "campaign_activated"
    let timestamp: Int64
    // entityID is the layer id for impression events.
    let key, entityID, uuid: String
    var tags:Dictionary<String,AttributeValue>? = [:]
    var value:AttributeValue? = nil
    var revenue:AttributeValue? = nil
    
    enum CodingKeys: String, CodingKey {
        case timestamp, key
        case entityID = "entity_id"
        case uuid
    }
    
    init(timestamp:Int64, key:String, entityID:String, uuid:String, tags:Dictionary<String,AttributeValue>?, value:AttributeValue?, revenue:AttributeValue?) {
        self.timestamp = timestamp
        self.key = key
        self.entityID = entityID
        self.uuid = uuid
        self.tags = tags
        self.value = value
        self.revenue = revenue
    }
    
    init(timestamp:Int64, key:String, entityID:String, uuid:String) {
        self.init(timestamp: timestamp, key: key, entityID: entityID, uuid: uuid, tags: [:], value: nil, revenue: nil)
    }

}
