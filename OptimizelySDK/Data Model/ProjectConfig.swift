/****************************************************************************
 * Copyright 2018, Optimizely, Inc. and contributors                        *
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

class ProjectConfig : Codable {
    
    var project: Project!
    
    var whitelistUsers = [String: [String: String]]()
    
    init(datafile: Data) throws {
        do {
            self.project = try JSONDecoder().decode(Project.self, from: datafile)
        } catch {
            // TODO: clean up (debug only)
            print(">>>>> Project Decode Error: \(error)")
            throw OptimizelyError.dataFileInvalid
        }
    }
    
    convenience init(datafile: String) throws {
        guard let data = datafile.data(using: .utf8) else {
            throw OptimizelyError.dataFileInvalid
        }
        
        try self.init(datafile: data)
   }
    
    init() {
        // TODO: [Jae] fix to throw error
    }
    
    class func DateFromString(dateString:String) -> NSDate
    {
        let dateFormatter = DateFormatter()
        let enUSPosixLocale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.locale = enUSPosixLocale as Locale
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return dateFormatter.date(from: dateString)! as NSDate
    }
}

extension ProjectConfig {
    func whitelistUser(userId:String, experimentId:String, variationId:String) {
        if var dic = whitelistUsers[userId] {
            dic[experimentId] = variationId
        }
        else {
            var dic = Dictionary<String,String>()
            dic[experimentId] = variationId
            whitelistUsers[userId] = dic
        }
    }
    func getWhitelistedVariationId(userId:String, experimentId:String) -> String? {
        if var dic = whitelistUsers[userId] {
            return dic[experimentId]
        }
        return nil
    }
}

