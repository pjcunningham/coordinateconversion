unit CoordTransform;

interface

uses LatLon;

  function ConvertOSGB36toWGS84(pOSGB36 : TLatLon) : TLatLon;
  function ConvertWGS84toOSGB36(pWGS84 : TLatLon) : TLatLon;

implementation

uses Math;

type

  TEllipse = record
    a : double;
    b : double;
    f : double;
  end;

  TDatumTransform = record
    tx : double;
    ty : double;
    tz : double;
    rx : double;
    ry : double;
    rz : double;
    s : double;
  end;

  TEllipses = record
      WGS84 : TEllipse;
      GRS80 : TEllipse;
      Airy1830: TEllipse;
      AiryModified : TEllipse;
      Intl1924 : TEllipse;
  end;

  TDatumTransforms = record
    toOSGB36 : TDatumTransform;
    toED50 : TDatumTransform;
    toIrl1975 : TDatumTransform;
  end;

const

  ELLIPSES : TEllipses = (
    WGS84 : ( a : 6378137; b : 6356752.3142; f : 1/298.257223563);
    GRS80 : ( a : 6378137; b : 6356752.314140; f : 1/298.257222101);
    Airy1830 : ( a : 6377563.396; b : 6356256.910; f : 1/299.3249646);
    AiryModified : ( a: 6377340.189; b: 6356034.448; f: 1/299.32496);
    Intl1924 : ( a: 6378388.000; b: 6356911.946; f: 1/297.0);
  );

  DATUMS : TDatumTransforms = (
    toOSGB36 : (tx : -446.448; ty : 125.157; tz : -542.060; rx : -0.1502; ry : -0.2470; rz : -0.8421; s :   20.4894);
    toED50 : (tx : 89.5; ty : 93.8; tz : 123.1; rx : 0.0; ry : 0.0; rz : 0.156; s : -1.2);
    toIrl1975 : (tx : -482.530; ty : 130.596; tz : -564.557; rx : -1.042; ry : -0.214; rz : -0.631; s :-8.150);
  );

  function ConvertEllipsoid(point : TLatLon; e1 : TEllipse; t : TDatumTransform; e2: TEllipse) : TLatLon; forward;

function ConvertOSGB36toWGS84(pOSGB36 : TLatLon) : TLatLon;
var
  txToOSGB36 : TDatumTransform;
  txFromOSGB36 : TDatumTransform;
begin
  txToOSGB36 := DATUMS.toOSGB36;
  with txFromOSGB36 do begin
    tx := - txToOSGB36.tx;
    ty := - txToOSGB36.ty;
    tz := - txToOSGB36.tz;
    rx := - txToOSGB36.rx;
    ry := - txToOSGB36.ry;
    rz := - txToOSGB36.rz;
    s :=  - txToOSGB36.s;
  end;
  Result := ConvertEllipsoid(pOSGB36, ELLIPSES.Airy1830, txFromOSGB36, ELLIPSES.WGS84);
end;

function ConvertWGS84toOSGB36(pWGS84 : TLatLon) : TLatLon;
begin
  Result := ConvertEllipsoid(pWGS84, ELLIPSES.WGS84, DATUMS.toOSGB36, ELLIPSES.Airy1830);
end;

function ConvertEllipsoid(point : TLatLon; e1 : TEllipse; t : TDatumTransform; e2: TEllipse) : TLatLon;
var
  lat, lon : double;
  a, b : double;
  sinPhi, cosPhi, sinLambda, cosLambda, H : double;
  eSq, nu, x1, y1, z1, tx, ty, tz, rx, ry, rz, s1, x2, y2, z2 : double;
  precision, p, phi, phiP, lambda : double;
begin

  lat := DegToRad(point.Lat);
  lon := DegToRad(point.Lon);

  a := e1.a;
  b := e1.b;

  sinPhi := Sin(lat);
  cosPhi := Cos(lat);
  sinLambda := Sin(lon);
  cosLambda := Cos(lon);
  H := 24.7;  // for the moment

  eSq := (a * a - b * b) / (a * a);
  nu := a / Sqrt(1 - eSq * sinPhi * sinPhi);

  x1 := (nu + H) * cosPhi * cosLambda;
  y1 := (nu + H) * cosPhi * sinLambda;
  z1 := ((1 - eSq) * nu + H) * sinPhi;

  // -- 2: apply helmert transform using appropriate params

  tx := t.tx;
  ty := t.ty;
  tz := t.tz;
  rx := DegToRad(t.rx / 3600);  // normalise seconds to radians
  ry := DegToRad(t.ry / 3600);
  rz := DegToRad(t.rz / 3600);
  s1 := t.s / 1e6 + 1; // normalise ppm to (s+1)

  // apply transform
  x2 := tx + x1 * s1 - y1 * rz + z1 * ry;
  y2 := ty + x1 * rz + y1 * s1 - z1 * rx;
  z2 := tz - x1 * ry + y1 * rx + z1 * s1;

  // -- 3: convert cartesian to polar coordinates (using ellipse 2)

  a := e2.a;
  b := e2.b;
  precision := 4 / a;  // results accurate to around 4 metres

  eSq := (a * a - b * b) / (a * a);
  p := Sqrt(x2*x2 + y2*y2);
  phi := Math.ArcTan2(z2, p*(1-eSq));
  phiP := 2 * Pi;
  while (Abs(phi-phiP) > precision) do begin
    nu := a / Sqrt(1 - eSq * Sin(phi) * Sin(phi));
    phiP := phi;
    phi := Math.ArcTan2(z2 + eSq * nu * Sin(phi), p);
  end;
  lambda := Math.ArcTan2(y2, x2);
  H := p / Cos(phi) - nu;

  Result := TLatLon.Create(RadToDeg(phi), RadToDeg(lambda), H);
end;

end.
