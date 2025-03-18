import SwiftUI
@preconcurrency import Domain
import MapKit
import Core
import ComposableArchitecture

struct ContentView: View {
    @Bindable var store: StoreOf<MapReducer>
    
    let viewScale: CGFloat = 3

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            
            GeometryReader { geometry in
                if viewStore.mapData != nil {
                    let polygons = viewStore.mapData!.polygons
                    let boundingRect = viewStore.mapData!.boundingRect
                    let tripData = viewStore.tripData
                    
                    ZoomableScrollView {
                        ZStack {
                            ForEach(0..<polygons.count, id: \.self) { index in
                                
                                let polygon = polygons[index]
                                    
                                PolygonItemView(polygon: polygon,
                                                boundingRect: boundingRect,
                                                tripVO: tripData[polygon.sigunguCode],
                                                viewScale: viewScale,
                                                geometrySize: geometry.size)
                                .onTapGesture {
                                    store.send(.mapTapped(polygon))
                                }
                            }
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    Text("Loading GeoJSON...")
                        .onAppear { viewStore.send(.onApear) }
                }
            }
        }
        .sheet(
            item: $store.scope(state: \.addTrip, action: \.addTrip)
        ) { addTripStore in
            NavigationStack {
                AddTripView(store: addTripStore)
            }
        }
    }
}

struct PolygonItemView: View {
    let polygon: PolygonData
    let boundingRect: MKMapRect
    let tripVO: TripVO?
    let viewScale: CGFloat
    let geometrySize: CGSize
    
    var body: some View {
        let shape = MultiPolygonShape(multiPolygon: polygon, boundingRect: boundingRect)
        let frame = CGRect(
            origin: .zero,
            size: CGSize(width: geometrySize.width * viewScale, height: geometrySize.height * viewScale)
            )
        
        let tripScale = CGFloat(tripVO?.scale ?? 1.0)
        
        return ZStack {
            
            let shapeRect = shape.path(in: frame).boundingRect

            shape.stroke(.gray, lineWidth: 0.5)
                .frame(width: frame.size.width, height: frame.size.height)
            
            let tripCenter: CGPoint = tripVO?.center ?? .zero
            
            let center = CGPoint(x: shapeRect.minX + tripCenter.x * shapeRect.width/2,
                                 y: shapeRect.minY + tripCenter.y * shapeRect.height/2)
            
            if let data = tripVO?.imageAtIndex(0),
               let image = UIImage(data:data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: shapeRect.width, height: shapeRect.height)
                    .scaleEffect(tripScale)
                    .position(center)
                    .clipShape(shape)
                    .contentShape(shape)
            }
            
//            Text(polygon.name)
//                .position(CGPoint(x: shapeRect.midX, y: shapeRect.midY))
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
        let scale = (rect.width / boundingRect.size.width)
        let x = (mapPoint.x - boundingRect.origin.x) * scale
        let y = (mapPoint.y - boundingRect.origin.y) * scale
        return CGPoint(x: x, y: y)
    }
    
    func center(_ rect: CGRect) -> CGPoint {
        
        var x: Double = 0, y: Double = 0
        var allCount = 0
        
        
        for polygon in multiPolygon.polygon.polygons {
            let count = polygon.pointCount
            guard count > 0 else { continue }
            let points = polygon.points()
            
            allCount += count
            
            for i in 0..<count {
                let point = convert(mapPoint: points[i], in: boundingRect, rect: rect)
                
                x += point.x
                y += point.y
            }
        }
        return CGPoint(x: Int(x/Double(allCount)), y: Int(y/Double(allCount)))
    }
}

//struct ContentView_Preview: PreviewProvider {
//    static var previews: some View {
//        ContentView(
//            store: .init(initialState: MapReducer.State()) {
//                MapReducer()
//            }
//        )
//    }
//}
