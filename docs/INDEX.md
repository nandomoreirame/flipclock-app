# FlipClock Documentation Index

> **Last Updated:** 2026-02-20
> **Maintained by:** SDLC Workflow

---

## Overview

Este índice rastreia todos os documentos SDLC do projeto FlipClock, incluindo PRDs (Product Requirements), ADRs (Architecture Decision Records), User Stories e Tasks.

---

## Product Requirements (PRDs)

| ID | Title | Status | Created | Related Docs |
|----|-------|--------|---------|--------------|
| [PRD-001](prds/PRD-001.md) | Multi-Monitor Support for Screensaver Mode | approved | 2026-02-20 | ADR-001, US-001 |

---

## Architecture Decision Records (ADRs)

| ID | Title | Status | Created | Related Docs |
|----|-------|--------|---------|--------------|
| [ADR-001](adrs/ADR-001.md) | Using GLFW Directly for Multi-Monitor Detection | accepted | 2026-02-20 | PRD-001, US-001 |

---

## User Stories

| ID | Title | Status | Priority | Story Points | Related Docs |
|----|-------|--------|----------|--------------|--------------|
| [US-001](user-stories/US-001.md) | Multi-Monitor Screensaver Coverage | ready | high | 5 | PRD-001, ADR-001, TASK-001 to TASK-004 |

---

## Tasks

| ID | Title | Status | Assignee | Blocks | Related Docs |
|----|-------|--------|----------|--------|--------------|
| [TASK-001](tasks/TASK-001.md) | Implement Multi-Monitor Detection with GLFW | todo | Claude Code | TASK-002 | US-001, ADR-001 |
| [TASK-002](tasks/TASK-002.md) | Implement Multi-Window Creation for Screensaver Mode | todo | Claude Code | TASK-003 | US-001, TASK-001 |
| [TASK-003](tasks/TASK-003.md) | Implement Unified Exit and Clock Synchronization | todo | Claude Code | TASK-004 | US-001, TASK-002 |
| [TASK-004](tasks/TASK-004.md) | Integration Testing and Documentation Update | todo | Claude Code | - | US-001, TASK-001-003 |

---

## Traceability Matrix

Rastreamento completo de requisitos → implementação:

```
PRD-001 (Multi-Monitor Support)
  ├─ ADR-001 (GLFW for monitor detection)
  ├─ US-001 (Multi-monitor screensaver coverage)
  │   ├─ TASK-001 (Monitor detection)
  │   ├─ TASK-002 (Multi-window creation)
  │   ├─ TASK-003 (Unified exit + sync)
  │   └─ TASK-004 (Testing + docs)
  └─ README.md (User-facing documentation)
```

---

## Branch Strategy

| Feature | Branch | Status | PRD | Tasks |
|---------|--------|--------|-----|-------|
| Multi-Monitor Screensaver | `feature/TASK-001-multi-monitor-detection` | in-progress | PRD-001 | TASK-001 to TASK-004 |

---

## Next Steps

1. **Phase 1 (Setup):** Create feature branch `feature/TASK-001-multi-monitor-detection`
2. **Phase 2 (Implementation):** Execute TASK-001 → TASK-002 → TASK-003 (TDD workflow)
3. **Phase 3 (Testing):** Execute TASK-004 (integration tests + documentation)
4. **Phase 4 (Review):** Self-review with verification-before-completion skill
5. **Phase 5 (Finalization):** Merge to develop or create PR to main

---

## Changelog

| Date | Action | Author | Details |
|------|--------|--------|---------|
| 2026-02-20 | Created | Claude Code | Initial index for multi-monitor feature |
