import SwiftUI

enum ScheduleRepeatMode: String, CaseIterable, Identifiable {
    case once
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .once: return "仅一次"
        case .custom: return "自定义"
        }
    }
}

enum RepeatSpan: String, CaseIterable, Identifiable {
    case currentWeek
    case weekly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .currentWeek: return "仅此周"
        case .weekly: return "每周重复"
        }
    }
}

struct CourseFlowView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var store: CoachStore

    private let existingSession: CourseSession?
    private let hasDraft: Bool
    @State private var step = 1
    @State private var memberID: UUID?
    @State private var date: Date
    @State private var startMinutes: Int
    @State private var endMinutes: Int
    @State private var courseType: String
    @State private var status: CourseStatus
    @State private var reminderMinutes: Int
    @State private var note: String
    @State private var memberSearchText = ""
    @State private var repeatMode: ScheduleRepeatMode = .once
    @State private var repeatSpan: RepeatSpan = .currentWeek
    @State private var repeatWeekCount = 4
    @State private var selectedWeekdays: Set<Int> = []
    @State private var showsHourLimitAlert = false

    init(sheet: CourseSheet) {
        existingSession = sheet.session
        let draft = sheet.draft
        hasDraft = sheet.session == nil && draft != nil
        _memberID = State(initialValue: sheet.session?.memberID ?? draft?.memberID)
        _date = State(initialValue: sheet.session?.date ?? draft?.date ?? sheet.baseDate)
        _startMinutes = State(initialValue: sheet.session?.startMinutes ?? draft?.startMinutes ?? 540)
        _endMinutes = State(initialValue: sheet.session?.endMinutes ?? draft?.endMinutes ?? 630)
        _courseType = State(initialValue: sheet.session?.courseType ?? draft?.courseType ?? defaultCourseTypes[0])
        _status = State(initialValue: sheet.session?.status ?? .upcoming)
        _reminderMinutes = State(initialValue: sheet.session?.reminderMinutes ?? draft?.reminderMinutes ?? 30)
        _note = State(initialValue: sheet.session?.note ?? draft?.note ?? "")
    }

    private var selectedMember: Member? {
        guard let memberID else { return nil }
        return store.member(for: memberID)
    }

    private var filteredMembers: [Member] {
        let trimmedSearch = memberSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else { return store.members }
        return store.members.filter {
            $0.name.localizedCaseInsensitiveContains(trimmedSearch) ||
            $0.phone.localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    private var availableCourseTypes: [String] {
        if store.courseTypes.contains(courseType) {
            return store.courseTypes
        }
        return [courseType] + store.courseTypes
    }

    private var draftSession: CourseSession? {
        guard let memberID else { return nil }
        return CourseSession(
            id: existingSession?.id ?? UUID(),
            memberID: memberID,
            date: Calendar.current.startOfDay(for: date),
            startMinutes: startMinutes,
            endMinutes: endMinutes,
            courseType: courseType,
            status: status,
            reminderMinutes: reminderMinutes,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private var conflicts: [CourseSession] {
        candidateSessions.flatMap { candidate in
            store.conflicts(for: candidate, ignoring: existingSession?.id)
        }
    }

    private var candidateSessions: [CourseSession] {
        guard let draftSession else { return [] }
        guard existingSession == nil, repeatMode == .custom else { return [draftSession] }

        let targetDates = repeatedDates()
        return targetDates.map { targetDate in
            var session = draftSession
            session.id = UUID()
            session.date = Calendar.current.startOfDay(for: targetDate)
            session.status = .upcoming
            return session
        }
    }

    private var canContinueFromTime: Bool {
        startMinutes < endMinutes && !candidateSessions.isEmpty && conflicts.isEmpty
    }

    private var hasEnoughMemberHoursForCandidates: Bool {
        guard existingSession == nil else { return true }
        guard let selectedMember else { return false }
        return candidateSessions.count <= selectedMember.remainingHours
    }

    private var hourLimitMessage: String {
        guard let selectedMember else {
            return "请先选择会员后再继续。"
        }
        return "\(selectedMember.name) 当前剩余 \(selectedMember.remainingHours) 课时，本次将创建 \(candidateSessions.count) 节课程，已超出剩余课时。请减少重复日期或调整生成周数后再继续。"
    }

    var body: some View {
        if existingSession == nil {
            createFlowBody
        } else {
            editDetailBody
        }
    }

    private var createFlowBody: some View {
        NavigationView {
            ZStack {
                WarmBackground()
                VStack(spacing: 18) {
                    StepDots(step: step)

                    Group {
                        if step == 1 {
                            memberStep
                        } else if step == 2 {
                            timeStep
                        } else {
                            confirmStep
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                    HStack {
                        Button(step == 1 ? "取消" : "上一步") {
                            if step == 1 {
                                presentationMode.wrappedValue.dismiss()
                            } else {
                                step -= 1
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .roundedBackground(Color.white.opacity(0.9), radius: 14)

                        Spacer()

                        if step < 3 {
                            Button("下一步") {
                                advanceStep()
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .foregroundColor(.white)
                            .roundedBackground(Theme.apricotDark, radius: 14)
                            .disabled(step == 1 ? memberID == nil : !canContinueFromTime)
                        } else {
                            Button("保存课程") {
                                save()
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .foregroundColor(.white)
                            .roundedBackground(Theme.apricotDark, radius: 14)
                            .disabled(draftSession == nil || !canContinueFromTime)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)
                }
            }
            .navigationBarTitle(Text(existingSession == nil ? "新增排课" : "编辑课程"), displayMode: .inline)
            .navigationBarItems(
                trailing: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                }
            )
            .onAppear {
                if memberID == nil, let first = store.members.first {
                    choose(first)
                } else if let selectedMember, existingSession == nil, !hasDraft {
                    applyDefaults(from: selectedMember)
                }
                if existingSession == nil {
                    applyDefaultSlot(for: date)
                    if !hasDraft {
                        reminderMinutes = 30
                    }
                    syncSelectedWeekday(with: date)
                }
            }
            .alert("课时不足", isPresented: $showsHourLimitAlert) {
                Button("重新选择", role: .cancel) {}
            } message: {
                Text(hourLimitMessage)
            }
        }
    }

    private var editDetailBody: some View {
        NavigationView {
            ZStack {
                WarmBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        Panel {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("会员")
                                    .font(.headline)
                                SearchField(text: $memberSearchText, placeholder: "搜索会员")
                                ScrollView {
                                    VStack(spacing: 8) {
                                        ForEach(filteredMembers) { member in
                                            MemberSelectRow(
                                                member: member,
                                                isSelected: memberID == member.id,
                                                onSelect: { choose(member) }
                                            )
                                        }
                                    }
                                }
                                .frame(maxHeight: filteredMembers.count > 3 ? 220 : nil)
                            }
                        }

                        Panel {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("日期和时间段")
                                    .font(.headline)
                                DatePicker("日期", selection: $date, displayedComponents: .date)
                                DatePicker("开始时间", selection: Binding(
                                    get: { timeDate(minutes: startMinutes) },
                                    set: { startMinutes = minutes(from: $0) }
                                ), displayedComponents: .hourAndMinute)
                                DatePicker("结束时间", selection: Binding(
                                    get: { timeDate(minutes: endMinutes) },
                                    set: { endMinutes = minutes(from: $0) }
                                ), displayedComponents: .hourAndMinute)
                            }
                        }

                        Panel {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("课程信息")
                                    .font(.headline)
                                WidePickerRow(title: "课程类型", selection: $courseType) {
                                    ForEach(availableCourseTypes, id: \.self) { type in
                                        Text(type).tag(type)
                                    }
                                }
                                WidePickerRow(title: "课程状态", selection: $status) {
                                    ForEach(CourseStatus.allCases) { status in
                                        Text(status.title).tag(status)
                                    }
                                }
                                WidePickerRow(title: "提醒规则", selection: $reminderMinutes) {
                                    ForEach(reminderOptions, id: \.self) { minutes in
                                        Text(reminderTitle(minutes)).tag(minutes)
                                    }
                                }
                            }
                        }

                        Panel {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("备注")
                                    .font(.headline)
                                MultilineTextView(text: $note)
                                    .frame(minHeight: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 52 : 120)
                                    .padding(8)
                                    .roundedBackground(Color.white.opacity(0.9), radius: 12)
                            }
                        }

                        if startMinutes >= endMinutes {
                            Panel {
                                WarningLine(text: "结束时间需要晚于开始时间。")
                            }
                        }

                        if !conflicts.isEmpty {
                            Panel {
                                VStack(alignment: .leading, spacing: 8) {
                                    WarningLine(text: "该时间段已有课程")
                                    ForEach(conflicts) { conflict in
                                        Text("\(store.member(for: conflict.memberID)?.name ?? "会员") · \(conflict.timeRangeText)")
                                            .font(.subheadline)
                                            .foregroundColor(Theme.muted)
                                    }
                                }
                            }
                        }
                    }
                    .padding(18)
                }
            }
            .navigationBarTitle(Text("编辑课程"), displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    save()
                }
                .disabled(draftSession == nil || !canContinueFromTime)
            )
        }
    }

    private var memberStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("选择会员")
                    .font(.system(size: 22, weight: .bold))
                    .padding(.horizontal, 18)

                SearchField(text: $memberSearchText, placeholder: "搜索会员")
                    .padding(.horizontal, 18)

                if filteredMembers.isEmpty {
                    EmptyBlock(systemImage: "person.crop.circle.badge.questionmark", title: "没有匹配会员", text: "换个姓名或手机号试试。")
                        .padding(.horizontal, 18)
                } else {
                    ForEach(filteredMembers) { member in
                        MemberSelectRow(
                            member: member,
                            isSelected: memberID == member.id,
                            onSelect: { choose(member) }
                        )
                        .padding(.horizontal, 18)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var timeStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                Panel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("日期和时间段")
                            .font(.headline)
                        DatePicker("日期", selection: Binding(
                            get: { date },
                            set: { newDate in
                                date = newDate
                                if existingSession == nil {
                                    applyDefaultSlot(for: newDate)
                                    syncSelectedWeekday(with: newDate)
                                }
                            }
                        ), displayedComponents: .date)
                        DatePicker("开始时间", selection: Binding(
                            get: { timeDate(minutes: startMinutes) },
                            set: { newDate in
                                startMinutes = minutes(from: newDate)
                                if existingSession == nil {
                                    endMinutes = defaultEndMinutes(for: startMinutes)
                                }
                            }
                        ), displayedComponents: .hourAndMinute)
                        DatePicker("结束时间", selection: Binding(
                            get: { timeDate(minutes: endMinutes) },
                            set: { endMinutes = minutes(from: $0) }
                        ), displayedComponents: .hourAndMinute)

                        if existingSession == nil {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("重复周期")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(Theme.muted)
                                Picker("重复周期", selection: $repeatMode) {
                                    ForEach(ScheduleRepeatMode.allCases) { mode in
                                        Text(mode.title).tag(mode)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 92)
                                .clipped()
                                .roundedBackground(Color.white.opacity(0.78), radius: 14)
                            }
                        }
                    }
                }

                if existingSession == nil, repeatMode == .custom {
                    RepeatCustomPanel(
                        repeatSpan: $repeatSpan,
                        repeatWeekCount: $repeatWeekCount,
                        selectedWeekdays: $selectedWeekdays,
                        baseDate: date
                    )
                }

                Panel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("课程")
                            .font(.headline)
                        CourseTypeWheelPicker(courseType: $courseType, courseTypes: availableCourseTypes)
                    }
                }

                if startMinutes >= endMinutes {
                    Panel {
                        WarningLine(text: "结束时间需要晚于开始时间。")
                    }
                }

                if !conflicts.isEmpty {
                    Panel {
                        VStack(alignment: .leading, spacing: 8) {
                            WarningLine(text: "该时间段已有课程")
                            ForEach(conflicts.uniquedByID()) { conflict in
                                Text("\(conflict.date.weekdayDateText) · \(store.member(for: conflict.memberID)?.name ?? "会员") · \(conflict.timeRangeText)")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.muted)
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
    }

    private var confirmStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                Panel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("确认课程")
                            .font(.headline)
                        HStack(spacing: 12) {
                            AvatarView(member: selectedMember, size: 56)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(selectedMember?.name ?? "未选择会员")
                                    .font(.headline)
                                Text(confirmTimeText)
                                    .font(.subheadline)
                                    .foregroundColor(Theme.muted)
                                Text(courseType)
                                    .font(.caption)
                                    .foregroundColor(Theme.coffee)
                            }
                        }
                        if existingSession == nil, repeatMode == .custom {
                            Text("将创建 \(candidateSessions.count) 节课程")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Theme.apricotDark)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Capsule().fill(Theme.apricot.opacity(0.14)))
                        }
                    }
                }

                Panel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("提醒与状态")
                            .font(.headline)
                        Picker("提醒规则", selection: $reminderMinutes) {
                            ForEach(reminderOptions, id: \.self) { minutes in
                                Text(reminderTitle(minutes)).tag(minutes)
                            }
                        }
                        if existingSession == nil {
                            HStack {
                                Text("课程状态")
                                Spacer()
                                StatusPill(status: .upcoming)
                            }
                        } else {
                            Picker("课程状态", selection: $status) {
                                ForEach(CourseStatus.allCases) { status in
                                    Text(status.title).tag(status)
                                }
                            }
                        }
                    }
                }

                Panel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("备注")
                            .font(.headline)
                        MultilineTextView(text: $note)
                            .frame(minHeight: 90)
                            .padding(8)
                            .roundedBackground(Color.white.opacity(0.9), radius: 12)
                    }
                }

                if !conflicts.isEmpty {
                    Panel {
                        WarningLine(text: "存在时间冲突，调整时间后再保存。")
                    }
                }
            }
            .padding(18)
        }
    }

    private func choose(_ member: Member) {
        memberID = member.id
        if existingSession == nil {
            applyDefaults(from: member)
        } else {
            courseType = member.courseType
        }
    }

    private func applyDefaults(from member: Member) {
        courseType = member.courseType
        reminderMinutes = 30
    }

    private func applyDefaultSlot(for selectedDate: Date) {
        let calendar = Calendar.current
        let latestEnd = store.sessions
            .filter { session in
                calendar.isDate(session.date, inSameDayAs: selectedDate) &&
                session.status.isVisibleInSchedule &&
                session.id != existingSession?.id
            }
            .map(\.endMinutes)
            .max()

        let start = latestEnd ?? fallbackStartMinutes(for: selectedDate)
        startMinutes = min(max(start, 0), 22 * 60 + 30)
        endMinutes = defaultEndMinutes(for: startMinutes)
    }

    private func fallbackStartMinutes(for selectedDate: Date) -> Int {
        if Calendar.current.isDateInToday(selectedDate) {
            let components = Calendar.current.dateComponents([.hour, .minute], from: Date())
            let currentMinutes = (components.hour ?? 9) * 60 + (components.minute ?? 0)
            let rounded = Int(ceil(Double(currentMinutes) / 30.0) * 30.0)
            return min(max(rounded, 9 * 60), 22 * 60 + 30)
        }
        return 9 * 60
    }

    private func defaultEndMinutes(for start: Int) -> Int {
        min(start + 90, 23 * 60 + 59)
    }

    private var confirmTimeText: String {
        let timeText = "\(CourseSession.timeText(startMinutes)) - \(CourseSession.timeText(endMinutes))"
        guard existingSession == nil, repeatMode == .custom else {
            return "\(date.weekdayDateText) · \(timeText)"
        }
        return "\(repeatSpan.title) · \(selectedWeekdayTitles().joined(separator: "、")) · \(timeText)"
    }

    private func syncSelectedWeekday(with selectedDate: Date) {
        let weekday = Calendar.current.component(.weekday, from: selectedDate)
        if selectedWeekdays.isEmpty || repeatMode == .once {
            selectedWeekdays = [weekday]
        }
    }

    private func selectedWeekdayTitles() -> [String] {
        weekdayOptions
            .filter { selectedWeekdays.contains($0.weekday) }
            .map(\.shortTitle)
    }

    private var weekdayOptions: [WeekdayOption] {
        WeekdayOption.ordered
    }

    private func repeatedDates() -> [Date] {
        guard !selectedWeekdays.isEmpty else { return [] }
        let calendar = Calendar.current
        let baseWeekStart = date.weekDays().first ?? calendar.startOfDay(for: date)
        let weekCount = repeatSpan == .weekly ? repeatWeekCount : 1

        return (0..<weekCount).flatMap { weekOffset -> [Date] in
            guard let weekStart = calendar.date(byAdding: .day, value: weekOffset * 7, to: baseWeekStart) else { return [] }
            return weekdayOptions.compactMap { option in
                guard selectedWeekdays.contains(option.weekday) else { return nil }
                return calendar.date(byAdding: .day, value: option.mondayBasedIndex, to: weekStart)
            }
        }
        .sorted()
    }

    private func advanceStep() {
        guard step == 2 else {
            step += 1
            return
        }
        guard hasEnoughMemberHoursForCandidates else {
            showsHourLimitAlert = true
            return
        }
        step += 1
    }

    private func save() {
        let sessionsToSave = candidateSessions
        guard !sessionsToSave.isEmpty else { return }
        guard hasEnoughMemberHoursForCandidates else {
            showsHourLimitAlert = true
            return
        }
        sessionsToSave.forEach { store.upsertSession($0) }
        presentationMode.wrappedValue.dismiss()
    }

    private func timeDate(minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: Calendar.current.startOfDay(for: Date())) ?? Date()
    }

    private func minutes(from date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}

struct WarningLine: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
            Text(text)
        }
        .foregroundColor(Theme.rose)
    }
}

struct RepeatCustomPanel: View {
    @Binding var repeatSpan: RepeatSpan
    @Binding var repeatWeekCount: Int
    @Binding var selectedWeekdays: Set<Int>
    let baseDate: Date
    @State private var showsWeekPicker = false

    private let weekOptions = Array(1...12)

    var body: some View {
        Panel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("自定义重复")
                        .font(.headline)
                    Spacer()
                    if repeatSpan == .weekly {
                        Button {
                            showsWeekPicker = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("未来 \(repeatWeekCount) 周")
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption2.weight(.bold))
                            }
                            .font(.caption.weight(.bold))
                            .foregroundColor(Theme.apricotDark)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Theme.apricot.opacity(0.14)))
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        Text("本周")
                            .font(.caption.weight(.bold))
                            .foregroundColor(Theme.apricotDark)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Theme.apricot.opacity(0.14)))
                    }
                }

                Picker("重复范围", selection: $repeatSpan) {
                    ForEach(RepeatSpan.allCases) { span in
                        Text(span.title).tag(span)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 8) {
                    Text("勾选日期")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.muted)
                    HStack(spacing: 7) {
                        ForEach(WeekdayOption.ordered) { option in
                            WeekdayButton(
                                title: option.shortTitle,
                                isSelected: selectedWeekdays.contains(option.weekday),
                                isBaseDay: Calendar.current.component(.weekday, from: baseDate) == option.weekday
                            ) {
                                toggle(option.weekday)
                            }
                        }
                    }
                }

                Text(repeatSpan == .weekly ? "会复用当前时间段和课程类型，生成未来 \(repeatWeekCount) 周的所选日期。" : "会在当前周内，按所选日期复用当前时间段和课程类型。")
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .sheet(isPresented: $showsWeekPicker) {
            NavigationView {
                ZStack {
                    WarmBackground()
                    VStack(spacing: 18) {
                        Text("生成周期")
                            .font(.headline)
                        Picker("生成周期", selection: $repeatWeekCount) {
                            ForEach(weekOptions, id: \.self) { week in
                                Text("\(week) 周").tag(week)
                            }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .frame(height: 180)
                        .clipped()
                        .roundedBackground(Color.white.opacity(0.84), radius: 18)

                        Text("每周重复会复用当前时间段和课程类型。")
                            .font(.caption)
                            .foregroundColor(Theme.muted)
                    }
                    .padding(20)
                }
                .navigationBarTitle("重复周数", displayMode: .inline)
                .navigationBarItems(trailing: Button("完成") {
                    showsWeekPicker = false
                })
            }
            .presentationDetents([.height(360)])
        }
    }

    private func toggle(_ weekday: Int) {
        if selectedWeekdays.contains(weekday) {
            selectedWeekdays.remove(weekday)
        } else {
            selectedWeekdays.insert(weekday)
        }
    }
}

private struct WeekdayButton: View {
    let title: String
    let isSelected: Bool
    let isBaseDay: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption.weight(.bold))
                if isBaseDay {
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.9) : Theme.apricot.opacity(0.45))
                        .frame(width: 5, height: 5)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 5, height: 5)
                }
            }
            .foregroundColor(isSelected ? .white : Theme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Theme.apricotDark : Color.white.opacity(0.76))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Theme.apricotDark.opacity(0.35) : Theme.line.opacity(0.75), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WeekdayOption: Identifiable {
    let weekday: Int
    let shortTitle: String
    let mondayBasedIndex: Int

    var id: Int { weekday }

    static let ordered: [WeekdayOption] = [
        WeekdayOption(weekday: 2, shortTitle: "一", mondayBasedIndex: 0),
        WeekdayOption(weekday: 3, shortTitle: "二", mondayBasedIndex: 1),
        WeekdayOption(weekday: 4, shortTitle: "三", mondayBasedIndex: 2),
        WeekdayOption(weekday: 5, shortTitle: "四", mondayBasedIndex: 3),
        WeekdayOption(weekday: 6, shortTitle: "五", mondayBasedIndex: 4),
        WeekdayOption(weekday: 7, shortTitle: "六", mondayBasedIndex: 5),
        WeekdayOption(weekday: 1, shortTitle: "日", mondayBasedIndex: 6)
    ]
}

struct StepDots: View {
    let step: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...3, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? Theme.apricot : Theme.line)
                    .frame(height: 6)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
    }
}

private extension Array where Element: Identifiable {
    func uniquedByID() -> [Element] where Element.ID: Hashable {
        var seen = Set<Element.ID>()
        return filter { seen.insert($0.id).inserted }
    }
}

struct WidePickerRow<SelectionValue: Hashable, Content: View>: View {
    let title: String
    @Binding var selection: SelectionValue
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.muted)
            Spacer(minLength: 16)
            Picker(title, selection: $selection) {
                content
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .roundedBackground(Color.white.opacity(0.78), radius: 14)
    }
}

struct CourseTypeWheelPicker: View {
    @Binding var courseType: String
    let courseTypes: [String]

    var body: some View {
        Picker("课程类型", selection: $courseType) {
            ForEach(courseTypes, id: \.self) { type in
                Text(type)
                    .font(.headline)
                    .tag(type)
            }
        }
        .pickerStyle(.wheel)
        .labelsHidden()
        .frame(maxWidth: .infinity)
        .frame(height: 176)
        .clipped()
        .roundedBackground(Color.white.opacity(0.78), radius: 16)
    }
}
