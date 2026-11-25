#include <cmath>
#include <iostream>
#include <fstream>
#include <sstream>
#include "tgaimage.h"

constexpr int width = 1024;
constexpr int height = width;

constexpr TGAColor white   = {255, 255, 255, 255}; // attention, BGRA order
constexpr TGAColor green   = {  0, 255,   0, 255};
constexpr TGAColor red     = {  0,   0, 255, 255};
constexpr TGAColor blue    = {255, 128,  64, 255};
constexpr TGAColor yellow  = {  0, 200, 255, 255};

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

double signed_triangle_area(int ax, int ay, int bx, int by, int cx, int cy) {
	return .5 * ((by-ay)*(bx+ax) + (cy-by)*(cx+bx) + (ay-cy)*(ax+cx));
}

void triangle(TGAImage& buffer, int ax, int ay, int bx, int by, int cx, int cy) {
	int bbminx = std::min(std::min(ax, bx), cx);
	int bbmaxx = std::max(std::max(ax, bx), cx);
	int bbminy = std::min(std::min(ay, by), cy);
	int bbmaxy = std::max(std::max(ay, by), cy);

	double total_area = signed_triangle_area(ax, ay, bx, by, cx, cy);
	if (total_area < 1) return;

#pragma omp parallel for
	for (int x = bbminx; x < bbmaxx; x++) {
		for (int y = bbminy; y < bbmaxy; y++) {
			double alpha = signed_triangle_area(x, y, bx, by, cx, cy) / total_area;
			double beta  = signed_triangle_area(x, y, cx, cy, ax, ay) / total_area;
			double gamma = signed_triangle_area(x, y, ax, ay, bx, by) / total_area;
			if (alpha<0 || beta<0 || gamma<0) continue;

			float offset = 0.175;
			if (alpha > offset && beta > offset && gamma > offset) continue;
			TGAColor color = {
				static_cast<unsigned char>(255 * alpha),
				static_cast<unsigned char>(255 * beta),
				static_cast<unsigned char>(255 * gamma),
				255
			};

			buffer.set(x, y, color);
		}
	}
}

int main(int argc, char** argv) {
	TGAImage framebuffer(width, height, TGAImage::RGB);

	float ax = 0.9, ay = 0.7;
	float bx = 0.95, by = 0.9;
	float cx = 0.7, cy = 0.8;

	Object a = load_obj("obj/diablo3_pose/diablo3_pose.obj");
for (size_t i = 0; i < a.faces.size(); i += 3) {
		const auto& f = a.faces;
		const auto& v = a.verticies;

		int a = (f[i] - 1) * 3, b = (f[i+1] - 1) * 3, c = (f[i+2] - 1) * 3;

		int ax = width * (v[a]+1)/2, ay = height * (v[a+1]+1)/2;
		int bx = width * (v[b]+1)/2, by = height * (v[b+1]+1)/2;
		int cx = width * (v[c]+1)/2, cy = height * (v[c+1]+1)/2;

		triangle(framebuffer, ax, ay, bx, by, cx, cy);
	}

	triangle(framebuffer, ax*width, ay*height, bx*width, by*height, cx*width, cy*height);

	framebuffer.write_tga_file("framebuffer.tga");
}

