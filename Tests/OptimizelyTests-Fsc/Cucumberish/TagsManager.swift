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

struct TagsManager {
    
    static func getExcludedTags() -> [String]? {
        return ["EVENT_BATCHING","DATAFILE_MANAGER","NO_EASY_EVENT_TRACKING","DYNAMIC_LANGUAGES","OASIS-3654","GET_FEATURE_VAR","OASIS-3582","EVENT_FLUSH"]
    }
    
    static func getIncludedTags() -> [String]? {
        return ["FEATURE_ROLLOUT","ALL"]
    }
}
