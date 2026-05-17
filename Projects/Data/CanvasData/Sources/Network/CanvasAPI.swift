import Foundation
import Moya
import Core
import CanvasDomain

enum CanvasAPI {
    case canvas(sharedSpaceId: String)
    case appendStroke(sharedSpaceId: String, stroke: CanvasStrokeVO)
    case strokes(sharedSpaceId: String, afterSequence: Int?)
    case clear(sharedSpaceId: String)
    case updateSnapshot(sharedSpaceId: String, snapshot: CanvasSnapshotVO)
    case snapshot(sharedSpaceId: String)
}

extension CanvasAPI: TargetType {
    var baseURL: URL { ConfigManager.shared.apiBaseURL ?? ConfigManager.fallbackBaseURL }

    var path: String {
        switch self {
        case .canvas(let sharedSpaceId):
            return "/shared-spaces/\(sharedSpaceId)/canvas"
        case .appendStroke(let sharedSpaceId, _):
            return "/shared-spaces/\(sharedSpaceId)/canvas/strokes"
        case .strokes(let sharedSpaceId, _):
            return "/shared-spaces/\(sharedSpaceId)/canvas/strokes"
        case .clear(let sharedSpaceId):
            return "/shared-spaces/\(sharedSpaceId)/canvas/clear"
        case .updateSnapshot(let sharedSpaceId, _), .snapshot(let sharedSpaceId):
            return "/shared-spaces/\(sharedSpaceId)/canvas/snapshot"
        }
    }

    var method: Moya.Method {
        switch self {
        case .canvas, .strokes, .snapshot: return .get
        case .appendStroke, .clear, .updateSnapshot: return .post
        }
    }

    var task: Task {
        switch self {
        case .strokes(_, let afterSequence):
            guard let afterSequence else { return .requestPlain }
            return .requestParameters(parameters: ["afterSequence": afterSequence], encoding: URLEncoding.queryString)
        case .appendStroke(_, let stroke):
            return .requestJSONEncodable(CanvasStrokeDTO(stroke))
        case .updateSnapshot(_, let snapshot):
            return .requestJSONEncodable(CanvasSnapshotDTO(snapshot))
        default:
            return .requestPlain
        }
    }

    var headers: [String : String]? { ["Content-Type": "application/json"] }
}
