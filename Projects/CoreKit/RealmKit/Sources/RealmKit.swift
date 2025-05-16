//
//  RealmKit.swift
//  MapData
//
//  Created by 박지봉 on 3/15/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import ComposableArchitecture
import RealmSwift


public class RealmKit {
    
    var realm: Realm {
        return try! Realm()
    }
    
    public func fetchAllData<T: Object>(type: T.Type) -> Results<T> {
        return realm.objects(type)
    }
    
    public func fetchData<T: Object>(type: T.Type, forKey key: String) -> T? {
        return realm.object(ofType: type, forPrimaryKey: key)
    }
    
    public func addData<T: Object>(_ object: T) {
        try! realm.write {
            realm.add(object, update: .modified)
        }
    }
    
    public func addDatas<T: Object>(_ objects: [T]) {
        try! realm.write {
            for object in objects {
                realm.add(object, update: .modified)
            }
        }
    }
    
    public func deleteData<T: Object>(_ type: T.Type, withId key: String) {
        if let data = realm.object(ofType: type, forPrimaryKey: key) {
            try! realm.write {
                realm.delete(data)
            }
        }
    }
}

public class TestRealmKit: RealmKit {
    override var realm: Realm {
        return try! Realm(configuration: .init(inMemoryIdentifier: "TestRealmKit"))
    }
}

private enum RealmKitKey: DependencyKey {
    static var liveValue: RealmKit = RealmKit()
    static var testValue: RealmKit = TestRealmKit()
}

public extension DependencyValues {
    var realmKit: RealmKit {
        get { self[RealmKitKey.self] }
        set { self[RealmKitKey.self] = newValue }
    }
}
