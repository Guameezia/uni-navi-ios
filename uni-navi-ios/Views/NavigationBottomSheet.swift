import SwiftUI

struct NavigationBottomSheet: View {
    @ObservedObject var vm: NavigationViewModel
    let onSearch: () -> Void
    @Binding var dragOffset: CGFloat
    let availableHeight: CGFloat

    private var targetHeight: CGFloat {
        max(60, availableHeight * vm.sheetDetent.heightFraction(for: vm.uiPhase) - dragOffset)
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetDragHandle()
                .gesture(sheetDragGesture)

            Group {
                switch vm.uiPhase {
                case .idle, .searching:
                    searchContent
                case .navigating:
                    if vm.sheetDetent == .collapsed {
                        collapsedNavigatingContent
                    } else {
                        directionsContent
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(height: targetHeight)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 12, y: -4)
        .animation(.easeInOut(duration: 0.25), value: vm.sheetDetent)
        .animation(.easeInOut(duration: 0.25), value: vm.uiPhase)
    }

    private var searchContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Plan Route")
                    .font(.headline)

                Text(vm.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                RouteSearchSection(vm: vm, onSearch: onSearch)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private var collapsedNavigatingContent: some View {
        Button {
            withAnimation { vm.sheetDetent = .medium }
        } label: {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundStyle(Color.accentBlue)
                Text("\(vm.steps.count) steps")
                    .font(.subheadline.weight(.semibold))
                Text("· Swipe up for directions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.up")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .buttonStyle(.plain)
    }

    private var directionsContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Directions")
                    .font(.headline)
                Spacer()
                if vm.sheetDetent == .large {
                    Button {
                        withAnimation { vm.sheetDetent = .medium }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        withAnimation { vm.sheetDetent = .large }
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            DirectionsPanel(steps: vm.steps, expanded: .constant(true), embeddedInSheet: true)
        }
    }

    private var sheetDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation.height
            }
            .onEnded { value in
                let predicted = value.predictedEndTranslation.height
                let threshold: CGFloat = 50

                withAnimation(.easeInOut(duration: 0.25)) {
                    if vm.uiPhase == .navigating {
                        if predicted < -threshold {
                            vm.sheetDetent = vm.sheetDetent == .collapsed ? .medium : .large
                        } else if predicted > threshold {
                            vm.sheetDetent = vm.sheetDetent == .large ? .medium : .collapsed
                        }
                    } else {
                        if predicted < -threshold {
                            vm.sheetDetent = .large
                        } else if predicted > threshold {
                            vm.sheetDetent = .medium
                        }
                    }
                    dragOffset = 0
                }
            }
    }
}
