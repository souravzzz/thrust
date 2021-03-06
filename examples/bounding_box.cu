#include <thrust/transform_reduce.h>
#include <thrust/device_vector.h>
#include <thrust/pair.h>
#include <thrust/random.h>
#include <thrust/extrema.h>

// This example shows how to compute a bounding box
// for a set of points in two dimensions.

struct point2d
{
    float x, y;

    __host__ __device__
    point2d() : x(0), y(0) {}
    
    __host__ __device__
    point2d(float _x, float _y) : x(_x), y(_y) {}
};


// bounding box type
typedef thrust::pair<point2d, point2d> bbox;

// reduce a pair of bounding boxes (a,b) to a bounding box containing a and b
struct bbox_reduction : public thrust::binary_function<bbox,bbox,bbox>
{
    __host__ __device__
    bbox operator()(bbox a, bbox b)
    {
        // lower left corner
        point2d ll(thrust::min(a.first.x, b.first.x), thrust::min(a.first.y, b.first.y));
        
        // upper right corner
        point2d ur(thrust::max(a.second.x, b.second.x), thrust::max(a.second.y, b.second.y));

        return bbox(ll, ur);
    }
};

// convert a point to a bbox containing that point, (point) -> (point, point)
struct bbox_transformation : public thrust::unary_function<point2d,bbox>
{
    __host__ __device__
    bbox operator()(point2d point)
    {
        return bbox(point, point);
    }
};

int main(void)
{
    const size_t N = 40;
    thrust::default_random_engine rng;
    thrust::uniform_real_distribution<float> u01(0.0f, 1.0f);
    
    // allocate storage for points
    thrust::device_vector<point2d> points(N);

    // generate some random points in the unit square
    for(size_t i = 0; i < N; i++)
    {
        float x = u01(rng);
        float y = u01(rng);
        points[i] = point2d(x,y);
    }

    // initial bounding box contains first point
    bbox init = bbox(points[0], points[0]);
    
    // transformation operation
    bbox_transformation unary_op;

    // binary reduction operation
    bbox_reduction binary_op;
    
    // compute the bounding box for the point set
    bbox result = thrust::transform_reduce(points.begin(), points.end(), unary_op, init, binary_op);

    // print output
    std::cout << "bounding box " << std::fixed;
    std::cout << "(" << result.first.x  << "," << result.first.y  << ") ";
    std::cout << "(" << result.second.x << "," << result.second.y << ")" << std::endl;

    return 0;
}
