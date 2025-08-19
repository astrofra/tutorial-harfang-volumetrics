$input vWorldPos, vModelPos, vNormal, vModelNormal, vTangent, vBinormal, vTexCoord0, vTexCoord1, vLinearShadowCoord0, vLinearShadowCoord1, vLinearShadowCoord2, vLinearShadowCoord3, vSpotShadowCoord, vProjPos, vPrevProjPos
#include <forward_pipeline.sh>

uniform vec4 uCamObj;   // xyz: camera in object-space
uniform vec4 uCylDims;  // x=R, y=yMin, z=yMax, w=edgeWidth
uniform vec4 uVolCyl;   // x=enable(>0), y=steps, z=sigma, w=jitter(0..1)
uniform vec4 uVolTint;  // rgb=tint, a=intensity

void main()
{
    // Early disable
    if (uVolCyl.x <= 0.0) { discard; }

    // Ray in OBJECT space
    vec3 ro = uCamObj.xyz;
    vec3 rd = normalize(vModelPos - ro);    // no drift: both in object-space

    // Cylinder dims (axis = +Y in object space)
    float R     = uCylDims.x;
    float yMin  = uCylDims.y;
    float yMax  = uCylDims.z;
    float edgeW = max(1e-5, uCylDims.w);

    // Analytic ray / infinite cylinder (x^2 + z^2 = R^2)
    float A = rd.x*rd.x + rd.z*rd.z;
    float B = 2.0*(ro.x*rd.x + ro.z*rd.z);
    float C = ro.x*ro.x + ro.z*ro.z - R*R;

    if (A < 1e-8) discard;                         // nearly parallel & outside
    float D = B*B - 4.0*A*C; if (D < 0.0) discard; // no hit

    float s = sqrt(D), inv2A = 0.5 / A;
    float t0 = (-B - s) * inv2A;
    float t1 = (-B + s) * inv2A;
    if (t0 > t1) { float tmp=t0; t0=t1; t1=tmp; }

    // Clamp by caps: y in [yMin, yMax]
    float y0 = ro.y + t0*rd.y;
    float y1 = ro.y + t1*rd.y;

    if (y0 < yMin) {
        if (rd.y <= 0.0) discard;
        float tc = (yMin - ro.y) / rd.y;
        if (tc > t1) discard;
        t0 = tc; y0 = yMin;
    }
    if (y1 > yMax) {
        if (rd.y >= 0.0) discard;
        float tc = (yMax - ro.y) / rd.y;
        if (tc < t0) discard;
        t1 = tc; y1 = yMax;
    }

    if (t1 <= 0.0) discard;     // behind camera
    t0 = max(t0, 0.0);          // start inside if needed

    // Raymarch
    int   steps   = max(1, int(uVolCyl.y));
    float sigma   = uVolCyl.z;               // extinction
    float jitterK = clamp(uVolCyl.w, 0.0, 1.0);

    float dt = (t1 - t0) / float(steps);
    float t  = t0 + dt * jitterK;

    float Aacc = 0.0; // accumulated alpha (premultiplied scheme)

    // Front-to-back integration with early-out
    [loop]
    for (int i = 0; i < 256; ++i) {
        if (i >= steps) break;

        vec3 p = ro + t*rd;

        // Radial soft edge
        float r     = length(p.xz);
        float edgeR = 1.0 - smoothstep(R - edgeW, R, r);

        // Soft caps
        float cap0  = smoothstep(yMin,       yMin + edgeW, p.y);
        float cap1  = 1.0 - smoothstep(yMax - edgeW, yMax, p.y);

        float dens  = edgeR * min(cap0, cap1);

        // Beer–Lambert over segment dt
        float a = 1.0 - exp(-sigma * dens * dt);

        Aacc += (1.0 - Aacc) * a;
        if ((1.0 - Aacc) < 0.01) break;  // early-out

        t += dt;
    }

    // Premultiplied output
    vec3 tint = uVolTint.rgb * uVolTint.a;   // multiply by intensity
    gl_FragColor = vec4(tint * Aacc, Aacc);
}