"use client";

import React, { useMemo, useRef, useEffect, useCallback, useState, Suspense } from "react";
import { Canvas, useFrame, useThree } from "@react-three/fiber";
import { PerspectiveCamera } from "@react-three/drei";
import { EffectComposer, Noise } from "@react-three/postprocessing";
import { BlendFunction } from "postprocessing";
import * as THREE from "three";

// ─── Mouse world position ─────────────────────────────────────────
const mouseWorld = new THREE.Vector3(0, -999, 0);

function MouseTracker() {
  const { camera, gl } = useThree();
  const raycaster = useMemo(() => new THREE.Raycaster(), []);
  const plane = useMemo(() => new THREE.Plane(new THREE.Vector3(0, 1, 0), 3), []);
  const ndc = useMemo(() => new THREE.Vector2(), []);

  const onMove = useCallback((e: PointerEvent) => {
    const rect = gl.domElement.getBoundingClientRect();
    ndc.x = ((e.clientX - rect.left) / rect.width) * 2 - 1;
    ndc.y = -((e.clientY - rect.top) / rect.height) * 2 + 1;
    raycaster.setFromCamera(ndc, camera);
    const target = new THREE.Vector3();
    if (raycaster.ray.intersectPlane(plane, target)) {
      mouseWorld.copy(target);
    }
  }, [camera, gl, raycaster, ndc, plane]);

  useEffect(() => {
    gl.domElement.addEventListener("pointermove", onMove);
    return () => gl.domElement.removeEventListener("pointermove", onMove);
  }, [gl, onMove]);

  return null;
}

// ─── Noise GLSL ───────────────────────────────────────────────────
const noiseGLSL = `
  vec3 permute(vec3 x){return mod(((x*34.0)+1.0)*x,289.0);}
  float snoise(vec2 v){
    const vec4 C=vec4(0.211324865405187,0.366025403784439,-0.577350269189626,0.024390243902439);
    vec2 i=floor(v+dot(v,C.yy));vec2 x0=v-i+dot(i,C.xx);vec2 i1;
    i1=(x0.x>x0.y)?vec2(1.0,0.0):vec2(0.0,1.0);
    vec4 x12=x0.xyxy+C.xxzz;x12.xy-=i1;i=mod(i,289.0);
    vec3 p=permute(permute(i.y+vec3(0.0,i1.y,1.0))+i.x+vec3(0.0,i1.x,1.0));
    vec3 m=max(0.5-vec3(dot(x0,x0),dot(x12.xy,x12.xy),dot(x12.zw,x12.zw)),0.0);
    m=m*m;m=m*m;
    vec3 x=2.0*fract(p*C.www)-1.0;vec3 h=abs(x)-0.5;vec3 ox=floor(x+0.5);vec3 a0=x-ox;
    m*=1.79284291400159-0.85373472095314*(a0*a0+h*h);
    vec3 g;g.x=a0.x*x0.x+h.x*x0.y;g.yz=a0.yz*x12.xz+h.yz*x12.yw;
    return 130.0*dot(m,g);
  }
`;

// ─── Shared explosion state ──────────────────────────────────────
const explosionState = { value: 0 };

// ─── Terrain ──────────────────────────────────────────────────────
function Terrain() {
  const pointsRef = useRef<THREE.Points>(null);

  const { positions, randoms } = useMemo(() => {
    const geo = new THREE.PlaneGeometry(70, 70, 600, 600);
    const pos = geo.attributes.position.array as Float32Array;
    const count = pos.length / 3;
    const rands = new Float32Array(count);
    for (let i = 0; i < count; i++) rands[i] = Math.random();
    return { positions: pos, randoms: rands };
  }, []);

  const vertexShader = `
    uniform float uTime;
    uniform vec3 uMouse;
    uniform float uExplosion;
    attribute float aRandom;
    varying float vElevation;
    varying float vMouseProximity;
    varying float vEdgeFade;
    varying float vDepth;
    varying float vExplosion;
    ${noiseGLSL}
    void main(){
      vec3 pos = position;
      vec4 mp = modelMatrix * vec4(pos, 1.0);
      float dc = length(pos.xy);

      // large flowing waves (slow, organic)
      float t = uTime * 0.4;
      float wave1 = snoise(mp.xz * 0.08 + t * 0.3) * 2.0;
      float wave2 = snoise(mp.xz * 0.15 + vec2(t * 0.2, -t * 0.15)) * 1.2;
      float wave3 = snoise(mp.xz * 0.3 + vec2(-t * 0.1, t * 0.25)) * 0.5;

      // fine detail ripples
      float detail1 = snoise(mp.xz * 0.6 + t * 0.5) * 0.25;
      float detail2 = snoise(mp.xz * 1.2 + vec2(t * 0.3, t * 0.4)) * 0.12;

      // gentle concentric pulse from center
      float pulse = sin(dc * 0.4 - uTime * 0.8) * 0.4 * (1.0 - smoothstep(10.0, 30.0, dc));

      float el = wave1 + wave2 + wave3 + detail1 + detail2 + pulse;

      // edge fade
      float edgeDist = max(abs(pos.x), abs(pos.y));
      vEdgeFade = 1.0 - smoothstep(25.0, 35.0, edgeDist);

      // mouse interaction
      vec2 toMouse = uMouse.xz - mp.xz;
      float dm = length(toMouse);
      float gravity = smoothstep(4.0, 0.2, dm);
      vMouseProximity = gravity;

      float seed = aRandom * 6.2831;
      vec2 pullDir = normalize(toMouse + 0.001);
      mp.xz += pullDir * gravity * 0.6;

      float scatterAngle = seed + uTime * 2.0 + dm * 1.5;
      vec2 scatter = vec2(cos(scatterAngle), sin(scatterAngle));
      mp.xz += scatter * gravity * 1.8 * (0.5 + aRandom);

      float vertScatter = sin(seed * 3.7 + uTime * 4.0) * gravity * 1.5 * (0.3 + aRandom);
      el += vertScatter;
      el += gravity * gravity * 1.2;

      // ─── EXPLOSION ─────────────────────────────────────────
      vExplosion = uExplosion;
      if (uExplosion > 0.0) {
        // Eased explosion curve (starts slow, accelerates violently)
        float ex = uExplosion * uExplosion * uExplosion;
        float ex2 = uExplosion * uExplosion;

        // Each particle gets a unique explosion direction
        float angle1 = seed * 2.7 + aRandom * 19.3;
        float angle2 = seed * 4.1 + aRandom * 7.7;
        vec3 explodeDir = normalize(vec3(
          cos(angle1) * sin(angle2),
          sin(angle1) * 0.6 + 0.4,
          cos(angle2) * sin(angle1)
        ));

        // Radial burst from center + random scatter
        float burstForce = 60.0 * ex * (0.3 + aRandom * 0.7);
        mp.xyz += explodeDir * burstForce;

        // Chaotic spin
        float spinSpeed = uTime * (3.0 + aRandom * 8.0);
        mp.x += sin(spinSpeed + seed) * ex2 * 8.0;
        mp.z += cos(spinSpeed + seed * 1.3) * ex2 * 8.0;
        mp.y += sin(spinSpeed * 0.7 + seed * 2.1) * ex2 * 12.0;

        // Override elevation with upward surge
        el += ex * 20.0 * (0.5 + aRandom);

        // Disable edge fade during explosion
        vEdgeFade = mix(vEdgeFade, 1.0, ex2);
      }

      mp.y += el;
      vElevation = el;
      vDepth = -mp.z;

      vec4 vp = viewMatrix * mp;

      // Point size grows during explosion
      float baseSize = 18.0 * (1.0 / -vp.z);
      float explosionSize = baseSize * (1.0 + uExplosion * uExplosion * 6.0);
      gl_PointSize = mix(baseSize, explosionSize, step(0.001, uExplosion));
      gl_Position = projectionMatrix * vp;
    }`;

  const fragmentShader = `
    varying float vElevation;
    varying float vMouseProximity;
    varying float vEdgeFade;
    varying float vDepth;
    varying float vExplosion;
    void main(){
      if(vEdgeFade < 0.01 && vExplosion < 0.01) discard;

      float d = distance(gl_PointCoord, vec2(0.5));
      // Softer particles during explosion
      float softness = mix(0.5, 0.7, vExplosion);
      float alpha = 1.0 - smoothstep(0.25, softness, d);
      if(alpha < 0.01) discard;

      // monochrome elevation palette
      vec3 cDeep = vec3(0.08, 0.08, 0.08);
      vec3 cMid = vec3(0.30, 0.30, 0.30);
      vec3 cPeak = vec3(0.65, 0.65, 0.65);
      vec3 cBright = vec3(0.90, 0.90, 0.90);

      float elNorm = clamp((vElevation + 2.0) * 0.22, 0.0, 1.0);
      vec3 col;
      if(elNorm < 0.3) {
        col = mix(cDeep, cMid, elNorm / 0.3);
      } else if(elNorm < 0.7) {
        col = mix(cMid, cPeak, (elNorm - 0.3) / 0.4);
      } else {
        col = mix(cPeak, cBright, (elNorm - 0.7) / 0.3);
      }

      // subtle depth fog
      float fog = 1.0 - smoothstep(5.0, 50.0, vDepth) * 0.6;

      // mouse glow
      col = mix(col, vec3(0.95, 0.95, 0.95), vMouseProximity * 0.4);

      // ─── EXPLOSION COLOR ───────────────────────────────────
      if (vExplosion > 0.0) {
        float ex = vExplosion * vExplosion;
        // Shift to brilliant white
        vec3 explosionColor = vec3(0.95, 0.95, 0.95);
        col = mix(col, explosionColor, ex);
        // Boost brightness dramatically
        col += ex * 0.6;
        // Override fog
        fog = mix(fog, 1.0, ex);
      }

      float a = alpha * vEdgeFade * fog * (0.7 + elNorm * 0.3);

      // Boost alpha during explosion
      if (vExplosion > 0.0) {
        a = mix(a, alpha * 0.9, vExplosion * vExplosion);
      }

      gl_FragColor = vec4(col, a);
    }`;

  const uniforms = useMemo(() => ({
    uTime: { value: 0 },
    uMouse: { value: new THREE.Vector3(0, -999, 0) },
    uExplosion: { value: 0 },
  }), []);

  useFrame((state) => {
    if (pointsRef.current) {
      const mat = pointsRef.current.material as THREE.ShaderMaterial;
      mat.uniforms.uTime.value = state.clock.getElapsedTime();
      mat.uniforms.uMouse.value.copy(mouseWorld);
      mat.uniforms.uExplosion.value = explosionState.value;
    }
  });

  return (
    <points ref={pointsRef} rotation={[-Math.PI / 2, 0, 0]} position={[0, -3, -8]} renderOrder={0}>
      <bufferGeometry>
        <bufferAttribute attach="attributes-position" args={[positions, 3]} />
        <bufferAttribute attach="attributes-aRandom" args={[randoms, 1]} />
      </bufferGeometry>
      <shaderMaterial
        vertexShader={vertexShader}
        fragmentShader={fragmentShader}
        uniforms={uniforms}
        transparent
        depthWrite={false}
        blending={THREE.AdditiveBlending}
      />
    </points>
  );
}

// ─── Explosion Animator ──────────────────────────────────────────
function ExplosionAnimator({ trigger }: { trigger: boolean }) {
  const startTime = useRef<number | null>(null);
  const DURATION = 1.4; // seconds for the explosion ramp

  useFrame((state) => {
    if (trigger) {
      if (startTime.current === null) {
        startTime.current = state.clock.getElapsedTime();
      }
      const elapsed = state.clock.getElapsedTime() - startTime.current;
      const progress = Math.min(elapsed / DURATION, 1.0);
      explosionState.value = progress;
    }
  });

  return null;
}

// ─── Main Page ──────────────────────────────────────────────────────
export default function AppsPage() {
  const [exploding, setExploding] = useState(false);
  const [whiteout, setWhiteout] = useState(false);

  useEffect(() => {
    // Trigger explosion at 4 seconds
    const explosionTimer = setTimeout(() => {
      setExploding(true);
    }, 4000);

    // Start whiteout flash at 4.8 seconds
    const whiteoutTimer = setTimeout(() => {
      setWhiteout(true);
    }, 4800);

    // Navigate at 5.5 seconds
    const navTimer = setTimeout(() => {
      window.location.href = '/start';
    }, 5500);

    return () => {
      clearTimeout(explosionTimer);
      clearTimeout(whiteoutTimer);
      clearTimeout(navTimer);
    };
  }, []);

  return (
    <>
      <Canvas
        dpr={[1, 2]}
        gl={{ alpha: true, antialias: true }}
        style={{ background: "#050505", position: "fixed", top: 0, left: 0, width: "100%", height: "100%" }}
      >
        <PerspectiveCamera makeDefault position={[0, 2.5, 12]} fov={55} />
        <MouseTracker />
        <ExplosionAnimator trigger={exploding} />
        <Suspense fallback={null}>
          <Terrain />
        </Suspense>
        <EffectComposer enableNormalPass={false}>
          <Noise opacity={0.03} blendFunction={BlendFunction.OVERLAY} />
        </EffectComposer>
      </Canvas>

      {/* Whiteout overlay */}
      <div
        style={{
          position: "fixed",
          top: 0,
          left: 0,
          width: "100%",
          height: "100%",
          zIndex: 10,
          pointerEvents: "none",
          backgroundColor: "#b0b0b0",
          opacity: whiteout ? 1 : 0,
          transition: "opacity 0.7s cubic-bezier(0.4, 0, 0.2, 1)",
        }}
      />
    </>
  );
}
