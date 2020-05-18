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
    
#if DEBUG || OPT_DBG

import Foundation
import CoreData

class LogDBManager {
    
    static let shared = LogDBManager()
    
    // MARK: - props
    
    private var priSessionId = AtomicProperty<Int>(property: 0)
    var sessionId: Int {
        get {
            return priSessionId.property!
        }
        set {
            priSessionId.property = newValue
        }
    }
    
    struct FetchSession {
        var id: Int
        var level: OptimizelyLogLevel
        var keyword: String?
        var countPerPage: Int
        var nextPage: Int = 0
        
        init(id: Int, level: OptimizelyLogLevel, keyword: String? = nil, countPerPage: Int) {
            self.id = id
            self.level = level
            self.keyword = keyword
            self.countPerPage = countPerPage
        }
    }
    
    var sessions = [Int: FetchSession]()
    
    // MARK: - Thread-safe CoreData

    lazy var persistentContainer: NSPersistentContainer? = {
        let modelName = "LogModel"
        guard let modelURL = Bundle(for: type(of: self)).url(forResource: modelName, withExtension: "momd") else {
            print("[ERROR] loading model from bundle")
            return nil
        }

        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            print("[ERROR] Error initializing mom from: \(modelURL)")
            return nil
        }

        let container = NSPersistentContainer(name: modelName, managedObjectModel: mom)
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                print("[ERROR] Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        let storeDescription = NSPersistentStoreDescription()
        storeDescription.shouldMigrateStoreAutomatically = true
        storeDescription.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [storeDescription]
        
        return container
    }()
    
    lazy var mainContext: NSManagedObjectContext? = {
        return self.persistentContainer?.viewContext
    }()
    
    lazy var backgroundContext: NSManagedObjectContext? = {
        return self.persistentContainer?.newBackgroundContext()
    }()
    
    lazy var defaultContext: NSManagedObjectContext? = {
        if Thread.isMainThread {
            return self.mainContext
        } else {
            return self.backgroundContext
        }
    }()
    
    // MARK: - init
    
    private init() {
    }
    
    // MARK: - methods
    
    func saveContext () {
        guard let context = defaultContext else { return }

        context.perform {   // thread-safe
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    let nserror = error as NSError
                    print("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        }
    }

    func insert(level: OptimizelyLogLevel, module: String, text: String) {
        guard let context = defaultContext else { return }

        context.perform {
            let entity = NSEntityDescription.entity(forEntityName: "LogItem", in: context)!
            let logItem = NSManagedObject(entity: entity, insertInto: context)
            
            logItem.setValue(level.rawValue, forKey: "level")
            logItem.setValue(module, forKey: "module")
            logItem.setValue(text, forKey: "text")
            logItem.setValue(Date(), forKey: "date")
            
            self.saveContext()
        }
    }
    
    func read(level: OptimizelyLogLevel, keyword: String?, countPerPage: Int = 25) -> (Int, [LogItem]) {
        priSessionId.performAtomic { value in
            priSessionId.property = value + 1
        }
        
        let session = FetchSession(id: sessionId, level: level, keyword: keyword, countPerPage: countPerPage)
        sessions[session.id] = session
        
        let items = fetchDB(session: session)
        
        return (sessionId, items)
    }
    
    func read(sessionId: Int) -> (Int, [LogItem]) {
        guard let session = sessions[sessionId] else { return (sessionId, []) }
        
        let items = fetchDB(session: session)
        return (sessionId, items)
    }
    
    func clear() {
        guard let context = defaultContext else { return }

        context.perform {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "LogItem")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            
            do {
                try context.execute(deleteRequest)
                try context.save()
            } catch {
                print("[ERROR] log clear failed: \(error)")
            }
        }
    }
    
    private func fetchDB(session: FetchSession) -> [LogItem] {
        guard let context = defaultContext else { return [] }

        var items = [LogItem]()
        
        context.performAndWait {
            let request = NSFetchRequest<NSManagedObject>(entityName: "LogItem")
            let sort = NSSortDescriptor(key: "date", ascending: false)
            request.sortDescriptors = [sort]
            var subpredicates = [NSPredicate]()
            subpredicates.append(NSPredicate(format: "level <= %d", session.level.rawValue))
            if let kw = session.keyword {
                subpredicates.append(NSPredicate(format: "text CONTAINS[cd] %@", kw))
            }
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
            
            if let fetched = try? context.fetch(request) as? [LogItem] {
                print("Fetched log items: \(fetched)")
                items = fetched
            } else {
                print("[ERROR] Failed to read log DB)")
                items = []
            }
        }
        
        return items
    }
    
}

#endif
