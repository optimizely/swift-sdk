//
//  DatafileHandler.swift
//  OptimizelySDK
//
//  Created by Thomas Zurkan on 12/3/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

public struct DatafileDownloadError : Error {
    var description:String
    
    init(description:String) {
        self.description = description
    }
}

public typealias DatafileDownloadCompletionHandler = (Result<String,DatafileDownloadError>) -> Void

public protocol DatafileHandler {
    /**
    Synchronous call to download the datafile.

    - Parameter sdkKey:   sdk key of the datafile to download
    - Parameter datafileConfig: DatafileConfig for the datafile
    - Returns: a valid datafile or null
     */
    func downloadDatafile(sdkKey:String) -> String?
    
    /**
     Asynchronous download data file.
     - Parameter sdkKey:   application context for download
     - Parameter completionHhandler:  listener to call when datafile download complete
     */
    func downloadDatafile(sdkKey:String, completionHandler:@escaping DatafileDownloadCompletionHandler)
    
    /**
      Start periodic updates to the project datafile .
     
      - Parameter sdkKey: SdkKey for the datafile
      - Parameter updateInterval: frequency of updates in seconds
     */
    func startPeriodicUpdates(sdkKey:String, updateInterval:Int)
    
    /**
     Stop the periodic updates. This should be called when the app goes to background
     
     - Parameter sdkKey: sdk key for datafile.
     */
    func stopPeriodicUpdates(sdkKey:String)

    /**
     Stop all periodic updates. This should be called when the app goes to background
     */
    func stopPeriodicUpdates()

    /**
     Save the datafile to cache.
     - Parameter sdkKey: sdkKey
     - Parameter datafile: JSON string of datafile.
     */
    func saveDatafile(sdkKey:String, dataFile:String)
    
    /**
     Load a cached datafile if it exists
     - Parameter sdkKey: sdkKey
     - Returns: the datafile cached or null if it was not available
     */
    func loadSavedDatafile(sdkKey:String) -> String?
    
    /**
     Has the file already been cached locally?
     - Parameter sdkKey: sdkKey
     - Returns: true if the datafile is cached or false if not.
     */
    func isDatafileSaved(sdkKey:String) -> Bool
    /**
     Remove the datafile in cache.
     - Parameter sdkKey: sdkKey
     */
    func removeSavedDatafile(sdkKey:String)

}
