import SwiftUI
@preconcurrency import Domain
import MapKit
import Core
import ComposableArchitecture

struct ContentView: View {
    let store: StoreOf<MapReducer>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            
            GeometryReader { geometry in
                if viewStore.mapData != nil {
                    let polygons = viewStore.mapData!.polygons
                    let boundingRect = viewStore.mapData!.boundingRect
                    
                    ZoomableScrollView {
                        ZStack {
                            ForEach(0..<polygons.count, id: \.self) { index in
                                let shape = MultiPolygonShape(multiPolygon: polygons[index], boundingRect: boundingRect)
                                
                                shape.fill(.white)
                                    .overlay(shape
                                        .stroke(.gray, lineWidth: 0.15))
                                    .onTapGesture {
                                        let _ = print(polygons[index].name)
                                    }
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                } else {
                    Text("Loading GeoJSON...")
                        .onAppear { viewStore.send(.onApear) }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct MultiPolygonShape: Shape {
    let multiPolygon: PolygonData
    let boundingRect: MKMapRect

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        for polygon in multiPolygon.polygon.polygons {
            let count = polygon.pointCount
            guard count > 0 else { continue }
            let points = polygon.points()
            let first = convert(mapPoint: points[0], in: boundingRect, rect: rect)
            path.move(to: first)
            for i in 1..<count {
                let point = convert(mapPoint: points[i], in: boundingRect, rect: rect)
                path.addLine(to: point)
            }
            path.closeSubpath()
        }
        return path
    }
    
    private func convert(mapPoint: MKMapPoint, in boundingRect: MKMapRect, rect: CGRect) -> CGPoint {
        let scale = rect.width / boundingRect.size.width
        let x = (mapPoint.x - boundingRect.origin.x) * scale
        let y = (mapPoint.y - boundingRect.origin.y) * scale
        return CGPoint(x: x, y: y)
    }
}

struct ContentView_Preview: PreviewProvider {
    static var previews: some View {
        ContentView(
            store: .init(initialState: MapReducer.State()) {
                MapReducer()
            }
        )
    }
}
