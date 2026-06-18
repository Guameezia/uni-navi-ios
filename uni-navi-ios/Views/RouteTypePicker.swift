import SwiftUI

struct RouteTypePicker: View {
    let selected: RouteMode
    let onSelect: (RouteMode) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(RouteMode.allCases, id: \.self) { mode in
                Button {
                    onSelect(mode)
                } label: {
                    Text(mode == .comfort ? "Comfort" : "Fast")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selected == mode ? Color.accentBlue : Color.clear)
                        .foregroundStyle(selected == mode ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentBlue, lineWidth: 1))
    }
}
