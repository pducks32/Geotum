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
    
    public init(easting : Double, northing : Double, zone : UInt, hemisphere : Hemisphere) {
        self.easting = easting
        self.northing = northing
        self.zone = zone
        self.hemisphere = hemisphere
    }
    
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
    
    /// The ratio between the equatorial radius and the polar radius
    public var inverseFlattening : Double {
        return (equatorialRadius - polarRadius) / equatorialRadius
    }
    
    public var eccentricity : Double {
        return sqrt(inverseFlattening * (2 - inverseFlattening))
    }
}

struct KrugerForms {
    let n1 : Double
    let n2 : Double
    let n3 : Double
    let n4 : Double
    let n5 : Double
    let n6 : Double
    
    let α : [Double]
    let β : [Double]
    
    let flattenedMeridianRadius : Double
    
    init(datum : PlanetaryDatum) {
        let thirdFlattening = datum.inverseFlattening / (2 - datum.inverseFlattening)
        
        n1 = thirdFlattening
        n2 = n1 * n1
        n3 = n2 * n1
        n4 = n3 * n1
        n5 = n4 * n1
        n6 = n5 * n1
        
        let α1 = 1/2*n1 - 2/3*n2 + 5/16*n3 + 41/180*n4 - 127/288*n5 + 7891/37800*n6
        let α2 = 13/48*n2 - 3/5*n3 + 557/1440*n4 + 281/630*n5 - 1983433/1935360*n6
        let α3 = 61/240*n3 - 103/140*n4 + 15061/26880*n5 + 167603/181440*n6
        let α4 = 49561/161280*n4 - 179/168*n5 + 6601661/7257600*n6
        let α5 = 34729/80640*n5 - 3418889/1995840*n6
        let α6 = 212378941/319334400*n6
        α = [α1, α2, α3, α4, α5, α6]
        
        let β1 = 1/2*n1 - 2/3*n2 + 37/96*n3 - 1/360*n4 - 81/512*n5 + 96199/604800*n6
        let β2 = 1/48*n2 + 1/15*n3 - 437/1440*n4 + 46/105*n5 - 1118711/3870720*n6
        let β3 = 17/480*n3 - 37/840*n4 - 209/4480*n5 + 5569/90720*n6
        let β4 = 4397/161280*n4 - 11/504*n5 - 830251/7257600*n6
        let β5 = 4583/161280*n5 - 108847/3991680*n6
        let β6 = 20648693/638668800*n6
        β = [β1, β2, β3, β4, β5, β6]
        
        let flatteningCoefficient = 1 + n2/4 + n4/64 + n6/256
        flattenedMeridianRadius = flatteningCoefficient * datum.equatorialRadius / (1 + thirdFlattening)
    }
}

public func abs<T : Dimension>(_ measurement : Measurement<T>) -> Measurement<T> {
    return Measurement<T>(value: abs(measurement.value), unit: measurement.unit)
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
        let latitude = coordinates.latitude
        let longitude = coordinates.longitude
        
        if abs(latitude) > Measurement(value: 84, unit: .degrees) {
            print("Oops")
            fatalError("Latitude is out of range")
        }
        
        var zone = UInt(floor((longitude.converted(to: .degrees).value + 180.0) / 6) + 1)
        
        let band = latitudeBand(at: latitude)
        zone = zoneWithNorwayCorrectionIfNeeded(zone: zone, latitudeBand: band, coordinates: coordinates)
        zone = zoneWithSvalbardCorrectionIfNeeded(zone: zone, latitudeBand: band, coordinates: coordinates)
        
        let centralMeridian = Measurement<UnitAngle>(value: (Double(zone - 1) * 6.0) - 180.0 + 3.0, unit: .degrees)
        let φ = latitude.converted(to: .radians).value
        let λ = longitude.converted(to: .radians).value - centralMeridian.converted(to: .radians).value
        
        let scaleFactor = 0.9996
        
        let cosλ = cos(λ)
        let sinλ = sin(λ)
        
        let τ = tan(φ)
        let σ = sinh(datum.eccentricity * atanh((datum.eccentricity * τ) / sqrt(1 + τ*τ)))
        let τPrime = τ * sqrt(1 + σ*σ) - σ * sqrt(1 + τ*τ)
        
        let ξPrime = atan2(τPrime, cosλ)
        let ηPrime = asinh(sinλ / sqrt(τPrime*τPrime + cosλ*cosλ))
        
        let krüger = KrugerForms(datum: datum)
        
        var ξ = ξPrime
        var η = ηPrime
        for index in 1...6 {
            let properIndex = Double(2 * index)
            ξ += krüger.α[index - 1] * sin(properIndex * ξPrime) * cosh(properIndex * ηPrime)
            η += krüger.α[index - 1] * cos(properIndex * ξPrime) * sinh(properIndex * ηPrime)
        }
        
        let x = scaleFactor * krüger.flattenedMeridianRadius * η
        let y = scaleFactor * krüger.flattenedMeridianRadius * ξ
        
        let falseEasting = 500e3
        let falseNorthing = 10000e3
        
        let easting = x + falseEasting
        var northing = y
        if (y < 0) {
            northing += falseNorthing
        }
        
        let hemisphere : UTMPoint.Hemisphere = φ >= 0 ? .northern : .southern
        return UTMPoint(easting: easting, northing: northing, zone: zone, hemisphere: hemisphere)
    }
    
    private func latitudeBand(at latitude : Measurement<UnitAngle>) -> String {
        let mgrsBands = ["C", "D", "E", "F", "G", "H", "J", "K", "L", "M", "N", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "X"]
        let index = Int(floor(latitude.converted(to: .degrees).value / 8 + 10))
        return mgrsBands[index]
    }
    
    private func zoneWithNorwayCorrectionIfNeeded(zone: UInt, latitudeBand : String, coordinates : LatLonCoordinate) -> UInt {
        guard zone == 31 else { return zone }
        guard latitudeBand == "V" else { return zone }
        guard coordinates.longitude >= Measurement(value: 3, unit: .degrees) else { return zone }
        
        return 32
    }
    
    private func zoneWithSvalbardCorrectionIfNeeded(zone : UInt, latitudeBand : String, coordinates : LatLonCoordinate) -> UInt {
        guard latitudeBand == "X" else { return zone }
        guard zone == 32 || zone == 34 || zone == 36 else { return zone }
        
        let longitiudeDegrees = coordinates.longitude.converted(to: .degrees).value
        
        if zone == 32 {
            return longitiudeDegrees < 9 ? 31 : 33
        }
        if zone == 34 {
            return longitiudeDegrees < 21 ? 31 : 33
        }
        if zone == 36 {
            return longitiudeDegrees < 33 ? 31 : 33
        }
        
        return zone
    }
    
    public func coordinateFrom(utm : UTMPoint) -> LatLonCoordinate {
        let falseEasting = 500e3
        let falseNorthing = 10000e3
        let scaleFactor = 0.9996
        let krüger = KrugerForms(datum: datum)
        
        let x = utm.easting - falseEasting
        var y = utm.northing
        if (utm.hemisphere == .southern) {
            y -= falseNorthing
        }
        
        let η = x / (scaleFactor * krüger.flattenedMeridianRadius);
        let ξ = y / (scaleFactor * krüger.flattenedMeridianRadius);
        
        var ξPrime = ξ
        var ηPrime = η
        for index in 1...6 {
            let properIndex = Double(2 * index)
            ξPrime -= krüger.β[index - 1] * sin(properIndex * ξ) * cosh(properIndex * η)
            ηPrime -= krüger.β[index - 1] * cos(properIndex * ξ) * sinh(properIndex * η)
        }
        
        let sinhηPrime = sinh(ηPrime)
        let sinξPrime = sin(ξPrime)
        let cosξPrime = cos(ξPrime)
        
        let τPrime = sinξPrime / sqrt(sinhηPrime*sinhηPrime + cosξPrime*cosξPrime)
        
        var δτi : Double = 1.0
        var τi : Double = τPrime
        let e2 = datum.eccentricity * datum.eccentricity
        while δτi > 1e-12 {
            let σi = sinh(datum.eccentricity*atanh(datum.eccentricity*τi/sqrt(1+τi*τi)));
            let τiPrime = τi * sqrt(1+σi*σi) - σi * sqrt(1+τi*τi);
            δτi = (τPrime - τiPrime)/sqrt(1+τiPrime*τiPrime)
                * (1 + (1 - e2)*τi*τi) / ((1-e2)*sqrt(1+τi*τi));
            τi += δτi;
        }
        let τ = τi
        let φ = atan(τ)
        
        let centralMeridian = Measurement<UnitAngle>(value: (Double(utm.zone) - 1.0) * 6 - 180.0 + 3.0, unit: .degrees).converted(to: .radians).value
        let λ = atan2(sinhηPrime, cosξPrime) + centralMeridian
        
        return LatLonCoordinate(latitude: Measurement<UnitAngle>(value: φ, unit: .radians), longitude: Measurement<UnitAngle>(value: λ, unit: .radians))
    }
}
