import SwiftUI

/// Onboarding's greeting in the open panel: "hello" writes itself in Ember's colours, then
/// "Welcome to Ember" and Get Started come in. With Reduce Motion, all of it shows at once.
struct HelloView: View {
    let getStarted: () -> Void
    @Environment(\.notchHeight) private var notchHeight
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var written: CGFloat = 0
    @State private var showsWelcome = false
    @State private var showsButton = false

    /// Ember rose, pink, violet and blue, from the first letter to the last.
    static let colors = [Color(red: 0.85, green: 0.47, blue: 0.42), Color(red: 0.93, green: 0.45, blue: 0.62),
                         Color(red: 0.66, green: 0.48, blue: 0.95), Color(red: 0.42, green: 0.62, blue: 1)]
    /// How long the word takes to write.
    static let writingTime: TimeInterval = 2.5

    var body: some View {
        VStack(spacing: 8) {
            HelloShape()
                .trim(from: 0, to: written)
                .stroke(LinearGradient(colors: Self.colors, startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                .frame(width: 190, height: 66)
                .accessibilityLabel("hello")
            Text("Welcome to Ember")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.65))
                .opacity(showsWelcome ? 1 : 0)
            Button(action: getStarted) {
                Text("Get Started")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.white))
            }
            .buttonStyle(.plain)
            .opacity(showsButton ? 1 : 0)
            .padding(.top, 4)
        }
        .padding(.top, notchHeight)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(\.colorScheme, .dark)
        .onAppear(perform: play)
    }

    private func play() {
        guard !reduceMotion else {
            written = 1
            showsWelcome = true
            showsButton = true
            return
        }
        // A moment for the panel to open first.
        withAnimation(.easeInOut(duration: Self.writingTime).delay(0.3)) { written = 1 }
        withAnimation(.easeOut(duration: 0.5).delay(Self.writingTime)) { showsWelcome = true }
        withAnimation(.easeOut(duration: 0.5).delay(Self.writingTime + 0.4)) { showsButton = true }
    }
}
