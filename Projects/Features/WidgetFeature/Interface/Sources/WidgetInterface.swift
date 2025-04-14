import Foundation
import SwiftUI
import Domain

public protocol WidgetInterface {
    func makeView() -> any View
    func widgetTextView(vo: WidgetVO) -> any View
}
