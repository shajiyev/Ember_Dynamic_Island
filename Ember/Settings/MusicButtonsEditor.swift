import SwiftUI

/// Settings → Music → Buttons: the Music tab's row drawn as it looks (a black strip, the
/// white buttons, play/pause's white circle), with Spare below it. A button is dragged onto
/// a place to move there (swapping with the one there), or down to Spare to come out; a
/// spare one is dragged up to go in. Play/pause stays in the middle.
struct MusicButtonsEditor: View {
    @Binding var row: MusicButtonRow

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            preview
            spare
        }
        .animation(.snappy, value: row)
    }

    /// The row, laid out like `MusicControls`: three places on each side of play/pause.
    private var preview: some View {
        MusicButtonLayout {
            ForEach(0..<3, id: \.self) { place($0) }
            Image(systemName: "play.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 32, height: 32)
                .background(Circle().fill(.white))
                .help("Play/pause stays in the middle")
                .accessibilityLabel("Play/pause, fixed in the middle")
            ForEach(3..<6, id: \.self) { place($0) }
        }
        .padding(.horizontal, 20)
        .frame(width: 360, height: 52)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.black))
        .frame(maxWidth: .infinity)
    }

    private func place(_ index: Int) -> some View {
        ButtonPlace(button: row.places[index]) { name in
            guard let button = name.flatMap(MusicButton.init(rawValue:)) else { return false }
            row = row.placing(button, at: index)
            return true
        }
    }

    private var spare: some View {
        HStack(spacing: 14) {
            Text("Spare")
                .foregroundStyle(.secondary)
            if row.spare.isEmpty {
                Text("Drag a button here to take it out.")
                    .foregroundStyle(.tertiary)
            }
            ForEach(row.spare, id: \.self) { button in
                MusicButtonIcon(button: button)
                    .foregroundStyle(.primary)
                    .draggable(button.rawValue) { MusicButtonIcon(button: button) }
                    .help("Drag up to add \(button.title)")
                    .accessibilityLabel("\(button.title), spare")
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 32)
        .contentShape(Rectangle())
        .dropDestination(for: String.self) { names, _ in
            guard let button = names.first.flatMap(MusicButton.init(rawValue:)) else { return false }
            row = row.removing(button)
            return true
        }
    }
}

/// A place in the preview row: its button, draggable, or a faint dashed circle when empty.
/// Takes a dropped button, lighting up while one is over it.
private struct ButtonPlace: View {
    let button: MusicButton?
    let onDrop: (String?) -> Bool
    @State private var isTargeted = false

    var body: some View {
        Group {
            if let button {
                MusicButtonIcon(button: button)
                    .foregroundStyle(.white.opacity(0.85))
                    .draggable(button.rawValue) { MusicButtonIcon(button: button) }
                    .help("Drag onto another place, or down to Spare")
                    .accessibilityLabel(button.title)
            } else {
                Circle()
                    .strokeBorder(.white.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .frame(width: 22, height: 22)
                    .accessibilityLabel("Empty place")
            }
        }
        .frame(width: 30, height: 30)
        .background(Circle().fill(.white.opacity(isTargeted ? 0.2 : 0)))
        .contentShape(Circle())
        .dropDestination(for: String.self) { names, _ in onDrop(names.first) } isTargeted: { isTargeted = $0 }
    }
}

/// A button's symbol at the size the Music tab draws it.
private struct MusicButtonIcon: View {
    let button: MusicButton

    var body: some View {
        let isToggle = button == .shuffle || button == .repeatMode
        Image(systemName: button.symbolName)
            .font(.system(size: isToggle ? 14 : 17, weight: isToggle ? .semibold : .regular))
            .frame(width: 24, height: 24)
            .contentShape(Rectangle())
    }
}
