import SwiftUI

struct RouteSummaryBar: View {
    @ObservedObject var vm: NavigationViewModel
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "circle.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.routeGreen)

                Text(vm.startQuery)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                Image(systemName: "arrow.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Image(systemName: "mappin.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.routeEndBlue)

                Text(vm.destinationQuery)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                Spacer(minLength: 4)

                Button("Edit", action: onEdit)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accentBlue)
            }

            if vm.hasMultipleRoutes {
                RouteTypePicker(selected: vm.selectedRouteType) { mode in
                    vm.selectRouteType(mode)
                }
            }

            Text(vm.statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: .black.opacity(0.1), radius: 6, y: 2)
    }
}
