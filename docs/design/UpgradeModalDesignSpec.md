# Upgrade Modal Design Specifications

## Introduction

### Goals
The primary goal of these design specifications is to align the upgrade modal on the profile page with the iOS app's Liquid Glass design system. This ensures a consistent visual language and user experience (UX/UI) that emphasizes subtlety, translucency, and minimalism. The specifications address the five main misalignments identified in the analysis ([UpgradeModalAnalysis.md](docs/design/UpgradeModalAnalysis.md)):

1. **Vibrant purple/pink colors vs. subtle tones**: Shift to neutral, subtle primaries and orange accents for a calmer, more integrated aesthetic.
2. **Solid backgrounds vs. frosted glass**: Implement frosted glass effects with blurs and low opacity to match the app's translucent, layered design.
3. **Gradient buttons/cards vs. clean styles**: Adopt clean, flat styles with subtle shadows and borders for cards and buttons, avoiding gradients.
4. **Purple crowns vs. neutral icons**: Replace custom purple icons with neutral SF Symbols or subtle, system-aligned icons.
5. **Tight spacing/typography vs. minimal flow**: Introduce generous spacing and a hierarchical typography scale to promote a minimal, flowing layout.

These changes will create a seamless integration with the overall app design, improving accessibility, responsiveness, and user engagement while maintaining the modal's purpose: encouraging upgrades to premium features.

The modal will present subscription plans, highlight premium benefits, and include a clear call-to-action (CTA) for upgrading, all while adhering to iOS Human Interface Guidelines.

## Color Palette & Effects

### Color Palette
The color scheme draws from the Liquid Glass design system's primaries, accents, and neutrals to ensure harmony with the app's subtle, ethereal aesthetic. Avoid all purples, pinks, and vibrant hues.

- **Primaries (Subtle Tones)**:
  - Background/Base: Light gray (`UIColor.systemGray6` or `#F2F2F7`, 98% lightness) for subtle layering.
  - Surface: White with low opacity (`UIColor.systemBackground` at 95% opacity) for content areas.
  - Text Primary: Dark gray (`UIColor.label`, `#000000` at 87% opacity) for readability.

- **Accents**:
  - CTA/Interactive: Orange (`UIColor.systemOrange`, `#FF9500`) for buttons and highlights, providing warmth and energy without overwhelming subtlety.
  - Secondary Accent: Soft blue (`UIColor.systemBlue` at 70% opacity, `#007AFF` desaturated) for links or subtle indicators.

- **Neutrals**:
  - Borders/Shadows: Ultra-light gray (`UIColor.separator`, `#C6C6C8` at 50% opacity).
  - Disabled States: Muted gray (`UIColor.systemGray3`, `#8E8E93` at 60% opacity).

All colors must meet WCAG AA accessibility standards, with contrast ratios ≥4.5:1 against backgrounds (e.g., orange CTA text on white: 4.6:1).

### Effects
- **Frosted Glass Backgrounds**: Use `UIBlurEffect(style: .systemUltraThinMaterial)` with 10-20% opacity for the modal overlay and card surfaces. This creates a translucent, depth-enhancing effect that integrates with iOS's dynamic backgrounds (e.g., light/dark mode).
  - Modal Overlay: Full-screen blur at 15% opacity, dimming the underlying profile view without solid fills.
  - Card Elements: Apply `.glassBackground` modifier (from [LiquidGlassDesignSystem.swift](Sources/LiquidGlassDesignSystem.swift)) for frosted panels, with `blur(radius: 10)` and subtle inner shadows.
- **Shadows and Borders**: Soft, diffused shadows (`UIColor.black` at 5-10% opacity, radius 8-12pt) for elevation. Borders: 1pt thickness in neutral gray at 30% opacity, rounded at 12pt corners.
- **No Solid Colors**: All elements must incorporate translucency to avoid visual heaviness; gradients are prohibited.

## Layout Structure

The modal adopts a hierarchical, vertical flow optimized for iPhone screens (e.g., iPhone 14: 390x844pt). Use sheet presentation for non-fullscreen modals or full-screen for immersive upgrades.

- **Overall Structure**:
  - **Header (Top 20%)**: Centered title and close button. Padding: 24pt top/bottom, 16pt sides.
  - **Features List (Middle 40%)**: Bullet-point or icon-listed premium benefits (e.g., unlimited scans, AI recommendations). Vertical spacing: 16pt between items.
  - **Plans Section (Middle 30%)**: Horizontal or stacked cards for subscription tiers (Free, Monthly, Yearly). Responsive: Stack on smaller screens (<414pt width).
  - **Footer CTA (Bottom 10%)**: Single prominent upgrade button, with secondary "Learn More" link. Fixed at bottom with 24pt padding.

- **Spacing and Padding**:
  - Generous margins: 16-24pt horizontal padding throughout; 20pt vertical sections.
  - Element Spacing: 12pt between features, 16pt between plans, 8pt for icon-text pairs.
  - Responsiveness: Use Auto Layout with ≥16pt safe areas; scale spacing by 1.2x on larger devices (e.g., iPad if supported).
  - Minimal Flow: Avoid tight clustering; ensure 1.5x line height for readability and finger-friendly touch targets (≥44pt).

- **Animations**: Smooth entrance (slide-up from bottom with 0.3s ease-in-out), scale on CTA tap (1.05x), and fade for feature highlights. Use `UIViewPropertyAnimator` for 60fps fluidity.

## Typography & Icons

### Typography
Leverage SF Pro (system font) for native iOS feel, with semantic scales for hierarchy.

- **Title (Header)**: SF Pro Display, Headline Large (32pt, bold), line height 1.2, primary text color. E.g., "Unlock Premium Features".
- **Body Text (Features/Descriptions)**: SF Pro Text, Body (17pt, regular), line height 1.5, primary text color. Limit to 2-3 lines per feature.
- **Pricing/Captions (Plans/Footer)**: SF Pro Text, Caption 1 (15pt, medium), line height 1.4, secondary text color (87% opacity). E.g., "$4.99/month".
- **Alignment**: Left-aligned for readability; center for titles and CTAs.
- **Accessibility**: Dynamic Type support; minimum 17pt base size, ≥4.5:1 contrast.

### Icons
Replace custom purple crowns with neutral, system-provided SF Symbols for consistency and scalability.

- **Primary Icons**: `star.fill` (yellow-orange tint for premium status), `bookmark.fill` (for saved books), `bolt.fill` (for fast scans). Size: 24pt, neutral gray fill (70% opacity), orange accent on hover/active.
- **Secondary Icons**: `info.circle` for details, `checkmark.circle.fill` for selected plans. Avoid custom assets; use SF Symbols kit.
- **Style**: Monoline, subtle weight; no gradients or shadows on icons. Integrate with text via 8pt leading.

## Component Specifications

- **Plan Cards**:
  - Style: `.appleBooksCard` modifier (inspired by Apple Books) with frosted glass background, 1pt neutral border, 8pt corner radius, subtle drop shadow (offset 0,4pt; blur 12pt).
  - Content: Icon + title (body font), pricing (caption), bullet features. Selected state: Orange border glow (2pt, 20% opacity).
  - Size: 140x200pt (stacked) or 160x180pt (horizontal); min height 160pt for touch.

- **Buttons**:
  - Primary CTA (Upgrade): Full-width, 48pt height, 12pt corner radius, orange fill (`systemOrange`), white SF Pro bold text (17pt). `.glassBackground` overlay for subtle blur if layered.
  - Secondary (Cancel/Learn More): Outline style, neutral border, transparent fill, primary text color.
  - States: Default (full opacity), Hover (scale 1.02x), Disabled (50% opacity, gray text).

- **Feature List Items**:
  - Row layout: 24pt icon + 16pt left text + chevron.right. Background: None; use list-style with 12pt divider lines (neutral gray, 30% opacity).

- **Modal Container**:
  - Presentation: `.sheet` or full-screen; corner radius 20pt top on sheets.
  - Scrollable if content exceeds (e.g., long features list); safe area insets applied.

All components integrate existing modifiers from [LiquidGlassDesignSystem.swift](Sources/LiquidGlassDesignSystem.swift), such as `.glassBackground` for blurs and `.appleBooksCard` for card styling.

## Integration Notes

These specifications tie directly into the existing codebase for seamless implementation:

- **ProfileView.swift**: The modal is triggered from the profile page (e.g., via a premium badge tap). Update the modal presentation to use `sheet(isPresented:)` with the new `UpgradeModalView.swift`. Ensure the underlying profile view's Liquid Glass elements (e.g., tab bar from [LiquidGlassTabBar.swift](Sources/LiquidGlassTabBar.swift)) remain visible through the translucent overlay. Pass user data (e.g., current tier from [RevenueCatManager.swift](Sources/RevenueCatManager.swift)) to customize features/pricing dynamically.

- **LiquidGlassDesignSystem.swift**: Leverage predefined modifiers and colors:
  - `.glassBackground` for all frosted effects.
  - `.appleBooksCard` for plan cards.
  - Color extensions (e.g., `liquidGlassOrange`, `systemGrayBlur`) for palette consistency.
  - Add new modifiers if needed: e.g., `.frostedModal` for the overlay, `.neutralIcon` for SF Symbols styling.
  - Ensure dark mode support by using `colorScheme` adaptive colors.

Implementation should reference these files to avoid duplication, maintaining the design system's single source of truth. Test for iOS 17+ compatibility, focusing on Material effects and Dynamic Type.