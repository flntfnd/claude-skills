# Accessibility

The system handles a lot automatically. Don't fight it.

Reduced Transparency: system increases frosting for clarity. Glass falls back gracefully.
Increased Contrast: system adds stark colors, borders, and higher-contrast backgrounds to glass elements.
Reduced Motion: minimize or eliminate animations. Use opacity transitions. Liquid Glass disables elastic interactions automatically.
Dynamic Type: all text must scale. No fixed-height containers that truncate text.
VoiceOver: all interactive elements need accessibility labels. Glass buttons need explicit labels.
Touch targets: 44x44pt minimum. Always. Do not reduce tap areas to fit a visually tighter glass composition.

The three system adaptations above fire automatically when users enable them. Always test with each one active. The reduced transparency fallback is the most commonly missed -- your glass UI must still communicate hierarchy and depth without the translucency effect.

```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency

.glassEffect(reduceTransparency ? .identity : .regular)
```

Contrast ratios:
- Normal text: 4.5:1
- Large text: 3:1
- Interactive elements: 3:1

These ratios must be verified **with the glass blur applied** against the actual content behind the glass, not against the glass fill color alone. The blur can significantly reduce effective contrast depending on what's beneath it -- test against the worst-case background your content will appear over.

iOS 27 / macOS 27 ship a system-wide Liquid Glass intensity slider (Settings > Appearance > Liquid Glass, ranging from ultra clear to fully tinted), independent of the existing Reduced Transparency toggle. `.glassEffect()` elements respond to it automatically with no code changes, but design review should still account for both this user-controlled intensity range and the app-level `accessibilityReduceTransparency` fallback -- a user can combine the two. See `whats-new-ios27.md`.
