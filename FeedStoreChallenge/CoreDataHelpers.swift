//
//  CoreDataHelpers.swift
//  FeedStoreChallenge
//
//  Created by Araceli Ruiz Ruiz on 23/05/2020.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import CoreData

extension NSPersistentContainer {
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

extension NSManagedObjectModel {
    static func with(modelName: String, in bundle: Bundle) -> NSManagedObjectModel? {
        return bundle.url(forResource: modelName, withExtension: "momd").flatMap { NSManagedObjectModel(contentsOf: $0) }
    }
}
