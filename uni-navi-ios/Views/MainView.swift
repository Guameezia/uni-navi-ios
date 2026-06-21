import SwiftUI

struct MainView: View {
    @StateObject private var vm = NavigationViewModel()
    @State private var showAlert = false
    @State private var sheetDragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let sheetHeight = max(60, geo.size.height * vm.sheetDetent.heightFraction(for: vm.uiPhase) - sheetDragOffset)
            let bottomInset = sheetHeight + 8

            ZStack(alignment: .bottom) {
                FloorMapView(vm: vm)
                    .ignoresSafeArea()

                if vm.uiPhase == .navigating {
                    RouteSummaryBar(vm: vm) {
                        vm.beginEditingRoute()
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }

                if !vm.segments.isEmpty {
                    FloorPicker(
                        floors: vm.availableFloors,
                        activeFloor: vm.activeFloor,
                        onSelect: { vm.switchFloor($0) },
                        floating: true
                    )
                    .frame(maxWidth: min(geo.size.width * 0.7, 280))
                    .padding(.leading, 12)
                    .padding(.bottom, bottomInset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }

                MapControlsOverlay(vm: vm)
                    .padding(.trailing, 12)
                    .padding(.bottom, bottomInset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

                NavigationBottomSheet(
                    vm: vm,
                    onSearch: {
                        if !vm.searchRoute() {
                            showAlert = true
                        }
                    },
                    dragOffset: $sheetDragOffset,
                    availableHeight: geo.size.height
                )
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
