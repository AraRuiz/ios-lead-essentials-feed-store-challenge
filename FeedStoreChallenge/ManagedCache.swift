//
//  ManagedCache.swift
//  FeedStoreChallenge
//
//  Created by Araceli Ruiz Ruiz on 23/05/2020.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import CoreData

@objc(ManagedCache)
class ManagedCache: NSManagedObject {
    @NSManaged public var timestamp: Date
    @NSManaged public var feed: NSOrderedSet
    
    static func get(from context: NSManagedObjectContext) throws -> ManagedCache? {
        let request = NSFetchRequest<ManagedCache>(entityName: "ManagedCache")
        return try context.fetch(request).first
    }
    
    static func uniqueManagedCache(in context: NSManagedObjectContext) throws -> ManagedCache {
        try get(from: context).map(context.delete)
        return ManagedCache(context: context)
    }
    
    var localFeed: [LocalFeedImage] {
        return feed.compactMap { ($0 as? ManagedFeedImage)?.localFeedImage }
    }
}
