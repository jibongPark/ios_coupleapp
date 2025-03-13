import Foundation
import Domain
import MapKit
import ComposableArchitecture


public struct MapRepositoryImpl: MapRepository {
    
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
                        let sigunguCode = properties["SIGUNGU_CD"] as? Int ?? -1
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
    
    public func fetchTrips(polygons: [Domain.PolygonData]) -> ComposableArchitecture.Effect<[Int : Domain.TripVO]> {
        .run { send in
            
        }
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
