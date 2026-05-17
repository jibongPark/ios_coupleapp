import Foundation
import ComposableArchitecture
import CanvasData
import CanvasDomain
import Core

@Reducer
public struct CanvasReducer {
    @Dependency(\.canvasRepository) var canvasRepository

    public init() {}

    @ObservableState
    public struct State: Equatable {
        public var activeSharedSpaceId: String?
        public var canvas: SharedCanvasVO?
        public var strokes: [CanvasStrokeVO] = []
        public var currentStroke: CanvasStrokeVO?
        public var selectedTool: CanvasTool = .pen
        public var selectedColorHex: String = "#3D2C2E"
        public var lineWidth: Double = 6
        public var errorMessage: String?
        public var snapshotUpdater = ThrottledSnapshotUpdater(minimumInterval: 2)

        public init(activeSharedSpaceId: String? = ConfigManager.shared.get("activeSharedSpaceId")) {
            self.activeSharedSpaceId = activeSharedSpaceId
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case startStroke(CanvasPointVO)
        case appendPoint(CanvasPointVO)
        case endStroke
        case clearTapped
        case didLoadCanvas(SharedCanvasVO)
        case didLoadStrokes([CanvasStrokeVO])
        case didAppendStroke(CanvasStrokeVO)
        case didUpdateSnapshot(CanvasSnapshotVO)
        case setTool(CanvasTool)
        case setColor(String)
        case setLineWidth(Double)
        case showError(String)
    }

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .onAppear:
                guard let sharedSpaceId = state.activeSharedSpaceId?.trimmingCharacters(in: .whitespacesAndNewlines), !sharedSpaceId.isEmpty else {
                    state.errorMessage = "페어링 후 우리 낙서장을 사용할 수 있어요."
                    return .none
                }
                return .merge(
                    canvasRepository.fetchCanvas(sharedSpaceId: sharedSpaceId).map { @Sendable result in
                        result.isSuccess ? .didLoadCanvas(result.data!) : .showError(result.message)
                    },
                    canvasRepository.fetchStrokes(sharedSpaceId: sharedSpaceId, afterSequence: nil).map { @Sendable result in
                        result.isSuccess ? .didLoadStrokes(result.data ?? []) : .showError(result.message)
                    }
                )
            case .didLoadCanvas(let canvas):
                state.canvas = canvas
                state.errorMessage = nil
                return .none
            case .didLoadStrokes(let strokes):
                state.strokes = strokes
                return .none
            case .startStroke(let point):
                guard let sharedSpaceId = state.activeSharedSpaceId, let canvasId = state.canvas?.id else { return .send(.showError("페어링 후 우리 낙서장을 사용할 수 있어요.")) }
                let sequence = (state.strokes.map(\.sequence).max() ?? 0) + 1
                state.currentStroke = CanvasStrokeVO(
                    id: UUID().uuidString,
                    canvasId: canvasId,
                    sharedSpaceId: sharedSpaceId,
                    authorId: "local",
                    sequence: sequence,
                    tool: state.selectedTool,
                    colorHex: state.selectedColorHex,
                    lineWidth: state.lineWidth,
                    points: [point]
                )
                return .none
            case .appendPoint(let point):
                guard let current = state.currentStroke else { return .none }
                state.currentStroke = CanvasStrokeVO(
                    id: current.id,
                    canvasId: current.canvasId,
                    sharedSpaceId: current.sharedSpaceId,
                    authorId: current.authorId,
                    sequence: current.sequence,
                    tool: current.tool,
                    colorHex: current.colorHex,
                    lineWidth: current.lineWidth,
                    points: current.points + [point]
                )
                return .none
            case .endStroke:
                guard let stroke = state.currentStroke else { return .none }
                state.currentStroke = nil
                state.strokes.append(stroke)
                return canvasRepository.appendStroke(stroke).map { @Sendable result in
                    result.isSuccess ? .didAppendStroke(result.data!) : .showError(result.message)
                }
            case .didAppendStroke:
                return .none
            case .clearTapped:
                guard let sharedSpaceId = state.activeSharedSpaceId else { return .none }
                state.strokes = []
                return canvasRepository.clearCanvas(sharedSpaceId: sharedSpaceId).map { @Sendable result in
                    result.isSuccess ? .didLoadCanvas(result.data!) : .showError(result.message)
                }
            case .didUpdateSnapshot:
                return .none
            case .setTool(let tool):
                state.selectedTool = tool
                return .none
            case .setColor(let color):
                state.selectedColorHex = color
                return .none
            case .setLineWidth(let width):
                state.lineWidth = width
                return .none
            case .showError(let message):
                state.errorMessage = message
                return .none
            }
        }
    }
}
