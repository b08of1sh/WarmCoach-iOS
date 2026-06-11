import SwiftUI

enum Theme {
    static let cream = Color(red: 1.00, green: 0.98, blue: 0.94)
    static let paper = Color(red: 1.00, green: 0.99, blue: 0.97)
    static let apricot = Color(red: 0.95, green: 0.66, blue: 0.36)
    static let apricotDark = Color(red: 0.78, green: 0.43, blue: 0.18)
    static let coffee = Color(red: 0.56, green: 0.42, blue: 0.33)
    static let sage = Color(red: 0.48, green: 0.64, blue: 0.47)
    static let softGreen = Color(red: 0.55, green: 0.71, blue: 0.55)
    static let rose = Color(red: 0.83, green: 0.39, blue: 0.35)
    static let ink = Color(red: 0.18, green: 0.16, blue: 0.14)
    static let muted = Color(red: 0.52, green: 0.48, blue: 0.43)
    static let line = Color(red: 0.91, green: 0.85, blue: 0.78)
}

struct WarmBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.96, blue: 0.88),
                    Theme.paper,
                    Color(red: 0.94, green: 0.98, blue: 0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            CozyMotifBackground()
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct Panel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .roundedBackground(Theme.paper.opacity(0.92), radius: 24)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Theme.line.opacity(0.8), lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                PanelCornerCharm()
                    .padding(.top, 12)
                    .padding(.trailing, 14)
            }
            .shadow(color: Theme.coffee.opacity(0.10), radius: 18, x: 0, y: 10)
    }
}

struct CozyMotifBackground: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                CozyMotifIcon(systemName: "pawprint.fill", color: Theme.apricotDark, size: 30, rotation: -16)
                    .position(x: proxy.size.width * 0.16, y: proxy.size.height * 0.13)
                CozyMotifIcon(systemName: "leaf.fill", color: Theme.sage, size: 26, rotation: 18)
                    .position(x: proxy.size.width * 0.82, y: proxy.size.height * 0.20)
                CozyMotifIcon(systemName: "sparkle", color: Theme.apricot, size: 22, rotation: 0)
                    .position(x: proxy.size.width * 0.72, y: proxy.size.height * 0.48)
                CozyMotifIcon(systemName: "pawprint.fill", color: Theme.coffee, size: 24, rotation: 14)
                    .position(x: proxy.size.width * 0.24, y: proxy.size.height * 0.72)
                CozyMotifIcon(systemName: "leaf.fill", color: Theme.softGreen, size: 20, rotation: -24)
                    .position(x: proxy.size.width * 0.88, y: proxy.size.height * 0.84)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .allowsHitTesting(false)
    }
}

struct CozyMotifIcon: View {
    let systemName: String
    let color: Color
    let size: CGFloat
    var rotation: Double = 0
    var opacity: Double = 0.08

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: .semibold))
            .foregroundColor(color)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
    }
}

private struct PanelCornerCharm: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkle")
                .font(.system(size: 9, weight: .bold))
            Image(systemName: "pawprint.fill")
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundColor(Theme.apricotDark.opacity(0.16))
        .allowsHitTesting(false)
    }
}

struct StatusPill: View {
    let status: CourseStatus

    var body: some View {
        Text(status.title)
            .font(.caption.weight(.bold))
            .foregroundColor(status.tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(status.tint.opacity(0.14)))
    }
}

extension View {
    func roundedBackground(_ color: Color, radius: CGFloat) -> some View {
        background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(color))
    }
}

struct AvatarView: View {
    let member: Member?
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.34, style: .continuous)
                .fill(member?.avatarTone.color ?? Theme.apricot)
            Text(member?.name.prefix(1).description ?? "?")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}
