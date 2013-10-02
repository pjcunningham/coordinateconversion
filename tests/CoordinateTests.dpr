program CoordinateTests;
{

  Delphi DUnit Test Project
  -------------------------
  This project contains the DUnit test framework and the GUI/Console test runners.
  Add "CONSOLE_TESTRUNNER" to the conditional defines entry in the project options
  to use the console test runner.  Otherwise the GUI test runner will be used by
  default.

}

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  Forms,
  TestFramework,
  GUITestRunner,
  TextTestRunner,
  GeoUnitTests in 'GeoUnitTests.pas',
  Geo in '..\units\Geo.pas',
  CoordTransformTests in 'CoordTransformTests.pas',
  CoordTransform in '..\units\CoordTransform.pas',
  LatLon in '..\units\LatLon.pas',
  GridRef in '..\units\GridRef.pas',
  GridRefUnitTests in 'GridRefUnitTests.pas';

{R *.RES}

begin
  Application.Initialize;
  if IsConsole then
    with TextTestRunner.RunRegisteredTests do
      Free
  else
    GUITestRunner.RunRegisteredTests;
end.

