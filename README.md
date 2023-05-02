# clip

"Calculator Language for Immediate Processing"

It is an engine for calculation processing in the CLIP language.

For the CLIP language, see "http://www5d.biglobe.ne.jp/~satis/clip/language_e.html".

## Use this package as a library

pubspec.yaml
```yml
dependencies:
  clip:
    git:
      url: https://github.com/SatisKia/dart_clip.git
      ref: HEAD
```

----------

## EasyClip

It provides the ability to easily run the CLIP engine from Dart.

```dart
import 'package:clip/extras/easyclip.dart';
```

### Overwriting functions

```dart
assertProc = ( int num, String? func ){
  // Returns true if processing is stopped when assertion fails
  return false;
};
errorProc = ( int err, int num, String func, String token ){
  // The following is an example of generating a string
  String str = (((err & CLIP_PROC_WARN) != 0) ? "warning:" : "error:") + intToString( err.toDouble(), 16, 4 ) + " line:$num";
};

printAnsComplex = ( String real, String imag ){
  // The following is an example of generating a string
  String str = real + imag;
};
printAnsMultiPrec = ( String str ){
};
printAnsMatrix = ( ClipParam param, ClipToken array ){
  // The following is an example of generating a string
  String str = curClip().getArrayTokenString( param, array, 0 );
};
printWarn = ( String warn, int num, String func ){
  // The following is an example of generating a string
  String str = "warning: ";
  if( func.isNotEmpty ){
    str += "$func: ";
  }
  if( num > 0 ){
    str += "line:$num ";
  }
  str += warn;
};
printError = ( String error, int num, String func ){
  // The following is an example of generating a string
  String str = "error: ";
  if( func.isNotEmpty ){
    str += "$func: ";
  }
  if( num > 0 ){
    str += "line:$num ";
  }
  str += error;
};

doCommandClear = (){
  // Function called when command ":clear" is executed
};
doCommandPrint = ( ClipProcPrint? topPrint, bool flag ){
  // Functions called when the commands ":print" / ":println" are executed
  // When command ":print", false is passed to flag, and when command ":println", true is passed to flag.
  // The following is an example of generating a string
  String str = "";
  ClipProcPrint? cur = topPrint;
  while( cur != null ){
    if( cur.string() != null ){
      ParamString tmp = ParamString( cur.string() );
      tmp.escape().replaceNewLine( "\n" );
      str += tmp.str();
    }
    cur = cur.next();
  }
  if( flag ){
    str += "\n";
  }
};
doCommandGWorld = ( int width, int height ){
  // Function called when command ":gworld" is executed
};
doCommandGWorld24 = ( int width, int height ){
  // Function called when command ":gworld24" is executed
};
```

When operating the EasyClip object inside the overwrite function, get the EasyClip object as follows.

```dart
EasyClip clip = curClip();
```

When manipulating the Canvas object inside the overwrite function, get the Canvas object as follows.

```dart
Canvas canvas = curCanvas();
```

### Object construction

```dart
EasyClip clip = EasyClip();
```

### Set a value for a variable

```dart
clip.setValue( 'a', 12.345 ); // @a in CLIP
clip.setComplex( 'b', 12.3, 4.5 ); // @b in CLIP
clip.setFract( 'c', -123, 45 ); // @c in CLIP
clip.setMultiPrec( 'a', array/*MPData*/ ); // @@a in CLIP
```

### Set values in the array

```dart
clip.setVector( 'a', [1,2,3,4,5,6] ); // @@a{1 2 3 4 5 6}
clip.setComplexVector( 'b', [1,0,2], [0,1,1] ); // @@b{1 i 2\+i}
clip.setFractVector( 'c', [1,-1], [3,3] );
clip.setMatrix( 'd', [[1,2,3],[4,5,6],[7,8,9]] ); // @@d{{1 2 3}{4 5 6}{7 8 9}}
clip.setComplexMatrix( 'e', [[3,2],[2,5]], [[0,1],[-1,0]] ); // @@e{{3 2\+i}{2\-i 5}}
clip.setFractMatrix( 'f', [[1,-1],[-2,2]], [[3,3],[3,3]] );
clip.setMatrix( 'g', matrix/*MathMatrix*/ );
clip.setArrayValue( 'h', [0, 0], 12 ); // @@h 0 0
clip.setArrayValue( 'h', [0, 1], 34 ); // @@h 0 1
clip.setArrayValue( 'h', [1, 0], 56 ); // @@h 1 0
clip.setArrayValue( 'h', [1, 1], 78 ); // @@h 1 1
clip.setArrayComplex( 'i', [0], 12.3, 4.5 ); // @@i 0
clip.setArrayFract( 'j', [2], 3, 7 ); // @@j 2
clip.setString( 's', "Hello World!!" );
```

### Check the value of the variable

```dart
double value = clip.getValue( 'a' ).toFloat();
double value = clip.getValue( 'b' ).real();
double value = clip.getValue( 'b' ).imag();
bool isMinus = clip.getValue( 'c' ).fractMinus();
double value = clip.getValue( 'c' ).num();
double value = clip.getValue( 'c' ).denom();
MPData array = clip.getMultiPrec( 'a' ); // MPData object
String string = clip.getComplexString( 'b' );
String string = clip.getFractString( 'c', false ); // Improper
String string = clip.getFractString( 'c', true ); // Mixed
String string = clip.getMultiPrecString( 'a' );
```

Since the return value of the getValue function is a MathValue object, you can use functions other than the toFloat, real, imag, fractMinus, num, and denom functions.

### Check the values in the array

```dart
List<dynamic> array = clip.getArray( 'a' ); // Forcibly convert to Dart Array
List<dynamic> array = clip.getArray( 'a', 1 ); // One-dimensional element
List<dynamic> array = clip.getArray( 'a', 2 ); // Two-dimensional element
List<dynamic> array = clip.getArray( 'a', N ); // N-dimensional element
String string = "@@d = ${clip.getArrayString( 'd', 6 )}";
String string = clip.getString( 's' );
```

### Check the value of the calculation result

```dart
double value = clip.getAnsValue().toFloat();
double value = clip.getAnsValue().real();
double value = clip.getAnsValue().imag();
bool isMinus = clip.getAnsValue().fractMinus();
double value = clip.getAnsValue().num();
double value = clip.getAnsValue().denom();
MPData array = clip.getAnsMultiPrec(); // MPData object
MathMatrix matrix = clip.getAnsMatrix(); // MathMatrix object
String string = "Ans = ${clip.getAnsMatrixString( 6 )}";
String string = clip.getAnsMultiPrecString();
```

Since the return value of the getAnsValue function is a MathValue object, you can use functions other than the toFloat, real, imag, fractMinus, num, and denom functions.

### various settings

A group of functions that execute CLIP setting commands directly from Dart.

**Type specification**

```dart
clip.setMode( mode, param1, param2 );
```

| `mode` | Meaning | `param1` | `param2` |
| --- | --- | --- | --- |
| CLIP_MODE_E_FLOAT | Double precision floating point type (exponential notation) | Display accuracy | - |
| CLIP_MODE_F_FLOAT | Double precision floating point type (decimal point notation) | Display accuracy | - |
| CLIP_MODE_G_FLOAT | Double precision floating point type | Display accuracy | - |
| CLIP_MODE_E_COMPLEX | Complex type (exponential notation) | Display accuracy | - |
| CLIP_MODE_F_COMPLEX | Complex type (decimal point notation) | Display accuracy | - |
| CLIP_MODE_G_COMPLEX | Complex type | Display accuracy | - |
| CLIP_MODE_I_FRACT | Fractional type | - | - |
| CLIP_MODE_M_FRACT | Band Fractional Type | - | - |
| CLIP_MODE_H_TIME | Time type (hour) | Frames per second | - |
| CLIP_MODE_M_TIME | Time type (minutes) | Frames per second | - |
| CLIP_MODE_S_TIME | Time type (seconds) | Frames per second | - |
| CLIP_MODE_F_TIME | Time type (frame) | Frames per second | - |
| CLIP_MODE_S_CHAR | Signed 8-bit integer type | Radix | - |
| CLIP_MODE_U_CHAR | Unsigned 8-bit integer type | Radix | - |
| CLIP_MODE_S_SHORT | Signed 16-bit integer type | Radix | - |
| CLIP_MODE_U_SHORT | Unsigned 16-bit integer type | Radix | - |
| CLIP_MODE_S_LONG | Signed 32-bit integer type | Radix | - |
| CLIP_MODE_U_LONG | Unsigned 32-bit integer type | Radix | - |
| CLIP_MODE_F_MULTIPREC | Multiple-precision floating point type | precision | Rounding mode |
| CLIP_MODE_I_MULTIPREC | Multiple-precision integer type | precision | Rounding mode |

| Rounding mode | Meaning |
| --- | --- |
| "up" | Round away from zero |
| "down" | Round to near zero |
| "ceiling" | Round to approach positive infinity |
| "floor" | Round to approach negative infinity |
| "h_up" | round up on 5 and round down on 4 |
| "h_down" | round up on 6 and round down on 5 |
| "h_even" | If the number in the `param1` digit is odd, "h_up" is processed, and if it is even, "h_down" is processed. |
| "h_down2" | banker's rounding |
| "h_even2" | If the number in the `param1` digit is odd, "h_up" is processed, and if it is even, "h_down2" is processed. |

`param1` and `param1` can be omitted.

Immediately after building the EasyClip object: CLIP_MODE_G_FLOAT

**Floating point display accuracy** (":prec" command in CLIP)

```dart
clip.setPrec( prec );
```

Immediately after building the EasyClip object: 6

**Frames per second** (":fps" command in CLIP)

```dart
clip.setFps( fps );
```

Immediately after building the EasyClip object: 30.0

**Radix in integer** (":radix" command in CLIP)

```dart
clip.setRadix( radix );
```

Immediately after building the EasyClip object: 10

**Angle unit specification**

```dart
clip.setAngType( type );
```

| `type` | Meaning |
| --- | --- |
| MATH_ANG_TYPE_RAD | Radian |
| MATH_ANG_TYPE_DEG | Degree |
| MATH_ANG_TYPE_GRAD | Grazian |

Immediately after building the EasyClip object: MATH_ANG_TYPE_RAD

**Calculator mode specification** (":calculator" command in CLIP)

```dart
clip.setCalculator( flag );
```

Immediately after building the EasyClip object: false

**Specify the lower limit of array subscripts** (":base" command in CLIP)

```dart
clip.setBase( base );
```

| `base` | Meaning |
| --- | --- |
| 0 | 0 origin |
| 1 | 1 origin |

Immediately after building the EasyClip object: 0

**Specify whether to return the calculation result** (":ans" command in CLIP)

```dart
clip.setAnsFlag( flag );
```

Immediately after building the EasyClip object: false

**Specify whether diagnostic message is valid** (":assert" command in CLIP)

```dart
clip.setAssertFlag( flag );
```

Immediately after building the EasyClip object: false

**Specify whether the warning message is valid** (":warn" command in CLIP)

```dart
clip.setWarnFlag( flag );
```

Immediately after building the EasyClip object: true

### Command

We provide a function that executes some CLIP commands directly from Dart.

```dart
clip.commandGWorld( width, height );
```

```dart
clip.commandGWorld24( width, height );
```

```dart
clip.commandWindow( left, bottom, right, top );
```

```dart
clip.commandGClear( index );
```

```dart
clip.commandGColor( index );
```

```dart
clip.commandGPut( array/*List<List<int>>*/ );
```

```dart
clip.commandGPut24( array/*List<List<int>>*/ );
```

```dart
List<List<int>>? array = clip.commandGGet(); // null if could not be obtained
```

```dart
List<List<int>>? array = clip.commandGGet24(); // null if could not be obtained
```

### Calculation

```dart
int ret = clip.procLine( line/*String*/ ); // Returns CLIP_PROC_END on successful completion
```

```dart
int ret = clip.procScript( script/*List<String>*/ ); // Returns CLIP_PROC_END upon normal completion
```

### Color palette

```dart
clip.newPalette();
```

```dart
clip.setPalette( bgrColorArray/*List<int>*/ );
```

```dart
// Below is an example of setting a grayscale palette
int bgrColor;
for( int i = 0; i < 256; i++ ){
    bgrColor = (i << 16) + (i << 8) + i;
    clip.setPaletteColor( i, bgrColor );
}
```

```dart
int bgrColor = clip.paletteColor( index );
```

### Canvas

```dart
Canvas canvas = clip.createCanvas( width, height );
```

```dart
clip.resizeCanvas( width, height );
```

```dart
clip.updateCanvas();
clip.updateCanvas( scale ); //  If scale is specified, the image memory in the ClipGWorld object will be enlarged and drawn.
```

```dart
Canvas canvas = clip.canvas(); // Canvas object
```

### Use the EasyCanvas object

After building the EasyCanvas object, CLIP graphics instructions will now be drawn directly on the canvas, eliminating the need to call the updateCanvas function.
 
```dart
EasyCanvas easyCanvas = EasyCanvas();
```

```dart
easyCanvas.setFont( size, family );
```

### Other

- Function used to implement the printAnsMatrix function called from the ClipProc object.

```dart
String string = clip.getArrayTokenString( param, array/*ClipToken*/, indent );
```

You can pass the parameters param and array of the printAnsMatrix function as they are.

- Get the ClipProc object, which is the only computational main class that exists in the EasyClip object.

```dart
ClipProc proc = clip.proc();
```

- Get the ClipParam object, which is the only calculated parameter class that exists in the EasyClip object.

```dart
ClipParam param = clip.param();
```

- Get the only ClipGWorld object that exists inside the EasyClip object.

```dart
ClipGWorld gWorld = clip.gWorld();
```

- Get the only MultiPrec object that exists in the CLIP engine.

```dart
MultiPrec mp = procMultiPrec();
```

----------

## MultiPrec

MultiPrec object for multi-precision computation

```dart
import 'package:clip/math/multiprec.dart';
```

### MultiPrec object constructor

```dart
MultiPrec()
```

### Constant definition method

**Multi-precision integer**

```dart
I( str )
```

Returns an MPData object.

If the constant is undefined, the definition is added, and if it is defined, the defined one is returned.

**Multi-precision floating point number**

```dart
F( str )
```

Returns an MPData object.

If the constant is undefined, the definition is added, and if it is defined, the defined one is returned.

### Multi-precision integer arithmetic method

**Convert a string to a multi-precision integer**

```dart
str2num( n/*MPData*/, s )
```

**Convert multi-precision integer to strings**

```dart
num2str( n/*MPData*/ )
```

Returns a String object.

**Substitution**

```dart
set( rop/*MPData*/, op/*MPData*/ )
```

**Large and small comparison**

```dart
cmp( a/*MPData*/, b/*MPData*/ )
```

Returns a positive value if `a` is greater than `b`, a negative value if it is less than b, and a zero value if equal.

**Addition**

```dart
add( ret/*MPData*/, a/*MPData*/, b/*MPData*/ )
```

**Subtraction**

```dart
sub( ret/*MPData*/, a/*MPData*/, b/*MPData*/ )
```

**Multiply**

```dart
mul( ret/*MPData*/, a/*MPData*/, b/*MPData*/ )
```

**Division**

```dart
div( q/*MPData*/, a/*MPData*/, b/*MPData*/, r/*MPData*/ )
```

Get the quotient `q` and the remainder `r`.
Returns true if the divisor `b` is 0.

`r` can be omitted.

**Sign inversion**

```dart
neg( rop/*MPData*/, op/*MPData*/ )
```

`op` can be omitted.

**Absolute value**

```dart
abs( rop/*MPData*/, op/*MPData*/ )
```

`op` can be omitted.

**Square root**

```dart
sqrt( x/*MPData*/, a/*MPData*/ )
```

Returns true if `a` is negative.

### Multi-precision floating point arithmetic method

**Convert strings to multi-precision floating point numbers**

```dart
fstr2num( n/*MPData*/, s )
```

**Convert multi-precision floating point numbers to strings**

```dart
fnum2str( n/*MPData*/ )
```

Returns a String object.

**Substitution**

```dart
fset( rop/*MPData*/, op/*MPData*/ )
```

**Large and small comparison**

```dart
fcmp( a/*MPData*/, b/*MPData*/ )
```

Returns positive value if `a` is greater than `b`, negative value if it is less than `b`, and zero value if equal.

**Addition**

```dart
fadd( ret/*MPData*/, a/*MPData*/, b/*MPData*/ )
```

**Subtraction**

```dart
fsub( ret/*MPData*/, a/*MPData*/, b/*MPData*/ )
```

**Multiply**

```dart
fmul( ret/*MPData*/, a/*MPData*/, b/*MPData*/, prec )
```

**Division**

```dart
fdiv( ret/*MPData*/, a/*MPData*/, b/*MPData*/, prec )
fdiv2( ret/*MPData*/, a/*MPData*/, b/*MPData*/, prec, digit/*ParamInteger*/ )
```

Returns true if the divisor `b` is 0.
`digit` stores the number of digits in the integer part of the divisor `a`.

`digit` can be omitted.

**Sign inversion**

```dart
fneg( rop/*MPData*/, op/*MPData*/ )
```

`op` can be omitted.

**Absolute value**

```dart
fabs( rop/*MPData*/, op/*MPData*/ )
```

`op` can be omitted.

**Truncate after the decimal point**

```dart
ftrunc( rop/*MPData*/, op/*MPData*/ )
```

**Square root**

```dart
fsqrt( ret/*MPData*/, a/*MPData*/, prec )
fsqrt2( ret/*MPData*/, a/*MPData*/, prec, order )
fsqrt3( ret/*MPData*/, a/*MPData*/, prec )
```

Returns true if `a` is negative.

**Number of digits in the integer part**

```dart
fdigit( a/*MPData*/ )
```

**Rounding operation**

```dart
fround( a/*MPData*/, prec, mode )
```

| `mode` | Meaning |
| --- | --- |
| MP_FROUND_UP | Round away from zero |
| MP_FROUND_DOWN | Round to near zero |
| MP_FROUND_CEILING | Round to approach positive infinity |
| MP_FROUND_FLOOR | Round to approach negative infinity |
| MP_FROUND_HALF_UP | round up on 5 and round down on 4 |
| MP_FROUND_HALF_DOWN | round up on 6 and round down on 5 |
| MP_FROUND_HALF_EVEN | If the number in the `prec` digit is odd, MP_FROUND_HALF_UP is processed, and if it is even, MP_FROUND_HALF_DOWN is processed. |
| MP_FROUND_HALF_DOWN2 | banker's rounding |
| MP_FROUND_HALF_EVEN2 | If the number in the `prec` digit is odd, MP_FROUND_HALF_UP is processed, and if it is even, MP_FROUND_HALF_DOWN2 is processed. |

If `mode` is omitted, the operation will be MP_FROUND_HALF_EVEN.
