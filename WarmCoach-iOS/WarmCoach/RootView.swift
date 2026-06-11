import SwiftUI
import UIKit

struct CourseSheet: Identifiable {
    let id = UUID()
    var session: CourseSession?
    var baseDate: Date
    var draft: CourseSession? = nil
}

struct MemberSheet: Identifiable {
    let id = UUID()
    var member: Member?
}

enum NotificationPermissionPrompt: Identifiable {
    case request
    case settings

    var id: String {
        switch self {
        case .request: return "request"
        case .settings: return "settings"
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: CoachStore
    @State private var selectedTab = 0
    @State private var courseSheet: CourseSheet?
    @State private var memberSheet: MemberSheet?
    @State private var notificationPrompt: NotificationPermissionPrompt?
    @State private var checkedNotificationPermission = false
    @State private var showsLaunchScreen = true

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                DashboardView(
                    onAdd: { courseSheet = CourseSheet(session: nil, baseDate: Date()) },
                    onEdit: { courseSheet = CourseSheet(session: $0, baseDate: $0.date) },
                    onReschedule: { courseSheet = CourseSheet(session: nil, baseDate: $0.date, draft: $0) }
                )
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首页")
                }
                .tag(0)

                WeekScheduleView(
                    onAdd: { courseSheet = CourseSheet(session: nil, baseDate: $0) },
                    onEdit: { courseSheet = CourseSheet(session: $0, baseDate: $0.date) }
                )
                .tabItem {
                    Image(systemName: "calendar")
                    Text("周课表")
                }
                .tag(1)

                MembersView(
                    onAdd: { memberSheet = MemberSheet(member: nil) },
                    onEdit: { memberSheet = MemberSheet(member: $0) },
                    onEditSession: { courseSheet = CourseSheet(session: $0, baseDate: $0.date) }
                )
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("会员")
                }
                .tag(2)

                ProfileView()
                    .tabItem {
                        Image(systemName: "person.crop.circle.fill")
                        Text("我的")
                    }
                    .tag(3)
            }

            if showsLaunchScreen {
                LaunchLoadingView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .accentColor(Theme.apricotDark)
        .onAppear(perform: finishLaunchScreen)
        .alert(item: $notificationPrompt) { prompt in
            switch prompt {
            case .request:
                return Alert(
                    title: Text("开启课程提醒"),
                    message: Text("允许通知后，WarmCoach 可以在课程开始前提醒你。"),
                    primaryButton: .default(Text("开启")) {
                        NotificationScheduler.requestAuthorization()
                    },
                    secondaryButton: .cancel(Text("稍后"))
                )
            case .settings:
                return Alert(
                    title: Text("通知权限未开启"),
                    message: Text("你可以在系统设置里开启通知，这样课程开始前才能收到提醒。"),
                    primaryButton: .default(Text("去设置")) {
                        openAppSettings()
                    },
                    secondaryButton: .cancel(Text("稍后"))
                )
            }
        }
        .sheet(item: $courseSheet) { sheet in
            CourseFlowView(sheet: sheet)
                .environmentObject(store)
        }
        .sheet(item: $memberSheet) { sheet in
            MemberEditorView(member: sheet.member)
                .environmentObject(store)
        }
    }

    private func finishLaunchScreen() {
        guard showsLaunchScreen else {
            checkNotificationPermissionIfNeeded()
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            withAnimation(.easeOut(duration: 0.25)) {
                showsLaunchScreen = false
            }
            checkNotificationPermissionIfNeeded()
        }
    }

    private func checkNotificationPermissionIfNeeded() {
        guard !checkedNotificationPermission else { return }
        checkedNotificationPermission = true

        NotificationScheduler.checkPermission { state in
            switch state {
            case .authorized:
                break
            case .needsRequest:
                notificationPrompt = .request
            case .denied:
                notificationPrompt = .settings
            }
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

struct DashboardView: View {
    @EnvironmentObject private var store: CoachStore
    @State private var conflictingRestoreSession: CourseSession?
    @State private var showsExceptionHistory = false
    let onAdd: () -> Void
    let onEdit: (CourseSession) -> Void
    let onReschedule: (CourseSession) -> Void

    private var todaySessions: [CourseSession] {
        store.sortedSessions.filter {
            Calendar.current.isDateInToday($0.date) &&
            $0.status == .upcoming
        }
    }

    private var todayScheduleSessions: [CourseSession] {
        store.sortedSessions.filter {
            Calendar.current.isDateInToday($0.date) &&
            $0.status.isVisibleInSchedule
        }
    }

    private var completedToday: Int {
        todayScheduleSessions.filter { $0.status == .completed }.count
    }

    private var nextSession: CourseSession? {
        store.sortedSessions.first { session in
            session.status == .upcoming && session.startsAt >= Date()
        }
    }

    private var todayExceptionSessions: [CourseSession] {
        store.sortedSessions.filter {
            Calendar.current.isDateInToday($0.date) &&
            $0.status.isExceptionRecord
        }
    }

    private var allExceptionSessions: [CourseSession] {
        store.sortedSessions.filter { $0.status.isExceptionRecord }
    }

    var body: some View {
        NavigationView {
            ZStack {
                WarmBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HeaderBlock(title: "今日工作台", subtitle: "")

                        TodayOverviewCard(
                            remaining: todaySessions.count,
                            total: todayScheduleSessions.count,
                            completed: completedToday,
                            exceptions: todayExceptionSessions.count
                        )

                        if let nextSession {
                            NextCoursePanel(session: nextSession)
                        }

                        Panel {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionTitle(title: "进行中", systemImage: "clock")
                                if todaySessions.isEmpty {
                                    EmptyBlock(systemImage: "calendar.badge.plus", title: "今天还没有课程", text: "点右上角新增排课，三步保存。")
                                } else {
                                    ForEach(todaySessions) { session in
                                        TodayCourseActionCard(
                                            session: session,
                                            member: store.member(for: session.memberID),
                                            isHighlighted: session.id == nextSession?.id,
                                            onEdit: { onEdit(session) },
                                            onStatus: { status in
                                                if status == .completed {
                                                    store.complete(session)
                                                } else {
                                                    store.updateStatus(session, status: status)
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                        }

                        Panel {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionTitleButton(title: "取消和异常", systemImage: "text.bubble", buttonTitle: "全部") {
                                    showsExceptionHistory = true
                                }
                                if todayExceptionSessions.isEmpty {
                                    EmptyBlock(systemImage: "tray", title: "今天暂无记录", text: "取消、请假和爽约会显示在这里。")
                                } else {
                                    ForEach(todayExceptionSessions) { session in
                                        StaticRecordRow(
                                            session: session,
                                            member: store.member(for: session.memberID),
                                            onRestore: { restoreException(session) }
                                        )
                                    }
                                }
                            }
                        }

                    }
                    .padding(18)
                }
            }
            .navigationBarTitle(Text("WarmCoach"), displayMode: .large)
            .alert("原时间段已被占用", isPresented: Binding(
                get: { conflictingRestoreSession != nil },
                set: { isPresented in
                    if !isPresented {
                        conflictingRestoreSession = nil
                    }
                }
            )) {
                Button("去新建课程") {
                    guard let session = conflictingRestoreSession else { return }
                    conflictingRestoreSession = nil
                    store.deleteSession(session)
                    onReschedule(draftForReschedule(from: session))
                }
                Button("先不处理", role: .cancel) {
                    conflictingRestoreSession = nil
                }
            } message: {
                Text("这节课原来的时间已经有其他课程了。我会帮你带着会员和课程信息进入新建排课，重新选择时间后保存。")
            }
            .sheet(isPresented: $showsExceptionHistory) {
                ExceptionHistoryView(
                    sessions: allExceptionSessions,
                    memberName: { store.member(for: $0)?.name ?? "未知会员" }
                )
            }
            .navigationBarItems(
                trailing:
                    Button(action: onAdd) {
                        Image(systemName: "plus")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(Theme.apricotDark))
                    }
                    .buttonStyle(PlainButtonStyle())
            )
        }
    }

    private func restoreException(_ session: CourseSession) {
        let restoredSession = store.restoredSession(from: session)
        if store.conflicts(for: restoredSession, ignoring: session.id).isEmpty {
            store.upsertSession(restoredSession)
        } else {
            conflictingRestoreSession = session
        }
    }

    private func draftForReschedule(from session: CourseSession) -> CourseSession {
        var draftSession = session
        draftSession.id = UUID()
        draftSession.status = .upcoming
        draftSession.restoreStatus = nil
        return draftSession
    }
}

struct WeekScheduleView: View {
    @State private var anchorDate = Date()
    @State private var query = ""
    @State private var showsGridSchedule = false
    @EnvironmentObject private var store: CoachStore
    let onAdd: (Date) -> Void
    let onEdit: (CourseSession) -> Void

    var body: some View {
        NavigationView {
            ZStack {
                WarmBackground()
                VStack(spacing: 14) {
                    HStack {
                        Button { anchorDate = Calendar.current.date(byAdding: .day, value: -7, to: anchorDate) ?? anchorDate } label: {
                            Image(systemName: "chevron.left")
                        }
                        Spacer()
                        VStack(spacing: 3) {
                            Text("周课表")
                                .font(.headline)
                            Text("\(anchorDate.weekDays().first?.shortDateText ?? "") 至 \(anchorDate.weekDays().last?.shortDateText ?? "")")
                                .font(.caption)
                                .foregroundColor(Theme.muted)
                        }
                        Spacer()
                        Button { anchorDate = Calendar.current.date(byAdding: .day, value: 7, to: anchorDate) ?? anchorDate } label: {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .padding(.horizontal, 18)

                    SearchField(text: $query, placeholder: "搜索会员姓名")
                        .padding(.horizontal, 18)

                    if showsGridSchedule {
                        WeeklyTimeGridView(
                            weekDays: anchorDate.weekDays(),
                            sessions: weekSessions,
                            memberName: { store.member(for: $0)?.name ?? "未知会员" },
                            onSelect: onEdit
                        )
                    } else {
                        GeometryReader { proxy in
                            ScrollViewReader { reader in
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(alignment: .top, spacing: 12) {
                                        ForEach(anchorDate.weekDays(), id: \.self) { day in
                                            WeekDayColumn(day: day, sessions: sessions(on: day), searchText: query, onAdd: { onAdd(day) }, onEdit: onEdit)
                                                .frame(width: dayColumnWidth(for: day), height: proxy.size.height)
                                                .id(day)
                                        }
                                    }
                                    .frame(height: proxy.size.height)
                                    .padding(.horizontal, 18)
                                    .padding(.bottom, 12)
                                }
                                .frame(height: proxy.size.height)
                                .onAppear {
                                    centerToday(in: reader)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 14)
            }
            .navigationBarTitle(Text("周课表"), displayMode: .large)
            .navigationBarItems(trailing: Button(showsGridSchedule ? "列表" : "切换") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showsGridSchedule.toggle()
                }
            })
        }
    }

    private func dayColumnWidth(for day: Date) -> CGFloat {
        Calendar.current.isDateInToday(day) ? 248 : 190
    }

    private func centerToday(in reader: ScrollViewProxy) {
        guard let today = anchorDate.weekDays().first(where: Calendar.current.isDateInToday) else { return }
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.25)) {
                reader.scrollTo(today, anchor: .center)
            }
        }
    }

    private var weekSessions: [CourseSession] {
        store.sortedSessions.filter { session in
            anchorDate.weekDays().contains { Calendar.current.isDate($0, inSameDayAs: session.date) } &&
            session.status.isVisibleInSchedule &&
            matchesSearch(session)
        }
    }

    private func sessions(on day: Date) -> [CourseSession] {
        store.sortedSessions.filter {
            Calendar.current.isDate($0.date, inSameDayAs: day) &&
            $0.status.isVisibleInSchedule &&
            matchesSearch($0)
        }
    }

    private func matchesSearch(_ session: CourseSession) -> Bool {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return true }
        return store.member(for: session.memberID)?.name.localizedCaseInsensitiveContains(trimmedQuery) == true
    }
}

struct MembersView: View {
    @EnvironmentObject private var store: CoachStore
    @State private var query = ""
    let onAdd: () -> Void
    let onEdit: (Member) -> Void
    let onEditSession: (CourseSession) -> Void

    private var filteredMembers: [Member] {
        guard !query.isEmpty else { return store.members }
        return store.members.filter { $0.name.contains(query) || $0.phone.contains(query) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                WarmBackground()
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Theme.muted)
                        TextField("搜索会员", text: $query)
                    }
                    .padding(12)
                    .roundedBackground(Color.white.opacity(0.92), radius: 14)
                    .padding(.horizontal, 18)
                    .padding(.top, 10)

                    List {
                    ForEach(filteredMembers) { member in
                        NavigationLink(destination:
                            MemberDetailView(member: member, onEdit: { onEdit(member) }, onEditSession: onEditSession)
                        ) {
                            HStack(spacing: 12) {
                                AvatarView(member: member)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(member.name)
                                        .font(.headline)
                                    Text("\(member.courseType) · 剩余 \(member.remainingHours) 课时")
                                        .font(.subheadline)
                                        .foregroundColor(Theme.muted)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                }
            }
            .navigationBarTitle(Text("会员"), displayMode: .large)
            .navigationBarItems(
                trailing: Button(action: onAdd) {
                    Image(systemName: "person.badge.plus")
                }
            )
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject private var store: CoachStore
    @State private var newCourseType = ""
    @State private var selectedDetail: ProfileDetail?
    @State private var showsLeaveRequest = false
    @State private var showsLeaveHistory = false

    private var activeMembers: Int {
        store.members.filter { $0.remainingHours > 0 }.count
    }

    private var activeMemberList: [Member] {
        store.members.filter { $0.remainingHours > 0 }
    }

    private var weekSessions: Int {
        weekSessionList.count
    }

    private var weekSessionList: [CourseSession] {
        let days = Date().weekDays()
        return store.sortedSessions.filter { session in
            days.contains { Calendar.current.isDate($0, inSameDayAs: session.date) } && session.status.isVisibleInSchedule
        }
    }

    private var totalRemainingHours: Int {
        store.members.reduce(0) { $0 + $1.remainingHours }
    }

    var body: some View {
        NavigationView {
            ZStack {
                WarmBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Panel {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionTitle(title: "个人中心", systemImage: "person.crop.circle")
                                MemberCompareCard(total: store.members.count, active: activeMembers)
                                HStack(spacing: 10) {
                                    ProfileMetricButton(title: "活跃", value: "\(activeMembers)", unit: "人", caption: "仍有课时", tint: Theme.sage) {
                                        selectedDetail = .activeMembers
                                    }
                                    ProfileMetricButton(title: "本周", value: "\(weekSessions)", unit: "节", caption: "时间网格", tint: Theme.apricotDark) {
                                        selectedDetail = .weekSessions
                                    }
                                    ProfileMetricButton(title: "课时", value: "\(totalRemainingHours)", unit: "节", caption: "剩余合计", tint: Theme.coffee) {
                                        selectedDetail = .remainingHours
                                    }
                                }
                            }
                        }

                        Panel {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionTitle(title: "工作室", systemImage: "figure.strengthtraining.traditional")
                                InfoLine(title: "身份", value: "私教")
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("请假休息")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Theme.muted)
                                    HStack(spacing: 10) {
                                        Button {
                                            showsLeaveRequest = true
                                        } label: {
                                            Label("我要请假", systemImage: "moon.zzz.fill")
                                                .font(.subheadline.weight(.bold))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.apricotDark))
                                        }
                                        .buttonStyle(PlainButtonStyle())

                                        Button {
                                            showsLeaveHistory = true
                                        } label: {
                                            Label("休假记录", systemImage: "list.bullet.rectangle")
                                                .font(.subheadline.weight(.bold))
                                                .foregroundColor(Theme.coffee)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.coffee.opacity(0.12)))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("课程类型")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Theme.muted)
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 8)], alignment: .leading, spacing: 8) {
                                        ForEach(store.courseTypes, id: \.self) { type in
                                            Text(type)
                                                .font(.caption.weight(.semibold))
                                                .foregroundColor(Theme.coffee)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 8)
                                                .background(Capsule().fill(Theme.coffee.opacity(0.10)))
                                        }
                                    }
                                }
                                HStack(spacing: 8) {
                                    TextField("新增课程类型", text: $newCourseType)
                                        .textFieldStyle(.roundedBorder)
                                        .onSubmit(addCourseType)
                                    Button(action: addCourseType) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(Theme.apricotDark)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .disabled(newCourseType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                            }
                        }

                        Panel {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionTitle(title: "数据", systemImage: "internaldrive")
                                InfoLine(title: "存储", value: "本机")
                                InfoLine(title: "会员资料", value: "\(store.members.count) 条")
                                InfoLine(title: "课程记录", value: "\(store.sessions.count) 条")
                            }
                        }
                    }
                    .padding(18)
                }
            }
            .navigationBarTitle(Text("我的"), displayMode: .large)
            .sheet(item: $selectedDetail) { detail in
                ProfileDetailSheet(
                    detail: detail,
                    members: store.members,
                    activeMembers: activeMemberList,
                    weekSessions: weekSessionList,
                    memberName: { store.member(for: $0)?.name ?? "未知会员" }
                )
            }
            .sheet(isPresented: $showsLeaveRequest) {
                CoachLeaveRequestView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showsLeaveHistory) {
                CoachLeaveHistoryView(records: store.leaveRecords)
            }
        }
    }

    private func addCourseType() {
        store.addCourseType(newCourseType)
        newCourseType = ""
    }
}

enum ProfileDetail: String, Identifiable {
    case activeMembers
    case weekSessions
    case remainingHours

    var id: String { rawValue }

    var title: String {
        switch self {
        case .activeMembers: return "活跃会员"
        case .weekSessions: return "本周课程"
        case .remainingHours: return "剩余课时"
        }
    }
}
