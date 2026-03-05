import SwiftUI

// MARK: – Wezan Logo Drop
struct WazanDrop: View {
    var size: CGFloat = 24
    var body: some View {
        Image(systemName: "drop.fill")
            .resizable().scaledToFit().frame(width: size, height: size)
            .foregroundStyle(LinearGradient(colors: [.wPrimary, .wAccent], startPoint: .top, endPoint: .bottom))
    }
}

// MARK: – Card (matches white rounded cards in design)
struct WCard<C: View>: View {
    var padding: CGFloat = 16
    var bg: Color = .wCard
    @ViewBuilder var content: () -> C
    var body: some View {
        content()
            .padding(padding)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: WRadius.lg, style: .continuous))
    }
}

// MARK: – Section header  (e.g. "اليوم", "أمس")
struct WSectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.wCaption)
            .foregroundColor(.wLabelSec)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, WSpacing.lg)
            .padding(.top, WSpacing.md)
            .padding(.bottom, WSpacing.xs)
    }
}

// MARK: – Status chip (مرتفع / طبيعي / منخفض)
struct WStatusChip: View {
    let status: GlucoseStatus
    var body: some View {
        Label(status.label, systemImage: status.sfSymbol)
            .font(.wBadge)
            .foregroundColor(status.color)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(status.chipBg)
            .clipShape(Capsule())
    }
}

// MARK: – Primary Button
struct WPrimaryBtn: View {
    let title : String
    let icon  : String?
    let action: () -> Void
    init(_ t: String, icon: String? = nil, _ a: @escaping () -> Void) { title = t; self.icon = icon; action = a }
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon).font(.system(size: 15, weight: .semibold)) }
                Text(title)
            }
                
                .font(.wButton)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(LinearGradient(colors: [.wPrimary, .wAccent], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: WRadius.md, style: .continuous))
                .shadow(color: Color.wPrimary.opacity(0.28), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: – Secondary (outline) button
struct WSecondaryBtn: View {
    let title : String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.wButton)
                .foregroundColor(.wPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.wTint1)
                .clipShape(RoundedRectangle(cornerRadius: WRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: – Setting Row  (used in Settings)
struct WSettingRow<T: View>: View {
    let icon    : String
    let iconBg  : Color
    let title   : String
    let subtitle: String?
    @ViewBuilder var trailing: () -> T

    init(icon: String, iconBg: Color = .wTint1, title: String, subtitle: String? = nil, @ViewBuilder trailing: @escaping () -> T) {
        self.icon = icon; self.iconBg = iconBg; self.title = title; self.subtitle = subtitle; self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous).fill(iconBg).frame(width: 32, height: 32)
                Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundColor(.wPrimary)
            }
            VStack(alignment: .trailing, spacing: 1) {
                Text(title).font(.wListBold).foregroundColor(.wLabel)
                if let s = subtitle { Text(s).font(.wCaption).foregroundColor(.wLabelSec) }
            }
            Spacer()
            trailing()
        }
        .padding(.horizontal, WSpacing.md)
        .padding(.vertical, 12)
    }
}

// MARK: – List Row (dose item)
struct DoseListRow: View {
    let dose: DoseRecord
    let unit: GlucoseUnit

    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            ZStack {
                Circle().fill(dose.insulinType.color.opacity(0.12)).frame(width: 36, height: 36)
                Image(systemName: dose.insulinType.sfSymbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(dose.insulinType.color)
            }

            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 4) {
                    Text("\(Int(dose.units)) وحدات")
                        .font(.wListBold).foregroundColor(.wLabel)
                    Text(dose.insulinType.rawValue)
                        .font(.wCaption).foregroundColor(.wLabelSec)
                }
                if !dose.note.isEmpty {
                    Text(dose.note).font(.wCaption).foregroundColor(.wLabelSec)
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 3) {
                Text(timeStr(dose.timestamp))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.wLabelSec)
                if let g = dose.glucoseAtDose {
                    Text(unit.displayString(g))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(GlucoseStatus(mgdL: g).color)
                }
            }
        }
        .padding(.horizontal, WSpacing.md)
        .padding(.vertical, 11)
    }

    private func timeStr(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: d)
    }
}

// MARK: – Glucose Sparkline
struct GlucoseSparkline: View {
    let readings   : [GlucoseReading]
    let unit       : GlucoseUnit
    let targetLow  : Double
    let targetHigh : Double
    var height     : CGFloat = 100

    private var vals: [Double] { readings.map { unit.display($0.valueMgdL) } }
    private var minV: Double { (vals.min() ?? 50)  - 8 }
    private var maxV: Double { (vals.max() ?? 200) + 8 }
    private func ny(_ v: Double) -> Double { (v - minV) / max(maxV - minV, 1) }

    var body: some View {
        Canvas { ctx, size in
            guard readings.count >= 2 else { return }
            let w = size.width, h = size.height

            func pt(_ i: Int) -> CGPoint {
                CGPoint(
                    x: CGFloat(i) / CGFloat(readings.count - 1) * w,
                    y: h - CGFloat(ny(vals[i])) * h
                )
            }

            // Target band
            let tL = unit.display(targetLow);  let tH = unit.display(targetHigh)
            let bandY  = h - CGFloat(ny(tH)) * h
            let bandH  = h - CGFloat(ny(tL)) * h - bandY
            ctx.fill(Path(CGRect(x: 0, y: bandY, width: w, height: bandH)), with: .color(.wNormal.opacity(0.07)))

            // Dashes
            for (v, c) in [(tH, Color.wNormal), (tL, Color.wLow)] {
                let y2 = h - CGFloat(ny(v)) * h
                var dash = Path(); dash.move(to: CGPoint(x: 0, y: y2)); dash.addLine(to: CGPoint(x: w, y: y2))
                ctx.stroke(dash, with: .color(c.opacity(0.4)), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }

            // Area
            var area = Path()
            area.move(to: CGPoint(x: 0, y: h))
            area.addLine(to: pt(0))
            for i in 1 ..< readings.count { area.addLine(to: pt(i)) }
            area.addLine(to: CGPoint(x: w, y: h))
            area.closeSubpath()
            ctx.fill(area, with: .linearGradient(
                Gradient(colors: [Color.wPrimary.opacity(0.18), .clear]),
                startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: h)
            ))

            // Line
            var line = Path()
            line.move(to: pt(0))
            for i in 1 ..< readings.count { line.addLine(to: pt(i)) }
            ctx.stroke(line, with: .color(.wPrimary), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

            // Dots
            for i in readings.indices {
                let p = pt(i); let isLast = i == readings.count - 1
                let r: CGFloat = isLast ? 5 : 3
                let dot = Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r*2, height: r*2))
                ctx.fill(dot, with: .color(isLast ? Color.wPrimary : Color.wCard))
                ctx.stroke(dot, with: .color(.wPrimary), style: StrokeStyle(lineWidth: 1.5))
            }
        }
        .frame(height: height)
    }
}

// MARK: – Share sheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: – Toast
struct WToast: View {
    let msg: String
    var body: some View {
        Text(msg)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 20).padding(.vertical, 11)
            .background(Color.wPrimary)
            .clipShape(Capsule())
            .shadow(color: Color.wPrimary.opacity(0.35), radius: 10, x: 0, y: 5)
    }
}
