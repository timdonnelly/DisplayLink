import SwiftUI
import Combine

extension SwiftUI.View {
    
    public func onFrame(isActive: Bool = true, displayLink: DisplayLink = .shared, _ action: @escaping (DisplayLink.Frame) -> Void) -> some View {
        let publisher = isActive ? displayLink.eraseToAnyPublisher() : Empty<DisplayLink.Frame, Never>().eraseToAnyPublisher()
        return SubscriptionView(content: self, publisher: publisher, action: action)
    }
    
}
