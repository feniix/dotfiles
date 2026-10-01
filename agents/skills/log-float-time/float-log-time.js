// Float time-entry helper for an authenticated Chrome page.
// Injected as-is with `agent-browser eval --stdin < float-log-time.js`. No build step.
// agent-browser's eval awaits a returned promise but rejects top-level `await`,
// so call the exported functions inside an async IIFE: (async () => { ... })()
//
// It captures auth passively in memory, never returns it, and verifies the task
// against Float's live task-meta response immediately before every write.
//
// There is deliberately NO cached task table here. A stale table is what caused
// Float to silently create a blank task on the shared project (see SKILL.md).
//
// ── USE ──
// 1. Be on https://spantree.float.com/log-time (logged in). Inject this file once.
// 2. await floatPrimeAuth()  → steps the week until Float makes an authenticated
//    request, then restores the week it started on.
// 3. await floatListTasks("211la")  → confirm the intended task name is live
//    (project alias or id; omitted → the default Evie Platform project)
// 4. await floatLogTime({ date: "2026-08-04", hours: 8, project: "211la",
//      task: "<live name>", notes: "..." })

(() => {
  // Known projects, keyed by a short alias. Project ids are stable; task names and
  // ids are NOT — they are always resolved live from task-meta for the TARGET
  // project at write time (defaultTask is only the name to look up).
  const PROJECTS = {
    "evie-platform": { id: 11348463, label: "Spantree / Evie Platform", defaultTask: "Tooling & Internal Platform" },
    "211la": { id: 11848944, label: "211 LA (2LA presales)", defaultTask: "Presales Engineering" },
  };

  window.FLOAT_CFG = {
    people_id: 17853024,
    project_id: PROJECTS["evie-platform"].id, // default project
    phase_id: 0,
    projects: PROJECTS,
  };

  // Resolve a project alias, numeric id, or undefined (→ default) to a known project.
  // Unknown ids are refused: writing to a project nobody vetted is how stray tasks happen.
  const resolveProject = (project) => {
    if (project === undefined || project === null) {
      return Object.values(PROJECTS).find((p) => p.id === window.FLOAT_CFG.project_id);
    }
    const byKey = PROJECTS[String(project)];
    if (byKey) return byKey;
    const byId = Object.values(PROJECTS).find((p) => p.id === Number(project));
    if (byId) return byId;
    throw new Error(
      `unknown project "${project}"; known: ${Object.entries(PROJECTS).map(([k, p]) => `${k} (${p.id})`).join(", ")}`,
    );
  };

  if (!window.__floatOrigFetch) {
    const orig = window.fetch;
    window.__floatOrigFetch = orig;
    window.__floatAuth = null;
    window.__floatApi3Seen = 0;

    const capture = (headers) => {
      try {
        if (!headers) return;
        const values = {};
        if (headers instanceof Headers) {
          for (const [key, value] of headers.entries()) values[key] = value;
        } else if (Array.isArray(headers)) {
          for (const [key, value] of headers) values[key] = value;
        } else {
          Object.assign(values, headers);
        }
        const auth = values.Authorization ?? values.authorization;
        if (auth) {
          window.__floatAuth = {
            auth,
            tokenType: values["X-Token-Type"] ?? values["x-token-type"],
          };
        }
      } catch (_) {}
    };

    window.fetch = function (input, init) {
      const url = typeof input === "string" ? input : (input && input.url) || "";
      if (url.includes("/svc/api3/")) {
        window.__floatApi3Seen++;
        capture(init && init.headers);
      }
      return orig.apply(this, arguments);
    };

    const originalSetRequestHeader = XMLHttpRequest.prototype.setRequestHeader;
    XMLHttpRequest.prototype.setRequestHeader = function (name, value) {
      try {
        if (/^authorization$/i.test(name)) this.__floatAuthValue = value;
        if (/^x-token-type$/i.test(name)) this.__floatTokenType = value;
        if (this.__floatAuthValue) {
          window.__floatAuth = {
            auth: this.__floatAuthValue,
            tokenType: this.__floatTokenType,
          };
        }
      } catch (_) {}
      return originalSetRequestHeader.apply(this, [name, value]);
    };
  }

  const authenticatedFetch = async (path, init = {}) => {
    const session = window.__floatAuth;
    if (!session) {
      throw new Error("auth not captured — run await floatPrimeAuth() first");
    }
    const requestHeaders = {
      Accept: "application/json",
      Authorization: session.auth,
      "X-Token-Type": session.tokenType ?? "",
      ...(init.headers || {}),
    };
    const doFetch = window.__floatOrigFetch ?? window.fetch;
    return doFetch(path, {
      ...init,
      headers: requestHeaders,
      credentials: "include",
    });
  };

  const collectTaskPairs = (value, found = [], seen = new Set()) => {
    if (!value || typeof value !== "object" || seen.has(value)) return found;
    seen.add(value);
    if (Array.isArray(value)) {
      for (const item of value) collectTaskPairs(item, found, seen);
      return found;
    }

    const id = value.task_meta_id ?? value.taskMetaId ?? value.id;
    const name = value.task_name ?? value.taskName ?? value.name ?? value.title;
    if ((typeof id === "number" || /^\d+$/.test(String(id))) && typeof name === "string") {
      const pair = { id: Number(id), name };
      if (!found.some((item) => item.id === pair.id && item.name === pair.name)) {
        found.push(pair);
      }
    }
    for (const child of Object.values(value)) collectTaskPairs(child, found, seen);
    return found;
  };

  const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
  const isPrimed = () => !!(window.__floatAuth && window.__floatAuth.auth);

  /**
   * Capture auth by making Float issue a request of its own.
   *
   * One arrow click is not enough: Float renders an adjacent week from data it
   * already holds and sends nothing. This steps forward until a /svc/api3/
   * request actually fires, then walks back so the view ends where it started.
   *
   * Returns { ok, steps, api3Seen }. ok:false with api3Seen:0 means no request
   * fired at all — the page is stale or not the Log my time view.
   */
  window.floatPrimeAuth = async function floatPrimeAuth(options = {}) {
    const { maxSteps = 12, settleMs = 500 } = options;
    if (isPrimed()) {
      return { ok: true, alreadyPrimed: true, steps: 0, api3Seen: window.__floatApi3Seen };
    }

    const next = document.querySelector('button[aria-label="Next week"]');
    const previous = document.querySelector('button[aria-label="Previous week"]');
    if (!next || !previous) {
      throw new Error("week navigation not found — open https://spantree.float.com/log-time");
    }

    let steps = 0;
    try {
      for (let attempt = 0; attempt < maxSteps && !isPrimed(); attempt++) {
        next.click();
        steps++;
        await sleep(settleMs);
      }
    } finally {
      // Restore the starting week even if priming threw.
      for (let back = 0; back < steps; back++) {
        previous.click();
        await sleep(80);
      }
    }

    return { ok: isPrimed(), steps, api3Seen: window.__floatApi3Seen };
  };

  /** Live tasks for a project (alias, id, or default). */
  window.floatListTasks = async function floatListTasks(project) {
    const target = resolveProject(project);
    const response = await authenticatedFetch(`/svc/api3/v3/task-meta?project_id=${target.id}`);
    const data = await response.json().catch(() => null);
    return {
      status: response.status,
      ok: response.ok,
      project: { id: target.id, label: target.label },
      tasks: collectTaskPairs(data),
      data,
    };
  };

  /**
   * Read this person's entries for a date range. Use before writing to check for
   * a duplicate, and after writing to verify. Float returns the whole team's rows,
   * so this filters to FLOAT_CFG.people_id.
   */
  window.floatListEntries = async function floatListEntries(startDate, endDate = startDate) {
    const response = await authenticatedFetch(
      `/svc/api3/v3/logged-time?start_date=${startDate}&end_date=${endDate}`,
    );
    const data = await response.json().catch(() => null);
    const rows = Array.isArray(data) ? data : (data && data.data) || [];
    return {
      status: response.status,
      ok: response.ok,
      entries: rows
        .filter((entry) => entry.people_id === window.FLOAT_CFG.people_id)
        .map((entry) => ({
          logged_time_id: entry.logged_time_id,
          date: entry.date,
          hours: entry.hours,
          project_id: entry.project_id,
          task_meta_id: entry.task_meta_id,
          task_name: entry.task_name,
          noteLength: (entry.notes || "").length,
          notes: entry.notes || "",
        })),
    };
  };

  window.floatLogTime = async function floatLogTime(args) {
    const {
      date,
      hours,
      notes = "",
      project, // alias ("evie-platform", "211la") or id; omitted → default project
      projectId, // legacy alias for `project`
      peopleId = window.FLOAT_CFG.people_id,
      phaseId = window.FLOAT_CFG.phase_id,
    } = args || {};
    // Task lookup and the write MUST target the same project; resolving once
    // guarantees it (an id checked against another project's list would let
    // Float mint a stray blank task).
    const target = resolveProject(project ?? projectId);
    const task = (args && args.task) || target.defaultTask;

    if (!/^\d{4}-\d{2}-\d{2}$/.test(date || "")) {
      throw new Error("date must be YYYY-MM-DD");
    }
    if (typeof hours !== "number" || !Number.isFinite(hours) || hours < 0 || hours > 24) {
      throw new Error("hours must be a number from 0 through 24");
    }
    if (typeof task !== "string" || !task) throw new Error("task is required");

    const live = await window.floatListTasks(target.id);
    if (!live.ok) throw new Error(`task lookup failed with status ${live.status}`);
    const matches = live.tasks.filter((candidate) => candidate.name === task);
    if (matches.length !== 1) {
      const names = [...new Set(live.tasks.map((candidate) => candidate.name))].sort();
      throw new Error(
        `expected one live task named "${task}", found ${matches.length}; live names: ${names.join(", ")}`,
      );
    }

    const notifyUuid = (
      crypto.randomUUID().replace(/-/g, "") + crypto.randomUUID().replace(/-/g, "")
    ).slice(0, 50);
    const body = JSON.stringify([
      {
        people_id: peopleId,
        project_id: target.id,
        phase_id: phaseId,
        task_meta_id: matches[0].id,
        date,
        hours,
        notes: String(notes).slice(0, 1500),
      },
    ]);

    const response = await authenticatedFetch("/svc/api3/v3/logged-time", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "notify-uuid": notifyUuid,
      },
      body,
    });
    const data = await response.json().catch(() => null);
    return {
      status: response.status,
      ok: response.ok,
      data,
      project: { id: target.id, label: target.label },
      task: matches[0],
      noteLength: String(notes).slice(0, 1500).length,
    };
  };

  /**
   * Partial-edit an existing entry, e.g. { task_meta_id: N } or { hours: 6 }.
   * Note the id goes in the PATH — PUT to the bare collection returns 404.
   * A task change is verified against the live list first, same as a create.
   * Pass `project` (alias or id) when the entry is not on the default project.
   */
  window.floatUpdateTime = async function floatUpdateTime(loggedTimeId, patch) {
    if (!loggedTimeId) throw new Error("loggedTimeId is required");
    if (!patch || typeof patch !== "object") throw new Error("patch object is required");

    const { project, ...body } = patch;
    if (body.task) {
      const live = await window.floatListTasks(project ?? body.project_id);
      if (!live.ok) throw new Error(`task lookup failed with status ${live.status}`);
      const matches = live.tasks.filter((candidate) => candidate.name === body.task);
      if (matches.length !== 1) {
        const names = [...new Set(live.tasks.map((candidate) => candidate.name))].sort();
        throw new Error(
          `expected one live task named "${body.task}", found ${matches.length}; live names: ${names.join(", ")}`,
        );
      }
      body.task_meta_id = matches[0].id;
      delete body.task;
    }

    const notifyUuid = (
      crypto.randomUUID().replace(/-/g, "") + crypto.randomUUID().replace(/-/g, "")
    ).slice(0, 50);
    const response = await authenticatedFetch(
      `/svc/api3/v3/logged-time/${encodeURIComponent(loggedTimeId)}`,
      {
        method: "PUT",
        headers: { "Content-Type": "application/json", "notify-uuid": notifyUuid },
        body: JSON.stringify(body),
      },
    );
    const data = await response.json().catch(() => null);
    // The PUT response shape is inconsistent; always re-read to verify.
    return { status: response.status, ok: response.ok, data };
  };
})();
