/****************************************************************************
* Copyright 2020, Optimizely, Inc. and contributors                        *
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

extension OptimizelyClient {
    
    /// Set a context of the user for which decision APIs will be called.
    ///
    /// The SDK will keep this context until it is called again with a different context data.
    ///
    /// - This API can be called after SDK initialization is completed (otherwise the __sdkNotReady__ error will be returned).
    /// - Only one user outstanding. The user-context can be changed any time by calling the same method with a different user-context value.
    /// - The SDK will copy the parameter value to create an internal user-context data atomically, so any further change in its caller copy after the API call is not reflected into the SDK state.
    /// - Once this API is called, the following other API calls can be called without a user-context parameter to use the same user-context.
    /// - Each Decide API call can contain an optional user-context parameter when the call targets a different user-context. This optional user-context parameter value will be used once only, instead of replacing the saved user-context. This call-based context control can be used to support multiple users at the same time.
    /// - If a user-context has not been set yet and decide APIs are called without a user-context parameter, SDK will return an error decision (__userNotSet__).
    ///
    /// - Parameters:
    ///   - user: a user-context
    /// - Throws: `OptimizelyError` if SDK fails to set the user context
    public func setUserContext(_ user: OptimizelyUserContext) throws {
        guard self.config != nil else { throw OptimizelyError.sdkNotReady }
                              
        userContext = user
    }
    
    /// Set the default decide-options which are commonly applied to all following decide API calls.
    ///
    /// These options will be overridden when each decide-API call provides own options.
    ///
    /// - Parameter options: An array of default decision options.
    public func setDefaultDecideOptions(_ options: [OptimizelyDecideOption]) {
        defaultDecideOptions = options
    }
    
}
