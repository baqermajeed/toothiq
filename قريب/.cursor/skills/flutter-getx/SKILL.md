---
name: flutter-getx
description: Enforces Flutter development standards using GetX MVC, StatelessWidget, ScreenUtil, and clean reusable code. Use when creating or refactoring Flutter screens, controllers, or UI components.
---

# Flutter GetX Development Skill

This skill defines the official Flutter development standards for this project.

## When to Use
- When creating new Flutter screens or pages
- When writing or updating GetX controllers
- When generating UI components
- When refactoring Flutter code

## Architecture
- Always follow **GetX MVC architecture**
  - View: UI only
  - Controller: business logic and state
  - Model: data structures only
- Keep business logic out of the UI layer

## Widget Rules
- Always use **StatelessWidget**
- Do NOT use StatefulWidget unless explicitly required
- UI must remain simple and declarative

## State Management
- Use **GetX** for state management
- Declare reactive variables using `obs`
- Update UI using `Obx`
- Avoid unnecessary rebuilds

## Responsive Design
- Use **flutter_screenutil** for:
  - Widths and heights (`.w`, `.h`)
  - Font sizes (`.sp`)
  - Radius (`.r`)
- Never use hardcoded sizes

## Code Quality
- Write **clean, readable, and maintainable code**
- Avoid code duplication
- Reuse shared functions and utilities
- Extract common logic into reusable methods or helpers
- Keep files small and well-structured

## Styling
- Always follow the project's **color palette**
- Always use the project's **font family**
- Do not introduce random colors or fonts

## Best Practices
- Prefer composition over duplication
- Use meaningful variable and method names
- Keep controllers focused and minimal
- Ensure scalability and clarity in all implementations
