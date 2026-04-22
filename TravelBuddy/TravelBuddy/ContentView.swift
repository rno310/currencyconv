import SwiftUI

private enum ConversionField { case from, to }

struct ContentView: View {
    @StateObject private var store = CurrencyStore()

    @State private var fromText = ""
    @State private var toText   = ""
    @FocusState private var focused: ConversionField?

    @State private var showFromPicker      = false
    @State private var showToPicker        = false
    @State private var showManualRateEntry = false

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
                    .padding(.bottom, 4)

                Text("Exchange rates by ExchangeRate-API")
                    .font(.caption2)
                    .foregroundStyle(Color(.tertiaryLabel))
                    .padding(.bottom, 32)
            }
            .navigationTitle("Exchange-o-matic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { refreshButton }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        fromText = ""
                        toText = ""
                    } label: {
                        Image(systemName: "xmark.circle")
                    }
                    .disabled(fromText.isEmpty && toText.isEmpty)
                }
            }
            // Recalculate after picker dismissal so the swap button's
            // synchronous text swap is never disrupted by a mid-action recalc.
            .sheet(isPresented: $showFromPicker, onDismiss: recalculate) {
                CurrencyPickerView(selected: $store.fromCurrency, excluding: store.toCurrency)
            }
            .sheet(isPresented: $showToPicker, onDismiss: recalculate) {
                CurrencyPickerView(selected: $store.toCurrency, excluding: store.fromCurrency)
            }
            // Bidirectional live conversion — each field only drives when focused.
            // applyGrouping reformats with thousand separators as the user types;
            // returning early triggers a second onChange with the formatted text.
            .onChange(of: fromText) { _, new in
                guard focused == .from else { return }
                let reformatted = applyGrouping(new)
                if reformatted != new { fromText = reformatted; return }
                toText = converted(new, from: store.fromCurrency, to: store.toCurrency)
            }
            .onChange(of: toText) { _, new in
                guard focused == .to else { return }
                let reformatted = applyGrouping(new)
                if reformatted != new { toText = reformatted; return }
                fromText = converted(new, from: store.toCurrency, to: store.fromCurrency)
            }
            .onChange(of: store.lastUpdated) { _, _ in recalculate() }
            .sheet(isPresented: $showManualRateEntry) {
                ManualRateEntryView(store: store)
            }
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
                    .font(.system(size: 48, weight: .light, design: .rounded))
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
                    Text(r).foregroundStyle(.secondary)
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
            } else if let d = store.effectiveLastUpdated {
                let prefix = store.isManualRate ? "Rates manually updated" : "Rates updated"
                let label  = "\(prefix) \(d.formatted(.relative(presentation: .named)))"
                if store.isRateStale {
                    Button { showManualRateEntry = true } label: {
                        Text("\(label) · Manual entry?")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(label)
                        .foregroundStyle(Color(.tertiaryLabel))
                }
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

    /// Adds thousand-separator grouping while preserving a trailing decimal point
    /// so the user can keep typing digits after ".".
    private func applyGrouping(_ raw: String) -> String {
        guard !raw.isEmpty else { return raw }
        let stripped = raw.replacingOccurrences(of: ",", with: "")
        let parts = stripped.components(separatedBy: ".")
        let intStr = parts[0]
        guard let intVal = Double(intStr.isEmpty ? "0" : intStr) else { return raw }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_US")
        let formattedInt = formatter.string(from: NSNumber(value: intVal)) ?? intStr
        return parts.count > 1 ? formattedInt + "." + parts[1] : formattedInt
    }

    /// Strips commas before parsing so formatted values (e.g. "1,234.56") round-trip correctly.
    private func converted(_ text: String, from: Currency, to: Currency) -> String {
        let stripped = text.replacingOccurrences(of: ",", with: "")
        guard !stripped.isEmpty,
              let amount = Double(stripped),
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
        formatter.locale = Locale(identifier: "en_US")
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
