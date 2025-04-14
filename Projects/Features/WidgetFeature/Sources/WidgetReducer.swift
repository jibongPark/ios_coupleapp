import Foundation
import ComposableArchitecture

import Domain

@Reducer
struct WidgetReducer {
    
    @Dependency(\.widgetRepository) var widgetRepository
    
    init() { }
    
    @ObservableState
    struct State: Equatable {
        var widgetData: [WidgetVO] = []
        var selectedWidget: Set<Int> = []
        var isEditing: Bool = false
        
        @Presents var destination: Destination.State?
    }
    
    enum Action {
        case onAppear
        case didLoadWidgetData([WidgetVO])
        case didTapAddDDayButton
        case didTapWidgetData(WidgetVO)
        case didLongPressWidgetData
        case didCancelEditing
        case didCommitEditing
        case destination(PresentationAction<Destination.Action>)
    }
    
    static let reducer = Self()
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            case .onAppear:
                
                return widgetRepository.fetchWidgetTCA()
                    .map { @Sendable widgets in
                        Action.didLoadWidgetData(widgets)
                    }
                
            case .didLoadWidgetData(let widgetData):
                state.widgetData = widgetData
                return .none
                
            case .didTapWidgetData(let widgetData):
                
                if(state.isEditing) {
                    if !state.selectedWidget.contains(widgetData.id) {
                        state.selectedWidget.insert(widgetData.id)
                    } else {
                        state.selectedWidget.remove(widgetData.id)
                    }
                    
                } else {
                    state.destination = .addDdayView(
                        AddDDayReducer.State(vo: widgetData)
                    )
                }
                return .none
                
            case .didLongPressWidgetData:
                if !state.isEditing {
                    state.isEditing = true
                }
                return .none
                
            case .didCancelEditing:
                state.isEditing = false
                return .none
                
            case .didCommitEditing:
                
                var removedData: [WidgetVO] = []
                
                for widget in state.widgetData {
                    if state.selectedWidget.contains(widget.id) {
                        removedData.append(widget)
                        Task {
                            await widgetRepository.removeWidget(widget)
                        }
                    }
                }
                
                state.widgetData.removeAll() {
                    removedData.contains($0)
                }
                
                state.isEditing = false
                return .none
                
            case .didTapAddDDayButton:
                state.destination = .addDdayView(
                    AddDDayReducer.State()
                )
                return .none
                

            case .destination:
                return .none
            
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension WidgetReducer {
    @Reducer
    enum Destination {
        case addDdayView(AddDDayReducer)
    }
}

extension WidgetReducer.Destination.State: Equatable {}
