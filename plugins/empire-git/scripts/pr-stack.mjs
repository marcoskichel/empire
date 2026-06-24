#!/usr/bin/env node
// @ts-check
/**
 * pr-stack.mjs — maintain the "PR stack" comment across a chain of stacked PRs.
 *
 * Dependency-free Node ESM. Shells out to `gh`; no jq, no build, no node_modules.
 * Pure logic (chain build, membership, render, decision) is exported for unit
 * tests in pr-stack.test.mjs. main() runs only when the file is invoked directly.
 *
 * Usage: node pr-stack.mjs [--pr <number>] [--repo <owner/repo>] [--dry-run]
 */

import { execFileSync } from "node:child_process";
import { pathToFileURL } from "node:url";

export const MARKER = "<!-- empire:pr-stack";
export const MAX_DEPTH = 50;

/**
 * @typedef {{ number: number, title: string, url: string,
 *   headRefName: string, baseRefName: string, state?: string }} PR
 * @typedef {{ title: string, url: string, state: string }} Meta
 */

/* ----------------------------- pure logic ------------------------------- */

/**
 * Build the live chain around an anchor PR from the open-PR list. Walks parents
 * up (a PR whose head branch is this PR's base) and children down (a PR whose
 * base is this PR's head). Linear stacks only: one child per level.
 * @param {PR[]} openPRs
 * @param {number} anchor
 * @param {number} [maxDepth]
 * @returns {number[]} ordered base -> tip
 */
export function buildChain(openPRs, anchor, maxDepth = MAX_DEPTH) {
  const byNum = new Map(openPRs.map((p) => [p.number, p]));
  const byHead = new Map(openPRs.map((p) => [p.headRefName, p.number]));
  const firstChildOf = (head) => {
    for (const p of openPRs) if (p.baseRefName === head) return p.number;
    return undefined;
  };

  const above = [];
  const seenUp = new Set([anchor]);
  let cur = anchor;
  for (let depth = 0; depth < maxDepth; depth++) {
    const p = byNum.get(cur);
    if (!p) break;
    const parent = byHead.get(p.baseRefName);
    if (parent === undefined || seenUp.has(parent)) break;
    above.unshift(parent);
    seenUp.add(parent);
    cur = parent;
  }

  const below = [];
  const seenDown = new Set([anchor]);
  cur = anchor;
  for (let depth = 0; depth < maxDepth; depth++) {
    const p = byNum.get(cur);
    if (!p) break;
    const child = firstChildOf(p.headRefName);
    if (child === undefined || seenDown.has(child)) break;
    below.push(child);
    seenDown.add(child);
    cur = child;
  }

  return [...above, anchor, ...below];
}

/**
 * Membership = stored order, then live-chain members not already present.
 * Preserves history (merged members stored earlier stay) and appends new tips.
 * @param {number[]} stored
 * @param {number[]} liveChain
 * @returns {number[]}
 */
export function mergeMembership(stored, liveChain) {
  const out = [];
  const seen = new Set();
  for (const n of [...stored, ...liveChain]) {
    if (!seen.has(n)) {
      seen.add(n);
      out.push(n);
    }
  }
  return out;
}

/**
 * A chain is worth showing while >=2 PRs are open, or >=1 open rides on >=1
 * merged sibling from the same stack.
 * @param {number[]} members
 * @param {Map<number,string>} stateByNum
 * @returns {boolean}
 */
export function decideActive(members, stateByNum) {
  let open = 0;
  let merged = 0;
  for (const n of members) {
    const s = stateByNum.get(n);
    if (s === "OPEN") open++;
    else if (s === "MERGED") merged++;
  }
  return open >= 2 || (open >= 1 && merged >= 1);
}

/**
 * Escape the table-breaking pipe in a cell.
 * @param {string} s
 */
export function escapeCell(s) {
  return String(s).replace(/\|/g, "\\|");
}

/**
 * Render one table row for a member.
 * @param {number} member
 * @param {Meta} meta
 * @param {number} current
 */
export function renderRow(member, meta, current) {
  const t = escapeCell(meta.title);
  const u = meta.url;
  if (member === current) return `**[${t}](${u}) ← this PR**`;
  if (meta.state === "MERGED") return `~~[${t}](${u})~~ ✅`;
  if (meta.state === "CLOSED") return `~~[${t}](${u})~~`;
  return `[${t}](${u})`;
}

/**
 * Render the full comment body for a given current PR.
 * @param {number[]} members
 * @param {Map<number,Meta>} metaByNum
 * @param {number} current
 * @returns {string}
 */
export function renderBody(members, metaByNum, current) {
  const lines = [
    `${MARKER} v=1 members=${members.join(",")} -->`,
    "### PR stack",
    "",
    "| PR |",
    "| --- |",
  ];
  for (const n of members) {
    const meta = metaByNum.get(n);
    if (!meta) continue;
    lines.push(`| ${renderRow(n, meta, current)} |`);
  }
  return lines.join("\n");
}

/**
 * Extract the stored membership list from a comment body marker.
 * @param {string} body
 * @returns {number[]}
 */
export function parseMembers(body) {
  const m = /members=([0-9,]*)/.exec(body || "");
  if (!m || !m[1]) return [];
  return m[1].split(",").filter(Boolean).map(Number);
}

/**
 * Find the skill's own comment (first one whose body starts with the marker).
 * @param {{id:number, body:string}[]} comments
 * @returns {{id:number, body:string} | null}
 */
export function findStackComment(comments) {
  return comments.find((c) => typeof c.body === "string" && c.body.startsWith(MARKER)) || null;
}

/* ------------------------------- I/O layer ------------------------------ */

const useColor = Boolean(process.stdout.isTTY);
const paint = (code, s) => (useColor ? `\x1b[${code}m${s}\x1b[0m` : s);
const info = (s) => console.log(`${paint("1;34", "==>")} ${s}`);
const success = (s) => console.log(`${paint("1;32", "==>")} ${s}`);
const die = (s) => {
  console.error(`${paint("1;31", "==>")} ${s}`);
  process.exit(1);
};

/**
 * Run `gh` and return stdout (parsed JSON when json=true).
 * @param {string[]} args
 * @param {{ json?: boolean, input?: string }} [opts]
 */
function gh(args, opts = {}) {
  const out = execFileSync("gh", args, {
    encoding: "utf8",
    input: opts.input,
    maxBuffer: 32 * 1024 * 1024,
  });
  return opts.json ? JSON.parse(out) : out;
}

/**
 * Existing stack comment id + stored membership for one PR.
 * @param {string} repo
 * @param {number} n
 * @returns {{ id: number|null, members: number[] }}
 */
function getStackComment(repo, n) {
  let comments;
  try {
    comments = gh(["api", `repos/${repo}/issues/${n}/comments`, "--paginate"], { json: true });
  } catch {
    return { id: null, members: [] };
  }
  const c = findStackComment(comments);
  if (!c) return { id: null, members: [] };
  return { id: c.id, members: parseMembers(c.body) };
}

/**
 * @param {string} repo
 * @param {number} n
 * @param {string} body
 * @param {number|null|undefined} id
 * @param {boolean} dryRun
 */
function upsert(repo, n, body, id, dryRun) {
  if (dryRun) {
    info(`[dry-run] would ${id ? "update" : "create"} stack comment on #${n}`);
    process.stdout.write(`${body}\n---\n`);
    return;
  }
  const input = JSON.stringify({ body });
  if (id) {
    gh(["api", "-X", "PATCH", `repos/${repo}/issues/comments/${id}`, "--input", "-"], { input });
    success(`updated stack comment on #${n}`);
  } else {
    gh(["api", `repos/${repo}/issues/${n}/comments`, "--input", "-"], { input });
    success(`created stack comment on #${n}`);
  }
}

/**
 * @param {string} repo
 * @param {number} n
 * @param {number|null|undefined} id
 * @param {boolean} dryRun
 */
function removeComment(repo, n, id, dryRun) {
  if (!id) return;
  if (dryRun) {
    info(`[dry-run] would remove stale stack comment on #${n}`);
    return;
  }
  gh(["api", "-X", "DELETE", `repos/${repo}/issues/comments/${id}`]);
  success(`removed stale stack comment on #${n}`);
}

/**
 * @param {string[]} argv
 */
export function parseArgs(argv) {
  let pr;
  let repo;
  let dryRun = false;
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--pr") pr = argv[++i];
    else if (a === "--repo") repo = argv[++i];
    else if (a === "--dry-run") dryRun = true;
    else throw new Error(`Unknown argument: ${a}`);
  }
  return { pr: pr ? Number(pr) : undefined, repo, dryRun };
}

function main() {
  try {
    execFileSync("gh", ["--version"], { stdio: "ignore" });
  } catch {
    die("gh CLI not found.");
  }

  const { pr, repo, dryRun } = parseArgs(process.argv.slice(2));

  let REPO = repo;
  if (!REPO) {
    try {
      REPO = gh(["repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"]).trim();
    } catch {
      die("Not in a GitHub repo (pass --repo).");
    }
  }
  const DEFAULT_BRANCH = gh([
    "repo",
    "view",
    REPO,
    "--json",
    "defaultBranchRef",
    "-q",
    ".defaultBranchRef.name",
  ]).trim();

  let target = pr;
  if (!target) {
    // gh requires an explicit PR arg when --repo is set, so resolve the
    // current branch's PR from the current repo (no --repo).
    if (repo) die("Pass --pr <number> when using --repo.");
    try {
      target = Number(gh(["pr", "view", "--json", "number", "-q", ".number"]).trim());
    } catch {
      die("No PR for the current branch. Pass --pr <number>.");
    }
  }

  /** @type {PR[]} */
  const openPRs = gh(
    [
      "pr",
      "list",
      "--repo",
      REPO,
      "--state",
      "open",
      "--limit",
      "300",
      "--json",
      "number,title,url,headRefName,baseRefName,state",
    ],
    { json: true },
  );

  const live = buildChain(openPRs, Number(target));

  /** @type {Map<number, number>} */
  const commentId = new Map();
  let stored = [];
  for (const n of live) {
    const got = getStackComment(REPO, n);
    if (got.id) commentId.set(n, got.id);
    if (got.members.length > stored.length) stored = got.members;
  }

  const members = mergeMembership(stored, live);

  const openByNum = new Map(openPRs.map((p) => [p.number, p]));
  /** @type {Map<number, Meta>} */
  const metaByNum = new Map();
  /** @type {Map<number, string>} */
  const stateByNum = new Map();
  for (const n of members) {
    const open = openByNum.get(n);
    if (open) {
      metaByNum.set(n, { title: open.title, url: open.url, state: "OPEN" });
      stateByNum.set(n, "OPEN");
      continue;
    }
    try {
      const meta = gh(["pr", "view", String(n), "--repo", REPO, "--json", "state,title,url"], {
        json: true,
      });
      metaByNum.set(n, { title: meta.title, url: meta.url, state: meta.state });
      stateByNum.set(n, meta.state);
    } catch {
      /* unresolved member: drop it */
    }
  }

  const resolved = members.filter((n) => stateByNum.has(n));
  const openMembers = resolved.filter((n) => stateByNum.get(n) === "OPEN");
  const mergedCount = resolved.filter((n) => stateByNum.get(n) === "MERGED").length;

  const ensureId = (n) => {
    if (!commentId.has(n)) {
      const got = getStackComment(REPO, n);
      if (got.id) commentId.set(n, got.id);
    }
  };

  if (decideActive(resolved, stateByNum)) {
    info(`Chain: ${resolved.length} PR(s), ${openMembers.length} open, ${mergedCount} merged.`);
    for (const n of openMembers) {
      ensureId(n);
      upsert(REPO, n, renderBody(resolved, metaByNum, n), commentId.get(n), dryRun);
    }
  } else {
    info(`Not a stack (single PR against ${DEFAULT_BRANCH}, no merged siblings). Cleaning up.`);
    for (const n of openMembers) {
      ensureId(n);
      removeComment(REPO, n, commentId.get(n), dryRun);
    }
  }
}

const invokedDirectly = process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;
if (invokedDirectly) {
  try {
    main();
  } catch (err) {
    die(err instanceof Error ? err.message : String(err));
  }
}
