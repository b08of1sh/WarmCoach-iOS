import React from "react";
import { createRoot } from "react-dom/client";
import {
  Bell,
  CalendarDays,
  Check,
  ChevronLeft,
  ChevronRight,
  Clock3,
  Edit3,
  Home,
  Leaf,
  MessageSquareText,
  PauseCircle,
  Plus,
  Search,
  UserRound,
  UsersRound,
  X,
  XCircle
} from "lucide-react";
import { registerServiceWorker } from "./registerServiceWorker";
import "./styles.css";

const STATUS = {
  upcoming: { label: "待上课", tone: "apricot" },
  completed: { label: "已完成", tone: "green" },
  cancelled: { label: "已取消", tone: "muted" },
  leave: { label: "请假", tone: "coffee" },
  makeup: { label: "补课", tone: "mint" },
  noShow: { label: "爽约", tone: "rose" }
};

const COURSE_TYPES = ["力量训练", "普拉提", "体态调整", "燃脂训练", "康复训练"];
const REMINDERS = [
  { label: "课前 15 分钟", value: 15 },
  { label: "课前 30 分钟", value: 30 },
  { label: "课前 1 小时", value: 60 }
];

const initials = (name) => name.slice(0, 1);

const pad = (n) => String(n).padStart(2, "0");

function todayKey() {
  const now = new Date();
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
}

function addDays(dateKey, days) {
  const [year, month, day] = dateKey.split("-").map(Number);
  const date = new Date(year, month - 1, day + days);
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

function weekStart(dateKey) {
  const [year, month, day] = dateKey.split("-").map(Number);
  const date = new Date(year, month - 1, day);
  const diff = (date.getDay() + 6) % 7;
  return addDays(dateKey, -diff);
}

function dateLabel(dateKey, long = false) {
  const [year, month, day] = dateKey.split("-").map(Number);
  const date = new Date(year, month - 1, day);
  return new Intl.DateTimeFormat("zh-CN", {
    month: "short",
    day: "numeric",
    weekday: long ? "long" : "short"
  }).format(date);
}

function timeToMinutes(time) {
  const [hour, minute] = time.split(":").map(Number);
  return hour * 60 + minute;
}

function sessionStartDate(session) {
  const [year, month, day] = session.date.split("-").map(Number);
  const [hour, minute] = session.start.split(":").map(Number);
  return new Date(year, month - 1, day, hour, minute);
}

function formatTimeRange(session) {
  return `${session.start} - ${session.end}`;
}

function overlaps(a, b) {
  if (a.date !== b.date || a.status === "cancelled" || b.status === "cancelled") return false;
  return timeToMinutes(a.start) < timeToMinutes(b.end) && timeToMinutes(a.end) > timeToMinutes(b.start);
}

function makeSeedData() {
  const today = todayKey();
  const tomorrow = addDays(today, 1);
  const yesterday = addDays(today, -1);
  const twoDays = addDays(today, 2);

  const members = [
    {
      id: "m-1",
      name: "林若溪",
      phone: "138 1024 6620",
      avatarTone: "peach",
      courseType: "普拉提",
      remaining: 16,
      defaultReminder: 30,
      note: "肩颈容易紧张，训练前先做 5 分钟动态拉伸。"
    },
    {
      id: "m-2",
      name: "陈一诺",
      phone: "186 7201 9908",
      avatarTone: "green",
      courseType: "力量训练",
      remaining: 8,
      defaultReminder: 60,
      note: "偏好上午课程，深蹲重量逐步推进。"
    },
    {
      id: "m-3",
      name: "周言",
      phone: "139 3108 4412",
      avatarTone: "latte",
      courseType: "体态调整",
      remaining: 11,
      defaultReminder: 15,
      note: "久坐，注意髋屈肌放松。"
    },
    {
      id: "m-4",
      name: "许曼",
      phone: "131 8890 2036",
      avatarTone: "sage",
      courseType: "燃脂训练",
      remaining: 20,
      defaultReminder: 30,
      note: "喜欢明确训练清单，课程后发送简短反馈。"
    }
  ];

  const sessions = [
    {
      id: "s-1",
      memberId: "m-1",
      date: today,
      start: "09:00",
      end: "10:00",
      courseType: "普拉提",
      status: "upcoming",
      reminder: 30,
      note: "核心稳定训练"
    },
    {
      id: "s-2",
      memberId: "m-2",
      date: today,
      start: "10:30",
      end: "11:30",
      courseType: "力量训练",
      status: "upcoming",
      reminder: 60,
      note: "下肢力量"
    },
    {
      id: "s-3",
      memberId: "m-3",
      date: today,
      start: "18:00",
      end: "19:00",
      courseType: "体态调整",
      status: "makeup",
      reminder: 15,
      note: "上周请假补课"
    },
    {
      id: "s-4",
      memberId: "m-4",
      date: tomorrow,
      start: "08:30",
      end: "09:30",
      courseType: "燃脂训练",
      status: "upcoming",
      reminder: 30,
      note: ""
    },
    {
      id: "s-5",
      memberId: "m-1",
      date: twoDays,
      start: "16:00",
      end: "17:00",
      courseType: "普拉提",
      status: "upcoming",
      reminder: 30,
      note: ""
    },
    {
      id: "s-6",
      memberId: "m-2",
      date: yesterday,
      start: "10:00",
      end: "11:00",
      courseType: "力量训练",
      status: "completed",
      reminder: 60,
      note: "已消课"
    }
  ];

  return { members, sessions };
}

function useLocalStorageState(key, initialValue) {
  const [state, setState] = React.useState(() => {
    const stored = localStorage.getItem(key);
    if (stored) {
      try {
        return JSON.parse(stored);
      } catch {
        return initialValue;
      }
    }
    return initialValue;
  });

  React.useEffect(() => {
    localStorage.setItem(key, JSON.stringify(state));
  }, [key, state]);

  return [state, setState];
}

function useSessionReminders(sessions, members) {
  const [permission, setPermission] = React.useState(
    typeof Notification === "undefined" ? "unsupported" : Notification.permission
  );

  React.useEffect(() => {
    if (typeof Notification === "undefined" || Notification.permission !== "granted") return undefined;
    const timers = sessions
      .filter((session) => session.status === "upcoming" || session.status === "makeup")
      .map((session) => {
        const notifyAt = sessionStartDate(session).getTime() - session.reminder * 60 * 1000;
        const delay = notifyAt - Date.now();
        if (delay <= 0 || delay > 2147483647) return null;
        return window.setTimeout(() => {
          const member = members.find((item) => item.id === session.memberId);
          new Notification("课程即将开始", {
            body: `${member?.name || "会员"} ${formatTimeRange(session)} · ${session.courseType}`
          });
        }, delay);
      })
      .filter(Boolean);

    return () => timers.forEach((timer) => window.clearTimeout(timer));
  }, [sessions, members]);

  async function requestPermission() {
    if (typeof Notification === "undefined") {
      setPermission("unsupported");
      return;
    }
    const result = await Notification.requestPermission();
    setPermission(result);
  }

  return { permission, requestPermission };
}

function App() {
  const seed = React.useMemo(makeSeedData, []);
  const [members, setMembers] = useLocalStorageState("warmcoach-members", seed.members);
  const [sessions, setSessions] = useLocalStorageState("warmcoach-sessions", seed.sessions);
  const [activeView, setActiveView] = React.useState("home");
  const [selectedDate, setSelectedDate] = React.useState(todayKey());
  const [selectedMemberId, setSelectedMemberId] = React.useState(members[0]?.id || "");
  const [wizard, setWizard] = React.useState(null);
  const [memberEditor, setMemberEditor] = React.useState(null);
  const { permission, requestPermission } = useSessionReminders(sessions, members);

  const sortedSessions = React.useMemo(
    () => [...sessions].sort((a, b) => `${a.date} ${a.start}`.localeCompare(`${b.date} ${b.start}`)),
    [sessions]
  );

  function memberById(memberId) {
    return members.find((member) => member.id === memberId);
  }

  function findConflicts(candidate, ignoreId = null) {
    return sessions.filter((session) => session.id !== ignoreId && overlaps(session, candidate));
  }

  function upsertSession(session) {
    setSessions((current) => {
      const exists = current.some((item) => item.id === session.id);
      if (exists) return current.map((item) => (item.id === session.id ? session : item));
      return [...current, session];
    });
  }

  function upsertMember(member) {
    setMembers((current) => {
      const exists = current.some((item) => item.id === member.id);
      if (exists) return current.map((item) => (item.id === member.id ? member : item));
      return [...current, member];
    });
    setSelectedMemberId(member.id);
    setActiveView("members");
  }

  function changeStatus(sessionId, status) {
    setSessions((current) => current.map((item) => (item.id === sessionId ? { ...item, status } : item)));
  }

  function consumeHour(session) {
    if (session.status === "completed") return;
    const member = memberById(session.memberId);
    if (!member || member.remaining <= 0) return;
    setMembers((current) =>
      current.map((item) => (item.id === member.id ? { ...item, remaining: Math.max(0, item.remaining - 1) } : item))
    );
    changeStatus(session.id, "completed");
  }

  const currentMember = members.find((member) => member.id === selectedMemberId) || members[0];

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="brand">
          <div className="brand-mark">
            <Leaf size={22} />
          </div>
          <div>
            <strong>WarmCoach</strong>
            <span>私教排课</span>
          </div>
        </div>

        <nav className="nav-list" aria-label="主导航">
          <NavButton icon={Home} label="首页日程" active={activeView === "home"} onClick={() => setActiveView("home")} />
          <NavButton icon={CalendarDays} label="周课表" active={activeView === "week"} onClick={() => setActiveView("week")} />
          <NavButton icon={UsersRound} label="会员页" active={activeView === "members"} onClick={() => setActiveView("members")} />
          <NavButton icon={Bell} label="提醒中心" active={activeView === "reminders"} onClick={() => setActiveView("reminders")} />
        </nav>

        <div className="sidebar-note">
          <Clock3 size={18} />
          <span>{dateLabel(todayKey(), true)}</span>
        </div>
      </aside>

      <main className="main">
        <TopBar
          permission={permission}
          onNotify={requestPermission}
          onAdd={() => setWizard({ mode: "create", baseDate: selectedDate })}
        />

        {activeView === "home" && (
          <HomeView
            sessions={sortedSessions}
            members={members}
            selectedDate={selectedDate}
            setSelectedDate={setSelectedDate}
            memberById={memberById}
            findConflicts={findConflicts}
            onEdit={(session) => setWizard({ mode: "edit", session })}
            onCancel={(session) => changeStatus(session.id, "cancelled")}
            onComplete={consumeHour}
          />
        )}

        {activeView === "week" && (
          <WeekView
            sessions={sortedSessions}
            members={members}
            selectedDate={selectedDate}
            setSelectedDate={setSelectedDate}
            memberById={memberById}
            onEdit={(session) => setWizard({ mode: "edit", session })}
            onAdd={(date) => setWizard({ mode: "create", baseDate: date })}
          />
        )}

        {activeView === "members" && (
          <MembersView
            members={members}
            sessions={sortedSessions}
            selectedMember={currentMember}
            setSelectedMemberId={setSelectedMemberId}
            setMembers={setMembers}
            memberById={memberById}
            onEditSession={(session) => setWizard({ mode: "edit", session })}
            onAddMember={() => setMemberEditor({ mode: "create" })}
            onEditMember={(member) => setMemberEditor({ mode: "edit", member })}
          />
        )}

        {activeView === "reminders" && (
          <RemindersView
            sessions={sortedSessions}
            members={members}
            memberById={memberById}
            onEdit={(session) => setWizard({ mode: "edit", session })}
            onStatus={changeStatus}
          />
        )}
      </main>

      {wizard && (
        <CourseWizard
          wizard={wizard}
          members={members}
          sessions={sessions}
          memberById={memberById}
          findConflicts={findConflicts}
          onClose={() => setWizard(null)}
          onSave={(session) => {
            upsertSession(session);
            setWizard(null);
            setSelectedDate(session.date);
          }}
        />
      )}

      {memberEditor && (
        <MemberEditor
          editor={memberEditor}
          onClose={() => setMemberEditor(null)}
          onSave={(member) => {
            upsertMember(member);
            setMemberEditor(null);
          }}
        />
      )}
    </div>
  );
}

function NavButton({ icon: Icon, label, active, onClick }) {
  return (
    <button className={`nav-button ${active ? "active" : ""}`} type="button" onClick={onClick} title={label}>
      <Icon size={20} />
      <span>{label}</span>
    </button>
  );
}

function TopBar({ permission, onNotify, onAdd }) {
  return (
    <header className="topbar">
      <div>
        <p className="eyebrow">今日工作台</p>
        <h1>排课、提醒和会员状态，一屏看清</h1>
      </div>
      <div className="topbar-actions">
        <button className="icon-text ghost" type="button" onClick={onNotify} title="开启本地通知">
          <Bell size={18} />
          <span>{permission === "granted" ? "通知已开启" : "开启提醒"}</span>
        </button>
        <button className="primary-action" type="button" onClick={onAdd}>
          <Plus size={20} />
          <span>新增排课</span>
        </button>
      </div>
    </header>
  );
}

function HomeView({
  sessions,
  members,
  selectedDate,
  setSelectedDate,
  memberById,
  findConflicts,
  onEdit,
  onCancel,
  onComplete
}) {
  const todaySessions = sessions.filter((session) => session.date === selectedDate);
  const openSessions = sessions.filter((session) => session.status === "upcoming" || session.status === "makeup");
  const nextSession = openSessions.find((session) => sessionStartDate(session) >= new Date());
  const week = weekStart(selectedDate);
  const weekDays = Array.from({ length: 7 }, (_, index) => addDays(week, index));
  const completedThisWeek = sessions.filter(
    (session) => weekDays.includes(session.date) && session.status === "completed"
  ).length;
  const weekCount = sessions.filter((session) => weekDays.includes(session.date) && session.status !== "cancelled").length;
  const conflictPairs = sessions
    .flatMap((session) => findConflicts(session, session.id).map((conflict) => [session, conflict]))
    .filter(([a, b], index, list) => list.findIndex(([x, y]) => x.id === b.id && y.id === a.id) === -1);

  return (
    <section className="view-stack">
      <div className="stats-grid">
        <StatCard label="本周课程" value={weekCount} detail="含补课，不含取消" />
        <StatCard label="已完成课时" value={completedThisWeek} detail="本周已消课" />
        <StatCard label="会员剩余课时" value={members.reduce((sum, item) => sum + item.remaining, 0)} detail="全部会员合计" />
      </div>

      <div className="split-grid">
        <section className="panel schedule-panel">
          <div className="panel-title-row">
            <div>
              <p className="eyebrow">首页日程</p>
              <h2>{selectedDate === todayKey() ? "今天课程" : dateLabel(selectedDate, true)}</h2>
            </div>
            <input
              className="date-input"
              type="date"
              value={selectedDate}
              onChange={(event) => setSelectedDate(event.target.value)}
              aria-label="选择日期"
            />
          </div>

          <div className="course-list">
            {todaySessions.length === 0 ? (
              <EmptyState icon={CalendarDays} title="这天还没有课程" text="点右上角新增排课，三步就能保存。" />
            ) : (
              todaySessions.map((session) => (
                <CourseCard
                  key={session.id}
                  session={session}
                  member={memberById(session.memberId)}
                  isSoon={nextSession?.id === session.id}
                  onEdit={() => onEdit(session)}
                  onCancel={() => onCancel(session)}
                  onComplete={() => onComplete(session)}
                />
              ))
            )}
          </div>
        </section>

        <aside className="side-stack">
          <section className="panel next-panel">
            <p className="eyebrow">即将开始</p>
            {nextSession ? (
              <div className="next-content">
                <Avatar member={memberById(nextSession.memberId)} />
                <div>
                  <h2>{memberById(nextSession.memberId)?.name}</h2>
                  <p>{nextSession.date} · {formatTimeRange(nextSession)}</p>
                  <span className={`status-pill ${STATUS[nextSession.status].tone}`}>
                    {STATUS[nextSession.status].label}
                  </span>
                </div>
              </div>
            ) : (
              <EmptyState icon={Check} title="没有待开始课程" text="当前排期已经很清爽。" compact />
            )}
          </section>

          <section className="panel conflict-panel">
            <div className="panel-title-row compact">
              <div>
                <p className="eyebrow">冲突提醒</p>
                <h2>{conflictPairs.length ? `${conflictPairs.length} 组冲突` : "暂无冲突"}</h2>
              </div>
              <PauseCircle size={24} />
            </div>
            <div className="conflict-list">
              {conflictPairs.length === 0 ? (
                <p className="muted-text">同一教练的时间段没有重叠课程。</p>
              ) : (
                conflictPairs.map(([a, b]) => (
                  <div className="conflict-item" key={`${a.id}-${b.id}`}>
                    <strong>{a.date} {a.start}</strong>
                    <span>{memberById(a.memberId)?.name} 与 {memberById(b.memberId)?.name}</span>
                  </div>
                ))
              )}
            </div>
          </section>
        </aside>
      </div>
    </section>
  );
}

function StatCard({ label, value, detail }) {
  return (
    <article className="stat-card">
      <span>{label}</span>
      <strong>{value}</strong>
      <p>{detail}</p>
    </article>
  );
}

function WeekView({ sessions, selectedDate, setSelectedDate, memberById, onEdit, onAdd }) {
  const start = weekStart(selectedDate);
  const days = Array.from({ length: 7 }, (_, index) => addDays(start, index));

  return (
    <section className="view-stack">
      <div className="week-toolbar">
        <button className="icon-button" type="button" onClick={() => setSelectedDate(addDays(selectedDate, -7))} title="上一周">
          <ChevronLeft size={20} />
        </button>
        <div>
          <p className="eyebrow">周课表</p>
          <h2>{days[0]} 至 {days[6]}</h2>
        </div>
        <button className="icon-button" type="button" onClick={() => setSelectedDate(addDays(selectedDate, 7))} title="下一周">
          <ChevronRight size={20} />
        </button>
      </div>

      <div className="week-grid">
        {days.map((day) => {
          const daySessions = sessions.filter((session) => session.date === day);
          return (
            <section className={`day-column ${day === todayKey() ? "today" : ""}`} key={day}>
              <div className="day-header">
                <span>{dateLabel(day)}</span>
                <button className="icon-button small" type="button" onClick={() => onAdd(day)} title="这天新增课程">
                  <Plus size={16} />
                </button>
              </div>
              <div className="mini-course-list">
                {daySessions.length === 0 ? (
                  <p className="muted-text small-copy">空</p>
                ) : (
                  daySessions.map((session) => (
                    <button className="mini-course" type="button" key={session.id} onClick={() => onEdit(session)}>
                      <span>{session.start}</span>
                      <strong>{memberById(session.memberId)?.name}</strong>
                      <em>{STATUS[session.status].label}</em>
                    </button>
                  ))
                )}
              </div>
            </section>
          );
        })}
      </div>
    </section>
  );
}

function MembersView({
  members,
  sessions,
  selectedMember,
  setSelectedMemberId,
  setMembers,
  onEditSession,
  onAddMember,
  onEditMember
}) {
  const [query, setQuery] = React.useState("");
  const filtered = members.filter((member) => member.name.includes(query) || member.phone.includes(query));
  const memberSessions = sessions.filter((session) => session.memberId === selectedMember?.id);

  function updateNote(note) {
    setMembers((current) => current.map((member) => (member.id === selectedMember.id ? { ...member, note } : member)));
  }

  return (
    <section className="members-layout">
      <aside className="panel member-list-panel">
        <div className="member-list-head">
          <div className="search-field">
            <Search size={18} />
            <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="搜索会员" />
          </div>
          <button className="icon-button" type="button" onClick={onAddMember} title="新增会员">
            <Plus size={18} />
          </button>
        </div>
        <div className="member-list">
          {filtered.map((member) => (
            <button
              className={`member-row ${selectedMember?.id === member.id ? "active" : ""}`}
              type="button"
              key={member.id}
              onClick={() => setSelectedMemberId(member.id)}
            >
              <Avatar member={member} />
              <span>
                <strong>{member.name}</strong>
                <em>{member.courseType} · 剩余 {member.remaining}</em>
              </span>
            </button>
          ))}
        </div>
      </aside>

      <section className="panel member-detail">
        {selectedMember ? (
          <>
            <div className="member-hero">
              <Avatar member={selectedMember} large />
              <div>
                <p className="eyebrow">会员页</p>
                <h2>{selectedMember.name}</h2>
                <p>{selectedMember.phone}</p>
              </div>
              <span className="remain-badge">剩余 {selectedMember.remaining} 课时</span>
              <button className="icon-button" type="button" onClick={() => onEditMember(selectedMember)} title="编辑会员">
                <Edit3 size={18} />
              </button>
            </div>

            <div className="member-meta-grid">
              <InfoTile label="课程类型" value={selectedMember.courseType} />
              <InfoTile label="默认提醒" value={`课前 ${selectedMember.defaultReminder} 分钟`} />
              <InfoTile label="历史课程" value={`${memberSessions.length} 次`} />
            </div>

            <label className="note-editor">
              <span>备注</span>
              <textarea value={selectedMember.note} onChange={(event) => updateNote(event.target.value)} rows={4} />
            </label>

            <div className="history-section">
              <div className="panel-title-row compact">
                <h3>历史课程</h3>
              </div>
              <div className="history-list">
                {memberSessions.map((session) => (
                  <button className="history-row" type="button" key={session.id} onClick={() => onEditSession(session)}>
                    <span>{session.date}</span>
                    <strong>{formatTimeRange(session)}</strong>
                    <em>{STATUS[session.status].label}</em>
                  </button>
                ))}
              </div>
            </div>
          </>
        ) : (
          <EmptyState icon={UserRound} title="没有会员" text="会员会显示在这里。" />
        )}
      </section>
    </section>
  );
}

function MemberEditor({ editor, onClose, onSave }) {
  const editing = editor.mode === "edit";
  const source = editor.member;
  const [draft, setDraft] = React.useState(() => ({
    id: source?.id || `m-${crypto.randomUUID()}`,
    name: source?.name || "",
    phone: source?.phone || "",
    avatarTone: source?.avatarTone || "peach",
    courseType: source?.courseType || COURSE_TYPES[0],
    remaining: source?.remaining ?? 10,
    defaultReminder: source?.defaultReminder || 30,
    note: source?.note || ""
  }));

  const canSave = draft.name.trim().length > 0 && Number(draft.remaining) >= 0;

  function save() {
    if (!canSave) return;
    onSave({
      ...draft,
      name: draft.name.trim(),
      phone: draft.phone.trim(),
      remaining: Number(draft.remaining),
      defaultReminder: Number(draft.defaultReminder)
    });
  }

  return (
    <div className="modal-backdrop" role="dialog" aria-modal="true">
      <section className="wizard member-editor">
        <div className="wizard-header">
          <div>
            <p className="eyebrow">{editing ? "编辑会员" : "新增会员"}</p>
            <h2>会员资料</h2>
          </div>
          <button className="icon-button" type="button" onClick={onClose} title="关闭">
            <X size={20} />
          </button>
        </div>

        <div className="form-grid member-form">
          <label>
            <span>姓名</span>
            <input value={draft.name} onChange={(event) => setDraft({ ...draft, name: event.target.value })} />
          </label>
          <label>
            <span>联系方式</span>
            <input value={draft.phone} onChange={(event) => setDraft({ ...draft, phone: event.target.value })} />
          </label>
          <label>
            <span>课程类型</span>
            <select value={draft.courseType} onChange={(event) => setDraft({ ...draft, courseType: event.target.value })}>
              {COURSE_TYPES.map((type) => (
                <option key={type}>{type}</option>
              ))}
            </select>
          </label>
          <label>
            <span>剩余课时</span>
            <input
              min="0"
              type="number"
              value={draft.remaining}
              onChange={(event) => setDraft({ ...draft, remaining: event.target.value })}
            />
          </label>
          <label>
            <span>默认提醒</span>
            <select
              value={draft.defaultReminder}
              onChange={(event) => setDraft({ ...draft, defaultReminder: Number(event.target.value) })}
            >
              {REMINDERS.map((item) => (
                <option value={item.value} key={item.value}>{item.label}</option>
              ))}
            </select>
          </label>
          <label>
            <span>头像色</span>
            <select value={draft.avatarTone} onChange={(event) => setDraft({ ...draft, avatarTone: event.target.value })}>
              <option value="peach">暖杏</option>
              <option value="green">柔和绿</option>
              <option value="latte">浅咖</option>
              <option value="sage">鼠尾草绿</option>
            </select>
          </label>
          <label className="wide-field">
            <span>备注</span>
            <textarea rows={4} value={draft.note} onChange={(event) => setDraft({ ...draft, note: event.target.value })} />
          </label>
        </div>

        <footer className="wizard-actions">
          <button className="icon-text ghost" type="button" onClick={onClose}>
            <X size={18} />
            <span>取消</span>
          </button>
          <button className="primary-action" type="button" disabled={!canSave} onClick={save}>
            <Check size={18} />
            <span>保存会员</span>
          </button>
        </footer>
      </section>
    </div>
  );
}

function InfoTile({ label, value }) {
  return (
    <article className="info-tile">
      <span>{label}</span>
      <strong>{value}</strong>
    </article>
  );
}

function RemindersView({ sessions, memberById, onEdit, onStatus }) {
  const now = new Date();
  const pending = sessions.filter((session) => {
    const start = sessionStartDate(session);
    return (session.status === "upcoming" || session.status === "makeup") && start >= now;
  });
  const special = sessions.filter((session) => ["cancelled", "leave", "makeup", "noShow"].includes(session.status));

  return (
    <section className="split-grid">
      <section className="panel">
        <div className="panel-title-row">
          <div>
            <p className="eyebrow">提醒中心</p>
            <h2>待上课与待确认</h2>
          </div>
          <Bell size={24} />
        </div>
        <div className="course-list">
          {pending.length === 0 ? (
            <EmptyState icon={Check} title="没有待提醒课程" text="后续课程保存后会出现在这里。" />
          ) : (
            pending.map((session) => (
              <ReminderRow
                key={session.id}
                session={session}
                member={memberById(session.memberId)}
                onEdit={() => onEdit(session)}
                onStatus={onStatus}
              />
            ))
          )}
        </div>
      </section>

      <section className="panel">
        <div className="panel-title-row">
          <div>
            <p className="eyebrow">记录</p>
            <h2>补课、取消和异常</h2>
          </div>
          <MessageSquareText size={24} />
        </div>
        <div className="course-list">
          {special.map((session) => (
            <ReminderRow
              key={session.id}
              session={session}
              member={memberById(session.memberId)}
              onEdit={() => onEdit(session)}
              onStatus={onStatus}
            />
          ))}
        </div>
      </section>
    </section>
  );
}

function ReminderRow({ session, member, onEdit, onStatus }) {
  return (
    <article className="reminder-row">
      <Avatar member={member} />
      <div>
        <strong>{member?.name}</strong>
        <span>{session.date} · {formatTimeRange(session)} · {session.courseType}</span>
      </div>
      <span className={`status-pill ${STATUS[session.status].tone}`}>{STATUS[session.status].label}</span>
      <div className="row-actions">
        <button className="icon-button small" type="button" onClick={onEdit} title="编辑课程">
          <Edit3 size={15} />
        </button>
        {session.status !== "completed" && (
          <button className="icon-button small" type="button" onClick={() => onStatus(session.id, "completed")} title="标记完成">
            <Check size={15} />
          </button>
        )}
      </div>
    </article>
  );
}

function CourseCard({ session, member, isSoon, onEdit, onCancel, onComplete }) {
  return (
    <article className={`course-card ${isSoon ? "soon" : ""}`}>
      <Avatar member={member} />
      <div className="course-main">
        <div className="course-title-row">
          <h3>{member?.name || "未知会员"}</h3>
          <span className={`status-pill ${STATUS[session.status].tone}`}>{STATUS[session.status].label}</span>
        </div>
        <p>{formatTimeRange(session)} · {session.courseType}</p>
        {session.note && <small>{session.note}</small>}
      </div>
      <div className="card-actions">
        <button className="icon-button" type="button" onClick={onEdit} title="编辑课程">
          <Edit3 size={18} />
        </button>
        {session.status !== "completed" && (
          <button className="icon-button" type="button" onClick={onComplete} title="标记完成">
            <Check size={18} />
          </button>
        )}
        {session.status !== "cancelled" && (
          <button className="icon-button danger" type="button" onClick={onCancel} title="取消课程">
            <XCircle size={18} />
          </button>
        )}
      </div>
    </article>
  );
}

function CourseWizard({ wizard, members, memberById, findConflicts, onClose, onSave }) {
  const editing = wizard.mode === "edit";
  const source = wizard.session;
  const defaultMember = editing ? memberById(source.memberId) : members[0];
  const [step, setStep] = React.useState(1);
  const [draft, setDraft] = React.useState(() => ({
    id: source?.id || `s-${crypto.randomUUID()}`,
    memberId: source?.memberId || defaultMember?.id || "",
    date: source?.date || wizard.baseDate || todayKey(),
    start: source?.start || "09:00",
    end: source?.end || "10:00",
    courseType: source?.courseType || defaultMember?.courseType || COURSE_TYPES[0],
    status: source?.status || "upcoming",
    reminder: source?.reminder || defaultMember?.defaultReminder || 30,
    note: source?.note || ""
  }));
  const selectedMember = memberById(draft.memberId);
  const conflicts = findConflicts(draft, editing ? draft.id : null);
  const validTime = timeToMinutes(draft.start) < timeToMinutes(draft.end);

  React.useEffect(() => {
    if (!selectedMember) return;
    setDraft((current) => ({
      ...current,
      courseType: current.courseType || selectedMember.courseType,
      reminder: current.reminder || selectedMember.defaultReminder
    }));
  }, [selectedMember]);

  function chooseMember(member) {
    setDraft((current) => ({
      ...current,
      memberId: member.id,
      courseType: member.courseType,
      reminder: member.defaultReminder
    }));
  }

  function save() {
    if (!validTime || conflicts.length > 0) return;
    onSave(draft);
  }

  return (
    <div className="modal-backdrop" role="dialog" aria-modal="true">
      <section className="wizard">
        <div className="wizard-header">
          <div>
            <p className="eyebrow">{editing ? "编辑课程" : "新增排课"}</p>
            <h2>{step === 1 ? "选择会员" : step === 2 ? "选择日期和时间段" : "确认提醒并保存"}</h2>
          </div>
          <button className="icon-button" type="button" onClick={onClose} title="关闭">
            <X size={20} />
          </button>
        </div>

        <div className="stepper" aria-label="排课步骤">
          {[1, 2, 3].map((item) => (
            <span className={item <= step ? "active" : ""} key={item} />
          ))}
        </div>

        {step === 1 && (
          <div className="wizard-member-grid">
            {members.map((member) => (
              <button
                className={`member-choice ${draft.memberId === member.id ? "active" : ""}`}
                type="button"
                key={member.id}
                onClick={() => chooseMember(member)}
              >
                <Avatar member={member} />
                <span>
                  <strong>{member.name}</strong>
                  <em>{member.courseType} · 剩余 {member.remaining}</em>
                </span>
              </button>
            ))}
          </div>
        )}

        {step === 2 && (
          <div className="form-grid">
            <label>
              <span>日期</span>
              <input type="date" value={draft.date} onChange={(event) => setDraft({ ...draft, date: event.target.value })} />
            </label>
            <label>
              <span>开始时间</span>
              <input type="time" value={draft.start} onChange={(event) => setDraft({ ...draft, start: event.target.value })} />
            </label>
            <label>
              <span>结束时间</span>
              <input type="time" value={draft.end} onChange={(event) => setDraft({ ...draft, end: event.target.value })} />
            </label>
            <label>
              <span>课程类型</span>
              <select value={draft.courseType} onChange={(event) => setDraft({ ...draft, courseType: event.target.value })}>
                {COURSE_TYPES.map((type) => (
                  <option key={type}>{type}</option>
                ))}
              </select>
            </label>
            {!validTime && <div className="warning-box">结束时间需要晚于开始时间。</div>}
            {conflicts.length > 0 && (
              <div className="warning-box">
                该时间段与 {conflicts.map((item) => memberById(item.memberId)?.name).join("、")} 的课程冲突。
              </div>
            )}
          </div>
        )}

        {step === 3 && (
          <div className="confirm-stack">
            <div className="confirm-card">
              <Avatar member={selectedMember} large />
              <div>
                <strong>{selectedMember?.name}</strong>
                <span>{draft.date} · {draft.start} - {draft.end}</span>
                <em>{draft.courseType}</em>
              </div>
            </div>
            <label>
              <span>提醒规则</span>
              <select value={draft.reminder} onChange={(event) => setDraft({ ...draft, reminder: Number(event.target.value) })}>
                {REMINDERS.map((item) => (
                  <option value={item.value} key={item.value}>{item.label}</option>
                ))}
              </select>
            </label>
            <label>
              <span>课程状态</span>
              <select value={draft.status} onChange={(event) => setDraft({ ...draft, status: event.target.value })}>
                {Object.entries(STATUS).map(([value, item]) => (
                  <option value={value} key={value}>{item.label}</option>
                ))}
              </select>
            </label>
            <label>
              <span>备注</span>
              <textarea rows={3} value={draft.note} onChange={(event) => setDraft({ ...draft, note: event.target.value })} />
            </label>
            {conflicts.length > 0 && <div className="warning-box">存在时间冲突，调整时间后再保存。</div>}
          </div>
        )}

        <footer className="wizard-actions">
          <button className="icon-text ghost" type="button" onClick={() => (step === 1 ? onClose() : setStep(step - 1))}>
            <ChevronLeft size={18} />
            <span>{step === 1 ? "取消" : "上一步"}</span>
          </button>
          {step < 3 ? (
            <button
              className="primary-action"
              type="button"
              disabled={step === 2 && (!validTime || conflicts.length > 0)}
              onClick={() => setStep(step + 1)}
            >
              <span>下一步</span>
              <ChevronRight size={18} />
            </button>
          ) : (
            <button className="primary-action" type="button" disabled={!validTime || conflicts.length > 0} onClick={save}>
              <Check size={18} />
              <span>保存课程</span>
            </button>
          )}
        </footer>
      </section>
    </div>
  );
}

function Avatar({ member, large = false }) {
  return (
    <div className={`avatar ${large ? "large" : ""} ${member?.avatarTone || "peach"}`} aria-hidden="true">
      {member ? initials(member.name) : "?"}
    </div>
  );
}

function EmptyState({ icon: Icon, title, text, compact = false }) {
  return (
    <div className={`empty-state ${compact ? "compact" : ""}`}>
      <Icon size={compact ? 20 : 28} />
      <strong>{title}</strong>
      <p>{text}</p>
    </div>
  );
}

createRoot(document.getElementById("root")).render(<App />);
registerServiceWorker();
