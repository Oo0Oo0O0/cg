vec2 rotate(in float x, in float y, in float r) {
	return vec2(x * cos(r) - y * sin(r), x * sin(r) + y * cos(r));
}

float sdCircle(in vec2 dist, in float rad) {
	return length(dist) - rad;
}

// AFTER 2 HOURS OF PURE GEOMETRY HOLY SHIT IT ACTUALLY WORKS
// prob couldve made it sooner if i wasnt so dumb ._.
float sdLine(in vec2 pos, in vec2 origin, in vec2 endpoint) {
	float a = length(pos - endpoint);
	float b = length(pos - origin);
	float c = length(origin - endpoint);

	float cosA = (pow(b, 2.0) + pow(c, 2.0) - pow(a, 2.0)) / (2.0 * b * c);
	float seg = b * cosA;
	float cosB = (c - seg) / a;

	if (cosA < 0.0 || cosB < 0.0) { return min(a, b); }

	float x = sqrt((b - seg) * (b + seg));
	return x;
}

// ok this is actually clever collision detection
// https://math.stackexchange.com/questions/190111/how-to-check-if-a-point-is-inside-a-rectangle
float sdRectangle(in vec2 pos, in vec2 center, in vec2 half_size, in float rad) {
	// a b
	// c d

	vec2 a = center + rotate(-half_size.x,  half_size.y, rad);
	vec2 b = center + rotate( half_size.x,  half_size.y, rad);
	vec2 c = center + rotate(-half_size.x, -half_size.y, rad);
	vec2 d = center + rotate( half_size.x, -half_size.y, rad);

	vec2 CX = pos - c;
	vec2 CA = a - c;
	vec2 CD = d - c;

	float CXCA = CX.x * CA.x + CX.y * CA.y;
	float CXCD = CX.x * CD.x + CX.y * CD.y;
	float CACA = CA.x * CA.x + CA.y * CA.y;
	float CDCD = CD.x * CD.x + CD.y * CD.y;

	if (CXCA > 0.0 && CXCA < CACA && CXCD > 0.0 && CXCD < CDCD) { return 0.0; }

	return min(sdLine(pos, a, b), min(sdLine(pos, b, d), min(sdLine(pos, d, c), sdLine(pos, c, a))));
}

float sdCar(in vec2 pos, in vec2 center, in float rotation) {
	// f
	// c
	// b

	vec2 half_size = vec2(.05, .1);
	vec2 wheels_half_size = vec2(.07, .04);
	float wheels_offset = .05;

	vec2 f = center + rotate(0.0,  wheels_offset, rotation);
	vec2 b = center + rotate(0.0, -wheels_offset, rotation);

	float body = sdRectangle(pos, center, half_size, rotation);
	float front_wheel = sdRectangle(pos, f, wheels_half_size, rotation);
	float back_wheel = sdRectangle(pos, b, wheels_half_size, rotation);

	return min(body, min(front_wheel, back_wheel));
}


void mainImage(out vec4 fragColor, in vec2 fragCoord) {
	vec2 uv = fragCoord / iResolution.y;

	float t = iTime;

	float line = sdLine(uv, vec2(.6, .6), vec2(.6, .6) + vec2(cos(t), sin(t)) * .1);

	float testRec = sdRectangle(uv, vec2(0.0, 0.0), vec2(.2, .1), iTime);

	float testCar = sdCar(uv, vec2(.5, .5), iTime);

	float closest = testCar;

	// Colorising
	vec3 col = closest > 0.0 ? vec3(0.9,0.6,0.3) : vec3(0.65,0.85,1.0);

	// Lines
	int hl = int(round(closest * 50.0 + iTime * sign(closest)));
	if (hl % 2 == 0) { col += vec3(0.1); }

	fragColor = vec4(col, 1.0);
}
