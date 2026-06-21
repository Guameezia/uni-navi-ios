import SwiftUI

struct RouteSearchSection: View {
    @ObservedObject var vm: NavigationViewModel
    let onSearch: () -> Void
    @FocusState private var focusedField: SearchFieldFocus?

    private enum SearchFieldFocus: Hashable {
        case start
        case destination
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 0) {
                    Circle()
                        .fill(Color.routeGreen)
                        .frame(width: 8, height: 8)
                        .padding(.top, 22)

                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 2, height: 36)

                    Circle()
                        .stroke(Color.routeEndBlue, lineWidth: 2)
                        .frame(width: 8, height: 8)
                        .padding(.bottom, 22)
                }

                VStack(spacing: 10) {
                    SearchField(
                        label: "From",
                        placeholder: "e.g., SA169",
                        text: Binding(
                            get: { vm.startQuery },
                            set: { vm.updateStartQuery($0) }
                        ),
                        suggestions: vm.startSuggestions,
                        focused: $focusedField,
                        focusValue: .start,
                        onSelect: { node in
                            vm.selectStart(node.id)
                            focusedField = .destination
                        }
                    )

                    SearchField(
                        label: "To",
                        placeholder: "e.g., SA301",
                        text: Binding(
                            get: { vm.destinationQuery },
                            set: { vm.updateDestinationQuery($0) }
                        ),
                        suggestions: vm.destinationSuggestions,
                        focused: $focusedField,
                        focusValue: .destination,
                        onSelect: { vm.selectDestination($0.id) }
                    )
                }
            }

            Button(action: onSearch) {
                Text("Go")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
}

private struct SearchField<F: Hashable>: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let suggestions: [Node]
    var focused: FocusState<F?>.Binding
    let focusValue: F
    let onSelect: (Node) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .focused(focused, equals: focusValue)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            if !suggestions.isEmpty {
                ScrollView {
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
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            if node.id != suggestions.last?.id {
                                Divider()
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
            }
        }
    }
}
