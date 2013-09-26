program TestProject;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  CoordTransform in '..\units\CoordTransform.pas',
  Geo in '..\units\Geo.pas',
  LatLon in '..\units\LatLon.pas';

var
  p1, p2, p3, midpoint : TLatLon;
  dist, bearing, finalbearing : double;
begin
  try
    p1 := TLatLon.Create(51.5136, -0.0983);
    p2 := TLatLon.Create(51.4778, -0.0015);

    dist := p1.DistanceTo(p2);  // in km
    bearing := p1.BearingTo(p2);   // in degrees clockwise from north
    finalbearing := p1.FinalBearingTo(p2);
    midpoint := p1.MidPointTo(p2);
    Writeln(dist);
    Writeln(bearing);
    Writeln(finalbearing);
    Writeln(midpoint.Lon);
    Writeln(midpoint.Lat);

    p3 := ConvertOSGB36toWGS84(p1);
    Writeln(p3.Lat);
    Writeln(p2.Lon);



    Writeln('Enter any key to quit ...');
    Readln;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
