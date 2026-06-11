import SwiftUI
import UIKit

struct HeaderBlock: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(subtitle.isEmpty ? .largeTitle.weight(.bold) : .caption.weight(.bold))
                .foregroundColor(subtitle.isEmpty ? Theme.ink : Theme.apricotDark)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SectionTitle: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack {
            Image(systemName: systemImage)
            Text(title)
                .font(.headline)
            Spacer()
        }
        .foregroundColor(Theme.ink)
    }
}

struct SectionTitleButton: View {
    let title: String
    let systemImage: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        HStack {
            Image(systemName: systemImage)
            Text(title)
                .font(.headline)
            Spacer()
            Button(action: action) {
                Text(buttonTitle)
                    .font(.caption.weight(.bold))
                    .foregroundColor(Theme.apricotDark)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Theme.apricot.opacity(0.14)))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .foregroundColor(Theme.ink)
    }
}

struct ExceptionHistoryView: View {
    @Environment(\.presentationMode) private var presentationMode
    let sessions: [CourseSession]
    let memberName: (UUID) -> String

    var body: some View {
        NavigationView {
            ZStack {
                WarmBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if sessions.isEmpty {
                            EmptyBlock(systemImage: "tray", title: "暂无历史记录", text: "取消、请假和爽约会沉淀在这里。")
                        } else {
                            ForEach(sessions.reversed()) { session in
                                ExceptionHistoryRow(session: session, memberName: memberName(session.memberID))
                            }
                        }
                    }
                    .padding(18)
                }
            }
            .navigationBarTitle(Text("全部取消和异常"), displayMode: .inline)
            .navigationBarItems(trailing: Button("完成") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

private struct ExceptionHistoryRow: View {
    let session: CourseSession
    let memberName: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(memberName)
                    .font(.headline)
                Text("\(session.date.weekdayDateText) · \(session.timeRangeText) · \(session.courseType)")
                    .font(.caption)
                    .foregroundColor(Theme.muted)
            }
            Spacer()
            StatusPill(status: session.status)
        }
        .padding(12)
        .roundedBackground(Color.white.opacity(0.88), radius: 18)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.line.opacity(0.7), lineWidth: 1)
        )
    }
}

struct SearchField: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.muted)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.muted)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(12)
        .roundedBackground(Color.white.opacity(0.92), radius: 14)
    }
}

struct MemberSelectRow: View {
    let member: Member
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                AvatarView(member: member)
                VStack(alignment: .leading, spacing: 4) {
                    Text(member.name)
                        .font(.headline)
                    Text("\(member.courseType) · 剩余 \(member.remainingHours) 课时")
                        .font(.subheadline)
                        .foregroundColor(Theme.muted)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.sage)
                }
            }
            .padding(14)
            .roundedBackground(isSelected ? Color.orange.opacity(0.12) : Color.white.opacity(0.86), radius: 20)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? Theme.apricot : Theme.line, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatTile: View {
    let title: String
    let value: String
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(Theme.muted)
            Text(value)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(Theme.ink)
            Text(caption)
                .font(.caption)
                .foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .roundedBackground(Theme.paper.opacity(0.94), radius: 22)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Theme.line.opacity(0.8), lineWidth: 1)
        )
    }
}

struct MemberCompareCard: View {
    let total: Int
    let active: Int

    private var ratio: Double {
        guard total > 0 else { return 0 }
        return min(1, Double(active) / Double(total))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("会员")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.muted)
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(active)")
                            .font(.system(size: 36, weight: .bold))
                        Text("/ \(total)")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(Theme.coffee)
                    }
                    .foregroundColor(Theme.ink)
                }
                Spacer()
                Text("活跃 \(Int(ratio * 100))%")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Theme.sage)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Theme.sage.opacity(0.14)))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.line.opacity(0.5))
                    Capsule()
                        .fill(Theme.sage.opacity(0.55))
                        .frame(width: proxy.size.width * ratio)
                }
            }
            .frame(height: 8)
        }
        .padding(14)
        .roundedBackground(Color.white.opacity(0.72), radius: 18)
    }
}

struct ProfileMetricButton: View {
    let title: String
    let value: String
    var unit: String = ""
    var caption: String = ""
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(value)
                        .font(.title.weight(.bold))
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Theme.ink)
                    }
                }
                Text(title)
                    .font(.caption.weight(.semibold))
                if !caption.isEmpty {
                    Text(caption)
                        .font(.caption2)
                        .foregroundColor(Theme.muted)
                        .lineLimit(2)
                }
            }
            .foregroundColor(tint)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(tint.opacity(0.12)))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProfileDetailSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    let detail: ProfileDetail
    let members: [Member]
    let activeMembers: [Member]
    let weekSessions: [CourseSession]
    let memberName: (UUID) -> String

    var body: some View {
        NavigationView {
            ZStack {
                WarmBackground()
                detailContent
            }
            .navigationBarTitle(Text(detail.title), displayMode: .inline)
            .navigationBarItems(trailing: Button("完成") {
                presentationMode.wrappedValue.dismiss()
            }
            .font(.headline)
            .foregroundColor(Theme.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.white.opacity(0.78)))
            .buttonStyle(PlainButtonStyle()))
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch detail {
        case .weekSessions:
            WeeklyTimeGridView(
                weekDays: Date().weekDays(),
                sessions: weekSessions,
                memberName: memberName,
                onSelect: nil
            )
            .padding(.top, 8)
        case .activeMembers:
            ProfileMemberDetailList(
                emptyTitle: "暂无活跃会员",
                emptyText: "仍有课时的会员会显示在这里。",
                members: activeMembers,
                valueTint: Theme.sage
            )
        case .remainingHours:
            ProfileMemberDetailList(
                emptyTitle: "暂无剩余课时",
                emptyText: "会员剩余课时会按数量从高到低排列。",
                members: members.sorted { $0.remainingHours > $1.remainingHours },
                valueTint: Theme.coffee
            )
        }
    }
}

private struct ProfileMemberDetailList: View {
    let emptyTitle: String
    let emptyText: String
    let members: [Member]
    let valueTint: Color

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if members.isEmpty {
                    EmptyBlock(systemImage: "person.crop.circle.badge.questionmark", title: emptyTitle, text: emptyText)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
                            ProfileMemberDetailRow(member: member, valueTint: valueTint)
                            if index < members.count - 1 {
                                Divider()
                                    .background(Theme.line.opacity(0.7))
                                    .padding(.leading, 64)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                    .roundedBackground(Color.white.opacity(0.84), radius: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Theme.line.opacity(0.72), lineWidth: 1)
                    )
                    .shadow(color: Theme.coffee.opacity(0.08), radius: 18, x: 0, y: 10)
                }
            }
            .padding(18)
        }
    }
}

private struct ProfileMemberDetailRow: View {
    let member: Member
    let valueTint: Color

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(member: member, size: 46)
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.headline)
                    .foregroundColor(Theme.ink)
                Text(member.courseType)
                    .font(.caption)
                    .foregroundColor(Theme.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(member.remainingHours) 课时")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(valueTint)
                Text(member.remainingHours > 0 ? "可预约" : "需续课")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(member.remainingHours > 0 ? Theme.sage : Theme.rose)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

struct LaunchLoadingView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.95, blue: 0.84),
                    Theme.cream,
                    Color(red: 0.86, green: 0.72, blue: 0.55).opacity(0.45)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            CozyMotifBackground()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.78))
                        .frame(width: 128, height: 128)
                        .shadow(color: Theme.coffee.opacity(0.16), radius: 26, x: 0, y: 16)
                    Circle()
                        .stroke(Theme.apricot.opacity(0.22), lineWidth: 10)
                        .frame(width: 104, height: 104)
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundColor(Theme.apricotDark)
                    Image(systemName: "sparkle")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.apricot)
                        .offset(x: 44, y: -38)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.sage)
                        .offset(x: -42, y: 40)
                }

                VStack(spacing: 8) {
                    Text("WarmCoach")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(Theme.ink)
                    Text("今日课程准备中")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.coffee)
                }

                HStack(spacing: 7) {
                    ForEach(0..<5, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(index == 2 ? Theme.sage.opacity(0.58) : Theme.apricot.opacity(0.48))
                            .frame(width: 18, height: 18)
                    }
                }
                .accessibilityHidden(true)
            }
        }
        .ignoresSafeArea()
    }
}

struct CoachLeaveRequestView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var store: CoachStore
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .hour, value: 8, to: Date()) ?? Date()
    @State private var note = ""

    private var affectedSessions: [CourseSession] {
        let normalizedStart = min(startDate, endDate)
        let normalizedEnd = max(startDate, endDate)
        return store.sortedSessions.filter {
            $0.status.isVisibleInSchedule &&
            $0.startsAt < normalizedEnd &&
            $0.endsAt > normalizedStart
        }
    }

    private var isValidRange: Bool {
        startDate < endDate
    }

    var body: some View {
        NavigationView {
            ZStack {
                WarmBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        Panel {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionTitle(title: "我要请假", systemImage: "moon.zzz.fill")
                                DatePicker("开始时间", selection: $startDate)
                                DatePicker("结束时间", selection: $endDate)
                                if !isValidRange {
                                    WarningLine(text: "结束时间需要晚于开始时间。")
                                }
                            }
                        }

                        Panel {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("备注")
                                    .font(.headline)
                                MultilineTextView(text: $note)
                                    .frame(minHeight: 82)
                                    .padding(8)
                                    .roundedBackground(Color.white.opacity(0.9), radius: 12)
                            }
                        }

                        Panel {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("将取消课程")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(affectedSessions.count) 节")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(Theme.apricotDark)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(Theme.apricot.opacity(0.14)))
                                }

                                if affectedSessions.isEmpty {
                                    Text("这个时间范围内没有课程。")
                                        .font(.subheadline)
                                        .foregroundColor(Theme.muted)
                                } else {
                                    ForEach(affectedSessions) { session in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(store.member(for: session.memberID)?.name ?? "未知会员")
                                                    .font(.subheadline.weight(.semibold))
                                                Text("\(session.date.weekdayDateText) · \(session.timeRangeText) · \(session.courseType)")
                                                    .font(.caption)
                                                    .foregroundColor(Theme.muted)
                                            }
                                            Spacer()
                                        }
                                        .padding(10)
                                        .roundedBackground(Color.white.opacity(0.68), radius: 14)
                                    }
                                }
                            }
                        }
                    }
                    .padding(18)
                }
            }
            .navigationBarTitle(Text("请假休息"), displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("完成") {
                    store.addLeaveRecord(startDate: startDate, endDate: endDate, note: note)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(!isValidRange)
            )
        }
    }
}

struct CoachLeaveHistoryView: View {
    @Environment(\.presentationMode) private var presentationMode
    let records: [CoachLeaveRecord]

    var body: some View {
        NavigationView {
            ZStack {
                WarmBackground()
                ScrollView {
                    VStack(spacing: 12) {
                        if records.isEmpty {
                            EmptyBlock(systemImage: "moon.zzz", title: "暂无休假记录", text: "完成请假后，起止时间和备注会显示在这里。")
                        } else {
                            ForEach(records) { record in
                                CoachLeaveHistoryRow(record: record)
                            }
                        }
                    }
                    .padding(18)
                }
            }
            .navigationBarTitle(Text("休假记录"), displayMode: .inline)
            .navigationBarItems(trailing: Button("完成") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

private struct CoachLeaveHistoryRow: View {
    let record: CoachLeaveRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("休假", systemImage: "moon.zzz.fill")
                    .font(.headline)
                    .foregroundColor(Theme.ink)
                Spacer()
                Text("\(record.affectedSessionIDs.count) 节已取消")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Theme.apricotDark)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Theme.apricot.opacity(0.14)))
            }
            Text("\(record.startDate.dateTimeText) 至 \(record.endDate.dateTimeText)")
                .font(.subheadline)
                .foregroundColor(Theme.coffee)
            if !record.note.isEmpty {
                Text(record.note)
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .roundedBackground(Color.white.opacity(0.84), radius: 20)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.line.opacity(0.72), lineWidth: 1)
        )
    }
}

struct WeeklyTimeGridView: View {
    let weekDays: [Date]
    let sessions: [CourseSession]
    let memberName: (UUID) -> String
    let onSelect: ((CourseSession) -> Void)?

    private let hourHeight: CGFloat = 64
    private let dayWidth: CGFloat = 92
    private let timeColumnWidth: CGFloat = 42
    private let headerHeight: CGFloat = 62

    private var hourRange: ClosedRange<Int> {
        let visibleSessions = sessions.filter { $0.status.isVisibleInSchedule }
        let earliest = visibleSessions.map { $0.startMinutes / 60 }.min() ?? 8
        let latest = visibleSessions.map { Int(ceil(Double($0.endMinutes) / 60.0)) }.max() ?? 21
        return max(6, earliest - 1)...min(23, latest + 1)
    }

    var body: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            ZStack(alignment: .topLeading) {
                gridLines
                dayHeaders
                hourLabels
                sessionCards
            }
            .frame(
                width: timeColumnWidth + CGFloat(weekDays.count) * dayWidth,
                height: headerHeight + CGFloat(hourRange.count) * hourHeight
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 18)
        }
    }

    private var gridLines: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(hourRange), id: \.self) { hour in
                Rectangle()
                    .fill(Theme.line.opacity(0.38))
                    .frame(width: CGFloat(weekDays.count) * dayWidth, height: 1)
                    .offset(x: timeColumnWidth, y: headerHeight + CGFloat(hour - hourRange.lowerBound) * hourHeight)
            }

            ForEach(0...weekDays.count, id: \.self) { index in
                Rectangle()
                    .fill(Theme.line.opacity(0.22))
                    .frame(width: 1, height: CGFloat(hourRange.count) * hourHeight)
                    .offset(x: timeColumnWidth + CGFloat(index) * dayWidth, y: headerHeight)
            }
        }
    }

    private var dayHeaders: some View {
        HStack(spacing: 0) {
            Text("\(weekDays.first.map { Calendar.current.component(.month, from: $0) } ?? 0)月")
                .font(.headline.weight(.bold))
                .foregroundColor(Theme.ink)
                .frame(width: timeColumnWidth, height: headerHeight)
            ForEach(weekDays, id: \.self) { day in
                VStack(spacing: 4) {
                    Text(day.weekdayText)
                        .font(.subheadline.weight(.bold))
                    Text(day.dayNumberText)
                        .font(.headline.weight(.semibold))
                }
                .foregroundColor(Theme.ink)
                .frame(width: dayWidth, height: headerHeight)
                .background(Calendar.current.isDateInToday(day) ? Theme.softGreen.opacity(0.32) : Color.white.opacity(0.55))
            }
        }
        .roundedBackground(Color.white.opacity(0.64), radius: 16)
    }

    private var hourLabels: some View {
        ForEach(Array(hourRange), id: \.self) { hour in
            Text("\(hour)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.muted)
                .frame(width: timeColumnWidth, height: hourHeight, alignment: .top)
                .offset(x: 0, y: headerHeight + CGFloat(hour - hourRange.lowerBound) * hourHeight + 6)
        }
    }

    private var sessionCards: some View {
        ForEach(sessions.filter { $0.status.isVisibleInSchedule }) { session in
            let dayIndex = indexOfDay(for: session)
            let start = max(session.startMinutes, hourRange.lowerBound * 60)
            let end = min(session.endMinutes, (hourRange.upperBound + 1) * 60)
            let y = headerHeight + CGFloat(start - hourRange.lowerBound * 60) / 60 * hourHeight + 5
            let height = max(52, CGFloat(end - start) / 60 * hourHeight - 10)

            Button {
                onSelect?(session)
            } label: {
                VStack(alignment: .leading, spacing: 5) {
                    Text(memberName(session.memberID))
                        .font(.caption.weight(.bold))
                        .lineLimit(2)
                    Text(session.courseType)
                        .font(.caption2.weight(.semibold))
                        .lineLimit(2)
                    Text(session.timeRangeText)
                        .font(.caption2)
                        .lineLimit(1)
                }
                .foregroundColor(Theme.ink)
                .frame(width: dayWidth - 8, height: height, alignment: .topLeading)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(gridCardColor(for: session)))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.9), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(onSelect == nil)
            .offset(x: timeColumnWidth + CGFloat(dayIndex) * dayWidth + 4, y: y)
        }
    }

    private func indexOfDay(for session: CourseSession) -> Int {
        weekDays.firstIndex { Calendar.current.isDate($0, inSameDayAs: session.date) } ?? 0
    }

    private func gridCardColor(for session: CourseSession) -> Color {
        switch session.status {
        case .completed:
            return Theme.sage.opacity(0.28)
        case .upcoming:
            return Theme.apricot.opacity(0.45)
        default:
            return Theme.line.opacity(0.5)
        }
    }
}

struct TodayOverviewCard: View {
    let remaining: Int
    let total: Int
    let completed: Int
    let exceptions: Int

    private var summaryText: String {
        max(total, remaining) == 0 ? "今日无事，勾栏听曲" : "今日共 \(max(total, remaining)) 节课，当前还剩 \(remaining) 节"
    }

    var body: some View {
        Panel {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 7) {
                            CozyBadgeIcon(systemName: "pawprint.fill", tint: Theme.apricotDark)
                            Text("今日课程")
                                .font(.headline)
                                .foregroundColor(Theme.muted)
                        }
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(remaining)")
                                .font(.system(size: 52, weight: .bold))
                                .foregroundColor(Theme.ink)
                            Text("/ \(max(total, remaining))")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(Theme.coffee)
                        }
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 10) {
                        TinyFarmRow()
                        Text(summaryText)
                            .font(.title3.weight(.bold))
                            .foregroundColor(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 8) {
                            TodayMiniMetric(title: "已完成", value: completed, tint: Theme.sage)
                            TodayMiniMetric(title: "异常", value: exceptions, tint: Theme.rose)
                        }
                    }
                    .frame(maxWidth: 180, alignment: .leading)
                }
            }
        }
    }
}

private struct CozyBadgeIcon: View {
    let systemName: String
    let tint: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(tint)
            .frame(width: 24, height: 24)
            .background(Circle().fill(tint.opacity(0.12)))
    }
}

private struct TinyFarmRow: View {
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(index == 1 ? Theme.sage.opacity(0.55) : Theme.apricot.opacity(0.38))
                    .frame(width: 14, height: 14)
                    .overlay(alignment: .top) {
                        if index == 1 {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(Theme.sage)
                                .offset(y: -4)
                        }
                    }
            }
        }
        .accessibilityHidden(true)
    }
}

private struct TodayMiniMetric: View {
    let title: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(.headline.weight(.bold))
            Text(title)
                .font(.caption2.weight(.semibold))
        }
        .foregroundColor(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(tint.opacity(0.12)))
    }
}

struct NextCoursePanel: View {
    @EnvironmentObject private var store: CoachStore
    let session: CourseSession

    var body: some View {
        Panel {
            HStack(spacing: 14) {
                AvatarView(member: store.member(for: session.memberID), size: 58)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 7) {
                        CozyBadgeIcon(systemName: "sparkle", tint: Theme.apricotDark)
                        Text("即将上课")
                            .font(.headline.weight(.bold))
                            .foregroundColor(Theme.apricotDark)
                    }
                    Text(store.member(for: session.memberID)?.name ?? "未知会员")
                        .font(.system(size: 20, weight: .bold))
                    Text("\(session.courseType) · \(session.timeRangeText)")
                        .font(.subheadline)
                        .foregroundColor(Theme.muted)
                }
                Spacer()
            }
        }
    }
}

struct TodayCourseActionCard: View {
    let session: CourseSession
    let member: Member?
    var isHighlighted = false
    let onEdit: () -> Void
    let onStatus: (CourseStatus) -> Void

    @State private var showsActions = false
    @State private var selectedStatus: CourseStatus = .completed

    var body: some View {
        CourseSummaryCard(session: session, member: member, isHighlighted: isHighlighted)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedStatus = .completed
                showsActions = true
            }
            .sheet(isPresented: $showsActions) {
                CourseStatusWheelSheet(
                    memberName: member?.name ?? "课程操作",
                    timeRange: "\(session.timeRangeText) · \(session.courseType)",
                    selectedStatus: $selectedStatus,
                    onSave: {
                        showsActions = false
                        onStatus(selectedStatus)
                    },
                    onEdit: {
                        showsActions = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            onEdit()
                        }
                    }
                )
            }
    }
}

private struct CourseStatusWheelSheet: View {
    let memberName: String
    let timeRange: String
    @Binding var selectedStatus: CourseStatus
    let onSave: () -> Void
    let onEdit: () -> Void

    private let statuses: [CourseStatus] = [.completed, .cancelled, .leave, .noShow]

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Theme.line)
                .frame(width: 40, height: 5)
                .padding(.top, 10)

            VStack(spacing: 6) {
                Text(memberName)
                    .font(.title3.weight(.bold))
                Text(timeRange)
                    .font(.subheadline)
                    .foregroundColor(Theme.muted)
            }

            Picker("课程状态", selection: $selectedStatus) {
                ForEach(statuses) { status in
                    Text(status.title).tag(status)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)
            .clipped()

            VStack(spacing: 10) {
                Button(action: onSave) {
                    Text("保存状态")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .roundedBackground(Theme.apricotDark, radius: 16)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: onEdit) {
                    Text("编辑课程")
                        .font(.headline)
                        .foregroundColor(Theme.coffee)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .roundedBackground(Theme.coffee.opacity(0.12), radius: 16)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .presentationDetents([.height(390)])
    }
}

private struct CourseSummaryCard: View {
    let session: CourseSession
    let member: Member?
    var isHighlighted = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AvatarView(member: member)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(member?.name ?? "未知会员")
                        .font(.headline)
                    Spacer()
                    StatusPill(status: session.status)
                }
                Text("\(session.timeRangeText) · \(session.courseType)")
                    .font(.subheadline)
                    .foregroundColor(Theme.muted)
                if !session.note.isEmpty {
                    Text(session.note)
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                }
            }
        }
        .padding(12)
        .roundedBackground(isHighlighted ? Color.orange.opacity(0.12) : Color.white.opacity(0.86), radius: 18)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isHighlighted ? Theme.apricot.opacity(0.7) : Theme.line.opacity(0.8), lineWidth: 1)
        )
    }
}

struct WeekDayColumn: View {
    @EnvironmentObject private var store: CoachStore
    let day: Date
    let sessions: [CourseSession]
    var searchText = ""
    let onAdd: () -> Void
    let onEdit: (CourseSession) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(day.weekdayText)
                        .font(.headline)
                    Text(day.shortDateText)
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                }
                Spacer()
                Button(action: onAdd) {
                    Image(systemName: "plus")
                }
                .buttonStyle(PlainButtonStyle())
            }

            if sessions.isEmpty {
                Text("空")
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                    .frame(maxWidth: .infinity, minHeight: 64)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(sessions) { session in
                            Button {
                                onEdit(session)
                            } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(session.timeRangeText)
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(Theme.coffee)
                                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                                        HighlightedNameText(
                                            name: store.member(for: session.memberID)?.name ?? "未知会员",
                                            searchText: searchText
                                        )
                                        Spacer(minLength: 4)
                                        Text(session.courseType)
                                            .font(.caption2.weight(.semibold))
                                            .foregroundColor(Theme.muted)
                                            .lineLimit(1)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .roundedBackground(scheduleCardBackground(for: session), radius: 16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(scheduleCardStroke(for: session), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .roundedBackground(Calendar.current.isDateInToday(day) ? Color.orange.opacity(0.12) : Theme.paper.opacity(0.92), radius: 24)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Theme.line.opacity(0.8), lineWidth: 1)
        )
        .overlay(alignment: .bottomTrailing) {
            if Calendar.current.isDateInToday(day) {
                CozyMotifIcon(systemName: "leaf.fill", color: Theme.sage, size: 18, rotation: -12, opacity: 0.16)
                    .padding(12)
            }
        }
    }

    private func scheduleCardBackground(for session: CourseSession) -> Color {
        switch session.status {
        case .completed:
            return Theme.sage.opacity(0.18)
        case .upcoming:
            return Theme.apricot.opacity(0.18)
        default:
            return Color.white.opacity(0.88)
        }
    }

    private func scheduleCardStroke(for session: CourseSession) -> Color {
        switch session.status {
        case .completed:
            return Theme.sage.opacity(0.35)
        case .upcoming:
            return Theme.apricot.opacity(0.35)
        default:
            return Theme.line.opacity(0.8)
        }
    }
}

struct HighlightedNameText: View {
    let name: String
    let searchText: String

    var body: some View {
        Text(attributedName)
            .font(.headline)
    }

    private var attributedName: AttributedString {
        var attributed = AttributedString(name)
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else { return attributed }

        var searchStart = attributed.startIndex
        while let range = attributed[searchStart...].range(of: trimmedSearch, options: [.caseInsensitive]) {
            attributed[range].foregroundColor = Theme.apricotDark
            attributed[range].backgroundColor = Theme.apricot.opacity(0.20)
            searchStart = range.upperBound
        }
        return attributed
    }
}

struct StaticRecordRow: View {
    let session: CourseSession
    let member: Member?
    var onRestore: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(member: member)
            VStack(alignment: .leading, spacing: 4) {
                Text(member?.name ?? "未知会员")
                    .font(.headline)
                Text("\(session.timeRangeText) · \(session.courseType)")
                    .font(.caption)
                    .foregroundColor(Theme.muted)
            }
            Spacer()
            StatusPill(status: session.status)
        }
        .padding(12)
        .roundedBackground(Color.white.opacity(0.88), radius: 18)
        .contextMenu {
            if let onRestore {
                Button(action: onRestore) {
                    Label("恢复课程", systemImage: "arrow.uturn.backward")
                }
            }
        }
    }
}

struct InfoLine: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(Theme.muted)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(Theme.ink)
        }
        .font(.subheadline)
        .padding(12)
        .roundedBackground(Color.white.opacity(0.72), radius: 14)
    }
}

struct EmptyBlock: View {
    let systemImage: String
    let title: String
    let text: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Theme.coffee)
            Text(title)
                .font(.headline)
            Text(text)
                .font(.subheadline)
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 140)
        .padding()
        .roundedBackground(Color.white.opacity(0.54), radius: 20)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.line, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
        )
    }
}

struct MultilineTextView: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.font = UIFont.preferredFont(forTextStyle: .body)
        view.backgroundColor = .clear
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func textViewDidChange(_ textView: UITextView) {
            text = textView.text
        }
    }
}

extension Date {
    var shortDateText: String {
        Self.shortFormatter.string(from: self)
    }

    var weekdayText: String {
        Self.weekdayFormatter.string(from: self)
    }

    var weekdayDateText: String {
        Self.weekdayDateFormatter.string(from: self)
    }

    var dateTimeText: String {
        Self.dateTimeFormatter.string(from: self)
    }

    var dayNumberText: String {
        Self.dayFormatter.string(from: self)
    }

    func weekDays() -> [Date] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: self)
        let offset = (weekday + 5) % 7
        let start = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: self)) ?? self
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEE"
        return formatter
    }()

    private static let weekdayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "d日"
        return formatter
    }()
}
