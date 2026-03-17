import SwiftUI

// MARK: - Cost Summary Card

struct CostSummaryCard: View {

    let grandTotal: String
    let equipmentTotal: String
    let finishesTotal: String
    let installationTotal: String

    var body: some View {
        VStack(spacing: 16) {
            // Estimated Total
            VStack(spacing: 4) {
                Text("Estimated Total")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)

                Text(grandTotal)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.appAccent, Color.appAccentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }

            // Breakdown subtitle
            HStack(spacing: 0) {
                breakdownChip("Equipment", value: equipmentTotal)
                Text(" | ")
                    .font(.caption2)
                    .foregroundStyle(Color.appTextTertiary)
                breakdownChip("Finishes", value: finishesTotal)
                Text(" | ")
                    .font(.caption2)
                    .foregroundStyle(Color.appTextTertiary)
                breakdownChip("Install", value: installationTotal)
            }

            // Disclaimer
            Text("Prices are estimates and may vary by location and vendor.")
                .font(.system(size: 10))
                .foregroundStyle(Color.appTextTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.appAccent.opacity(0.5),
                            Color.appAccentSecondary.opacity(0.3),
                            Color.appAccent.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }

    // MARK: - Breakdown Chip

    private func breakdownChip(_ label: String, value: String) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.appTextTertiary)
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.appTextSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        CostSummaryCard(
            grandTotal: "$8,425.00",
            equipmentTotal: "$5,200.00",
            finishesTotal: "$1,980.00",
            installationTotal: "$1,077.00"
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
