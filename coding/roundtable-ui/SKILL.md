---
name: roundtable-ui
description: Work within the roundtable-ui dashboard repo (React + Go API). Use when modifying the fleet dashboard, components, API endpoints, or WebSocket integration in dapperdivers/roundtable-ui.
---

# roundtable-ui Codebase Guide

## Quick Reference

| Aspect | Detail |
|--------|--------|
| Frontend | React 18, Vite, TypeScript, Tailwind CSS |
| Backend | Go 1.23, gorilla/mux + gorilla/websocket |
| Tests | Vitest + Testing Library (UI), Go test (API) |
| Storybook | v8.6 for component development |
| CI | npm build + go vet + Docker multi-stage build |
| Image | `ghcr.io/dapperdivers/roundtable-ui:<sha>` |

## Project Layout

```
api/
  main.go             Go API server (REST + WebSocket proxy)
  main_test.go        API tests
  go.mod / go.sum     Go dependencies
ui/
  src/
    App.tsx           Root component + routing
    main.tsx          Entry point
    index.css         Tailwind base styles
    components/
      FleetGraph.tsx          Fleet topology visualization (@xyflow/react)
      KnightCard.tsx          Knight status card
      KnightDetailDrawer.tsx  Knight detail panel
      MessageParticle.tsx     Animated NATS message particles
      MissionCard.tsx         Mission display
      MissionPhaseBadge.tsx   Mission phase indicator
      RoundTableGraph.tsx     Round table visualization
      Toast.tsx               Notification toasts
    hooks/
      useFleet.ts             Fleet data fetching
      useKnightSession.ts     Knight session management
      useWebSocket.ts         NATS WebSocket connection
      useMissions.ts          Mission data
      useTaskNotifications.ts Task notification handler
    pages/
      Dashboard.tsx           Main dashboard
      Fleet.tsx               Fleet overview
      Architecture.tsx        Architecture diagram
      Briefings.tsx           Morning briefings
      Chains.tsx              Chain visualization
      CostDashboard.tsx       Cost tracking
    lib/
      auth.ts                 Authentication
      knights.ts              Knight data utilities
  .storybook/                 Storybook config
  package.json
  tsconfig.json
Dockerfile                    Multi-stage: node→go→alpine
```

## Build & Test

```bash
# Frontend
cd ui
npm install
npm run build          # tsc -b && vite build
npm run dev            # Vite dev server
npm run test           # Vitest
npm run test:coverage  # Coverage report
npm run storybook      # Component development

# Backend
cd api
go vet ./...
go test ./...

# Docker (full stack)
docker build -t roundtable-ui .
```

## Architecture

- **Go API** serves static UI assets from `./static/` and proxies WebSocket connections to NATS
- **Vite** builds to `../api/static/` (configured in vite config)
- **WebSocket** connects UI to NATS for real-time fleet updates
- **@xyflow/react** powers the fleet topology graph

## Key Libraries

### Frontend
- `@xyflow/react` — Interactive node graph (fleet topology)
- `react-router-dom` v7 — Client-side routing
- `lucide-react` — Icons
- `tailwind-merge` + `clsx` — Conditional class merging
- `date-fns` — Date formatting
- `react-markdown` — Markdown rendering (briefings)

### Backend
- `gorilla/mux` — HTTP routing
- `gorilla/websocket` — WebSocket proxy to NATS
- `nats-io/nats.go` — NATS JetStream client

## Component Development

Use Storybook for isolated component work:
```bash
cd ui && npm run storybook
```

All visual components should have `.stories.tsx` files. Tests use `@testing-library/react` + `vitest`.

## Conventions

- **Always run `npx tsc --noEmit`** before committing — catches type errors Vite ignores
- Components in `components/`, page-level views in `pages/`, data fetching in `hooks/`
- Tailwind for all styling (no CSS modules)
- `CGO_ENABLED=0` for Go API builds
