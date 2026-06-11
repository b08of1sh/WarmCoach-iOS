import Foundation
import UserNotifications

final class CoachStore: ObservableObject {
    @Published var members: [Member] = [] {
        didSet { save() }
    }

    @Published var sessions: [CourseSession] = [] {
        didSet {
            save()
            NotificationScheduler.scheduleUpcomingSessions(sessions, members: members)
        }
    }

    @Published var courseTypes: [String] = [] {
        didSet { saveCourseTypes() }
    }

    @Published var leaveRecords: [CoachLeaveRecord] = [] {
        didSet { save() }
    }

    private let storageKey = "warmcoach.data.v1"
    private let courseTypesStorageKey = "warmcoach.courseTypes.v1"

    init() {
        load()
    }

    func member(for id: UUID) -> Member? {
        members.first { $0.id == id }
    }

    func upsertMember(_ member: Member) {
        if let index = members.firstIndex(where: { $0.id == member.id }) {
            members[index] = member
        } else {
            members.append(member)
        }
        NotificationScheduler.scheduleUpcomingSessions(sessions, members: members)
    }

    func addCourseType(_ type: String) {
        let trimmedType = type.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedType.isEmpty else { return }
        guard !courseTypes.contains(where: { $0.caseInsensitiveCompare(trimmedType) == .orderedSame }) else { return }
        courseTypes.append(trimmedType)
    }

    func upsertSession(_ session: CourseSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            let previous = sessions[index]
            let preparedSession = preparedForStorage(session, previous: previous)
            reconcileCompletedHours(previous: previous, next: preparedSession)
            sessions[index] = preparedSession
        } else {
            let preparedSession = preparedForStorage(session, previous: nil)
            reconcileCompletedHours(previous: nil, next: preparedSession)
            sessions.append(preparedSession)
        }
    }

    func updateStatus(_ session: CourseSession, status: CourseStatus) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        var updatedSession = sessions[index]
        updatedSession.status = status
        upsertSession(updatedSession)
    }

    func complete(_ session: CourseSession) {
        updateStatus(session, status: .completed)
    }

    func deleteSession(_ session: CourseSession) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        reconcileCompletedHours(previous: sessions[index], next: nil)
        sessions.remove(at: index)
    }

    func restoredSession(from session: CourseSession) -> CourseSession {
        var restoredSession = session
        restoredSession.status = session.statusAfterRestore
        restoredSession.restoreStatus = nil
        return restoredSession
    }

    func addLeaveRecord(startDate: Date, endDate: Date, note: String) {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedStart = min(startDate, endDate)
        let normalizedEnd = max(startDate, endDate)
        let affectedSessions = sessions.filter {
            $0.status.isVisibleInSchedule &&
            $0.startsAt < normalizedEnd &&
            $0.endsAt > normalizedStart
        }
        let affectedSessionIDs = affectedSessions.map(\.id)

        for session in affectedSessions {
            var cancelledSession = session
            cancelledSession.status = .cancelled
            upsertSession(cancelledSession)
        }

        let record = CoachLeaveRecord(
            id: UUID(),
            startDate: normalizedStart,
            endDate: normalizedEnd,
            note: trimmedNote,
            affectedSessionIDs: affectedSessionIDs
        )
        leaveRecords.insert(record, at: 0)
    }

    private func preparedForStorage(_ session: CourseSession, previous: CourseSession?) -> CourseSession {
        var preparedSession = session

        if preparedSession.status.isExceptionRecord {
            if let previousStatus = previous?.status, previousStatus.isVisibleInSchedule {
                preparedSession.restoreStatus = previousStatus
            } else if let previousRestoreStatus = previous?.restoreStatus, previousRestoreStatus.isVisibleInSchedule {
                preparedSession.restoreStatus = previousRestoreStatus
            } else if preparedSession.restoreStatus?.isVisibleInSchedule != true {
                preparedSession.restoreStatus = .upcoming
            }
        } else {
            preparedSession.restoreStatus = nil
        }

        return preparedSession
    }

    private func reconcileCompletedHours(previous: CourseSession?, next: CourseSession?) {
        if let previous, previous.status.consumesMemberHours {
            updateRemainingHours(for: previous.memberID, delta: 1)
        }
        if let next, next.status.consumesMemberHours {
            updateRemainingHours(for: next.memberID, delta: -1)
        }
    }

    private func updateRemainingHours(for memberID: UUID, delta: Int) {
        guard let memberIndex = members.firstIndex(where: { $0.id == memberID }) else { return }
        members[memberIndex].remainingHours = max(0, members[memberIndex].remainingHours + delta)
    }

    func conflicts(for candidate: CourseSession, ignoring ignoredID: UUID? = nil) -> [CourseSession] {
        sessions.filter { session in
            session.id != ignoredID &&
            session.status.isVisibleInSchedule &&
            candidate.status.isVisibleInSchedule &&
            Calendar.current.isDate(session.date, inSameDayAs: candidate.date) &&
            session.startMinutes < candidate.endMinutes &&
            session.endMinutes > candidate.startMinutes
        }
    }

    var sortedSessions: [CourseSession] {
        sessions.sorted { first, second in
            if Calendar.current.isDate(first.date, inSameDayAs: second.date) {
                return first.startMinutes < second.startMinutes
            }
            return first.startsAt < second.startsAt
        }
    }

    private func load() {
        if let decodedTypes = UserDefaults.standard.stringArray(forKey: courseTypesStorageKey), !decodedTypes.isEmpty {
            courseTypes = decodedTypes
        } else {
            courseTypes = defaultCourseTypes
        }

        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode(CoachData.self, from: data)
        else {
            let seed = CoachStore.seedData()
            members = seed.members
            sessions = seed.sessions
            return
        }
        members = decoded.members
        sessions = decoded.sessions
        leaveRecords = decoded.leaveRecords
    }

    private func save() {
        let payload = CoachData(members: members, sessions: sessions, leaveRecords: leaveRecords)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func saveCourseTypes() {
        UserDefaults.standard.set(courseTypes, forKey: courseTypesStorageKey)
    }

    private static func seedData() -> CoachData {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let twoDays = calendar.date(byAdding: .day, value: 2, to: today) ?? today

        let m1 = Member(id: UUID(), name: "林若溪", phone: "138 1024 6620", avatarTone: .peach, courseType: "普拉提", remainingHours: 16, defaultReminderMinutes: 30, note: "肩颈容易紧张，训练前先做 5 分钟动态拉伸。")
        let m2 = Member(id: UUID(), name: "陈一诺", phone: "186 7201 9908", avatarTone: .green, courseType: "力量训练", remainingHours: 8, defaultReminderMinutes: 60, note: "偏好上午课程，深蹲重量逐步推进。")
        let m3 = Member(id: UUID(), name: "周言", phone: "139 3108 4412", avatarTone: .latte, courseType: "体态调整", remainingHours: 11, defaultReminderMinutes: 15, note: "久坐，注意髋屈肌放松。")
        let m4 = Member(id: UUID(), name: "许曼", phone: "131 8890 2036", avatarTone: .sage, courseType: "燃脂训练", remainingHours: 20, defaultReminderMinutes: 30, note: "喜欢明确训练清单，课程后发送简短反馈。")

        return CoachData(
            members: [m1, m2, m3, m4],
            sessions: [
                CourseSession(id: UUID(), memberID: m1.id, date: today, startMinutes: 540, endMinutes: 600, courseType: "普拉提", status: .upcoming, reminderMinutes: 30, note: "核心稳定训练"),
                CourseSession(id: UUID(), memberID: m2.id, date: today, startMinutes: 630, endMinutes: 690, courseType: "力量训练", status: .upcoming, reminderMinutes: 60, note: "下肢力量"),
                CourseSession(id: UUID(), memberID: m3.id, date: today, startMinutes: 1080, endMinutes: 1140, courseType: "体态调整", status: .upcoming, reminderMinutes: 15, note: "体态调整复训"),
                CourseSession(id: UUID(), memberID: m4.id, date: tomorrow, startMinutes: 510, endMinutes: 570, courseType: "燃脂训练", status: .upcoming, reminderMinutes: 30, note: ""),
                CourseSession(id: UUID(), memberID: m1.id, date: twoDays, startMinutes: 960, endMinutes: 1020, courseType: "普拉提", status: .upcoming, reminderMinutes: 30, note: ""),
                CourseSession(id: UUID(), memberID: m2.id, date: yesterday, startMinutes: 600, endMinutes: 660, courseType: "力量训练", status: .completed, reminderMinutes: 60, note: "已消课")
            ]
        )
    }
}

enum NotificationScheduler {
    enum PermissionState {
        case authorized
        case needsRequest
        case denied
    }

    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func checkPermission(completion: @escaping (PermissionState) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let state: PermissionState
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                state = .authorized
            case .notDetermined:
                state = .needsRequest
            case .denied:
                state = .denied
            @unknown default:
                state = .denied
            }

            DispatchQueue.main.async {
                completion(state)
            }
        }
    }

    static func scheduleUpcomingSessions(_ sessions: [CourseSession], members: [Member]) {
        let center = UNUserNotificationCenter.current()
        let identifiers = sessions.map { "warmcoach-\($0.id.uuidString)" }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)

        for session in sessions where session.status == .upcoming {
            let fireDate = session.startsAt.addingTimeInterval(TimeInterval(-session.reminderMinutes * 60))
            guard fireDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            let memberName = members.first { $0.id == session.memberID }?.name ?? "会员"
            content.title = "课程即将开始"
            content.body = "\(memberName) \(session.timeRangeText) · \(session.courseType)"
            content.sound = .default

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "warmcoach-\(session.id.uuidString)", content: content, trigger: trigger)
            center.add(request)
        }
    }
}
