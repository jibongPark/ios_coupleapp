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
        @Presents var addTrip: AddTripReducer.State?
        
        public var mapData: PolygonVO? = nil
        public var tripData: [Int: TripVO] = [:]
    }
    
    public enum Action {
        case onApear
        case mapDataLoaded(PolygonVO)
        case tripDataLoaded([Int: TripVO])
        case mapTapped(PolygonData)
        case addTrip(PresentationAction<AddTripReducer.Action>)
    }
    
    public static let reducer = Self()
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onApear:

                return .merge(
                    mapRepository.fetchTrips()
                        .map { @Sendable trip in
                            Action.tripDataLoaded(trip)
                        },
                    mapRepository.fetchPolygons()
                        .map { @Sendable polygonVO in
                            Action.mapDataLoaded(polygonVO)
                        }
                )
                
            case .mapDataLoaded(let data):
                state.mapData = data
                return .none
                
            case .tripDataLoaded(let data):
                state.tripData = data
                return .none
                
            case .mapTapped(let polygon):
                if let tripData = state.tripData[polygon.sigunguCode] {
                    state.addTrip = AddTripReducer.State(polygon: polygon, tripVO: tripData)
                } else {
                    state.addTrip = AddTripReducer.State(polygon: polygon)
                }
                return .none
                
            case .addTrip(.presented(.delegate(.saveTrip(let tripVO)))):
                state.tripData.updateValue(tripVO, forKey: tripVO.sigunguCode)
                return .none
            case .addTrip:
                return .none
            }
        }
        .ifLet(\.$addTrip, action: \.addTrip) {
            AddTripReducer()
        }
        
    }
}
