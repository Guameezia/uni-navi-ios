import SwiftUI

extension Color {
    static let accentBlue = Color(red: 0.043, green: 0.420, blue: 0.796)
    static let routeGreen = Color(red: 0.086, green: 0.639, blue: 0.165)
    static let routeEndBlue = Color(red: 0.114, green: 0.306, blue: 0.847)
}

enum AppTheme {
    static let cornerRadius: CGFloat = 12
    static let primaryButtonHeight: CGFloat = 48
    static let mapControlSize: CGFloat = 44
    static let sheetHandleWidth: CGFloat = 36
    static let sheetHandleHeight: CGFloat = 5
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.primaryButtonHeight)
            .background(Color.accentBlue.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }
}

struct MapControlButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.primary)
            .frame(width: AppTheme.mapControlSize, height: AppTheme.mapControlSize)
            .background(.regularMaterial, in: Circle())
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

struct FloatingPanelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
    }
}

extension View {
    func floatingPanel() -> some View {
        modifier(FloatingPanelStyle())
    }
}

struct SheetDragHandle: View {
    var body: some View {
        Capsule()
            .fill(Color(.systemGray3))
            .frame(width: AppTheme.sheetHandleWidth, height: AppTheme.sheetHandleHeight)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }
}
