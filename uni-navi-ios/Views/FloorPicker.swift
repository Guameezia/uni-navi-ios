import SwiftUI

struct FloorPicker: View {
    let floors: [String]
    let activeFloor: String
    let onSelect: (String) -> Void
    var floating: Bool = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(floors, id: \.self) { floor in
                    Button {
                        onSelect(floor)
                    } label: {
                        Text(floor)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(activeFloor == floor ? Color.accentBlue : Color(.tertiarySystemGroupedBackground))
                            .foregroundStyle(activeFloor == floor ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .modifier(FloorPickerContainerModifier(floating: floating))
    }
}

private struct FloorPickerContainerModifier: ViewModifier {
    let floating: Bool

    func body(content: Content) -> some View {
        if floating {
            content.floatingPanel()
        } else {
            content
        }
    }
}
