shader_type canvas_item;

uniform sampler2D vegetation : filter_nearest;
uniform sampler2D flowmap : filter_nearest;
uniform sampler2D noise;

const float WIDTH = 25.0;
const float CREASE_DIST = 0.02;

vec2 getFlowUV(vec2 tUv, vec2 pUv, vec2 displace){
	return (fract(tUv + displace) / WIDTH) + pUv;
}

vec4 getVegitation(vec2 uv, float time){
	vec4 vegTex = texture(vegetation, uv);
	float noiseSample = texture(noise, fract((uv * 0.5) + (time * vec2(0.3, 0.0)))).r;
	float creaseMask = (1.0 - vegTex.r);
	float radius = CREASE_DIST * noiseSample * noiseSample * creaseMask * creaseMask * creaseMask;
	vec4 total = vec4(0.0);
	
	for (int i = 0; i < 16; i++){
		float rad = (3.1416 * float(i)) / 8.0;
		vec2 samplePoint = vec2(cos(rad) * radius, sin(rad) * radius);
		vec4 texSample = texture(vegetation, uv + samplePoint);
		total += texSample;
	}
	
	total /= 16.0;
	
	total = min(vegTex, total);
	
	return total;
}

void fragment() {
	vec2 texFlow = (texture(flowmap, UV).xy * 2.0) - 1.0;
	float time = TIME * 0.2;
	vec2 tUv = fract(UV * WIDTH);
	vec2 pUv = floor(UV * WIDTH) / WIDTH;
	
	texFlow = normalize(texFlow);
	texFlow.x *= -1.0;
	
	//get flow UVs
	vec2 displace = time * texFlow;
	vec2 uv1 = getFlowUV(tUv, pUv, displace);
	vec2 uv2 = getFlowUV(tUv, pUv, displace + 0.5);
	
	//compute terrain flow displace
	vec3 terrainFlow = texture(TEXTURE, uv1).xyz;
	vec3 terrainOrig = texture(TEXTURE, UV).xyz;
	terrainFlow = min(terrainOrig, terrainFlow);
	vec3 terrain = mix(terrainOrig, terrainFlow, 0.5);
	
	//composite back in vegitation
	vec4 texVeg = getVegitation(UV, time);
	vec3 composite = mix(terrain, texVeg.xyz, texVeg.a);
	
	COLOR = vec4(composite, 1.0);
}
