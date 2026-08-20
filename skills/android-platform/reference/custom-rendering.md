# Custom Rendering

What separates native Android apps that feel hand-crafted from generic Compose output. Use these APIs when standard composables can't achieve the visual result.

## Contents
- [Compose Canvas](#compose-canvas)
- [AGSL (Android Graphics Shading Language)](#agsl-android-graphics-shading-language)
- [RenderEffect](#rendereffect)
- [AnnotatedString for Rich Typography](#annotatedstring-for-rich-typography)

## Compose Canvas

Direct 2D drawing inside Compose. Same power as `onDraw()` without View overhead.

```kotlin
// Waveform visualizer
@Composable
fun WaveformCanvas(samples: List<Float>) {
    Canvas(modifier = Modifier.fillMaxWidth().height(80.dp)) {
        val midY = size.height / 2
        val path = Path()

        samples.forEachIndexed { i, sample ->
            val x = size.width * i / samples.size
            val y = midY - sample * midY * 0.9f
            if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
        }

        drawPath(
            path = path,
            brush = Brush.horizontalGradient(listOf(Color.Cyan, Color(0xFF7C4DFF))),
            style = Stroke(width = 2.dp.toPx(), cap = StrokeCap.Round)
        )
    }
}

// Animated organic blob
@Composable
fun AnimatedBlob() {
    val infiniteTransition = rememberInfiniteTransition()
    val phase by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = (2 * Math.PI).toFloat(),
        animationSpec = infiniteRepeatable(
            animation = tween(4000, easing = LinearEasing)
        )
    )

    Canvas(modifier = Modifier.size(200.dp)) {
        val cx = size.width / 2
        val cy = size.height / 2
        val baseRadius = size.minDimension * 0.4f
        val points = 8

        val path = Path()
        for (i in 0..points) {
            val angle = (i.toFloat() / points) * 2f * PI.toFloat()
            val noise = sin(angle * 3 + phase) * 20f + cos(angle * 5 + phase * 0.7f) * 15f
            val r = baseRadius + noise
            val x = cx + cos(angle) * r
            val y = cy + sin(angle) * r
            if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
        }
        path.close()

        drawPath(
            path,
            brush = Brush.radialGradient(
                colors = listOf(Color(0xFF4CAF83), Color(0xFF2E7D5F).copy(alpha = 0f)),
                center = Offset(cx, cy),
                radius = baseRadius + 40f
            )
        )
    }
}
```

Compose 1.12 (paired with BOM 2026.08.00) added `MeshGradientPainter` for multi-point, hardware-accelerated mesh gradients and Wide Color Gamut support (non-sRGB color spaces like Display P3 and AdobeRGB, preserved on API 29+) — reach for these instead of hand-rolled multi-stop `Brush.radialGradient` chains when the design calls for an organic, multi-color gradient field.

## AGSL (Android Graphics Shading Language)

Android's shader language, API 33 (Tiramisu)+. GLSL-like syntax, runs on the GPU for custom visual effects.

```kotlin
// Chromatic aberration effect
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
@Composable
fun ChromaticAberration(intensity: Float, content: @Composable () -> Unit) {
    val shader = remember {
        RuntimeShader("""
            uniform shader image;
            uniform float intensity;
            
            half4 main(float2 coord) {
                half4 r = image.eval(coord + float2(intensity, 0.0));
                half4 g = image.eval(coord);
                half4 b = image.eval(coord - float2(intensity, 0.0));
                return half4(r.r, g.g, b.b, g.a);
            }
        """.trimIndent())
    }

    Box(modifier = Modifier.graphicsLayer {
        shader.setFloatUniform("intensity", intensity)
        renderEffect = RenderEffect.createRuntimeShaderEffect(shader, "image")
            .asComposeRenderEffect()
    }) {
        content()
    }
}

// Noise / grain texture shader
val grainShader = RuntimeShader("""
    uniform float2 resolution;
    uniform float time;
    uniform float intensity;
    uniform shader content;
    
    float random(float2 st) {
        return fract(sin(dot(st, float2(12.9898, 78.233))) * 43758.5453);
    }
    
    half4 main(float2 coord) {
        half4 color = content.eval(coord);
        float noise = random(coord / resolution + fract(time)) * intensity;
        return half4(color.rgb + half3(noise - intensity * 0.5), color.a);
    }
""".trimIndent())
```

## RenderEffect

Apply GPU effects to any composable, API 31 (S)+. Lower-level than AGSL but covers most blur/color needs without custom shaders.

```kotlin
// Blur behind an element (glass card effect)
@Composable
fun BlurredCard(blurRadius: Float, content: @Composable () -> Unit) {
    Box(modifier = Modifier.graphicsLayer {
        renderEffect = BlurEffect(
            radiusX = blurRadius,
            radiusY = blurRadius,
            edgeTreatment = TileMode.Clamp
        ).asComposeRenderEffect()
    }) {
        content()
    }
}

// Chain effects: blur then color matrix
val chainedEffect = RenderEffect.createChainEffect(
    RenderEffect.createBlurEffect(16f, 16f, Shader.TileMode.CLAMP),
    RenderEffect.createColorFilterEffect(
        ColorMatrixColorFilter(ColorMatrix().apply { setSaturation(1.4f) })
    )
)
```

## AnnotatedString for Rich Typography

```kotlin
// Mixed weight / color inline text
val annotated = buildAnnotatedString {
    withStyle(SpanStyle(fontSize = 48.sp, fontWeight = FontWeight.Bold)) {
        append("Design")
    }
    withStyle(SpanStyle(
        fontSize = 48.sp,
        fontWeight = FontWeight.Light,
        fontFamily = FontFamily.Serif,
        color = MaterialTheme.colorScheme.onSurfaceVariant
    )) {
        append(" system.")
    }
}

Text(
    text = annotated,
    letterSpacing = 0.05.em
)

// Paragraph-level styling
val paragraphAnnotated = buildAnnotatedString {
    withStyle(ParagraphStyle(
        lineHeight = 1.8.em,
        textIndent = TextIndent(firstLine = 16.sp)
    )) {
        append(articleBody)
    }
}
```

`BasicTextField` already supports rich formatting (`SpanStyle`/`ParagraphStyle`) on *editable* text, not just display `Text` — query it via `getSpanStyles`/`getParagraphStyles` on the field's `TextFieldState`. This predates the current release; Compose 1.12 just refined those query APIs to take a `TextRange` instead of separate start/end indices. Reach for it on any rich-text-input surface instead of a hand-rolled markdown renderer.
