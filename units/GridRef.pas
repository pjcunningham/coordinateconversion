unit GridRef;

interface

uses LatLon;

type

  TOSGridRef = record
    private
      fEasting : double;
      fNorthing : double;
    public
      constructor Create(const easting: double; const northing: double);
      class function LatLongToOSGrid(const point : TLatLon) : TOSGridRef; static;
      class function OSGridToLatLong(const gridref : TOSGridRef) : TLatLon; static;
      class function Parse(const value : string) : TOSGridRef; static;
      function AsString(const digits : integer = 10) : string;
      property Easting : double read fEasting;
      property Northing : double read fNorthing;
    end;

implementation

uses Math, SysUtils, StrUtils;

constructor TOSGridRef.Create(const easting: double; const northing: double);
begin
  fEasting := easting;
  fNorthing := northing;
end;

class function TOSGridRef.LatLongToOSGrid (const point : TLatLon) : TOSGridRef;
var
  easting, northing : double;
  lat, lon, a, b, F0, lat0, lon0, N0, E0, e2, n, n2, n3, cosLat, sinLat, nu, rho, eta2, Ma, Mb, Mc, Md, M : double;
  cos3lat, cos5lat, tan2lat, tan4lat, I, II, III, IIIA, IV, V, VI, dLon, dLon2, dLon3, dLon4, dlon5, dLon6 : Double;
begin
  lat := DegToRad(point.Lat);
  lon := DegToRad(point.lon);

  a := 6377563.396;
  b := 6356256.910;          // Airy 1830 major & minor semi-axes
  F0 := 0.9996012717;        // NatGrid scale factor on central meridian
  lat0 :=  DegToRad(49);
  lon0 := DegToRad(-2);      // NatGrid true origin is 49ºN,2ºW
  N0 := -100000;
  E0 := 400000;              // northing & easting of true origin, metres
  e2 := 1 - (b * b) / (a * a);     // eccentricity squared
  n := (a - b) / (a + b);
  n2 := n * n;
  n3 := n * n * n;

  cosLat := Cos(lat);
  sinLat := Sin(lat);
  nu := a * F0 / Sqrt(1 - e2 * sinLat *sinLat);              // transverse radius of curvature
  rho := a * F0 *(1 - e2)/ Power(1 - e2 * sinLat * sinLat, 1.5);  // meridional radius of curvature
  eta2 := nu/rho-1;

  Ma := (1 + n + (5/4)*n2 + (5/4)*n3) * (lat-lat0);
  Mb := (3 * n + 3 * n * n + (21 / 8) * n3) * Sin(lat - lat0) * Cos(lat + lat0);
  Mc := ((15 / 8) * n2 + (15 / 8) * n3) * Sin(2 *(lat - lat0)) * Cos(2 * (lat + lat0));
  Md := (35/24) * n3 * Sin(3 *(lat - lat0)) * Cos(3 * (lat + lat0));
  M := b * F0 * (Ma - Mb + Mc - Md);              // meridional arc
  cos3lat := cosLat * cosLat *cosLat;
  cos5lat := cos3lat * cosLat * cosLat;
  tan2lat := Tan(lat) * Tan(lat);
  tan4lat := tan2lat * tan2lat;

  I := M + N0;
  II := (nu / 2) * sinLat * cosLat;
  III := (nu / 24) * sinLat * cos3lat *(5 -tan2lat +9 * eta2);
  IIIA := (nu / 720) * sinLat * cos5lat *(61 -58 * tan2lat + tan4lat);
  IV := nu * cosLat;
  V := (nu / 6) * cos3lat *(nu / rho - tan2lat);
  VI := (nu / 120) * cos5lat * (5 - 18 * tan2lat + tan4lat + 14 * eta2 - 58 * tan2lat * eta2);

  dLon := lon - lon0;
  dLon2 := dLon * dLon;
  dLon3 := dLon2 * dLon;
  dLon4 := dLon3 * dLon;
  dLon5 := dLon4 * dLon;
  dLon6 := dLon5 * dLon;

  northing := I + II * dLon2 + III * dLon4 + IIIA * dLon6;
  easting := E0 + IV * dLon + V * dLon3 + VI * dLon5;

  Result := TOSGridRef.Create(Trunc(easting), Trunc(northing));
end;

class function TOSGridRef.OSGridToLatLong(const gridref : TOSGridRef) : TLatLon;
var
  easting, northing, a, b, F0,lat0,lon0,N0,E0,e2,n,n2,n3,M,Ma,Mb,Mc,Md,cosLat,sinLat,nu,rho,eta2,tanLat,tan2lat : double;
  tan4lat,tan6lat,secLat,nu3,nu5,nu7,VII,VIII,IX,X,XI,XII,XIIA,dE,dE2,dE3,dE4,dE5,dE6,dE7,lat,lon : double;
begin
  easting := gridref.Easting;
  northing := gridref.Northing;

  a := 6377563.396;
  b := 6356256.910;              // Airy 1830 major & minor semi-axes
  F0 := 0.9996012717;                             // NatGrid scale factor on central meridian
  lat0 := 49 * PI / 180;
  lon0 := - 2 * PI / 180;  // NatGrid true origin
  N0 := -100000;
  E0 := 400000;                     // northing & easting of true origin, metres
  e2 := 1 - (b * b) / (a * a);                          // eccentricity squared
  n := (a - b) /(a + b);
  n2 := n * n;
  n3 := n * n * n;

  lat := lat0;
  M := 0;
  while (N - N0 - M >= 0.00001) do begin // until < 0.01mm

    lat := (N - N0 - M) / (a * F0) + lat;

    Ma := (1 + n + (5/4)*n2 + (5/4)*n3) * (lat-lat0);
    Mb := (3*n + 3*n*n + (21/8)*n3) * Sin(lat-lat0) * Cos(lat+lat0);
    Mc := ((15/8)*n2 + (15/8)*n3) * Sin(2*(lat-lat0)) * Cos(2*(lat+lat0));
    Md := (35/24)*n3 * Sin(3*(lat-lat0)) * Cos(3*(lat+lat0));
    M := b * F0 * (Ma - Mb + Mc - Md);                // meridional arc

  end;

  cosLat := Cos(lat);
  sinLat := Sin(lat);
  nu := a*F0/Sqrt(1-e2*sinLat*sinLat);              // transverse radius of curvature
  rho := a*F0*(1-e2)/Power(1-e2*sinLat*sinLat, 1.5);  // meridional radius of curvature
  eta2 := nu/rho-1;

  tanLat := Math.tan(lat);
  tan2lat := tanLat*tanLat;
  tan4lat := tan2lat*tan2lat;
  tan6lat := tan4lat*tan2lat;
  secLat := 1/cosLat;
  nu3 := nu*nu*nu;
  nu5 := nu3*nu*nu;
  nu7 := nu5*nu*nu;
  VII := tanLat/(2*rho*nu);
  VIII := tanLat/(24*rho*nu3)*(5+3*tan2lat+eta2-9*tan2lat*eta2);
  IX := tanLat/(720*rho*nu5)*(61+90*tan2lat+45*tan4lat);
  X := secLat/nu;
  XI := secLat/(6*nu3)*(nu/rho+2*tan2lat);
  XII := secLat/(120*nu5)*(5+28*tan2lat+24*tan4lat);
  XIIA := secLat/(5040*nu7)*(61+662*tan2lat+1320*tan4lat+720*tan6lat);

  dE := (easting - E0);
  dE2 := dE*dE;
  dE3 := dE2*dE;
  dE4 := dE2*dE2;
  dE5 := dE3*dE2;
  dE6 := dE4*dE2;
  dE7 := dE5*dE2;
  lat := lat - VII*dE2 + VIII*dE4 - IX*dE6;
  lon := lon0 + X*dE - XI*dE3 + XII*dE5 - XIIA*dE7;

   Result :=  TLatLon.Create(RadToDeg(lat), RadToDeg(lon));
end;

function TOSGridRef.AsString(const digits : integer = 10) : string;
var
  e100k, n100k, l1, l2, e, n : integer;
  letPair : string;
begin
  // get the 100km-grid indices
  e100k := Floor(self.Easting / 100000);
  n100k := Floor(self.Northing / 100000);

  if (e100k < 0) or (e100k > 6) or (n100k < 0) or (n100k > 12) then begin
    Result := '';
    Exit;
  end;

  // translate those into numeric equivalents of the grid letters
  l1 := (19 - n100k) - (19 - n100k) mod 5 + Floor((e100k + 10) / 5);
  l2 := (19 - n100k) * 5 mod 25 + e100k mod 5;

  // compensate for skipped 'I' and build grid letter-pairs
  if (l1 > 7) then Inc(l1);
  if (l2 > 7) then Inc(l2);
  letPair := Chr(l1 + Ord('A')) + Chr(l2 + Ord('A'));

  // strip 100km-grid indices from easting & northing, and reduce precision
  e := Floor((Trunc(self.Easting) mod 100000) / Power(10, 5 - digits / 2));
  n := Floor((Trunc(self.Northing) mod 100000) / Power(10, 5 - digits / 2));

  Result := letPair + ' ' + Format('%.*d', [digits div 2, e]) + ' ' + Format('%.*d', [digits div 2, n]);

end;

class function TOSGridRef.Parse(const value : string) : TOSGridRef;
var
  gridref : string;
  l1, l2, e, n : integer;
begin
  gridref := UpperCase(Trim(value));
  //get numeric values of letter references, mapping A->0, B->1, C->2, etc:
  l1 := Ord(gridref[1]) - Ord('A');
  l2 := Ord(gridref[2]) - Ord('A');
  // shuffle down letters after 'I' since 'I' is not used in grid:
  if (l1 > 7) then Dec(l1);
  if (l2 > 7) then Dec(l2);

    // convert grid letters into 100km-square indexes from false origin (grid square SV):
  e := ((l1 - 2) mod 5) * 5 + (l2 mod 5);
  n := (19 - Floor(l1 / 5) * 5) - Floor(l2 / 5);
  if (e < 0) or (e > 6) or (n < 0) or ( n > 12) then begin
    Result := TOSGridRef.Create(NaN, NaN);
    Exit;
  end;

  // skip grid letters to get numeric part of ref, stripping any spaces:
  gridref := StringReplace(RightStr(gridref, Length(gridref) - 2), ' ', '', [rfReplaceAll, rfIgnoreCase]);

  // append numeric part of references to grid index:
  e := StrToInt(IntToStr(e) + LeftStr(gridref, Length(gridref) div 2));
  n := StrToInt(IntToStr(n) + RightStr(gridref, Length(gridref) div 2));

  // normalise to 1m grid, rounding up to centre of grid square:
  case Length(gridref) of
    0 : begin
        e := e + 50000;
        n := n + 50000;
      end;
    2 : begin
        e := e + 5000;
        n := n + 5000;
      end;
    4 : begin
        e := e + 500;
        n := n + 500;
      end;
    6 : begin
        e := e + 50;
        n := n + 50;
      end;
    8 : begin
        e := e + 5;
        n := n + 5;
      end;
    10 : // 10-digit refs are already 1m
    else begin
      Result := TOSGridRef.Create(NaN, NaN);
      Exit;
    end;
  end;

  Result := TOSGridRef.Create(e, n);
end;

end.
