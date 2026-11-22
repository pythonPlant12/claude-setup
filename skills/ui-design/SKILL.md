---
name: ui-design
description: >
  Structured UI design rules and workflow for ANY change to a user interface:
  new screens or pages, components, layout, styling, CSS, Tailwind, design
  tokens, colors, typography, spacing, buttons, forms, modals, cards, tables,
  dashboards, navigation, mobile layouts, dark mode, motion, icons, UI copy,
  or "make it look better" requests. Use it whenever the user asks to build,
  change, restyle, polish, review, or fix anything visual or interactive in a
  frontend (web, mobile, desktop, Figma-to-code, Claude Design prototypes),
  even when the user does not say "design". Based on the UI principles that
  Zander Whitehurst (Memorisely) teaches. Skip it when the user disabled it
  with /disable-ui-skill.
---

# UI design

## Gate

Skill state: !`test -f "$HOME/.local/state/claude/ui-skill-disabled" && echo DISABLED || echo ENABLED`

If the state above is `DISABLED`, or the user ran `/disable-ui-skill` in this
session, stop reading this skill and do the UI work without it. The user
enables it again with `/enable-ui-skill`.

## Why this skill exists

AI-generated UI looks the same everywhere: the same layouts, the same
components, the same generic experience. A polished screen is not a solved
problem. This skill makes Claude design from a system and from a problem, and
apply concrete craft rules instead of defaults.

Two ideas drive every rule below:

1. **Design is subtraction.** Every element must earn its place. If an element
   does not improve clarity, hierarchy, emotion, or action, it is noise.
2. **If everything is important, nothing is.** Hierarchy guides decisions.
   Decoration does not.

## Workflow

Do these steps in order. Keep each step short for small changes.

1. **Find the problem.** State in one sentence what the change must make
   easier for the user. If the request is only a solution ("move this button",
   "copy competitor X"), find the problem behind it before you design.
2. **Find the system.** Before you write UI code, read what exists:
   - tokens: CSS variables, Tailwind config/theme, `tokens.*`, theme files;
   - type scale, spacing scale, radii, shadows, breakpoints;
   - existing components (button, input, card, modal) and their props.
   Reuse them. Do not add a one-off color, size, or component when the system
   has one. If no system exists, define a minimal one first (see
   [Foundations](#foundations)) and put it in one place.
3. **Lay out content first.** Start with real content and its grouping by
   white space. Add surfaces, borders, and color only for emphasis.
4. **Set hierarchy.** Pick the one primary action and the one most important
   piece of information on the screen. Everything else steps back.
5. **Design every state.** Default, hover, focus, active, disabled, loading,
   empty, error, success. Add motion only where it explains a change.
6. **Review.** Run the [checklist](#review-checklist) on the result. Fix
   failures before you report the work as done.

## Foundations

### Spacing

- Never eyeball spacing. Use a scale on a 4px base:
  `4, 8, 12, 16, 24, 32, 48, 64, 96`.
- Use proximity to show relationships: related items get less space than
  unrelated groups. Space inside a group < space between groups.
- Group content with white space, not with containers or lines.

### Corner radius

- Nested radii: **inner radius = outer radius − padding** between them.
  Example: card radius 24, padding 8 → inner element radius 16.
- Use a small radius set from tokens. Do not mix arbitrary radii.

### Typography

- Use one functional sans-serif family for product UI unless the system says
  otherwise. Pick a font with intent, not the same default for every project.
- Use a modular type scale (for example a major-third 1.25 ratio) from tokens.
  Do not invent sizes.
- No tiny text. Body text 16px on web (17pt iOS). Smallest caption/label
  11–12px, and only for secondary metadata.
- Set line height and letter spacing intentionally:
  body line height 1.4–1.6, headings 1.1–1.3; tighten tracking slightly on
  large headings, add slight tracking to small uppercase labels.
- Keep body line length at 50–75 characters.
- Create hierarchy with size, weight, and grey tones, not with many colors.

### Alignment

- Do not center multi-line text. Every centered line creates a new alignment
  anchor. Use one left-aligned anchor and proximity. Centering is acceptable
  only for one short line (for example an empty-state title).
- Align icons to text optically: center the icon on the text line, use a
  fixed gap from the spacing scale, and keep icon size tied to the font size.
- Give users visual anchors (icons, thumbnails, shapes) to scan before they
  read.

### Color

- Use primitive tokens (`blue-500`) only inside semantic tokens
  (`color-action-primary`, `color-text-muted`, `color-surface-raised`).
  Components use semantic tokens only. Tokens are the UI's visual API.
- The brand color is not automatically the primary UI color. If the brand
  color fails contrast for text or buttons, derive an accessible primary
  shade and keep the brand hue for marketing and accents.
- If the brand color is red, danger actions must still be distinguishable:
  use a different treatment (shade, icon, explicit verb + noun label,
  placement) so a destructive action never looks like the main brand CTA.
- Contrast: WCAG AA minimum (4.5:1 body text, 3:1 large text and UI
  boundaries).
- Use color with intent: status, emphasis, and action. Not decoration.

### Dark mode

- Do not invert the light theme. Use dark grey surfaces, not pure black.
- Show elevation with lighter surfaces, not with shadows.
- Desaturate and lighten accent colors so they do not vibrate on dark
  backgrounds. Re-check contrast for every semantic token in both modes.

### Gradients and imagery

- Avoid muddy gradients: do not blend two distant hues straight through grey.
  Add intermediate stops or blend through adjacent hues.
- Text on images: add a gradient scrim so text stays accessible and the image
  stays visible.
- No blurry images and no dated stock photos.

### Shadows and surfaces

- Do not use the default drop shadow. Use soft, low-opacity, layered shadows
  that imitate natural light, and only on elevated surfaces (popovers,
  dialogs, dragged items).
- Do not add a background or border to every card. Too many borders turn a
  layout into a spreadsheet. Hold layouts together with white space.

### Icons

- Do not draw custom icons. Use one existing library consistently (for
  example Lucide, Phosphor, Heroicons, Material Symbols) with one stroke
  weight and size scale.

### Breakpoints

- Use named breakpoints from the system (`sm`, `md`, `lg`, `xl`) with a max
  content width.
- Design mobile first from the smallest common screen (iPhone SE width,
  375px). It is easier to scale up than down.
- Design mobile screens as scrollable pages, not as fixed device-sized posters.

## Components and patterns

### Buttons

- One primary button per view. Pair it with secondary or ghost buttons.
  This pairing works for auth, forms, confirmations, and destructive flows.
- Labels are **verb + noun**: "Delete file", "Remove member", "Create
  project". Never "Click here", "OK", "Submit", "Yes".
- Write outcome copy, not mechanics: "Get weekly tips" instead of
  "Subscribe". Use precise verbs in flows ("Reserve", "Choose", "Pay now").
- Size buttons from content outwards (padding around the label) and set a
  minimum width so short labels do not produce awkward tap targets.
  Tap targets ≥ 44×44px.
- Design all states: default, hover, focus (visible ring), active/pressed,
  disabled, loading. Add keyboard shortcut hints in tooltips for power-user
  actions.

### Cards

- If the whole card is clickable, do not put a button inside it.
- Build hierarchy inside cards with size, position, and proximity: one
  dominant element (image or title), then supporting metadata in muted tones.

### Forms

- Always use visible labels. A placeholder is never a label.
- Placeholders show a real example or a direct instruction, without "e.g.".
- Choose the control by option count:
  radio buttons for one choice of 2–7 options;
  chips for multiple choices of 3–10 options;
  dropdown only for 10+ options or very tight space.
- Reduce effort: fewer fields, smart defaults, inline validation, clear
  progress, and small motion feedback that builds confidence.
- Date pickers: clear hierarchy (selected date and range dominant), large
  targets, quick presets.

### Modals and confirmations

- Do not write "Are you sure?" modals. Title and button state the action:
  "Delete file?" + "Delete file". Explain the consequence in one line.
- Make the destructive action explicit and the safe action easy.

### Navigation and tabs

- Mobile menus: use a plain grouped vertical list, not columns.
- Tab bars: icon + label, clear active state, no action buttons mixed into
  tabs. Functional first, Dribbble style second.
- Carousels: show that more content exists (peek next item), give controls,
  and never auto-rotate critical content.

### Data and dashboards

- Do not show raw numbers alone. Add context: comparison, trend, target, or a
  one-line insight, so users scan instead of calculate.
- Promote one hero metric. Equal-weight stat tiles mean no hierarchy.

### Content

- No lorem ipsum and no duplicated placeholder content. Use realistic content
  with realistic lengths, including long names and empty values.
- Do not depend on text to explain the UI. Use layout to group, visual cues
  for status, and hierarchy for attention. Great UI is designed for scanning.
- Fewer choices: each extra button, filter, or link adds hesitation (Hick's
  law, law of Prägnanz). Remove before you add.

### Motion

- No instant default transitions on state changes, and no motion for
  decoration. A transition must explain what changed (where an element came
  from, where it went, what it relates to).
- Use motion to support hierarchy: animate the most important element first,
  then stagger the rest (keep it to about three levels).
- Typical durations 150–300ms with ease-out for entering, ease-in for
  leaving. Respect `prefers-reduced-motion`.

### Subscriptions and ethics

- Make cancellation easy to find and complete. Do not hide cancel, add
  forms, or swap the primary action. Earn trust so users come back.

## Design system hygiene (code)

- Component props in code match the design tool's component properties
  (same names, same variants).
- Name components as base + modifiers (`Button`, `variant="secondary"`,
  `size="sm"`), not ad-hoc names.
- Put new tokens in the token source, not inline in a component.

## Review checklist

Check every item before you report UI work as done. Report failures you
could not fix.

- [ ] The change solves a stated user problem, not only a requested look.
- [ ] Only tokens from the system: no new hard-coded colors, sizes, radii.
- [ ] Spacing is on the 4px scale; groups separate by proximity.
- [ ] One primary action per view; other actions are visually secondary.
- [ ] No multi-line centered text; one alignment anchor per group.
- [ ] Nested radii follow inner = outer − padding.
- [ ] No unnecessary containers, borders, or card backgrounds.
- [ ] Text ≥ 16px body, ≥ 11–12px smallest; line length 50–75 chars.
- [ ] Contrast AA in light and dark mode.
- [ ] Buttons and modal actions use verb + noun labels.
- [ ] Forms: visible labels, correct control per option count.
- [ ] Numbers have context; one hero metric where data is shown.
- [ ] All interactive states exist, including focus and loading.
- [ ] Empty, error, and long-content cases are designed.
- [ ] Motion explains change and respects reduced motion.
- [ ] Mobile layout works at 375px wide.
- [ ] Nothing on the screen exists only because AI suggested "more".

For the source posts behind these rules, see
[references/sources.md](references/sources.md).
