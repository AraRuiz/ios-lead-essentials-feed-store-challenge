//
//  CoreDataFeedStore.swift
//  FeedStoreChallenge
//
//  Created by Araceli Ruiz Ruiz on 17/05/2020.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import Foundation
import CoreData

public final class CoreDataFeedStore: FeedStore {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    public init(storeURL: URL, bundle: Bundle = .main) throws {
        container = try NSPersistentContainer.load(modelName: "CoreDataFeedStore", url: storeURL, in: bundle)
        context = container.newBackgroundContext()
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        let context = self.context
        context.perform {
            do {
                try ManagedCache.get(from: context).map(context.delete)
                try context.save()
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let context = self.context
        context.perform {
            do {
                let managedCache = try ManagedCache.uniqueManagedCache(in: context)
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
        let context = self.context
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

private extension NSPersistentContainer {
    enum LoadingError: Swift.Error {
        case modelNotFound
        case loadPersistentStoresFail(Swift.Error)
    }
    
    static func load(modelName: String, url: URL, in bundle: Bundle) throws -> NSPersistentContainer {
        guard let model = NSManagedObjectModel.with(modelName: modelName, in: bundle) else {
            throw LoadingError.modelNotFound
        }
        let container = NSPersistentContainer(name: modelName, managedObjectModel: model)
        let description = NSPersistentStoreDescription(url: url)
        container.persistentStoreDescriptions = [description]
        var error: Swift.Error?
        container.loadPersistentStores { error = $1 }
        try error.map {
            throw LoadingError.loadPersistentStoresFail($0)
        }
        return container
    }
}

private extension NSManagedObjectModel {
    static func with(modelName: String, in bundle: Bundle) -> NSManagedObjectModel? {
        return bundle.url(forResource: modelName, withExtension: "momd").flatMap { NSManagedObjectModel(contentsOf: $0) }
    }
}
