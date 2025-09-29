# Bookshelf Scanner Documentation

This directory contains comprehensive documentation for the Bookshelf Scanner iOS application, organized into three main categories: Design, Planning, and Technical documentation.

## 📁 Documentation Structure

### 🎨 Design Documentation (`docs/design/`)
Comprehensive design specifications and UI/UX guidelines for the Bookshelf Scanner app.

- **[Liquid Glass UI Design Plan](design/LiquidGlassUIDesignPlan.md)** - Complete design system specification featuring Apple's Liquid Glass design language with glassmorphism effects, component library, and screen-by-screen redesign plans
- **[Home Page Design Specification](design/LiquidGlassUIDesignPlan.md#home-page-design-specification)** - Detailed specification for the unauthenticated landing page, including layout, components, and responsive design considerations

### 📋 Planning Documentation (`docs/planning/`)
Project planning, user journey analysis, and development roadmap.

- **[MVP Plan and User Journey](planning/MVP_Plan_and_User_Journey.md)** - Comprehensive MVP development plan with 90% completion status, detailed user personas, journey mapping, and success metrics
- **[Initial Technical Architecture Plan](planning/MVP_Plan_and_User_Journey.md#initial-technical-architecture-plan)** - Original technical architecture specification including data models, API integration, and implementation phases

### 🔧 Technical Documentation (`docs/technical/`)
Technical implementation details and architecture decisions.

- **[Initial Technical Architecture Plan](planning/MVP_Plan_and_User_Journey.md#initial-technical-architecture-plan)** - Detailed technical specification covering MVVM architecture, API integration, persistence layer, and implementation phases (merged into planning document)

## 🚀 Quick Start

1. **New to the project?** Start with the [MVP Plan and User Journey](planning/MVP_Plan_and_User_Journey.md) to understand the project scope and current status
2. **Designing new features?** Refer to the [Liquid Glass UI Design Plan](design/LiquidGlassUIDesignPlan.md) for design system guidelines
3. **Implementing features?** Check the [Technical Architecture Plan](technical/plan.md) for implementation details
4. **Working on the home page?** See the [Home Page Design Specification](design/LiquidGlassUIDesignPlan.md#home-page-design-specification)

## 📊 Project Status

- **MVP Completion**: 90% ✅
- **Core Features**: Bookshelf scanning, AI recognition, library management, reading progress tracking
- **Design System**: Liquid Glass UI with glassmorphism effects
- **Architecture**: MVVM with Firebase backend and offline support

## 🔗 Cross-References

- Main project README: [`../README.md`](../README.md)
- Source code: [`../Sources/`](../Sources/)
- Firebase configuration: [`../Resources/GoogleService-Info.plist`](../Resources/GoogleService-Info.plist)

## 📝 Contributing to Documentation

When adding new documentation:
1. Place files in the appropriate subdirectory (`design/`, `planning/`, or `technical/`)
2. Update this index with the new document
3. Add cross-references where appropriate
4. Follow the existing naming and formatting conventions

## 📞 Support

For questions about the documentation or codebase, refer to the main project README or check the individual document sections for contact information.