import SwiftUI

// MARK: - Cost Line Item Row

struct CostLineItemRow: View {

    let item: CostLineItem

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                // Category icon
                Image(systemName: item.category.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appTextTertiary)
                    .frame(width: 20)

                // Name
                Text(item.name)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(1)

                // Quantity badge
                if item.quantity > 1 {
                    Text("x\(item.quantity)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.appAccent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.appAccent.opacity(0.15), in: Capsule())
                }

                Spacer()

                // Price
                Text(item.formattedTotalPrice)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.appAccent)
            }
            .padding(.vertical, 8)

            // Divider
            Rectangle()
                .fill(Color.appDivider)
                .frame(height: 0.5)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        VStack {
            CostLineItemRow(
                item: CostLineItem(
                    category: .equipment,
                    name: "Rogue Power Rack",
                    quantity: 1,
                    unitPrice: 1299.00
                )
            )
            CostLineItemRow(
                item: CostLineItem(
                    category: .flooring,
                    name: "Rubber Gym Flooring",
                    quantity: 215,
                    unitPrice: 6.50
                )
            )
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
