unit GeoUnitTests;

interface

uses
  TestFramework;

type

  // Test methods for unit Geo.pas

  TGeoUnitTest = class(TTestCase)
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
    procedure Test10;
  end;

implementation

uses Math, Geo;

procedure TGeoUnitTest.Test00;
var
  test : string;
begin
  test := ToDMS(NaN, TDMSFormat.D, TDecimalPlaces.Zero);
  CheckEquals('', test, 'Not a number');
end;

procedure TGeoUnitTest.Test01;
var
  test : string;
begin
  test := ToDMS(Infinity, TDMSFormat.D, TDecimalPlaces.Zero);
  CheckEquals('', test, 'Infinity');
end;

procedure TGeoUnitTest.Test02;
var
  test : string;
begin
  test := ToDMS(0.0, TDMSFormat.D, TDecimalPlaces.Zero);
  CheckEquals('000º', test, 'Zero Degrees, Zero DP');
end;

procedure TGeoUnitTest.Test03;
var
  test : string;
begin
  test := ToDMS(0.0, TDMSFormat.D, TDecimalPlaces.Two);
  CheckEquals('000.00º', test, 'Zero Degrees, Two DP');
end;

procedure TGeoUnitTest.Test04;
var
  test : string;
begin
  test := ToDMS(0.0, TDMSFormat.D, TDecimalPlaces.Four);
  CheckEquals('000.0000º', test, 'Zero Degrees, Four DP');
end;

procedure TGeoUnitTest.Test05;
var
  test : string;
begin
  test := ToDMS(0.0, TDMSFormat.DM, TDecimalPlaces.Zero);
  CheckEquals('000º00''', test, 'Zero Degrees Minutes, Zero DP');
end;

procedure TGeoUnitTest.Test06;
var
  test : string;
begin
  test := ToDMS(0.0, TDMSFormat.DM, TDecimalPlaces.Two);
  CheckEquals('000º00.00''', test, 'Zero Degrees Minutes, Two DP');
end;

procedure TGeoUnitTest.Test07;
var
  test : string;
begin
  test := ToDMS(0.0, TDMSFormat.DM, TDecimalPlaces.Four);
  CheckEquals('000º00.0000''', test, 'Zero Degrees Minutes, Four DP');
end;

procedure TGeoUnitTest.Test08;
var
  test : string;
begin
  test := ToDMS(0.0, TDMSFormat.DMS, TDecimalPlaces.Zero);
  CheckEquals('000º00''00"', test, 'Zero Degrees Minutes Seconds, Zero DP');
end;

procedure TGeoUnitTest.Test09;
var
  test : string;
begin
  test := ToDMS(0.0, TDMSFormat.DMS, TDecimalPlaces.Two);
  CheckEquals('000º00''00.00"', test, 'Zero Degrees Minutes Seconds, Two DP');
end;

procedure TGeoUnitTest.Test10;
var
  test : string;
begin
  test := ToDMS(0.0, TDMSFormat.DMS, TDecimalPlaces.Four);
  CheckEquals('000º00''00.0000"', test, 'Zero Degrees Minutes Seconds, Four DP');
end;

initialization
  // Register any test cases with the test runner
  RegisterTest(TGeoUnitTest.Suite);
end.

