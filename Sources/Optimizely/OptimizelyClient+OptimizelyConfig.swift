//
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

extension OptimizelyClient : OptimizelyConfig, OptimizelyExperiments, OptimizelyFeatures {
    public var revision: String {
        guard let _ = config?.project else { return ""}
        
        return config?.project.revision ?? ""
    }
    
    public var experiments: OptimizelyExperiments {
        return self
    }
    
    public var features: OptimizelyFeatures {
        return self
    }
    
    public subscript(key: String) -> OptimizelyFeature? {
        return config?.featureFlagKeyMap[key]
    }
    
    public subscript(index: Int) -> OptimizelyFeature? {
        guard config?.featureFlagKeyMap.keys.count ?? 0 > index else { return nil }
        guard let config = config else { return nil }
        let key = Array<String>(config.featureFlagKeyMap.keys)[index]
        return config.featureFlagKeyMap[key]
    }
    
    public subscript(key: String) -> OptimizelyExperiment? {
        return config?.experimentKeyMap[key]
    }
    
    public subscript(index: Int) -> OptimizelyExperiment? {
        guard config?.allExperiments.count ?? 0 > index else { return nil }
        
        return config?.allExperiments[index]
    }
    
}
