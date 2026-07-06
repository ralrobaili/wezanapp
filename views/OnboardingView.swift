//
//  OnboardingView.swift
//  wezanapp
//
//  Created by raghad alenezi on 16/09/1447 AH.
//

import SwiftUI

struct OnboardingView: View {

    @EnvironmentObject var health  : HealthKitService
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var page = 0

    private let pages: [OnboardPage] = [
        OnboardPage(
            icon    : "drop.fill",
            iconColor: Color(adaptive: "#7B6FCC", dark: "#9D92E0"),
            title   : "أهلاً في وزان",
            body    : "تطبيقك الشخصي لمتابعة جرعات الإنسولين ومستوى السكر يومياً بكل سهولة.",
            isLogo  : true
        ),
        OnboardPage(
            icon    : "heart.fill",
            iconColor: .wLow,
            title   : "متصل بـ Apple Health",
            body    : "وزان يقرأ قراءات السكر تلقائياً من Apple Health ويعرضها لك لحظة بلحظة.",
            isLogo  : false
        ),
        OnboardPage(
            icon    : "syringe.fill",
            iconColor: .wPrimary,
            title   : "سجّل جرعاتك بسهولة",
            body    : "اضغط \"تسجيل جرعة جديدة\" في أي وقت لتسجيل نوع الإنسولين وعدد الوحدات.",
            isLogo  : false
        ),
        OnboardPage(
            icon    : "waveform",
            iconColor: .wAccent,
            title   : "سيري يسجّل عنك",
            body    : "قل فقط:\n\"يا سيري سجّل جرعة ٧ وحدات في وزان\"\nوسيري يسجّلها تلقائياً بدون ما تفتح التطبيق.",
            isLogo  : false
        ),
    ]

    var body: some View {
        ZStack {
            Color.wBg.ignoresSafeArea()

            VStack(spacing: 0) {

                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        pageView(pages[i])
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(duration: 0.4), value: page)

                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Color.wPrimary : Color.wTint1)
                            .frame(width: i == page ? 22 : 8, height: 8)
                            .animation(.spring(duration: 0.3), value: page)
                    }
                }
                .padding(.bottom, 32)

                Group {
                    if page < pages.count - 1 {
                        WPrimaryBtn("التالي", icon: "arrow.right") {
                            withAnimation { page += 1 }
                        }
                    } else {
                        WPrimaryBtn("ابدأ الآن — اتصل بـ Apple Health", icon: "heart.fill") {
                            Task {
                                await health.requestAuthorization()
                                settings.hasOnboarded = true
                                dismiss()
                            }
                        }
                    }
                }
                .padding(.horizontal, WSpacing.lg)
                .padding(.bottom, 48)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .interactiveDismissDisabled()
    }

    // MARK: – Single page
    private func pageView(_ p: OnboardPage) -> some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(p.iconColor.opacity(0.12))
                    .frame(width: 120, height: 120)
                if p.isLogo {
                    Image(systemName: "drop.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 54, height: 54)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.wPrimary, .wAccent],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                } else {
                    Image(systemName: p.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .foregroundColor(p.iconColor)
                }
            }
            .shadow(color: p.iconColor.opacity(0.2), radius: 20, x: 0, y: 8)

            VStack(spacing: 14) {
                Text(p.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.wLabel)
                    .multilineTextAlignment(.center)

                Text(p.body)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.wLabelSec)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 32)

                if p.icon == "waveform" {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.wPrimary)
                        Text("\"يا سيري سجّل جرعة ٧ وحدات في وزان\"")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.wPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.wTint1)
                    .clipShape(RoundedRectangle(cornerRadius: WRadius.md, style: .continuous))
                }
            }

            Spacer()
            Spacer()
        }
    }
}

private struct OnboardPage {
    let icon     : String
    let iconColor: Color
    let title    : String
    let body     : String
    let isLogo   : Bool
}
