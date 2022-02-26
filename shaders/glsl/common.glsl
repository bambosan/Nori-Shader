precision highp float;
uniform float TOTAL_REAL_WORLD_TIME;

const float pi = 3.14159265;
const float hpi = 1.57079633;
const float invpi = 0.31830989;
const float tau = 6.28318531;
const float invtau = 0.15915494;

#define max0(x) max(0.0, x)
#define saturate(x) clamp(x, 0.0, 1.0)
#define rotate2d(r) mat2(cos(r), sin(r), -sin(r), cos(r))
#define wrain smoothstep(0.6, 0.3, FOG_CONTROL.x)

// Uchimura 2017, "HDR theory and practice"
// Math: https://www.desmos.com/calculator/gslcdxvipg
// Source: https://www.slideshare.net/nikuque/hdr-theory-and-practicce-jp
vec3 uchimura(vec3 x, float P, float a, float m, float l, float c, float b) {
	float l0 = ((P - m) * l) / a;
	float L0 = m - m / a;
	float L1 = m + (1.0 - m) / a;
	float S0 = m + l0;
	float S1 = m + a * l0;
	float C2 = (a * P) / (P - S1);
	float CP = -C2 / P;

	vec3 w0 = vec3(1.0 - smoothstep(0.0, m, x));
	vec3 w2 = vec3(step(m + l0, x));
	vec3 w1 = vec3(1.0 - w0 - w2);

	vec3 T = vec3(m * pow(x / m, vec3(c)) + b);
	vec3 S = vec3(P - (P - S1) * exp(CP * (x - S0)));
	vec3 L = vec3(m + a * (x - m));
	return T * w0 + L * w1 + S * w2;
}
vec3 uchimura(vec3 x) {
	const float P = 1.0;  // max display brightness
	const float a = 1.0;  // contrast
	const float m = 0.22; // linear section start
	const float l = 0.4;  // linear section length
 	const float c = 1.33; // black
	const float b = 0.0;  // pedestal
	return uchimura(x, P, a, m, l, c, b);
}

float bayer2(vec2 coord){
	coord = floor(coord);
	return fract(dot(coord, vec2(0.5, coord.y * 0.75)));
}
float bayer4(vec2 coord){
	return bayer2(0.5 * coord) * 0.25 + bayer2(coord);
}
float bayer8(vec2 coord){
	return bayer4(0.5 * coord) * 0.25 + bayer2(coord);
}
float lum(vec3 col){
	return dot(col, vec3(0.2125, 0.7154, 0.0721));
}
const vec3 rco = vec3(SKY_COEFF_R, SKY_COEFF_G, SKY_COEFF_B);
#define mco mix(SKY_MIE_COEFF, 0.5, wrain)
#define scf(coeff, coeff2, d) (coeff * d + coeff2 * d)
mat3 gab(vec3 od){
#define ab(coeff, coeff2, d) exp(-scf(coeff, coeff2, d))
	vec3 sab = ab(rco, mco, od.x), mab = ab(rco, mco, od.y), vab = ab(rco, mco, od.z);
#undef ab
	return mat3(sab, mab, vab);
}
vec2 pt(vec3 pos){
	float d = -pos.y * 1500.0;
	return vec2(sqrt(365e3 + d * d - 36e4) + d, sqrt(373e3 + d * d - 36e4) + d);
}
float rp(float cost){ return 0.375 * (cost * cost + 1.0); }
float mp(float cost, float g){
	float g2 = g * g;
	return (1.0 / 4.0 * pi) * ((1.0 - g2) / pow(1.0 + g2 - 2.0 * g * cost, 1.5));
}
vec3 catm(vec3 pos, vec3 spos, vec3 zc){
	float mieg = mix(SKY_MIE_G, 0.3, wrain);
	float scdist = saturate(1.0 - distance(pos, spos)), mcdist = saturate(1.0 - distance(pos, -spos));
	float vod = pt(pos).x, sod = pt(spos).y, mood = pt(-spos).y;
	mat3 abc = gab(vec3(sod, mood, vod));
#define tsc(a, a2, s, s2, p) (abs(a - a2) / abs(s - s2)) * p
	float drp = rp(scdist), dmp = mp(scdist, 0.0 + mieg * exp2(-vod * 0.005));
	vec3 dsc = tsc(abc[0], abc[2], scf(rco, mco, sod), scf(rco, mco, vod), scf(rco * drp, mco * dmp, vod)) * (zc + tau * exp2(-vod * 0.01));
	float nrp = rp(mcdist), nmp = mp(mcdist, 0.0 + mieg * exp2(-vod * 0.005));
	vec3 nsc = tsc(abc[1], abc[2], scf(rco, mco, mood), scf(rco, mco, vod), scf(rco * nrp, mco * nmp, vod)) * exp2(-vod * 0.01);
#undef tsc
		nsc = mix(vec3(length(nsc)), nsc, SKY_NIGHT_SATURATION) * invpi;
	return (dsc * 0.5 + zc * 0.5) + nsc;
}
vec3 catm(vec3 pos, vec3 spos){
	vec3 zc = catm(vec3(0,1,0), spos, vec3(0));
	return catm(pos, spos, zc);
}
#undef scf
float gdi(vec3 spos, vec3 dpos, float size){
	float angle = saturate((1.0 - dot(spos, dpos)) * size);
	return cos(angle * hpi);
}
vec3 csky(vec3 pos, vec3 spos, vec3 sc, vec3 mc){
	vec3 res = catm(pos, spos);
		res += sc * 50.0 * gdi(pos, spos, 3e3);
		res += mc * 10.0 * gdi(pos, -spos, 6e3);
	return res;
}
#ifdef ENABLE_CLOUD
const float cminh = CLOUD_HEIGHT;
const float cmaxh = CLOUD_HEIGHT + CLOUD_THICKNESS;
float hash21(vec2 p){
	return fract(43757.5453 * sin(dot(p, vec2(12.9898, 78.233))));
}
float map(float value, float min1, float max1, float min2, float max2) { return min2 + (value - min1) * (max2 - min2) / (max1 - min1); }
float ccd(vec3 pos){
	if(pos.y < cminh || pos.y > cmaxh) return 0.0;
	float hf = (pos.y - cminh) / CLOUD_THICKNESS;
	float ha = saturate(map(hf, 0.0, 0.1, 0.0, 1.0) * map(hf, 0.9, 1.0, 1.0, 0.0));
	return saturate(step(0.9, hash21(floor(pos.xz * 1.8e-3 + TOTAL_REAL_WORLD_TIME * 0.05))) * ha - 0.5) * 0.03;
}
float mpc(float cost){
	float mie1 = mp(cost, CLOUD_MIE_DIRECTIONAL_G), mie2 = mp(cost, -0.05);
	return mix(mie2, mie1, CLOUD_MIE_STRENGTH);
}
vec2 ccl(vec3 rpos, vec3 spos, float cdens, float cost, float cod, float tr){
	float ss = CLOUD_THICKNESS / float(CLOUD_LIGHT_STEPS);
	float cl = 0.0;
	for(int i = 0; i < CLOUD_LIGHT_STEPS; i++, rpos += spos * ss) cl += ccd(rpos) * ss;
	float ph = mpc(cost), pd = 1.0 - exp(-cdens * 2.0);
	return vec2((1.0 - cod) * exp(-cl) * tr * pd * ph, (1.0 - cod) * tr);
}
float sint(float yalt, float h){
	float r = 6371e3 + h, ds = yalt * 6371e3;
	return -ds + sqrt((ds * ds) + (r * r) - 4.058964e13);
}
vec4 ccv(vec3 pos, vec3 spos, vec3 sc, vec3 mc, vec3 zc, float dither){
	vec3 ro = pos * sint(pos.y, cminh), endp = pos * sint(pos.y, cmaxh);
	vec3 rd = (endp - ro) / float(CLOUD_STEPS);
		ro = ro + rd * dither;
	float tr = 1.0, codl = 0.0, cost = dot(pos, spos);
	vec2 tclsc = vec2(0.0);
	for(int i = 0; i < CLOUD_STEPS; i++, ro += rd){
		float cdens = ccd(ro) * length(rd);
		if(cdens <= 0.0) continue;
		float cod = exp(-cdens);
		tclsc += ccl(ro, spos, cdens, cost, cod, tr);
		tr *= cod;
    }
	return mix(vec4(tclsc.x * (sc + mc) + (tclsc.y * zc * 0.3), tr), vec4(0.0, 0.0, 0.0, 1.0), saturate(length(ro) * 7e-5));
}
#endif
void clig(vec3 spos, out vec3 sc, out vec3 monc, out vec3 szcol){
	float sod = pt(spos).y, mood = pt(-spos).y;
	sc = gab(vec3(sod))[0], monc = gab(vec3(mood))[0];
	szcol = catm(vec3(0, 1, 0), spos);
	sc *= 3.0, monc = vec3(lum(monc)) * 0.15, szcol *= 3.0;
}
vec3 colc(vec3 col){
	col *= EXPOSURE_MULTIPLICATION;
	col = uchimura(col);
	col = pow(col, vec3(1.0 / 2.2));
	col = mix(vec3(lum(col)), col, SATURATION);
	return col;
}
void clpos(out vec3 tlp, out vec3 lp){
	#ifdef ENABLE_DYNAMIC_LIGHT_ANGLE
		float ang = TOTAL_REAL_WORLD_TIME * DYNAMIC_LIGHT_ANGLE_SPEED;
		lp = normalize(vec3(cos(ang), sin(ang), 0.0));
	#else
		lp = normalize(vec3(cos(radians(SUN_LIGHT_ANGLE)), sin(radians(SUN_LIGHT_ANGLE)), 0.0));
	#endif
	lp.yz *= rotate2d(radians(SUN_PATH_ROTATION));
	tlp = lp.y > 0.0 ? lp : -lp;
}
