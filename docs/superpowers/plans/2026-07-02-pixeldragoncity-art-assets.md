# Pixel Dragon City Art Assets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the current pixel-art direction and prototype assets into a staged, documented, Godot-ready art asset pipeline.

**Architecture:** Keep art planning separate from gameplay implementation. `docs/13_ArtAssetPlan.md` owns the staged resource roadmap, `docs/12_ArtDirection.md` owns visual direction, and `assets/ASSET_MANIFEST.md` owns concrete asset status.

**Tech Stack:** Godot 4, PNG assets, GDScript resource loading, Markdown project documentation.

---

## File Structure

- Create: `docs/13_ArtAssetPlan.md`
- Modify: `docs/12_ArtDirection.md`
- Modify: `assets/ASSET_MANIFEST.md`
- Modify: `TODO.md`
- Modify: `prompts/art.md`
- Modify: `docs/11_DevelopmentPlan.md`
- Modify: `docs/DevLog.md`

## Task 1: Add Art Asset Plan Document

**Files:**
- Create: `docs/13_ArtAssetPlan.md`

- [ ] **Step 1: Create the plan document**

Write a document with status levels, production principles, naming rules, common specs, staged phases, current priorities, and maintenance rules.

- [ ] **Step 2: Verify no placeholders remain**

Run: `rg -n "TBD|TODO|待定|稍后|占位待补" docs/13_ArtAssetPlan.md`

Expected: no matches.

## Task 2: Link Art Direction To Asset Production

**Files:**
- Modify: `docs/12_ArtDirection.md`

- [ ] **Step 1: Add an asset-production section**

Add a section after the first-batch resource section that links to `docs/13_ArtAssetPlan.md`.

- [ ] **Step 2: Clarify asset maturity**

State that reference images are not final cuts, prototype sheets may need recutting, and blockout resources validate motion rather than visual polish.

## Task 3: Classify Current Assets

**Files:**
- Modify: `assets/ASSET_MANIFEST.md`

- [ ] **Step 1: Add status vocabulary**

Add `reference`, `prototype`, `blockout`, `production_candidate`, and `production_ready`.

- [ ] **Step 2: Add current classification**

Classify existing player, monster, item, tileset, UI, background, and portrait assets using the statuses above.

## Task 4: Update Task Tracking

**Files:**
- Modify: `TODO.md`

- [ ] **Step 1: Add top-level art plan task**

Add a checked item for creating the art asset plan.

- [ ] **Step 2: Add an art pipeline section**

Create `## 像素美术资源管线` and list current art-resource work by milestone priority.

## Task 5: Update Art Prompt Contract

**Files:**
- Modify: `prompts/art.md`

- [ ] **Step 1: Add output contract**

Future image generation requests must state asset type, exact canvas/cell size, frame count, direction count, row order, transparent-background requirement, and intended Godot path.

- [ ] **Step 2: Add rejection criteria**

Reject outputs that imitate commercial game assets, lack strict grids for animation, merge UI text into bitmap buttons, or use inconsistent proportions.

## Task 6: Update Main Planning Docs

**Files:**
- Modify: `docs/11_DevelopmentPlan.md`
- Modify: `docs/DevLog.md`

- [ ] **Step 1: Link the main plan to art asset planning**

Add `docs/13_ArtAssetPlan.md` as the source of truth for staged art production.

- [ ] **Step 2: Record the documentation update**

Add a `2026-07-02 像素美术资源开发计划` entry to `docs/DevLog.md` with completed items and remaining work.

## Task 7: Verify Documentation Consistency

**Files:**
- Check: `docs/13_ArtAssetPlan.md`
- Check: `docs/12_ArtDirection.md`
- Check: `assets/ASSET_MANIFEST.md`
- Check: `TODO.md`
- Check: `prompts/art.md`
- Check: `docs/11_DevelopmentPlan.md`
- Check: `docs/DevLog.md`

- [ ] **Step 1: Check links and file references**

Run: `rg -n "13_ArtAssetPlan|像素美术资源管线|美术资源生产计划|reference|production_ready" docs assets/ASSET_MANIFEST.md prompts/art.md TODO.md`

Expected: matches in all updated documents.

- [ ] **Step 2: Check changed files**

Run: `find docs assets prompts -maxdepth 3 -type f | sort`

Expected: `docs/13_ArtAssetPlan.md` exists and no generated binary assets were added by this plan-only update.
