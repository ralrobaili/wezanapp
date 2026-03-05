//
//  PDFExportService.swift
//  wezanapp
//
//  Created by raghad alenezi on 16/09/1447 AH.
//

import UIKit
import PDFKit

final class PDFExportService {

    static func generate(doses: [DoseRecord], readings: [GlucoseReading], range: ExportRange, unit: GlucoseUnit) -> URL? {
        let W: CGFloat = 595, H: CGFloat = 842, M: CGFloat = 44
        let cW = W - M * 2
        let purple = UIColor(hex: "#7B6FCC")

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: W, height: H),
            format: {
                let f = UIGraphicsPDFRendererFormat()
                f.documentInfo = [kCGPDFContextTitle as String: "تقرير وزان"]
                return f
            }()
        )

        let dFmt = DateFormatter(); dFmt.locale = Locale(identifier: "ar_SA"); dFmt.dateFormat = "d MMM yyyy"
        let tFmt = DateFormatter(); tFmt.locale = Locale(identifier: "ar_SA"); tFmt.dateFormat = "d MMM – HH:mm"

        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = 0

            // ── Header bar
            purple.withAlphaComponent(0.09).setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: W, height: 88))
            y = 20

            let titleAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                .foregroundColor: purple
            ]
            "وزان  —  تقرير الإنسولين والسكر".draw(in: CGRect(x: M, y: y, width: cW, height: 32), withAttributes: titleAttr)
            y += 36

            let subAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.secondaryLabel
            ]
            "\(range.rawValue):  \(dFmt.string(from: range.startDate)) — \(dFmt.string(from: .now))".draw(
                in: CGRect(x: M, y: y, width: cW, height: 18), withAttributes: subAttr)
            y = 108

            // ── Summary cards
            let stats: [(String, String)] = [
                ("إجمالي الجرعات",  "\(doses.count) جرعة"),
                ("إجمالي الوحدات",  String(format: "%.0f وحدة", doses.reduce(0) { $0 + $1.units })),
                ("متوسط السكر",     readings.isEmpty ? "–" : {
                    let avg = readings.reduce(0.0) { $0 + $1.valueMgdL } / Double(readings.count)
                    return unit.displayString(avg) + " " + unit.label
                }()),
                ("قراءات السكر",    "\(readings.count)"),
            ]
            let bW = (cW - 3 * 10) / 4
            for (i, (lbl, val)) in stats.enumerated() {
                let bx = M + CGFloat(i) * (bW + 10)
                let br = CGRect(x: bx, y: y, width: bW, height: 58)
                purple.withAlphaComponent(0.07).setFill()
                UIBezierPath(roundedRect: br, cornerRadius: 10).fill()
                val.draw(in: CGRect(x: bx + 8, y: y + 8, width: bW - 16, height: 24),
                         withAttributes: [.font: UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .bold), .foregroundColor: purple])
                lbl.draw(in: CGRect(x: bx + 8, y: y + 34, width: bW - 16, height: 16),
                         withAttributes: [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: UIColor.secondaryLabel])
            }
            y += 74

            // ── Dose table header
            "سجل الجرعات".draw(in: CGRect(x: M, y: y, width: cW, height: 22),
                               withAttributes: [.font: UIFont.systemFont(ofSize: 14, weight: .semibold), .foregroundColor: purple])
            y += 28

            let cols: [(String, CGFloat)] = [
                ("التاريخ والوقت", 140), ("الوحدات", 55), ("النوع", 95), ("السكر", 90),
                ("الملاحظة", cW - 140 - 55 - 95 - 90)
            ]
            purple.withAlphaComponent(0.10).setFill()
            UIRectFill(CGRect(x: M, y: y, width: cW, height: 22))
            var cx = M
            for (h2, w2) in cols {
                h2.draw(in: CGRect(x: cx + 4, y: y + 4, width: w2 - 8, height: 14),
                        withAttributes: [.font: UIFont.systemFont(ofSize: 9, weight: .semibold), .foregroundColor: purple])
                cx += w2
            }
            y += 24

            for (idx, dose) in doses.prefix(60).enumerated() {
                if y > H - 50 { ctx.beginPage(); y = M }
                if idx.isMultiple(of: 2) {
                    purple.withAlphaComponent(0.03).setFill()
                    UIRectFill(CGRect(x: M, y: y, width: cW, height: 21))
                }
                let gStr: String = {
                    guard let g = dose.glucoseAtDose else { return "–" }
                    return unit.displayString(g) + " " + unit.label
                }()
                let cells = [tFmt.string(from: dose.timestamp), String(format: "%.0f", dose.units),
                             dose.insulinType.rawValue, gStr, dose.note.isEmpty ? "–" : dose.note]
                cx = M
                for (i, cell) in cells.enumerated() {
                    cell.draw(in: CGRect(x: cx + 4, y: y + 4, width: cols[i].1 - 8, height: 13),
                              withAttributes: [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: UIColor.darkText])
                    cx += cols[i].1
                }
                UIColor(hex: "#E8E5F5").setStroke()
                let sep = UIBezierPath(); sep.move(to: CGPoint(x: M, y: y + 21)); sep.addLine(to: CGPoint(x: M + cW, y: y + 21))
                sep.lineWidth = 0.4; sep.stroke()
                y += 22
            }

            // ── Footer
            "تم إنشاؤه بواسطة تطبيق وزان — يُستخدم للاطلاع الطبي فقط".draw(
                in: CGRect(x: M, y: H - 28, width: cW, height: 16),
                withAttributes: [.font: UIFont.systemFont(ofSize: 8), .foregroundColor: UIColor.tertiaryLabel])
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("wezan_\(Int(Date().timeIntervalSince1970)).pdf")
        try? data.write(to: url)
        return url
    }
}
