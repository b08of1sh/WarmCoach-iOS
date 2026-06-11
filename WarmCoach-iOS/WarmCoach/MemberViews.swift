import SwiftUI
import UIKit

struct MemberDetailView: View {
    @EnvironmentObject private var store: CoachStore
    @State private var copiedPhone = false
    let member: Member
    let onEdit: () -> Void
    let onEditSession: (CourseSession) -> Void

    private var liveMember: Member {
        store.member(for: member.id) ?? member
    }

    private var sessions: [CourseSession] {
        store.sortedSessions.filter { $0.memberID == member.id }
    }

    private var phoneText: String {
        liveMember.phone.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            WarmBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Panel {
                        HStack(spacing: 14) {
                            AvatarView(member: liveMember, size: 68)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(liveMember.name)
                                    .font(.system(size: 22, weight: .bold))
                                CopyablePhoneText(
                                    phone: phoneText,
                                    copiedPhone: copiedPhone,
                                    onCopy: copyPhone
                                )
                            }
                            Spacer()
                            Text("剩余 \(liveMember.remainingHours) 课时")
                                .font(.caption.weight(.bold))
                                .foregroundColor(Theme.sage)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Theme.sage.opacity(0.14)))
                        }
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onEdit)
                    }

                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            InfoTile(title: "课程类型", value: liveMember.courseType, onTap: onEdit)
                            InfoTile(title: "默认提醒", value: "课前 \(liveMember.defaultReminderMinutes) 分钟", onTap: onEdit)
                        }
                        HStack(spacing: 12) {
                            InfoTile(title: "历史课程", value: "\(sessions.count) 次")
                            CopyableContactTile(phone: phoneText, copiedPhone: copiedPhone, onCopy: copyPhone, onEdit: onEdit)
                        }
                    }

                    Panel {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionTitle(title: "备注", systemImage: "note.text")
                            Text(liveMember.note.isEmpty ? "暂无备注" : liveMember.note)
                                .font(.body)
                                .foregroundColor(liveMember.note.isEmpty ? Theme.muted : Theme.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onEdit)
                    }

                    Panel {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(title: "历史课程", systemImage: "clock.arrow.circlepath")
                            if sessions.isEmpty {
                                EmptyBlock(systemImage: "calendar", title: "没有历史课程", text: "创建排课后会自动沉淀到这里。")
                            } else {
                                ForEach(sessions) { session in
                                    Button {
                                        onEditSession(session)
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(session.date.weekdayDateText)
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
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                }
                .padding(18)
            }
        }
        .navigationBarTitle(Text(liveMember.name), displayMode: .large)
    }

    private func copyPhone() {
        guard !phoneText.isEmpty else { return }
        UIPasteboard.general.string = phoneText
        copiedPhone = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            copiedPhone = false
        }
    }
}

struct InfoTile: View {
    let title: String
    let value: String
    var onTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(Theme.muted)
            Text(value)
                .font(.headline)
                .foregroundColor(Theme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .roundedBackground(Theme.paper.opacity(0.9), radius: 18)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.line.opacity(0.7), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}

struct CopyablePhoneText: View {
    let phone: String
    let copiedPhone: Bool
    let onCopy: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(phone.isEmpty ? "未填写联系方式" : phone)
                .foregroundColor(Theme.muted)
            if copiedPhone {
                Text("已复制")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(Theme.sage)
            }
        }
        .contentShape(Rectangle())
        .onLongPressGesture(perform: onCopy)
        .contextMenu {
            if !phone.isEmpty {
                Button(action: onCopy) {
                    Label("复制联系方式", systemImage: "doc.on.doc")
                }
            }
        }
    }
}

struct CopyableContactTile: View {
    let phone: String
    let copiedPhone: Bool
    let onCopy: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("联系方式")
                .font(.caption.weight(.semibold))
                .foregroundColor(Theme.muted)
            HStack(spacing: 6) {
                Text(phone.isEmpty ? "未填写" : phone)
                    .font(.headline)
                    .foregroundColor(Theme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                if copiedPhone {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(Theme.sage)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .roundedBackground(Theme.paper.opacity(0.9), radius: 18)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.line.opacity(0.7), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
        .onLongPressGesture(perform: onCopy)
        .contextMenu {
            if !phone.isEmpty {
                Button(action: onCopy) {
                    Label("复制联系方式", systemImage: "doc.on.doc")
                }
            }
        }
    }
}

struct MemberEditorView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var store: CoachStore

    private let existingMember: Member?
    @State private var name: String
    @State private var phone: String
    @State private var avatarTone: AvatarTone
    @State private var courseType: String
    @State private var remainingHours: Int
    @State private var defaultReminderMinutes: Int
    @State private var note: String

    init(member: Member?) {
        existingMember = member
        _name = State(initialValue: member?.name ?? "")
        _phone = State(initialValue: member?.phone ?? "")
        _avatarTone = State(initialValue: member?.avatarTone ?? AvatarTone.allCases.randomElement() ?? .peach)
        _courseType = State(initialValue: member?.courseType ?? defaultCourseTypes[0])
        _remainingHours = State(initialValue: member?.remainingHours ?? 10)
        _defaultReminderMinutes = State(initialValue: member?.defaultReminderMinutes ?? 30)
        _note = State(initialValue: member?.note ?? "")
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Panel {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("基础信息")
                                .font(.headline)
                            TextField("姓名", text: $name)
                                .textFieldStyle(.roundedBorder)
                            TextField("联系方式", text: $phone)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    Panel {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("课程")
                                .font(.headline)
                            Picker("课程类型", selection: $courseType) {
                                ForEach(store.courseTypes, id: \.self) { type in
                                    Text(type).tag(type)
                                }
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                Text("剩余 \(remainingHours) 课时")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(Theme.muted)
                                Picker("剩余课时", selection: $remainingHours) {
                                    ForEach(0...200, id: \.self) { hours in
                                        Text("\(hours) 课时").tag(hours)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 130)
                                .clipped()
                            }
                            Picker("默认提醒", selection: $defaultReminderMinutes) {
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
                                .frame(minHeight: 120)
                                .padding(8)
                                .roundedBackground(Color.white.opacity(0.9), radius: 12)
                        }
                    }
                }
                .padding(18)
            }
            .background(WarmBackground())
            .navigationBarTitle(Text(existingMember == nil ? "新增会员" : "编辑会员"), displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("保存") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }

    private func save() {
        let member = Member(
            id: existingMember?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
            avatarTone: avatarTone,
            courseType: courseType,
            remainingHours: remainingHours,
            defaultReminderMinutes: defaultReminderMinutes,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        store.upsertMember(member)
        presentationMode.wrappedValue.dismiss()
    }
}

func reminderTitle(_ minutes: Int) -> String {
    minutes == 60 ? "课前 1 小时" : "课前 \(minutes) 分钟"
}
