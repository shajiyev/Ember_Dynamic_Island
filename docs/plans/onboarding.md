# Onboarding Implementation Plan

**Goal:** Greet the user with "hello" in the notch on the first launch, then ask in a short
window for the glow and for each feature that needs a permission.

**Spec:** docs/specs/onboarding.md.

**Build and test:** as in docs/plans/settings.md (clean `Build/Products` first; Debug and
Release with no warnings).

## Part 1: Onboarding

### Task 1: The rules
- [x] Tests first: the pages' order, Back and Continue (`OnboardingPage`); `onboarded` saved,
  off at first, untouched by Reset; `prepareForOnboarding()` turns Music off; Show Welcome
  Again found in search on About.
- [x] Tests first: the pill holds the panel open while the greeting shows (pointer leaving,
  the close delay and the shortcut do nothing) and a close request ends it
  (`PillModel`, `PillController.showWelcome`); the hello path stays in its box.

### Task 2: The greeting and the window
- [x] The written "hello" with its gradient and the timing; Reduce Motion.
- [x] The window and its six pages; first launch and Show Welcome Again; Volume &
  Brightness asks for Accessibility on Turn on. CLEAN, TEST, BUILD (Debug and Release, no
  warnings): 561 tests pass.
- [x] Asked after the check: the h rises into its loop without a corner.
- [x] The user checks on screen (first launch from a clean state, each page, closing early,
  Show Welcome Again). Checkpoint and commit.
