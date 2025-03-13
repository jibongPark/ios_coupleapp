import Foundation
import ComposableArchitecture

import Domain
import Dependencies
import MapData

@Reducer
public struct MapReducer {
    @Dependency(\.mapRepository) var mapRepository
    
    public init() { }
    
    @ObservableState
    public struct State: Equatable {
        public init() { }
        
        public var mapData: PolygonVO? = nil
        public var tripData: [Int: TripVO] = [:]
    }
    
    public enum Action {
        case onApear
        case mapDataLoaded(PolygonVO)
    }
    
    public static let reducer = Self()
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onApear:
                return mapRepository.fetchPolygons()
                    .map { @Sendable polygonVO in
                        Action.mapDataLoaded(polygonVO)
                    }
            case .mapDataLoaded(let data):
                state.mapData = data
                return .none
            }
        }
    }
    
}
