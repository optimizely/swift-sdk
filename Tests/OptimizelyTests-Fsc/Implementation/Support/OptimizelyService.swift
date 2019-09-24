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
import Optimizely

class OptimizelyE2EService {
    
    private let datafilesDirectory = "Datafiles"
    private var optimizelyClient: OptimizelyClient? = nil
    
    private static var i = 0
    private var requestModel: RequestModel?
    
    private init() {
    }
    
    public static func LoadOptimizelyE2E(request : RequestModel) -> OptimizelyE2EService? {
        
        let optimizelyE2E = OptimizelyE2EService()
        optimizelyE2E.requestModel = request
        
        _ = optimizelyE2E
            .buildOptimizelyClient()
        
        return optimizelyE2E
    }
    
    public func run() throws -> ResponseModel?  {
        
        var responseModel = ResponseModel()
        guard let api = requestModel?.api, let arguments = requestModel?.arguments else {
            return nil
        }
        
        do {
            switch api {
            case API.featureVariableBoolean.rawValue:
                let request = FeatureVariableAPIRequestModel(dictionary: arguments)
                var result = false
                if let value = try optimizelyClient?.getFeatureVariableBoolean(featureKey: request.featureKey, variableKey: request.variableKey, userId: request.userId, attributes: request.attributes) {
                    result = value
                }
                responseModel.result = (result ? "TRUE" : "FALSE")
                break
            case API.featureVariableDouble.rawValue:
                let request = FeatureVariableAPIRequestModel(dictionary: arguments)
                if let value = try optimizelyClient?.getFeatureVariableDouble(featureKey: request.featureKey, variableKey: request.variableKey, userId: request.userId, attributes: request.attributes) {
                    responseModel.result = value
                }
                break
            case API.featureVariableInteger.rawValue:
                let request = FeatureVariableAPIRequestModel(dictionary: arguments)
                if let value = try optimizelyClient?.getFeatureVariableInteger(featureKey: request.featureKey, variableKey: request.variableKey, userId: request.userId, attributes: request.attributes) {
                    responseModel.result = value
                }
                break
            case API.featureVariableString.rawValue:
                let request = FeatureVariableAPIRequestModel(dictionary: arguments)
                if let value = try optimizelyClient?.getFeatureVariableString(featureKey: request.featureKey, variableKey: request.variableKey, userId: request.userId, attributes: request.attributes) {
                    responseModel.result = value
                }
                break
                
            default:
                break
            }
        }
        catch {
            print(error.localizedDescription)
        }
        
        return responseModel
    }
    
    private func buildOptimizelyClient() -> OptimizelyE2EService {
        
        guard let dataFileName = requestModel?.datafileName
            else { return self}
        
        var data: Data?
        
        guard let url = Bundle.init(for: FSCTests.self).url(forResource: dataFileName, withExtension: nil, subdirectory: datafilesDirectory) else {
            return self
        }
        do {
            data = try Data(contentsOf: url)
        } catch  {
            print("invalid Data of type json")
            return self
        }
        
        OptimizelyE2EService.i = OptimizelyE2EService.i + 1
        optimizelyClient = OptimizelyClient(sdkKey: String(OptimizelyE2EService.i), periodicDownloadInterval: 0)
        if let _data = data {
            do {
                try optimizelyClient?.start(datafile: _data, doFetchDatafileBackground: false)
            } catch {
                print("Exception occured initializing with datafile")
            }
        }
        
        return self
    }

}

