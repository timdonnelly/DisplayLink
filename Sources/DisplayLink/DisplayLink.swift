import Foundation
import QuartzCore
import Combine


// A publisher that emits new values when the system is about to update the display.
public final class DisplayLink: Publisher {
    public typealias Output = Frame
    public typealias Failure = Never
    
    private let platformDisplayLink: PlatformDisplayLink
    
    private var subscribers: [CombineIdentifier:AnySubscriber<Frame, Never>] = [:] {
        didSet {
            dispatchPrecondition(condition: .onQueue(.main))
            platformDisplayLink.isPaused = subscribers.isEmpty
        }
    }
    
    fileprivate init(platformDisplayLink: PlatformDisplayLink) {
        dispatchPrecondition(condition: .onQueue(.main))
        self.platformDisplayLink = platformDisplayLink
        self.platformDisplayLink.onFrame = { [weak self] frame in
            self?.send(frame: frame)
        }
    }
    
    public func receive<S>(subscriber: S) where S : Subscriber, S.Failure == Never, S.Input == Frame {
        dispatchPrecondition(condition: .onQueue(.main))
        
        let typeErased = AnySubscriber(subscriber)
        let identifier = typeErased.combineIdentifier
        let subscription = Subscription(onCancel: { [weak self] in
            self?.cancelSubscription(for: identifier)
        })
        subscribers[identifier] = typeErased
        subscriber.receive(subscription: subscription)
    }
    
    private func cancelSubscription(for identifier: CombineIdentifier) {
        dispatchPrecondition(condition: .onQueue(.main))
        subscribers.removeValue(forKey: identifier)
    }
    
    private func send(frame: Frame) {
        dispatchPrecondition(condition: .onQueue(.main))
        let subscribers = self.subscribers.values
        subscribers.forEach {
            _ = $0.receive(frame) // Ignore demand
        }
    }
    
}

extension DisplayLink {
    
    // Represents a frame that is about to be drawn
    public struct Frame {
        
        // The system timestamp for the frame to be drawn
        public var timestamp: TimeInterval
        
        // The duration between each display update
        public var duration: TimeInterval
    }
    
}

extension DisplayLink {
    
    @available(iOS 13.0, tvOS 13.0, *)
    public convenience init() {
        self.init(platformDisplayLink: CADisplayLinkPlatformDisplayLink())

    }
    
}

extension DisplayLink {
    public static let shared = DisplayLink()
}

extension DisplayLink {
    
    fileprivate final class Subscription: Combine.Subscription {
        
        var onCancel: () -> Void

        init(onCancel: @escaping () -> Void) {
            self.onCancel = onCancel
        }
        
        func request(_ demand: Subscribers.Demand) {
            // Do nothing – subscribers can't impact how often the system draws frames.
        }
        
        func cancel() {
            onCancel()
        }
    }
    
}

fileprivate protocol PlatformDisplayLink: class {
    var onFrame: (DisplayLink.Frame) -> Void { get set }
    var isPaused: Bool { get set }
}


@available(iOS 13.0, tvOS 13.0, *)
final class CADisplayLinkPlatformDisplayLink: PlatformDisplayLink {
    
    private var displayLink: CADisplayLink!
    
    var onFrame: (DisplayLink.Frame) -> Void = { _ in }
    
    var isPaused: Bool {
        get { displayLink.isPaused }
        set { displayLink.isPaused = newValue }
    }
    
    init() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidFire(_:)))
        displayLink.add(to: RunLoop.main, forMode: .common)
        displayLink.isPaused = true
    }
    
    @objc private func displayLinkDidFire(_ link: CADisplayLink) {
        let frame = DisplayLink.Frame(
            timestamp: link.timestamp,
            duration: link.duration)
        onFrame(frame)
    }
}
