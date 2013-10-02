unit LatLon;

interface

type

  TLatLon = record
    private
      fLat : double;
      fLon : double;
      fRadius : double;
    public
      constructor Create(const lat: double; const lon: double; const rad : double =  6371.0);
      function DistanceTo (const point : TLatLon) : double;
      function BearingTo(const point : TLatLon) : double;
      function FinalBearingTo(const point : TLatLon) : double;
      function MidPointTo(const point : TLatLon) : TLatLon;
      function DestinationPoint(const brng : double; const dist : double) : TLatLon;
      function Intersection(const p1 : TLatLon; const brng1 : double; const p2 : TLatLon; const brng2: double) : TLatLon;
      function RhumbDistanceTo(const point : TLatLon) : double;
      function RhumbBearingTo(const point : TLatLon) : double;
      function RhumbDestinationPoint(const brng : double; const dist : double) : TLatLon;
      function RhumbMidpointTo (const point : TLatLon) : TLatLon;
      property Lat : double read fLat;
      property Lon : double read fLon;
      property Radius : double read fRadius;
    end;

implementation

uses Math, Geo;

//  Creates a point on the earth's surface at the supplied latitude / longitude
//
// @constructor
// @param {Number} lat: latitude in numeric degrees
// @param {Number} lon: longitude in numeric degrees
// @param {Number} [rad=6371]: radius of earth if different value is required from standard 6,371km

constructor TLatLon.Create(const lat: double; const lon: double; const rad : double =  6371.0);
begin
  fLat := lat;
  fLon := lon;
  fRadius := rad;
end;


//Returns the distance from this point to the supplied point, in km
//(using Haversine formula)
//
// from: Haversine formula - R. W. Sinnott, "Virtues of the Haversine",
//       Sky and Telescope, vol 68, no 2, 1984
//
// @param   {LatLon} point: Latitude/longitude of destination point
// @param   {Number} [precision=4]: no of significant digits to use for returned value
// @returns {Number} Distance in km between this point and destination point
function TLatLon.DistanceTo(const point : TLatLon) : double;
var
  R, lat1, lon1, lat2, lon2, dLat, dLon, a, c : double;
begin
  R := fRadius;
  lat1 := DegToRad(fLat);
  lon1 := DegToRad(fLon);
  lat2 := DegToRad(point.Lat);
  lon2 := DegToRad(point.Lon);
  dLat := lat2 - lat1;
  dLon := lon2 - lon1;

  a := Sin(dLat / 2) * Sin(dLat / 2) + Cos(lat1) * Cos(lat2) * Sin(dLon / 2) * Sin(dLon / 2);
  c := 2 * Math.ArcTan2(Sqrt(a), Sqrt(1 - a));
  Result := R * c;
end;

// Returns the (initial) bearing from this point to the supplied point, in degrees
// see http://williams.best.vwh.net/avform.htm#Crs
//
// @param   {LatLon} point: Latitude/longitude of destination point
// @returns {Number} Initial bearing in degrees from North
function TLatLon.BearingTo(const point : TLatLon) : double;
var
  lat1, lat2, dLon, y, x, brng : double;
begin
  lat1 := DegToRad(Lat);
  lat2 := DegToRad(point.Lat);
  dLon := DegToRad(point.Lon - self.Lon);

  y := Sin(dLon) * Cos(lat2);
  x := Cos(lat1) * Sin(lat2) - Sin(lat1) * Cos(lat2) * Cos(dLon);
  brng := Math.arcTan2(y, x);
  Result := FloatingPointMod(RadToDeg(brng) + 360, 360);
end;

// Returns final bearing arriving at supplied destination point from this point; the final bearing
// will differ from the initial bearing by varying degrees according to distance and latitude
//
// @param   {LatLon} point: Latitude/longitude of destination point
// @returns {Number} Final bearing in degrees from North
function TLatLon.FinalBearingTo(const point : TLatLon) : double;
var
  lat1, lat2, dLon, y, x, brng : double;
begin
  // get initial bearing from supplied point back to this point...
  lat1 := DegToRad(point.Lat);
  lat2 := DegToRad(self.Lat);
  dLon := DegToRad(self.Lon - point.Lon);

  y := Sin(dLon) * Cos(lat2);
  x := Cos(lat1) * Sin(lat2) - Sin(lat1) * Cos(lat2) * Cos(dLon);
  brng := Math.ArcTan2(y, x);
  Result := FloatingPointMod( RadToDeg(brng) + 180, 360);
end;


// Returns the midpoint between this point and the supplied point.
//   see http://mathforum.org/library/drmath/view/51822.html for derivation
//
// @param   {LatLon} point: Latitude/longitude of destination point
// @returns {LatLon} Midpoint between this point and the supplied point
function TLatLon.MidPointTo(const point : TLatLon) : TLatLon;
var
  lat1, lon1, lat2, dLon, Bx, By, lat3, lon3 : double;
begin
  lat1 := DegToRad(self.Lat);
  lon1 := DegToRad(self.Lon);
  lat2 := DegToRad(point.Lat);
  dLon := DegToRad(point.Lon - Self.Lon);

  Bx := Cos(lat2) * Cos(dLon);
  By := Cos(lat2) * Sin(dLon);

  lat3 := Math.ArcTan2(Sin(lat1) + Sin(lat2), Sqrt((Cos(lat1) + Bx) * (Cos(lat1) + Bx) + By * By));
  lon3 := lon1 + Math.ArcTan2(By, Cos(lat1) + Bx);
  lon3 := FloatingPointMod((lon3 + 3 * PI), (2 * PI)) - PI;  // normalise to -180..+180º

  Result :=  TLatLon.Create(RadToDeg(lat3), RadToDeg(lon3));
end;

// Returns the destination point from this point having travelled the given distance (in km) on the
// given initial bearing (bearing may vary before destination is reached)
//
//   see http://williams.best.vwh.net/avform.htm#LL
//
// @param   {Number} brng: Initial bearing in degrees
// @param   {Number} dist: Distance in km
// @returns {LatLon} Destination point
function TLatLon.DestinationPoint(const brng : double; const dist : double) : TLatLon;
var
  dist1, brng1, lat1, lon1, lat2, lon2 : double;
begin
  dist1 :=  dist / self.Radius;  // convert dist to angular distance in radians
  brng1 := DegToRad(brng);  //
  lat1 := DegToRad(self.Lat);
  lon1 := DegToRad(self.Lon);

  lat2 := Math.ArcSin(Sin(lat1) * Cos(dist) +  Cos(lat1) * Sin(dist) * Cos(brng1));
  lon2 := lon1 + Math.ArcTan2(Sin(brng1) * Sin(dist1) * Cos(lat1),  Cos(dist1) - Sin(lat1) * Sin(lat2));
  lon2 := FloatingPointMod((lon2 + 3 * PI), (2 * PI)) - PI;  // normalise to -180..+180º

  Result := TLatLon.Create(RadToDeg(lat2), RadToDeg(lon2));
end;

// Returns the point of intersection of two paths defined by point and bearing
//
//   see http://williams.best.vwh.net/avform.htm#Intersection
//
// @param   {LatLon} p1: First point
// @param   {Number} brng1: Initial bearing from first point
// @param   {LatLon} p2: Second point
// @param   {Number} brng2: Initial bearing from second point
// @returns {LatLon} Destination point (null if no unique intersection defined)
function TLatLon.Intersection(const p1 : TLatLon; const brng1 : double; const p2 : TLatLon; const brng2: double) : TLatLon;
begin
//brng1 = typeof brng1 == 'number' ? brng1 : typeof brng1 == 'string' && trim(brng1)!='' ? +brng1 : NaN;
//  brng2 = typeof brng2 == 'number' ? brng2 : typeof brng2 == 'string' && trim(brng2)!='' ? +brng2 : NaN;
//  lat1 = p1._lat.toRad(), lon1 = p1._lon.toRad();
//  lat2 = p2._lat.toRad(), lon2 = p2._lon.toRad();
//  brng13 = brng1.toRad(), brng23 = brng2.toRad();
//  dLat = lat2-lat1, dLon = lon2-lon1;
//
//  dist12 = 2*Math.asin( Math.sqrt( Math.sin(dLat/2)*Math.sin(dLat/2) +
//    Math.cos(lat1)*Math.cos(lat2)*Math.sin(dLon/2)*Math.sin(dLon/2) ) );
//  if (dist12 == 0) return null;
//
//  // initial/final bearings between points
//  brngA = Math.acos( ( Math.sin(lat2) - Math.sin(lat1)*Math.cos(dist12) ) /
//    ( Math.sin(dist12)*Math.cos(lat1) ) );
//  if (isNaN(brngA)) brngA = 0;  // protect against rounding
//  brngB = Math.acos( ( Math.sin(lat1) - Math.sin(lat2)*Math.cos(dist12) ) /
//    ( Math.sin(dist12)*Math.cos(lat2) ) );
//
//  if (Math.sin(lon2-lon1) > 0) {
//    brng12 = brngA;
//    brng21 = 2*Math.PI - brngB;
//  } else {
//    brng12 = 2*Math.PI - brngA;
//    brng21 = brngB;
//  }
//
//  alpha1 = (brng13 - brng12 + Math.PI) % (2*Math.PI) - Math.PI;  // angle 2-1-3
//  alpha2 = (brng21 - brng23 + Math.PI) % (2*Math.PI) - Math.PI;  // angle 1-2-3
//
//  if (Math.sin(alpha1)==0 && Math.sin(alpha2)==0) return null;  // infinite intersections
//  if (Math.sin(alpha1)*Math.sin(alpha2) < 0) return null;       // ambiguous intersection
//
//  //alpha1 = Math.abs(alpha1);
//  //alpha2 = Math.abs(alpha2);
//  // ... Ed Williams takes abs of alpha1/alpha2, but seems to break calculation?
//
//  alpha3 = Math.acos( -Math.cos(alpha1)*Math.cos(alpha2) +
//                       Math.sin(alpha1)*Math.sin(alpha2)*Math.cos(dist12) );
//  dist13 = Math.atan2( Math.sin(dist12)*Math.sin(alpha1)*Math.sin(alpha2),
//                       Math.cos(alpha2)+Math.cos(alpha1)*Math.cos(alpha3) )
//  lat3 = Math.asin( Math.sin(lat1)*Math.cos(dist13) +
//                    Math.cos(lat1)*Math.sin(dist13)*Math.cos(brng13) );
//  dLon13 = Math.atan2( Math.sin(brng13)*Math.sin(dist13)*Math.cos(lat1),
//                       Math.cos(dist13)-Math.sin(lat1)*Math.sin(lat3) );
//  lon3 = lon1+dLon13;
//  lon3 = (lon3+3*Math.PI) % (2*Math.PI) - Math.PI;  // normalise to -180..+180º
//
//  return new LatLon(lat3.toDeg(), lon3.toDeg());
end;


// Returns the distance from this point to the supplied point, in km, travelling along a rhumb line
//
//   see http://williams.best.vwh.net/avform.htm#Rhumb
//
// @param   {LatLon} point: Latitude/longitude of destination point
// @returns {Number} Distance in km between this point and destination point
function TLatLon.RhumbDistanceTo(const point : TLatLon) : double;
var
  R, lat1, lat2, dLat, dLon, dPhi, q : double;
begin
  R := self.Radius;
  lat1 := DegToRad(self.Lat);
  lat2 := DegToRad(point.Lat);
  dLat := DegToRad(point.Lat - Self.Lat);
  dLon := DegToRad(Abs(point.Lon - self.Lon));
  dPhi := Ln(Tan(lat2 / 2 + PI / 4) / Tan(lat1 / 2 + PI / 4));

  if IsNan(dLat/dPhi)then begin
    q :=  Cos(lat1)
  end else begin
    q := dLat / dPhi;
  end;

  // if dLon over 180° take shorter rhumb across anti-meridian:
  if (Abs(dLon) > PI) then begin
    if dLon > 0 then
      dLon := -(2 * PI - dLon)
    else
      dlon := (2 * PI + dLon);
  end;

  Result := Sqrt(dLat * dLat + q * q * dLon * dLon) * R;

end;


// Returns the bearing from this point to the supplied point along a rhumb line, in degrees
//
// @param   {LatLon} point: Latitude/longitude of destination point
// @returns {Number} Bearing in degrees from North
function TLatLon.RhumbBearingTo(const point : TLatLon) : double;
var
  lat1 , lat2, dLon, dPhi, brng : double;
begin
  lat1 := DegToRad(self.Lat);
  lat2 := DegToRad(point.Lat);
  dLon := DegToRad(point.Lon - self.Lon);

  dPhi := Ln(Tan(lat2 / 2 + PI / 4) / Tan( lat1 / 2 + PI / 4));
  if (Abs(dLon) > PI) then begin
    if dLon > 0 then begin
      dLon :=  -(2 * PI - dLon);
    end else begin
      dLon := (2 * PI + dLon);
    end;
  end;

  brng := Math.ArcTan2(dLon, dPhi);

  Result := FloatingPointMod(RadToDeg(brng) + 360, 360);
end;


// Returns the destination point from this point having travelled the given distance (in km) on the
// given bearing along a rhumb line
//
// @param   {Number} brng: Bearing in degrees from North
// @param   {Number} dist: Distance in km
// @returns {LatLon} Destination point
function TLatLon.RhumbDestinationPoint(const brng : double; const dist : double) : TLatLon;
  var R, d, lat1, lon1, brng1, dLat, lat2, lon2, dPhi, q, dLon : double;
begin
  R := self.Radius;
  d := dist / R;  // d = angular distance covered on earth’s surface
  lat1 := DegToRad(self.Lat);
  lon1 := DegToRad(self.Lon);
  brng1 := DegToRad(brng);

  dLat := d * Cos(brng1);
  // nasty kludge to overcome ill-conditioned results around parallels of latitude:
  if (Abs(dLat) < 1e-10) then dLat := 0; // dLat < 1 mm

  lat2 := lat1 + dLat;
  dPhi := Ln(Tan(lat2 / 2 + PI / 4) / Tan(lat1 / 2 + PI / 4));

  if IsNan(dLat / dPhi) then begin
    q := Cos(lat1);
  end else begin
    q :=  dLat / dPhi;
  end;

  dLon := d * Sin(brng1) / q;

  // check for some daft bugger going past the pole, normalise latitude if so
  if (Abs(lat2) > PI / 2) then begin
    if lat2 > 0 then begin
      lat2 := PI - lat2;
    end else begin
      lat2 := -PI - lat2;
    end;
  end;

  lon2 := FloatingPointMod(lon1 + dLon + 3 * PI, 2 * PI) - PI;

  Result :=  TLatLon.Create(RadToDeg(lat2), RadToDeg(lon2));
end;

function TLatLon.RhumbMidpointTo (const point : TLatLon) : TLatLon;
var
  lat1, lon1, lat2, lon2, lat3, f1, f2, f3, lon3 : double;
begin
  lat1 := DegToRad(self.Lat);
  lon1 := DegToRad(self.Lon);
  lat2 := DegToRad(point.Lat);
  lon2 := DegToRad(point.Lon);

  if (Abs(lon2-lon1) > PI) then
    lon1 := lon1 + (2 * PI); // crossing anti-meridian

  lat3 := (lat1 + lat2) / 2;
  f1 := Tan(PI / 4 + lat1 / 2);
  f2 := Tan(PI / 4 + lat2 / 2);
  f3 := Tan(PI / 4 + lat3 / 2);
  lon3 := ((lon2 - lon1) * Ln(f3) + lon1 * Ln(f2) - lon2 * Ln(f1)) / ln(f2 / f1);

  if (Math.IsNan(lon3)) then
    lon3 := (lon1 + lon2) / 2; // parallel of latitude

  lon3 := FloatingPointMod(lon3 + 3 * PI,  2 * PI) - PI;  // normalise to -180..+180º

  Result := TLatLon.Create(RadToDeg(lat3), RadToDeg(lon3));
end;

end.
