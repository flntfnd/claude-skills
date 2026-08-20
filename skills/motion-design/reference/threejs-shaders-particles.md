# Three.js: Shaders, Post-Processing & Particles

GLSL techniques for scroll-driven image reveals, the post-processing pipeline, style-specific shader looks, and GPU particle systems. See [threejs-core.md](threejs-core.md) for renderer setup, materials, lighting, and memory management first -- everything here assumes a working `WebGLRenderer` scene already exists.

## Contents

- [Image Reveal Shaders](#image-reveal-shaders)
- [Post-Processing](#post-processing)
- [Style-Specific Shaders](#style-specific-shaders)
- [Particle Systems](#particle-systems)

## Image Reveal Shaders

```glsl
// Fragment shader: scroll-triggered image reveal with distortion
uniform sampler2D uTexture;
uniform float uProgress;    // 0 = hidden, 1 = revealed (driven by scroll)
uniform float uTime;

varying vec2 vUv;

void main() {
    vec2 uv = vUv;

    // Distortion wave that sweeps across on reveal
    float wave = sin(uv.y * 12.0 + uTime * 2.0) * 0.05 * (1.0 - uProgress);
    uv.x += wave;

    // Reveal mask from left to right
    float reveal = smoothstep(uProgress - 0.1, uProgress + 0.1, uv.x);

    vec4 color = texture2D(uTexture, uv);
    gl_FragColor = vec4(color.rgb, color.a * reveal);
}
```

```javascript
// Animate uniform with GSAP
gsap.to(material.uniforms.uProgress, {
    value: 1.0,
    duration: 1.2,
    ease: "exponential",
    scrollTrigger: {
        trigger: imageElement,
        start: "top 70%",
        once: true
    }
});
```

## Post-Processing

Requires `three/addons/postprocessing`. Full visual upgrade for Futuristic, Glassmorphism, and Y2K styles.

`EffectComposer` (below) is the classic WebGL post-processing pipeline: a linear list of passes, each rendering a full-screen quad. It still works and is what most existing production code uses. Three.js has since introduced `RenderPipeline` (a node-based post-processing system paired with `WebGPURenderer`, renamed from an earlier `PostProcessing` class) as the forward-looking replacement -- it shares render targets across passes instead of re-rendering the scene per effect, which matters once you stack more than two or three passes. **[Unverified]** the exact `RenderPipeline` API for wiring up bloom/film-grain/FXAA equivalents isn't reproduced here since it wasn't confirmed against current docs during this pass; if starting a new WebGPU-first project, check `threejs.org/docs/pages/RenderPipeline.html` (or the current equivalent page) before assuming the pass-based code below maps 1:1.

```javascript
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';
import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';

const composer = new EffectComposer(renderer);
composer.addPass(new RenderPass(scene, camera));

// Bloom (Futuristic/Sci-Fi: makes glowing elements actually glow)
const bloomPass = new UnrealBloomPass(
    new THREE.Vector2(window.innerWidth, window.innerHeight),
    0.8,    // strength
    0.4,    // radius
    0.85    // threshold -- only pixels above this luminance bloom
);
composer.addPass(bloomPass);

// Film grain and scanlines (Y2K)
import { FilmPass } from 'three/addons/postprocessing/FilmPass.js';
const filmPass = new FilmPass(
    0.35,   // noise intensity
    0.025,  // scanline intensity
    648,    // scanline count
    false   // grayscale
);
composer.addPass(filmPass);

// FXAA anti-aliasing (always add as last pass before OutputPass)
import { ShaderPass } from 'three/addons/postprocessing/ShaderPass.js';
import { FXAAShader } from 'three/addons/shaders/FXAAShader.js';
const fxaaPass = new ShaderPass(FXAAShader);
fxaaPass.uniforms['resolution'].value.set(
    1 / window.innerWidth,
    1 / window.innerHeight
);
composer.addPass(fxaaPass);
composer.addPass(new OutputPass());

// Use composer.render() instead of renderer.render() in the loop
function animate() {
    requestAnimationFrame(animate);
    composer.render();
}
```

## Style-Specific Shaders

Each visual style has a corresponding shader or post-processing approach. Use these as the GPU layer for the style.

**Futuristic / Sci-Fi -- grid + neon glow:**
```glsl
/* Fragment shader for glowing grid plane */
uniform float uTime;
uniform vec3 uAccentColor;
varying vec2 vUv;

void main() {
    // Grid lines
    vec2 grid = abs(fract(vUv * 20.0 - 0.5) - 0.5) / fwidth(vUv * 20.0);
    float gridLine = 1.0 - min(min(grid.x, grid.y), 1.0);

    // Animated glow pulse
    float pulse = 0.5 + 0.5 * sin(uTime * 0.5);
    float glow = gridLine * (0.6 + pulse * 0.4);

    // Fade to edges (vignette)
    float dist = length(vUv - 0.5) * 2.0;
    float fade = 1.0 - smoothstep(0.6, 1.0, dist);

    vec3 color = uAccentColor * glow * fade;
    float alpha = glow * fade;

    gl_FragColor = vec4(color, alpha);
}
```

**Organic / Biomorphic -- noise displacement:**
```glsl
/* Vertex shader: noise-displaced geometry */
uniform float uTime;
varying vec2 vUv;

// Classic 3D simplex noise (include via glsl-noise package or inline)
// float snoise(vec3 v) { ... }

void main() {
    vUv = uv;
    vec3 pos = position;

    // Displace vertices along normals using noise
    float noiseVal = snoise(pos * 1.5 + uTime * 0.2) * 0.3;
    pos += normal * noiseVal;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}
```

**Y2K / Retro -- CRT post-processing:**
```glsl
/* Full-screen CRT effect as ShaderPass */
uniform sampler2D tDiffuse;
uniform float uTime;
varying vec2 vUv;

void main() {
    // Slight barrel distortion
    vec2 uv = vUv - 0.5;
    float dist = length(uv);
    uv *= 1.0 + dist * dist * 0.1;
    uv += 0.5;

    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // Chromatic aberration
    float aberration = 0.002;
    vec4 color;
    color.r = texture2D(tDiffuse, uv + vec2(aberration, 0.0)).r;
    color.g = texture2D(tDiffuse, uv).g;
    color.b = texture2D(tDiffuse, uv - vec2(aberration, 0.0)).b;
    color.a = 1.0;

    // Scanlines
    float scanline = sin(uv.y * 800.0) * 0.04;
    color.rgb -= scanline;

    // Phosphor glow / green tint
    color.g *= 1.1;

    // Flicker
    float flicker = 0.97 + 0.03 * sin(uTime * 60.0);
    color.rgb *= flicker;

    // Vignette
    float vig = (0.5 - dist * 0.8);
    color.rgb *= clamp(vig * 2.0, 0.0, 1.0);

    gl_FragColor = color;
}
```

**Glassmorphism -- depth-of-field blur:**
```javascript
import { BokehPass } from 'three/addons/postprocessing/BokehPass.js';

const bokehPass = new BokehPass(scene, camera, {
    focus: 5.0,      // focal distance
    aperture: 0.002, // f/stop -- higher = more blur
    maxblur: 0.01    // clamp
});
composer.addPass(bokehPass);

// Animate focus pull with GSAP
gsap.to(bokehPass.uniforms['focus'], {
    value: 2.0,
    duration: 1.5,
    ease: 'power2.inOut',
    scrollTrigger: { trigger: '.glass-section', start: 'top center' }
});
```

## Particle Systems

```javascript
// GPU particle system using Points geometry
const count = 3000;
const positions = new Float32Array(count * 3);
const scales = new Float32Array(count);

for (let i = 0; i < count; i++) {
    positions[i * 3]     = (Math.random() - 0.5) * 20;  // x
    positions[i * 3 + 1] = (Math.random() - 0.5) * 20;  // y
    positions[i * 3 + 2] = (Math.random() - 0.5) * 20;  // z
    scales[i] = Math.random();
}

const geometry = new THREE.BufferGeometry();
geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
geometry.setAttribute('aScale', new THREE.BufferAttribute(scales, 1));

const particleMaterial = new THREE.ShaderMaterial({
    vertexShader: /* glsl */ `
        attribute float aScale;
        uniform float uTime;
        varying float vScale;

        void main() {
            vScale = aScale;
            vec4 modelPosition = modelMatrix * vec4(position, 1.0);

            // Gentle float animation
            modelPosition.y += sin(uTime + position.x * 0.5) * 0.1;

            gl_Position = projectionMatrix * viewMatrix * modelPosition;
            gl_PointSize = aScale * 3.0 * (300.0 / -gl_Position.z);
        }
    `,
    fragmentShader: /* glsl */ `
        varying float vScale;

        void main() {
            // Circular point with soft edges
            float dist = distance(gl_PointCoord, vec2(0.5));
            float alpha = 1.0 - smoothstep(0.4, 0.5, dist);
            gl_FragColor = vec4(1.0, 1.0, 1.0, alpha * vScale * 0.6);
        }
    `,
    uniforms: { uTime: { value: 0 } },
    transparent: true,
    depthWrite: false,
    blending: THREE.AdditiveBlending  // Additive: particles brighten overlaps
});

const particles = new THREE.Points(geometry, particleMaterial);
scene.add(particles);
```
