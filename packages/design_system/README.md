# design_system

Material 3 design system (built on `material_ui`). No workspace dependencies
and no user-facing strings: components receive localized text as parameters.

- Tokens: `AppSpacing`, `AppRadius`, `AppSizes`, `AppDurations`, `AppColors.seed`
- Themes: `AppTheme.light()`, `AppTheme.dark()`
- Components: `AppButton`, `AppTextField`, `showAppConfirmDialog`, `showAppSnackBar`,
  `AppLoadingView`, `AppMessageView.empty/error`, `AppSectionHeader`
- Layout: `WindowSize`, `ContentConstraint`, `AdaptiveNavigationScaffold`

Tests include Android/iOS tap-target, labelling and contrast guideline checks
in both themes.
