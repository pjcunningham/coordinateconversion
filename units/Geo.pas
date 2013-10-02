unit Geo;

interface

type

  TDMSFormat = (D, DM, DMS);
  TDecimalPlaces = (Zero = 0, Two = 2, Four = 4);

  function FloatingPointMod(const Dividend, Divisor : double) : double;
  function ParseDMS(const value : string) : double;
  function ToDMS (const deg: double; const dmsFormat : TDMSFormat; const dp : TDecimalPlaces) : string;
  function ToLat(const deg : double; const format : TDMSFormat; const dp : TDecimalPlaces) : string;
  function ToLon(const deg : double; const format : TDMSFormat; const dp : TDecimalPlaces) : string;
  function ToBearing(const deg : double; const format : TDMSFormat; const dp : TDecimalPlaces) : string;

implementation

uses Math, SysUtils, StrUtils;

function FloatingPointMod(const Dividend, Divisor : double) : double;
var
  quotient : integer;
begin
  quotient := Trunc( Dividend / Divisor);
  Result := Dividend - (quotient * Divisor);
end;

// Parses string representing degrees/minutes/seconds into numeric degrees
//
// This is very flexible on formats, allowing signed decimal degrees, or deg-min-sec optionally
// suffixed by compass direction (NSEW). A variety of separators are accepted (eg 3º 37' 09"W)
// or fixed-width format without separators (eg 0033709W). Seconds and minutes may be omitted.
// (Note minimal validation is done).
//
// @param   {String|Number} dmsStr: Degrees or deg/min/sec in variety of formats
// @returns {Number} Degrees as decimal number
// @throws  {TypeError} dmsStr is an object, perhaps DOM object without .value?
function parseDMS(const value : string) : double;
var
  a : double;
  dms : string;
begin

  try
    Result := StrToFloat(value);
  except

    Result := NaN;
  end;
//  // check for signed decimal degrees without NSEW, if so return it directly
//  if (typeof dmsStr === 'number' && isFinite(dmsStr)) return Number(dmsStr);
//
//  // strip off any sign or compass dir'n & split out separate d/m/s
//  var dms = String(dmsStr).trim().replace(/^-/,'').replace(/[NSEW]$/i,'').split(/[^0-9.,]+/);
//  if (dms[dms.length-1]=='') dms.splice(dms.length-1);  // from trailing symbol
//
//  if (dms == '') return NaN;
//
//  // and convert to decimal degrees...
//  switch (dms.length) {
//    case 3:  // interpret 3-part result as d/m/s
//      var deg = dms[0]/1 + dms[1]/60 + dms[2]/3600;
//      break;
//    case 2:  // interpret 2-part result as d/m
//      var deg = dms[0]/1 + dms[1]/60;
//      break;
//    case 1:  // just d (possibly decimal) or non-separated dddmmss
//      var deg = dms[0];
//      // check for fixed-width unseparated format eg 0033709W
//      //if (/[NS]/i.test(dmsStr)) deg = '0' + deg;  // - normalise N/S to 3-digit degrees
//      //if (/[0-9]{7}/.test(deg)) deg = deg.slice(0,3)/1 + deg.slice(3,5)/60 + deg.slice(5)/3600;
//      break;
//    default:
//      return NaN;
//  }
//  if (/^-|[WS]$/i.test(dmsStr.trim())) deg = -deg; // take '-', west and south as -ve
//  return Number(deg);
end;


// Convert decimal degrees to deg/min/sec format
//  - degree, prime, double-prime symbols are added, but sign is discarded, though no compass
//    direction is added
//
// @private
// @param   {Number} deg: Degrees
// @param   {String} [format=dms]: Return value as 'd', 'dm', 'dms'
// @param   {Number} [dp=0|2|4]: No of decimal places to use - default 0 for dms, 2 for dm, 4 for d
// @returns {String} deg formatted as deg/min/secs according to specified format
// @throws  {TypeError} deg is an object, perhaps DOM object without .value?

function ToDMS(const deg: double; const dmsFormat : TDMSFormat; const dp : TDecimalPlaces) : string;
var
  degrees, minutes, seconds : double;
begin
  Result := '';
  if (IsNaN(deg) or IsInfinite(deg)) then exit ;  // give up here if we can't make a number from deg

  case dmsFormat of
     D : begin
       case dp of
         Zero: Result := FormatFloat('000."º"', degrees);
         Two: Result := FormatFloat('000.00"º"', degrees);
         Four: Result := FormatFloat('000.0000"º"', degrees)
       end;
    end;
    DM :  begin
      minutes := deg * 60;  // convert degrees to minutes
      degrees := Floor(minutes / 60);    // get degress
      minutes := FloatingPointMod(minutes, 60); // get whole minutes
       case dp of
         Zero: Result := FormatFloat('000"º"', degrees) + FormatFloat('00"''"', minutes);
         Two: Result := FormatFloat('000"º"', degrees) + FormatFloat('00.00"''"', minutes);
         Four: Result := FormatFloat('000"º"', degrees) + FormatFloat('00.0000"''"', minutes);
       end;
    end;
    DMS : begin
      seconds := ( deg * 3600);  // convert degrees to seconds & round
      degrees := Floor(seconds / 3600);
      minutes := FloatingPointMod(Floor(seconds / 60), 60);
      seconds := FloatingPointMod(seconds, 60);
       case dp of
         Zero: Result := FormatFloat('000"º"', degrees) + FormatFloat('00"''"', minutes) + FormatFloat('00', seconds) + '"';
         Two: Result := FormatFloat('000"º"', degrees) + FormatFloat('00"''"', minutes) + FormatFloat('00.00', seconds) + '"';
         Four: Result := FormatFloat('000"º"', degrees) + FormatFloat('00"''"', minutes) + FormatFloat('00.0000', seconds) + '"';
       end;
    end;
  end;

end;

// Convert numeric degrees to deg/min/sec latitude (suffixed with N/S)
//
// @param   {Number} deg: Degrees
// @param   {String} [format=dms]: Return value as 'd', 'dm', 'dms'
// @param   {Number} [dp=0|2|4]: No of decimal places to use - default 0 for dms, 2 for dm, 4 for d
// @returns {String} Deg/min/seconds

function ToLat(const deg : double; const format : TDMSFormat; const dp : TDecimalPlaces) : string;
var lat : string;
begin
  lat := ToDMS(deg, format, dp);
  Result := RightStr(lat, Length(lat) - 1);
  if (deg < 0) then begin
    Result := Result + 'S';
  end else begin
    Result := Result + 'N';
  end;
end;

// Convert numeric degrees to deg/min/sec longitude (suffixed with E/W)
//
// @param   {Number} deg: Degrees
// @param   {String} [format=dms]: Return value as 'd', 'dm', 'dms'
// @param   {Number} [dp=0|2|4]: No of decimal places to use - default 0 for dms, 2 for dm, 4 for d
// @returns {String} Deg/min/seconds
function ToLon(const deg : double; const format : TDMSFormat; const dp : TDecimalPlaces) : string;
var lon : string;
begin
  lon := ToDMS(deg, format, dp);
  if (deg < 0) then begin
    lon := lon + 'W';
  end else begin
    lon := lon + 'E';
  end;
end;

// Convert numeric degrees to deg/min/sec as a bearing (0º..360º)
//
// @param   {Number} deg: Degrees
// @param   {String} [format=dms]: Return value as 'd', 'dm', 'dms'
// @param   {Number} [dp=0|2|4]: No of decimal places to use - default 0 for dms, 2 for dm, 4 for d
// @returns {String} Deg/min/seconds

function ToBearing(const deg : double; const format : TDMSFormat; const dp : TDecimalPlaces) : string;
var
  deg1 : double;
  bearing : string;
begin
  deg1 := FloatingPointMod(deg + 360, 360);  // normalise -ve values to 180º..360º
  bearing :=  ToDMS(deg1, format, dp);
  Result := StringReplace(Bearing, '360', '0', []);  // just in case rounding took us up to 360º!
end;

end.
