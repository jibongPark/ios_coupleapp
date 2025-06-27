//
//  AddDDayView.swift
//  WidgetFeature
//
//  Created by 박지봉 on 4/11/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import Domain
import Core


struct AddDDayView: View {
    
    @Bindable var store: StoreOf<AddDDayReducer>
    
    @State var subHeight: CGFloat = .zero
    
    init(store: StoreOf<AddDDayReducer>) {
        self.store = store
    }
    
    let scale: CGFloat = 0.3
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    ZStack {
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .center, spacing: 20) {
                                WidgetPreview(store: store,
                                              width: 155,
                                              height: 155)
                                .frame(width: 155, height: 155)
                                
                                WidgetPreview(store: store,
                                              width: 329,
                                              height: 155)
                                .frame(width: 329, height: 155)
                                
                            }
                            .frame(maxHeight: .infinity, alignment: .center)
                        }
                        .padding(.bottom, 20)
                        
                        
                        Button(action: {
                            store.send(.addPhotoButtonTapped)
                        }) {
                            Image(systemName: "photo.artframe.circle.fill")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 10)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                    
                    
                    
                    VStack {
                        
                        TextField("", text: $store.title)
                            .font(.title2.bold())
                            .foregroundStyle(.gray)
                            .overlay(alignment: .topLeading) {
                                if store.title.isEmpty {
                                    Text("디데이 제목을 입력하세요.")
                                        .font(.title2.bold())
                                        .foregroundStyle(Color.mbTextLightGray)
                                        .allowsHitTesting(false)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        
                        
                        Divider()
                            .background(.gray)
                        
                        HStack(spacing: 0) {
                            
                            Text("처음 만난 날")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .setInputColor()
                            
                            Button(action: {
                                store.send(.dateChangeButtonTapped)
                            }) {
                                HStack {
                                    Text(store.startDate.formattedDateString)
                                        .frame(alignment: .trailing)
//                                        .setInputColor()
                                    
                                    Image(systemName: store.destination != nil ? "chevron.up" : "chevron.down")
//                                        .setInputColor()
                                    
                                    
                                }
                            }
                            .setInputColor()
                            .frame(maxWidth: .infinity)
                        }
                        .padding(5)
                        
                        Divider()
                            .background(.gray)
                        
                        Toggle("디데이 표시", isOn: $store.isShowDate)
                            .setInputColor()
                        
                        if store.isShowDate {
                            AlignmentView(alignment: store.dateAlignment) { alignment in
                                store.send(.didTapDateAlignment(alignment))
                            }
                        }
                        
                        Toggle("제목 표시", isOn: $store.isShowTitle)
                            .setInputColor()
                        
                        if store.isShowTitle {
                            AlignmentView(alignment: store.titleAlignment) { alignment in
                                store.send(.didTapTitleAlignment(alignment))
                            }
                        }
                        
                        Spacer()
                        
                    }
                    .ignoresSafeArea(.all, edges:.top)
                    .padding(10)
                    .frame(height: geometry.size.height * (1-scale), alignment: .top)
                    .setBackgroundColor()
                }
                .setBackgroundColor()
            }
            .toolbar {
                Group {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: {
                            store.send(.cancelButtonTapped)
                        }) {
                            Image(systemName: "xmark")
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("저장") {
                            store.send(.saveButtonTapped)
                        }
                    }
                }
            }
        }
        .sheet(item: $store.scope(state: \.destination?.photoPicker, action: \.destination.photoPicker)) { store in
            ImagePickerView(store: store)
        }
        
        .resizingSheet(item: $store.scope(state: \.destination?.datePicker, action: \.destination.datePicker)) { store in
            DatePickerView(store: store)
        }
    }

}

struct WidgetPreview: View {
    
    init(store: StoreOf<AddDDayReducer>, width: CGFloat, height: CGFloat) {
        title = store.title
        startDate = store.startDate
        image = store.image
        imagePath = store.imagePath
        isShowDate = store.isShowDate
        dateAlignment = store.dateAlignment
        isShowTitle = store.isShowTitle
        titleAlignment = store.titleAlignment
        self.width = width
        self.height = height
    }
    
    init(vo: WidgetVO, width: CGFloat, height: CGFloat) {
        title = vo.title
        startDate = vo.startDate
        image = nil
        imagePath = vo.imagePath
        isShowDate = vo.isShowDate
        dateAlignment = vo.dateAlignment.toTextAlignment()
        isShowTitle = vo.isShowTitle
        titleAlignment = vo.titleAlignment.toTextAlignment()
        self.width = width
        self.height = height
    }
    
    let title: String
    let startDate: Date
    let image: UIImage?
    let imagePath: String
    let isShowDate: Bool
    let dateAlignment: Alignment
    let isShowTitle: Bool
    let titleAlignment: Alignment

    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                
                if let image = image ?? ImageLib.loadImageFromGroup(withFileName: imagePath, groupName: "group.com.bongbong.coupleapp") {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: height)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .overlay() {
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(.gray)
                        }
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(.gray)
                        .frame(width: width, height: height)
                }
                
                WidgetTextView(title: title, startDate: startDate, isShowDate: isShowDate, dateAlignment: dateAlignment, isShowTitle: isShowTitle, titleAlignment: titleAlignment)
                
//                if titleAlignment == dateAlignment {
//                    VStack {
//                        if isShowDate {
//                            Text(startDate.dDayString)
//                                .font(.title)
//                                .foregroundColor(.white)
//                                .shadow(radius: 2)
//                        }
//                        
//                        if isShowTitle {
//                            WidgetTitleView(title: title, subTitle: startDate.formattedDateString)
//                        }
//                    }
//                    .padding(10)
//                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: titleAlignment)
//                } else {
//                    
//                    if isShowDate {
//                        Text(startDate.dDayString)
//                            .font(.title)
//                            .foregroundColor(.white)
//                            .shadow(radius: 2)
//                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: dateAlignment)
//                    }
//                    
//                    if isShowTitle {
//                        WidgetTitleView(title: title, subTitle: startDate.formattedDateString)
//                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: titleAlignment)
//                    }
//                }
            }
        }
    }
}

struct WidgetTitleView: View {
    let title: String
    let subTitle: String
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .shadow(color: .black, radius: 2)
            
            Text(subTitle)
                .font(.caption)
                .foregroundStyle(.white)
                .shadow(color: .black, radius: 2)
        }
    }
}

public struct WidgetTextView: View {
    
    init(vo: WidgetVO, isWidget: Bool = false) {
        title = vo.title
        startDate = vo.startDate
        isShowDate = vo.isShowDate
        dateAlignment = vo.dateAlignment.toTextAlignment()
        isShowTitle = vo.isShowTitle
        titleAlignment = vo.titleAlignment.toTextAlignment()
    }
    
    init(title: String, startDate: Date, isShowDate: Bool, dateAlignment: Alignment, isShowTitle: Bool, titleAlignment: Alignment) {
        self.title = title
        self.startDate = startDate
        self.isShowDate = isShowDate
        self.dateAlignment = dateAlignment
        self.isShowTitle = isShowTitle
        self.titleAlignment = titleAlignment
    }
    
    let title: String
    let startDate: Date
    let isShowDate: Bool
    let dateAlignment: Alignment
    let isShowTitle: Bool
    let titleAlignment: Alignment
    
    
    public var body: some View {
        
        let padding: CGFloat = 10
        
        if titleAlignment == dateAlignment {
            VStack {
                if isShowDate {
                    Text(startDate.dDayString)
                        .font(.title)
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 2)
                        .frame(maxWidth: .infinity, alignment: dateAlignment)
                }
                
                if isShowTitle {
                    WidgetTitleView(title: title, subTitle: startDate.formattedDateString)
                        .frame(maxWidth: .infinity, alignment: titleAlignment)
                }
            }
            .padding(padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: titleAlignment)
        } else {
            
            if isShowDate {
                Text(startDate.dDayString)
                    .font(.title)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2)
                    .padding(padding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: dateAlignment)
            }
            
            if isShowTitle {
                WidgetTitleView(title: title, subTitle: startDate.formattedDateString)
                    .padding(padding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: titleAlignment)
            }
        }
    }
}

struct AlignmentView: View {
    let alignment: Alignment
    let onTap: (Alignment) -> Void
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(spacing: 0), count: 3), alignment: .center, spacing: 3) {
            ForEach(0..<9) { index in
                RoundedRectangle(cornerRadius: 12)
                    .fill(index == alignmentToInt(alignment) ? .gray : .black)
                    .frame(width: 30, height: 30)
                    .onTapGesture() {
                        onTap(intToAlignment(index))
                    }
                    .overlay() {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.gray)
                    }
            }
        }
        .frame(width: 100)
    }
    
    
    func intToAlignment(_ index: Int) -> Alignment {
        switch index {
        case 0: return .topLeading
        case 1: return .top
        case 2: return .topTrailing
        case 3: return .leading
        case 4: return .center
        case 5: return .trailing
        case 6: return .bottomLeading
        case 7: return .bottom
        case 8: return .bottomTrailing
        default: return .center
        }
    }
    
    func alignmentToInt(_ alignment: Alignment) -> Int {
        switch alignment {
        case .topLeading: return 0
        case .top: return 1
        case .topTrailing: return 2
        case .leading: return 3
        case .center: return 4
        case .trailing: return 5
        case .bottomLeading: return 6
        case .bottom: return 7
        case .bottomTrailing: return 8
        default: return 4
            
        }
    }
}

extension Date {
    var formattedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd E"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: self)
    }
}


#Preview {
    AddDDayView(store: Store(initialState: AddDDayReducer.State()) {
        AddDDayReducer()
    })
}
