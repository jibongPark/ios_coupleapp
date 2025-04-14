//
//  coupleapp_WidgetExtension.swift
//  coupleapp.WidgetExtension
//
//  Created by 박지봉 on 4/9/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import WidgetKit
import SwiftUI
import Dependencies
import Domain
import WidgetData
import AppIntents
import Core
import WidgetFeature

struct WidgetEntry: TimelineEntry {
    let date: Date
    let widgetVO: WidgetVO?
}

struct WidgetProvider: AppIntentTimelineProvider {
    
    @Dependency(\.widgetRepository) var repository
    
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), widgetVO: nil)
    }
    
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> WidgetEntry {
        guard let selectedEntity = configuration.selectedItem else {
            return WidgetEntry(date: Date(), widgetVO: nil)
        }
        
        let all = repository.fetchWidget()
        let selectedVO = all.first(where: { $0.id == selectedEntity.id })
        
        return WidgetEntry(date: Date(), widgetVO: selectedVO)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<WidgetEntry> {
        
        guard let selected = configuration.selectedItem else {
            return Timeline(entries: [WidgetEntry(date: .now, widgetVO: nil)], policy: .atEnd)
        }
        
        let all = repository.fetchWidget()
        let vo = all.first(where: { $0.id == selected.id })
        
        let entry = WidgetEntry(date: .now, widgetVO: vo)
        
        let currentDate = Date()
                let calendar = Calendar.current
        guard let todayMidnight = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: currentDate)) else {
            return Timeline(entries: [entry], policy: .atEnd)
        }
        
        guard let nextMidnight = calendar.date(byAdding: .day, value: 1, to: todayMidnight) else {
            return Timeline(entries: [entry], policy: .atEnd)
        }
        
        
        return Timeline(entries: [entry], policy: .after(nextMidnight))
    }
}


struct coupleapp_WidgetExtensionEntryView : View {
    
    @Dependency(\.widgetFeature) var widgetFeature
    
    var entry: WidgetProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        if let vo = entry.widgetVO {
            
            switch widgetFamily {
                
            case .accessoryCircular, .accessoryRectangular, .accessoryInline:
                VStack {
                    Text(vo.title)
                    Text(vo.startDate.dDayString)
                }
                .containerBackground(.fill, for: .widget)
                
            default:
                
                GeometryReader { geometry in
                    
                    let _ = print(geometry.size)
                    ZStack {
                        AnyView(widgetFeature.widgetTextView(vo: vo))
                    }
                    

                }
                .containerBackground(for: .widget) {
                    if let image = ImageLib.loadImageFromGroup(withFileName: vo.imagePath, groupName:"group.com.bongbong.coupleapp") {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .clipped()
                    } else {
                    }
                }
            }
            
        } else {
            Text("No data")
                .padding()
                .containerBackground(.fill.tertiary, for: .widget)
        }
        
    }
}

struct coupleapp_WidgetExtension: Widget {
    let kind: String = "coupleapp_WidgetExtension"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: WidgetProvider()) { entry in
            coupleapp_WidgetExtensionEntryView(entry: entry)
        }
        .configurationDisplayName("디데이 위젯")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

struct WidgetEntityQuery: EntityStringQuery {
    func entities(matching string: String) async throws -> [WidgetEntity] {
        let all = repository.fetchWidget()
        
        return all
            .filter { $0.title.localizedCaseInsensitiveContains(string) }
            .map { WidgetEntity(vo: $0) }
    }
    
    
    let repository = DependencyValues().widgetRepository
    
    func suggestedEntities() async throws -> [WidgetEntity] {
        let all = repository.fetchWidget()
        return all.map { WidgetEntity(vo: $0) }
    }
    
    func entities(for identifiers: [Int]) async throws -> [WidgetEntity] {
        let all = repository.fetchWidget()
        return all.filter { identifiers.contains($0.id) }.map { WidgetEntity(vo: $0) }
    }
    
    func query(for string: String) async throws -> [WidgetEntity] {
        let all = repository.fetchWidget()
        
        return all
            .filter { $0.title.localizedCaseInsensitiveContains(string) }
            .map { WidgetEntity(vo: $0) }
    }
}


struct WidgetEntity: AppEntity {
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Widget Item")
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
    
    var id: Int
    var title: String
    var startDate: Date
    var memo: String
    
    static var defaultQuery = WidgetEntityQuery()
    
    static func entities(for query: String) async throws -> [WidgetEntity] {
        
        let repository = DependencyValues().widgetRepository
        let all: [WidgetVO] = repository.fetchWidget()
        
        guard !query.isEmpty else { return all.map { WidgetEntity(vo: $0) } }
        return all.filter { $0.title.localizedCaseInsensitiveContains(query) }
            .map { WidgetEntity(vo: $0) }
        }
    
    init(vo: WidgetVO) {
        self.id = vo.id
        self.title = vo.title
        self.memo = vo.memo
        self.startDate = vo.startDate
    }
    
    static func from(id: Int) async throws -> WidgetEntity {
        
        let repository = DependencyValues().widgetRepository
        
        let all: [WidgetVO] = repository.fetchWidget()
        if let vo = all.first(where: { $0.id == id }) {
            return WidgetEntity(vo: vo)
        } else {
            throw NSError(domain: "WidgetEntity", code: -1)
        }
    }
    
    
}

#Preview(as: .systemSmall) {
    coupleapp_WidgetExtension()
} timeline: {
    WidgetEntry(date: .now, widgetVO: WidgetVO(title: "hello"))
}
