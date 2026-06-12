import Foundation
import SwiftUI

enum CourseStatus: String, CaseIterable, Identifiable, Codable {
    case upcoming
    case completed
    case cancelled
    case leave
    case noShow

    var id: String { rawValue }

    var title: String {
        switch self {
        case .upcoming: return "待上课"
        case .completed: return "已完成"
        case .cancelled: return "已取消"
        case .leave: return "请假"
        case .noShow: return "爽约"
        }
    }

    var tint: Color {
        switch self {
        case .upcoming: return Theme.apricot
        case .completed: return Theme.sage
        case .cancelled: return Theme.muted
        case .leave: return Theme.coffee
        case .noShow: return Theme.rose
        }
    }

    var isVisibleInSchedule: Bool {
        self == .upcoming || self == .completed
    }

    var isExceptionRecord: Bool {
        self == .cancelled || self == .leave || self == .noShow
    }

    var consumesMemberHours: Bool {
        self == .completed || self == .noShow
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        if value == "makeup" {
            self = .cancelled
        } else {
            self = CourseStatus(rawValue: value) ?? .upcoming
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum AvatarTone: String, CaseIterable, Codable, Identifiable {
    case peach
    case sage
    case latte
    case green

    var id: String { rawValue }

    var title: String {
        switch self {
        case .peach: return "暖杏"
        case .sage: return "鼠尾草绿"
        case .latte: return "浅咖"
        case .green: return "柔和绿"
        }
    }

    var color: Color {
        switch self {
        case .peach: return Theme.apricot
        case .sage: return Theme.sage
        case .latte: return Theme.coffee
        case .green: return Theme.softGreen
        }
    }
}

struct Member: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var phone: String
    var avatarTone: AvatarTone
    var courseType: String
    var remainingHours: Int
    var defaultReminderMinutes: Int
    var note: String
}

struct CourseSession: Identifiable, Codable, Equatable {
    var id: UUID
    var memberID: UUID
    var date: Date
    var startMinutes: Int
    var endMinutes: Int
    var courseType: String
    var status: CourseStatus
    var restoreStatus: CourseStatus? = nil
    var reminderMinutes: Int
    var note: String

    var startsAt: Date {
        Calendar.current.date(byAdding: .minute, value: startMinutes, to: Calendar.current.startOfDay(for: date)) ?? date
    }

    var endsAt: Date {
        Calendar.current.date(byAdding: .minute, value: endMinutes, to: Calendar.current.startOfDay(for: date)) ?? date
    }

    var timeRangeText: String {
        "\(Self.timeText(startMinutes)) - \(Self.timeText(endMinutes))"
    }

    var statusAfterRestore: CourseStatus {
        guard let restoreStatus, restoreStatus.isVisibleInSchedule else { return .upcoming }
        return restoreStatus
    }

    static func timeText(_ minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }
}

struct CoachLeaveRecord: Identifiable, Codable, Equatable {
    var id: UUID
    var startDate: Date
    var endDate: Date
    var note: String
    var affectedSessionIDs: [UUID]
}

struct MemberLeaveRecord: Identifiable, Codable, Equatable {
    var id: UUID
    var memberID: UUID
    var startDate: Date
    var endDate: Date
    var note: String
    var affectedSessionIDs: [UUID]
}

struct CoachData: Codable {
    var members: [Member]
    var sessions: [CourseSession]
    var leaveRecords: [CoachLeaveRecord]
    var memberLeaveRecords: [MemberLeaveRecord]

    init(
        members: [Member],
        sessions: [CourseSession],
        leaveRecords: [CoachLeaveRecord] = [],
        memberLeaveRecords: [MemberLeaveRecord] = []
    ) {
        self.members = members
        self.sessions = sessions
        self.leaveRecords = leaveRecords
        self.memberLeaveRecords = memberLeaveRecords
    }

    private enum CodingKeys: String, CodingKey {
        case members
        case sessions
        case leaveRecords
        case memberLeaveRecords
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        members = try container.decode([Member].self, forKey: .members)
        sessions = try container.decode([CourseSession].self, forKey: .sessions)
        leaveRecords = try container.decodeIfPresent([CoachLeaveRecord].self, forKey: .leaveRecords) ?? []
        memberLeaveRecords = try container.decodeIfPresent([MemberLeaveRecord].self, forKey: .memberLeaveRecords) ?? []
    }
}

let defaultCourseTypes = ["力量训练", "普拉提", "体态调整", "燃脂训练", "康复训练"]
let reminderOptions = [15, 30, 60]
