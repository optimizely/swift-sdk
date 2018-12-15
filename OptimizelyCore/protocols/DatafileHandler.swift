//
//  DatafileHandler.swift
//  OptimizelyCore
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
     * Synchronous call to download the datafile.
     *
     * @param context   application context for download
     * @param datafileConfig DatafileConfig for the datafile
     * @return a valid datafile or null
     */
    func downloadDatafile(sdkKey:String) -> String?
    
    /**
     * Asynchronous download data file.
     *
     * @param context   application context for download
     * @param datafileConfig DatafileConfig for the datafile to get
     * @param completionHhandler  listener to call when datafile download complete
     */
    func downloadDatafile(sdkKey:String, completionHandler:@escaping DatafileDownloadCompletionHandler)
    
    /**
     * Start background updates to the project datafile .
     *
     * @param context application context for download
     * @param datafileConfig DatafileConfig for the datafile
     * @param updateInterval frequency of updates in seconds
     */
    func startBackgroundUpdates(sdkKey:String, updateInterval:Int)
    
    /**
     * Stop the background updates.
     *
     * @param context   application context for download
     * @param datafileConfig DatafileConfig for the datafile
     */
    func stopBackgroundUpdates(sdkKey:String)
    
    /**
     * Save the datafile to cache.
     *
     * @param context   application context for datafile cache
     * @param datafileConfig DatafileConfig for the datafile
     * @param dataFile  the datafile to save
     */
    func saveDatafile(sdkKey:String, dataFile:String)
    
    /**
     * Load a cached datafile if it exists
     *
     * @param context   application context for datafile cache
     * @param projectId project id of the datafile to try and get from cache
     * @return the datafile cached or null if it was not available
     */
    func loadSavedDatafile(sdkKey:String) -> String?
    
    /**
     * Has the file already been cached locally?
     *
     * @param context   application context for datafile cache
     * @param datafileConfig DatafileConfig for the datafile
     * @return true if the datafile is cached or false if not.
     */
    func isDatafileSaved(sdkKey:String) -> Bool
    /**
     * Remove the datafile in cache.
     *
     * @param context   application context for datafile cache
     * @param datafileConfig DatafileConfig for the datafile
     */
    func removeSavedDatafile(sdkKey:String)

}
