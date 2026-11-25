// iChannel0 - bufferA

vec4 read(ivec2 slot) {
    return texelFetch(iChannel0, slot, 0);
}

struct Object {
    float d;
    vec3 col;
};

Object emptyObj() {
    return Object(EMPTY_OBJ_D, vec3(0.0));
}

// this is a bit of a waste to have to fill this objects[] with empty ones
// but i feel like its much better then this min(_, min(_, ...)) way
// also auto color assignment is kinda nice
//
// 10 is hardcoded and not in common, cuz i need to manually insert
// 10 elements in every array
Object findClosestObj(Object objects[10]) {
    // find min
    float m = 1.0;
    for (int i = 0; i < 10; i++) {
        Object obj = objects[i];
        if (obj.d == EMPTY_OBJ_D) break;
        m = min(m, obj.d);
    }
    
    // decide color
    vec3 color;
    for (int i = 0; i < 10; i++) {
        Object obj = objects[i];
        if (obj.d != m) continue; else
        if (obj.d == EMPTY_OBJ_D) break;
        color = obj.col;
    }
    
    return Object(m, color);
}

Object sdTank(vec3 p, vec2 ori, vec3 bodySize, vec3 mainColor, bool hasMarker) {
    p += vec3(0.0, -1.0, 0.0) * bodySize.y; // height offset
    
    // main objects
    vec3 topSize = bodySize * TC_TOP_SIZE_M;
    vec3 topPos = p + vec3(0.0, -1.0, 0.0) * (topSize.y + bodySize.y);
    topPos *= rotateY(ori.y);
    
    vec3 barrelSize = bodySize * TC_BARREL_SIZE_M;
    vec3 barrelPos = topPos + vec3(0.0, 0.0, 1.0) * topSize.z;
    barrelPos *= rotateX(ori.x);
    barrelPos += vec3(0.0, 0.0, 1.0) * barrelSize.z;
    
    vec3 barrelEndSize = bodySize * TC_BARRELEND_SIZE_M;
    vec3 barrelEndPos = barrelPos + vec3(0.0, 0.0, 1.0) * barrelSize.z;
    
    // colors
    vec3 colorD = mainColor - vec3(.05);
    vec3 colorDD = mainColor - vec3(.1); // darker darker xd
    
    // a bit ugly, but marker needs to be separated
    Object closest = findClosestObj(Object[10](
        Object(sdBox(p, bodySize),                 colorDD),   // body
        Object(sdBox(topPos, topSize),             colorD),    // top
        Object(sdBox(barrelPos, barrelSize),       mainColor), // barrel
        Object(sdBox(barrelEndPos, barrelEndSize), colorD),    // barrel end
        
        emptyObj(),
        emptyObj(),
        emptyObj(),
        emptyObj(),
        emptyObj(),
        emptyObj()
    ));
    
    if (hasMarker) {
        vec3 markerCol = COLOR_ORANGE;
        vec2 markerSize = bodySize.xy * vec2(1.0, 0.1);
        vec3 markerPos = topPos + vec3(0.0, 0.0, 5.5 - ori.x * 12.0); // tbc
        markerPos.y += bodySize.y + topSize.y + barrelSize.y + barrelEndSize.y;
        
        float marker = sdCylinder(markerPos, markerSize);
        if (marker < closest.d) closest = Object(marker, markerCol);
    }
    
    return closest;
}

Object scene(vec3 p) {
    vec3 plPos = vec3(0.0);
    vec3 plSize = read(PL_SIZE_DATA).xyz;
    vec2 plOri = -read(PL_ORI_DATA).xy;
    vec3 plCol = COLOR_PURPLE;
    
    vec3 npcPos = vec3(0.0,0.0,15.0);
    vec2 npcOri = vec2(sin(iTime), cos(iTime) + PI);
    vec3 npcSize = TC_BODY_DEF_SIZE * (sin(iTime / 2.0) + 1.0);
    vec3 npcCol = plCol + vec3(0.2, -0.1, -0.1);
    
    Object closest = findClosestObj(Object[10](
        Object(sdPlane(p), COLOR_GREEN), //earth
        sdTank(p - plPos, plOri, plSize, plCol, true), // player tank
        sdTank(p + npcPos, npcOri, npcSize, npcCol, false), // test npc
        
        emptyObj(),
        emptyObj(),
        emptyObj(),
        emptyObj(),
        emptyObj(),
        emptyObj(),
        emptyObj()
    ));
    
    // balls
    for (int i = 0; i < PROJ_CAP; i++) {
        vec4 proj_pos = read(ivec2(i, PROJ_POS_Y));
        if (proj_pos.w == 0.0) continue;
        
        float proj = sdSphere(p - proj_pos.xyz, 0.5);
        if (proj < closest.d) closest = Object(proj, vec3(1.0));
    }
    
    return closest;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y; // [-1, 1]
    
    vec2 camOri = read(CAM_ORI_DATA).xy; // yaw, pitch
    
    //origin
    vec3 plPos = vec3(0.0);
    vec3 plSize = read(PL_SIZE_DATA).xyz;
    
    vec3 target = plPos + vec3(0.0, 1.0, 0.0) * (plSize.y + 3.0); //tbc
    vec3 ro = target + vec3(
        cos(camOri.x) * sin(camOri.y),
        sin(camOri.x),
        cos(camOri.x) * cos(camOri.y)
    ) * 10.0;
    
    //direction
    vec3 forward = normalize(target - ro);
    vec3 right = normalize(cross(forward, vec3(0.0,1.0,0.0)));
    vec3 up = cross(right, forward);
    vec3 rd = normalize(forward + uv.x * right + uv.y * up);

    //raymarch
    float t = 0.0;
    for (int i = 0; i < 100; i++) {
        Object obj = scene(ro + rd * t);
        
        if (obj.d < 0.1) { fragColor = vec4(obj.col, 1.0); return; }
        if (t > 50.0) break;
        t += obj.d;
    }

    fragColor.xyz = COLOR_BLUE;
}
