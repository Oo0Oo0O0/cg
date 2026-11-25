// iChannel0 - bufferA
// iChannel1 - keyboard

#define CAR_DATA ivec2(0,0)
#define SIMPLE_OBSTACLES_DATA ivec2(1,0)
#define COMPLEX_OBSTACLE_DATA ivec2(2,0)

vec4 read(ivec2 slot) {
    return texelFetch(iChannel0, slot, 0);
}

bool keyPressed(int code) {
    return texelFetch(iChannel1, ivec2(code, 0), 0).x > 0.0;
}

// hopefully random enough ._.
float random() {
    vec4 car = read(CAR_DATA);
    return fract(sin((float(iFrame)) * car.y) * (car.z + iTime));
}

vec2 slerp(vec2 a, vec2 b, float t) {
    float o = dot(a, b);
    return (sin((1.0-t)*o)/sin(o))*a+(sin(t*o)/sin(o))*b;
}

// x, y - position, z - angle
vec4 updateCarData() {
    vec4 data = read(CAR_DATA);
    
    // get movement vector
    vec2 moveVector = vec2(0.0);
    if (keyPressed(65)) moveVector.x -= 1.0; // a
    if (keyPressed(68)) moveVector.x += 1.0; // d
    if (keyPressed(87)) moveVector.y += 1.0; // w
    if (keyPressed(83)) moveVector.y -= 1.0; // s

    if (length(moveVector) != 0.0) {
        data.xy += normalize(moveVector) * iTimeDelta;
        
        // very unique and cool angle calculation (no)
        vec2 oldV = vec2(cos(data.z), sin(data.z));
        vec2 resultV = slerp(oldV, moveVector, iTimeDelta * 10.0);
        data.z = atan(resultV.y, resultV.x);
    }

    return data;
}

vec4 updateSimpleObstaclesData() {
    vec4 data = read(SIMPLE_OBSTACLES_DATA);
    
    float speed = 0.8;
    
    // obstacle1
    if (data.y < -1.3) {
        data.xy = vec2((random()-0.5)*2.0, 1.3);
    } else {
        data.y -= iTimeDelta * speed;
    }
    
    // obstacle2
    if (data.w > 1.3) {
        data.zw = vec2((random()-0.5)*1.5, -1.3);
    } else {
        data.w += iTimeDelta * speed * 0.8;
    }
        
    return data;
}

vec4 updateComplexObstacleData() {
    vec4 data = read(COMPLEX_OBSTACLE_DATA);
    
    float defaultDelay = 2.0;
    float defaultSpeed = 5.0;
    
    float t = data.w;
    
    // 2 is defaultDelay
    // -2<t<0 - waiting --
    // t<-2 => t=0.001
    // 0<t<2 - flying ++
    // t>2 => t=-0.001
    if (t < -defaultDelay) data.w = 0.001;
    else if (t > defaultDelay) data.w = -0.001;
    
    // tbd: add speed
    if (t < 0.0) data.w -= iTime;
    else if (t >= 0.0) {
        vec2 dist = read(CAR_DATA).xy - data.xy;
        vec2 moveV = length(dist) <= 0.001 ? vec2(0.0) : normalize(dist);
    
        data.xy += moveV * iTimeDelta * 0.5;
        data.w += iTime;
    }
    
    return data;
    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    ivec2 ifragCoord = ivec2( fragCoord );
    if (ifragCoord.x > 2 || ifragCoord.y > 0) discard;
    
    if (all(equal(ifragCoord, CAR_DATA))) fragColor = updateCarData();
    if (all(equal(ifragCoord, SIMPLE_OBSTACLES_DATA))) fragColor = updateSimpleObstaclesData();
    if (all(equal(ifragCoord, COMPLEX_OBSTACLE_DATA))) fragColor = updateComplexObstacleData();
}
