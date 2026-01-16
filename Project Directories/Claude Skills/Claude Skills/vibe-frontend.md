---
name: vibe-frontend
description: Frontend development combining distinctive UI design with conversion-focused copywriting and SEO. Use when building user interfaces, designing pages, writing web copy, implementing animations, or optimizing for search engines. Covers React/Next.js, CSS/Tailwind, animations, responsive design, accessibility, headlines, CTAs, meta tags, and content structure.
---

# Vibe Frontend

Design that stops scrolling. Copy that converts. Code that performs.

---

# 2025 Design Philosophy

**Beautiful design is intentional design.** Every pixel should earn its place. Every color should have a reason. Every animation should serve the user.

## Core Principles

```
1. CLARITY OVER CLEVERNESS
   - Users should understand your interface instantly
   - Complexity should be hidden, not displayed
   - When in doubt, simplify

2. RESTRAINT IS TASTE
   - The best designs feel effortless because they show restraint
   - One accent color. Two typefaces maximum. Three interaction patterns.
   - Empty space is a feature, not a bug

3. AUTHENTICITY OVER TRENDS
   - Design for YOUR brand, not "what's popular"
   - Borrow inspiration, don't copy wholesale
   - Let content and purpose drive visual decisions

4. CRAFT IN THE DETAILS
   - Micro-interactions that feel right
   - Typography that breathes
   - Colors that work in real lighting conditions
   - Transitions that feel natural, not performative

5. ACCESSIBILITY IS BEAUTY
   - Contrast ratios aren't constraints—they're clarity
   - Keyboard navigation isn't an afterthought—it's craft
   - Readable text isn't boring—it's respectful
```

## Design Inspiration (Study These)

```
REFERENCE THESE FOR QUALITY:
- Stripe (clarity, typography, motion)
- Linear (dark mode done right, information density)
- Vercel (minimalism, developer aesthetic)
- Raycast (keyboard-first, power user focus)
- Arc Browser (playful yet professional)
- Notion (flexible systems, whitespace)
- Figma (tool UI that feels native)
- Apple (restraint, hierarchy, polish)

STUDY THEIR PATTERNS:
- How they use ONE accent color
- How much whitespace they leave
- How subtle their animations are
- How readable their text is
- How few decorative elements they use
- How every element serves a purpose
```

## The Beauty Test

Before shipping any design, ask:

```
□ Does this feel calm or chaotic?
□ Could I remove an element and improve it?
□ Is the hierarchy immediately clear?
□ Does color guide attention to the right places?
□ Would this still work in grayscale?
□ Does the typography feel considered?
□ Are interactive elements obviously interactive?
□ Does this respect the user's time and attention?
```

---

# AUDIT FIRST — Before Implementing

**STOP!** Before adding UI components to an existing project, run a quick audit:

```bash
# Quick audit commands
ls -la components/           # Check existing components
ls -la components/ui/        # Check UI library (shadcn?)
cat tailwind.config.*        # Check existing Tailwind config
cat package.json | grep -E "shadcn|radix|framer"  # Check UI deps
```

## Pre-Implementation Checklist

```markdown
- [ ] Identified existing component library (shadcn, Radix, MUI)
- [ ] Checked existing design tokens/theme
- [ ] Noted existing Tailwind customizations
- [ ] Scanned existing components for reuse
- [ ] Identified existing animation patterns
- [ ] Checked existing form patterns
```

## If Conflicts Found:

| Conflict | Resolution |
|----------|------------|
| shadcn already setup | Use existing components, don't reinstall |
| Custom theme exists | Extend existing theme, don't override |
| Component exists | Extend or compose, don't duplicate |
| Different styling approach | Match existing patterns |

**Only proceed after audit is complete.**

---

# 🚨 LAYOUT FOUNDATIONS (MUST READ)

**Before building ANY components, establish proper page structure.** Most broken layouts come from skipping this step.

## The Root Layout Pattern

```tsx
// app/layout.tsx - ALWAYS START HERE
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="h-full">
      <body className="h-full flex flex-col">
        {children}
      </body>
    </html>
  )
}
```

## Page Layout Patterns

### Pattern 1: Full-Height App Layout (Dashboards)

```tsx
// app/(app)/layout.tsx
export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="h-full flex">
      {/* Sidebar - fixed width */}
      <aside className="w-64 shrink-0 border-r bg-muted/30">
        <Sidebar />
      </aside>
      
      {/* Main content - fills remaining space */}
      <main className="flex-1 flex flex-col min-w-0 overflow-hidden">
        {/* Header - fixed height */}
        <header className="h-14 shrink-0 border-b px-6 flex items-center">
          <Header />
        </header>
        
        {/* Content - scrollable */}
        <div className="flex-1 overflow-auto p-6">
          {children}
        </div>
      </main>
    </div>
  )
}
```

### Pattern 2: Marketing Page Layout

```tsx
// app/(marketing)/layout.tsx
export default function MarketingLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-full flex flex-col">
      {/* Navbar - sticky */}
      <header className="sticky top-0 z-50 border-b bg-background/95 backdrop-blur">
        <Navbar />
      </header>
      
      {/* Content - grows */}
      <main className="flex-1">
        {children}
      </main>
      
      {/* Footer - at bottom */}
      <footer className="border-t py-12">
        <Footer />
      </footer>
    </div>
  )
}
```

### Pattern 3: Split Panel Layout

```tsx
// For side-by-side layouts like your DesignForge
export default function SplitLayout() {
  return (
    <div className="h-full flex flex-col">
      {/* Top bar */}
      <header className="h-14 shrink-0 border-b px-4 flex items-center justify-between">
        <Logo />
        <Nav />
      </header>
      
      {/* Main content area */}
      <div className="flex-1 flex min-h-0"> {/* min-h-0 is CRITICAL for nested scroll */}
        {/* Left panel */}
        <aside className="w-72 shrink-0 border-r overflow-auto p-4">
          <LeftPanel />
        </aside>
        
        {/* Center content */}
        <main className="flex-1 min-w-0 overflow-auto p-6">
          <CenterContent />
        </main>
        
        {/* Right panel */}
        <aside className="w-80 shrink-0 border-l overflow-auto p-4">
          <RightPanel />
        </aside>
      </div>
    </div>
  )
}
```

## Critical Layout Rules

### Rule 1: Height Chain Must Be Unbroken

```tsx
// ❌ BROKEN - height chain broken at flex container
<html>           // No height
  <body>         // No height
    <div>        // No height - CHILDREN WILL COLLAPSE
      <div className="h-full">  // h-full of what? Parent has no height!

// ✅ CORRECT - height flows from root
<html className="h-full">
  <body className="h-full">
    <div className="h-full flex flex-col">
      <div className="flex-1">  // Takes remaining space
```

### Rule 2: Flex Children Need Constraints

```tsx
// ❌ BROKEN - children overflow container
<div className="flex">
  <div>Very long content...</div>  // Will push siblings off screen

// ✅ CORRECT - constrain children
<div className="flex">
  <div className="min-w-0 truncate">Very long content...</div>
  // OR
  <div className="shrink-0 w-64">Fixed width</div>
  <div className="flex-1 min-w-0">Takes rest</div>
```

### Rule 3: Nested Scroll Needs min-h-0

```tsx
// ❌ BROKEN - inner content won't scroll
<div className="flex-1">
  <div className="overflow-auto">  // Won't scroll!
    {/* Tall content */}
  </div>
</div>

// ✅ CORRECT - min-h-0 allows shrinking
<div className="flex-1 min-h-0">
  <div className="h-full overflow-auto">  // Now scrolls!
    {/* Tall content */}
  </div>
</div>
```

### Rule 4: Grid Needs Container Constraints

```tsx
// ❌ BROKEN - grid items fall into void
<div>
  <div className="grid grid-cols-3 gap-4">
    {cards}  // Will overflow if content is tall
  </div>
</div>

// ✅ CORRECT - constrain the grid container
<div className="flex-1 overflow-auto p-6">
  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
    {cards}
  </div>
</div>
```

### Rule 5: Absolute Positioning Needs Relative Parent

```tsx
// ❌ BROKEN - floats to nearest positioned ancestor (might be <body>!)
<div>
  <div className="absolute bottom-4 right-4">
    Floating Card
  </div>
</div>

// ✅ CORRECT - explicit positioning context
<div className="relative">
  <div className="absolute bottom-4 right-4">
    Floating Card
  </div>
</div>
```

## Responsive Layout Patterns

### Always Use Responsive Breakpoints

```tsx
// ❌ Will break on mobile
<div className="grid grid-cols-3">

// ✅ Responsive
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
```

### Collapsible Sidebar for Mobile

```tsx
function AppLayout({ children }) {
  const [sidebarOpen, setSidebarOpen] = useState(false)
  
  return (
    <div className="h-full flex">
      {/* Mobile sidebar overlay */}
      <div className={cn(
        "fixed inset-0 z-40 lg:hidden",
        sidebarOpen ? "block" : "hidden"
      )}>
        <div className="fixed inset-0 bg-black/50" onClick={() => setSidebarOpen(false)} />
        <aside className="fixed inset-y-0 left-0 w-64 bg-background">
          <Sidebar />
        </aside>
      </div>
      
      {/* Desktop sidebar */}
      <aside className="hidden lg:block w-64 shrink-0 border-r">
        <Sidebar />
      </aside>
      
      {/* Main content */}
      <main className="flex-1 min-w-0">
        {/* Mobile header with menu button */}
        <header className="lg:hidden h-14 border-b px-4 flex items-center">
          <button onClick={() => setSidebarOpen(true)}>
            <Menu className="h-6 w-6" />
          </button>
        </header>
        
        <div className="p-6">
          {children}
        </div>
      </main>
    </div>
  )
}
```

## Debug Layout Issues

```tsx
// Add this temporarily to see container boundaries
<div className="border-2 border-red-500">
  <div className="border-2 border-blue-500">
    <div className="border-2 border-green-500">
      Content
    </div>
  </div>
</div>

// Or use Tailwind debug screen size
<div className="fixed bottom-4 right-4 bg-black text-white p-2 text-xs z-50">
  <span className="sm:hidden">XS</span>
  <span className="hidden sm:inline md:hidden">SM</span>
  <span className="hidden md:inline lg:hidden">MD</span>
  <span className="hidden lg:inline xl:hidden">LG</span>
  <span className="hidden xl:inline">XL</span>
</div>
```

## Layout Checklist Before Building Components

```markdown
- [ ] Root layout has `h-full` on html and body
- [ ] App layout uses flex with flex-1 for main content
- [ ] All flex containers have proper constraints (shrink-0, min-w-0)
- [ ] Scrollable areas have min-h-0 on flex parent
- [ ] Grid uses responsive breakpoints (grid-cols-1 md:grid-cols-2)
- [ ] Absolutely positioned elements have relative parent
- [ ] Sidebar collapses on mobile
- [ ] Content areas have proper padding (p-4 or p-6)
```

---

# Reliable Interactive Components

## The Problem: Broken State Management

Your sidebar toggle "stopped working" because of common React mistakes:

```tsx
// ❌ BROKEN: State not persisted, event handlers broken
function Sidebar() {
  const [open, setOpen] = useState(true)  // Resets on re-render
  
  return (
    <button onClick={setOpen(!open)}>  // WRONG: Called immediately
      Toggle
    </button>
  )
}

// ❌ BROKEN: Multiple sources of truth
function App() {
  const [sidebarOpen, setSidebarOpen] = useState(true)
  
  return (
    <>
      <Sidebar open={sidebarOpen} />  {/* Prop */}
      <button onClick={() => setSidebarOpen(!sidebarOpen)}>Toggle</button>
    </>
  )
}
function Sidebar({ open }) {
  const [isOpen, setIsOpen] = useState(open)  // WRONG: Internal state shadows prop
}
```

## Collapsible Sidebar (CORRECT Implementation)

```tsx
'use client'
import { useState, useCallback } from 'react'
import { PanelLeftClose, PanelLeft, Menu, X } from 'lucide-react'
import { cn } from '@/lib/utils'

interface SidebarContextValue {
  isOpen: boolean
  isMobileOpen: boolean
  toggle: () => void
  toggleMobile: () => void
  closeMobile: () => void
}

const SidebarContext = createContext<SidebarContextValue | null>(null)

export function useSidebar() {
  const context = useContext(SidebarContext)
  if (!context) throw new Error('useSidebar must be used within SidebarProvider')
  return context
}

export function SidebarProvider({ children }: { children: React.ReactNode }) {
  const [isOpen, setIsOpen] = useState(true)
  const [isMobileOpen, setIsMobileOpen] = useState(false)
  
  // Use useCallback to prevent recreation on every render
  const toggle = useCallback(() => setIsOpen(prev => !prev), [])
  const toggleMobile = useCallback(() => setIsMobileOpen(prev => !prev), [])
  const closeMobile = useCallback(() => setIsMobileOpen(false), [])
  
  return (
    <SidebarContext.Provider value={{ isOpen, isMobileOpen, toggle, toggleMobile, closeMobile }}>
      {children}
    </SidebarContext.Provider>
  )
}

export function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <SidebarProvider>
      <div className="h-screen flex flex-col bg-gray-50">
        <Header />
        <div className="flex-1 flex min-h-0">
          <DesktopSidebar />
          <MobileSidebar />
          <main className="flex-1 min-w-0 overflow-auto">
            {children}
          </main>
        </div>
      </div>
    </SidebarProvider>
  )
}

function Header() {
  const { toggleMobile, toggle, isOpen } = useSidebar()
  
  return (
    <header className="h-14 shrink-0 bg-white border-b border-gray-200 px-4 flex items-center justify-between">
      <div className="flex items-center gap-3">
        {/* Mobile menu button */}
        <button 
          onClick={toggleMobile}
          className="lg:hidden p-2 hover:bg-gray-100 rounded-md"
          aria-label="Open menu"
        >
          <Menu className="w-5 h-5 text-gray-600" />
        </button>
        
        {/* Desktop collapse button */}
        <button 
          onClick={toggle}
          className="hidden lg:flex p-2 hover:bg-gray-100 rounded-md"
          aria-label={isOpen ? "Collapse sidebar" : "Expand sidebar"}
        >
          {isOpen ? (
            <PanelLeftClose className="w-5 h-5 text-gray-600" />
          ) : (
            <PanelLeft className="w-5 h-5 text-gray-600" />
          )}
        </button>
        
        <span className="font-semibold text-gray-900">DesignForge</span>
      </div>
    </header>
  )
}

function DesktopSidebar() {
  const { isOpen } = useSidebar()
  
  return (
    <aside className={cn(
      "hidden lg:flex flex-col shrink-0 bg-white border-r border-gray-200 transition-all duration-200",
      isOpen ? "w-64" : "w-16"
    )}>
      <SidebarContent collapsed={!isOpen} />
    </aside>
  )
}

function MobileSidebar() {
  const { isMobileOpen, closeMobile } = useSidebar()
  
  return (
    <>
      {/* Backdrop */}
      {isMobileOpen && (
        <div 
          className="fixed inset-0 z-40 bg-black/50 lg:hidden"
          onClick={closeMobile}
          aria-hidden="true"
        />
      )}
      
      {/* Sidebar */}
      <aside className={cn(
        "fixed inset-y-0 left-0 z-50 w-64 bg-white border-r border-gray-200 lg:hidden",
        "transform transition-transform duration-200 ease-in-out",
        isMobileOpen ? "translate-x-0" : "-translate-x-full"
      )}>
        <div className="h-14 flex items-center justify-between px-4 border-b border-gray-200">
          <span className="font-semibold text-gray-900">Menu</span>
          <button 
            onClick={closeMobile}
            className="p-2 hover:bg-gray-100 rounded-md"
            aria-label="Close menu"
          >
            <X className="w-5 h-5 text-gray-600" />
          </button>
        </div>
        <SidebarContent collapsed={false} />
      </aside>
    </>
  )
}

function SidebarContent({ collapsed }: { collapsed: boolean }) {
  return (
    <div className="flex-1 overflow-y-auto p-4">
      <nav className="space-y-1">
        <SidebarLink icon={Upload} label="Upload" collapsed={collapsed} active />
        <SidebarLink icon={Search} label="Analyze" collapsed={collapsed} />
        <SidebarLink icon={RefreshCw} label="Recreate" collapsed={collapsed} />
        <SidebarLink icon={Sliders} label="Refine" collapsed={collapsed} />
        <SidebarLink icon={Download} label="Export" collapsed={collapsed} />
      </nav>
    </div>
  )
}

function SidebarLink({ 
  icon: Icon, 
  label, 
  collapsed, 
  active = false 
}: { 
  icon: React.ComponentType<{ className?: string }>
  label: string
  collapsed: boolean
  active?: boolean 
}) {
  return (
    <a
      href="#"
      className={cn(
        "flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-colors",
        active 
          ? "bg-gray-100 text-gray-900 font-medium" 
          : "text-gray-600 hover:bg-gray-50 hover:text-gray-900"
      )}
    >
      <Icon className="w-5 h-5 shrink-0" />
      {!collapsed && <span>{label}</span>}
    </a>
  )
}
```

## Toggle Button Pattern (Reliable)

```tsx
// ❌ BROKEN: onClick runs immediately
<button onClick={setOpen(!open)}>Toggle</button>

// ❌ BROKEN: Stale closure
<button onClick={() => setOpen(!open)}>Toggle</button>  // 'open' may be stale

// ✅ CORRECT: Functional update
<button onClick={() => setOpen(prev => !prev)}>Toggle</button>

// ✅ CORRECT: useCallback for stable reference
const toggle = useCallback(() => setOpen(prev => !prev), [])
<button onClick={toggle}>Toggle</button>
```

## Interactive Component Checklist

```markdown
Before shipping ANY interactive component:

### State Management
- [ ] Single source of truth (not duplicated state)
- [ ] useState with functional updates for toggles
- [ ] useCallback for event handlers passed to children
- [ ] Context for state shared across components

### Event Handlers
- [ ] onClick={() => fn()} not onClick={fn()} 
- [ ] aria-label on icon-only buttons
- [ ] Keyboard accessible (Enter/Space triggers click)

### Visual Feedback
- [ ] Hover state visible
- [ ] Active/pressed state visible
- [ ] Disabled state obvious
- [ ] Loading state for async actions

### Accessibility
- [ ] Button has accessible name
- [ ] Focus visible (no outline-none)
- [ ] Screen reader announces state changes
```

---

## Design Philosophy

---

# 🚨 MANDATORY: Color System & Contrast Rules

**READ THIS FIRST. These rules are NON-NEGOTIABLE.**

## The #1 Problem: No Color System

Your screenshot shows the classic AI failure: random colors with no system.

```
WHAT'S WRONG:
- "Workspace" text is light gray on white (INVISIBLE)
- Background is pure white (#fff) with no depth
- Cards have no visible boundaries
- Random grays: #666, #888, #aaa, #ccc with no logic
- No foreground/background relationship
```

## Color Palette Rules (MUST FOLLOW)

### Rule 1: Define Your Palette FIRST

```tsx
// BEFORE writing ANY component, define these 6 colors minimum:

// Light Mode
const lightPalette = {
  // Backgrounds (3 levels)
  bg: {
    primary: '#ffffff',      // Main content background
    secondary: '#f9fafb',    // Sidebar, cards (MUST be different from primary)
    tertiary: '#f3f4f6',     // Nested elements, hover states
  },
  
  // Foregrounds (3 levels)  
  fg: {
    primary: '#111827',      // Headings, important text (DARK)
    secondary: '#4b5563',    // Body text (medium)
    tertiary: '#9ca3af',     // Muted text, placeholders (light, but NOT on light bg)
  },
  
  // Accent
  accent: '#2563eb',         // ONE color, used consistently
  
  // Borders
  border: '#e5e7eb',         // Visible but subtle
}

// Dark Mode  
const darkPalette = {
  bg: {
    primary: '#0f0f0f',      // Main content
    secondary: '#171717',    // Sidebar, cards
    tertiary: '#262626',     // Nested elements
  },
  
  fg: {
    primary: '#fafafa',      // Headings
    secondary: '#a1a1aa',    // Body text
    tertiary: '#71717a',     // Muted (NOT on dark bg alone)
  },
  
  accent: '#3b82f6',
  border: '#27272a',
}
```

### Rule 2: Contrast Requirements (WCAG AA Minimum)

```
TEXT CONTRAST (ratio to background):
- Primary text (headings):     7:1 minimum (AAA)
- Secondary text (body):       4.5:1 minimum (AA)
- Tertiary text (muted):       3:1 minimum (AA Large)

NEVER DO THIS:
❌ #9ca3af text on #ffffff background (2.8:1 - FAILS)
❌ #71717a text on #0f0f0f background (3.0:1 - BARELY PASSES)
❌ Light gray on light gray (your "Workspace" text)

ALWAYS DO THIS:
✅ #111827 text on #ffffff background (16:1 - EXCELLENT)
✅ #4b5563 text on #ffffff background (7:1 - GOOD)
✅ #6b7280 text on #ffffff background (5:1 - ACCEPTABLE for body)
```

### Rule 3: Background Layering

```tsx
// CRITICAL: Every layer must be visually distinct

// ❌ WRONG: Everything same color
<div className="bg-white">
  <aside className="bg-white">     {/* INVISIBLE sidebar */}
  <main className="bg-white">       {/* No separation */}
    <div className="bg-white">      {/* Cards blend in */}

// ✅ CORRECT: Clear visual hierarchy
<div className="bg-gray-50">                           {/* Page bg */}
  <aside className="bg-white border-r border-gray-200"> {/* Sidebar pops */}
  <main className="bg-gray-50">                         {/* Content area */}
    <div className="bg-white border border-gray-200 rounded-lg"> {/* Cards visible */}
```

### Rule 4: The Card Visibility Test

```tsx
// Ask: "Can I see where this card starts and ends?"

// ❌ INVISIBLE CARD
<div className="bg-white rounded-lg">  {/* On white bg = invisible */}

// ❌ BARELY VISIBLE
<div className="bg-white rounded-lg shadow-sm">  {/* Shadow alone isn't enough */}

// ✅ VISIBLE CARD (Option A: Border)
<div className="bg-white rounded-lg border border-gray-200">

// ✅ VISIBLE CARD (Option B: Background contrast)
<div className="bg-white rounded-lg">  {/* Only if parent is bg-gray-50+ */}

// ✅ VISIBLE CARD (Option C: Stronger shadow)
<div className="bg-white rounded-lg shadow-md ring-1 ring-gray-100">
```

---

## Light Mode Done Right

```tsx
// Full page structure with proper contrast

export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-gray-50">  {/* NOT white */}
      {/* Header */}
      <header className="bg-white border-b border-gray-200 h-14">
        <nav className="h-full px-4 flex items-center justify-between">
          <span className="font-semibold text-gray-900">DesignForge</span>  {/* DARK text */}
          <div className="flex items-center gap-2">
            {/* Buttons with proper contrast */}
          </div>
        </nav>
      </header>
      
      <div className="flex">
        {/* Sidebar - MUST be visually distinct */}
        <aside className="w-64 bg-white border-r border-gray-200 min-h-[calc(100vh-3.5rem)]">
          <div className="p-4">
            <h2 className="text-sm font-semibold text-gray-900">Workflow</h2>  {/* DARK */}
            <p className="text-sm text-gray-600 mt-1">Progress: 25%</p>  {/* Medium gray, NOT light */}
          </div>
        </aside>
        
        {/* Main content */}
        <main className="flex-1 p-6">
          {/* Page title - MUST be dark and prominent */}
          <h1 className="text-2xl font-bold text-gray-900">
            Design <span className="text-gray-400">Workspace</span>  {/* If you want muted, still needs contrast */}
          </h1>
          
          {/* Cards - MUST have visible boundaries */}
          <div className="mt-6 bg-white rounded-lg border border-gray-200 p-6">
            <h2 className="font-semibold text-gray-900">Input Source</h2>
            <p className="text-gray-600 mt-1">Select your design source</p>
          </div>
        </main>
      </div>
    </div>
  )
}
```

---

## Dark Mode Done Right

```tsx
export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-neutral-950">  {/* Near black, not pure black */}
      {/* Header */}
      <header className="bg-neutral-900 border-b border-neutral-800 h-14">
        <nav className="h-full px-4 flex items-center justify-between">
          <span className="font-semibold text-white">DesignForge</span>  {/* WHITE text */}
        </nav>
      </header>
      
      <div className="flex">
        {/* Sidebar - Slightly lighter than page bg */}
        <aside className="w-64 bg-neutral-900 border-r border-neutral-800">
          <div className="p-4">
            <h2 className="text-sm font-semibold text-white">Workflow</h2>
            <p className="text-sm text-neutral-400 mt-1">Progress: 25%</p>  {/* Not too dark */}
          </div>
        </aside>
        
        {/* Main content */}
        <main className="flex-1 p-6">
          <h1 className="text-2xl font-bold text-white">
            Design <span className="text-neutral-500">Workspace</span>
          </h1>
          
          {/* Cards - visible on dark bg */}
          <div className="mt-6 bg-neutral-900 rounded-lg border border-neutral-800 p-6">
            <h2 className="font-semibold text-white">Input Source</h2>
            <p className="text-neutral-400 mt-1">Select your design source</p>
          </div>
        </main>
      </div>
    </div>
  )
}
```

---

## Color Contrast Cheat Sheet

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         LIGHT MODE CONTRAST                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Background Layers:                                                          │
│  ┌──────────────┬──────────────┬──────────────┐                             │
│  │ bg-white     │ bg-gray-50   │ bg-gray-100  │                             │
│  │ #ffffff      │ #f9fafb      │ #f3f4f6      │                             │
│  │ Cards/Modal  │ Page bg      │ Nested/Hover │                             │
│  └──────────────┴──────────────┴──────────────┘                             │
│                                                                              │
│  Text on white/gray-50:                                                      │
│  ┌──────────────┬──────────────┬──────────────┐                             │
│  │ text-gray-900│ text-gray-600│ text-gray-500│                             │
│  │ #111827      │ #4b5563      │ #6b7280      │                             │
│  │ Headings     │ Body text    │ Muted (min)  │                             │
│  │ 16:1 ✅      │ 7:1 ✅       │ 5:1 ✅       │                             │
│  └──────────────┴──────────────┴──────────────┘                             │
│                                                                              │
│  ❌ NEVER: text-gray-400 (#9ca3af) on white = 2.8:1 FAILS                   │
│                                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                         DARK MODE CONTRAST                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Background Layers:                                                          │
│  ┌──────────────┬──────────────┬──────────────┐                             │
│  │ bg-neutral-  │ bg-neutral-  │ bg-neutral-  │                             │
│  │ 950 (#0a0a0a)│ 900 (#171717)│ 800 (#262626)│                             │
│  │ Page bg      │ Cards/Sidebar│ Nested/Hover │                             │
│  └──────────────┴──────────────┴──────────────┘                             │
│                                                                              │
│  Text on dark backgrounds:                                                   │
│  ┌──────────────┬──────────────┬──────────────┐                             │
│  │ text-white   │ text-neutral-│ text-neutral-│                             │
│  │ #ffffff      │ 300 (#d4d4d4)│ 400 (#a3a3a3)│                             │
│  │ Headings     │ Body text    │ Muted (min)  │                             │
│  │ 21:1 ✅      │ 11:1 ✅      │ 7:1 ✅       │                             │
│  └──────────────┴──────────────┴──────────────┘                             │
│                                                                              │
│  ❌ NEVER: text-neutral-600 (#525252) on neutral-900 = 3.3:1 BARELY         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Pre-Build Checklist (REQUIRED)

Before writing ANY UI code, answer these:

```markdown
## Color System Checklist

### Palette Defined?
- [ ] Page background color defined (NOT pure white in light mode)
- [ ] Card/surface background defined (DIFFERENT from page)
- [ ] Primary text color defined (HIGH contrast)
- [ ] Secondary text color defined (READABLE contrast)
- [ ] Border color defined (VISIBLE)
- [ ] Accent color defined (ONE color)

### Contrast Verified?
- [ ] Headings have 7:1+ contrast ratio
- [ ] Body text has 4.5:1+ contrast ratio
- [ ] Muted text has 3:1+ contrast ratio (and used sparingly)
- [ ] No light-on-light or dark-on-dark text

### Visual Hierarchy Clear?
- [ ] Cards are visually distinct from background
- [ ] Sidebar is visually distinct from main content
- [ ] Sections have clear boundaries
- [ ] Interactive elements are obvious
```

---

## Crafting Professional UI: Quick Reference

### The Two Absolute Bans

These elements are never acceptable, regardless of context:

```
1. SPARKLES — Zero tolerance
   - <Sparkles> icon from any library
   - ✨ emoji anywhere in UI
   - Star-burst, twinkle, or glitter effects
   - "Magic wand with glow" patterns

2. PURPLE-BLUE GRADIENTS — Zero tolerance
   - bg-gradient-to-r from-purple-500 to-blue-500
   - Any purple-to-blue or violet-to-indigo gradient
   - Gradient text with purple/blue

These have become universal markers of AI-generated design.
Serious products never use them.
```

### Professional Icon Selection

```
FOR AI/GENERATION FEATURES (instead of sparkles):
- Zap — Speed, instant generation (PREFERRED)
- ArrowRight — Action-focused, forward momentum
- Play — Execute, run
- Send — Submit
- RefreshCw — Regenerate, retry
- Terminal — Code generation
- Cpu — Processing (subtle, technical)

FOR CREATION:
- Plus — Universal create/add
- FilePlus — New document
- PenLine — Edit, compose

FOR FEEDBACK:
- Loader2 (with animate-spin) — Loading
- Check / CheckCircle — Success
- AlertCircle — Error, warning

ICON RULES:
- ONE library (Lucide recommended)
- ONE style (outline OR solid)
- Icons inherit text color (no gradients, no glows)
- Size: 16-20px inline, 24px standalone
```

### Quick Color Guide

```
INSTEAD OF GRADIENTS:
- Single solid accent color
- Your brand color (best choice)
- Emerald/green for success
- Neutral grays for most UI

BACKGROUNDS:
- Off-white (#fafafa) not pure white
- Off-black (#171717) not pure black
- Warm grays over cool grays
```

### The Professional Test

Before shipping ANY UI, ask:
1. "Would Stripe, Linear, or Vercel use this visual element?" If no, remove it.
2. "Does this look like every AI demo from 2023?" If yes, redesign it.
3. "Would a Fortune 500 company accept this design?" If no, simplify it.
4. "Are there ANY sparkles, glows, or purple-blue gradients?" If yes, remove them.

---

## WHAT TO DO INSTEAD: Professional Design Patterns

**This section provides positive guidance on how to create distinctive, professional UI that feels crafted and intentional—not generated.**

### Color & Palette

```
CREATIVE COLOR COMBINATIONS (2025 Palettes):
- Mustard (#D4A84B) + Navy (#1E3A5F) — warm confidence
- Terracotta (#C4573A) + Sage (#87A878) — organic sophistication  
- Coral (#FF6F61) + Charcoal (#36454F) — energetic but grounded
- Olive (#708238) + Cream (#FFFDD0) — quiet luxury
- Rust (#B7410E) + Slate (#708090) — industrial warmth
- Forest green (#228B22) + Blush (#DE5D83) — unexpected harmony
- Deep teal (#014D4E) + Warm white (#FAF9F6) — serene authority
- Burgundy (#800020) + Sand (#C2B280) — timeless elegance

STRATEGIC COLOR USE:
- Pick ONE strong accent color, not gradients
- Use off-whites (#fafafa, #f5f5f4, #FAF9F6) instead of pure #fff
- Use off-blacks (#171717, #1c1c1c, #0f0f0f) instead of pure #000
- Consider warm grays (stone, zinc) over cool grays (slate, gray)
- Let whitespace do the work instead of gradient fills
- Use color sparingly—reserve accent for 1-2 key actions per screen
- Dark mode: Use layered grays (#0f0f0f, #171717, #262626) for depth

COLOR HIERARCHY:
- Background: Neutral, recedes
- Surface: Slightly elevated (cards, modals)
- Primary text: High contrast, commands attention
- Secondary text: Medium contrast, supports
- Accent: Appears rarely, signals action
- Error/Success: Semantic, not decorative
```

### Typography

```
FONTS WITH PERSONALITY (2025 Recommendations):

Editorial/Luxury:
- Playfair Display — classic elegance
- Cormorant — refined serif
- Fraunces — quirky serif with character
- Instrument Serif — modern editorial

Modern/Technical:
- Space Grotesk — geometric with warmth
- Cabinet Grotesk — confident, distinctive
- Satoshi — clean but not sterile
- General Sans — versatile, characterful
- Geist — Vercel's font, technical precision

Monospace (for technical products):
- JetBrains Mono — readable code
- IBM Plex Mono — industrial
- Fira Code — ligatures for developers
- Berkeley Mono — premium feel

TYPOGRAPHIC CRAFT:
- Create hierarchy through SIZE contrast, not just weight
- Headlines: 1.1-1.2 line-height (tight, impactful)
- Body text: 1.5-1.7 line-height (readable, breathable)
- Left-align body text (center only for short, intentional moments)
- Body copy: 16-18px minimum (respect readability)
- Resist oversized hero text unless content warrants it
- Limit to 2-3 font weights (400, 500, 700 is enough)
- Letter-spacing: Slightly tighter for headlines, default for body

PAIRING EXAMPLES:
- Space Grotesk (headlines) + Inter (body) — modern tech
- Playfair Display (headlines) + Source Sans 3 (body) — editorial
- Cabinet Grotesk (headlines) + Satoshi (body) — confident SaaS
- Instrument Serif (headlines) + Geist (body) — refined product
```

### Layout & Structure

```
BREAK THE TEMPLATE:
- Asymmetric layouts create visual interest
- Offset grids (70/30 splits, 60/40, not always 50/50)
- Vary item counts: 2, 4, or 5 cards—rarely exactly 3
- Use negative space asymmetrically (more on one side)
- Let content dictate layout, not templates
- Create visual tension through intentional alignment breaks
- Mix full-bleed elements with contained sections

LAYOUT TECHNIQUES FOR 2025:
- Overlap elements intentionally (text over image edges)
- Use generous margins (more than you think)
- Create rhythm through alternating section densities
- Let some sections breathe, pack others tightly
- Consider vertical rhythm (consistent spacing multiples)
- Use CSS Grid for complex, intentional layouts
- Embrace unusual aspect ratios for images

AVOID TEMPLATE THINKING:
- If you have 3 features, show 2 prominently + 1 different
- Pricing doesn't need exactly 3 tiers (2 is often clearer)
- Footer doesn't need 4 equal columns
- Hero doesn't need centered text + subtext + button
- Not every section needs the same container width
```

### Components & UI

```
PURPOSE-DRIVEN DESIGN:
- Design buttons with purpose—vary shapes based on hierarchy
- Primary: solid fill, high contrast
- Secondary: outlined or subtle fill
- Ghost: text only or minimal styling
- Use borders and lines instead of shadows for separation
- Cards don't always need icons—text can be powerful alone
- Remove decorative elements unless they serve a function
- Every component should answer "why is this here?"

SUBSTANTIAL, NOT FLOATY:
- Inputs should feel substantial (padding, clear borders)
- Buttons should feel clickable (adequate size, visual feedback)
- Cards need clear boundaries (border OR background contrast, not neither)
- Modals should feel grounded (subtle shadow, clear backdrop)
- Form fields: 40-48px height, clear focus states

2025 COMPONENT TRENDS:
- Subtle borders over heavy shadows
- Rounded corners: 8-12px (not too round, not too sharp)
- Micro-interactions on focus/hover (subtle transforms)
- Command palettes (Cmd+K patterns)
- Inline editing over modal forms
- Progressive disclosure over everything visible
- Skeleton loading that matches content shape
```

### Imagery & Graphics

```
INTENTIONAL VISUAL CHOICES:
- Photography with a consistent mood/treatment
- Color grading that matches your palette
- Illustrations with a distinctive, ownable style
- Icons consistent in stroke weight throughout
- Real UI screenshots, not idealized mockups
- Texture, grain, or solid colors—not gradient blobs

ICON CRAFT:
- Choose ONE icon library and commit
- Lucide (clean, minimal)
- Heroicons (Tailwind-native)
- Phosphor (flexible weights)
- Consistent stroke width: 1.5px or 2px, never mixed
- Icons should aid comprehension or be removed
- Size: 16-20px for inline, 24px for standalone

BACKGROUND TREATMENT:
- Solid colors (most elegant)
- Subtle gradients (same color family, not purple-blue)
- Fine grain/noise texture (adds depth without distraction)
- Subtle grid patterns (technical, structured feel)
- Photography (full-bleed, muted, as backdrop)
- AVOID: Gradient blobs, particle effects, abstract shapes
```

### Copy & Microcopy

```
SPECIFIC, CONCRETE COPY:
Good: "Save 4 hours per week on reporting"
Bad: "Transform your workflow"

Good: "Edit videos in your browser"
Bad: "Unlock the power of video"

Good: "Used by 847 design teams"
Bad: "Trusted by thousands"

Good: "Deploys in 38 seconds on average"
Bad: "Lightning-fast deployments"

NATURAL, HONEST LANGUAGE:
- Conversational tone over corporate speak
- CTAs with specifics: "Start your 14-day trial" not "Get Started"
- Match voice to actual brand personality
- Numbers and specifics beat vague superlatives
- If you can't prove it, don't claim it
- Shorter is usually better

HEADLINE CRAFT:
- Lead with benefit, not feature
- Be specific about what changes for the user
- Use active voice
- Cut words until it breaks, then add one back
- Test readability out loud

ALWAYS BANNED PHRASES:
- Seamlessly, revolutionize, supercharge, elevate, unlock
- "The future of [X]"
- "Reimagine how you [X]"
- "All-in-one platform"
- "Built for modern teams"
- "Effortlessly [X]"
- Any phrase you've seen on 10 other landing pages
```

### Animation & Interaction

```
ANIMATE WITH PURPOSE:
- Micro-interactions provide feedback (button press, form validation)
- Transitions guide attention (modal open, page change)
- Animation should answer "what just happened?" or "what's next?"
- If removing the animation wouldn't hurt UX, remove it

TIMING & EASING (2025 Standards):
- Micro-interactions: 100-150ms
- UI transitions: 200-300ms  
- Page transitions: 300-500ms
- Easing: ease-out for exits, ease-in-out for movements
- AVOID: bounce, spring (feels dated), linear (feels robotic)

SUBTLE OVER FLASHY:
- Prefer opacity and transform over scale
- Prefer ease-out over bounce/spring
- Not everything needs to animate
- Loading spinners: the main valid continuous animation
- Hover states: inform, don't entertain

WHAT TO ANIMATE:
✓ Button press feedback (subtle scale/shadow)
✓ Focus states (ring appearance)
✓ Modal/dropdown appearance
✓ Toast notifications
✓ Loading indicators
✓ Form validation feedback

WHAT NOT TO ANIMATE:
✗ Every section on scroll
✗ Background decorative elements
✗ Text appearing letter by letter
✗ Logos floating/bouncing
✗ Cards scaling on hover (unless it's the primary interaction)
```

### Technical Implementation

```
CLEAN CODE PATTERNS:
- Extract repeated Tailwind patterns into components
- Don't use every shadcn component because it's available
- Customize shadcn to match your design language
- Semantic HTML: section, article, nav, main, aside, header, footer
- Ensure design works without JavaScript animations
- Test in slow network conditions

TAILWIND CRAFT:
- Create design tokens in tailwind.config
- Use @apply for repeated patterns
- Organize utilities: layout → spacing → typography → color → effects
- Limit to necessary utilities (no className soup)
- Use CSS Grid when flexbox isn't the right tool

COMPONENT ARCHITECTURE:
- If you use a library, customize it
- If you use an icon set, subset it
- If you copy a pattern, adapt it to your context
- Remove unused code and dependencies
- Consistent prop patterns across similar components
```

### Design Philosophy

```
INTENTIONAL THINKING:
- Embrace constraints—a limited palette forces creativity
- Design for the specific brand/context, not "generic modern"
- Prioritize readability and usability over visual flair
- Ask "why is this element here?" for every decorative choice
- Study specific inspirations (Stripe, Linear, Vercel, Raycast, Arc)

RUTHLESS EDITING:
- When in doubt, REMOVE elements rather than add them
- Simpler is almost always better
- Every element should earn its place
- White space is not wasted space
- Fewer colors, fewer fonts, fewer effects
- A design is complete when there's nothing left to remove

THE CRAFT MINDSET:
- Would you be proud to show this to a designer you respect?
- Does this solve the user's problem or just look nice?
- Is this sustainable (can you maintain this quality)?
- Does this feel like YOUR product or everyone's product?
```

---

## PATTERNS TO QUESTION: Common Design Pitfalls

**Context matters.** Most patterns below aren't inherently bad—they're just overused to the point of being meaningless. Question whether each serves YOUR design, or if you're using it because "that's what websites look like."

Two patterns, however, are absolutely banned with no exceptions: **sparkles and purple-blue gradients**. These have become universal markers of AI-generated, low-effort design.

### ABSOLUTELY BANNED (No Exceptions, Ever)

```
ZERO TOLERANCE — These destroy credibility instantly:

SPARKLES:
- <Sparkles> icon from any library
- ✨ emoji anywhere in UI
- Star-burst or twinkle effects
- Glitter animations
- Any "magic" visual metaphor

PURPLE-BLUE GRADIENTS:
- bg-gradient-to-r from-purple-500 to-blue-500
- bg-gradient-to-r from-indigo-500 to-purple-500
- bg-gradient-to-r from-violet-500 to-indigo-500
- Any purple-to-blue gradient variation
- Gradient text with purple/blue

Why these specifically? They've become THE visual cliché of AI-generated content.
Every AI demo, every ChatGPT wrapper, every "AI-powered" landing page uses them.
Using them signals "I didn't think about design, I just accepted defaults."
```

### QUESTION: Visual Design Choices

These patterns are overused. Ask "why this?" before using them.

```
COLOR CHOICES (QUESTION THESE):
- Violet/indigo as primary accent → Why not a color with personality?
- Dark mode with neon accents → Does this match your brand?
- Teal-to-cyan gradients → Is a gradient necessary at all?
- Overly safe, harmonious palettes → Where's the visual interest?

DECORATIVE ELEMENTS (QUESTION THESE):
- Floating gradient blobs → What do they communicate?
- Glowing orbs → Is this decorating or adding meaning?
- Abstract wavy lines → Why waves specifically?
- Dot grid patterns → Does this support the content?

These might be fine if: They reinforce a specific brand identity, 
they're used with extreme restraint, or they serve a clear purpose.

EFFECTS (QUESTION THESE):
- Glassmorphism → Is this a focal point or just decoration?
- Heavy blur/backdrop-filter → Does this add or distract?
- Pillowy shadows everywhere → Could borders work instead?
- Gradient borders → Is this the brand or just "modern"?
```

### QUESTION: Layout Patterns

```
PAGE STRUCTURES (COMMON BUT OFTEN LAZY):
- Giant centered hero + subtext + CTA → Does your content need this much space?
- Exactly 3 feature cards → Why not 2, 4, or a different format entirely?
- Bento box grids → Does this layout serve the content?
- Left-right-left-right sections → Is alternating necessary?
- 3-tier pricing (Free/Pro/Enterprise) → Do users need 3 choices?

Ask: "Am I using this layout because it fits, or because it's familiar?"

BETTER APPROACHES:
- Let content determine layout
- Vary structures between pages
- Break patterns intentionally
- Use asymmetry for visual interest
```

### QUESTION: Typography Choices

```
FONTS (SAFE BUT GENERIC):
- Inter → The world's most common font. Is that what you want?
- Poppins → Second most common. Does it say anything about your brand?
- DM Sans → Popular ≠ appropriate

If you use these, ask: "Is there a brand reason, or am I just defaulting?"

TYPOGRAPHIC PATTERNS:
- Giant hero text (text-6xl+) → Does the content warrant this?
- Gradient text → Is this a brand statement or decoration?
- Gray-500 body on white → Is this readable enough?

These are fine when: Brand guidelines specify them, or you've 
intentionally chosen them for a specific reason.
```

### QUESTION: Component Choices

```
UI PATTERNS (OVERUSED):
- Pill buttons for everything → Are these your brand or just trendy?
- Icon → Title → Description cards → Could text alone be more powerful?
- Badge chips everywhere → Is every piece of info really a "badge"?
- Person-with-laptop illustrations → Does this represent your users?

These are fine when: They genuinely fit the interaction pattern,
not just because they're what components "look like."
```

### QUESTION: Animation Choices

```
ANIMATIONS (OFTEN GRATUITOUS):
- Fade-in-up on every scroll section → Does this guide attention or distract?
- Scale-105 hover on every card → Is this meaningful feedback?
- Typewriter hero text → Is this cute or annoying by the 10th visit?
- Stagger animations everywhere → Does timing add meaning?

Animation is fine when: It provides feedback, guides attention,
or communicates state change. Not when it's just "more alive."
```

### The Thoughtful Design Checklist

```markdown
## Before Shipping

### ABSOLUTE BANS (Must be NO)
- [ ] Any sparkle icons or ✨ emoji? → REMOVE
- [ ] Any purple-to-blue gradients? → REMOVE

### PATTERN AUDIT (Ask "why?" for each YES)
- [ ] Am I using violet/indigo without brand reason?
- [ ] Do I have exactly 3 feature cards?
- [ ] Is my hero: centered giant text + subtext + CTA?
- [ ] Am I using Inter/Poppins as default?
- [ ] Are all buttons pill-shaped?
- [ ] Does every section animate on scroll?
- [ ] Are there decorative blobs in backgrounds?

For each YES: Either justify it or change it.
```

---

## shadcn/ui Design System (Reference Standard)

When building "modern" UI, follow shadcn conventions BUT customize them. Using shadcn exactly as-is is itself an AI tell. Modify colors, spacing, and variants to make it yours.

### Design Tokens (CSS Variables)

```css
/* globals.css - shadcn-style tokens */
@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 240 10% 3.9%;
    --card: 0 0% 100%;
    --card-foreground: 240 10% 3.9%;
    --popover: 0 0% 100%;
    --popover-foreground: 240 10% 3.9%;
    --primary: 240 5.9% 10%;
    --primary-foreground: 0 0% 98%;
    --secondary: 240 4.8% 95.9%;
    --secondary-foreground: 240 5.9% 10%;
    --muted: 240 4.8% 95.9%;
    --muted-foreground: 240 3.8% 46.1%;
    --accent: 240 4.8% 95.9%;
    --accent-foreground: 240 5.9% 10%;
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 0 0% 98%;
    --border: 240 5.9% 90%;
    --input: 240 5.9% 90%;
    --ring: 240 5.9% 10%;
    --radius: 0.5rem;
  }

  .dark {
    --background: 240 10% 3.9%;
    --foreground: 0 0% 98%;
    --card: 240 10% 3.9%;
    --card-foreground: 0 0% 98%;
    --popover: 240 10% 3.9%;
    --popover-foreground: 0 0% 98%;
    --primary: 0 0% 98%;
    --primary-foreground: 240 5.9% 10%;
    --secondary: 240 3.7% 15.9%;
    --secondary-foreground: 0 0% 98%;
    --muted: 240 3.7% 15.9%;
    --muted-foreground: 240 5% 64.9%;
    --accent: 240 3.7% 15.9%;
    --accent-foreground: 0 0% 98%;
    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 0 0% 98%;
    --border: 240 3.7% 15.9%;
    --input: 240 3.7% 15.9%;
    --ring: 240 4.9% 83.9%;
  }
}
```

### Tailwind Config (shadcn-style)

```typescript
// tailwind.config.ts
import type { Config } from "tailwindcss"

const config: Config = {
  darkMode: ["class"],
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
}
export default config
```

### cn() Utility (Required)

```typescript
// lib/utils.ts
import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
```

---

## shadcn-Style Component Wrappers

These are production-ready components following shadcn conventions.

### Button (shadcn-style)

```tsx
// components/ui/button.tsx
import * as React from "react"
import { Slot } from "@radix-ui/react-slot"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const buttonVariants = cva(
  // Base styles - CLEAN, NO GRADIENTS
  "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        // Primary: Solid, single color
        default: "bg-primary text-primary-foreground shadow hover:bg-primary/90",
        // Destructive: For dangerous actions
        destructive: "bg-destructive text-destructive-foreground shadow-sm hover:bg-destructive/90",
        // Outline: Clear boundaries
        outline: "border border-input bg-background shadow-sm hover:bg-accent hover:text-accent-foreground",
        // Secondary: Muted but visible
        secondary: "bg-secondary text-secondary-foreground shadow-sm hover:bg-secondary/80",
        // Ghost: Minimal, for less important actions
        ghost: "hover:bg-accent hover:text-accent-foreground",
        // Link: Text only
        link: "text-primary underline-offset-4 hover:underline",
      },
      size: {
        default: "h-9 px-4 py-2",
        sm: "h-8 rounded-md px-3 text-xs",
        lg: "h-10 rounded-md px-8",
        icon: "h-9 w-9",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : "button"
    return (
      <Comp
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    )
  }
)
Button.displayName = "Button"

export { Button, buttonVariants }
```

### Card (shadcn-style)

```tsx
// components/ui/card.tsx
import * as React from "react"
import { cn } from "@/lib/utils"

const Card = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      // CLEAN: No gradient borders, no excessive shadows
      "rounded-xl border bg-card text-card-foreground shadow-sm",
      className
    )}
    {...props}
  />
))
Card.displayName = "Card"

const CardHeader = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn("flex flex-col space-y-1.5 p-6", className)}
    {...props}
  />
))
CardHeader.displayName = "CardHeader"

const CardTitle = React.forwardRef<
  HTMLParagraphElement,
  React.HTMLAttributes<HTMLHeadingElement>
>(({ className, ...props }, ref) => (
  <h3
    ref={ref}
    className={cn("font-semibold leading-none tracking-tight", className)}
    {...props}
  />
))
CardTitle.displayName = "CardTitle"

const CardDescription = React.forwardRef<
  HTMLParagraphElement,
  React.HTMLAttributes<HTMLParagraphElement>
>(({ className, ...props }, ref) => (
  <p
    ref={ref}
    className={cn("text-sm text-muted-foreground", className)}
    {...props}
  />
))
CardDescription.displayName = "CardDescription"

const CardContent = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div ref={ref} className={cn("p-6 pt-0", className)} {...props} />
))
CardContent.displayName = "CardContent"

const CardFooter = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn("flex items-center p-6 pt-0", className)}
    {...props}
  />
))
CardFooter.displayName = "CardFooter"

export { Card, CardHeader, CardFooter, CardTitle, CardDescription, CardContent }
```

### Badge (shadcn-style)

```tsx
// components/ui/badge.tsx
import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const badgeVariants = cva(
  // CLEAN: Simple, no gradients
  "inline-flex items-center rounded-md border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
  {
    variants: {
      variant: {
        default: "border-transparent bg-primary text-primary-foreground shadow",
        secondary: "border-transparent bg-secondary text-secondary-foreground",
        destructive: "border-transparent bg-destructive text-destructive-foreground shadow",
        outline: "text-foreground",
        // Custom status variants
        success: "border-transparent bg-emerald-500/10 text-emerald-500",
        warning: "border-transparent bg-amber-500/10 text-amber-500",
      },
    },
    defaultVariants: {
      variant: "default",
    },
  }
)

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {}

function Badge({ className, variant, ...props }: BadgeProps) {
  return (
    <div className={cn(badgeVariants({ variant }), className)} {...props} />
  )
}

export { Badge, badgeVariants }
```

### Input (shadcn-style)

```tsx
// components/ui/input.tsx
import * as React from "react"
import { cn } from "@/lib/utils"

export interface InputProps
  extends React.InputHTMLAttributes<HTMLInputElement> {}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, type, ...props }, ref) => {
    return (
      <input
        type={type}
        className={cn(
          // CLEAN: Simple border, no glow effects
          "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors",
          "file:border-0 file:bg-transparent file:text-sm file:font-medium",
          "placeholder:text-muted-foreground",
          "focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
          "disabled:cursor-not-allowed disabled:opacity-50",
          className
        )}
        ref={ref}
        {...props}
      />
    )
  }
)
Input.displayName = "Input"

export { Input }
```

### AI Feature Button (Professional, Not AI-Looking)

```tsx
// The RIGHT way to style an AI feature button
// It should look like any other button - professional and clean

// ❌ ABSOLUTELY FORBIDDEN - AI SLOP
<button className="bg-gradient-to-r from-purple-500 to-blue-500 text-white rounded-full px-6 py-3">
  <Sparkles className="w-4 h-4 mr-2" />  {/* NEVER USE SPARKLES */}
  ✨ Generate with AI  {/* NEVER USE EMOJI */}
</button>

// ✅ PROFESSIONAL: Looks like a normal, high-quality button
<Button>
  <Zap className="w-4 h-4 mr-2" />
  Generate
</Button>

// ✅ PROFESSIONAL: If you want emphasis, use your brand color
<Button className="bg-emerald-600 hover:bg-emerald-500 text-white">
  Generate
</Button>

// ✅ PROFESSIONAL: Action-focused, not magic-focused
<Button>
  <ArrowRight className="w-4 h-4 mr-2" />
  Create
</Button>

// ✅ PROFESSIONAL: Secondary style for less emphasis
<Button variant="outline">
  <RefreshCw className="w-4 h-4 mr-2" />
  Regenerate
</Button>
```

### Status Badge (Professional, Not AI-Looking)

```tsx
// ❌ ABSOLUTELY FORBIDDEN - AI SLOP
<span className="bg-gradient-to-r from-purple-500 to-pink-500 text-white px-3 py-1 rounded-full animate-pulse">
  ✨ AI Enabled  {/* NEVER USE SPARKLES OR EMOJI */}
</span>

// ✅ PROFESSIONAL: Subtle, clean
<Badge variant="secondary">
  <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 mr-1.5" />
  Online
</Badge>

// ✅ PROFESSIONAL: If you must indicate AI, be subtle
<Badge variant="outline" className="font-normal">
  AI-assisted
</Badge>

// ✅ PROFESSIONAL: Use simple text, no visual gimmicks
<Badge variant="secondary">
  Smart
</Badge>
```

---

**COLOR & CONTRAST**
```
❌ Purple-to-blue gradients (the #1 AI default)
❌ Gray-on-gray text that's barely readable
❌ Rainbow accent colors (different color per card)
❌ White cards on light gray (no visible boundaries)
❌ Button states with similar colors (active vs inactive nearly identical)
❌ Invisible hover effects (color change too subtle)

✅ ONE accent color used consistently
✅ Body text with 4.5:1+ contrast ratio
✅ High-contrast interactive states
✅ OBVIOUS state changes (active, hover, disabled)
```

**TYPOGRAPHY**
```
❌ Inter/Roboto/system font everywhere (zero personality)
❌ Random type sizes with no scale relationship
❌ Everything bold OR nothing bold
❌ Tiny line-heights (1.2-1.3 on body text)
❌ ALL CAPS EVERYWHERE

✅ Display font with character for headlines
✅ Mathematical type scale (1.25, 1.333, or 1.5 ratio)
✅ Weight variation for hierarchy (300-800 range)
✅ Body text line-height 1.5-1.7
✅ Caps reserved for short labels only
```

**LAYOUT & SPACING**
```
❌ Everything perfectly centered (PowerPoint vibes)
❌ Identical card grids (same size, shadow, padding)
❌ Fixed widths causing horizontal scroll
❌ Uniform padding/margin on everything
❌ No whitespace (content crammed together)

✅ Left-align body text, center only intentionally
✅ Vary card sizes or use alternative patterns (bento, lists)
✅ Fluid widths (max-width + 100%)
✅ Spacing varies by content importance
✅ Generous whitespace (when in doubt, add more)
```

**IMAGES & ICONS**
```
❌ Generic stock photos (smiling team in office)
❌ Inconsistent icon styles (mixing sets)
❌ Decorative icons without purpose
❌ Misaligned or wrong-sized icons
❌ Unoptimized images (4MB hero images)
❌ EMOJI IN HEADLINES (lazy, breaks encoding, looks unprofessional)
❌ Emoji for critical UI elements (inconsistent cross-platform)
❌ SPARKLE ICONS OF ANY KIND (absolute ban - see Anti-AI-Slop section)
❌ Gradient icons or icons with glow effects
❌ "Magic" themed icons (wands with glow, stars with sparkle)
❌ AI-cliché icons (brains, robots, neural networks)

✅ Real photos, illustrations, or intentional abstract
✅ ONE icon set, ONE style (outline OR solid, never mixed)
✅ Icons that aid comprehension or remove them
✅ Icons sized to match text weight (1.25-1.5x font size)
✅ WebP/AVIF, srcset, lazy loading, proper dimensions
✅ SVG icons from professional libraries (Lucide, Heroicons, Phosphor)
✅ Simple, single-color icons that inherit text color
✅ Animated icons only for meaningful feedback (loading, success)
```

**BUTTONS & INTERACTIONS**
```
❌ Too many button styles (Primary, Secondary, Tertiary, Ghost, Outline, Gradient...)
❌ Generic text ("Submit", "Click Here", "Learn More")
❌ Disabled buttons that look enabled
❌ No loading states on async actions
❌ No focus states (outline: none for "aesthetics")

✅ MAX 3 button styles (Primary, Secondary, Ghost)
✅ Specific action + benefit ("Start Free Trial", "Download PDF")
✅ Disabled = 40-50% opacity, obviously inactive
✅ Every action: loading → success/error states
✅ Visible focus ring (:focus-visible)
```

**MOBILE & RESPONSIVE**
```
❌ Mobile as afterthought (desktop cramped into 375px)
❌ Broken at common breakpoints (768px, 1024px)
❌ Tiny tap targets (< 44px)
❌ Nav disappears on mobile or hamburger doesn't work

✅ Design mobile-first, desktop as enhancement
✅ Test: 375, 768, 1024, 1280, 1440
✅ Minimum 44x44px touch targets
✅ Mobile nav is its own tested component
```

**CONTENT & UX**
```
❌ Lorem ipsum shipped to production
❌ Feature vomit (20 features, no hierarchy)
❌ Walls of text (8+ line paragraphs)
❌ No empty states (blank when no data)
❌ No error states (silent failures)
❌ Modals for everything

✅ Real copy written first, design around it
✅ Top 3-5 features with benefits, not just features
✅ Short paragraphs (3-4 lines), subheadings every 2-3
✅ Designed empty states with guidance
✅ Clear error messages with recovery actions
✅ Modals only for focused tasks; many things can be inline
```

**DARK MODE**
```
❌ Just inverted colors or filter: invert(1)
❌ Pure black background (#000000)
❌ Same pure white text (#ffffff) as light mode

✅ Separate dark palette, designed not inverted
✅ Dark gray (#0a0a0b to #111), not pure black
✅ Slightly dimmed white (#fafafa) on dark backgrounds
```

**ACCESSIBILITY**
```
❌ Color-only meaning (red=error, green=success, nothing else)
❌ No alt text or alt="image"
❌ Animations without prefers-reduced-motion check

✅ Color + icon + text (never color alone)
✅ Descriptive alt text (or alt="" for decorative)
✅ @media (prefers-reduced-motion: reduce) { disable animations }
```

**TECHNICAL**
```
❌ Div soup instead of semantic HTML
❌ Inline styles
❌ !important everywhere
❌ z-index: 9999
❌ Console errors ignored
❌ Broken emoji encoding (ðŸ"¦ instead of 📦)
❌ Missing <meta charset="UTF-8">
❌ Absolute positioned elements overlapping content
❌ Copy buttons covering text they're supposed to copy
❌ Fixed-position elements without content awareness

✅ Semantic HTML (header, main, section, article, nav)
✅ CSS classes and design tokens
✅ Fix specificity properly, !important as last resort
✅ Defined z-index scale (Modal: 50, Dropdown: 40, etc.)
✅ Zero console errors or warnings
✅ Always <meta charset="UTF-8"> in <head>
✅ Use system emoji font stack or test emoji rendering
✅ Positioned elements account for variable content length
✅ Copy buttons: padding-right on container OR button below content
```

**COMMON AI LAYOUT BUGS**
```
❌ Absolute button overlaps text:
   .code-block { position: relative; }
   .copy-btn { position: absolute; top: 8px; right: 8px; }
   /* Text wraps under button! */

✅ Fix 1: Add padding to container
   .code-block { position: relative; padding-right: 80px; }
   .copy-btn { position: absolute; top: 8px; right: 8px; }

✅ Fix 2: Button below or beside content
   .code-block { display: flex; justify-content: space-between; }
   
✅ Fix 3: Button only visible on hover
   .copy-btn { opacity: 0; transition: opacity 0.2s; }
   .code-block:hover .copy-btn { opacity: 1; }

❌ Emoji mojibake (broken encoding):
   Cause: Missing charset OR copy-pasting from wrong encoding
   
✅ Fix: Always include in HTML <head>:
   <meta charset="UTF-8">
   
✅ Fix: Use emoji with fallback font stack:
   font-family: "Apple Color Emoji", "Segoe UI Emoji", "Noto Color Emoji", sans-serif;

✅ Fix: Or use text labels instead of emoji for critical UI
```

### Pick an Aesthetic Direction

| Direction | Characteristics | Best For |
|-----------|-----------------|----------|
| **Neo-Brutalist** | Raw, bold, intentional ugliness, thick borders | Creative agencies, portfolios |
| **Luxury Minimal** | Restrained palette, premium type, whisper animations | Fashion, finance, premium SaaS |
| **Editorial** | Strong type hierarchy, columns, magazine feel | Blogs, content sites, news |
| **Dark Atmospheric** | Deep shadows, gradients, cinematic | Dev tools, SaaS, portfolios |
| **Playful Geometric** | Bold shapes, bright colors, bouncy | Consumer apps, kids, social |
| **Organic/Natural** | Blobs, earth tones, flowing shapes | Wellness, eco, food |

## Design System Foundation

```css
:root {
  /* Colors - customize per project */
  --bg-primary: #0a0a0b;
  --bg-secondary: #141416;
  --bg-tertiary: #1c1c1f;
  --border: #27272a;
  --text-primary: #fafafa;
  --text-secondary: #a1a1aa;
  --text-muted: #71717a;
  --accent: #3b82f6;
  --accent-hover: #2563eb;
  
  /* Typography */
  --font-display: 'Cabinet Grotesk', sans-serif;
  --font-body: 'Inter', sans-serif;
  --font-mono: 'JetBrains Mono', monospace;
  
  /* Type Scale (fluid) */
  --text-xs: clamp(0.75rem, 0.7rem + 0.25vw, 0.875rem);
  --text-sm: clamp(0.875rem, 0.8rem + 0.375vw, 1rem);
  --text-base: clamp(1rem, 0.9rem + 0.5vw, 1.125rem);
  --text-lg: clamp(1.125rem, 1rem + 0.625vw, 1.25rem);
  --text-xl: clamp(1.25rem, 1rem + 1.25vw, 1.5rem);
  --text-2xl: clamp(1.5rem, 1.25rem + 1.25vw, 2rem);
  --text-3xl: clamp(2rem, 1.5rem + 2.5vw, 3rem);
  --text-4xl: clamp(2.5rem, 1.5rem + 5vw, 4rem);
  --text-hero: clamp(3rem, 1rem + 10vw, 7rem);
  
  /* Spacing */
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 0.75rem;
  --space-4: 1rem;
  --space-6: 1.5rem;
  --space-8: 2rem;
  --space-12: 3rem;
  --space-16: 4rem;
  --space-24: 6rem;
  
  /* Animation */
  --ease-out: cubic-bezier(0.16, 1, 0.3, 1);
  --ease-spring: cubic-bezier(0.34, 1.56, 0.64, 1);
  --duration-fast: 150ms;
  --duration-normal: 300ms;
  --duration-slow: 500ms;
}
```

## Icons & Visual Assets

**CRITICAL: Never use emoji or sparkle icons in professional UI.** They break encoding, render inconsistently, and look unprofessional.

### Professional Icon Libraries (Pick ONE and stick to it)

| Library | Style | Best For | CDN/Package |
|---------|-------|----------|-------------|
| **Lucide** | Clean, minimal | Modern apps, SaaS | `lucide-react` |
| **Heroicons** | Tailwind-native | Tailwind projects | `@heroicons/react` |
| **Phosphor** | Flexible weights | Customizable needs | `phosphor-react` |
| **Tabler** | 4000+ icons | Large icon needs | `@tabler/icons-react` |

### Lucide Icons (Recommended)
```tsx
// Install: npm install lucide-react
import { 
  Zap,           // For generation/speed (NOT Sparkles)
  ArrowRight,    // For actions
  RefreshCw,     // For regenerate
  Send,          // For submit
  Check,         // For success
  Plus,          // For create
  FileText,      // For content
  MessageSquare, // For chat
  Terminal,      // For code
  Play,          // For run/execute
} from 'lucide-react'

// NEVER import Sparkles - it is banned

// Usage - icons accept size, color, strokeWidth
<Zap size={24} className="text-accent" />
<ArrowRight size={20} strokeWidth={1.5} />

// With text - align properly
<span className="inline-flex items-center gap-2">
  <Check size={16} />
  Feature included
</span>

// Button with icon - use action-focused icons
<button className="inline-flex items-center gap-2">
  Get Started <ArrowRight size={16} />
</button>
```

### Icon Selection by Feature Type

```tsx
// FOR AI/GENERATION FEATURES - NEVER USE SPARKLES
<Zap />         // Speed/instant - PREFERRED for AI features
<ArrowRight />  // Action/generate
<Play />        // Execute/run
<Send />        // Submit
<RefreshCw />   // Regenerate
<Terminal />    // Code generation
<Cpu />         // Processing (subtle)

// FOR CONTENT CREATION
<Plus />        // Add/create
<FilePlus />    // New document
<PenLine />     // Edit/compose
<FileText />    // Content

// FOR FEEDBACK/STATUS
<Check />       // Success
<CheckCircle /> // Complete
<AlertCircle /> // Warning/error
<Loader2 />     // Loading (with animate-spin)
<Clock />       // Processing

// FOR NAVIGATION
<ArrowLeft />   // Back
<ArrowRight />  // Forward/next
<ChevronDown /> // Expand
<Menu />        // Mobile menu
<X />           // Close
```

### Animated Icons (Use Sparingly, Professionally)

**Animation should provide feedback, not decoration. Never animate icons to look "magical" or "AI-like".**

**Option 1: CSS Animated SVG (Recommended)**
```tsx
// Loading spinner - the only animation you really need
const LoadingIcon = () => (
  <Loader2 className="w-4 h-4 animate-spin" />
)

// Subtle hover scale - professional feedback
const InteractiveIcon = ({ children }) => (
  <span className="inline-block transition-transform hover:scale-110">
    {children}
  </span>
)

// Success check animation
const SuccessCheck = () => (
  <CheckCircle className="w-5 h-5 text-emerald-500 animate-in zoom-in duration-200" />
)

// DO NOT animate icons to:
// - Pulse continuously (looks AI-sloppy)
// - Shimmer or glow (looks cheap)
// - Bounce without user action (distracting)
// - Rotate continuously except loading spinners
```

**Option 2: Lottie Animations (Complex feedback only)**
```tsx
// Install: npm install lottie-react
import Lottie from 'lottie-react'
import successAnimation from './animations/success.json'

// USE ONLY FOR:
// - Success/completion confirmations
// - Error feedback
// - Onboarding moments
// - Empty states

// DO NOT USE FOR:
// - AI/generation features (no magic effects)
// - Buttons (keep them simple)
// - Decorative purposes

const SuccessIcon = () => (
  <Lottie 
    animationData={successAnimation}
    loop={false}  // Always false for feedback
    style={{ width: 64, height: 64 }}
  />
)
```

**Option 3: Simple CSS Animation on Lucide Icons**
```tsx
// Loading state - the most common need
const LoadingButton = ({ loading, children }) => (
  <button disabled={loading} className="flex items-center gap-2">
    {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : null}
    {children}
  </button>
)

// Subtle hover effect - professional feedback
const IconButton = ({ icon: Icon, label, onClick }) => (
  <button 
    onClick={onClick}
    className="group flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-muted transition-colors"
  >
    <Icon className="w-4 h-4 transition-transform group-hover:scale-110" />
    {label}
  </button>
)

// Success feedback
const SaveButton = ({ saved }) => (
  <button className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-lg">
    {saved ? (
      <Check className="w-4 h-4 animate-in zoom-in" />
    ) : (
      <Save className="w-4 h-4" />
    )}
    {saved ? 'Saved' : 'Save'}
  </button>
)
```

### SVG Resources (Free)

| Resource | Type | License |
|----------|------|---------|
| **svgrepo.com** | 500k+ vectors | Various (check each) |
| **heroicons.com** | 300+ icons | MIT |
| **lucide.dev** | 1400+ icons | ISC |
| **feathericons.com** | 280+ icons | MIT |
| **simpleicons.org** | Brand logos | CC0 |
| **undraw.co** | Illustrations | MIT |
| **humaaans.com** | People illustrations | Free |

### Inline SVG Best Practices
```tsx
// ✅ DO: Use as React components
import { ReactComponent as Logo } from './logo.svg'
<Logo className="h-8 w-auto" />

// ✅ DO: Inline for small icons (saves HTTP request)
const CheckIcon = () => (
  <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
    <path d="M13 4L6 11L3 8" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
  </svg>
)

// ❌ DON'T: Use <img> for icons (can't style with CSS)
<img src="/check.svg" /> // Bad - can't change color

// ✅ DO: Make icons inherit color
<svg fill="currentColor">  // Inherits text color
<svg stroke="currentColor"> // For stroke-based icons
```

### Icon Sizing Guidelines
```
Text size → Icon size (inline with text)
12px     → 14-16px
14px     → 16-18px  
16px     → 18-20px
18px     → 20-24px
24px     → 28-32px

Rule: Icons should feel the same "weight" as text
Tip: Icons often need to be slightly larger than text to appear balanced
```

### Creative/Fun Project Elements (Use With Extreme Caution)

**WARNING: Most "fun" visual elements quickly become AI slop. When in doubt, leave it out.**

**Confetti Effects (Celebrations Only)**
```tsx
// Install: npm install canvas-confetti
import confetti from 'canvas-confetti'

// USE ONLY FOR:
// - Major accomplishments (first project created, goal reached)
// - One-time celebrations
// - User-triggered celebrations

// DO NOT USE FOR:
// - Every form submission
// - AI generation completion
// - Page loads

const celebrateMilestone = () => {
  confetti({
    particleCount: 100,
    spread: 70,
    origin: { y: 0.6 }
  })
}

<button onClick={celebrateMilestone}>
  Complete Onboarding
</button>
```

**When to Use Fun Elements (Strict Criteria):**
- Landing pages for consumer/creative products ONLY
- Major success states (not every success)
- 404 pages (one place where playfulness is expected)
- Onboarding completion (once per user, ever)

**When NOT to Use (Most Cases):**
- B2B/enterprise products - NEVER
- Dashboard/admin interfaces - NEVER
- Forms and data entry - NEVER
- AI/generation features - NEVER (avoid "magic" associations)
- Documentation - NEVER
- Anywhere they slow down the experience - NEVER
- If you're unsure - DON'T USE THEM

## Typography That Stands Out

### Font Pairings
```css
/* Editorial */
--font-display: 'Playfair Display', serif;
--font-body: 'Source Sans 3', sans-serif;

/* Modern Tech */
--font-display: 'Space Grotesk', sans-serif;
--font-body: 'Inter', sans-serif;

/* Bold Creative */
--font-display: 'Clash Display', sans-serif;
--font-body: 'Satoshi', sans-serif;

/* Luxury */
--font-display: 'Cormorant Garamond', serif;
--font-body: 'Montserrat', sans-serif;
```

## Animation Library

### Core Animations
```css
@keyframes fadeUp {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes scaleIn {
  from { opacity: 0; transform: scale(0.95); }
  to { opacity: 1; transform: scale(1); }
}

@keyframes slideInLeft {
  from { opacity: 0; transform: translateX(-20px); }
  to { opacity: 1; transform: translateX(0); }
}

/* Usage */
.animate-fade-up {
  animation: fadeUp 0.6s var(--ease-out) forwards;
}
```

### Staggered Children
```css
.stagger > * {
  opacity: 0;
  animation: fadeUp 0.5s var(--ease-out) forwards;
}
.stagger > *:nth-child(1) { animation-delay: 0ms; }
.stagger > *:nth-child(2) { animation-delay: 75ms; }
.stagger > *:nth-child(3) { animation-delay: 150ms; }
.stagger > *:nth-child(4) { animation-delay: 225ms; }
.stagger > *:nth-child(5) { animation-delay: 300ms; }
```

### Micro-Interactions
```css
/* Button lift */
.btn {
  transition: transform var(--duration-fast) var(--ease-out),
              box-shadow var(--duration-fast) var(--ease-out);
}
.btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 20px rgba(59, 130, 246, 0.4);
}

/* Card hover */
.card {
  transition: transform var(--duration-normal) var(--ease-out),
              border-color var(--duration-normal) var(--ease-out);
}
.card:hover {
  transform: translateY(-4px);
  border-color: var(--accent);
}

/* Link underline */
.link::after {
  content: '';
  position: absolute;
  bottom: -2px;
  left: 0;
  width: 100%;
  height: 2px;
  background: var(--accent);
  transform: scaleX(0);
  transform-origin: right;
  transition: transform var(--duration-normal) var(--ease-out);
}
.link:hover::after {
  transform: scaleX(1);
  transform-origin: left;
}
```

## Button & Interactive States (CRITICAL)

**THE #1 AI SLOP PROBLEM:** Buttons and tabs with nearly identical active/inactive states. This is unacceptable. Every interactive element must have OBVIOUS, HIGH-CONTRAST state changes.

### State Contrast Rules
```
MINIMUM REQUIREMENTS:
- Active vs Inactive: Must be distinguishable at a glance
- Hover: Must be visibly different from default
- Disabled: Must look obviously disabled (not just slightly faded)
- Focus: Must have visible ring/outline for keyboard users

CONTRAST TARGETS:
- Active button: Filled with accent color OR strong border
- Inactive button: Transparent/ghost with subtle border
- The difference should be OBVIOUS, not subtle
```

### Button States Pattern (DO THIS)
```css
/* ✅ CORRECT: High contrast between states */

/* Default/Inactive - clearly muted */
.btn {
  background: transparent;
  color: var(--text-muted);
  border: 1px solid var(--border);
  padding: 0.625rem 1.25rem;
  border-radius: 8px;
  font-weight: 500;
  transition: all 0.2s ease;
}

/* Hover - noticeable change */
.btn:hover {
  background: var(--bg-secondary);
  border-color: var(--text-muted);
  color: var(--text);
}

/* Active/Selected - COMPLETELY DIFFERENT */
.btn.active,
.btn[aria-selected="true"] {
  background: var(--accent);
  color: white;
  border-color: var(--accent);
}

/* Active + Hover - still interactive */
.btn.active:hover {
  background: var(--accent-hover);
  border-color: var(--accent-hover);
}

/* Disabled - obviously unusable */
.btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
  pointer-events: none;
}

/* Focus - keyboard accessibility */
.btn:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
}
```

### Tab/Toggle Group Pattern
```css
/* Tab container */
.tabs {
  display: flex;
  gap: 0.5rem;
  padding: 0.25rem;
  background: var(--bg-secondary);
  border-radius: 10px;
}

/* Individual tab - inactive */
.tab {
  padding: 0.5rem 1rem;
  background: transparent;
  color: var(--text-muted);
  border: none;
  border-radius: 6px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
}

/* Tab hover */
.tab:hover:not(.active) {
  color: var(--text);
  background: rgba(255, 255, 255, 0.05);
}

/* Tab active - MUST BE OBVIOUS */
.tab.active {
  background: var(--accent);
  color: white;
  box-shadow: 0 2px 8px rgba(59, 130, 246, 0.3);
}
```

### ❌ NEVER DO THIS (The Screenshot Problem)
```css
/* BAD: Active and inactive are nearly identical */
.tab {
  background: #1c1c1f;
  color: #a1a1aa;
}
.tab.active {
  background: #2563eb;  /* Too similar in dark mode! */
  color: #a1a1aa;       /* Same muted color?! */
}

/* The problem: Both look like dark gray boxes */
```

### ✅ ALWAYS DO THIS
```css
/* GOOD: Active is unmistakably different */
.tab {
  background: transparent;
  color: var(--text-muted);
  border: 1px solid var(--border);
}
.tab.active {
  background: var(--accent);      /* Solid accent color */
  color: white;                   /* White text, not muted */
  border-color: var(--accent);    /* Border matches */
  font-weight: 600;               /* Extra weight for emphasis */
}
```

### Segmented Control Pattern
```tsx
// React component with proper states
function SegmentedControl({ options, value, onChange }) {
  return (
    <div className="flex bg-secondary/50 p-1 rounded-lg">
      {options.map((option) => (
        <button
          key={option.value}
          onClick={() => onChange(option.value)}
          className={cn(
            'px-4 py-2 rounded-md text-sm font-medium transition-all',
            value === option.value
              ? 'bg-accent text-white shadow-md'  // OBVIOUS active state
              : 'text-muted hover:text-foreground' // Clearly inactive
          )}
        >
          {option.label}
        </button>
      ))}
    </div>
  )
}
```

### Primary vs Secondary Buttons
```css
/* Primary - the main action */
.btn-primary {
  background: var(--accent);
  color: white;
  border: none;
  font-weight: 600;
}
.btn-primary:hover {
  background: var(--accent-hover);
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4);
}

/* Secondary - less important action */
.btn-secondary {
  background: transparent;
  color: var(--text);
  border: 1px solid var(--border);
}
.btn-secondary:hover {
  background: var(--bg-secondary);
  border-color: var(--accent);
}

/* Ghost - minimal emphasis */
.btn-ghost {
  background: transparent;
  color: var(--text-muted);
  border: none;
}
.btn-ghost:hover {
  background: rgba(255, 255, 255, 0.1);
  color: var(--text);
}

/* THE KEY: Each variant is VISUALLY DISTINCT */
```

### Interactive State Checklist
Before shipping ANY interactive element:
- [ ] Can you tell active from inactive at a glance?
- [ ] Is hover state visibly different from default?
- [ ] Does disabled look obviously disabled?
- [ ] Is there a focus ring for keyboard users?
- [ ] Would a colorblind user see the difference? (don't rely on color alone)
- [ ] Is there enough contrast between states?

---

## 🚨 CRITICAL: Dark Mode Button Failures

**THE PROBLEM:** On dark backgrounds, buttons become invisible or unreadable.

### ❌ NEVER DO THIS (Common AI Failures)

```tsx
// BROKEN: Dark text on dark background
<button className="bg-transparent text-gray-600 border-gray-700">
  Back  {/* INVISIBLE on dark mode */}
</button>

// BROKEN: Disabled looks same as enabled
<button className="bg-gray-800 text-gray-400" disabled>
  Back  {/* Can't tell it's disabled */}
</button>

// BROKEN: No border, no background = invisible
<button className="text-gray-500">
  Back  {/* Where's the button? */}
</button>

// BROKEN: Purple gradient (AI slop)
<button className="bg-gradient-to-r from-purple-500 to-blue-500">
  Generate  {/* Screams "AI made this" */}
</button>
```

### ✅ ALWAYS DO THIS (Dark Mode Buttons)

```tsx
// Button System for Dark UIs
const buttonVariants = {
  // PRIMARY: Main action - solid, high contrast
  primary: cn(
    "bg-blue-600 text-white font-medium",
    "hover:bg-blue-500",
    "active:bg-blue-700",
    "disabled:bg-blue-600/50 disabled:text-white/50"
  ),
  
  // SECONDARY: Supporting action - visible border
  secondary: cn(
    "bg-transparent text-gray-200 border border-gray-600",
    "hover:bg-gray-800 hover:border-gray-500",
    "active:bg-gray-700",
    "disabled:text-gray-600 disabled:border-gray-700"
  ),
  
  // GHOST: Minimal - but STILL VISIBLE
  ghost: cn(
    "bg-transparent text-gray-300",
    "hover:bg-gray-800 hover:text-white",
    "active:bg-gray-700",
    "disabled:text-gray-600"
  ),
  
  // OUTLINE: Clear boundaries
  outline: cn(
    "bg-transparent text-white border-2 border-white/20",
    "hover:border-white/40 hover:bg-white/5",
    "active:bg-white/10",
    "disabled:border-white/10 disabled:text-white/30"
  ),
}

// Usage
<button className={cn(
  "px-4 py-2 rounded-lg transition-all",
  "focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:ring-offset-gray-900",
  buttonVariants.primary
)}>
  Next
</button>

<button className={cn(
  "px-4 py-2 rounded-lg transition-all",
  "focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:ring-offset-gray-900",
  buttonVariants.secondary
)} disabled>
  Back
</button>
```

### Button Pair Pattern (Back/Next)

```tsx
// CORRECT: Back/Next buttons with proper contrast
function NavigationButtons({ 
  onBack, 
  onNext, 
  canGoBack = true,
  canGoNext = true 
}: Props) {
  return (
    <div className="flex items-center gap-2">
      {/* Back - secondary, but VISIBLE */}
      <button
        onClick={onBack}
        disabled={!canGoBack}
        className={cn(
          "flex items-center gap-2 px-4 py-2 rounded-lg transition-all",
          "focus:outline-none focus:ring-2 focus:ring-blue-500",
          canGoBack
            ? "bg-gray-800 text-gray-200 border border-gray-600 hover:bg-gray-700 hover:text-white"
            : "bg-gray-800/50 text-gray-600 border border-gray-700 cursor-not-allowed"
        )}
      >
        <ArrowLeft className="w-4 h-4" />
        Back
      </button>
      
      {/* Next - primary, stands out */}
      <button
        onClick={onNext}
        disabled={!canGoNext}
        className={cn(
          "flex items-center gap-2 px-4 py-2 rounded-lg transition-all",
          "focus:outline-none focus:ring-2 focus:ring-blue-500",
          canGoNext
            ? "bg-blue-600 text-white hover:bg-blue-500"
            : "bg-blue-600/50 text-white/50 cursor-not-allowed"
        )}
      >
        Next
        <ArrowRight className="w-4 h-4" />
      </button>
    </div>
  )
}
```

### Tab Button Group (Dark Mode)

```tsx
// CORRECT: Tabs with obvious active state
function TabGroup({ tabs, activeTab, onChange }: Props) {
  return (
    <div className="flex items-center gap-1 p-1 bg-gray-800/50 rounded-lg">
      {tabs.map(tab => (
        <button
          key={tab.id}
          onClick={() => onChange(tab.id)}
          className={cn(
            "flex items-center gap-2 px-3 py-1.5 rounded-md transition-all text-sm",
            activeTab === tab.id
              ? "bg-gray-700 text-white shadow-sm"  // ACTIVE: Filled background
              : "text-gray-400 hover:text-gray-200 hover:bg-gray-800" // INACTIVE: No fill
          )}
        >
          {tab.icon && <tab.icon className="w-4 h-4" />}
          {tab.label}
        </button>
      ))}
    </div>
  )
}
```

### Action Button (No Purple Gradients)

```tsx
// ❌ AI SLOP - ABSOLUTELY FORBIDDEN
<button className="bg-gradient-to-r from-purple-500 to-blue-500 text-white">
  ✨ Generate
</button>

// ✅ PROFESSIONAL
<button className={cn(
  "flex items-center gap-2 px-4 py-2 rounded-lg",
  "bg-emerald-600 text-white font-medium",
  "hover:bg-emerald-500",
  "active:bg-emerald-700",
  "transition-colors"
)}>
  <Zap className="w-4 h-4" />
  Generate
</button>

// ✅ ALTERNATIVE: Subtle accent
<button className={cn(
  "flex items-center gap-2 px-4 py-2 rounded-lg",
  "bg-blue-600/20 text-blue-400 border border-blue-500/30",
  "hover:bg-blue-600/30 hover:border-blue-500/50",
  "transition-colors"
)}>
  <ArrowRight className="w-4 h-4" />
  Generate
</button>
```

---

## 🚨 CRITICAL: Chat Bubble Text Overflow

**THE PROBLEM:** Chat messages overflow their containers and cover other content.

### ❌ NEVER DO THIS

```tsx
// BROKEN: No width constraints
<div className="bg-blue-600 text-white p-3 rounded-lg">
  {message}  {/* Will expand forever */}
</div>

// BROKEN: Fixed width without overflow handling
<div className="w-64 bg-blue-600 text-white p-3 rounded-lg">
  {longMessage}  {/* Text escapes the bubble */}
</div>
```

### ✅ ALWAYS DO THIS

```tsx
// Chat container with proper constraints
function ChatBubble({ message, isUser }: { message: string; isUser: boolean }) {
  return (
    <div className={cn(
      "flex",
      isUser ? "justify-end" : "justify-start"
    )}>
      <div className={cn(
        // MAX WIDTH is critical
        "max-w-[80%] sm:max-w-[70%]",
        // Padding and shape
        "px-4 py-2 rounded-2xl",
        // Word breaking for long words/URLs
        "break-words",
        // Overflow handling
        "overflow-hidden",
        // Colors
        isUser 
          ? "bg-blue-600 text-white rounded-br-md" 
          : "bg-gray-800 text-gray-100 rounded-bl-md"
      )}>
        {/* Whitespace handling */}
        <p className="whitespace-pre-wrap break-words">
          {message}
        </p>
      </div>
    </div>
  )
}
```

### Chat Message List (Proper Containment)

```tsx
function ChatMessages({ messages }: { messages: Message[] }) {
  return (
    // Container with scroll and padding
    <div className="flex-1 overflow-y-auto p-4 space-y-3 min-h-0">
      {messages.map(msg => (
        <div
          key={msg.id}
          className={cn(
            "flex",
            msg.role === 'user' ? "justify-end" : "justify-start"
          )}
        >
          {/* CRITICAL: max-w constraint on the bubble container */}
          <div className={cn(
            "max-w-[85%]", // Never full width
            "min-w-0",      // Allow shrinking
          )}>
            <div className={cn(
              "px-4 py-2 rounded-2xl",
              "break-words overflow-hidden", // Prevent text escape
              msg.role === 'user'
                ? "bg-blue-600 text-white"
                : "bg-gray-800 text-gray-100"
            )}>
              <p className="whitespace-pre-wrap break-words text-sm">
                {msg.content}
              </p>
            </div>
          </div>
        </div>
      ))}
    </div>
  )
}
```

### AI Assistant Card (Right Panel)

```tsx
// For fixed-width assistant panels
function AssistantPanel() {
  return (
    // Fixed width panel
    <aside className="w-80 shrink-0 border-l border-gray-800 flex flex-col overflow-hidden">
      {/* Header */}
      <div className="p-4 border-b border-gray-800 shrink-0">
        <h2 className="font-semibold">AI Assistant</h2>
      </div>
      
      {/* Messages - scrollable */}
      <div className="flex-1 overflow-y-auto p-4 space-y-3 min-h-0">
        {messages.map(msg => (
          <div key={msg.id} className={cn(
            // CRITICAL: Constrain to panel width
            "max-w-full",
            "min-w-0", // Allow text to wrap
          )}>
            <div className={cn(
              "px-3 py-2 rounded-lg text-sm",
              "break-words overflow-hidden", // NEVER let text escape
              "bg-gray-800 text-gray-200"
            )}>
              {msg.content}
            </div>
          </div>
        ))}
      </div>
      
      {/* Input - fixed at bottom */}
      <div className="p-4 border-t border-gray-800 shrink-0">
        <input 
          type="text" 
          placeholder="Ask something..."
          className="w-full px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-sm"
        />
      </div>
    </aside>
  )
}
```

### Text Overflow Quick Reference

```
┌────────────────────────────────────────────────────────────────┐
│ TEXT CONTAINMENT CHECKLIST                                      │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│ For ANY text container:                                         │
│ ✓ max-w-[X] or max-w-full  — Set maximum width                 │
│ ✓ min-w-0                  — Allow shrinking in flex           │
│ ✓ break-words              — Break long words                  │
│ ✓ overflow-hidden          — Clip if all else fails            │
│                                                                 │
│ For chat bubbles specifically:                                  │
│ ✓ max-w-[80%]              — Never full width                  │
│ ✓ whitespace-pre-wrap      — Preserve line breaks              │
│ ✓ break-words              — Handle long URLs/words            │
│                                                                 │
│ For panels with text:                                           │
│ ✓ overflow-hidden on container                                  │
│ ✓ min-w-0 on flex children                                      │
│ ✓ truncate OR line-clamp-N for titles                          │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

---

### Scroll Animations (Intersection Observer)
```typescript
// hooks/useScrollReveal.ts
import { useEffect, useRef } from 'react'

export function useScrollReveal() {
  const ref = useRef<HTMLElement>(null)
  
  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add('revealed')
            observer.unobserve(entry.target)
          }
        })
      },
      { threshold: 0.1, rootMargin: '0px 0px -50px 0px' }
    )
    
    if (ref.current) observer.observe(ref.current)
    return () => observer.disconnect()
  }, [])
  
  return ref
}

// CSS
.scroll-reveal {
  opacity: 0;
  transform: translateY(30px);
  transition: opacity 0.6s var(--ease-out), transform 0.6s var(--ease-out);
}
.scroll-reveal.revealed {
  opacity: 1;
  transform: translateY(0);
}
```

---

# Copywriting & SEO

## Headline Formulas

### Problem-Agitation
```
"Tired of [pain point]?"
"Stop [frustrating action]. Start [desired outcome]."
"[Pain point] is costing you [consequence]"
```

### Value-First
```
"[Outcome] in [timeframe]"
"The [adjective] way to [desired action]"
"[Number]x faster [action] with [product]"
```

### Social Proof
```
"Join [number]+ [audience] who [benefit]"
"Trusted by [impressive names/numbers]"
"The #1 [category] for [audience]"
```

### How-To / Educational
```
"How to [achieve outcome] without [common obstacle]"
"The complete guide to [topic]"
"[Number] ways to [improve something]"
```

## CTA Best Practices

### Button Copy (Specific > Generic)
```
❌ "Submit" → ✅ "Get My Free Guide"
❌ "Sign Up" → ✅ "Start Free Trial"
❌ "Learn More" → ✅ "See How It Works"
❌ "Buy Now" → ✅ "Get Instant Access"
❌ "Contact" → ✅ "Schedule a Call"
```

### CTA Formula
```
[Action Verb] + [Benefit/Object] + [Urgency if applicable]

Examples:
- "Start saving 10 hours/week"
- "Get your free strategy session"
- "Claim your spot (12 left)"
- "Download the checklist"
```

## Page Structure for SEO

### Landing Page Blueprint
```
1. HERO
   - H1: Primary keyword + value prop (50-60 chars)
   - Subhead: Expand on benefit, add credibility
   - CTA: Primary action
   - Trust: Social proof snippet

2. PROBLEM
   - Agitate the pain point
   - Show you understand
   - 2-3 specific problems

3. SOLUTION
   - Introduce your product/service
   - Key benefits (3-5)
   - How it works (3 steps)

4. SOCIAL PROOF
   - Testimonials with specifics
   - Logos
   - Numbers/stats

5. FEATURES/BENEFITS
   - Feature → Benefit pairs
   - Visual demos

6. OBJECTION HANDLING
   - FAQ section
   - Guarantee/risk reversal

7. FINAL CTA
   - Restate value prop
   - Clear call to action
   - Urgency if appropriate
```

### Meta Tags Template
```tsx
// app/layout.tsx or page-specific
export const metadata: Metadata = {
  title: 'Primary Keyword - Secondary Keyword | Brand',  // 50-60 chars
  description: 'Benefit-focused description with primary keyword. Include call to action.', // 150-160 chars
  keywords: ['keyword1', 'keyword2', 'keyword3'],
  openGraph: {
    title: 'Compelling title for social sharing',
    description: 'Description optimized for social clicks',
    images: ['/og-image.png'],  // 1200x630px
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Title for Twitter',
    description: 'Description for Twitter',
    images: ['/twitter-image.png'],
  },
}
```

### Heading Hierarchy
```
H1: One per page, primary keyword (page title)
H2: Major sections, secondary keywords
H3: Subsections within H2s
H4: Supporting points (use sparingly)

Rule: Never skip levels (H1 → H3)
```

## Responsive Design

### Mobile-First Breakpoints
```css
/* Base: Mobile */
.container { padding: 1rem; }

/* Tablet */
@media (min-width: 768px) {
  .container { padding: 2rem; }
}

/* Desktop */
@media (min-width: 1024px) {
  .container { 
    padding: 4rem; 
    max-width: 1200px;
    margin: 0 auto;
  }
}
```

### Responsive Grid
```css
.grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--space-6);
}

@media (min-width: 768px) {
  .grid { grid-template-columns: repeat(2, 1fr); }
}

@media (min-width: 1024px) {
  .grid { grid-template-columns: repeat(3, 1fr); }
}

/* Or auto-fit */
.grid-auto {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(300px, 100%), 1fr));
  gap: var(--space-6);
}
```

## Accessibility Essentials

**WCAG 2.1 AA is the standard.** Build it in from the start, not as an afterthought.

### CSS Foundations
```css
/* Visible focus states */
:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
}

/* Respect motion preferences */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}

/* Screen reader only */
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  border: 0;
}
```

### ARIA Patterns for Every Interactive Element

```tsx
// BUTTONS - Always include aria-label when icon-only
<button
  aria-label="Close dialog"
  aria-pressed={isToggled}         // For toggle buttons
  disabled={isLoading}
>
  <XIcon />
</button>

// EXPANDABLE CONTENT
<button
  aria-expanded={isOpen}
  aria-controls="panel-content"
>
  Show Details
</button>
<div id="panel-content" hidden={!isOpen}>
  Content here
</div>

// LOADING STATES - Announce to screen readers
<div aria-live="polite" aria-busy={isLoading}>
  {isLoading ? <Spinner /> : <Content />}
</div>

// ERRORS - Announce immediately
<div role="alert" aria-live="assertive">
  {error && <span className="text-red-500">{error}</span>}
</div>

// FORMS - Always associate labels
<div>
  <label htmlFor="email">Email</label>
  <input 
    id="email"
    type="email"
    aria-describedby="email-help email-error"
    aria-invalid={!!error}
  />
  <span id="email-help" className="text-zinc-400">We'll never share your email</span>
  {error && <span id="email-error" className="text-red-500">{error}</span>}
</div>

// MODALS - Trap focus, announce
<dialog
  aria-modal="true"
  aria-labelledby="modal-title"
>
  <h2 id="modal-title">Confirm Action</h2>
  {/* Focus trap here */}
</dialog>
```

### Keyboard Navigation

```tsx
// Hook for keyboard navigation
function useKeyboardNavigation(items: string[], onSelect: (item: string) => void) {
  const [activeIndex, setActiveIndex] = useState(0)
  
  const handleKeyDown = (e: KeyboardEvent) => {
    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault()
        setActiveIndex(i => Math.min(i + 1, items.length - 1))
        break
      case 'ArrowUp':
        e.preventDefault()
        setActiveIndex(i => Math.max(i - 1, 0))
        break
      case 'Enter':
      case ' ':
        e.preventDefault()
        onSelect(items[activeIndex])
        break
      case 'Escape':
        // Close/cancel
        break
    }
  }
  
  return { activeIndex, handleKeyDown }
}

// Focus trap for modals
function useFocusTrap(ref: RefObject<HTMLElement>) {
  useEffect(() => {
    const element = ref.current
    if (!element) return
    
    const focusableElements = element.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    )
    const firstElement = focusableElements[0] as HTMLElement
    const lastElement = focusableElements[focusableElements.length - 1] as HTMLElement
    
    firstElement?.focus()
    
    const handleTab = (e: KeyboardEvent) => {
      if (e.key !== 'Tab') return
      
      if (e.shiftKey && document.activeElement === firstElement) {
        e.preventDefault()
        lastElement?.focus()
      } else if (!e.shiftKey && document.activeElement === lastElement) {
        e.preventDefault()
        firstElement?.focus()
      }
    }
    
    element.addEventListener('keydown', handleTab)
    return () => element.removeEventListener('keydown', handleTab)
  }, [ref])
}
```

### Color Contrast Requirements

```
Text on background:
- Normal text (< 24px): 4.5:1 minimum
- Large text (≥ 24px or 18.5px bold): 3:1 minimum
- UI components & graphics: 3:1 minimum

Common passing combinations:
- White (#fff) on blue (#2563eb): ✓ 4.5:1
- White (#fff) on zinc-800 (#27272a): ✓ 12.6:1
- Zinc-400 (#a1a1aa) on zinc-900 (#18181b): ✓ 5.5:1

Common FAILING combinations:
- Zinc-500 (#71717a) on zinc-800 (#27272a): ✗ 2.8:1
- Red-500 (#ef4444) on zinc-900 (#18181b): ✗ 4.0:1
```

### Screen Reader Announcements

```tsx
// Hook for dynamic announcements
function useAnnounce() {
  const announce = (message: string, priority: 'polite' | 'assertive' = 'polite') => {
    const el = document.createElement('div')
    el.setAttribute('aria-live', priority)
    el.setAttribute('aria-atomic', 'true')
    el.className = 'sr-only'
    document.body.appendChild(el)
    
    // Delay to ensure screen readers catch it
    setTimeout(() => {
      el.textContent = message
      setTimeout(() => el.remove(), 1000)
    }, 100)
  }
  
  return announce
}

// Usage
const announce = useAnnounce()

const handleSave = async () => {
  await save()
  announce('Changes saved successfully')
}

const handleError = (error: string) => {
  announce(error, 'assertive')
}
```

## Network & Offline States

```tsx
// Hook for network status
function useNetworkStatus() {
  const [isOnline, setIsOnline] = useState(
    typeof navigator !== 'undefined' ? navigator.onLine : true
  )

  useEffect(() => {
    const handleOnline = () => setIsOnline(true)
    const handleOffline = () => setIsOnline(false)

    window.addEventListener('online', handleOnline)
    window.addEventListener('offline', handleOffline)

    return () => {
      window.removeEventListener('online', handleOnline)
      window.removeEventListener('offline', handleOffline)
    }
  }, [])

  return isOnline
}

// Offline banner component
function OfflineBanner() {
  const isOnline = useNetworkStatus()
  
  if (isOnline) return null
  
  return (
    <div 
      role="alert"
      className="fixed top-0 left-0 right-0 bg-yellow-500/10 border-b border-yellow-500/20 
                 px-4 py-2 text-center text-yellow-200 text-sm z-50"
    >
      You're offline. Some features may not work until you reconnect.
    </div>
  )
}

// Queue actions for when back online
function useOfflineQueue() {
  const [queue, setQueue] = useState<(() => Promise<void>)[]>([])
  const isOnline = useNetworkStatus()
  
  useEffect(() => {
    if (isOnline && queue.length > 0) {
      // Process queue
      Promise.all(queue.map(fn => fn()))
        .then(() => setQueue([]))
        .catch(console.error)
    }
  }, [isOnline, queue])
  
  const enqueue = (action: () => Promise<void>) => {
    if (isOnline) {
      action()
    } else {
      setQueue(q => [...q, action])
    }
  }
  
  return { enqueue, pendingCount: queue.length }
}
```

## Optimistic UI with Rollback

```tsx
function useOptimistic<T extends { id: string }>(
  initialItems: T[],
  saveItem: (item: T) => Promise<T>
) {
  const [items, setItems] = useState(initialItems)
  
  const addOptimistic = async (item: Omit<T, 'id'>) => {
    const tempId = `temp-${crypto.randomUUID()}`
    const tempItem = { ...item, id: tempId } as T
    
    // Optimistically add
    setItems(prev => [...prev, tempItem])
    
    try {
      const saved = await saveItem(tempItem)
      // Replace temp with real
      setItems(prev => prev.map(i => i.id === tempId ? saved : i))
      return saved
    } catch (error) {
      // ROLLBACK - remove temp item
      setItems(prev => prev.filter(i => i.id !== tempId))
      throw error
    }
  }
  
  const updateOptimistic = async (id: string, updates: Partial<T>) => {
    const original = items.find(i => i.id === id)
    if (!original) return
    
    // Optimistically update
    setItems(prev => prev.map(i => i.id === id ? { ...i, ...updates } : i))
    
    try {
      const saved = await saveItem({ ...original, ...updates })
      setItems(prev => prev.map(i => i.id === id ? saved : i))
      return saved
    } catch (error) {
      // ROLLBACK - restore original
      setItems(prev => prev.map(i => i.id === id ? original : i))
      throw error
    }
  }
  
  const deleteOptimistic = async (id: string, deleteFn: (id: string) => Promise<void>) => {
    const original = items.find(i => i.id === id)
    if (!original) return
    
    // Optimistically remove
    setItems(prev => prev.filter(i => i.id !== id))
    
    try {
      await deleteFn(id)
    } catch (error) {
      // ROLLBACK - restore item
      setItems(prev => [...prev, original])
      throw error
    }
  }
  
  return { items, addOptimistic, updateOptimistic, deleteOptimistic }
}
```

## Form Dirty State Warning

```tsx
function useUnsavedChangesWarning(isDirty: boolean) {
  useEffect(() => {
    const handleBeforeUnload = (e: BeforeUnloadEvent) => {
      if (isDirty) {
        e.preventDefault()
        e.returnValue = '' // Required for Chrome
      }
    }
    
    window.addEventListener('beforeunload', handleBeforeUnload)
    return () => window.removeEventListener('beforeunload', handleBeforeUnload)
  }, [isDirty])
}

// Usage in form
function EditForm() {
  const { formState: { isDirty } } = useForm()
  
  useUnsavedChangesWarning(isDirty)
  
  return (
    <form>
      {/* form fields */}
    </form>
  )
}
```

## Performance Checklist

- [ ] Images in WebP/AVIF with fallbacks
- [ ] Lazy loading on below-fold images
- [ ] Font-display: swap on custom fonts
- [ ] Critical CSS inlined
- [ ] JavaScript code-split by route
- [ ] LCP < 2.5s, CLS < 0.1

## Component Patterns

### Button
```tsx
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost' | 'destructive'
  size?: 'sm' | 'md' | 'lg'
  isLoading?: boolean
  children: React.ReactNode
}

const Button = ({ 
  variant = 'primary', 
  size = 'md', 
  isLoading = false,
  disabled,
  children, 
  ...props 
}: ButtonProps) => (
  <button
    disabled={isLoading || disabled}
    aria-busy={isLoading}
    className={cn(
      'inline-flex items-center justify-center gap-2 font-medium transition-all rounded-lg',
      'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent focus-visible:ring-offset-2',
      'disabled:opacity-50 disabled:cursor-not-allowed',
      {
        'bg-accent text-white hover:bg-accent-hover': variant === 'primary',
        'bg-secondary text-foreground hover:bg-secondary-hover': variant === 'secondary',
        'bg-transparent border border-border hover:bg-secondary': variant === 'ghost',
        'bg-red-600 text-white hover:bg-red-500': variant === 'destructive',
      },
      {
        'h-9 px-4 text-sm': size === 'sm',
        'h-11 px-6': size === 'md',
        'h-13 px-8 text-lg': size === 'lg',
      }
    )}
    {...props}
  >
    {isLoading && (
      <svg 
        className="animate-spin h-4 w-4" 
        viewBox="0 0 24 24"
        aria-hidden="true"
      >
        <circle 
          className="opacity-25" 
          cx="12" cy="12" r="10" 
          stroke="currentColor" 
          strokeWidth="4" 
          fill="none" 
        />
        <path 
          className="opacity-75" 
          fill="currentColor" 
          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" 
        />
      </svg>
    )}
    {isLoading ? 'Loading...' : children}
  </button>
)

// Usage
<Button isLoading={isSaving}>Save Changes</Button>
<Button variant="destructive" onClick={handleDelete}>Delete</Button>
```

### Confirm Button (For Destructive Actions)
```tsx
function ConfirmButton({ 
  onConfirm, 
  children,
  confirmText = 'Are you sure?',
  ...props 
}: { 
  onConfirm: () => void
  children: React.ReactNode
  confirmText?: string
} & Omit<ButtonProps, 'onClick'>) {
  const [isConfirming, setIsConfirming] = useState(false)
  
  const handleClick = () => {
    if (isConfirming) {
      onConfirm()
      setIsConfirming(false)
    } else {
      setIsConfirming(true)
      // Reset after 3 seconds
      setTimeout(() => setIsConfirming(false), 3000)
    }
  }
  
  return (
    <Button
      {...props}
      variant={isConfirming ? 'destructive' : props.variant}
      onClick={handleClick}
    >
      {isConfirming ? confirmText : children}
    </Button>
  )
}

// Usage - requires two clicks to delete
<ConfirmButton onConfirm={handleDelete} variant="ghost">
  Delete Account
</ConfirmButton>
```

### Card
```tsx
const Card = ({ children, className, ...props }) => (
  <div
    className={cn(
      'bg-secondary border border-border rounded-xl p-6',
      'transition-all duration-300',
      'hover:border-accent hover:-translate-y-1',
      className
    )}
    {...props}
  >
    {children}
  </div>
)
```

### Input
```tsx
const Input = ({ label, error, ...props }) => (
  <div className="space-y-2">
    {label && <label className="text-sm font-medium">{label}</label>}
    <input
      className={cn(
        'w-full px-4 py-3 bg-secondary border rounded-lg',
        'focus:outline-none focus:ring-2 focus:ring-accent focus:border-transparent',
        'placeholder:text-muted',
        error ? 'border-red-500' : 'border-border'
      )}
      {...props}
    />
    {error && <p className="text-sm text-red-500">{error}</p>}
  </div>
)
```

---

# Forms

## React Hook Form + Zod Pattern
```tsx
// Install: npm install react-hook-form @hookform/resolvers zod

import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Loader2 } from 'lucide-react'

const schema = z.object({
  email: z.string().email('Invalid email'),
  password: z.string().min(8, 'Password must be 8+ characters'),
  name: z.string().min(2, 'Name is required'),
})

type FormData = z.infer<typeof schema>

export function SignupForm() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
    setError,
  } = useForm<FormData>({
    resolver: zodResolver(schema),
  })

  const onSubmit = async (data: FormData) => {
    try {
      const res = await fetch('/api/signup', {
        method: 'POST',
        body: JSON.stringify(data),
      })
      
      if (!res.ok) {
        const { error } = await res.json()
        setError('root', { message: error })
        return
      }
      
      // Success
    } catch (err) {
      setError('root', { message: 'Something went wrong' })
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <div>
        <label className="block text-sm font-medium mb-1.5">Name</label>
        <input
          {...register('name')}
          className="w-full px-4 py-2.5 bg-zinc-900 border border-zinc-800 rounded-lg text-white focus:ring-2 focus:ring-blue-500"
        />
        {errors.name && (
          <p className="text-sm text-red-400 mt-1">{errors.name.message}</p>
        )}
      </div>

      <div>
        <label className="block text-sm font-medium mb-1.5">Email</label>
        <input
          {...register('email')}
          type="email"
          className="w-full px-4 py-2.5 bg-zinc-900 border border-zinc-800 rounded-lg text-white focus:ring-2 focus:ring-blue-500"
        />
        {errors.email && (
          <p className="text-sm text-red-400 mt-1">{errors.email.message}</p>
        )}
      </div>

      <div>
        <label className="block text-sm font-medium mb-1.5">Password</label>
        <input
          {...register('password')}
          type="password"
          className="w-full px-4 py-2.5 bg-zinc-900 border border-zinc-800 rounded-lg text-white focus:ring-2 focus:ring-blue-500"
        />
        {errors.password && (
          <p className="text-sm text-red-400 mt-1">{errors.password.message}</p>
        )}
      </div>

      {errors.root && (
        <div className="p-3 bg-red-500/10 border border-red-500/20 rounded-lg">
          <p className="text-sm text-red-400">{errors.root.message}</p>
        </div>
      )}

      <button
        type="submit"
        disabled={isSubmitting}
        className="w-full py-2.5 bg-blue-600 hover:bg-blue-500 disabled:bg-blue-600/50 text-white font-medium rounded-lg flex items-center justify-center gap-2"
      >
        {isSubmitting ? <Loader2 className="w-4 h-4 animate-spin" /> : 'Sign Up'}
      </button>
    </form>
  )
}
```

## Form Field Component
```tsx
interface FieldProps {
  label: string
  error?: string
  children: React.ReactNode
}

function Field({ label, error, children }: FieldProps) {
  return (
    <div className="space-y-1.5">
      <label className="block text-sm font-medium text-zinc-300">{label}</label>
      {children}
      {error && <p className="text-sm text-red-400">{error}</p>}
    </div>
  )
}
```

---

# Data Fetching

## SWR Pattern (Recommended)
```tsx
// Install: npm install swr

import useSWR from 'swr'

const fetcher = (url: string) => fetch(url).then((res) => res.json())

export function useProjects() {
  const { data, error, isLoading, mutate } = useSWR('/api/projects', fetcher)

  return {
    projects: data?.data ?? [],
    isLoading,
    isError: !!error,
    refresh: mutate,
  }
}

// Usage
function ProjectList() {
  const { projects, isLoading, isError } = useProjects()

  if (isLoading) return <ProjectsSkeleton />
  if (isError) return <ErrorState />
  if (projects.length === 0) return <EmptyState />

  return projects.map((p) => <ProjectCard key={p.id} project={p} />)
}
```

## TanStack Query Pattern
```tsx
// Install: npm install @tanstack/react-query

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'

export function useProjects() {
  return useQuery({
    queryKey: ['projects'],
    queryFn: async () => {
      const res = await fetch('/api/projects')
      if (!res.ok) throw new Error('Failed to fetch')
      return res.json()
    },
  })
}

export function useCreateProject() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (data: CreateProjectData) => {
      const res = await fetch('/api/projects', {
        method: 'POST',
        body: JSON.stringify(data),
      })
      if (!res.ok) throw new Error('Failed to create')
      return res.json()
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['projects'] })
    },
  })
}
```

## Optimistic Updates
```tsx
const queryClient = useQueryClient()

const mutation = useMutation({
  mutationFn: updateProject,
  onMutate: async (newData) => {
    await queryClient.cancelQueries({ queryKey: ['projects'] })
    const previous = queryClient.getQueryData(['projects'])
    
    queryClient.setQueryData(['projects'], (old) =>
      old.map((p) => (p.id === newData.id ? { ...p, ...newData } : p))
    )
    
    return { previous }
  },
  onError: (err, newData, context) => {
    queryClient.setQueryData(['projects'], context.previous)
  },
  onSettled: () => {
    queryClient.invalidateQueries({ queryKey: ['projects'] })
  },
})
```

---

# Modal/Dialog

## Accessible Modal Component
```tsx
// Install: npm install @radix-ui/react-dialog

import * as Dialog from '@radix-ui/react-dialog'
import { X } from 'lucide-react'

interface ModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  title: string
  description?: string
  children: React.ReactNode
}

export function Modal({ open, onOpenChange, title, description, children }: ModalProps) {
  return (
    <Dialog.Root open={open} onOpenChange={onOpenChange}>
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 bg-black/60 backdrop-blur-sm animate-in fade-in" />
        <Dialog.Content className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-md bg-zinc-900 border border-zinc-800 rounded-xl p-6 shadow-xl animate-in fade-in zoom-in-95">
          <div className="flex items-center justify-between mb-4">
            <Dialog.Title className="text-xl font-semibold text-white">
              {title}
            </Dialog.Title>
            <Dialog.Close className="p-1 rounded-lg hover:bg-zinc-800 transition-colors">
              <X className="w-5 h-5 text-zinc-400" />
            </Dialog.Close>
          </div>
          
          {description && (
            <Dialog.Description className="text-zinc-400 mb-4">
              {description}
            </Dialog.Description>
          )}
          
          {children}
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  )
}

// Usage
function Example() {
  const [open, setOpen] = useState(false)

  return (
    <>
      <button onClick={() => setOpen(true)}>Open Modal</button>
      <Modal
        open={open}
        onOpenChange={setOpen}
        title="Create Project"
        description="Add a new project to your workspace."
      >
        <form className="space-y-4">
          {/* Form fields */}
          <div className="flex gap-3 justify-end">
            <button type="button" onClick={() => setOpen(false)} className="px-4 py-2 text-zinc-400">
              Cancel
            </button>
            <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded-lg">
              Create
            </button>
          </div>
        </form>
      </Modal>
    </>
  )
}
```

## Confirm Dialog
```tsx
interface ConfirmDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  title: string
  description: string
  confirmText?: string
  onConfirm: () => void
  destructive?: boolean
}

export function ConfirmDialog({
  open,
  onOpenChange,
  title,
  description,
  confirmText = 'Confirm',
  onConfirm,
  destructive = false,
}: ConfirmDialogProps) {
  return (
    <Modal open={open} onOpenChange={onOpenChange} title={title} description={description}>
      <div className="flex gap-3 justify-end mt-6">
        <button
          onClick={() => onOpenChange(false)}
          className="px-4 py-2 text-zinc-400 hover:text-white transition-colors"
        >
          Cancel
        </button>
        <button
          onClick={() => {
            onConfirm()
            onOpenChange(false)
          }}
          className={`px-4 py-2 rounded-lg font-medium ${
            destructive
              ? 'bg-red-600 hover:bg-red-500 text-white'
              : 'bg-blue-600 hover:bg-blue-500 text-white'
          }`}
        >
          {confirmText}
        </button>
      </div>
    </Modal>
  )
}
```

---

# Toast Notifications

## Toast Context + Component
```tsx
'use client'
import { createContext, useContext, useState, useCallback } from 'react'
import { Check, X, AlertTriangle, Info } from 'lucide-react'

type ToastType = 'success' | 'error' | 'warning' | 'info'

interface Toast {
  id: string
  type: ToastType
  message: string
}

const ToastContext = createContext<{
  toast: (type: ToastType, message: string) => void
} | null>(null)

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([])

  const toast = useCallback((type: ToastType, message: string) => {
    const id = Math.random().toString(36).slice(2)
    setToasts((prev) => [...prev, { id, type, message }])
    
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id))
    }, 4000)
  }, [])

  const dismiss = (id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id))
  }

  return (
    <ToastContext.Provider value={{ toast }}>
      {children}
      <div className="fixed bottom-4 right-4 z-50 flex flex-col gap-2">
        {toasts.map((t) => (
          <ToastItem key={t.id} toast={t} onDismiss={() => dismiss(t.id)} />
        ))}
      </div>
    </ToastContext.Provider>
  )
}

function ToastItem({ toast, onDismiss }: { toast: Toast; onDismiss: () => void }) {
  const icons = {
    success: <Check className="w-5 h-5 text-green-400" />,
    error: <X className="w-5 h-5 text-red-400" />,
    warning: <AlertTriangle className="w-5 h-5 text-yellow-400" />,
    info: <Info className="w-5 h-5 text-blue-400" />,
  }

  const backgrounds = {
    success: 'bg-green-500/10 border-green-500/20',
    error: 'bg-red-500/10 border-red-500/20',
    warning: 'bg-yellow-500/10 border-yellow-500/20',
    info: 'bg-blue-500/10 border-blue-500/20',
  }

  return (
    <div
      className={`flex items-center gap-3 px-4 py-3 rounded-lg border ${backgrounds[toast.type]} animate-in slide-in-from-right`}
    >
      {icons[toast.type]}
      <span className="text-white">{toast.message}</span>
      <button onClick={onDismiss} className="ml-2 text-zinc-400 hover:text-white">
        <X className="w-4 h-4" />
      </button>
    </div>
  )
}

export function useToast() {
  const context = useContext(ToastContext)
  if (!context) throw new Error('useToast must be used within ToastProvider')
  return context
}

// Usage
function Example() {
  const { toast } = useToast()

  const handleSave = async () => {
    try {
      await save()
      toast('success', 'Changes saved!')
    } catch {
      toast('error', 'Failed to save changes')
    }
  }
}
```

---

# Skeleton Loaders

## Skeleton Component
```tsx
function Skeleton({ className }: { className?: string }) {
  return (
    <div
      className={cn(
        'bg-zinc-800 rounded animate-pulse',
        className
      )}
    />
  )
}

// Text skeleton
<Skeleton className="h-4 w-3/4" />

// Avatar skeleton
<Skeleton className="h-10 w-10 rounded-full" />

// Card skeleton
<Skeleton className="h-32 w-full rounded-xl" />
```

## List Skeleton
```tsx
function ProjectListSkeleton() {
  return (
    <div className="space-y-4">
      {Array.from({ length: 5 }).map((_, i) => (
        <div key={i} className="bg-zinc-900 border border-zinc-800 rounded-xl p-6">
          <div className="flex items-center gap-4">
            <Skeleton className="h-12 w-12 rounded-lg" />
            <div className="flex-1 space-y-2">
              <Skeleton className="h-5 w-1/3" />
              <Skeleton className="h-4 w-2/3" />
            </div>
            <Skeleton className="h-8 w-20 rounded-lg" />
          </div>
        </div>
      ))}
    </div>
  )
}
```

## Card Skeleton
```tsx
function CardSkeleton() {
  return (
    <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-6 space-y-4">
      <Skeleton className="h-40 w-full rounded-lg" />
      <Skeleton className="h-6 w-3/4" />
      <Skeleton className="h-4 w-full" />
      <Skeleton className="h-4 w-2/3" />
      <div className="flex gap-2 pt-2">
        <Skeleton className="h-8 w-20 rounded-full" />
        <Skeleton className="h-8 w-20 rounded-full" />
      </div>
    </div>
  )
}

function CardGridSkeleton({ count = 6 }: { count?: number }) {
  return (
    <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
      {Array.from({ length: count }).map((_, i) => (
        <CardSkeleton key={i} />
      ))}
    </div>
  )
}
```

## Loading Pattern
```tsx
function ProjectsPage() {
  const { projects, isLoading, isError } = useProjects()

  if (isLoading) {
    return (
      <div className="space-y-4">
        <div className="flex justify-between items-center">
          <Skeleton className="h-8 w-40" />
          <Skeleton className="h-10 w-32 rounded-lg" />
        </div>
        <ProjectListSkeleton />
      </div>
    )
  }

  if (isError) {
    return <ErrorState onRetry={() => window.location.reload()} />
  }

  if (projects.length === 0) {
    return <EmptyState />
  }

  return <ProjectList projects={projects} />
}
```

---

# User Onboarding

## Welcome Modal (First Login)
```tsx
function WelcomeModal({ user, onComplete }: { user: User; onComplete: () => void }) {
  const [step, setStep] = useState(0)
  const [answers, setAnswers] = useState({})

  const steps = [
    {
      title: `Welcome, ${user.name?.split(' ')[0] || 'there'}! 👋`,
      subtitle: "Let's personalize your experience",
      content: (
        <div className="space-y-3">
          <p className="text-zinc-400">What brings you here today?</p>
          {['Personal use', 'Work project', 'Just exploring'].map((option) => (
            <button
              key={option}
              onClick={() => {
                setAnswers({ ...answers, purpose: option })
                setStep(1)
              }}
              className="w-full p-3 text-left bg-zinc-800 hover:bg-zinc-700 rounded-lg"
            >
              {option}
            </button>
          ))}
        </div>
      ),
    },
    {
      title: 'How experienced are you?',
      subtitle: "We'll adjust the interface accordingly",
      content: (
        <div className="space-y-3">
          {['Beginner', 'Intermediate', 'Expert'].map((level) => (
            <button
              key={level}
              onClick={() => {
                setAnswers({ ...answers, experience: level })
                setStep(2)
              }}
              className="w-full p-3 text-left bg-zinc-800 hover:bg-zinc-700 rounded-lg"
            >
              {level}
            </button>
          ))}
        </div>
      ),
    },
    {
      title: "You're all set! 🎉",
      subtitle: 'Here are your next steps',
      content: (
        <div className="space-y-4">
          <div className="flex items-start gap-3 p-3 bg-zinc-800 rounded-lg">
            <div className="w-6 h-6 bg-blue-600 rounded-full flex items-center justify-center text-sm">1</div>
            <div>
              <p className="font-medium">Create your first project</p>
              <p className="text-sm text-zinc-400">Start with a template or from scratch</p>
            </div>
          </div>
          <div className="flex items-start gap-3 p-3 bg-zinc-800 rounded-lg">
            <div className="w-6 h-6 bg-zinc-700 rounded-full flex items-center justify-center text-sm">2</div>
            <div>
              <p className="font-medium">Invite your team</p>
              <p className="text-sm text-zinc-400">Collaborate in real-time</p>
            </div>
          </div>
          <button
            onClick={onComplete}
            className="w-full py-3 bg-blue-600 hover:bg-blue-500 rounded-lg font-medium"
          >
            Get Started
          </button>
        </div>
      ),
    },
  ]

  return (
    <div className="fixed inset-0 bg-black/80 flex items-center justify-center z-50">
      <div className="bg-zinc-900 border border-zinc-800 rounded-2xl p-8 max-w-md w-full mx-4">
        {/* Progress */}
        <div className="flex gap-1 mb-6">
          {steps.map((_, i) => (
            <div
              key={i}
              className={`h-1 flex-1 rounded-full ${i <= step ? 'bg-blue-600' : 'bg-zinc-800'}`}
            />
          ))}
        </div>

        <h2 className="text-2xl font-bold text-white mb-2">{steps[step].title}</h2>
        <p className="text-zinc-400 mb-6">{steps[step].subtitle}</p>
        {steps[step].content}
      </div>
    </div>
  )
}
```

## Product Tour (Tooltips)
```tsx
// Install: npm install @floating-ui/react

import { useState, useEffect } from 'react'
import { useFloating, offset, arrow, shift } from '@floating-ui/react'

interface TourStep {
  target: string  // CSS selector
  title: string
  content: string
  position: 'top' | 'bottom' | 'left' | 'right'
}

const TOUR_STEPS: TourStep[] = [
  {
    target: '[data-tour="create-button"]',
    title: 'Create something new',
    content: 'Click here to create your first project',
    position: 'bottom',
  },
  {
    target: '[data-tour="sidebar"]',
    title: 'Your workspace',
    content: 'All your projects appear here',
    position: 'right',
  },
  {
    target: '[data-tour="settings"]',
    title: 'Customize',
    content: 'Adjust your preferences and team settings',
    position: 'left',
  },
]

function ProductTour({ onComplete }: { onComplete: () => void }) {
  const [step, setStep] = useState(0)
  const [targetEl, setTargetEl] = useState<Element | null>(null)

  useEffect(() => {
    const el = document.querySelector(TOUR_STEPS[step].target)
    setTargetEl(el)
    el?.scrollIntoView({ behavior: 'smooth', block: 'center' })
  }, [step])

  const { refs, floatingStyles } = useFloating({
    elements: { reference: targetEl },
    placement: TOUR_STEPS[step].position,
    middleware: [offset(12), shift()],
  })

  if (!targetEl) return null

  const isLast = step === TOUR_STEPS.length - 1

  return (
    <>
      {/* Spotlight overlay */}
      <div className="fixed inset-0 bg-black/60 z-40" />
      
      {/* Highlight target */}
      <div
        className="fixed z-50 ring-4 ring-blue-500 ring-offset-2 ring-offset-zinc-950 rounded-lg"
        style={{
          top: targetEl.getBoundingClientRect().top - 4,
          left: targetEl.getBoundingClientRect().left - 4,
          width: targetEl.getBoundingClientRect().width + 8,
          height: targetEl.getBoundingClientRect().height + 8,
        }}
      />

      {/* Tooltip */}
      <div
        ref={refs.setFloating}
        style={floatingStyles}
        className="bg-zinc-900 border border-zinc-700 rounded-xl p-4 max-w-xs z-50 shadow-xl"
      >
        <p className="font-medium text-white mb-1">{TOUR_STEPS[step].title}</p>
        <p className="text-sm text-zinc-400 mb-4">{TOUR_STEPS[step].content}</p>
        
        <div className="flex items-center justify-between">
          <span className="text-xs text-zinc-500">
            {step + 1} of {TOUR_STEPS.length}
          </span>
          <div className="flex gap-2">
            <button
              onClick={onComplete}
              className="text-sm text-zinc-400 hover:text-white"
            >
              Skip
            </button>
            <button
              onClick={() => isLast ? onComplete() : setStep(step + 1)}
              className="px-3 py-1 bg-blue-600 hover:bg-blue-500 rounded text-sm"
            >
              {isLast ? 'Finish' : 'Next'}
            </button>
          </div>
        </div>
      </div>
    </>
  )
}
```

## Onboarding Checklist
```tsx
interface ChecklistItem {
  id: string
  label: string
  completed: boolean
  action: () => void
}

function OnboardingChecklist({ items }: { items: ChecklistItem[] }) {
  const completed = items.filter((i) => i.completed).length
  const progress = (completed / items.length) * 100

  if (completed === items.length) return null // Hide when done

  return (
    <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-4">
      <div className="flex items-center justify-between mb-3">
        <h3 className="font-medium text-white">Getting Started</h3>
        <span className="text-sm text-zinc-400">{completed}/{items.length}</span>
      </div>
      
      {/* Progress bar */}
      <div className="h-1 bg-zinc-800 rounded-full mb-4">
        <div
          className="h-full bg-blue-600 rounded-full transition-all"
          style={{ width: `${progress}%` }}
        />
      </div>

      <div className="space-y-2">
        {items.map((item) => (
          <button
            key={item.id}
            onClick={item.action}
            disabled={item.completed}
            className="w-full flex items-center gap-3 p-2 rounded-lg hover:bg-zinc-800 disabled:opacity-50 text-left"
          >
            <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${
              item.completed ? 'bg-green-600 border-green-600' : 'border-zinc-600'
            }`}>
              {item.completed && <Check className="w-3 h-3 text-white" />}
            </div>
            <span className={item.completed ? 'text-zinc-500 line-through' : 'text-white'}>
              {item.label}
            </span>
          </button>
        ))}
      </div>
    </div>
  )
}

// Usage
const checklistItems = [
  { id: 'profile', label: 'Complete your profile', completed: true, action: () => {} },
  { id: 'project', label: 'Create first project', completed: false, action: () => router.push('/new') },
  { id: 'invite', label: 'Invite a teammate', completed: false, action: () => setShowInvite(true) },
]
```

## Empty State with Onboarding
```tsx
function EmptyProjectsState() {
  return (
    <div className="flex flex-col items-center justify-center py-16 px-4 text-center">
      <div className="w-16 h-16 bg-zinc-800 rounded-2xl flex items-center justify-center mb-6">
        <FolderPlus className="w-8 h-8 text-zinc-400" />
      </div>
      
      <h2 className="text-xl font-semibold text-white mb-2">
        No projects yet
      </h2>
      <p className="text-zinc-400 max-w-md mb-6">
        Create your first project to get started. You can start from scratch or use a template.
      </p>

      <div className="flex flex-col sm:flex-row gap-3">
        <button className="px-6 py-3 bg-blue-600 hover:bg-blue-500 rounded-lg font-medium flex items-center gap-2">
          <Plus className="w-5 h-5" />
          Create Project
        </button>
        <button className="px-6 py-3 bg-zinc-800 hover:bg-zinc-700 rounded-lg font-medium">
          Browse Templates
        </button>
      </div>

      {/* Quick tips */}
      <div className="mt-12 grid sm:grid-cols-3 gap-4 text-left max-w-2xl">
        <div className="p-4 bg-zinc-900 border border-zinc-800 rounded-xl">
          <Zap className="w-5 h-5 text-yellow-500 mb-2" />
          <p className="text-sm text-zinc-300">Use templates to start faster</p>
        </div>
        <div className="p-4 bg-zinc-900 border border-zinc-800 rounded-xl">
          <Users className="w-5 h-5 text-blue-500 mb-2" />
          <p className="text-sm text-zinc-300">Invite team members anytime</p>
        </div>
        <div className="p-4 bg-zinc-900 border border-zinc-800 rounded-xl">
          <Keyboard className="w-5 h-5 text-green-500 mb-2" />
          <p className="text-sm text-zinc-300">Press ⌘K for quick actions</p>
        </div>
      </div>
    </div>
  )
}
```

## First-Run Experience Hook
```tsx
function useOnboarding() {
  const [state, setState] = useState({
    showWelcome: false,
    showTour: false,
    checklistItems: [],
  })

  useEffect(() => {
    const hasSeenWelcome = localStorage.getItem('onboarding_welcome')
    const hasSeenTour = localStorage.getItem('onboarding_tour')

    if (!hasSeenWelcome) {
      setState((s) => ({ ...s, showWelcome: true }))
    }
  }, [])

  const completeWelcome = () => {
    localStorage.setItem('onboarding_welcome', 'true')
    setState((s) => ({ ...s, showWelcome: false, showTour: true }))
  }

  const completeTour = () => {
    localStorage.setItem('onboarding_tour', 'true')
    setState((s) => ({ ...s, showTour: false }))
  }

  return { ...state, completeWelcome, completeTour }
}
```
      ))}
    </ol>
  )
}
```

---

# Selection Patterns

## Checkbox Group

```tsx
function CheckboxGroup({ options, selected, onChange }: Props) {
  const toggle = (id: string) => {
    onChange(selected.includes(id) 
      ? selected.filter(s => s !== id) 
      : [...selected, id])
  }

  return (
    <div className="space-y-2">
      {options.map(option => (
        <label key={option.id} className={cn(
          "flex items-start gap-3 p-3 rounded-lg border cursor-pointer transition-colors",
          selected.includes(option.id) ? "border-primary bg-primary/5" : "hover:bg-muted/50"
        )}>
          <input
            type="checkbox"
            checked={selected.includes(option.id)}
            onChange={() => toggle(option.id)}
            className="mt-0.5 h-4 w-4 rounded border-gray-300 text-primary"
          />
          <div>
            <span className="font-medium">{option.label}</span>
            {option.description && <p className="text-sm text-muted-foreground">{option.description}</p>}
          </div>
        </label>
      ))}
    </div>
  )
}
```

## Radio Card Group

```tsx
function RadioCardGroup({ options, selected, onChange }: Props) {
  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
      {options.map(option => (
        <label key={option.id} className={cn(
          "relative flex flex-col p-4 rounded-lg border cursor-pointer transition-all",
          selected === option.id ? "border-primary bg-primary/5 ring-1 ring-primary" : "hover:border-primary/50"
        )}>
          <input type="radio" value={option.id} checked={selected === option.id} 
            onChange={() => onChange(option.id)} className="sr-only" />
          <div className={cn(
            "absolute top-3 right-3 h-5 w-5 rounded-full border-2 flex items-center justify-center",
            selected === option.id ? "border-primary bg-primary" : "border-muted"
          )}>
            {selected === option.id && <div className="h-2 w-2 rounded-full bg-white" />}
          </div>
          <span className="font-medium">{option.label}</span>
          {option.description && <span className="text-sm text-muted-foreground mt-1">{option.description}</span>}
        </label>
      ))}
    </div>
  )
}
```

---

# Data Display

## Badge Variants

```tsx
const badgeVariants = {
  default: "bg-primary/10 text-primary",
  success: "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400",
  warning: "bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400",
  error: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
  outline: "border bg-transparent",
}

function Badge({ children, variant = 'default' }: Props) {
  return (
    <span className={cn(
      "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
      badgeVariants[variant]
    )}>
      {children}
    </span>
  )
}
```

## Progress Bar

```tsx
function Progress({ value, max = 100, showLabel = false }: Props) {
  const percentage = Math.round((value / max) * 100)
  return (
    <div className="w-full">
      {showLabel && (
        <div className="flex justify-between text-sm mb-1">
          <span className="text-muted-foreground">Progress</span>
          <span className="font-medium">{percentage}%</span>
        </div>
      )}
      <div className="w-full h-2 bg-muted rounded-full overflow-hidden">
        <div className="h-full bg-primary rounded-full transition-all" style={{ width: `${percentage}%` }} />
      </div>
    </div>
  )
}
```

## Avatar & Avatar Group

```tsx
function Avatar({ src, alt, fallback, size = 'md' }: Props) {
  const sizes = { sm: 'h-8 w-8', md: 'h-10 w-10', lg: 'h-12 w-12', xl: 'h-16 w-16' }
  return (
    <div className={cn("relative rounded-full overflow-hidden bg-muted flex items-center justify-center font-medium", sizes[size])}>
      {src ? <Image src={src} alt={alt} fill className="object-cover" /> : <span>{fallback}</span>}
    </div>
  )
}

function AvatarGroup({ avatars, max = 4 }: Props) {
  const shown = avatars.slice(0, max)
  const remaining = avatars.length - max
  return (
    <div className="flex -space-x-3">
      {shown.map((a, i) => (
        <div key={i} className="ring-2 ring-background rounded-full"><Avatar {...a} size="sm" /></div>
      ))}
      {remaining > 0 && (
        <div className="h-8 w-8 rounded-full bg-muted flex items-center justify-center text-xs font-medium ring-2 ring-background">
          +{remaining}
        </div>
      )}
    </div>
  )
}
```

---

# Empty States

```tsx
function EmptyState({ icon: Icon, title, description, action }: Props) {
  return (
    <div className="flex flex-col items-center justify-center py-12 px-4 text-center">
      {Icon && <div className="mb-4 p-3 bg-muted rounded-full"><Icon className="h-6 w-6 text-muted-foreground" /></div>}
      <h3 className="font-semibold">{title}</h3>
      {description && <p className="text-sm text-muted-foreground mt-1 max-w-sm">{description}</p>}
      {action && <button onClick={action.onClick} className="mt-4 px-4 py-2 bg-primary text-white rounded-md">{action.label}</button>}
    </div>
  )
}

// Usage variants
<EmptyState icon={Search} title="No results found" description="Try adjusting your search" action={{ label: "Clear filters", onClick: clear }} />
<EmptyState icon={FileText} title="No documents yet" description="Upload your first document" action={{ label: "Upload", onClick: upload }} />
<EmptyState icon={AlertCircle} title="Something went wrong" description="We couldn't load your data" action={{ label: "Retry", onClick: retry }} />
```

---

# Search Patterns

## Search with Dropdown

```tsx
function SearchInput({ onSearch, results, onSelect }: Props) {
  const [query, setQuery] = useState('')
  const [open, setOpen] = useState(false)

  return (
    <div className="relative">
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        <input
          value={query}
          onChange={e => { setQuery(e.target.value); onSearch(e.target.value); setOpen(!!e.target.value) }}
          placeholder="Search..."
          className="w-full pl-10 pr-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary"
        />
        {query && <button onClick={() => { setQuery(''); setOpen(false) }} className="absolute right-3 top-1/2 -translate-y-1/2">
          <X className="h-4 w-4" />
        </button>}
      </div>
      
      {open && results.length > 0 && (
        <div className="absolute top-full left-0 right-0 mt-1 bg-background border rounded-lg shadow-lg z-dropdown">
          <ul className="py-1 max-h-64 overflow-auto">
            {results.map(r => (
              <li key={r.id}>
                <button onClick={() => { onSelect(r.id); setOpen(false); setQuery('') }}
                  className="w-full px-4 py-2 text-left hover:bg-muted">
                  <div className="font-medium">{r.title}</div>
                  {r.subtitle && <div className="text-sm text-muted-foreground">{r.subtitle}</div>}
                </button>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  )
}
```

---

# Pagination

```tsx
function Pagination({ currentPage, totalPages, onPageChange }: Props) {
  return (
    <nav className="flex items-center gap-1">
      <button onClick={() => onPageChange(currentPage - 1)} disabled={currentPage === 1}
        className="p-2 rounded-md hover:bg-muted disabled:opacity-50">
        <ChevronLeft className="h-4 w-4" />
      </button>
      
      {generatePages(currentPage, totalPages).map((page, i) => (
        page === '...' ? <span key={i} className="px-2">...</span> : (
          <button key={i} onClick={() => onPageChange(page as number)} className={cn(
            "h-8 w-8 rounded-md text-sm",
            currentPage === page ? "bg-primary text-white" : "hover:bg-muted"
          )}>
            {page}
          </button>
        )
      ))}
      
      <button onClick={() => onPageChange(currentPage + 1)} disabled={currentPage === totalPages}
        className="p-2 rounded-md hover:bg-muted disabled:opacity-50">
        <ChevronRight className="h-4 w-4" />
      </button>
    </nav>
  )
}
```

---

# Accordion / Collapsible

```tsx
import * as Accordion from '@radix-ui/react-accordion'

function AccordionGroup({ items }: { items: { id: string; trigger: ReactNode; content: ReactNode }[] }) {
  return (
    <Accordion.Root type="single" collapsible className="space-y-2">
      {items.map(item => (
        <Accordion.Item key={item.id} value={item.id} className="border rounded-lg overflow-hidden">
          <Accordion.Trigger className="flex w-full items-center justify-between px-4 py-3 font-medium hover:bg-muted/50 [&[data-state=open]>svg]:rotate-180">
            {item.trigger}
            <ChevronDown className="h-4 w-4 transition-transform duration-200" />
          </Accordion.Trigger>
          <Accordion.Content className="overflow-hidden data-[state=closed]:animate-accordion-up data-[state=open]:animate-accordion-down">
            <div className="px-4 pb-4">{item.content}</div>
          </Accordion.Content>
        </Accordion.Item>
      ))}
    </Accordion.Root>
  )
}
```

---

# Infinite Scroll

```tsx
function InfiniteScroll({ items, renderItem, loadMore, hasMore, loading }: Props) {
  const observerRef = useRef<IntersectionObserver>()
  const loadMoreRef = useCallback((node: HTMLDivElement | null) => {
    if (loading) return
    if (observerRef.current) observerRef.current.disconnect()
    observerRef.current = new IntersectionObserver(entries => {
      if (entries[0].isIntersecting && hasMore) loadMore()
    })
    if (node) observerRef.current.observe(node)
  }, [loading, hasMore, loadMore])

  return (
    <div>
      {items.map((item, i) => renderItem(item, i))}
      <div ref={loadMoreRef} className="h-10">
        {loading && <div className="flex justify-center py-4"><Loader className="h-6 w-6 animate-spin" /></div>}
      </div>
      {!hasMore && items.length > 0 && <p className="text-center text-sm text-muted-foreground py-4">No more items</p>}
    </div>
  )
}
```

---

# Hover/Focus/Active States Guide

## Complete Button States

```tsx
<button className={cn(
  // Base
  "px-4 py-2 rounded-md font-medium transition-all",
  
  // Default
  "bg-primary text-white",
  
  // Hover - MUST be obviously different
  "hover:bg-primary/90 hover:shadow-md",
  
  // Focus - for keyboard navigation
  "focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2",
  
  // Active/pressed
  "active:scale-[0.98] active:bg-primary/80",
  
  // Disabled
  "disabled:opacity-50 disabled:pointer-events-none"
)}>
  Button
</button>
```

## Input States

```tsx
<input className={cn(
  "w-full px-3 py-2 border rounded-md transition-colors",
  "hover:border-primary/50",
  "focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent",
  error && "border-red-500 focus:ring-red-500",
  "disabled:bg-muted disabled:cursor-not-allowed disabled:opacity-50"
)} />
```

## Card States

```tsx
<div className={cn(
  "rounded-lg border p-4 transition-all",
  onClick && "cursor-pointer hover:border-primary/50 hover:shadow-md hover:-translate-y-0.5",
  "focus-within:ring-2 focus-within:ring-primary",
  selected && "border-primary bg-primary/5 ring-1 ring-primary"
)}>
  {/* Card content */}
</div>
```

## Interactive State Checklist

```markdown
Before shipping ANY interactive element:

**Visual:**
- [ ] Default → Hover is OBVIOUSLY different
- [ ] Hover → Active provides feedback  
- [ ] Focus ring visible (2px+ contrasting)
- [ ] Disabled looks uninteractable

**Accessibility:**
- [ ] Focus works with Tab key
- [ ] Focus ring has sufficient contrast
- [ ] Disabled has aria-disabled

**Consistency:**
- [ ] All buttons use same patterns
- [ ] All inputs use same patterns
- [ ] Transitions are 150-200ms
```

---

# Quick Reference

```
┌─────────────────────────────────────────────────────────────────────┐
│                    DESIGN SYSTEM QUICK REFERENCE                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  SPACING: gap-1(4px) gap-2(8px) gap-4(16px) gap-6(24px) gap-8(32px)│
│                                                                      │
│  Z-INDEX: dropdown(100) sticky(200) overlay(300) modal(400)        │
│           popover(500) tooltip(600) toast(700)                      │
│                                                                      │
│  TEXT:    truncate | line-clamp-2 | break-words | whitespace-nowrap│
│                                                                      │
│  FLEX:    min-w-0 (prevent overflow) | shrink-0 (fixed size)       │
│           flex-1 (fill space) | min-h-0 (enable scroll)            │
│                                                                      │
│  GRID:    grid-cols-1 md:grid-cols-2 lg:grid-cols-3                 │
│           grid-cols-[repeat(auto-fit,minmax(280px,1fr))]            │
│                                                                      │
│  STATES:  hover: | focus: | active: | disabled: | data-[state=]:   │
│                                                                      │
│  SCROLL:  overflow-auto | overflow-x-auto | overflow-hidden         │
│                                                                      │
│  LAYOUT:  h-screen flex flex-col → flex-1 min-h-0 → overflow-auto  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```
```
