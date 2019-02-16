// Note: M_PI is not part of the C or C++ standards, _USE_MATH_DEFINES enables it
#define _USE_MATH_DEFINES
#include <boost/geometry.hpp>
#include <cmath>
#include <iostream>
#include <ios>

// WGS 84 parameters from: Eurocontrol WGS 84 Implementation Manual
// Version 2.4 Chapter 3, page 14

/// The Semimajor axis measured in metres.
/// This is the radius at the equator.
constexpr double a = 6378137.0;

/// Flattening, a ratio.
/// This is the flattening of the ellipse at the poles
constexpr double f = 1.0/298.257223563;

/// The Semiminor axis measured in metres.
/// This is the radius at the poles.
/// Note: this is derived from the Semimajor axis and the flattening.
/// See WGS 84 Implementation Manual equation B-2, page 69.
constexpr double b = a * (1.0 - f);

int main(int argc, char* argv[])
{
  std::cout.setf(std::ios::fixed);
  
  // For boost::geometry:
  typedef boost::geometry::cs::geographic<boost::geometry::radian> Wgs84Coords;
  typedef boost::geometry::model::point<double, 2, Wgs84Coords> GeographicPoint;
  // Note boost points are Long & Lat NOT Lat & Long
  GeographicPoint Point1   (std::stod(argv[1])* M_PI / 180.0, std::stod(argv[2])* M_PI / 180.0);
  GeographicPoint Point2   (std::stod(argv[3])* M_PI / 180.0, std::stod(argv[4])* M_PI / 180.0);

  // Note: the default boost geometry spheroid is WGS84
  // #include <boost/geometry/core/srs.hpp>
  typedef boost::geometry::srs::spheroid<double> SpheroidType;
  SpheroidType spheriod;

  //#include <boost/geometry/strategies/geographic/distance_vincenty.hpp>
  typedef boost::geometry::strategy::distance::vincenty<SpheroidType>
                                                               VincentyStrategy;
  VincentyStrategy vincenty(spheriod);

  double vincenty_minor(boost::geometry::distance(Point1, Point2, vincenty));
  std::cout << vincenty_minor << std::endl;

  return 0;
}