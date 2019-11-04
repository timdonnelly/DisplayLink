# DisplayLink

A Combine publisher with SwiftUI integration for `CADisplayLink`.

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