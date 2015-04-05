unit GridRefUnitTests;

interface

uses
  TestFramework;

type

  // Test methods for unit Geo.pas

  TGridRefUnitTest = class(TTestCase)
  private
  public
  published
    procedure Test00;
    procedure Test01;
    procedure Test02;
    procedure Test03;
    procedure Test04;
    procedure Test05;
    procedure Test06;
    procedure Test07;
    procedure Test08;
    procedure Test09;
  end;

implementation

uses Math, CoordTransform, LatLon, GridRef, SysUtils;

procedure TGridRefUnitTest.Test00;
var
  pWGS84, pOSGB : TLatLon;
  gr : TOSGridRef;
  d : double;
begin
  pWGS84 := TLatLon.Create(53.333373, -0.150160 );
  pOSGB := ConvertWGS84toOSGB36(pWGS84);
  gr := TOSGridRef.LatLongToOSGrid(pOSGB);
  CheckTrue((gr.Easting = 523280) and (gr.Northing = 383424), 'Convert WGS84 53.333373, -0.150160 to OSGB36 to OS Grid');
end;

procedure TGridRefUnitTest.Test01;
var
  pWGS84, pOSGB : TLatLon;
  gr : TOSGridRef;
  d : double;
begin
  pOSGB := TLatLon.Create(53.333075, -0.148477);
  gr := TOSGridRef.LatLongToOSGrid(pOSGB);
  CheckTrue((gr.Easting = 523280) and (gr.Northing = 383424), 'Convert OSGB36 53.333075, -0.148477 to OS Grid');
end;


procedure TGridRefUnitTest.Test02;
var
  gr : TOSGridRef;
begin
  gr := TOSGridRef.Parse('TF 23280 83424');
  CheckTrue((gr.Easting = 523280) and (gr.Northing = 383424), ' Parse TF 23280 83424');
end;

procedure TGridRefUnitTest.Test03;
var
  gr : TOSGridRef;
begin
  gr := TOSGridRef.Parse('TF2328083424');
  CheckTrue((gr.Easting = 523280) and (gr.Northing = 383424), ' Parse TF2328083424');
end;

procedure TGridRefUnitTest.Test04;
var
  gr : TOSGridRef;
  temp : string;
begin
  gr := TOSGridRef.Create(523280, 383424);
  temp := gr.AsString();
  CheckEquals('TF 23280 83424' , temp, '523280, 383424 as string');
end;

procedure TGridRefUnitTest.Test05;
var
  gr : TOSGridRef;
  temp : string;
begin
  gr := TOSGridRef.Create(523280, 383424);
  temp := gr.AsString(8);
  CheckEquals('TF 2328 8342' , temp, '523280, 383424 as string');
end;

procedure TGridRefUnitTest.Test06;
var
  gr : TOSGridRef;
  temp : string;
begin
  gr := TOSGridRef.Create(523280, 383424);
  temp := gr.AsString(6);
  CheckEquals('TF 232 834' , temp, '523280, 383424 as string');
end;

procedure TGridRefUnitTest.Test07;
var
  OS : TOSGridRef;
  pWGS84, pOSGB : TLatLon;
  temp1, temp2 : string;
begin
  OS := TOSGridRef.Parse('TF2328083424');
  pOSGB := TOSGridRef.OSGridToLatLong(OS);
  pWGS84 := ConvertOSGB36toWGS84(pOSGB);
  temp1 := FormatFloat('##0.00000', pWGS84.Lat);
  temp2 := FormatFloat('##0.00000', pWGS84.Lon);
  CheckTrue((temp1 = '53.33337') and (temp2 = '-0.15016'), 'TF 2328083424 as WGS84');
end;

procedure TGridRefUnitTest.Test08;
var
  OS : TOSGridRef;
  pWGS84, pOSGB : TLatLon;
  temp1, temp2 : string;
begin
  OS := TOSGridRef.Parse('TF 2328083424');
  pOSGB := TOSGridRef.OSGridToLatLong(OS);
  pWGS84 := ConvertOSGB36toWGS84(pOSGB);
  temp1 := FormatFloat('##0.00000', pWGS84.Lat);
  temp2 := FormatFloat('##0.00000', pWGS84.Lon);
  CheckTrue((temp1 = '53.33337') and (temp2 = '-0.15016'), 'TF 2328083424 as WGS84');
end;

procedure TGridRefUnitTest.Test09;
var
  OS : TOSGridRef;
  pWGS84, pOSGB : TLatLon;
  temp1, temp2 : string;
begin
  OS := TOSGridRef.Parse('TF 23280 83424');
  pOSGB := TOSGridRef.OSGridToLatLong(OS);
  pWGS84 := ConvertOSGB36toWGS84(pOSGB);
  temp1 := FormatFloat('##0.00000', pWGS84.Lat);
  temp2 := FormatFloat('##0.00000', pWGS84.Lon);
  CheckTrue((temp1 = '53.33337') and (temp2 = '-0.15016'), 'TF 2328083424 as WGS84');
end;


initialization
  // Register any test cases with the test runner
  RegisterTest(TGridRefUnitTest.Suite);
end.
