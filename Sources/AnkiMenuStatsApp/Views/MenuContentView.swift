import SwiftUI

struct MenuContentView: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            topHeader

            VStack(spacing: 9) {
                metricRow(
                    icon: "list.bullet.rectangle.portrait",
                    title: "Cards Left",
                    value: viewModel.remainingDescription
                )

                metricRow(
                    icon: "timer",
                    title: "Time Reviewed",
                    value: viewModel.studiedTimeDescription
                )
            }
            .padding(12)
            .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            if let error = viewModel.errorDescription {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(Color(red: 1, green: 0.45, blue: 0.45))
                    .lineLimit(3)
            }

            Divider()
                .overlay(Color.white.opacity(0.14))

            HStack(spacing: 10) {
                actionButton("Refresh", icon: "arrow.clockwise", action: viewModel.refresh)
                actionButton("Open Anki", icon: "arrow.up.forward.app", action: viewModel.openAnki)
                Spacer(minLength: 0)
                Button("Quit", action: viewModel.quitApp)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .buttonStyle(.plain)
            }

            Text(viewModel.lastUpdatedDescription)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(16)
        .frame(width: 320)
        .background(
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.11, blue: 0.16), Color(red: 0.12, green: 0.16, blue: 0.24)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var topHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Anki")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                Text("Today")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 0) {
                Text(viewModel.menuBarTitle)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("due")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .frame(minWidth: 64, alignment: .trailing)
            .contentTransition(.numericText())
        }
    }

    private func metricRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 18)

            Text(title)
                .font(.callout.weight(.medium))
                .foregroundStyle(.white.opacity(0.85))

            Spacer(minLength: 0)

            Text(value)
                .font(.callout.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
    }

    private func actionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.callout.weight(.medium))
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
        .foregroundStyle(.white)
    }
}
