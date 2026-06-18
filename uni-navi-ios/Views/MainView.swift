import SwiftUI

struct MainView: View {
    @StateObject private var vm = NavigationViewModel()
    @State private var showAlert = false

    var body: some View {
        VStack(spacing: 0) {
            RouteSearchSection(vm: vm, onSearch: {
                if !vm.searchRoute() {
                    showAlert = true
                }
            })
            .padding(.horizontal, 12)
            .padding(.top, 8)

            StatusBar(text: vm.statusText)

            if vm.hasMultipleRoutes {
                RouteTypePicker(selected: vm.selectedRouteType) { mode in
                    vm.selectRouteType(mode)
                }
                .padding(.horizontal, 12)
            }

            FloorMapView(vm: vm)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)

            if !vm.segments.isEmpty {
                FloorPicker(
                    floors: vm.availableFloors,
                    activeFloor: vm.activeFloor,
                    onSelect: { vm.switchFloor($0) }
                )
                .padding(.horizontal, 12)
            }

            if !vm.steps.isEmpty {
                DirectionsPanel(
                    steps: vm.steps,
                    expanded: $vm.directionsExpanded
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear { vm.loadGraph() }
        .alert("Please select a valid start point and destination", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        }
    }
}

#Preview {
    MainView()
}
