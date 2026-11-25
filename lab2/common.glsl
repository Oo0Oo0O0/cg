// data slots
#define CAM_ORI_DATA ivec2(0,0)
#define PROJ_DATA ivec2(1,0)

#define PL_SIZE_DATA ivec2(2,0)
#define PL_ORI_DATA ivec2(3,0)

// The whole data rows are reserved for projectiles data, 0 <= X < PROJ_CAP
#define PROJ_POS_Y 1
#define PROJ_FORCE_Y 2


// constants
#define PI 3.141592

#define KEY_A 65
#define KEY_D 68
#define KEY_W 87
#define KEY_S 83
#define KEY_SPACE 32
#define KEY_LEFT 37
#define KEY_RIGHT 39
#define KEY_UP 38
#define KEY_DOWN 40

#define COLOR_BLUE vec3(0.537,0.706,0.98)
#define COLOR_PURPLE vec3(0.706, 0.745, 0.996)
#define COLOR_ORANGE vec3(0.98,0.702,0.529)
#define COLOR_GREEN vec3(0.651,0.89,0.631)

// vars
const vec2 CAM_SENS = vec2(0.5, 1.0);

const int PROJ_CAP = 10;
const float SHOOT_CD = 0.5; // If cd is too low, it will fuck up force calculations
const float ORI_ALLIGN_SPEED = 4.0;

// private
#define EMPTY_OBJ_D 67.0

#define TC_BODY_DEF_SIZE vec3(1.5,0.5,1.7)
#define TC_TOP_SIZE_M vec3(0.7, 1.0, 0.9)
#define TC_BARREL_SIZE_M vec3(0.1, 0.3, 0.6)
#define TC_BARRELEND_SIZE_M vec3(.25,.5,.1)

// math
mat3 rotateY(float a) {
	float c = cos(a);
	float s = sin(a);
	return mat3(
        c,0,s,
        0,1,0,
        -s,0,c
    );
}

mat3 rotateX(float a) {
	float c = cos(a);
	float s = sin(a);
	return mat3(
        1,0,0,
        0,c,-s,
        0,s,c
    );
}

// shapes
float sdPlane(vec3 p) {
    return p.y;
}

float sdSphere(vec3 p,float s) {
    return length(p)-s;
}

float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdCylinder(vec3 p, vec2 h) {
    vec2 d = abs(vec2(length(p.xz),p.y)) - h;
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
