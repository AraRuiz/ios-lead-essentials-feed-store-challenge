//
//  ManagedFeedImage.swift
//  FeedStoreChallenge
//
//  Created by Araceli Ruiz Ruiz on 23/05/2020.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import CoreData

@objc(ManagedFeedImage)
class ManagedFeedImage: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var imageDescription: String?
    @NSManaged public var location: String?
    @NSManaged public var url: URL
    @NSManaged public var cache: ManagedCache
}
