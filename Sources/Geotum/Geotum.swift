import CoreLocation

struct UTMCoordinate {
    let easting : Double
    let northing : Double
}

/// Describes a planet as an ellipsoid
struct PlanetaryDatum {
    static let wgs84 = PlanetaryDatum(equatorialRadius: 6_378_137.0, polarRadius: 6_356_752.3)
    
    /// Radius towards the equator from center
    let equatorialRadius : Double
    /// Radius towards the pole from center
    let polarRadius : Double
    
    /// Create new datum.
    ///
    /// - Parameters:
    ///   - equatorialRadius: The radius from the center to the equator.
    ///   - polarRadius: The radius from the center to the pole.
    init(equatorialRadius : Double, polarRadius : Double) {
        self.equatorialRadius = equatorialRadius
        self.polarRadius = polarRadius
    }
    
    /// Create new datum described by standard equatorial radius
    /// and inverse flattening.
    ///
    /// - Parameters:
    ///   - equatorialRadius: The radius from the center to the equator.
    ///   - inverseFlattening: The ratio between the equatorial radius and the polar radius
    init(equatorialRadius : Double, inverseFlattening : Double) {
        self.equatorialRadius = equatorialRadius
        self.polarRadius = equatorialRadius * (inverseFlattening - 1) / inverseFlattening
    }
}

class UTMConverter {
    var datum : PlanetaryDatum
    
    init(datum : PlanetaryDatum) {
        self.datum = datum
    }
}

struct Geotum {
    func utmToLatLong() -> CLLocationCoordinate2D {
        
    }
    
    func latlongToUTM() -> UTMCoordinate {
        
    }
}
