import Foundation
import Domain
import ComposableArchitecture
import Core


public struct WidgetRepositoryImpl: WidgetRepository {
    
    let groupName: String = "group.com.bongbong.coupleapp"
    
    let widgetDicKey: String = "widgetDic"
    let widgetKey: String = "widget_"
    
    public func fetchWidgetTCA() -> Effect<[WidgetVO]> {
        
        let datas = fetchWidget()
        
        return Effect.run { [datas] send in
            await send(datas)
        }
    }
    
    public func fetchWidget() -> [WidgetVO] {
        
        let defaults = UserDefaults(suiteName: groupName)
        
        var datas = [WidgetVO]()
        
        let keys = fetchKeys()
        
        for key in keys {
            if let data = defaults?.data(forKey: key) {
                do {
                    let widget = try JSONDecoder().decode(WidgetVO.self, from: data)
                    datas.append(widget)
                } catch {
                    print("widget 변환 실패")
                }
            }
        }
        
        return datas
    }
    
    func fetchKeys() -> [String] {
        
        let defaults = UserDefaults(suiteName: groupName)
        
        let keys = defaults?.array(forKey: widgetDicKey) ?? [String]()
        
        return keys.map { "\($0)" }
    }
    
    public func updateWidget(_ newValue: WidgetVO) async {
        let defaults = UserDefaults(suiteName: groupName)
        
        var keys = fetchKeys()
        
        let key = widgetKey + String(newValue.id)

        do {
            let encodedData = try JSONEncoder().encode(newValue)
            
            defaults?.set(encodedData, forKey: key)
            
            if !keys.contains(key) {
                keys.append(key)
                defaults?.set(keys, forKey: widgetDicKey)
            }
            
        } catch {
            print("widget 저장 실패")
        }
    }
    
    public func removeWidget(_ value: WidgetVO) async {
        
        if !value.imagePath.isEmpty {
            ImageLib.removeImageFromGroup(withFilename: value.imagePath, groupName: "group.com.bongbong.coupleapp")
        }
        
        let defaults = UserDefaults(suiteName: groupName)
        
        var keys = fetchKeys()
        
        let key = widgetKey + String(value.id)
        
        keys.removeAll { $0 == key }
        defaults?.set(keys, forKey: widgetDicKey)
        
        defaults?.removeObject(forKey: key)
    }
}

private enum WidgetRepositoryKey: DependencyKey {
    static var liveValue: WidgetRepository = WidgetRepositoryImpl()
}

public extension DependencyValues {
    var widgetRepository: WidgetRepository {
        get { self[WidgetRepositoryKey.self] }
        set { self[WidgetRepositoryKey.self] = newValue }
    }
}
