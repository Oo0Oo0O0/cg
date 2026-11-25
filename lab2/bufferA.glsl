// iChannel0 - bufferA
// iChannel1 - keyboard

vec4 read(ivec2 slot) {
    return texelFetch(iChannel0, slot, 0);
}

bool keyPressed(int code) {
    return texelFetch(iChannel1, ivec2(code, 0), 0).x > 0.0;
}

// xy - pitch, yaw
vec4 updateCamOri() {
    vec4 data = read(CAM_ORI_DATA);
    
    vec2 diff = vec2(0.0);
    if (keyPressed(KEY_A)) diff.y += 1.0;
    if (keyPressed(KEY_D)) diff.y -= 1.0;
    if (keyPressed(KEY_W)) diff.x += 1.0;
    if (keyPressed(KEY_S)) diff.x -= 1.0;
    
    if (length(diff) != 0.0) {
        data.xy += diff * CAM_SENS * iTimeDelta;
        
        data.x = clamp(data.x, -10.0 * PI/180.0, 40.0 * PI/180.0);
    }
    
    return data;
}

// x - projectiles launched total
// y - last shot iTime
// z - shoot flag
vec4 updateProjData() {
    vec4 data = read(PROJ_DATA);
    
    if (keyPressed(KEY_SPACE) && iTime - data.y > SHOOT_CD) {
        data.xyz = vec3(data.x + 1.0, iTime, 1.0);
        
    } else data.z = 0.0;
    
    return data;
}

// xyz - pos
// w - does exists? (rendering & in general)
vec4 updateProjPos(int x) {
    vec4 proj_data = read(PROJ_DATA);
    vec4 pos_data = read(ivec2(x, PROJ_POS_Y));
    vec4 force_data = read(ivec2(x, PROJ_FORCE_Y));
    
    if (proj_data.z == 1.0 && int(proj_data.x) % PROJ_CAP == x) {
        pos_data = vec4(0.0, 2.0, 0.0, 1.0);
        
    } else if (pos_data.w == 1.0) {
        pos_data.xyz += force_data.xyz * iTimeDelta * 10.0; // temp speed hardcode
        
        if (pos_data.y < -10.0) pos_data.w = 0.0; // destroy
    }

    return pos_data;
}

// xyz - vec
// w - does exist? (4 initial set up)
vec4 updateProjForce(int x) {
    vec4 pos_data = read(ivec2(x, PROJ_POS_Y));
    vec4 force_data = read(ivec2(x, PROJ_FORCE_Y));
    vec4 ori_data = read(PL_ORI_DATA);
    
    if (pos_data.w == 1.0) {
        // new force setup
        if (force_data.w == 0.0) force_data.xyzw = vec4(-sin(ori_data.y), ori_data.x, -cos(ori_data.y), 1.0);
        else force_data.xyz = normalize(force_data.xyz + vec3(0.0, -1.0, 0.0) * iTimeDelta);
        
    } else force_data.w = 0.0;

    return force_data;
}

// xyz - size
vec4 updatePlayerSize() {
    return vec4(TC_BODY_DEF_SIZE, 1.0);
}

// glorified vfx (just a small barrel move delay lol)
vec4 updatePlayerOri() {
    vec4 ori_data = read(PL_ORI_DATA);
    vec4 cam_data = read(CAM_ORI_DATA);
    
    ori_data = mix(ori_data, cam_data, iTimeDelta * ORI_ALLIGN_SPEED);
    
    return ori_data;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    ivec2 ifragCoord = ivec2(fragCoord);
    
    // a bit ugly, but it is what it is 
    // (needs manual changes in case of additional data slots)
    if (
        (ifragCoord.y == 0 && ifragCoord.x > 3) ||
        ((ifragCoord.y == 1 || ifragCoord.y == 2) && (ifragCoord.x >= PROJ_CAP)) ||
        (ifragCoord.y > 2)
    ) discard;
    
    if (all(equal(ifragCoord, CAM_ORI_DATA))) fragColor = updateCamOri(); else
    if (all(equal(ifragCoord, PROJ_DATA))) fragColor = updateProjData(); else
    if (all(equal(ifragCoord, PL_SIZE_DATA))) fragColor = updatePlayerSize(); else
    if (all(equal(ifragCoord, PL_ORI_DATA))) fragColor = updatePlayerOri(); else
    
    if (ifragCoord.y == PROJ_POS_Y) fragColor = updateProjPos(ifragCoord.x); else
    if (ifragCoord.y == PROJ_FORCE_Y) fragColor = updateProjForce(ifragCoord.x);
}
