import Foundation
import Domain
import MapKit
import ComposableArchitecture
import RealmKit
import RealmSwift


public struct MapRepositoryImpl: MapRepository {
    
    @Dependency(\.realmKit) var realmKit
    
    public init() {}
    
    public func fetchPolygons() -> Effect<PolygonVO> {
        return Effect.run { send in
            guard let url = Bundle.main.url(forResource: "sigungu", withExtension: "geojson"),
                  let data = try? Data(contentsOf: url) else {
                return
            }
            do {
                let objects = try MKGeoJSONDecoder().decode(data)
                var polygons: [PolygonData] = []
                var boundingRect = MKMapRect.null
                
                for object in objects {
                    if let feature = object as? MKGeoJSONFeature,
                       let propertiesData = feature.properties,
                       let jsonObject = try? JSONSerialization.jsonObject(with: propertiesData, options: []),
                       let properties = jsonObject as? [String: Any] {
                        let name = properties["SIGUNGU_NM"] as? String ?? ""
                        let codeString = properties["SIGUNGU_CD"] as? String ?? "-1"
                        let sigunguCode = Int(codeString) ?? -1
                        for geometry in feature.geometry {
                            if let multiPolygon = geometry as? MKMultiPolygon {
                                let polygonData = PolygonData(sigunguCode: sigunguCode, name: name, polygon: multiPolygon)
                                polygons.append(polygonData)
                                boundingRect = boundingRect.union(multiPolygon.boundingMapRect)
                            }
                        }
                    }
                }
                
                await send(PolygonVO(polygons: polygons, boundingRect: boundingRect))
            } catch {
            }
        }
    }
    
    public func fetchTrips() -> ComposableArchitecture.Effect<[Int : Domain.TripVO]> {
        .run { send in
            let config = Realm.Configuration(
                schemaVersion: 2, // Increase this number from the previous version
                migrationBlock: { migration, oldSchemaVersion in
                    if oldSchemaVersion < 2 {
                        migration.enumerateObjects(ofType: TripDTO.className()) { oldObject, newObject in
                            // Set default values for the new properties
                            newObject?["scale"] = 1.0     // or another default value
                            newObject?["centerX"] = 0.0   // default value (adjust as needed)
                            newObject?["centerY"] = 0.0   // default value
                        }
                    }
                }
            )
            Realm.Configuration.defaultConfiguration = config
            
            let tripDatas = realmKit.fetchAllData(type: TripDTO.self)
            let tripDic = Dictionary(uniqueKeysWithValues:tripDatas.map { ($0.sigunguCode, $0.toVO()) })
            await send(tripDic)
        }
    }
    
    public func updateTrip(_ trip: TripVO) {
        realmKit.addData(TripDTO(from: trip))
    }
}

private enum MapRepositoryKey: DependencyKey {
    static var liveValue: MapRepository = MapRepositoryImpl()
}

public extension DependencyValues {
    var mapRepository: MapRepository {
        get { self[MapRepositoryKey.self] }
        set { self[MapRepositoryKey.self] = newValue }
    }
}
