/// Animated UI widget library — ReactBits-inspired Flutter components.
///
/// Import this single file to access all 26 animated widgets:
///
/// ```dart
/// import 'package:klinik_aurora_portal/widgets/animated/animated_widgets.dart';
/// ```
///
/// ## Text Effects
/// - [SplitText]       — staggered char/word fade + slide
/// - [BlurText]        — blur-to-sharp reveal
/// - [GradientText]    — shimmer sweep gradient
/// - [TypewriterText]  — typewriter with blinking cursor
/// - [ScrambleText]    — random-char scramble reveal
/// - [GlitchText]      — RGB-split glitch effect
/// - [CountingText]    — animated number counter
///
/// ## Animated Backgrounds
/// - [ParticlesBackground] — floating particles with optional connection lines
/// - [AuroraBackground]    — drifting soft gradient blobs
/// - [GridBackground]      — dot / line / crosshatch grid
/// - [NoiseBackground]     — animated film-grain overlay
/// - [BeamsBackground]     — diagonal light-beam sweep
///
/// ## UI Components
/// - [AnimatedCard]     — pointer-driven 3-D tilt card
/// - [MagneticButton]   — magnetic pull-to-cursor button
/// - [GlassCard]        — frosted-glass card (BackdropFilter)
/// - [SpotlightCard]    — radial spotlight follows pointer
/// - [CountdownTimer]   — animated flip countdown display
/// - [AnimatedBorder]   — rotating gradient border
///
/// ## Scroll & Transition Effects
/// - [RevealOnScroll]      — fade + slide in on viewport entry
/// - [ParallaxScroll]      — translate at a fraction of scroll speed
/// - [StickyHeader]        — sticky shrinking header (Sliver-based)
/// - [StickyHeaderSliver]  — raw sliver delegate for custom scroll views
/// - [ScrollProgressBar]   — thin progress bar tracking scroll depth
///
/// ## Loading & Feedback
/// - [PulseLoader]        — ripple pulse loader
/// - [SkeletonLoader]     — shimmer placeholder wrapper
/// - [SkeletonBone]       — individual skeleton bone shape
/// - [SkeletonCard]       — ready-made skeleton card layout
/// - [SuccessCheckmark]   — animated drawn checkmark
/// - [ToastNotification]  — slide-in/out overlay toast
library;

export 'text/text_effects.dart';
export 'backgrounds/animated_backgrounds.dart';
export 'components/ui_components.dart';
export 'scroll/scroll_effects.dart';
export 'loading/loading_feedback.dart';
