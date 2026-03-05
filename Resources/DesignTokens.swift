//
//  DesignTokens.swift
//  wezanapp
//
//  Created by raghad alenezi on 16/09/1447 AH.
//
import SwiftUI

// MARK: – Wezan Design System v2
// مطابق 100% للتصميم مع دعم كامل للدارك مود عبر UIColor adaptive

extension Color {

    // ── Brand
    static let wPrimary = Color(adaptive: "#7B6FCC", dark: "#9D92E0")
    static let wAccent  = Color(adaptive: "#A594F9", dark: "#B8AEFF")

    // ── Tints (الأسطح البنفسجية الفاتحة)
    static let wTint1   = Color(adaptive: "#EDE9FF", dark: "#252244") // surface فاتح
    static let wTint2   = Color(adaptive: "#F3F1FF", dark: "#1E1B38") // surface أفتح

    // ── Backgrounds
    static let wBg      = Color(adaptive: "#F2F2F7", dark: "#0C0C1A") // iOS system grouped
    static let wBgBase  = Color(adaptive: "#FFFFFF", dark: "#111128") // كارد أبيض

    // ── Cards & Surfaces
    static let wCard       = Color(adaptive: "#FFFFFF",  dark: "#1C1A32")
    static let wCardInner  = Color(adaptive: "#F7F5FF",  dark: "#252244")
    static let wCardStroke = Color(adaptive: "#E8E5F5",  dark: "#2E2B4A")

    // ── Text
    static let wLabel        = Color(adaptive: "#1C1C1E", dark: "#F2F2F7") // iOS primary label
    static let wLabelSec     = Color(adaptive: "#3C3C43", dark: "#EBEBF5").opacity(0.6)
    static let wLabelTer     = Color(adaptive: "#3C3C43", dark: "#EBEBF5").opacity(0.3)
    static let wLabelQ       = Color(adaptive: "#3C3C43", dark: "#EBEBF5").opacity(0.18)

    // ── Semantic
    static let wLow    = Color(adaptive: "#FF3B30", dark: "#FF453A") // iOS red
    static let wHigh   = Color(adaptive: "#FF9500", dark: "#FF9F0A") // iOS orange
    static let wNormal = Color(adaptive: "#34C759", dark: "#30D158") // iOS green
    static let wBlue   = Color(adaptive: "#007AFF", dark: "#0A84FF") // iOS blue

    // ── Separator
    static let wSep    = Color(adaptive: "#C6C6C8", dark: "#38383A")
}

extension Color {
    init(adaptive light: String, dark: String) {
        self.init(uiColor: UIColor(
            light: UIColor(hex: light),
            dark:  UIColor(hex: dark)
        ))
    }
}

extension UIColor {
    convenience init(light: UIColor, dark: UIColor) {
        self.init { $0.userInterfaceStyle == .dark ? dark : light }
    }
    convenience init(hex: String) {
        var s = hex.trimmingCharacters(in: .alphanumerics.inverted)
        if s.count == 6 { s = "FF" + s }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self.init(
            red  : CGFloat((v >> 16) & 0xFF) / 255,
            green: CGFloat((v >>  8) & 0xFF) / 255,
            blue : CGFloat( v        & 0xFF) / 255,
            alpha: CGFloat((v >> 24) & 0xFF) / 255
        )
    }
}

// MARK: – Typography — مطابق للتصميم
extension Font {
    // عناوين الصفحات
    static let wNavTitle   = Font.system(size: 28, weight: .bold,    design: .rounded)
    // عنوان الكارد
    static let wCardTitle  = Font.system(size: 17, weight: .semibold,design: .rounded)
    // الرقم الكبير (210)
    static let wGlucoseLg  = Font.system(size: 56, weight: .bold,    design: .rounded)
    // وحدة القياس
    static let wUnit       = Font.system(size: 15, weight: .medium,  design: .rounded)
    // label صغير
    static let wCaption    = Font.system(size: 12, weight: .medium,  design: .rounded)
    // خط القائمة
    static let wListItem   = Font.system(size: 15, weight: .regular, design: .rounded)
    static let wListBold   = Font.system(size: 15, weight: .semibold,design: .rounded)
    // badge
    static let wBadge      = Font.system(size: 11, weight: .semibold,design: .rounded)
    // زر رئيسي
    static let wButton     = Font.system(size: 15, weight: .semibold,design: .rounded)
    // body
    static let wBody       = Font.system(size: 14, weight: .regular, design: .rounded)
}

// MARK: – Corner Radii (Apple HIG)
enum WRadius {
    static let xs  : CGFloat = 8
    static let sm  : CGFloat = 12
    static let md  : CGFloat = 16
    static let lg  : CGFloat = 20
    static let xl  : CGFloat = 26
    static let full: CGFloat = 999
}

// MARK: – Spacing
enum WSpacing {
    static let xs  : CGFloat = 4
    static let sm  : CGFloat = 8
    static let md  : CGFloat = 16
    static let lg  : CGFloat = 20
    static let xl  : CGFloat = 28
}

