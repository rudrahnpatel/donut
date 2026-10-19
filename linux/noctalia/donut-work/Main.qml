import QtQuick 6.11
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons

// Donut Work: counts working time by itself, every 30 s.
//
// Working means a manual session is on, or Claude Code wrote to a session
// log in the last 2 minutes (busy in that project), or you are active
// (input within `idleMinutes`) in a coding app or on a work site in a
// browser. Ticks closer together than `idleMinutes` make one session.
// Personal projects never count: Claude Code busy only in them means you
// are on your own time, even in a coding app.
//
// Sessions are saved per day to ~/.local/share/donut/work/YYYY-MM-DD.json,
// which the Donut app reads to draw them on its dial.
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

  // Today's sessions: [{start, end (epoch ms), manual, projects: {name: seconds}}].
  property var sessions: []
  property string dayKey: ""
  // A session started by hand stays on until stopped.
  property bool manual: false
  // Whether the last tick counted, and why ("Claude Code · timemng", "kitty").
  property bool working: false
  property string reason: ""
  // Projects Claude Code is busy in, from the last scan.
  property var claudeProjects: []
  // Bumped on every change so bindings on the derived totals update.
  property int revision: 0

  readonly property int todaySeconds: {
    revision;
    let ms = 0;
    for (const s of sessions) ms += s.end - s.start;
    return Math.round(ms / 1000);
  }

  readonly property var projectSeconds: {
    revision;
    const out = {};
    for (const s of sessions)
      for (const p in s.projects) out[p] = (out[p] || 0) + s.projects[p];
    return out;
  }

  function splitList(text) {
    return text.split(",").map(s => s.trim().toLowerCase()).filter(s => s.length > 0);
  }

  function pad(n) {
    return n < 10 ? "0" + n : "" + n;
  }

  function keyFor(ms) {
    const d = new Date(ms);
    return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate());
  }

  function fileFor(key) {
    return dataDir + "/" + key + ".json";
  }

  function formatDuration(seconds) {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    return h > 0 ? h + "h " + pad(m) + "m" : m + "m";
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

  // ── sessions ────────────────────────────────────────────────────────────

  function tick() {
    const now = Date.now();
    rollDay(now);
    const top = ToplevelManager.activeToplevel;
    const appId = top ? top.appId : "";
    const active = !idle.isIdle;
    const busy = countClaude ? claudeProjects : [];
    const claude = busy.filter(p => !isPersonal(p));
    const personalOnly = busy.length > 0 && claude.length === 0;
    let projects = [];
    if (manual) {
      reason = "Manual session";
      projects = claude.length > 0 ? claude : ["manual"];
    } else if (claude.length > 0) {
      reason = "Claude Code · " + claude.join(", ");
      projects = claude;
    } else if (personalOnly) {
      reason = "Personal · " + busy.join(", ");
    } else if (active && isWorkApp(appId, top ? top.title : "")) {
      reason = appId;
      projects = [appId];
    } else {
      reason = active ? "Not a work app" : "Idle";
    }
    working = projects.length > 0;
    if (working)
      record(now, projects);
  }

  function record(now, projects) {
    const gap = idleMinutes * 60000 + tickMs;
    let last = sessions.length > 0 ? sessions[sessions.length - 1] : null;
    if (!last || now - last.end > gap) {
      last = {
        "start": now - tickMs,
        "end": now,
        "manual": manual,
        "projects": {}
      };
      sessions.push(last);
    } else {
      last.end = now;
      last.manual = last.manual || manual;
    }
    for (const p of projects)
      last.projects[p] = (last.projects[p] || 0) + tickMs / 1000;
    save();
  }

  function rollDay(now) {
    const key = keyFor(now);
    if (key === dayKey)
      return;
    dayKey = key;
    sessions = [];
    revision++;
    dayFile.path = fileFor(key);
  }

  function save() {
    revision++;
    dayFile.setText(JSON.stringify({
      "v": 1,
      "day": dayKey,
      "sessions": sessions
    }, null, 1));
  }

  function isPersonal(project) {
    return personalProjects.indexOf(project.toLowerCase()) >= 0;
  }

  // Marks [project] personal: it stops counting, and today's sessions spent
  // only on it go. (A session shared with other work keeps its time.)
  function setPersonal(project, personal) {
    if (!pluginApi)
      return;
    let list = personalProjects.filter(p => p !== project.toLowerCase());
    if (personal)
      list.push(project.toLowerCase());
    pluginApi.pluginSettings.personalProjects = list.join(", ");
    pluginApi.saveSettings();
    if (!personal)
      return;
    for (const s of sessions)
      delete s.projects[project];
    sessions = sessions.filter(s => Object.keys(s.projects).length > 0);
    save();
  }

  function toggleManual() {
    manual = !manual;
    tick();
  }

  // Drops a session that wasn't work (from the panel).
  function discard(index) {
    sessions.splice(index, 1);
    save();
  }

  FileView {
    id: dayFile
    // Picks up today's sessions after a shell restart.
    onLoaded: {
      try {
        const data = JSON.parse(text());
        if (data.day === root.dayKey && Array.isArray(data.sessions)) {
          root.sessions = data.sessions.concat(root.sessions.filter(s => s.start > Date.now() - root.tickMs * 2));
          root.revision++;
        }
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
      return root.formatDuration(root.todaySeconds) + (root.working ? " · " + root.reason : "");
    }
  }
}
