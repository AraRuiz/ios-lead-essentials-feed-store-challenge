//
//  CoreDataFeedStore.swift
//  FeedStoreChallenge
//
//  Created by Araceli Ruiz Ruiz on 17/05/2020.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import Foundation
import CoreData

@objc(ManagedFeedImage)
private class ManagedFeedImage: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var imageDescription: String?
    @NSManaged public var location: String?
    @NSManaged public var url: URL
    @NSManaged public var cache: ManagedCache
}

@objc(ManagedCache)
private class ManagedCache: NSManagedObject {
    @NSManaged public var timestamp: Date
    @NSManaged public var feed: NSOrderedSet
}

public final class CoreDataFeedStore: FeedStore {
    private let container: NSPersistentContainer
    
    public init(storeURL: URL, bundle: Bundle = .main) {
        let modelURL = bundle.url(forResource: "CoreDataFeedStore", withExtension: "momd")!
        let model = NSManagedObjectModel(contentsOf: modelURL)!
        container = NSPersistentContainer(name: "CoreDataFeedStore", managedObjectModel: model)
        let description = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                print("Unresolved error \(error)")
            }
        }
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {}
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let context = container.viewContext
        context.perform {
            do {
                let managedCache = ManagedCache(context: context)
                managedCache.feed = NSOrderedSet(array: feed.map {
                    let managedFeedImage = ManagedFeedImage(context: context)
                    managedFeedImage.id = $0.id
                    managedFeedImage.imageDescription = $0.description
                    managedFeedImage.location = $0.location
                    managedFeedImage.url = $0.url
                    return managedFeedImage
                })
                
                managedCache.timestamp = timestamp
                
                try context.save()
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        let context = container.viewContext
        context.perform {
            do {
                let request = NSFetchRequest<ManagedCache>(entityName: "ManagedCache")
                if let cache = try context.fetch(request).first {
                    let localFeedImages = cache.feed.compactMap { $0 as? ManagedFeedImage }
                        .map {
                            LocalFeedImage(id: $0.id, description: $0.imageDescription, location: $0.location, url: $0.url)
                    }
                    completion(.found(feed: localFeedImages, timestamp: cache.timestamp))
                } else {
                    completion(.empty)
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
}
