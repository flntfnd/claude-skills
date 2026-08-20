# Three.js / WebGL Core

For immersive, GPU-accelerated visual experiences: 3D product showcases, scroll-driven camera journeys, shader-based image reveals, particle systems. Shader and post-processing techniques (style-specific GLSL, bloom, particles) are in [threejs-shaders-particles.md](threejs-shaders-particles.md) -- this file covers renderer setup, DOM sync, materials, lighting, and memory management.

## Contents

- [Renderer: WebGL vs WebGPU](#renderer-webgl-vs-webgpu)
- [Canvas Architecture](#canvas-architecture)
- [DOM-WebGL Sync](#dom-webgl-sync)
- [Scroll-Driven Camera with GSAP](#scroll-driven-camera-with-gsap)
- [Materials and Physically-Based Rendering](#materials-and-physically-based-rendering)
- [Lighting Setup](#lighting-setup)
- [Memory Management](#memory-management)

## Renderer: WebGL vs WebGPU

Three.js is mid-migration from `WebGLRenderer` to `WebGPURenderer` as the recommended entry point for new projects -- `WebGPURenderer` is designed to fall back to WebGL2 automatically on browsers/devices without WebGPU, so it's positioned as a superset rather than a parallel track. `WebGLRenderer` remains maintained and is the right call for projects that need to stay strictly on WebGL2 (e.g. targeting older devices or avoiding the WebGPU code path entirely), but new large features are landing on the WebGPU side going forward.

The examples below use `WebGLRenderer` with classic `ShaderMaterial`/GLSL because that surface is stable, everywhere, and what most existing production code (and this skill's shader examples) is built on. `WebGPURenderer` projects author materials with TSL (Three.js Shading Language) node graphs instead of raw GLSL strings -- a different authoring model. **[Unverified]** the exact current TSL node syntax and migration path aren't reproduced here; check `threejs.org/docs/pages/WebGPURenderer.html` and the TSL docs directly before starting a WebGPU-first project, since that surface is still moving fast.

## Canvas Architecture

```javascript
import * as THREE from "three";

// Fixed canvas behind DOM content
// <div style="position:fixed; inset:0; z-index:0"><canvas /></div>
// DOM content scrolls above canvas at z-index:1+

const renderer = new THREE.WebGLRenderer({
    canvas: document.querySelector("canvas"),
    antialias: true,
    alpha: true   // Transparent background to show DOM content
});
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2)); // Cap at 2 for performance

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    100
);

// Render loop -- do not start until all assets are loaded
function animate() {
    requestAnimationFrame(animate);
    renderer.render(scene, camera);
}
```

## DOM-WebGL Sync

Synchronize Three.js elements with DOM element bounds for seamless hybrid layouts:

```javascript
function syncMeshToDOMElement(mesh, element) {
    const rect = element.getBoundingClientRect();
    const viewportHeight = window.innerHeight;
    const viewportWidth = window.innerWidth;

    // Convert DOM coordinates to Three.js NDC space
    mesh.position.x = (rect.left + rect.width / 2 - viewportWidth / 2) / viewportWidth * 2;
    mesh.position.y = -(rect.top + rect.height / 2 - viewportHeight / 2) / viewportHeight * 2;

    // Scale to match element dimensions
    mesh.scale.x = rect.width;
    mesh.scale.y = rect.height;
}

// Update on scroll (via Lenis or ScrollTrigger)
lenis.on("scroll", () => {
    syncMeshToDOMElement(imagePlane, imageElement);
});
```

## Scroll-Driven Camera with GSAP

```javascript
const cameraAnim = { x: 0, y: 2, z: 8 };

gsap.timeline({
    scrollTrigger: {
        trigger: ".scene-container",
        start: "top top",
        end: "bottom bottom",
        scrub: 1
    }
})
.to(cameraAnim, { z: 4, duration: 1, ease: "none" })
.to(cameraAnim, { y: 0, x: 1.5, z: 2, duration: 1.5, ease: "none" })
.to(cameraAnim, { x: 0, y: -1, z: 6, duration: 1, ease: "none" });

// Apply in render loop
function animate() {
    requestAnimationFrame(animate);
    camera.position.set(cameraAnim.x, cameraAnim.y, cameraAnim.z);
    camera.lookAt(0, 0, 0);
    renderer.render(scene, camera);
}
```

## Materials and Physically-Based Rendering

```javascript
// MeshStandardMaterial: PBR, responds to lights -- correct for most use cases
const material = new THREE.MeshStandardMaterial({
    color: 0x2a2a3a,
    roughness: 0.4,      // 0 = mirror, 1 = fully diffuse
    metalness: 0.8,      // 0 = dielectric, 1 = metallic
    envMapIntensity: 1.0 // how much the environment map affects the surface
});

// ShaderMaterial: full custom GLSL vertex + fragment shaders
const shaderMaterial = new THREE.ShaderMaterial({
    vertexShader: /* glsl */ `
        varying vec2 vUv;
        varying vec3 vNormal;

        void main() {
            vUv = uv;
            vNormal = normalize(normalMatrix * normal);
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
    `,
    fragmentShader: /* glsl */ `
        uniform float uTime;
        varying vec2 vUv;
        varying vec3 vNormal;

        void main() {
            vec3 color = vec3(vUv, 0.5 + 0.5 * sin(uTime));
            gl_FragColor = vec4(color, 1.0);
        }
    `,
    uniforms: {
        uTime: { value: 0 }
    }
});

// Update uniforms in render loop
shaderMaterial.uniforms.uTime.value = clock.getElapsedTime();
```

## Lighting Setup

```javascript
// Three-point lighting setup for most scenes
const ambientLight = new THREE.AmbientLight(0xffffff, 0.4);  // Soft fill
scene.add(ambientLight);

const keyLight = new THREE.DirectionalLight(0xffffff, 1.0);  // Main light
keyLight.position.set(5, 8, 5);
keyLight.castShadow = true;
scene.add(keyLight);

const fillLight = new THREE.DirectionalLight(0x4488ff, 0.3); // Cool fill
fillLight.position.set(-5, 0, -5);
scene.add(fillLight);

// Environment map: most realistic reflections for metallic/shiny materials
import { RGBELoader } from 'three/addons/loaders/RGBELoader.js';
const pmremGenerator = new THREE.PMREMGenerator(renderer);

new RGBELoader().load('/studio.hdr', (texture) => {
    const envMap = pmremGenerator.fromEquirectangular(texture).texture;
    scene.environment = envMap;     // affects all PBR materials
    scene.background = envMap;      // shows as background (optional)
    texture.dispose();
    pmremGenerator.dispose();
});
```

## Memory Management

GPU memory leaks are the #1 Three.js production problem in SPAs:

```javascript
// Dispose everything when the component or page unmounts
function disposeScene(scene) {
    scene.traverse((object) => {
        if (object.geometry) object.geometry.dispose();
        if (object.material) {
            if (Array.isArray(object.material)) {
                object.material.forEach(m => {
                    disposeMaterial(m);
                });
            } else {
                disposeMaterial(object.material);
            }
        }
    });
}

function disposeMaterial(material) {
    material.dispose();
    Object.keys(material).forEach(key => {
        if (material[key] && typeof material[key].dispose === "function") {
            material[key].dispose(); // Disposes textures
        }
    });
}

renderer.dispose();
```
