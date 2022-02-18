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

public class DecisionTableGenerator {
    
    public static func create(for optimizely: OptimizelyClient) -> OptimizelyDecisionTables {
        // save original datafile for reference
        saveOriginalDatafileToFile(optimizely: optimizely)
        
        var decisionTables: OptimizelyDecisionTables
        //decisionTables = createDecisionTableUncompressed(optimizely: optimizely)
        decisionTables = createDecisionTableCompressed(optimizely: optimizely)
        //decisionTables = createDecisionTableCompressedToRanges(optimizely: optimizely)
        decisionTables = createDecisionTableCompressedFlatAudiences(optimizely: optimizely)
        
        // set decision table for decide tests
        optimizely.decisionTables = decisionTables
        return decisionTables
    }
    
}
