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

import DiaryFeature


public struct CalendarView: View {
    
    @Perception.Bindable var store: StoreOf<CalendarReducer>
    
    public init(store: StoreOf<CalendarReducer>) {
        self.store = store
    }
    
    public var body: some View {

        NavigationStack {
            ZStack {
                calendarView
                    .frame(maxHeight: .infinity, alignment: .top)
                
                expandableButton
                    .padding(.trailing, 10)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
        .sheet(
            item: $store.scope(state: \.destination?.diaryView, action: \.destination.diaryView)) { diaryViewStore in
                NavigationStack {
                    DiaryView(store: diaryViewStore)
                }
            }
        
    }
    
    private var calendarView: some View {
        VStack {
            headerView
            calendarGridView
        }
    }
    
    private var headerView: some View {
        VStack {
            HStack {
                yearMonthView
                
                Spacer()
                
                Button(
                    action: { },
                    label: {
                        Image(systemName: "list.bullet")
                            .font(.title)
                            .foregroundColor(.black)
                    }
                )
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 5)
            
            HStack {
                ForEach(Self.weekdaySymbols.indices, id: \.self) { symbol in
                    Text(Self.weekdaySymbols[symbol].uppercased())
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 5)
        }
    }
    
    // MARK: - 연월 표시
    private var yearMonthView: some View {
        HStack(alignment: .center, spacing: 20) {
            Button(
                action: {
                    changeMonth(by: -1)
                },
                label: {
                    Image(systemName: "chevron.left")
                        .font(.title)
                        .foregroundColor(.black)
                }
            )
            
            Text(store.selectedMonth, formatter: Self.calendarHeaderDateFormatter)
                .font(.title.bold())
            
            Button(
                action: {
                    changeMonth(by: 1)
                },
                label: {
                    Image(systemName: "chevron.right")
                        .font(.title)
                        .foregroundColor(.black)
                }
            )
        }
    }
    
    // MARK: - 날짜 그리드 뷰
    private var calendarGridView: some View {
        let daysInMonth: Int = numberOfDays(in: store.selectedMonth)
        let firstWeekday: Int = firstWeekdayOfMonth(in: store.selectedMonth) - 1
        let lastDayOfMonthBefore = numberOfDays(in: previousMonth())
        let numberOfRows = Int(ceil(Double(daysInMonth + firstWeekday) / 7.0))
        let visibleDaysOfNextMonth = numberOfRows * 7 - (daysInMonth + firstWeekday)
        
        return LazyVGrid(columns: Array(repeating: GridItem(), count: 7)) {
            ForEach(-firstWeekday ..< daysInMonth + visibleDaysOfNextMonth, id: \.self) { index in
                let isCurrentMonth = index >= 0 && index < daysInMonth
                
                if isCurrentMonth {
                    let date = getDate(for: index)
                    let day = Calendar.current.component(.day, from: date)
                    let clicked = store.selectedDate == date
                    let isToday = date.formattedCalendarDayDate == today.formattedCalendarDayDate
                    
                    CellView(day: day, clicked: clicked, isToday: isToday)
                        .onTapGesture {
                            store.send(.selectedDateChange(date))
                        }
                } else  {
                    if let prevMonthDate = Calendar.current.date(
                        byAdding: .day,
                        value: index < 0 ? index + lastDayOfMonthBefore : index,
                        to: previousMonth()) {
                        let day = Calendar.current.component(.day, from: prevMonthDate)
                        
                        CellView(day: day, isCurrentMonthDay: false)
                    }
                }
            }
        }
    }
    // MARK: - 일자 셀 뷰
    private struct CellView: View {
        private var day: Int
        private var clicked: Bool
        private var isToday: Bool
        private var isCurrentMonthDay: Bool
        private var textColor: Color {
            if clicked {
                return Color.white
            } else if isCurrentMonthDay {
                return Color.black
            } else {
                return Color.gray
            }
        }
        private var backgroundColor: Color {
            if clicked {
                return Color.black
            } else if isToday {
                return Color.gray
            } else {
                return Color.white
            }
        }
        
        fileprivate init(
            day: Int,
            clicked: Bool = false,
            isToday: Bool = false,
            isCurrentMonthDay: Bool = true
        ) {
            self.day = day
            self.clicked = clicked
            self.isToday = isToday
            self.isCurrentMonthDay = isCurrentMonthDay
        }
        
        fileprivate var body: some View {
            VStack {
                Circle()
                    .fill(backgroundColor)
                    .overlay(Text(String(day)))
                    .foregroundColor(textColor)
                
                Spacer()
                
                if clicked {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.red)
                        .frame(width: 10, height: 10)
                } else {
                    Spacer()
                        .frame(height: 10)
                }
            }
            .frame(height: 50)
        }
    }
    
    // MARK: 확장 버튼
    
    @State private var isButtonExpand = false;
    
    private var expandableButton: some View {
        VStack {
            if isButtonExpand {
                VStack(spacing: 10) {
                    actionButton(title: "1", color: .blue, action: { store.send(.navigateTo(.diary)) })
                    actionButton(title: "2", color: .green, action: { store.send(.navigateTo(.todo)) })
                        actionButton(title: "3", color: .purple, action: { store.send(.navigateTo(.schedule)) })
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
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
                }
    }
    
}

private extension CalendarView {
    var today: Date {
        let now = Date()
        let components = Calendar.current.dateComponents([.year, .month, .day], from: now)
        return Calendar.current.date(from: components)!
      }
      
      static let calendarHeaderDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY.MM"
        return formatter
      }()
      
      static let weekdaySymbols: [String] = Calendar.current.shortWeekdaySymbols
    
  /// 특정 해당 날짜
  func getDate(for index: Int) -> Date {
    let calendar = Calendar.current
    guard let firstDayOfMonth = calendar.date(
      from: DateComponents(
        year: calendar.component(.year, from: store.selectedMonth),
        month: calendar.component(.month, from: store.selectedMonth),
        day: 1
      )
    ) else {
      return Date()
    }
    
    var dateComponents = DateComponents()
    dateComponents.day = index
    
    let timeZone = TimeZone.current
    let offset = Double(timeZone.secondsFromGMT(for: firstDayOfMonth))
    dateComponents.second = Int(offset)
    
    let date = calendar.date(byAdding: dateComponents, to: firstDayOfMonth) ?? Date()
    return date
  }
  
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
  
  /// 이전 월 마지막 일자
  func previousMonth() -> Date {
    let components = Calendar.current.dateComponents([.year, .month], from: store.selectedMonth)
    let firstDayOfMonth = Calendar.current.date(from: components)!
    let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: firstDayOfMonth)!
    
    return previousMonth
  }
  
  /// 월 변경
  func changeMonth(by value: Int) {
      store.send(.selectedMonthChange(adjustedMonth(by: value)))
  }
  
  
  /// 변경하려는 월 반환
  func adjustedMonth(by value: Int) -> Date {
    if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: store.selectedMonth) {
      return newMonth
    }
    return store.selectedMonth
  }
}

extension Date {
  static let calendarDayDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM yyyy dd"
    return formatter
  }()
  
  var formattedCalendarDayDate: String {
    return Date.calendarDayDateFormatter.string(from: self)
  }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView(
            store: Store(initialState: CalendarReducer.State(selectedMonth: Date())) {
                CalendarReducer()
            }
        )
    }
}
