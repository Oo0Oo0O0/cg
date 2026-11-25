//iChannel0 - bufferA

vec4 read(ivec2 v) {
	return texelFetch(iChannel0, v, 0);
}

mat2 rotate(float a) {
	float c = cos(a);
	float s = sin(a);
	return mat2(c, -s, s, c);
}

float sdCircle(vec2 p, float r) {
	return length(p) - r;
}

float sdRectangle(vec2 p, vec2 b) {
	vec2 d = abs(p) - b;
	return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdCar(vec2 uv) {
	vec4 carData = read(ivec2(0));

	vec2 carS = vec2(0.2, 0.3) * 0.3;
	vec2 wheelsS = carS * vec2(1.2, 0.3);
	vec2 wheelsOff = vec2(0.0, carS.y / 2.0);

	// im way too dumb to rotate it on its on, so offset should do it, magic number is pi/2
	vec2 carP = rotate(carData.z + 1.5708) * (carData.xy - uv);

	float carBody = sdRectangle(carP, carS);
	float carWheelsFront = sdRectangle(carP + wheelsOff, wheelsS);
	float carWheelsBack = sdRectangle(carP - wheelsOff, wheelsS);

	return min(carBody, min(carWheelsFront, carWheelsBack));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
	vec2 uv = (fragCoord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);

	float car = sdCar(uv);

	float obstacle1 = sdCircle(uv - read(ivec2(1,0)).xy, 0.1);
	float obstacle2 = sdCircle(uv - read(ivec2(1,0)).zw, 0.1);

	float complexObstacle = sdCircle(uv - read(ivec2(2,0)).xy, 0.1);

	vec3 col;
	float closestObst = min(obstacle1, min(complexObstacle, obstacle2));
	float closest = min(closestObst, car);
	if (closestObst <= 0.0 && car <= 0.0) {
		//intersection
		col = vec3(0.9,0.1,0.1);
	} else {
		if (closest <= 0.0) {
			col = vec3(0.65,0.85,1.0);

		} else {
			col = vec3(0.1,0.1,0.1);
		}

		// lines visualisation
		int hl = int(round(closest * 50.0 + iTime * sign(closest)));
		if (hl % 2 == 0) col += vec3(0.1);
	}

	fragColor = vec4(col, 1.0);
}
