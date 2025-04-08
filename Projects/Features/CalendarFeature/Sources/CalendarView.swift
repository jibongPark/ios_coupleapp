//
//  CalendarView.swift
//  CalendarFeature
//
//  Created by 박지봉 on 2/7/25.
//  Copyright © 2025 SampleCompany. All rights reserved.
//

import CalendarData
import ComposableArchitecture
import SwiftUI

import CalendarFeatureInterface
import Domain


struct CalendarView: View {
    
    @Bindable var store: StoreOf<CalendarReducer>
    
    @State private var didAppear = false
    
    init(store: StoreOf<CalendarReducer>) {
        self.store = store
    }
    
    var body: some View {
        
        let sidePadding: CGFloat = 5
        
        NavigationStack {
            GeometryReader { proxy in
                
                
                ZStack(alignment: .top) {
                    VStack(spacing: 5) {
                        
                        // MARK: 헤더 뷰 + 캘린더 뷰
                        
                        Text(store.selectedMonth.formattedCalendarMonthDate)
                            .font(.title.bold())
                            .padding(.bottom, 5)
                        
                        HStack {
                            ForEach(Self.weekdaySymbols.indices, id: \.self) { symbol in
                                Text(Self.weekdaySymbols[symbol].uppercased())
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding([.leading, .trailing], sidePadding)
                        
                        Divider()
                        
                        let viewHeight = proxy.size.height/2
                        
                        InfinitePagerView(selection: store.selectedMonth,
                                          before: { _ in store.selectedMonth.addMonth(-1) },
                                          after: { _ in store.selectedMonth.addMonth(1) },
                                          selectDate: store.selectedDate,
                                          onDisapearCompletion: { date in
                            store.send(.selectedMonthChange(date))
                        },
                                          view: { date in
                            
                            let daysInMonth: Int = numberOfDays(in: date)
                            let firstWeekday: Int = firstWeekdayOfMonth(in: date) - 1
                            let numberOfRows = Int(ceil(Double(daysInMonth + firstWeekday) / 7.0))
                            let visibleDaysOfNextMonth = numberOfRows * 7 - (daysInMonth + firstWeekday)
                            
                            let cellHeight = viewHeight / CGFloat(numberOfRows)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(spacing: 0), count: 7), alignment: .center, spacing: 0) {
                                ForEach(-firstWeekday ..< daysInMonth + visibleDaysOfNextMonth, id: \.self) { index in
                                    let isCurrentMonth = index >= 0 && index < daysInMonth
                                    
                                    let currentDate = date.getDate(for: index)
                                    
                                    DateCellView(date: currentDate,
                                                 isCurrentMonth: isCurrentMonth,
                                                 isSelectDate: currentDate.isEqual(to: store.selectedDate),
                                                 todos: store.todoData[currentDate.calendarKeyString],
                                                 schedules: store.scheduleData[currentDate.calendarKeyString],
                                                 diary: store.diaryData[currentDate.calendarKeyString]
                                                 
                                    )
                                    .frame(height: cellHeight)
                                    .onTapGesture {
                                        store.send(.selectedDateChange(currentDate))
                                    }
                                }
                            }
                            .padding([.leading, .trailing], sidePadding)
                        })
                        .frame(height: viewHeight, alignment: .top)
                        
                    }
                    
                }
                
                InfoView(store: store)
                
                expandableButton
                    .padding(.trailing, 10)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
            .navigationDestination(item: $store.scope(state: \.destination?.diaryView, action: \.destination.diaryView)) { store in
                DiaryView(store: store)
            }
            .navigationDestination(item: $store.scope(state: \.destination?.todoView, action: \.destination.todoView)) { store in
                TodoView(store: store)
            }
            .navigationDestination(item: $store.scope(state: \.destination?.scheduleView, action: \.destination.scheduleView)) { store in
                ScheduleView(store: store)
            }
            .onAppear() {
                if !didAppear {
                    didAppear = true
                    store.send(.searchAllData)
                }
            }
        }
    }
    
    private struct DateCellView: View {
        let date: Date
        let isCurrentMonth: Bool
        let isSelectDate: Bool
        
        let todos: [TodoVO]?
        let schedules: [ScheduleVO]?
        let diary: DiaryVO?
        
        var body: some View {
            
            GeometryReader { geometry in
                VStack(alignment: .center, spacing: 2) {
                    
                    let color = date.getColorOfDate()
                    
                    if date.isToday() {
                        Text("\(date.day)")
                            .font(.system(size: 13, weight: .bold, design: .default))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(Color.red.opacity(isCurrentMonth ? 0.95 : 0.3))
                                    .frame(width: 23, height: 23)
                            )
                            .padding(EdgeInsets(top: 4, leading: 4, bottom: 2, trailing: 4))
                        
                    } else if isSelectDate {
                        Text("\(date.day)")
                            .font(.system(size: 13, weight: .bold, design: .default))
                            .foregroundColor(color)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.5))
                                    .frame(width: 23, height: 23)
                            )
                            .padding(EdgeInsets(top: 4, leading: 4, bottom: 2, trailing: 4))
                    } else {
                        Text("\(date.day)")
                            .font(.system(size: 13, weight: .bold, design: .default))
                            .foregroundColor(color)
                            .opacity(isCurrentMonth ? 1 : 0.3)
                            .padding(EdgeInsets(top: 4, leading: 4, bottom: 2, trailing: 4))
                    }
                    
                    // FIXME: todos, schedules를 하나의 배열로 합쳐서 처리할경우 컴파일러 타입추론 시간이 길어져 에러 발생... DetailView에서 처리하도록 처리
                    DateCellDetailView(todos: todos,
                                       schedules: schedules,
                                       isCurrentMonth: isCurrentMonth
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }
    
    private struct DateCellDetailView: View {
        let todos: [TodoVO]?
        let schedules: [ScheduleVO]?
        let isCurrentMonth: Bool
        
        var body: some View {
            let calendarItems: [CalendarVO] = (schedules ?? []) + (todos ?? [])

            GeometryReader { geometry in
                
                let rowHeight: CGFloat = 15
                let availableRows = Int(geometry.size.height / rowHeight) - 1
                let visibleItems = Array(calendarItems.prefix(availableRows))
                let extraCount = calendarItems.count - visibleItems.count
                
                VStack(spacing: 1) {
                    ForEach(visibleItems, id: \.id) { item in
                        ZStack {
                            Text(item.title)
                                .lineLimit(1)
                                .foregroundColor(.white)
                                .font(.system(size: 8, weight: .bold, design: .default))
                                .padding(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
                                .frame(width: geometry.size.width, alignment: .center)
                                .background(item.color)
                                .opacity(isCurrentMonth ? 1 : 0.3)
                        }
                    }
                    
                    if extraCount > 0 {
                                Text("+\(extraCount)")
                                    .lineLimit(1)
                                    .foregroundColor(.white)
                                    .font(.system(size: 8, weight: .bold, design: .default))
                                    .padding(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
                                    .frame(width: geometry.size.width, alignment: .center)
                                    .background(Color.red)
                                    .opacity(isCurrentMonth ? 1 : 0.3)
                            }
                }
            }
        }
    }
    
    private struct InfoView: View {
        let store: StoreOf<CalendarReducer>
        
        @State private var spacerHeight: CGFloat = 300  // 초기 높이
        @State private var dragOffset: CGFloat = 0
        @State private var isDragable = false
        
        @State private var scrollOffset: CGFloat = 0
        
        var body: some View {
            
            GeometryReader { proxy in
                VStack {
                    Spacer()
                        .frame(height: CGFloat(max(proxy.size.height - (spacerHeight - dragOffset), 0)))
                    
                    ZStack(alignment: .top) {
                        
                        RoundedRectangle(cornerRadius: 30)
                            .fill(.gray.opacity(0.7))
                            .frame(width: 50, height: 5)
                            .padding(5)
                        
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.gray.opacity(0.5))
                            .frame(height: 40)
                            .mask(VStack(spacing:0) {
                                Rectangle()
                                    .frame(height: 20)
                                Spacer(minLength: 0)
                            })
                        
                        HStack {
                            Text("\(String(store.selectedDate.day)). \(store.selectedDate.weekDay)")
                                .frame(alignment: .leading)
                                .padding(10)
                            Spacer()
                        }
                    
                        
                        ScrollView {
                            LazyVStack(alignment: .leading) {
                                
                                if let todos = store.todoData[store.selectedDate.calendarKeyString] {
                                    InfoTodoView(store: store, todos: todos)
                                        .id(todos)
                                }
                                
                                if let schedules = store.scheduleData[store.selectedDate.calendarKeyString] {
                                    InfoScheduleView(store: store, schedules: schedules)
                                }
                                
                                if let diary = store.diaryData[store.selectedDate.calendarKeyString] {
                                    InfoDiaryView(store: store, diary: diary)
                                }
                                
                            }
                            .padding(5)
                            .background(GeometryReader { proxy -> Color in
                                            DispatchQueue.main.async {
                                                scrollOffset = -proxy.frame(in: .named("scroll")).origin.y
                                            }
                                return .white
                            })
                        }
                        .coordinateSpace(name: "scroll")
                        .padding(.top, 30)
                        .scrollDisabled(!isDragable)
                        .scrollContentBackground(.hidden)
                        .simultaneousGesture(
                            DragGesture(coordinateSpace: .global)
                                .onChanged { value in
                                    if((!isDragable && value.velocity.height < 0) || (scrollOffset == 0 && value.velocity.height > 0)) {
                                        dragOffset = value.translation.height
                                        isDragable = false
                                    }
                                }
                                .onEnded {value in
                                    
                                    if(!isDragable) {
                                        
                                        var newHeight = spacerHeight - dragOffset
                                        let minHeight = proxy.size.height * 0.4
                                        let maxHeight = proxy.size.height * 0.95

                                        if value.velocity.height >= 100 {
                                            newHeight = minHeight
                                        } else if value.velocity.height <= -100 {
                                            newHeight = maxHeight
                                        } else {
                                            if newHeight >= ((maxHeight + minHeight)/2) {
                                                newHeight = maxHeight
                                            } else {
                                                newHeight = minHeight
                                            }
                                        }
                                        
                                        if(newHeight == maxHeight) {
                                            isDragable = true
                                        } else {
                                            isDragable = false
                                        }
                                        
                                        withAnimation() {
                                            spacerHeight = min(max(newHeight, minHeight), maxHeight)
                                            dragOffset = 0
                                        }
                                    }
                                }
                        )
                    }
                    .background(.white)
                    
                }
                .onAppear() {
                    UIScrollView.appearance().bounces = false
                }
                .onDisappear() {
                    UIScrollView.appearance().bounces = true
                }
                
            }
        }
    }
    
    private struct InfoTodoView: View {
        let store: StoreOf<CalendarReducer>
        
        @State var todos: [TodoVO]
        var body: some View {
            
            LazyVStack(alignment: .leading, spacing: 0) {
                Text("할일")
                    .font(.system(size: 10, weight: .light))
                    .padding(5)
                
                ForEach($todos, id: \.id) { todo in
                    HStack(alignment: .center, spacing: 0) {
                        Toggle("", isOn: todo.isDone)
                            .toggleStyle(CheckboxToggleStyle(style: .square))
                            .onChange(of: todo.wrappedValue) { before, new in
                                store.send(.todoDidToggle(new))
                            }
                        
                        Text(todo.wrappedValue.title)
                    }
                    .padding(.bottom, 5)
                    .padding(.leading, 10)
                    .onTapGesture {
                        store.send(.navigateTo(.todo(todo.wrappedValue)))
                    }
                }
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
        }
    }
    
    private struct InfoScheduleView: View {
        let store: StoreOf<CalendarReducer>
        let schedules: [ScheduleVO]
        
        var body: some View {
            
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(schedules, id: \.id) { schedule in
                    HStack(alignment: .center, spacing: 0) {
                        Circle()
                            .fill(.gray.opacity(0.75))
                            .frame(width:12, height: 12)
                        VStack(alignment: .leading) {
                            Text(schedule.title)
                            
                            Text("\(scheduleDateString(for: schedule.startDate)) - \(scheduleDateString(for: schedule.endDate))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.leading, 8)
                    }
                    .padding(5)
                    .onTapGesture {
                        store.send(.navigateTo(.schedule(schedule)))
                    }
                }
            }
        }
        
        func scheduleDateString(for date: Date) -> String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "M.d EEE a h시"
             
            return formatter.string(from: date)
        }
    }
    
    private struct InfoDiaryView: View {
        let store: StoreOf<CalendarReducer>
        let diary: DiaryVO
        
        var body: some View {
            LazyHStack {
                Text("다이어리 : \(diary.content)")
            }
            .onTapGesture {
                store.send(.navigateTo(.diary))
            }
        }
    }
    
    struct CheckboxToggleStyle: ToggleStyle {
        @Environment(\.isEnabled) var isEnabled
        let style: Style // custom param

        func makeBody(configuration: Configuration) -> some View {
            Button(action: {
                configuration.isOn.toggle() // toggle the state binding
            }, label: {
                HStack {
                    Image(systemName: configuration.isOn ? "checkmark.\(style.sfSymbolName).fill" : style.sfSymbolName)
                        .imageScale(.large)
                        .foregroundColor(Color.blue)
                    configuration.label
                }
            })
            .buttonStyle(PlainButtonStyle()) // remove any implicit styling from the button
            .disabled(!isEnabled)
        }

        enum Style {
            case square, circle

            var sfSymbolName: String {
                switch self {
                case .square:
                    return "square"
                case .circle:
                    return "circle"
                }
            }
        }
    }

    
    @State private var isButtonExpand = false;
    
    private var expandableButton: some View {
        VStack {
            if isButtonExpand {
                VStack(spacing: 10) {
                    actionButton(title: "일기", color: .blue, action: { store.send(.navigateTo(.diary)) })
                    actionButton(title: "할일", color: .green, action: { store.send(.navigateTo(.todo(nil))) })
                    actionButton(title: "일정", color: .purple, action: { store.send(.navigateTo(.schedule(nil))) })
                }
                .transition(.opacity)
            }
            
            Button(action: {
                withAnimation {
                    isButtonExpand.toggle()
                }
            }, label: {
                Image(systemName: isButtonExpand ? "xmark.circle.fill" : "plus.circle.fill")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.blue)
            })
        }
    }
    
    private func actionButton(title: String, color: Color, action: @escaping @MainActor () -> Void) -> some View {
        Button(action: action) {
                    Text(title)
                        .padding()
                        .frame(width: 60)
                        .background(color)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .font(.system(size: 10))
                }
    }
    
}

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

private extension CalendarView {
    
    static let weekdaySymbols: [String] = Calendar.current.shortWeekdaySymbols
    
    /// 해당 월에 존재하는 일자 수
    func numberOfDays(in date: Date) -> Int {
        return Calendar.current.range(of: .day, in: .month, for: date)?.count ?? 0
    }
    
    /// 해당 월의 첫 날짜가 갖는 해당 주의 몇번째 요일
    func firstWeekdayOfMonth(in date: Date) -> Int {
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        let firstDayOfMonth = Calendar.current.date(from: components)!
        
        return Calendar.current.component(.weekday, from: firstDayOfMonth)
    }
}

extension Date {
    
    func getColorOfDate() -> Color {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: self)
        
        if weekday == 1 {
            return Color.red
        } else if weekday == 7 {
            return Color.blue
        } else {
            return Color.black
        }
    }
}

public struct CalendarFeature: CalendarInterface {
    public init() {}
    
    public func makeView() -> any View {
        AnyView(
            CalendarView(
                store: .init(initialState: CalendarReducer.State(selectedMonth: Date())) {
                    CalendarReducer()
                }
            )
        )
    }
}

enum CalendarFeatureKey: DependencyKey {
    static var liveValue: CalendarInterface = CalendarFeature()
}

public extension DependencyValues {
    var calendarFeature: CalendarInterface {
        get { self[CalendarFeatureKey.self] }
        set { self[CalendarFeatureKey.self] = newValue }
    }
}

#Preview {
    CalendarView(store: Store(initialState: CalendarReducer.State(selectedMonth: Date())) {
        CalendarReducer()
    })
}
