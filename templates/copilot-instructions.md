---
description: 'Central Copilot instructions for all projects using Smart Agent'
applyTo: '**/*'
---

# Copilot Instructions

## Default Agent Mode - **ALWAYS @smart**

When starting a new chat session or when no specific agent is selected, **automatically load the Smart Agent** (`@smart`).

The Smart Agent ensures all code changes are planned, tracked, and explicitly approved before implementation, with documentation maintained in the `.copilot/docs/` folder.

## Agent Loading Priority

1. If user explicitly selects an agent → Use that agent
2. If no agent selected → Load `@smart` agent automatically
3. Always check `.github/agents/` for available custom agents

## Available Agents

### @smart (Default)
- **Purpose**: Plan, track, implement code changes with docs-first approach
- **Location**: `.github/agents/smart.agent.md`
- **When to use**: Any task that involves code modifications

## Required Behavior

### Always On First Interaction:
1. Load `.copilot/docs/index.yaml` search index (PRIMARY CONTEXT)
2. Navigate to relevant docs based on index keywords
3. Check `.copilot/plans/state.yaml` for pending plans

### Never:
- Implement code changes without explicit user approval
- Skip the planning phase for significant changes
- Ignore the documentation in `.copilot/docs/`

## Project Configuration

- **Documentation**: `.copilot/docs/` (single source of truth)
- **Search Index**: `.copilot/docs/index.yaml`
- **Plans Location**: `.copilot/plans/`
- **Standards**: `.copilot/standards/` (if installed)

## Workflow Summary

```
User Request → Load Index → Read Docs → Create Plan → Approval → Implement → Update Docs
```

After every completed request, documentation must be updated to reflect changes.

---

## Standards (If Installed)

When `.copilot/standards/` folder exists, **always read and apply** the relevant standards files before generating or reviewing code:

| File | When to Apply |
|------|---------------|
| `general.md` | **Always** - Core principles for all languages |
| `rust.md` | When working with Rust code |
| `nodejs.md` | When working with Node.js/TypeScript code |

The standards contain critical guidelines that must be followed. Read them on first interaction with a project.
