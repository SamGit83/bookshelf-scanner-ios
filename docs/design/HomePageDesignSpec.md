# Bookshelf Scanner Home Page Design Specification

## Overview
This document outlines the detailed design specification for the Bookshelf Scanner iOS app's home page, serving as a landing page for unauthenticated users. The design follows the established Liquid Glass design system for consistency with the app's authenticated views.

## Layout Structure

### 1. Navigation Bar
**Position**: Top of screen, fixed
**Height**: 60pt (standard navigation bar height)
**Background**: Translucent with blur effect matching Liquid Glass system

**Layout**:
- **Left**: App logo and title "Bookshelf Scanner"
- **Right**: Login and Signup buttons
- **Center**: Empty for balance

**Content**:
- Logo: Books vertical icon (systemImage: "books.vertical.fill") with circular background
- Title: "Bookshelf Scanner" in large title font
- Login Button: "Login" text, secondary style
- Signup Button: "Sign Up" text, primary style (white background, blue text)

### 2. Hero Section
**Position**: Below navigation bar
**Height**: Flexible, minimum 70% of screen height
**Background**: Dynamic gradient (blue to purple to pink) with animated blur overlays

**Layout**:
- **Vertical Stack**: Centered content
- **Icon**: Large books icon with glow effect
- **Headline**: Main value proposition
- **Subheadline**: Supporting description
- **CTA Button**: "Get Started" primary button
- **Background Elements**: Animated geometric shapes with blur

**Content Suggestions**:
- **Headline**: "Transform Your Bookshelf into a Digital Library"
- **Subheadline**: "Scan your physical books with AI, discover new reads, and track your reading journey—all in one beautiful app."
- **CTA**: "Get Started" button leading to signup/login

### 3. User Journey Section
**Position**: Below hero section
**Height**: Flexible, approximately 60% of screen height
**Background**: Subtle translucent overlay

**Layout**:
- **Section Title**: "How It Works"
- **Horizontal ScrollView**: 4-step process
- **Each Step Card**:
  - Step number icon
  - Step title
  - Step description
  - Visual element (icon or illustration)
- **Benefits Summary**: Below steps

**Content Suggestions**:
- **Step 1**: "Scan Your Bookshelf" - "Point your camera at your bookshelf and capture a photo"
- **Step 2**: "AI Recognition" - "Our AI identifies books instantly using advanced vision technology"
- **Step 3**: "Organize Your Library" - "Automatically add books to your digital collection"
- **Step 4**: "Track & Discover" - "Monitor reading progress and get personalized recommendations"

- **Benefits**: "Save time cataloging • Never lose track of your books • Discover new favorites • Track reading goals"

### 4. Features Section
**Position**: Below user journey
**Height**: Flexible, approximately 50% of screen height
**Background**: Alternating translucent cards

**Layout**:
- **Section Title**: "Powerful Features"
- **Grid Layout**: 2x2 or 3x2 grid of feature cards
- **Each Feature Card**:
  - Feature icon
  - Feature title
  - Feature description
  - Glass effect background

**Content Suggestions**:
- **AI-Powered Scanning**: "Advanced computer vision recognizes books instantly"
- **Offline Access**: "Read and manage your library anywhere, even offline"
- **Reading Progress**: "Track pages read, set goals, and monitor your reading habits"
- **Smart Recommendations**: "Discover new books based on your reading patterns"
- **Manual Entry**: "Add books manually with ISBN lookup for complete coverage"
- **Cross-Device Sync**: "Access your library on all your Apple devices"

### 5. Footer
**Position**: Bottom of screen
**Height**: Flexible, minimum 100pt
**Background**: Dark translucent overlay

**Layout**:
- **Horizontal Stack**: Centered content
- **Links**: Privacy Policy, Terms of Service, Contact, Social Media
- **Copyright**: "© 2024 Bookshelf Scanner. All rights reserved."

**Content Suggestions**:
- **Links**: Privacy Policy • Terms of Service • Contact Us • Twitter • Instagram
- **Copyright**: Include current year and app name

## Visual Styling (Liquid Glass Design System)

### Color Palette
- **Primary Gradient**: Linear gradient from blue (top-left) to purple (center) to pink (bottom-right)
- **Glass Effects**: White opacity 0.1 for backgrounds, 0.2 for borders
- **Text Colors**: White (0.9 opacity) for primary, White (0.7) for secondary
- **Accent Colors**: Blue for primary actions, Pink for secondary

### Typography
- **Navigation Title**: Large Title (34pt) font weight bold
- **Headlines**: Title (28pt) font weight bold
- **Subheadlines**: Headline (17pt) regular
- **Body Text**: Body (17pt) regular
- **Captions**: Caption (12pt) regular

### Glass Effects
- **Background Blur**: 1pt radius for subtle depth
- **Border Effects**: 0.5pt white opacity 0.2 stroke
- **Corner Radius**: 20pt for cards, 10pt for buttons
- **Shadow/Depth**: Subtle inner shadows for layered glass effect

### Animations
- **Page Load**: Fade in with spring animation (0.3s delay for each section)
- **Button Interactions**: Scale effect (0.95x) on tap
- **Background Elements**: Subtle floating animation for geometric shapes
- **Scroll Effects**: Parallax scrolling for background elements

### Spacing
- **Section Margins**: 32pt horizontal, 64pt vertical between sections
- **Element Spacing**: 24pt between related elements, 16pt for tight spacing
- **Padding**: 24pt internal padding for cards and sections

## New Components Needed

### 1. HomeNavigationBar
**Purpose**: Custom navigation bar for home page
**Properties**: None (self-contained)
**Styling**: Liquid Glass background, app branding, action buttons

### 2. HeroSection
**Purpose**: Main value proposition display
**Properties**: headline, subheadline, ctaAction
**Styling**: Centered layout, large icon, gradient background with animations

### 3. UserJourneySection
**Purpose**: Step-by-step process visualization
**Properties**: steps array (title, description, icon)
**Styling**: Horizontal scrolling cards, numbered steps, glass backgrounds

### 4. FeaturesSection
**Purpose**: Feature showcase grid
**Properties**: features array (title, description, icon)
**Styling**: Grid layout, feature cards with icons, alternating backgrounds

### 5. HomeFooter
**Purpose**: Legal and social links
**Properties**: links array (title, url)
**Styling**: Horizontal layout, subtle background, small text

### 6. GlassCard
**Purpose**: Reusable card component for sections
**Properties**: content, backgroundColor (optional)
**Styling**: Rounded rectangle with glass effect, blur, border

### 7. AnimatedBackground
**Purpose**: Dynamic background with floating elements
**Properties**: colors array, shapes array
**Styling**: Gradient background with animated blur circles

## Responsive Design Considerations

### iPhone SE (Compact)
- Reduce section heights proportionally
- Stack feature grid in single column
- Smaller text sizes and spacing

### iPhone Pro Max (Large)
- Increase spacing and text sizes
- Maintain aspect ratios
- Optimize for taller screens

### iPad (Tablet)
- Center content with max width constraints
- Adjust grid layouts for wider screens
- Larger touch targets

## Accessibility Features

### VoiceOver Support
- Descriptive labels for all interactive elements
- Proper heading hierarchy (title, headline, body)
- Image descriptions for icons

### Dynamic Type
- Support for all text size preferences
- Maintain readability at largest sizes
- Flexible layouts that adapt to text scaling

### Color Contrast
- Minimum 4.5:1 contrast ratio for text
- Alternative indicators for color-dependent elements
- Support for high contrast mode

## Implementation Notes

### Navigation Flow
- Login/Signup buttons navigate to existing LoginView
- "Get Started" CTA navigates to signup flow
- Footer links open external URLs or in-app views

### Performance Considerations
- Lazy load section content
- Optimize image assets for icons
- Minimize background animations on lower-end devices

### Integration Points
- AuthService for user state management
- Existing LiquidGlassDesignSystem components
- AppDelegate for navigation coordination

## Success Metrics

### User Engagement
- Time spent on home page
- Click-through rates on CTA buttons
- Conversion to signup/login

### Technical Performance
- Page load time < 2 seconds
- Smooth scrolling performance
- Memory usage < 50MB

### Design Effectiveness
- Visual consistency with app design system
- Clear communication of value proposition
- Intuitive navigation and user flow