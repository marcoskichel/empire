// @ts-check
/**
 * Unit tests for pr-stack.mjs pure logic. Run: node --test plugins/empire-git/scripts
 * No network, no gh — only the exported pure functions.
 */
import { test } from "node:test";
import assert from "node:assert/strict";

import {
  MARKER,
  buildChain,
  mergeMembership,
  decideActive,
  escapeCell,
  renderRow,
  renderBody,
  parseMembers,
  findStackComment,
  parseArgs,
} from "./pr-stack.mjs";

/** Linear 3-stack: a(base main) <- b <- c */
const linear = [
  { number: 1, title: "A", url: "u1", headRefName: "a", baseRefName: "main" },
  { number: 2, title: "B", url: "u2", headRefName: "b", baseRefName: "a" },
  { number: 3, title: "C", url: "u3", headRefName: "c", baseRefName: "b" },
];

test("buildChain: anchored at middle returns full base->tip", () => {
  assert.deepEqual(buildChain(linear, 2), [1, 2, 3]);
});

test("buildChain: anchored at base returns full chain", () => {
  assert.deepEqual(buildChain(linear, 1), [1, 2, 3]);
});

test("buildChain: anchored at tip returns full chain", () => {
  assert.deepEqual(buildChain(linear, 3), [1, 2, 3]);
});

test("buildChain: lone PR against default branch is just itself", () => {
  const solo = [{ number: 9, title: "S", url: "u", headRefName: "solo", baseRefName: "main" }];
  assert.deepEqual(buildChain(solo, 9), [9]);
});

test("buildChain: anchor absent from list returns [anchor]", () => {
  assert.deepEqual(buildChain(linear, 99), [99]);
});

test("buildChain: branching follows the first child per level", () => {
  const branched = [
    { number: 1, title: "A", url: "u", headRefName: "a", baseRefName: "main" },
    { number: 2, title: "B", url: "u", headRefName: "b", baseRefName: "a" },
    { number: 3, title: "C", url: "u", headRefName: "c", baseRefName: "a" },
  ];
  const chain = buildChain(branched, 1);
  assert.equal(chain[0], 1);
  assert.equal(chain.length, 2); // one child followed, not both
});

test("buildChain: cycle does not hang and is bounded", () => {
  const cyclic = [
    { number: 1, title: "A", url: "u", headRefName: "a", baseRefName: "b" },
    { number: 2, title: "B", url: "u", headRefName: "b", baseRefName: "a" },
  ];
  const chain = buildChain(cyclic, 1, 10);
  assert.ok(chain.includes(1));
  assert.ok(chain.length <= 2 + 1);
});

test("mergeMembership: empty stored returns live chain", () => {
  assert.deepEqual(mergeMembership([], [1, 2, 3]), [1, 2, 3]);
});

test("mergeMembership: appends new tips after stored order", () => {
  assert.deepEqual(mergeMembership([1, 2], [1, 2, 3]), [1, 2, 3]);
});

test("mergeMembership: preserves stored merged member missing from live", () => {
  // 1 merged (branch deleted, not in live), live rediscovers 2,3
  assert.deepEqual(mergeMembership([1, 2, 3], [2, 3]), [1, 2, 3]);
});

test("mergeMembership: dedupes while preserving first-seen order", () => {
  assert.deepEqual(mergeMembership([2, 1], [1, 2, 3]), [2, 1, 3]);
});

test("decideActive: two open is active", () => {
  const s = new Map([
    [1, "OPEN"],
    [2, "OPEN"],
  ]);
  assert.equal(decideActive([1, 2], s), true);
});

test("decideActive: one open riding on one merged is active", () => {
  const s = new Map([
    [1, "MERGED"],
    [2, "OPEN"],
  ]);
  assert.equal(decideActive([1, 2], s), true);
});

test("decideActive: single open with no merged sibling is not active", () => {
  const s = new Map([[2, "OPEN"]]);
  assert.equal(decideActive([2], s), false);
});

test("decideActive: one open plus one closed-unmerged is not active", () => {
  const s = new Map([
    [1, "CLOSED"],
    [2, "OPEN"],
  ]);
  assert.equal(decideActive([1, 2], s), false);
});

test("escapeCell: escapes pipe, leaves rest alone", () => {
  assert.equal(escapeCell("feat: a | b"), "feat: a \\| b");
  assert.equal(escapeCell("no pipes here"), "no pipes here");
});

test("renderRow: current PR is bold with arrow (wins even if merged)", () => {
  const meta = { title: "T", url: "U", state: "MERGED" };
  assert.equal(renderRow(5, meta, 5), "**[T](U) ← this PR**");
});

test("renderRow: merged is struck-through with check", () => {
  assert.equal(renderRow(1, { title: "T", url: "U", state: "MERGED" }, 9), "~~[T](U)~~ ✅");
});

test("renderRow: closed-unmerged is struck-through without check", () => {
  assert.equal(renderRow(1, { title: "T", url: "U", state: "CLOSED" }, 9), "~~[T](U)~~");
});

test("renderRow: open non-current is a plain link", () => {
  assert.equal(renderRow(1, { title: "T", url: "U", state: "OPEN" }, 9), "[T](U)");
});

test("renderRow: pipe in title is escaped", () => {
  const r = renderRow(1, { title: "a | b", url: "U", state: "OPEN" }, 9);
  assert.equal(r, "[a \\| b](U)");
});

test("renderBody: marker first line carries members, table well-formed", () => {
  const meta = new Map([
    [1, { title: "A", url: "u1", state: "MERGED" }],
    [2, { title: "B", url: "u2", state: "OPEN" }],
    [3, { title: "C", url: "u3", state: "OPEN" }],
  ]);
  const body = renderBody([1, 2, 3], meta, 2);
  const lines = body.split("\n");
  assert.equal(lines[0], `${MARKER} v=1 members=1,2,3 -->`);
  assert.equal(lines[1], "### PR stack");
  assert.equal(lines[3], "| PR |");
  assert.equal(lines[4], "| --- |");
  assert.equal(lines[5], "| ~~[A](u1)~~ ✅ |");
  assert.equal(lines[6], "| **[B](u2) ← this PR** |");
  assert.equal(lines[7], "| [C](u3) |");
  assert.equal(lines.length, 8);
});

test("renderBody: round-trips through parseMembers", () => {
  const meta = new Map([
    [4, { title: "A", url: "u", state: "OPEN" }],
    [7, { title: "B", url: "u", state: "OPEN" }],
  ]);
  assert.deepEqual(parseMembers(renderBody([4, 7], meta, 4)), [4, 7]);
});

test("parseMembers: extracts list, ignores surrounding text", () => {
  assert.deepEqual(
    parseMembers("<!-- empire:pr-stack v=1 members=10,20,30 -->\n### PR stack"),
    [10, 20, 30],
  );
});

test("parseMembers: missing or empty marker yields empty", () => {
  assert.deepEqual(parseMembers("no marker"), []);
  assert.deepEqual(parseMembers("members="), []);
  assert.deepEqual(parseMembers(""), []);
});

test("findStackComment: finds first marker comment", () => {
  const comments = [
    { id: 1, body: "unrelated" },
    { id: 2, body: `${MARKER} v=1 members=1 -->\n### PR stack` },
    { id: 3, body: `${MARKER} v=1 members=9 -->` },
  ];
  assert.equal(findStackComment(comments)?.id, 2);
});

test("findStackComment: none returns null", () => {
  assert.equal(findStackComment([{ id: 1, body: "nope" }]), null);
});

test("parseArgs: parses flags", () => {
  assert.deepEqual(parseArgs(["--pr", "15", "--repo", "o/r", "--dry-run"]), {
    pr: 15,
    repo: "o/r",
    dryRun: true,
  });
  assert.deepEqual(parseArgs([]), { pr: undefined, repo: undefined, dryRun: false });
});

test("parseArgs: rejects unknown flags", () => {
  assert.throws(() => parseArgs(["--bogus"]), /Unknown argument/);
});
