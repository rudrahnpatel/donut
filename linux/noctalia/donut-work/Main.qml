import QtQuick 6.11
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons

// Donut Work: notes what you are working on every 30 s.
//
// A tick records the projects busy at that moment: those Claude Code wrote
// a session log for in the last 2 minutes, else the coding app you are
// active in (input within `idleMinutes`), plus "manual" while a manual
// session is on. Ticks are kept raw, so calling a project personal (or
// work again) recounts the whole day at once.
//
// Work time is derived: ticks with at least one work project, joined into
// sessions when closer than `idleMinutes`. Ticks with only personal
// projects are personal time. The day file at
// ~/.local/share/donut/work/YYYY-MM-DD.json keeps the raw ticks plus the
// derived work sessions, which the Donut app reads for its dial.
Item {
  id: root

  property var pluginApi: null

  readonly property var cfg: pluginApi?.pluginSettings || ({})
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  readonly property int idleMinutes: cfg.idleMinutes ?? defaults.idleMinutes ?? 5
  readonly property bool countClaude: cfg.countClaudeCode ?? defaults.countClaudeCode ?? true
  readonly property var workApps: splitList(cfg.workApps ?? defaults.workApps ?? "")
  readonly property var browserKeywords: splitList(cfg.browserKeywords ?? defaults.browserKeywords ?? "")
  readonly property var personalProjects: splitList(cfg.personalProjects ?? defaults.personalProjects ?? "")

  readonly property int tickMs: 30000
  readonly property string dataDir: Quickshell.env("HOME") + "/.local/share/donut/work"

  // Raw ticks: [epoch ms, [projects]], and spans dropped as not work at all.
  property var ticks: []
  property var excluded: []
  property string dayKey: ""
  // Whether today's file has been read back (once per day).
  property bool restored: false
  // A session started by hand stays on until stopped.
  property bool manual: false
  // The last tick: did it count as work, and why.
  property bool working: false
  property string reason: ""
  property var claudeProjects: []
  // Bumped on every change so the derived values recompute.
  property int revision: 0

  // Derived from the ticks with the current work/personal split.
  readonly property var day: {
    revision;
    personalProjects;
    return derive();
  }
  readonly property var sessions: day.sessions
  readonly property int todaySeconds: day.workSeconds
  readonly property int personalSeconds: day.personalSeconds
  // Project → seconds over the day, personal ones included.
  readonly property var projectSeconds: day.projectSeconds

  function splitList(text) {
    return text.split(",").map(s => s.trim().toLowerCase()).filter(s => s.length > 0);
  }

  function isPersonal(project) {
    return personalProjects.indexOf(project.toLowerCase()) >= 0;
  }

  function pad(n) {
    return n < 10 ? "0" + n : "" + n;
  }

  function keyFor(ms) {
    const d = new Date(ms);
    return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate());
  }

  function formatDuration(seconds) {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    return h > 0 ? h + "h " + pad(m) + "m" : m + "m";
  }

  function isExcluded(ms) {
    return excluded.some(r => ms > r[0] && ms <= r[1]);
  }

  // Work sessions, work and personal seconds, and per-project seconds.
  function derive() {
    const gap = idleMinutes * 60000 + tickMs;
    const sessions = [];
    const projectSeconds = {};
    let personal = 0;
    let last = null;
    for (const [ms, projects] of ticks) {
      if (isExcluded(ms))
        continue;
      for (const p of projects)
        projectSeconds[p] = (projectSeconds[p] || 0) + tickMs / 1000;
      const work = projects.filter(p => !isPersonal(p));
      if (work.length === 0) {
        personal += tickMs / 1000;
        continue;
      }
      if (!last || ms - last.end > gap) {
        last = {
          "start": ms - tickMs,
          "end": ms,
          "manual": false,
          "projects": {},
          "personal": {}
        };
        sessions.push(last);
      }
      last.end = ms;
      last.manual = last.manual || projects.indexOf("manual") >= 0;
      for (const p of projects) {
        const bucket = isPersonal(p) ? last.personal : last.projects;
        bucket[p] = (bucket[p] || 0) + tickMs / 1000;
      }
    }
    let workMs = 0;
    for (const s of sessions)
      workMs += s.end - s.start;
    return {
      "sessions": sessions,
      "workSeconds": Math.round(workMs / 1000),
      "personalSeconds": personal,
      "projectSeconds": projectSeconds
    };
  }

  // ── inputs ──────────────────────────────────────────────────────────────

  IdleMonitor {
    id: idle
    timeout: root.idleMinutes * 60
    // A playing video holds an inhibitor; that is not you working.
    respectInhibitors: false
  }

  function isWorkApp(appId, title) {
    const app = (appId || "").toLowerCase();
    if (workApps.indexOf(app) >= 0)
      return true;
    const browser = /firefox|chrom|brave|vivaldi|zen|librewolf|edge|opera/.test(app);
    if (!browser)
      return false;
    const t = (title || "").toLowerCase();
    return browserKeywords.some(k => t.indexOf(k) >= 0);
  }

  // Claude Code appends to ~/.claude/projects/<project>/<session>.jsonl as
  // it works. Each line carries the working directory at the time, which
  // wanders into subfolders, so the project is the first one: where the
  // session started.
  Process {
    id: claudeScan
    command: ["sh", "-c", "find \"$HOME/.claude/projects\" -name '*.jsonl' -mmin -2 2>/dev/null " + "| while read -r f; do head -c 200000 \"$f\" | grep -o -m 1 '\"cwd\":\"[^\"]*\"' | head -n 1; done " + "| sed 's/\"cwd\":\"//; s/\"$//' | sort -u"]
    stdout: StdioCollector {
      onStreamFinished: {
        const dirs = text.split("\n").filter(l => l.length > 0);
        root.claudeProjects = dirs.map(d => d.split("/").filter(x => x).pop() || d);
        root.tick();
      }
    }
  }

  // ── ticks ───────────────────────────────────────────────────────────────

  function tick() {
    const now = Date.now();
    rollDay(now);
    const top = ToplevelManager.activeToplevel;
    const appId = top ? top.appId : "";
    const active = !idle.isIdle;
    const claude = countClaude ? claudeProjects : [];
    let projects = [];
    if (claude.length > 0)
      projects = claude.slice();
    else if (active && isWorkApp(appId, top ? top.title : ""))
      projects = [appId];
    if (manual)
      projects.push("manual");
    const work = projects.filter(p => !isPersonal(p));
    working = work.length > 0;
    if (working)
      reason = (claude.length > 0 ? "Claude Code · " : "") + work.join(", ");
    else if (projects.length > 0)
      reason = "Personal · " + projects.join(", ");
    else
      reason = active ? "Not a work app" : "Idle";
    if (projects.length === 0)
      return;
    ticks.push([now, projects]);
    save();
  }

  function rollDay(now) {
    const key = keyFor(now);
    if (key === dayKey)
      return;
    dayKey = key;
    restored = false;
    ticks = [];
    excluded = [];
    revision++;
    dayFile.path = dataDir + "/" + key + ".json";
  }

  function save() {
    revision++;
    dayFile.setText(JSON.stringify({
      "v": 2,
      "day": dayKey,
      "sessions": sessions,
      "excluded": excluded,
      "ticks": ticks
    }));
  }

  // Makes [project] personal (or work again); the day recounts.
  function setPersonal(project, personal) {
    if (!pluginApi)
      return;
    const name = project.toLowerCase();
    const list = personalProjects.filter(p => p !== name);
    if (personal)
      list.push(name);
    pluginApi.pluginSettings.personalProjects = list.join(", ");
    pluginApi.saveSettings();
    Qt.callLater(save);
  }

  function toggleManual() {
    manual = !manual;
    tick();
  }

  // Drops a work session's span entirely (it wasn't work at all).
  function discard(session) {
    excluded.push([session.start, session.end]);
    save();
  }

  // Version 1 files kept only sessions with per-project seconds. Each
  // becomes evenly spread ticks: a project busy for n of the session's N
  // slots is put in n of them, spaced out.
  function ticksFromSessions(old) {
    const out = [];
    for (const s of old) {
      const n = Math.max(1, Math.round((s.end - s.start) / tickMs));
      const counts = {};
      for (const p in s.projects)
        counts[p] = Math.min(n, Math.round(s.projects[p] / (tickMs / 1000)));
      for (let i = 0; i < n; i++) {
        const busy = Object.keys(counts).filter(p => (i * counts[p]) % n < counts[p]);
        if (busy.length > 0)
          out.push([s.start + (i + 1) * tickMs, busy]);
      }
    }
    return out;
  }

  FileView {
    id: dayFile
    // Picks up today after a shell restart.
    onLoaded: {
      if (root.restored)
        return;
      root.restored = true;
      try {
        const data = JSON.parse(text());
        if (data.day !== root.dayKey)
          return;
        const saved = Array.isArray(data.ticks) ? data.ticks : root.ticksFromSessions(data.sessions || []);
        const since = saved.length > 0 ? saved[saved.length - 1][0] : 0;
        root.ticks = saved.concat(root.ticks.filter(t => t[0] > since));
        root.excluded = data.excluded || [];
        root.save();
      } catch (e) {
        Logger.w("DonutWork", "Could not read", path, e);
      }
    }
  }

  Process {
    id: makeDir
    command: ["mkdir", "-p", root.dataDir]
    onExited: root.rollDay(Date.now())
  }

  Timer {
    interval: root.tickMs
    running: true
    repeat: true
    onTriggered: {
      if (root.countClaude)
        claudeScan.running = true;
      else
        root.tick();
    }
  }

  Component.onCompleted: makeDir.running = true

  IpcHandler {
    target: "plugin:donut-work"

    // Starts or stops a manual session, e.g. from a key binding:
    // qs -c noctalia-shell ipc call plugin:donut-work toggle
    function toggle(): void {
      root.toggleManual();
    }

    function status(): string {
      return root.formatDuration(root.todaySeconds) + " work, " + root.formatDuration(root.personalSeconds) + " personal · " + root.reason;
    }
  }
}
