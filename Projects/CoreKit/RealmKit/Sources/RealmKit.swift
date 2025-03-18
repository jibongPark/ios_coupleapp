//
//  RealmKit.swift
//  MapData
//
//  Created by 박지봉 on 3/15/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Dependencies
import RealmSwift


public class RealmKit {
    
    var realm: Realm {
        return try! Realm()
    }
    
    public func fetchAllData<T: Object>(type: T.Type) -> Results<T> {
        return realm.objects(type)
    }
    
    public func addData<T: Object>(_ object: T) {
        try! realm.write {
            realm.add(object, update: .modified)
        }
    }
}

private enum RealmKitKey: DependencyKey {
    static var liveValue: RealmKit = RealmKit()
}

public extension DependencyValues {
    var realmKit: RealmKit {
        get { self[RealmKitKey.self] }
        set { self[RealmKitKey.self] = newValue }
    }
}
