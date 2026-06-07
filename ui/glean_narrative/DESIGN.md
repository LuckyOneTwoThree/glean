---
name: Glean Narrative
colors:
  surface: '#f9f9f8'
  surface-dim: '#dadad9'
  surface-bright: '#f9f9f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4f3'
  surface-container: '#eeeeed'
  surface-container-high: '#e8e8e7'
  surface-container-highest: '#e2e2e2'
  on-surface: '#1a1c1c'
  on-surface-variant: '#44474c'
  inverse-surface: '#2f3130'
  inverse-on-surface: '#f1f1f0'
  outline: '#74777d'
  outline-variant: '#c4c6cd'
  surface-tint: '#4f6073'
  primary: '#041627'
  on-primary: '#ffffff'
  primary-container: '#1a2b3c'
  on-primary-container: '#8192a7'
  inverse-primary: '#b7c8de'
  secondary: '#735c00'
  on-secondary: '#ffffff'
  secondary-container: '#fed65b'
  on-secondary-container: '#745c00'
  tertiary: '#211200'
  on-tertiary: '#ffffff'
  tertiary-container: '#38260b'
  on-tertiary-container: '#a88c69'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d2e4fb'
  primary-fixed-dim: '#b7c8de'
  on-primary-fixed: '#0b1d2d'
  on-primary-fixed-variant: '#38485a'
  secondary-fixed: '#ffe088'
  secondary-fixed-dim: '#e9c349'
  on-secondary-fixed: '#241a00'
  on-secondary-fixed-variant: '#574500'
  tertiary-fixed: '#feddb5'
  tertiary-fixed-dim: '#e1c29b'
  on-tertiary-fixed: '#281802'
  on-tertiary-fixed-variant: '#584326'
  background: '#f9f9f8'
  on-background: '#1a1c1c'
  surface-variant: '#e2e2e2'
  ink-blue: '#1A2B3C'
  golden-hour: '#D4AF37'
  soft-grey: '#E8E8E6'
  unread-blue: '#2D5AF7'
  paper-white: '#FFFFFF'
  text-dimmed: '#6B7280'
typography:
  headline-xl:
    fontFamily: Source Serif 4
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
  headline-lg:
    fontFamily: Source Serif 4
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-md:
    fontFamily: Source Serif 4
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-sm:
    fontFamily: Source Serif 4
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Hanken Grotesk
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Hanken Grotesk
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Hanken Grotesk
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Hanken Grotesk
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Hanken Grotesk
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.04em
  code-sm:
    fontFamily: jetbrainsMono
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 18px
  headline-lg-mobile:
    fontFamily: Source Serif 4
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  container-margin: 24px
  gutter-md: 16px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 32px
  section-gap: 48px
---

## Brand & Style

The design system is anchored in the concept of "curated clarity." It reflects the brand personality of a high-end digital newspaper—minimalist, professional, and calm. The objective is to transform the chaotic influx of daily information into a serene, structured research environment. 

The design style is **Minimalist** with a **Corporate Modern** foundation. It prioritizes whitespace and typographic hierarchy to ensure that AI-driven insights remain the focal point. By utilizing thin lines and a restricted color palette, the system evokes the feeling of a personal research assistant who values the user's time and cognitive load. The aesthetic is "Less but Better," focusing on information density without visual clutter.

## Colors

The palette is designed to reduce eye strain during long reading sessions. 
- **Primary (Ink Blue):** Used for typography, iconography, and structural elements. It provides a grounded, authoritative feel.
- **Secondary (Golden Hour):** Reserved for "Glean" moments—highlights, AI synthesis indicators, and the accentuation of high-quality scores.
- **Neutral (Paper White & Soft Grey):** The background is a slightly warmed white to mimic high-quality paper, avoiding the harshness of pure digital white.
- **Semantic Colors:** A specific 'Unread Blue' is used for activity markers, while standard success and error states are treated with low-saturation tones to maintain the calm atmosphere.

## Typography

This design system employs a "Journalistic Pairing" strategy:
- **Headline (Source Serif 4):** A sophisticated serif for article titles and section headers. It provides the "High-Quality News" aesthetic and aids in reading flow for longer titles.
- **Body & UI (Hanken Grotesk):** A sharp, modern sans-serif for interface elements, summaries, and navigation. It ensures clarity and a technical, precise feel for AI-generated data.
- **Monospace (JetBrains Mono):** Used strictly for metadata, logs, and export previews to emphasize the "Research Tool" aspect of the app.

## Layout & Spacing

The system uses a **Fixed Grid** approach for desktop and tablet to maintain a "readable column" width, while transitioning to a **Fluid Grid** for mobile devices.

- **Desktop/Tablet:** Content is centered in a max-width container (approx 800px for reading comfort) to prevent long line lengths that strain the eyes.
- **Mobile:** 12-column grid with 24px side margins.
- **Spacing Philosophy:** We utilize a 4px baseline. Large gaps (32px+) are encouraged between different news categories to allow the user to "reset" mentally. Divider lines are thin (1px) and use `soft-grey` to define boundaries without adding visual weight.

## Elevation & Depth

Visual hierarchy is achieved through **Tonal Layers** and **Subtle Shadows**. 

- **Surface Tiers:** The primary background uses `paper-white`. Secondary content (like the "Score Explanation" or "Search Bar") sits on `neutral-color-hex`.
- **Shadows:** Avoid heavy, dark shadows. Use ambient, high-diffusion shadows (Blur: 20px, Opacity: 4%, Color: `ink-blue`) to lift cards slightly off the background.
- **Interaction Depth:** Elements should feel "pressed" or "hollow" when active using thin 1px inset strokes rather than dramatic color changes.
- **Modals:** Use a semi-transparent `ink-blue` overlay (20% opacity) with a background blur (8px) to focus attention on dialogs.

## Shapes

The shape language is "Soft Professional." 
- **Cards & Input Fields:** Use a medium radius (8px / 0.5rem) to strike a balance between friendly and institutional.
- **Score Badges:** Use perfect circles for numerical scores to make them stand out as the "anchor" of the list view.
- **Chips & Tags:** Use pill-shaped (fully rounded) containers for categories (e.g., #AI, #Tech) to distinguish them from actionable buttons.

## Components

- **News Cards:** Use a three-zone layout. Left: Circular Score Badge. Center: Serif Headline + Sans-serif one-line summary. Right: Thin-line action icons (Heart, Share).
- **Buttons:** 
  - **Primary:** Filled `ink-blue` with white text.
  - **Secondary:** Outlined with 1px `ink-blue` stroke.
  - **Accent:** Clear background with `golden-hour` text and icon.
- **Progress Bars:** Use a thin 4px height. The track is `soft-grey` and the indicator is a gradient from `ink-blue` to `golden-hour` to show the transition from "Raw Data" to "Gleaned Insight."
- **Dividers:** Use text-integrated dividers for briefing sections: `━━━ 🤖 AI ━━━` using `ink-blue` for the emoji and line.
- **Input Fields:** Minimalist design with only a bottom-border in `soft-grey`, which turns `ink-blue` and thickens to 2px upon focus.
- **Chips:** Small, pill-shaped tags with `soft-grey` backgrounds and `ink-blue` text for metadata like "Source" or "Topic."