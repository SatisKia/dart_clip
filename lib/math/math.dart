/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import 'dart:convert';
import 'dart:math' as math;

import '../param/float.dart';
import '../param/integer.dart';
import 'matrix.dart';
import 'value.dart';

class ClipMathEnv {
	// _Complex用
	int _complexAngType = ClipMath.angTypeRad; // 角度の単位の種類
	bool _complexIsRad = true; // 角度の単位の種類がラジアンかどうかのフラグ
	double _complexAngCoef = ClipMath.pi; // ラジアンから現在の単位への変換用係数
	bool _complexIsReal = false; // 実数計算を行うかどうかのフラグ
	bool _complexErr = false; // エラーが起こったかどうかのフラグ

	// _Fract用
	bool _fractErr = false; // エラーが起こったかどうかのフラグ

	// _Matrix用
	bool _matrixErr = false; // エラーが起こったかどうかのフラグ

	// _Time用
	double _timeFps = 30.0; // 秒間フレーム数（グローバル）
	bool _timeErr = false; // エラーが起こったかどうかのフラグ

	// _Value用
	int _valueType = ClipMath.valueTypeComplex; // 型（グローバル）
}

class ClipMath {
	static ClipMathEnv _env = ClipMathEnv();
	static void setEnv( ClipMathEnv env ){
		_env = env;
	}

	// _Complex用
	static void setComplexAngType( int angType ){
		_env._complexAngType = angType;
		_env._complexIsRad = (_env._complexAngType == ClipMath.angTypeRad);
		_env._complexAngCoef = (_env._complexAngType == ClipMath.angTypeDeg) ? 180.0 : 200.0;
	}
	static int complexAngType(){
		return _env._complexAngType;
	}
	static bool complexIsRad(){
		return _env._complexIsRad;
	}
	static double complexAngCoef(){
		return _env._complexAngCoef;
	}
	static void setComplexIsReal( bool isReal ){
		_env._complexIsReal = isReal;
	}
	static bool complexIsReal(){
		return _env._complexIsReal;
	}
	static void clearComplexError(){
		_env._complexErr = false;
	}
	static void setComplexError(){
		_env._complexErr = true;
	}
	static bool complexError(){
		return _env._complexErr;
	}

	// _Fract用
	static void clearFractError(){
		_env._fractErr = false;
	}
	static void setFractError(){
		_env._fractErr = true;
	}
	static bool fractError(){
		return _env._fractErr;
	}

	// _Matrix用
	static void clearMatrixError(){
		_env._matrixErr = false;
	}
	static void setMatrixError(){
		_env._matrixErr = true;
	}
	static bool matrixError(){
		return _env._matrixErr;
	}

	// _Time用
	static void setTimeFps( double fps ){
		_env._timeFps = fps;
	}
	static double timeFps(){
		return _env._timeFps;
	}
	static void clearTimeError(){
		_env._timeErr = false;
	}
	static void setTimeError(){
		_env._timeErr = true;
	}
	static bool timeError(){
		return _env._timeErr;
	}

	// _Value用
	static void setValueType( int type ){
		_env._valueType = type;
	}
	static int valueType(){
		return _env._valueType;
	}
	static void clearValueError(){
		clearComplexError();
		clearFractError();
		clearTimeError();
	}
	static bool valueError(){
		return complexError() || fractError() || timeError();
	}

	// 角度の単位の種類
	static const int angTypeRad = 0; // ラジアン
	static const int angTypeDeg = 1; // 度
	static const int angTypeGrad = 2; // グラジアン

	// 型
	static const int valueTypeComplex = 0; // 複素数型
	static const int valueTypeFract = 1; // 分数型
	static const int valueTypeTime = 2; // 時間型

	// _SIGNED、_UNSIGNED用
	static const double umax8 = 256;
	static const double umax16 = 65536;
	static const double umax24 = 16777216;
	static const double umax32 = 4294967296;

	// _SIGNED用
	static const double smin8 = -128;
	static const double smax8 = 127;
	static const double smin16 = -32768;
	static const double smax16 = 32767;
	static const double smin32 = -2147483648;
	static const double smax32 = 2147483647;

	static const double dblEpsilon = 2.2204460492503131e-016;
	static const double normalize = 0.434294481903251816668; // 1/log(10)
	static const double pi = 3.14159265358979323846264; // 円周率
	static const int randMax = 32767;

	// 数学関数
	static double abs( double x ){ return x.abs(); }
	static double acos( double x ){ return math.acos( x ); }
	static double asin( double x ){ return math.asin( x ); }
	static double atan( double x ){ return math.atan( x ); }
	static double atan2( double x, double y ){ return math.atan2( x, y ); }
	static double ceil( double x ){ return x.ceil().toDouble(); }
	static double cos( double x ){ return math.cos( x ); }
	static double exp( double x ){ return math.exp( x ); }
	static double floor( double x ){ return x.floor().toDouble(); }
	static double log( double x ){ return math.log( x ); }
	static double pow( double x, double y ){ return math.pow( x, y ).toDouble(); }
	static double sin( double x ){ return math.sin( x ); }
	static double sqrt( double x ){ return math.sqrt( x ); }
	static double tan( double x ){ return math.tan( x ); }

	// 乱数
	static int _randNext = 1;
	static void srand( int seed ){
		_randNext = seed;
	}
	static int rand(){
		_randNext = unsigned( _randNext * 1103515245 + 12345, umax32.toDouble() ).toInt();
		return imod( _randNext ~/ ((randMax + 1) * 2), randMax + 1 );
	}

	static double toDouble( dynamic x ){
		if( x is MathValue ){
			return x.toFloat();
		} else if( x is int ){
			return x.toDouble();
		}
		return x as double;
	}

	// 剰余
	static double fmod( double a, double b ){
		if( a < 0.0 ){
			return -(-a % b.abs());
		}
		return a % b.abs();
	}
	static int imod( int a, int b ){
		if( a < 0 ){
			return -(-a % b.abs());
		}
		return a % b.abs();
	}

	// 整数値
	static double toInt( double x ){
		if( x < 0.0 ){
			return ceil( x );
		}
		return floor( x );
	}

	// 整数演算
	static double div( double a, double b/*符号なし整数値*/ ){
		return (a.toInt() ~/ b.toInt()).toDouble();
	}
	static double mod( double a, double b/*符号なし整数値*/ ){
		return imod( a.toInt(), b.toInt() ).toDouble();
	}
	static double shiftL( double a, double b ){
		return (a.toInt() << b.toInt()).toDouble();
	}
	static double shiftR( double a, double b ){
		return (a.toInt() >> b.toInt()).toDouble();
	}
	static double and( double a, double b ){
		return (a.toInt() & b.toInt()).toDouble();
	}
	static double or( double a, double b ){
		return (a.toInt() | b.toInt()).toDouble();
	}
	static double xor( double a, double b ){
		return (a.toInt() ^ b.toInt()).toDouble();
	}

	// 符号付き整数値
	static double signed( double x, double umax, double smin, double smax ){
		x = mod( x, umax );
		if( x > smax ) return x - umax;
		if( x < smin ) return x + umax;
		return x;
	}

	// 符号なし整数値
	static double unsigned( double x, double umax ){
		x = mod( x, umax );
		if( x < 0 ) return x + umax;
		return x;
	}

	// 浮動小数点数値を小数部と整数部に分割する
	static double modf( double x, ParamFloat y ){
		String str = x.toString();
		double k;
		if( (str.contains( "e" )) || (str.contains( "E" )) ){
			k = 1;
		} else {
			List<String> tmp = str.split( "." );
			if( tmp.length > 1 ){
				k = pow( 10, tmp[1].length.toDouble() );
			} else {
				k = 1;
			}
		}
		double i = toInt( x );
		y.set( i );
		return (x * k - i * k) / k;
	}

	// 階乗
	static double factorial( double x ){
		bool m = false;
		if( x < 0 ){
			m = true;
			x = 0 - x;
		}
		double f = 1;
		for( int i = 2; i <= x; i++ ){
			f *= i;
			if( isInf( f ) ){
				break;
			}
		}
		return m ? -f : f;
	}

	// 文字コード
	static int char( String chr ){
		return charCodeAt( chr, 0 );
	}
	static int charCode0 = char( '0' );
	static int charCode9 = char( '9' );
	static int charCodeLA = char( 'a' ); // Lowercase
	static int charCodeLZ = char( 'z' ); // Lowercase
	static int charCodeUA = char( 'A' ); // Uppercase
	static int charCodeUZ = char( 'Z' ); // Uppercase
	static int charCodeEx = char( '!' ); // Exclamation
	static int charCodeColon = char( ':' );

	// 各種判定
	static bool isInf( double x ){
		return x.isInfinite;
	}
	static bool isNan( double x ){
		return x.isNaN;
	}
	static bool isZero( double x ){
		// NaNをゼロでないように判定させる処理
		return (isNan( x ) || (x != 0.0)) ? false : true;
	}
	static bool approx( double x, double y ){
		if( y == 0 ){
			return abs( x ) < (dblEpsilon * 4.0);
		}
		return abs( (y - x) / y ) < (dblEpsilon * 4.0);
	}
	static bool approxM( MathMatrix x, MathMatrix y ){
		if( x.row() != y.row() ) return false;
		if( x.col() != y.col() ) return false;
		int l = x.len();
		for( int i = 0; i < l; i++ ){
			if( !approx( x.mat( i ).toFloat(), y.mat( i ).toFloat() ) || !approx( x.mat( i ).imag(), y.mat( i ).imag() ) ) return false;
		}
		return true;
	}

	// 有効桁数を求める
	static double eprec( double x ){
		int p, q;
		double t, i;

		if( isInf( x ) || isNan( x ) || isZero( x ) ){
			return 0;
		}

		q = 0;
		for( p = 0; ; p++ ){
			t = x * pow( 10.0, p.toDouble() );
			i = toInt( t );
			if( (t - i) == 0.0 ){
				break;
			}
			if( i == 0 ){
				q++;
			}
		}

		if( q == 0 ){
			return p + toInt( log( abs( x ) ) * normalize )/*整数部の桁数-1*/;
		}
		return (p - q).toDouble();
	}
	static double fprec( double x ){
		int p;
		double t, i;

		if( isInf( x ) || isNan( x ) ){
			return 0;
		}

		for( p = 0; ; p++ ){
			t = x * pow( 10.0, p.toDouble() );
			i = toInt( t );
			if( (t - i) == 0.0 ){
				break;
			}
		}

		return p.toDouble();
	}

	// 最大公約数
	static double gcd( double x, double y ){
		if( isNan( x ) ) return x;
		if( isNan( y ) ) return y;
		x = toInt( x );
		y = toInt( y );
		double t;
		while( y != 0 ){
			t = mod( x, y );
			x = y;
			y = t;
		}
		return x;
	}

	// 最小公倍数
	static double lcm( double x, double y ){
		if( isNan( x ) ) return x;
		if( isNan( y ) ) return y;
		x = toInt( x );
		y = toInt( y );
		double g = gcd( x, y );
		if( g == 0 ){
			return 0;
		}
		return x * y / g;
	}

	// 文字列を浮動小数点数値に変換する
	static double stringToFloat( String str, int top, ParamInteger stop ){
		int step = 0;
		int i = top;
		bool _break = false;
		while( i < str.length ){
			switch( step ){
				case 0:
					if( (charAt( str, i ) == '+') || charAt( str, i ) == '-' ){
						i++;
					}
					step++;
					break;
				case 1:
				case 3:
				case 5:
					if( (charCodeAt( str, i ) >= charCode0) && (charCodeAt( str, i ) <= charCode9) ){
						i++;
					} else {
						step++;
					}
					break;
				case 2:
					if( charAt( str, i ) == '.' ){
						i++;
						step = 3;
					} else {
						step = 4;
					}
					break;
				case 4:
					if( (charAt( str, i ) == 'e') || (charAt( str, i ) == 'E') ){
						if( (charCodeAt( str, i + 1 ) >= charCode0) && (charCodeAt( str, i + 1 ) <= charCode9) ){
							i++;
							step = 5;
							break;
						}
						if( (charAt( str, i + 1 ) == '+') || charAt( str, i + 1 ) == '-' ){
							i += 2;
							step = 5;
							break;
						}
					}
					// そのまま下に流す
					continue case_6;
				case_6:
				case 6:
					_break = true;
					break;
			}
			if( _break ){
				break;
			}
		}
		stop.set( i );
		if( i == 0 ){
			return 0;
		}
		return double.parse( str.substring( top, i ) );
	}

	static String charAt( String str, int i ){
		if( i >= str.length ){
			return "";
		}
		return str.substring( i, i + 1 );
	}
	static int charCodeAt( String str, int i ){
		List<int> code = utf8.encode( charAt( str, i ) );
		if( code.isEmpty ){
			return 0;
		}
		return code[0];
	}

	// 文字列を整数値に変換する
	static int stringToInt( String str, int top, ParamInteger stop, int radix ){
		int val = 0;
		int i = top;
		bool swi = false;
		if( charAt( str, i ) == '+' ){
			i++;
		} else if( charAt( str, i ) == '-' ){
			swi = true;
			i++;
		}
		int chr;
		int num = (radix > 10) ? 10 : radix;
		while( i < str.length ){
			chr = charCodeAt( str, i );
			val *= radix;
			if( (chr >= charCode0) && (chr < charCode0 + num) ){
				val += chr - charCode0;
				i++;
			} else if( (chr >= charCodeLA) && (chr < charCodeLA + (radix - 10)) ){
				val += 10 + (chr - charCodeLA);
				i++;
			} else if( (chr >= charCodeUA) && (chr < charCodeUA + (radix - 10)) ){
				val += 10 + (chr - charCodeUA);
				i++;
			} else {
				break;
			}
		}
		stop.set( i );
		return swi ? -val : val;
	}

	// 浮動小数点数表記文字列の最適化
	static String _trimFloatStr( String str ){
		String str1 = str;
		String str2 = "";
		int top = str.indexOf( "e" );
		if( top < 0 ){
			top = str.indexOf( "E" );
		}
		if( top >= 0 ){
			str1 = str.substring( 0, top );
			str2 = str.substring( top );
		}
		int min = str1.indexOf( "." );
		if( min >= 0 ){
			int len = str1.length;
			while( len > min ){
				if( (charAt( str1, len - 1 ) != '0') && (charAt( str1, len - 1 ) != '.') ){
					break;
				}
				len--;
			}
			str1 = str1.substring( 0, len );
		}
		return str1 + str2;
	}

	// 浮動小数点数を文字列に変換する
	static String floatToExponential( double val, [int? width] ){
		String str;
		if( width == null ){
			str = val.toStringAsExponential();
		} else {
			if( width < 0 ){
				width = 0;
			}
			if( width > 20 ){
				width = 20;
			}
			str = val.toStringAsExponential( width );
		}
		return _trimFloatStr( str );
	}
	static String floatToFixed( double val, [int? width] ){
		String str;
		if( width == null ){
			str = val.toStringAsFixed( 6 );
			if( (str.contains( "e" )) || (str.contains( "E" )) ){
				str = val.toStringAsExponential();
			}
		} else {
			if( width < 0 ){
				width = 0;
			}
			if( width > 20 ){
				width = 20;
			}
			str = val.toStringAsFixed( width );
			if( (str.contains( "e" )) || (str.contains( "E" )) ){
				str = val.toStringAsExponential( width );
			}
		}
		return _trimFloatStr( str );
	}
	static String floatToString( double val, [int? width] ){
		String str;
		if( width == null ){
			str = val.toStringAsPrecision( 6 );
		} else {
			if( width < 1 ){
				width = 1;
			}
			if( width > 21 ){
				width = 21;
			}
			str = val.toStringAsPrecision( width );
		}
		return _trimFloatStr( str );
	}
	static String floatToStringPoint( double val, [int? width] ){
		String str = floatToString( val, width );
		if( !str.contains( "." ) ){
			str += ".0";
		}
		return str;
	}

	// 整数を文字列に変換する
	static String intToString( double val, int radix, [int? width] ){
		if( isNan( val ) ){
			return val.toString();
		}

		if( (width == null) || (width <= 0) ){
			width = 1;
		}

		String chr = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

		// 符号をチェックして、負の値の場合は正の値に変換する
		bool swi = (val < 0);
		if( swi ){
			val = -val;
		}

		int i;

		// 基数の変換メイン
		String str = "";
		while( val != 0 ){
			str += charAt( chr, mod( val, radix.toDouble() ).toInt() );
			val = div( val, radix.toDouble() );
		}
		for( i = str.length; i < width; i++ ){
			str += "0";
		}

		// 符号を元に戻す
		if( swi ){
			str += "-";
		}

		// 文字列の反転
		String str2 = "";
		for( i = str.length - 1; i >= 0; i-- ){
			str2 += charAt( str, i );
		}

		return str2;
	}
}
