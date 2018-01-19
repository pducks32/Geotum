# Geotum

[![Version](https://img.shields.io/cocoapods/v/Geotum.svg?style=flat)](http://cocoapods.org/pods/Geotum)
[![License](https://img.shields.io/cocoapods/l/Geotum.svg?style=flat)](http://cocoapods.org/pods/Geotum)
[![Platform](https://img.shields.io/cocoapods/p/Geotum.svg?style=flat)](http://cocoapods.org/pods/Geotum)

Geotum is for converting to and from latitude/longitude pairs and UTM points.

## Usage

```swift
// Converting to UTM (near Santa Cruz)
let latitude = 37.0837
let longitude = -121.9981
let latLonCoordinate = LatLonCoordinate(latiudinalDegrees: latitude, longitudinalDegrees: longitude)
UTMConverter(datum: .wgs84).utmCoordinatesFrom(coordinates: latLonCoordinate)

// Converting to Lat Lon
let utmCoordinate = UTMPoint(easting: 589048.6, northing: 4104627, zone: 10, hemisphere: .northern)
UTMConverter(datum: .wgs84).coordinateFrom(utm: utmCoordinate)
```

## Accuracy
As detailed below this library suffers from a common UTM conversion problem, namely the poles (which are not supported by UTM) and the Svalbard/Norway problem.

I am aware of these problems and plan to fix them shortly.

## Comparisons
Another library [GeodeticUTMConverter](https://github.com/palmerc/GeodeticUTMConverter) works but is no longer maintained. As I (@pducks32) have dealt with geodesy both academically and professionally I thought I would start my own library to handle the conversions.

Currently this library just copies [GeodeticUTMConverter](https://github.com/palmerc/GeodeticUTMConverter) and supports macOS but in the future will be extended to fix significant problems in that source (such as the [Svalbard problem](priede.bf.lu.lv/grozs/BotanikasEkologijas/Flora_Europa/www/www.helsinki.fi/kmus/afe/mgrszones_europe.jpg)).

## Installation

Geotum is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Geotum"
```

## Author

Patrick Metcalfe, git@patrickmetcalfe.com

## License

Hamilton is available under the MIT license. See the LICENSE file for more info.
