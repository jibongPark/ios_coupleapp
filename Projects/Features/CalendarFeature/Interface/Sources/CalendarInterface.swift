import Foundation
import SwiftUI

public protocol CalendarInterface {
    func makeView() -> any View
    func sync()
}
