import SwiftUI

/// Settings → Glow → Custom: a square for how vivid and how bright, a rainbow bar for
/// the hue, and a field for a hex code. Every change sets the colour at once.
struct ColorPopup: View {
    @Binding var color: Color
    @State private var hue = 0.0
    @State private var saturation = 0.0
    @State private var brightness = 0.0
    @State private var code = ""

    private static let squareSize = CGSize(width: 200, height: 140)
    private static let barHeight: CGFloat = 12

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            square
            hueBar
            HStack(spacing: 6) {
                Text("#").foregroundStyle(.secondary)
                TextField("Hex code", text: $code)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .onSubmit(applyCode)
            }
        }
        .padding(14)
        .frame(width: Self.squareSize.width + 28)
        .onAppear {
            (hue, saturation, brightness) = GlowColors.hsb(of: color)
            code = String(GlowColors.hex(of: color).dropFirst())
        }
    }

    /// White to the full hue across, clear to black down.
    private var square: some View {
        let size = Self.squareSize
        return ZStack {
            LinearGradient(colors: [.white, Color(hue: hue, saturation: 1, brightness: 1)],
                           startPoint: .leading, endPoint: .trailing)
            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
            Circle()
                .strokeBorder(.white, lineWidth: 2)
                .shadow(radius: 1)
                .frame(width: 14, height: 14)
                .position(x: saturation * size.width, y: (1 - brightness) * size.height)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0).onChanged { drag in
            saturation = Self.fraction(drag.location.x, of: size.width)
            brightness = 1 - Self.fraction(drag.location.y, of: size.height)
            apply()
        })
        .accessibilityLabel("Colour square")
    }

    private var hueBar: some View {
        let width = Self.squareSize.width
        let height = Self.barHeight
        return ZStack {
            LinearGradient(colors: stride(from: 0.0, through: 1, by: 1.0 / 6).map { Color(hue: $0, saturation: 1, brightness: 1) },
                           startPoint: .leading, endPoint: .trailing)
                .clipShape(Capsule())
            Circle()
                .strokeBorder(.white, lineWidth: 2)
                .shadow(radius: 1)
                .frame(width: height + 4, height: height + 4)
                .position(x: hue * width, y: height / 2)
        }
        .frame(width: width, height: height)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0).onChanged { drag in
            hue = Self.fraction(drag.location.x, of: width)
            apply()
        })
        .accessibilityLabel("Hue")
    }

    private func apply() {
        color = Color(hue: hue, saturation: saturation, brightness: brightness)
        code = String(GlowColors.hex(of: color).dropFirst())
    }

    /// A typed code applies on Return; an unreadable one is put back.
    private func applyCode() {
        guard let typed = GlowColors.color(typed: code) else {
            code = String(GlowColors.hex(of: color).dropFirst())
            return
        }
        color = typed
        (hue, saturation, brightness) = GlowColors.hsb(of: typed)
        code = String(GlowColors.hex(of: typed).dropFirst())
    }

    private static func fraction(_ value: CGFloat, of length: CGFloat) -> Double {
        min(max(value / length, 0), 1)
    }
}
