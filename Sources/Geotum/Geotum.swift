import CoreLocation

public struct UTMDistance {
    public var easting : Double
    public var northing : Double
    
    public init(easting : Double, northing : Double) {
        self.easting = easting
        self.northing = northing
    }
}

public struct UTMPoint {
    public typealias Distance = UTMDistance
    
    public enum Hemisphere : String {
        case northern
        case southern
        
        public var abbreviation : String {
            switch self {
            case .northern:
                return "N"
            case .southern:
                return "S"
            }
        }
    }
    public var easting : Double
    public var northing : Double
    public var zone : UInt
    public var hemisphere : Hemisphere
    
    public static func -(lhs : UTMPoint, rhs : UTMPoint) -> UTMDistance {
        return UTMDistance(easting: lhs.easting - rhs.easting, northing: lhs.northing - rhs.northing)
    }
    
    public static func +(lhs : UTMPoint, rhs : UTMDistance) -> UTMPoint {
        return UTMPoint(easting: lhs.easting + rhs.easting, northing: lhs.northing + rhs.northing, zone: lhs.zone, hemisphere: lhs.hemisphere)
    }
}

public struct LatLonCoordinate {
    public typealias Distance = LatLonCoordinate
    public let latitude : Measurement<UnitAngle>
    public let longitude : Measurement<UnitAngle>
    
    public init(latitude : Measurement<UnitAngle>, longitude : Measurement<UnitAngle>) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    public init(latiudinalDegrees: Double, longitudinalDegrees: Double) {
        self.latitude = Measurement(value: latiudinalDegrees, unit: .degrees)
        self.longitude = Measurement(value: longitudinalDegrees, unit: .degrees)
    }
}

/// Describes a planet as an ellipsoid
public struct PlanetaryDatum {
    public static let wgs84 = PlanetaryDatum(equatorialRadius: 6_378_137.0, polarRadius: 6_356_752.3)
    
    /// Radius towards the equator from center
    public let equatorialRadius : Double
    /// Radius towards the pole from center
    public let polarRadius : Double
    
    /// Create new datum.
    ///
    /// - Parameters:
    ///   - equatorialRadius: The radius from the center to the equator.
    ///   - polarRadius: The radius from the center to the pole.
    public init(equatorialRadius : Double, polarRadius : Double) {
        self.equatorialRadius = equatorialRadius
        self.polarRadius = polarRadius
    }
    
    /// Create new datum described by standard equatorial radius
    /// and inverse flattening.
    ///
    /// - Parameters:
    ///   - equatorialRadius: The radius from the center to the equator.
    ///   - inverseFlattening: The ratio between the equatorial radius and the polar radius
    public init(equatorialRadius : Double, inverseFlattening : Double) {
        self.equatorialRadius = equatorialRadius
        self.polarRadius = equatorialRadius * (inverseFlattening - 1) / inverseFlattening
    }
}

public class UTMConverter {
    public var datum : PlanetaryDatum
    
    public init(datum : PlanetaryDatum) {
        self.datum = datum
    }
    
    private func centralMeridian(for zone : UInt) -> Measurement<UnitAngle> {
        return Measurement<UnitAngle>(value: -183.0 + (Double(zone) * 6.0), unit: .degrees)
    }
    
    public func utmCoordinatesFrom(coordinates : LatLonCoordinate) -> UTMPoint {
        var baseCoordinates = tmCoordinatesFrom(coordinates: coordinates)
        baseCoordinates.easting = baseCoordinates.easting * 0.9996 + 500000.0
        baseCoordinates.northing = baseCoordinates.northing * 0.9996
        
        if baseCoordinates.northing < 0 {
            baseCoordinates.northing += 10000000.0
        }
        
        return baseCoordinates
    }
    
    public func coordinateFrom(utm : UTMPoint) -> LatLonCoordinate {
        let x = (utm.easting - 500000.0) / 0.9996
        var y = utm.northing
        
        if utm.hemisphere == .southern {
            y -= 10000000.0
        }
        y /= 0.9996
        
        let tmCoordinate = UTMPoint(easting: x, northing: y, zone: utm.zone, hemisphere: utm.hemisphere)
        
        return self.latlonCoordinateFrom(tmCoordinate: tmCoordinate)
    }
    
    private func latlonCoordinateFrom(tmCoordinate : UTMPoint) -> LatLonCoordinate {
        let x = tmCoordinate.easting;
        
        let centralMeridian = self.centralMeridian(for: tmCoordinate.zone).converted(to: .radians).value
        
        let equitorialRadus = datum.equatorialRadius;
        let polarRadius = datum.polarRadius;
        
        /* Get the value of phif, the footpoint latitude. */
        let phif = footprintLatitude(forNorthing: Measurement(value: tmCoordinate.northing, unit: .meters)).converted(to: .radians).value
        
        /* Precalculate ep2 */
        let ep2 = (pow(equitorialRadus, 2.0) - pow(polarRadius, 2.0)) / pow(polarRadius, 2.0);
        
        /* Precalculate cos (phif) */
        let cf = cos(phif);
        
        /* Precalculate nuf2 */
        let nuf2 = ep2 * pow(cf, 2.0);
        
        /* Precalculate Nf and initialize Nfpow */
        let Nf = pow(equitorialRadus, 2.0) / (polarRadius * sqrt(1 + nuf2));
        var Nfpow = Nf;
        
        /* Precalculate tf */
        let tf = tan(phif);
        let tf2 = tf * tf;
        let tf4 = tf2 * tf2;
        
        /* Precalculate fractional coefficients for x**n in the equations
         below to simplify the expressions for latitude and longitude. */
        let x1frac = 1.0 / (Nfpow * cf);
        
        Nfpow *= Nf;   /* now equals Nf**2) */
        let x2frac = tf / (2.0 * Nfpow);
        
        Nfpow *= Nf   /* now equals Nf**3) */
        let x3frac = 1.0 / (6.0 * Nfpow * cf);
        
        Nfpow *= Nf   /* now equals Nf**4) */
        let x4frac = tf / (24.0 * Nfpow);
        
        Nfpow *= Nf   /* now equals Nf**5) */
        let x5frac = 1.0 / (120.0 * Nfpow * cf);
        
        Nfpow *= Nf   /* now equals Nf**6) */
        let x6frac = tf / (720.0 * Nfpow);
        
        Nfpow *= Nf   /* now equals Nf**7) */
        let x7frac = 1.0 / (5040.0 * Nfpow * cf);
        
        Nfpow *= Nf   /* now equals Nf**8) */
        let x8frac = tf / (40320.0 * Nfpow)
        
        /* Precalculate polynomial coefficients for x**n.
         -- x**1 does not have a polynomial coefficient. */
        let x2poly = -1.0 - nuf2
        let x3poly = -1.0 - 2 * tf2 - nuf2
        let x4poly = 5.0 + 3.0 * tf2 + 6.0 * nuf2 - 6.0 * tf2 * nuf2 - 3.0 * (nuf2 * nuf2) - 9.0 * tf2 * (nuf2 * nuf2)
        let x5poly = 5.0 + 28.0 * tf2 + 24.0 * tf4 + 6.0 * nuf2 + 8.0 * tf2 * nuf2
        let x6poly = -61.0 - 90.0 * tf2 - 45.0 * tf4 - 107.0 * nuf2 + 162.0 * tf2 * nuf2
        let x7poly = -61.0 - 662.0 * tf2 - 1320.0 * tf4 - 720.0 * (tf4 * tf2)
        let x8poly = 1385.0 + 3633.0 * tf2 + 4095.0 * tf4 + 1575 * (tf4 * tf2)
        
        /* Calculate latitude */
        let latitude = phif + x2frac * x2poly * (x * x) + x4frac * x4poly * pow(x, 4.0) + x6frac * x6poly * pow(x, 6.0) + x8frac * x8poly * pow(x, 8.0)
        
        /* Calculate longitude */
        let longitude = centralMeridian + x1frac * x + x3frac * x3poly * pow(x, 3.0) + x5frac * x5poly * pow(x, 5.0) + x7frac * x7poly * pow(x, 7.0)
        
        return LatLonCoordinate(latitude: Measurement<UnitAngle>(value: latitude, unit: .radians), longitude: Measurement<UnitAngle>(value: longitude, unit: .radians))
    }
    
    private func tmCoordinatesFrom(coordinates: LatLonCoordinate) -> UTMPoint {
        let zone = floor((coordinates.longitude.converted(to: .degrees).value + 180.0) / 6) + 1
        let meridian = centralMeridian(for: UInt(zone)).converted(to: .radians).value
        let hemisphere : UTMPoint.Hemisphere
        if coordinates.latitude.value < 0 {
            hemisphere = .northern
        } else {
            hemisphere = .southern
        }
        
        let latitudeInRadians = coordinates.latitude.converted(to: .radians).value
        let longitudeInRadians = coordinates.longitude.converted(to: .radians).value
        
        /* Precalculate ep2 */
        let ep2 = (pow(datum.equatorialRadius, 2.0) - pow(datum.polarRadius, 2.0)) / pow(datum.polarRadius, 2.0)
        
        /* Precalculate nu2 */
        let nu2 = ep2 * pow(cos(latitudeInRadians), 2.0)
        
        /* Precalculate N */
        let N = pow(datum.equatorialRadius, 2.0) / (datum.polarRadius * sqrt(1 + nu2))
        
        /* Precalculate t */
        let t = tan(latitudeInRadians)
        let t2 = t * t
        
        /* Precalculate l */
        let l = longitudeInRadians - meridian;
        
        /* Precalculate coefficients for l**n in the equations below
         so a normal human being can read the expressions for easting
         and northing
         -- l**1 and l**2 have coefficients of 1.0 */
        let l3coef = 1.0 - t2 + nu2;
        let l4coef = 5.0 - t2 + 9 * nu2 + 4.0 * (nu2 * nu2)
        let l5coef = 5.0 - 18.0 * t2 + (t2 * t2) + 14.0 * nu2 - 58.0 * t2 * nu2
        let l6coef = 61.0 - 58.0 * t2 + (t2 * t2) + 270.0 * nu2 - 330.0 * t2 * nu2
        let l7coef = 61.0 - 479.0 * t2 + 179.0 * (t2 * t2) - (t2 * t2 * t2)
        let l8coef = 1385.0 - 3111.0 * t2 + 543.0 * (t2 * t2) - (t2 * t2 * t2)
        
        /* Calculate easting (x) */
        let easting = N * cos(latitudeInRadians) * l + (N / 6.0 * pow(cos(latitudeInRadians), 3.0) * l3coef * pow(l, 3.0)) + (N / 120.0 * pow(cos(latitudeInRadians), 5.0) * l5coef * pow(l, 5.0)) + (N / 5040.0 * pow(cos(latitudeInRadians), 7.0) * l7coef * pow(l, 7.0));
        
        /* Calculate northing (y) */
        let northing = arcLengthFromEquator(atLatitude: coordinates.latitude) + (t / 2.0 * N * pow(cos(latitudeInRadians), 2.0) * pow(l, 2.0)) + (t / 24.0 * N * pow(cos(latitudeInRadians), 4.0) * l4coef * pow(l, 4.0)) + (t / 720.0 * N * pow(cos(latitudeInRadians), 6.0) * l6coef * pow(l, 6.0)) + (t / 40320.0 * N * pow(cos(latitudeInRadians), 8.0) * l8coef * pow(l, 8.0));
        
        return UTMPoint(easting: easting, northing: northing, zone: UInt(zone), hemisphere: hemisphere)
    }
    
    private func arcLengthFromEquator(atLatitude latitude: Measurement<UnitAngle>) -> Double {
        let radiansValue = latitude.converted(to: .radians).value
        let separatedRatio = (datum.equatorialRadius - datum.polarRadius) / (datum.equatorialRadius + datum.polarRadius)
        /// αβγδε
        let α = ((datum.equatorialRadius + datum.polarRadius) / 2.0) * (1.0 + (pow(separatedRatio, 2.0) / 4.0) + (pow(separatedRatio, 4.0) / 64.0))
        let β = (-3.0 * separatedRatio / 2.0) + (9.0 * pow(separatedRatio, 3.0) / 16.0) + (-3.0 * pow(separatedRatio, 5.0) / 32.0)
        let γ = (15.0 * pow(separatedRatio, 2.0) / 16.0) + (-15.0 * pow(separatedRatio, 4.0) / 32.0)
        let δ = (-35.0 * pow(separatedRatio, 3.0) / 48.0) + (105.0 * pow(separatedRatio, 5.0) / 256.0);
        let ε = (315.0 * pow(separatedRatio, 4.0) / 512.0);
        
        /* Now calculate the sum of the series and return */
        return α * (radiansValue + (β * sin(2.0 * radiansValue)) + (γ * sin(4.0 * radiansValue)) + (δ * sin(6.0 * radiansValue)) + (ε * sin(8.0 * radiansValue)));
    }
    
    private func footprintLatitude(forNorthing northing : Measurement<UnitLength>) -> Measurement<UnitAngle> {
        let northingInMeters = northing.converted(to: .meters).value
        /* Precalculate n (Eq. 10.18) */
        let n = (datum.equatorialRadius - datum.polarRadius) / (datum.equatorialRadius + datum.polarRadius);
        
        /* Precalculate alpha_ (Eq. 10.22) */
        /* (Same as alpha in Eq. 10.17) */
        let alpha = ((datum.equatorialRadius + datum.polarRadius) / 2.0) * (1 + (pow(n, 2.0) / 4) + (pow(n, 4.0) / 64))
        
        /* Precalculate y (Eq. 10.23) */
        let y = northingInMeters / alpha
        
        /* Precalculate beta (Eq. 10.22) */
        let beta = (3.0 * n / 2.0) + (-27.0 * pow(n, 3.0) / 32.0) + (269.0 * pow(n, 5.0) / 512.0)
        
        /* Precalculate gamma (Eq. 10.22) */
        let gamma = (21.0 * pow(n, 2.0) / 16.0) + (-55.0 * pow(n, 4.0) / 32.0)
        
        /* Precalculate delta (Eq. 10.22) */
        let delta = (151.0 * pow(n, 3.0) / 96.0) + (-417.0 * pow(n, 5.0) / 128.0)
        
        /* Precalculate epsilon (Eq. 10.22) */
        let epsilon = (1097.0 * pow(n, 4.0) / 512.0)
        
        /* Now calculate the sum of the series (Eq. 10.21) */
        let footprintLatitudeInRadians = y + (beta * sin(2.0 * y)) + (gamma * sin(4.0 * y)) + (delta * sin(6.0 * y)) + (epsilon * sin(8.0 * y))
        
        return Measurement<UnitAngle>(value: footprintLatitudeInRadians, unit: .radians);
    }
}

struct Geotum {
}
