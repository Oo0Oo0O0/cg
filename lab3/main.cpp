#include <cmath>
#include <iostream>
#include <fstream>
#include <sstream>
#include "tgaimage.h"

constexpr TGAColor white   = {255, 255, 255, 255}; // attention, BGRA order
constexpr TGAColor green   = {  0, 255,   0, 255};
constexpr TGAColor red     = {  0,   0, 255, 255};
constexpr TGAColor blue    = {255, 128,  64, 255};
constexpr TGAColor yellow  = {  0, 200, 255, 255};

// every verticie take 3 consecutive slots, face takes 2
struct Object {
	std::vector<float> verticies;
	std::vector<float> faces;
};

Object load_obj(const std::string& filename) {
	Object result = {};

	std::ifstream in(filename);
	if (!in.good()) { std::cerr << "cant load obj\n"; return {}; }

	std::string line;
	while (std::getline(in, line)) {
		std::istringstream iss(line);

		std::string token;
		std::getline(iss, token, ' ');

		if (token == "v") {
			for (int i = 0; i < 3; i++) {
				std::getline(iss, token, ' ');
				result.verticies.push_back(std::stof(token));
			}
		} else if (token == "f") {
			for (int i = 0; i < 3; i++) {
				std::getline(iss, token, ' ');
				std::istringstream ts(token);

				std::getline(ts, token, '/');
				result.faces.push_back(std::stoi(token));
			}
		}
	}

	return result;
}

void line(TGAImage& buffer, int ax, int ay, int bx, int by, TGAColor color) {
	bool steep = std::abs(ax-bx) < std::abs(ay-by);
	if (steep) { std::swap(ax, ay); std::swap(bx, by); }
	if (ax > bx) { std::swap(ax, bx); std::swap(ay, by); }

	float y = ay;
	for (int x = ax; x < bx; x++) {
		if (steep) buffer.set(y, x, color);
		else buffer.set(x, y, color);

		y += (by - ay) / static_cast<float>(bx-ax);
	}
}

int main(int argc, char** argv) {
	constexpr int width  = 1024;
	constexpr int height = width;
	TGAImage framebuffer(width, height, TGAImage::RGB);

	Object a = load_obj("obj/diablo3_pose/diablo3_pose.obj");
	// Object a = load_obj("obj/african_head/african_head.obj");
	// Object a = load_obj("obj/boggie/body.obj");

	// Faces
	for (size_t i = 0; i < a.faces.size(); i += 3) {
		const auto& f = a.faces;
		const auto& v = a.verticies;

		int a = (f[i] - 1) * 3, b = (f[i+1] - 1) * 3, c = (f[i+2] - 1) * 3;

		int ax = width * (v[a]+1)/2, ay = height * (v[a+1]+1)/2;
		int bx = width * (v[b]+1)/2, by = height * (v[b+1]+1)/2;
		int cx = width * (v[c]+1)/2, cy = height * (v[c+1]+1)/2;

		line(framebuffer, ax, ay, bx, by, red);
		line(framebuffer, bx, by, cx, cy, red);
		line(framebuffer, ax, ay, cx, cy, red);
	}

	// Vert
	for (size_t i = 0; i < a.verticies.size(); i += 3) {
		const auto& v = a.verticies;

		int x = width * (v[i]+1)/2, y = height * (v[i+1]+1)/2;
		framebuffer.set(x, y, white);
	}

	framebuffer.write_tga_file("framebuffer.tga");
}

