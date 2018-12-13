//
//  BatchEvent.swift
//  OptimizelyCore
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

enum AttributeValue : Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    
    init?(value:Any?) {
        if value is String {
            self = .string(value as! String)
        }
        if value is Int {
            self = .int(value as! Int)
        }
        if value is Double {
            self = .double(value as! Double)
        }
        if value is Bool {
            self = .bool(value as! Bool)
        }
        
        return nil
    }
    
    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer() {
            if let value = try? container.decode(Double.self) {
                self = .double(value)
                return
            }
            if let value = try? container.decode(String.self) {
                self = .string(value)
                return
            }
            if let value = try? container.decode(Int.self) {
                self = .int(value)
                return
            }
            if let value = try? container.decode(Bool.self) {
                self = .bool(value)
                return
            }
        }
        
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Failed to decode event batch attribute value"))
    }
    
    func encode(to encoder: Encoder) throws {
        switch self {
        case .string(let str):
            var container = encoder.singleValueContainer()
            try? container.encode(str)
        case .double(let double):
            var container = encoder.singleValueContainer()
            try? container.encode(double)
        case .int(let int):
            var container = encoder.singleValueContainer()
            try? container.encode(int)
        case .bool(let bool):
            var container = encoder.singleValueContainer()
            try? container.encode(bool)
        }
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
    static let activateEventKey = "campaign_activated"
    let timestamp: Int64
    // entityID is the layer id for impression events.
    let key, entityID, uuid: String
    let tags:Dictionary<String,AttributeValue>? = [:]
    let value:AttributeValue? = .double(0.0)
    let revenue:AttributeValue? = .double(0.0)
    
    enum CodingKeys: String, CodingKey {
        case timestamp, key
        case entityID = "entity_id"
        case uuid
    }
}
