# DisplayLink

A simplified `DisplayLink` abstraction for all platforms (including iOS, tvOS, watchOS, macOS, Linux).

```swift
public final class DisplayLink : Publisher {
    public typealias Output = Frame
    public typealias Failure = Never
}

extension DisplayLink {
    public struct Frame {
        public var timestamp: TimeInterval
        public var duration: TimeInterval
    }
}
```

*****

Includes a Combine publisher with SwiftUI integration for `CADisplayLink`.

SwiftUI does not currently provide any API to perform actions on a per-frame basis. This tiny 
library simplifies the work of bridging between `CADisplayLink` and SwiftUI:

```swift
import DisplayLink

struct MyView: View {

    @State var offset: CGFloat = 0.0

    var body: some View {
        Color
            .red
            .frame(width: 40, height: 40)
            .offset(x: offset, y: offset)
            .onFrame { frame in
                self.offset += (frame.duration * 20.0)
            }
    }
}
```
