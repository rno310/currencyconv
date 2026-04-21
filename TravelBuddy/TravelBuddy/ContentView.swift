import SwiftUI

private enum ConversionField { case from, to }

struct ContentView: View {
    @StateObject private var store = CurrencyStore()

    @State private var fromText = ""
    @State private var toText   = ""
    @FocusState private var focused: ConversionField?

    @State private var showFromPicker = false
    @State private var showToPicker   = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                inputRow(
                    label: "FROM",
                    currency: store.fromCurrency,
                    text: $fromText,
                    field: .from,
                    onPickerTap: { showFromPicker = true }
                )

                rateRow

                inputRow(
                    label: "TO",
                    currency: store.toCurrency,
                    text: $toText,
                    field: .to,
                    onPickerTap: { showToPicker = true }
                )

                Spacer()

                lastUpdatedLabel
                    .padding(.bottom, 32)
            }
            .navigationTitle("Travel Buddy · Currency Converter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { refreshButton }
            }
            .sheet(isPresented: $showFromPicker) {
                CurrencyPickerView(selected: $store.fromCurrency, excluding: store.toCurrency)
            }
            .sheet(isPresented: $showToPicker) {
                CurrencyPickerView(selected: $store.toCurrency, excluding: store.fromCurrency)
            }
            // Bidirectional live conversion — each field only drives when it has focus
            .onChange(of: fromText) { _, new in
                guard focused == .from else { return }
                toText = converted(new, from: store.fromCurrency, to: store.toCurrency)
            }
            .onChange(of: toText) { _, new in
                guard focused == .to else { return }
                fromText = converted(new, from: store.toCurrency, to: store.fromCurrency)
            }
            // Recalculate when currency selection or rates change
            .onChange(of: store.fromCurrency) { _, _ in recalculate() }
            .onChange(of: store.toCurrency)   { _, _ in recalculate() }
            .onChange(of: store.lastUpdated)  { _, _ in recalculate() }
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func inputRow(
        label: String,
        currency: Currency,
        text: Binding<String>,
        field: ConversionField,
        onPickerTap: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            HStack(spacing: 12) {
                Button(action: onPickerTap) {
                    HStack(spacing: 8) {
                        Text(currency.flag).font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currency.code)
                                .font(.headline)
                            Text(currency.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                TextField("0", text: text)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 36, weight: .light, design: .rounded))
                    .multilineTextAlignment(.trailing)
                    .focused($focused, equals: field)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
    }

    private var rateRow: some View {
        HStack {
            Group {
                if let r = store.rateDisplay {
                    Text(r)
                        .foregroundStyle(store.isRateStale ? .red : .secondary)
                } else {
                    Text(store.isRefreshing ? "Fetching rates…" : "Rate unavailable")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.caption)

            Spacer()

            Button {
                let tmpFrom = fromText
                let tmpTo   = toText
                store.swap()
                fromText = tmpTo
                toText   = tmpFrom
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var lastUpdatedLabel: some View {
        Group {
            if store.isCacheExpired {
                Text("Rates may be outdated — please connect to refresh")
                    .foregroundStyle(.red)
            } else if let d = store.lastUpdated {
                Text("Rates updated \(d.formatted(.relative(presentation: .named)))")
                    .foregroundStyle(store.isRateStale ? .red : Color(.tertiaryLabel))
            } else {
                Text(store.isRefreshing ? "Fetching rates…" : "No rates cached — connect to download")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption2)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20)
    }

    private var refreshButton: some View {
        Button { store.refresh() } label: {
            if store.isRefreshing {
                ProgressView().controlSize(.small)
            } else {
                Image(systemName: "arrow.clockwise")
            }
        }
        .disabled(store.isRefreshing)
    }

    // MARK: - Helpers

    private func converted(_ text: String, from: Currency, to: Currency) -> String {
        guard !text.isEmpty,
              let amount = Double(text),
              let result = store.convert(amount: amount, from: from, to: to)
        else { return "" }
        return formatAmount(result)
    }

    private func recalculate() {
        if focused == .to, !toText.isEmpty {
            fromText = converted(toText, from: store.toCurrency, to: store.fromCurrency)
        } else if !fromText.isEmpty {
            toText = converted(fromText, from: store.fromCurrency, to: store.toCurrency)
        }
    }

    private func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        if value >= 1 {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
        } else if value >= 0.01 {
            formatter.minimumFractionDigits = 4
            formatter.maximumFractionDigits = 4
        } else {
            formatter.minimumFractionDigits = 6
            formatter.maximumFractionDigits = 6
        }
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}
