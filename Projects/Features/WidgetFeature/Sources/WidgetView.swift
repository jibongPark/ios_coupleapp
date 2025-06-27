import SwiftUI
@preconcurrency import Domain
import Core
import ComposableArchitecture
import WidgetFeatureInterface

struct WidgetView: View {
    @Bindable var store: StoreOf<WidgetReducer>
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(spacing: 0), count: 2), alignment: .center, spacing: 0) {
                        ForEach(store.widgetData) { widgetItem in
                            ZStack {
                                WidgetPreview(vo: widgetItem, width: geometry.size.width / 2, height: geometry.size.width / 2)
//                                WidgetItemView(widgetItem: widgetItem)
                                    .padding(10)
                                    .frame(width: geometry.size.width / 2, height: geometry.size.width / 2)
                                    .onTapGesture() {
                                        store.send(.didTapWidgetData(widgetItem))
                                    }
                                    .onLongPressGesture() {
                                        store.send(.didLongPressWidgetData)
                                    }
                                
                                if(store.isEditing) {
                                    Image(systemName: store.selectedWidget.contains(widgetItem.id) ? "checkmark.circle" : "circle")
                                        .padding(20)
                                        .foregroundStyle(.blue)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                }
                            }
                            .setBackgroundColor()
                        }
                    }
                }
                
                
                Button(action: {
                    store.send(.didTapAddDDayButton)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                }
                .padding(.trailing, 10)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                
                
            }
//            .navigationTitle("디데이")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if store.isEditing {
                        Button("취소") {
                            store.send(.didCancelEditing)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if store.isEditing {
                        Button("삭제") {
                            store.send(.didCommitEditing)
                        }
                    }
                }
            }
        }
        .setBackgroundColor()
        .fullScreenCover(item: $store.scope(state: \.destination?.addDdayView, action: \.destination.addDdayView)) { store in
            AddDDayView(store: store)
        }
        .onAppear() {
            store.send(.onAppear)
        }
    }
}

struct WidgetItemView: View {
    let widgetItem: WidgetVO
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let image = ImageLib.loadImageFromGroup(withFileName: widgetItem.imagePath, groupName: "group.com.bongbong.coupleapp") {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
                
                VStack(alignment: .leading) {
                    Text(widgetItem.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .shadow(color: .black, radius: 2)
                    
                    Text(widgetItem.startDate.formattedDateString)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .shadow(color: .black, radius: 2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: widgetItem.titleAlignment.toTextAlignment())
            }
            .background(.white)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(.gray)
            )
        }
    }
}


public struct WidgetFeature: WidgetInterface {
    
    private let store: StoreOf<WidgetReducer>
    
    public init() {
        store = .init(initialState: WidgetReducer.State()) {
            WidgetReducer()
        }
    }
    
    public func makeView() -> any View {
        AnyView(
            WidgetView(store: self.store)
        )
    }
    
    public func widgetTextView(vo: WidgetVO) -> any View {
        AnyView(
            WidgetTextView(vo: vo)
        )
    }
}

private enum WidgetFeatureKey: DependencyKey {
    static var liveValue: WidgetInterface = WidgetFeature()
}

public extension DependencyValues {
    var widgetFeature: WidgetInterface {
        get { self[WidgetFeatureKey.self] }
        set { self[WidgetFeatureKey.self] = newValue }
    }
}
