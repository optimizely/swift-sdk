//
//  BatchEvent.swift
//  OptimizelySDK
//
//  Created by Thomas Zurkan on 12/3/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

struct BatchEvent: Codable, Equatable {
    var revision: String
    var accountID: String
    var clientVersion: String
    var visitors: [Visitor]
    var projectID: String
    var clientName: String
    var anonymizeIP: Bool
    var enrichDecisions: Bool
    
    enum CodingKeys: String, CodingKey {
        case revision
        case accountID = "account_id"
        case clientVersion = "client_version"
        case visitors
        case projectID = "project_id"
        case clientName = "client_name"
        case anonymizeIP = "anonymize_ip"
        case enrichDecisions = "enrich_decisions"
    }
    
    func getEventAttribute(key: String) -> EventAttribute? {
        for visitor in visitors {
            if let attribute = visitor.attributes.filter({ $0.key == key }).first {
                return attribute
            }
        }
        
        return nil
    }
}

struct Visitor: Codable, Equatable {
    var attributes: [EventAttribute]
    var snapshots: [Snapshot]
    var visitorID: String
    
    enum CodingKeys: String, CodingKey {
        case attributes
        case snapshots
        case visitorID = "visitor_id"
    }
}

struct EventAttribute: Codable, Equatable {
    var value: AttributeValue
    var key: String
    var type: String
    var entityID: String
    
    enum CodingKeys: String, CodingKey {
        case value
        case key
        case type
        case entityID = "entity_id"
    }
}

struct Snapshot: Codable, Equatable {
    var decisions: [Decision]?
    var events: [DispatchEvent]
}

struct Decision: Codable, Equatable {
    var variationID, campaignID, experimentID: String
    
    enum CodingKeys: String, CodingKey {
        case variationID = "variation_id"
        case campaignID = "campaign_id"
        case experimentID = "experiment_id"
    }
}

struct DispatchEvent: Codable, Equatable {
    static let revenueKey = "revenue"
    static let valueKey = "value"
    static let activateEventKey = "campaign_activated"
    
    // entityID is the layer id for impression events.
    var entityID: String
    var key: String
    var timestamp: Int64
    var uuid: String
    var tags: [String: AttributeValue]?
    var revenue: AttributeValue?
    var value: AttributeValue?

    enum CodingKeys: String, CodingKey {
        case entityID = "entity_id"
        case key
        case tags
        case timestamp
        case uuid
        case revenue
        case value
    }
    
    init(timestamp: Int64,
         key: String,
         entityID: String,
         uuid: String,
         tags: [String: AttributeValue]? = [:],
         value: AttributeValue? = nil,
         revenue: AttributeValue? = nil)
    {
        
        // TODO: add validation and throw here for invalid value (int, double) and revenue (int) types

        self.timestamp = timestamp
        self.key = key
        self.entityID = entityID
        self.uuid = uuid
        self.tags = tags
        self.value = value
        self.revenue = revenue
    }
}
