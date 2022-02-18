//
// Copyright 2021, Optimizely, Inc. and contributors 
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
import CoreText

// Compressed + Flat-audiences

extension DecisionTableGenerator {

    public static func createDecisionTableCompressedFlatAudiences(optimizely: OptimizelyClient) -> OptimizelyDecisionTables {
        let config = optimizely.config!
        let flags = config.getFeatureFlags()

        var decisionTablesMap = [String: FlagDecisionTable]()

        for flag in flags.sorted(by: { $0.key < $1.key }) {
            print("\n[Flag]: \(flag.key)")

            let rules = getAllRulesInOrderForFlag(config: config, flag: flag)
            
            let schemas = makeSchemasCompressedFlatAudiences(config: config, rules: rules)
            let (compressed, bodyInArray) = makeTableBodyCompressedFlatAudiences(optimizely: optimizely, flagKey: flag.key, schemas: schemas)
            decisionTablesMap[flag.key] = FlagDecisionTable(key: flag.key, schemas: schemas, bodyInArray: bodyInArray, compressed: compressed)
        }
    
        let audiences = compressAllAudiences(config: config)
        let sdkKey = optimizely.sdkKey
        
        let decisionTables = OptimizelyDecisionTables(sdkKey: sdkKey, tables: decisionTablesMap, audiences: audiences)
        saveDecisionTablesToFile(sdkKey: sdkKey, decisionTables: decisionTables, suffix: "table-flat-audiences")
        
        return decisionTables
    }

    // MARK: - DecisionSchemas (Compressed + Flat-Audiences)

    static func makeSchemasCompressedFlatAudiences(config: ProjectConfig, rules: [Experiment]) -> [DecisionSchema] {
        let schemas = makeSchemasCompressed(config: config, rules: rules)
        // optimize later if needed
        return schemas
    }

    // MARK: - DecisionTable Body (Compressed + Flat-Audiences)

    static func makeTableBodyCompressedFlatAudiences(optimizely: OptimizelyClient, flagKey: String, schemas: [DecisionSchema]) -> (Bool, [(String, String)]) {
        let body = makeTableBodyCompressed(optimizely: optimizely,
                                           flagKey: flagKey,
                                           schemas: schemas)
        // optimize later if needed
        return body
    }
    
    // MARK: - Utils
    
    static func compressAllAudiences(config: ProjectConfig) -> [Audience] {
        let audiences = makeAllAudiences(config: config)
        
        var compressed = [Audience]()
        for var audience in audiences {
            audience.conditionHolder = flattenAudienceConditions(audience.conditionHolder)
            audience.conditionHolder = mergeAudienceConditions(audience.conditionHolder)
            
            // update serialized strings too (to avoid confusion later)
            audience.conditions = serializeConditionHolder(audience.conditionHolder)

            compressed.append(audience)
        }
        
        return compressed
    }
    
    static func flattenAudienceConditions(_ condition: ConditionHolder) -> ConditionHolder {
        guard case ConditionHolder.array(let array) = condition else { return condition }

        if array.count == 2, case ConditionHolder.logicalOp = array[0] {
            return flattenAudienceConditions(array[1])   // repeat into lower levels
        }
          
        var compressedCondition: [ConditionHolder] = [array[0]]
        let operands = array[1...]

        for item in operands {
            switch item {
            case .array:
                // recursive call for compression
                compressedCondition.append(flattenAudienceConditions(item))
            default:
                compressedCondition.append(item)
            }
        }

        return ConditionHolder.array(compressedCondition)
    }
    
    static func mergeAudienceConditions(_ condition: ConditionHolder) -> ConditionHolder {
        guard case ConditionHolder.array(let array) = condition else { return condition }
        guard array.count > 2 else { return condition }
        guard case ConditionHolder.logicalOp(let op) = array[0] else { return condition }
        
        let operands = array[1...]

        // merge only with OR operator with multiple operands with all same name and
        // "exact" or "substring" matches
        
        if case LogicalOp.or = op {
            var merged = true
            
            var commonUserAttribute: UserAttribute?
            var mergedValues = [Any]()
            for item in operands {
                guard case ConditionHolder.leaf(let leaf) = item,
                      case .attribute(let userAttribute) = leaf else {
                          merged = false
                          break
                      }
                
                if commonUserAttribute == nil {
                    commonUserAttribute = userAttribute
                }
                
                guard commonUserAttribute!.name == userAttribute.name,
                      commonUserAttribute!.match == userAttribute.match,
                      AttributeValue.isSameType(commonUserAttribute!.value, userAttribute.value)  // some condition is mixed up with multiple types. DO NOT merge them.
                else {
                    merged = false
                    break
                }
                                    
                switch userAttribute.value {
                case .string(let value):
                    mergedValues.append(value)
                case .int(let value):
                    mergedValues.append(value)
                case .double(let value):
                    mergedValues.append(value)
                default:
                    break
                }
            }
        
            if merged, var mergedAttributes = commonUserAttribute {
                if mergedAttributes.match == "exact" || mergedAttributes.match == "substring" {
                    mergedAttributes.match = (mergedAttributes.match == "exact") ? "member" : "member_substring"
                    mergedAttributes.value = AttributeValue(value: mergedValues)
                    return ConditionHolder.leaf(ConditionLeaf.attribute(mergedAttributes))
                } else {
                    // merge not supported for other types yet
                }
            }
        }

        // look into next-level for compression
        
        var compressedCondition: [ConditionHolder] = [array[0]]
        
        for item in operands {
            switch item {
            case .array:
                // recursive call for compression
                compressedCondition.append(mergeAudienceConditions(item))
            default:
                compressedCondition.append(item)
            }
        }

        return ConditionHolder.array(compressedCondition)
    }
    
    static func serializeConditionHolder(_ conditionHolder: ConditionHolder) -> String {
        // update serialized strings too (to avoid confusion later)
        let sortEncoder = JSONEncoder()
        if #available(iOSApplicationExtension 11.0, *) {
            sortEncoder.outputFormatting = .sortedKeys
        }
        
        var serialized = ""
        if let data = try? sortEncoder.encode(conditionHolder) {
            serialized = String(bytes: data, encoding: .utf8) ?? ""
        }
        
        return serialized
    }

}
