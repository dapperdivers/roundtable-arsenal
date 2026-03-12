# Frontend Development Skill

You have tools and knowledge for frontend development with React, TypeScript, Vite, and Tailwind CSS.

## Stack

- **React 18+** with TypeScript
- **Vite** for dev server and bundling
- **Tailwind CSS** for styling
- **Storybook 8** for component development and visual testing

## Storybook

Storybook is installed on `roundtable-ui`. Use it for component development.

### Running Storybook

```bash
cd ui
npm run storybook          # Dev server (port 6006)
npx storybook build        # Static build (for CI)
```

### Writing Stories

Stories go next to their component: `ComponentName.stories.tsx`

```tsx
import type { Meta, StoryObj } from '@storybook/react';
import { ComponentName } from './ComponentName';

const meta: Meta<typeof ComponentName> = {
  title: 'Components/ComponentName',
  component: ComponentName,
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof ComponentName>;

export const Default: Story = {
  args: {
    // props here
  },
};

export const Variant: Story = {
  args: {
    // different props
  },
};
```

### Decorators

Components that need context providers:

```tsx
// React Router
import { MemoryRouter } from 'react-router-dom';

const meta: Meta<typeof ComponentName> = {
  decorators: [(Story) => <MemoryRouter><Story /></MemoryRouter>],
};

// React Flow (@xyflow/react)
import { ReactFlowProvider } from '@xyflow/react';

const meta: Meta<typeof ComponentName> = {
  decorators: [(Story) => <ReactFlowProvider><Story /></ReactFlowProvider>],
};
```

### Mock Data

Use realistic Round Table data in stories:

```tsx
const mockKnight = {
  name: 'galahad',
  domain: 'security',
  model: 'claude-sonnet-4-20250514',
  ready: true,
  taskCount: 42,
};

const mockMission = {
  name: 'pentest-sprint',
  phase: 'Active',
  objective: 'Penetration test the staging environment',
  knights: ['galahad', 'tristan'],
};
```

## Component Conventions

### File Structure
```
src/
  components/       # Reusable UI components
    ComponentName.tsx
    ComponentName.stories.tsx
  pages/            # Route-level page components
    PageName.tsx
  lib/              # API clients, utilities, types
```

### Styling
- Use Tailwind utility classes, not CSS modules
- Use `clsx` + `tailwind-merge` for conditional classes
- Dark mode: use `dark:` prefix classes

### TypeScript
- Define prop types with `interface` at the top of each component file
- Export types that other components need
- **ALWAYS run `npx tsc --noEmit` before pushing**

### API Data
- API client functions are in `src/lib/`
- Types mirror the Kubernetes CRD structures
- Use `fetch()` to the Go API backend (proxied in dev via Vite)

## Visual Testing Workflow

When developing UI components:

1. **Read** the existing component to understand its props and behavior
2. **Write/update** the story with representative variants
3. **Build Storybook** to verify rendering: `npx storybook build --quiet`
4. **Typecheck**: `npx tsc --noEmit`
5. **Build the app**: `npm run build`

## Anti-Patterns

- ❌ Don't use inline styles — use Tailwind
- ❌ Don't skip TypeScript — no `any` types, no `@ts-ignore`
- ❌ Don't forget dark mode variants in Tailwind classes
- ❌ Don't write components without stories — every component needs one
- ❌ Don't hardcode API URLs — use the lib/ client functions
