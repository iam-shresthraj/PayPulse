---
name: Obsidian Amber
colors:
  surface: '#131313'
  surface-dim: '#131313'
  surface-bright: '#3a3939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1c1b1b'
  surface-container: '#201f1f'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353534'
  on-surface: '#e5e2e1'
  on-surface-variant: '#ddc1ae'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#313030'
  outline: '#a48c7a'
  outline-variant: '#564334'
  surface-tint: '#ffb77d'
  primary: '#ffb77d'
  on-primary: '#4d2600'
  primary-container: '#ff8c00'
  on-primary-container: '#623200'
  inverse-primary: '#904d00'
  secondary: '#c8c6c5'
  on-secondary: '#313030'
  secondary-container: '#474746'
  on-secondary-container: '#b7b5b4'
  tertiary: '#c8c6c5'
  on-tertiary: '#303030'
  tertiary-container: '#aba9a9'
  on-tertiary-container: '#3e3e3e'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffdcc3'
  primary-fixed-dim: '#ffb77d'
  on-primary-fixed: '#2f1500'
  on-primary-fixed-variant: '#6e3900'
  secondary-fixed: '#e5e2e1'
  secondary-fixed-dim: '#c8c6c5'
  on-secondary-fixed: '#1c1b1b'
  on-secondary-fixed-variant: '#474746'
  tertiary-fixed: '#e5e2e1'
  tertiary-fixed-dim: '#c8c6c5'
  on-tertiary-fixed: '#1b1c1c'
  on-tertiary-fixed-variant: '#474746'
  background: '#131313'
  on-background: '#e5e2e1'
  surface-variant: '#353534'
typography:
  display-lg:
    fontFamily: Poppins
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Poppins
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Poppins
    fontSize: 26px
    fontWeight: '600'
    lineHeight: 32px
  title-md:
    fontFamily: Poppins
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Poppins
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Poppins
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Poppins
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  container-padding: 20px
  gutter: 16px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 32px
  section-gap: 48px
---

## Brand & Style

The design system is centered on a **Premium Glassmorphism** aesthetic, tailored for a high-end fintech or luxury management experience. It evokes a sense of exclusivity, precision, and depth. By utilizing a "Pure Black" foundation, the interface recedes to allow content to float within translucent, frosted glass containers. 

The brand personality is authoritative yet modern, replacing traditional gold tones with a high-energy **Dark Orange** to signal innovation rather than legacy. The emotional response is one of "Sophisticated Utility"—where the user feels they are interacting with a high-performance tool that doesn't compromise on visual elegance. High-contrast typography and vibrant orange gradients cut through the dark atmosphere to provide clear directional cues.

## Colors

The palette is strictly dark-mode, rooted in `#000000` (Pure Black) for the primary background to maximize OLED efficiency and depth. 

- **Primary:** Dark Orange (`#FF8C00`) is used for critical actions, active states, and brand highlights. 
- **Gradients:** Use the Amber-to-Fire gradient for primary buttons and high-impact promotion banners.
- **Surfaces:** Dark Grays (`#0D0D0D` and `#1A1A1A`) serve as the base for glass containers. 
- **Glass Effect:** All card surfaces must use a semi-transparent hex with a `backdrop-filter: blur(20px)` and a subtle `1px` inner stroke of `rgba(255, 255, 255, 0.08)` to define edges against the black background.
- **Strict Rule:** Gold and yellow hues are entirely deprecated in favor of orange tones.

## Typography

This design system utilizes **Poppins** exclusively to achieve a clean, geometric, and modern feel. 

- **Headlines:** Use Bold (`700`) or SemiBold (`600`) weights with tight letter-spacing for a high-impact, editorial look.
- **Contrast:** Maintain a clear hierarchy by using Pure White (`#FFFFFF`) for primary headings and a muted gray (`#A0A0A0`) for secondary body text and descriptions.
- **Readability:** On dark backgrounds, slightly increase line-height for body text to prevent "halpation" (the glowing effect of white text on black) and ensure comfortable scanning.

## Layout & Spacing

The layout follows a **Fluid Grid** model with a generous, "breathing" spacing philosophy. Elements are treated as floating objects rather than rigid blocks.

- **Floating Cards:** All main content containers should have lateral margins of at least 20px, preventing them from touching the screen edges.
- **Vertical Rhythm:** Use a base unit of 4px. Standard groupings use 16px (stack-md), while distinct sections are separated by 48px (section-gap).
- **Safe Areas:** Ensure interactive elements are within a 44px hit-zone. On mobile, bottom navigation and primary "Scan" buttons are elevated and detached from the bottom edge to maintain the floating aesthetic.

## Elevation & Depth

Depth is the cornerstone of this design system, achieved through three layers of visual information:

1.  **Base Layer:** Pure Black (`#000000`) background, representing infinite depth.
2.  **Glass Layer:** Semi-transparent containers with `backdrop-filter: blur(24px)`. These surfaces use "Ambient Shadows"—deep, ultra-diffused drop shadows (`0px 20px 40px rgba(0,0,0,0.4)`) to separate the card from the base.
3.  **Active/Focus Layer:** Elements that require immediate attention (like primary buttons or active chips) use the **Orange Gradient** and a subtle glow (outer shadow) matching the brand color to appear as if they are emitting light.

## Shapes

The shape language is ultra-smooth and friendly to balance the technicality of the dark theme. 

- **Global Radius:** Following the `ROUND_TWENTY` directive, standard cards and containers use a `1.25rem` (20px) corner radius.
- **Interactive Elements:** Buttons and input fields should match this `20px` radius for consistency.
- **Logo & Icons:** The logo should be reduced in scale by roughly 15% compared to the reference, but must maintain its original proportions. Icons are enclosed in rounded squares or circles with consistent 2px stroke weights.

## Components

### Buttons
- **Primary:** Full Orange Gradient background, white text (SemiBold), 20px roundedness. No border.
- **Secondary:** Semi-transparent glass background (`#FFFFFF05`), white text, 1px subtle white stroke (`0.1` opacity).
- **Ghost:** No background, Orange text, used for less frequent actions.

### Cards
- **Standard Card:** Backdrop blur (20px), fill (`#1A1A1A` at 70% opacity), 20px border radius, and a 1px top-down inner highlight.
- **Floating Action Card:** High-elevation shadow, floating 16px above the bottom nav.

### Input Fields
- Dark Gray fill (`#0D0D0D`), 20px radius, 1px border that glows Orange (`#FF8C00`) on focus. Placeholder text in muted gray.

### Chips & Badges
- **Active:** Solid Dark Orange.
- **Inactive:** Glass effect with thin gray stroke.
- **Status Badges:** Use gradients for "Live" or "New" states to draw immediate attention.

### Navigation
- A floating bottom bar with a glass container. Icons use a "glowing" state (Orange) when active and a dimmed state when inactive.