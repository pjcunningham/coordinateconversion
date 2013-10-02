unit CoordTransformTests;

interface

uses
  TestFramework;

type

  // Test methods for unit Geo.pas

  TCoordTransformUnitTest = class(TTestCase)
  private
  public
  published
    procedure Test00;
    procedure Test01;
  end;

implementation

uses Math, CoordTransform, LatLon;

procedure TCoordTransformUnitTest.Test00;
var
  pWGS84, pOSGB36 : TLatLon;
begin
  pWGS84 := TLatLon.Create(53.333373, -0.150160);
  pOSGB36 := ConvertWGS84toOSGB36(pWGS84);
  CheckTrue((pOSGB36.Lat = 53.333075) and (pOSGB36.Lon = -0.148477), 'Convert WGS84 53.333373, -0.150160 to OSGB36');
end;

procedure TCoordTransformUnitTest.Test01;
var
  pWGS84, pOSGB36 : TLatLon;
begin
  pOSGB36 := TLatLon.Create(53.333075, -0.148477);
  pWGS84 := ConvertOSGB36toWGS84(pOSGB36);
  CheckTrue((pWGS84.Lat = 53.333373) and (pWGS84.Lon = -0.150160), 'Convert OSGB36 53.333075 -0.148477 to WGS84');
end;

initialization
  // Register any test cases with the test runner
  RegisterTest(TCoordTransformUnitTest.Suite);
end.
