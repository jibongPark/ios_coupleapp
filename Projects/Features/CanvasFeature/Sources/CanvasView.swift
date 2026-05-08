import SwiftUI
import ComposableArchitecture
import CanvasDomain
import CanvasFeatureInterface
import Core

public struct CanvasView: View {
    @Bindable var store: StoreOf<CanvasReducer>

    public init(store: StoreOf<CanvasReducer>) { self.store = store }

    public var body: some View {
        VStack(spacing: 12) {
            if let message = store.errorMessage, store.activeSharedSpaceId == nil {
                ContentUnavailableView("우리 낙서장", systemImage: "heart.text.square", description: Text(message))
            } else {
                DrawingSurface(strokes: store.strokes, currentStroke: store.currentStroke)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let point = CanvasPointVO(x: value.location.x / max(value.startLocation.x + abs(value.translation.width), 1), y: value.location.y / max(value.startLocation.y + abs(value.translation.height), 1), t: Date().timeIntervalSince1970, pressure: nil)
                                if store.currentStroke == nil { store.send(.startStroke(point)) } else { store.send(.appendPoint(point)) }
                            }
                            .onEnded { _ in store.send(.endStroke) }
                    )
                    .background(Color.mbBackgroundBeige)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding()

                HStack {
                    Button("펜") { store.send(.setTool(.pen)) }
                    Button("지우개") { store.send(.setTool(.eraser)) }
                    ColorPicker("색", selection: Binding(get: { Color(hex: store.selectedColorHex) }, set: { store.send(.setColor($0.hexString)) }))
                    Slider(value: $store.lineWidth.sending(\.setLineWidth), in: 2...24)
                    Button("전체 지우기") { store.send(.clearTapped) }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("우리 낙서장")
        .onAppear { store.send(.onAppear) }
    }
}

private struct DrawingSurface: View {
    let strokes: [CanvasStrokeVO]
    let currentStroke: CanvasStrokeVO?

    var body: some View {
        Canvas { context, size in
            for stroke in (strokes + [currentStroke].compactMap { $0 }).sorted(by: { $0.sequence < $1.sequence }) {
                var path = Path()
                guard let first = stroke.points.first else { continue }
                path.move(to: CGPoint(x: first.x * size.width, y: first.y * size.height))
                for point in stroke.points.dropFirst() {
                    path.addLine(to: CGPoint(x: point.x * size.width, y: point.y * size.height))
                }
                context.stroke(path, with: .color(stroke.tool == .eraser ? .mbBackgroundBeige : Color(hex: stroke.colorHex)), style: StrokeStyle(lineWidth: stroke.lineWidth, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(minHeight: 420)
    }
}

public struct CanvasFeature: CanvasInterface {
    private let store: StoreOf<CanvasReducer>

    public init() {
        self.store = Store(initialState: CanvasReducer.State()) { CanvasReducer() }
    }

    public func makeView() -> any View { AnyView(CanvasView(store: store)) }
}

enum CanvasFeatureKey: DependencyKey {
    static var liveValue: CanvasInterface = CanvasFeature()
}

public extension DependencyValues {
    var canvasFeature: CanvasInterface {
        get { self[CanvasFeatureKey.self] }
        set { self[CanvasFeatureKey.self] = newValue }
    }
}

private extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xff) / 255
        let g = Double((int >> 8) & 0xff) / 255
        let b = Double(int & 0xff) / 255
        self.init(red: r, green: g, blue: b)
    }

    var hexString: String { "#3D2C2E" }
}
