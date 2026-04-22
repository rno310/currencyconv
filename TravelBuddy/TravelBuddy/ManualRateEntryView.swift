import SwiftUI

struct ManualRateEntryView: View {
    @ObservedObject var store: CurrencyStore
    @Environment(\.dismiss) private var dismiss
    @State private var rateText = ""

    private var parsedRate: Double? {
        guard let v = Double(rateText), v > 0 else { return nil }
        return v
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Text("Enter the exchange rate manually. Useful when you have no internet access.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(spacing: 12) {
                    Text("1 \(store.fromCurrency.code) =")
                        .font(.title3)
                    TextField("0.00", text: $rateText)
                        .keyboardType(.decimalPad)
                        .font(.title3)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.roundedBorder)
                    Text(store.toCurrency.code)
                        .font(.title3)
                }
                .padding(.horizontal)

                if store.isManualRate {
                    Button("Clear Manual Rate", role: .destructive) {
                        store.clearManualRate()
                        dismiss()
                    }
                }

                Spacer()
            }
            .padding(.top, 32)
            .navigationTitle("Manual Rate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        if let rate = parsedRate {
                            store.setManualRate(rate)
                            dismiss()
                        }
                    }
                    .disabled(parsedRate == nil)
                }
            }
        }
    }
}
