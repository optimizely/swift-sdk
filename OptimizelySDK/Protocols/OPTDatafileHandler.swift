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

public typealias DatafileDownloadCompletionHandler = (OptimizelyResult<Data?>) -> Void

///
/// The datafile handler is used by the optimizely manager to manage the Optimizely datafile.
///
public protocol OPTDatafileHandler {
    init()
    
    var endPointStringFormat: String { get set }
    /**
    Synchronous call to download the datafile.

    - Parameter sdkKey: sdk key of the datafile to download
    - Parameter datafileConfig: DatafileConfig for the datafile
    - Returns: a valid datafile or null
     */
    func downloadDatafile(sdkKey: String) -> Data?
    
    /**
     Asynchronous download data file.
     - Parameter sdkKey: application context for download
     - Parameter resourceTimeoutInterval: timeout in seconds to wait for resource.
     - Parameter completionHhandler:  listener to call when datafile download complete
     */
    func downloadDatafile(sdkKey: String,
                          resourceTimeoutInterval: Double?,
                          completionHandler:@escaping DatafileDownloadCompletionHandler)
    
    /**
      Start updates to the project datafile .
     
      - Parameter sdkKey: SdkKey for the datafile
     */
    func startUpdates(sdkKey: String, datafileChangeNotification: ((Data) -> Void)?)
    
    /**
     Stop the periodic updates. This should be called when the app goes to background
     
     - Parameter sdkKey: sdk key for datafile.
     */
    func stopUpdates(sdkKey: String)

    /**
     Stop all periodic updates. This should be called when the app goes to background
     */
    func stopAllUpdates()

    /**
     Save the datafile to cache.
     - Parameter sdkKey: sdkKey
     - Parameter datafile: JSON string of datafile.
     */
    func saveDatafile(sdkKey: String, dataFile: Data)
    
    /**
     Load a cached datafile if it exists
     - Parameter sdkKey: sdkKey
     - Returns: the datafile cached or null if it was not available
     */
    func loadSavedDatafile(sdkKey: String) -> Data?
    
    /**
     Has the file already been cached locally?
     - Parameter sdkKey: sdkKey
     - Returns: true if the datafile is cached or false if not.
     */
    func isDatafileSaved(sdkKey: String) -> Bool
    /**
     Remove the datafile in cache.
     - Parameter sdkKey: sdkKey
     */
    func removeSavedDatafile(sdkKey: String)

}
