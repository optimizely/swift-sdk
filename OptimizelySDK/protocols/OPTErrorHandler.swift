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

public protocol OPTErrorHandler {
    
    static func createInstance() -> OPTErrorHandler

    /**
     Handle an error thrown by the SDK.
     - Parameter error: The error object to be handled.
     */
    func handleError(error:Error)
    
    /**
     Handle an exception thrown by the SDK.
     - Parameter exception: The exception object to be handled.
     */
    func handlerException(exception:NSException)

}
