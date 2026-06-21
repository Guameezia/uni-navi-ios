import SwiftUI

struct MapControlsOverlay: View {
    @ObservedObject var vm: NavigationViewModel

    var body: some View {
        VStack(spacing: 8) {
            Button {
                vm.zoomMap(by: 1.25)
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(MapControlButtonStyle())

            Button {
                vm.zoomMap(by: 0.8)
            } label: {
                Image(systemName: "minus")
            }
            .buttonStyle(MapControlButtonStyle())

            Button {
                vm.resetMapTransform()
            } label: {
                Image(systemName: "location.fill")
            }
            .buttonStyle(MapControlButtonStyle())
        }
    }
}
