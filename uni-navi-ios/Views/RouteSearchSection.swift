import SwiftUI

struct RouteSearchSection: View {
    @Bindable var vm: NavigationViewModel
    let onSearch: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(spacing: 6) {
                SearchField(
                    label: "From",
                    placeholder: "e.g., SA169",
                    text: Binding(
                        get: { vm.startQuery },
                        set: { vm.updateStartQuery($0) }
                    ),
                    suggestions: vm.startSuggestions,
                    onSelect: { vm.selectStart($0.id) }
                )

                SearchField(
                    label: "To",
                    placeholder: "e.g., SA169",
                    text: Binding(
                        get: { vm.destinationQuery },
                        set: { vm.updateDestinationQuery($0) }
                    ),
                    suggestions: vm.destinationSuggestions,
                    onSelect: { vm.selectDestination($0.id) }
                )
            }

            Button(action: onSearch) {
                Text("Go")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Color.accentBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.top, 16)
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct SearchField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let suggestions: [Node]
    let onSelect: (Node) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            if !suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(suggestions) { node in
                        Button {
                            onSelect(node)
                        } label: {
                            HStack {
                                Text(node.label)
                                    .font(.subheadline)
                                Spacer()
                                Text(node.id)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                        if node.id != suggestions.last?.id {
                            Divider()
                        }
                    }
                }
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
            }
        }
    }
}
