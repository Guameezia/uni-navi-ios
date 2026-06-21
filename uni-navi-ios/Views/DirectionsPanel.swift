import SwiftUI

struct DirectionsPanel: View {
    let steps: [String]
    @Binding var expanded: Bool
    var embeddedInSheet: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !embeddedInSheet {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
                } label: {
                    HStack {
                        Text("Directions")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }

            if expanded || embeddedInSheet {
                if !embeddedInSheet {
                    Divider()
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(idx + 1)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 20, height: 20)
                                    .background(Color.accentBlue)
                                    .clipShape(Circle())
                                Text(step)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(embeddedInSheet ? EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16) : EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                }
                .frame(maxHeight: embeddedInSheet ? nil : 160)
            }
        }
        .background {
            if !embeddedInSheet {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            }
        }
    }
}
