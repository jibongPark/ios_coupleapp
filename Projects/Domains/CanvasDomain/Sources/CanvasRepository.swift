import ComposableArchitecture
import Core

public protocol CanvasRepository {
    func fetchCanvas(sharedSpaceId: String) -> Effect<DataResult<SharedCanvasVO>>
    func fetchStrokes(sharedSpaceId: String, afterSequence: Int?) -> Effect<DataResult<[CanvasStrokeVO]>>
    func appendStroke(_ stroke: CanvasStrokeVO) -> Effect<DataResult<CanvasStrokeVO>>
    func clearCanvas(sharedSpaceId: String) -> Effect<DataResult<SharedCanvasVO>>
    func updateSnapshot(_ snapshot: CanvasSnapshotVO) -> Effect<DataResult<CanvasSnapshotVO>>
}
