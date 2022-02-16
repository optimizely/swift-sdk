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

// DecisionTableGenerator + Utils

extension DecisionTableGenerator {

    static func getAllRulesInOrderForFlag(config: ProjectConfig, flag: FeatureFlag) -> [Experiment] {
        var rules = flag.experimentIds.compactMap { expId in
            return config.allExperiments.filter { $0.id == expId }.first
        }
        
        let rollout = config.project.rollouts.filter { $0.id == flag.rolloutId }.first
        rules.append(contentsOf: rollout?.experiments ?? [])

        return rules
    }
    
    static func makeAllAudiences(config: ProjectConfig) -> [Audience] {
        let project = config.project!

        var audiences = project.typedAudiences ?? []
        project.audiences.forEach { oldAudience in
            if audiences.filter({ newAudience in newAudience.id == oldAudience.id }).isEmpty {
                guard oldAudience.id != "$opt_dummy_audience" else { return }
                audiences.append(oldAudience)
            }
        }

        return audiences
    }
    
    static func saveOriginalDatafileToFile(optimizely: OptimizelyClient) {
        guard var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("FileManager saveDecisionTablesToFile error")
            return
        }
        
        url.appendPathComponent("decisionTables")
        
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("FileManager saveDecisionTablesToFile create folder error")
                return
            }
        }
        
        let sdkKey = optimizely.sdkKey
        if let data = optimizely.datafileHandler?.loadSavedDatafile(sdkKey: sdkKey),
           let datafile = String(bytes: data, encoding: .utf8) {
            
            let filename = "\(sdkKey).json"
            let urlOriginal = url.appendingPathComponent(filename)
            try? datafile.write(to: urlOriginal, atomically: true, encoding: .utf8)
        }
    }
        
    static func saveDecisionTablesToFile(sdkKey: String, decisionTables: OptimizelyDecisionTables, suffix: String) {
        guard var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("FileManager saveDecisionTablesToFile error")
            return
        }
        
        url.appendPathComponent("decisionTables")
        
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("FileManager saveDecisionTablesToFile create folder error")
                return
            }
        }
                
        let filename = "\(sdkKey).\(suffix)"
        let urlText = url.appendingPathComponent(filename)
        let contentsInText = decisionTableInTextFormat(sdkKey: sdkKey, decisionTables: decisionTables)
        try? contentsInText.write(to: urlText, atomically: true, encoding: .utf8)
        
        let urlJson = url.appendingPathComponent("\(filename).json")
        let contentsInJson = decisionTableInJSONFormat(sdkKey: sdkKey, decisionTables: decisionTables, pretty: false)
        try? contentsInJson.write(to: urlJson, atomically: true, encoding: .utf8)
        
        let urlJson2 = url.appendingPathComponent("\(filename).pretty.json")
        let contentsInJson2 = decisionTableInJSONFormat(sdkKey: sdkKey, decisionTables: decisionTables, pretty: true)
        try? contentsInJson2.write(to: urlJson2, atomically: true, encoding: .utf8)
    }
    
    static func decisionTableInTextFormat(sdkKey: String, decisionTables: OptimizelyDecisionTables) -> String {
        var contents = "SDKKey: \(sdkKey)\n"
        
        let sortedFlagKeys = decisionTables.tables.keys.sorted { $0 < $1 }
        sortedFlagKeys.forEach { flagKey in
            let table = decisionTables.tables[flagKey]!
            
            contents += "\n[Flag]: \(flagKey)\n"
            contents += "\n   [Schemas]\n"
            table.schemas.array.forEach {
                contents += "\($0)\n"
            }
            
            contents += "\n   [DecisionTable]\n"
            
            table.bodyInArray.forEach { (input, decision) in
                contents += "      \(input) -> \(decision)\n"
            }
        }
        
        if decisionTables.audiences.count > 0 {
            contents += "\n\n[Audiences]\n"
            decisionTables.audiences.forEach { audience in
                contents += "   \(audience.name) (\(audience.id)) \(audience.conditions)\n"
            }
        }

        return contents
    }

    static func decisionTableInJSONFormat(sdkKey: String, decisionTables: OptimizelyDecisionTables, pretty: Bool) -> String {
        do {
            let encoder = JSONEncoder()
            if pretty {
                encoder.outputFormatting = [.prettyPrinted]
            }

            let data = try encoder.encode(decisionTables)
            let str = String(data: data, encoding: .utf8) ?? "invalid JSON data"
            return str
        } catch {
            return "JSON failed: \(error)"
        }
    }

}
