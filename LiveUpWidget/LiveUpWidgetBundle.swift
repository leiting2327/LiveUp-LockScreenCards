import WidgetKit
import SwiftUI

@main
struct LiveUpWidgetBundle: WidgetBundle {
    var body: some Widget {
        CardLiveActivity()
        LockScreenCardWidget()
    }
}
