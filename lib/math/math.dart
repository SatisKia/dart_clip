/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import 'dart:convert';
import 'dart:math';

import '../param/float.dart';
import '../param/integer.dart';
import 'matrix.dart';
import 'value.dart';

// 角度の単位の種類
const int MATH_ANG_TYPE_RAD = 0; // ラジアン
const int MATH_ANG_TYPE_DEG = 1; // 度
const int MATH_ANG_TYPE_GRAD = 2; // グラジアン

// 型
const int MATH_VALUE_TYPE_COMPLEX = 0; // 複素数型
const int MATH_VALUE_TYPE_FRACT = 1; // 分数型
const int MATH_VALUE_TYPE_TIME = 2; // 時間型

// _SIGNED、_UNSIGNED用
const double MATH_UMAX_8 = 256;
const double MATH_UMAX_16 = 65536;
const double MATH_UMAX_24 = 16777216;
const double MATH_UMAX_32 = 4294967296;

// _SIGNED用
const double MATH_SMIN_8 = -128;
const double MATH_SMAX_8 = 127;
const double MATH_SMIN_16 = -32768;
const double MATH_SMAX_16 = 32767;
const double MATH_SMIN_32 = -2147483648;
const double MATH_SMAX_32 = 2147483647;

const double MATH_DBL_EPSILON = 2.2204460492503131e-016;
const double MATH_NORMALIZE = 0.434294481903251816668; // 1/log(10)
const int MATH_RAND_MAX = 32767;

// 数学関数
double MATH_ABS( double x ){ return x.abs(); }
double MATH_ACOS( double x ){ return acos( x ); }
double MATH_ASIN( double x ){ return asin( x ); }
double MATH_ATAN( double x ){ return atan( x ); }
double MATH_ATAN2( double x, double y ){ return atan2( x, y ); }
double MATH_CEIL( double x ){ return x.ceil().toDouble(); }
double MATH_COS( double x ){ return cos( x ); }
double MATH_EXP( double x ){ return exp( x ); }
double MATH_FLOOR( double x ){ return x.floor().toDouble(); }
double MATH_LOG( double x ){ return log( x ); }
double MATH_POW( double x, double y ){ return pow( x, y ).toDouble(); }
double MATH_SIN( double x ){ return sin( x ); }
double MATH_SQRT( double x ){ return sqrt( x ); }
double MATH_TAN( double x ){ return tan( x ); }

// 乱数
int _rand_next = 1;
void MATH_SRAND( int seed ){
	_rand_next = seed;
}
int MATH_RAND(){
	_rand_next = MATH_UNSIGNED( _rand_next * 1103515245 + 12345, MATH_UMAX_32.toDouble() ).toInt();
	return MATH_IMOD( _rand_next ~/ ((MATH_RAND_MAX + 1) * 2), MATH_RAND_MAX + 1 );
}

double MATH_DOUBLE( dynamic x ){
	if( x is MathValue ){
		return x.toFloat();
	} else if( x is int ){
		return x.toDouble();
	}
	return x as double;
}

// 剰余
double MATH_FMOD( double a, double b ){
	if( a < 0.0 ){
		return -(-a % b.abs());
	}
	return a % b.abs();
}
int MATH_IMOD( int a, int b ){
	if( a < 0 ){
		return -(-a % b.abs());
	}
	return a % b.abs();
}

// 整数値
double MATH_INT( double x ){
	return x.toInt().toDouble();
}

// 整数演算
double MATH_DIV( double a, double b/*符号なし整数値*/ ){
	return (a.toInt() ~/ b.toInt()).toDouble();
}
double MATH_MOD( double a, double b/*符号なし整数値*/ ){
	return MATH_IMOD( a.toInt(), b.toInt() ).toDouble();
}
double MATH_SHIFTL( double a, double b ){
	return (a.toInt() << b.toInt()).toDouble();
}
double MATH_SHIFTR( double a, double b ){
	return (a.toInt() >> b.toInt()).toDouble();
}
double MATH_AND( double a, double b ){
	return (a.toInt() & b.toInt()).toDouble();
}
double MATH_OR( double a, double b ){
	return (a.toInt() | b.toInt()).toDouble();
}
double MATH_XOR( double a, double b ){
	return (a.toInt() ^ b.toInt()).toDouble();
}

// 符号付き整数値
double MATH_SIGNED( double x, double umax, double smin, double smax ){
	x = MATH_MOD( x, umax );
	if( x > smax ) return x - umax;
	if( x < smin ) return x + umax;
	return x;
}

// 符号なし整数値
double MATH_UNSIGNED( double x, double umax ){
	x = MATH_MOD( x, umax );
	if( x < 0 ) return x + umax;
	return x;
}

// 浮動小数点数値を小数部と整数部に分割する
double MATH_MODF( double x, ParamFloat y ){
	String str = x.toString();
	double k;
	if( (str.contains( "e" )) || (str.contains( "E" )) ){
		k = 1;
	} else {
		List<String> tmp = str.split( "." );
		if( tmp.length > 1 ){
			k = MATH_POW( 10, tmp[1].length.toDouble() );
		} else {
			k = 1;
		}
	}
	double i = MATH_INT( x );
	y.set( i );
	return (x * k - i * k) / k;
}

// 階乗
double MATH_FACTORIAL( double x ){
	bool m = false;
	if( x < 0 ){
		m = true;
		x = 0 - x;
	}
	double f = 1;
	for( int i = 2; i <= x; i++ ){
		f *= i;
		if( MATH_ISINF( f ) ){
			break;
		}
	}
	return m ? -f : f;
}

// 文字コード
int MATH_CHAR( String chr ){
	return charCodeAt( chr, 0 );
}
int MATH_CHAR_CODE_0 = MATH_CHAR( '0' );
int MATH_CHAR_CODE_9 = MATH_CHAR( '9' );
int MATH_CHAR_CODE_LA = MATH_CHAR( 'a' ); // Lowercase
int MATH_CHAR_CODE_LZ = MATH_CHAR( 'z' ); // Lowercase
int MATH_CHAR_CODE_UA = MATH_CHAR( 'A' ); // Uppercase
int MATH_CHAR_CODE_UZ = MATH_CHAR( 'Z' ); // Uppercase
int MATH_CHAR_CODE_EX = MATH_CHAR( '!' ); // Exclamation
int MATH_CHAR_CODE_COLON = MATH_CHAR( ':' );

// 各種判定
bool MATH_ISINF( double x ){
	return x.isInfinite;
}
bool MATH_ISNAN( double x ){
	return x.isNaN;
}
bool MATH_ISZERO( double x ){
	// NaNをゼロでないように判定させる処理
	return (MATH_ISNAN( x ) || (x != 0.0)) ? false : true;
}
bool MATH_APPROX( double x, double y ){
	if( y == 0 ){
		return MATH_ABS( x ) < (MATH_DBL_EPSILON * 4.0);
	}
	return MATH_ABS( (y - x) / y ) < (MATH_DBL_EPSILON * 4.0);
}
bool MATH_APPROX_M( MathMatrix x, MathMatrix y ){
	if( x.row() != y.row() ) return false;
	if( x.col() != y.col() ) return false;
	int l = x.len();
	for( int i = 0; i < l; i++ ){
		if( !MATH_APPROX( x.mat( i ).toFloat(), y.mat( i ).toFloat() ) || !MATH_APPROX( x.mat( i ).imag(), y.mat( i ).imag() ) ) return false;
	}
	return true;
}

// 有効桁数を求める
double MATH_EPREC( double x ){
	int p, q;
	double t, i;

	if( MATH_ISINF( x ) || MATH_ISNAN( x ) || MATH_ISZERO( x ) ){
		return 0;
	}

	q = 0;
	for( p = 0; ; p++ ){
		t = x * MATH_POW( 10.0, p.toDouble() );
		i = MATH_INT( t );
		if( (t - i) == 0.0 ){
			break;
		}
		if( i == 0 ){
			q++;
		}
	}

	if( q == 0 ){
		return p + MATH_INT( MATH_LOG( MATH_ABS( x ) ) * MATH_NORMALIZE )/*整数部の桁数-1*/;
	}
	return (p - q).toDouble();
}
double MATH_FPREC( double x ){
	int p;
	double t, i;

	if( MATH_ISINF( x ) || MATH_ISNAN( x ) ){
		return 0;
	}

	for( p = 0; ; p++ ){
		t = x * MATH_POW( 10.0, p.toDouble() );
		i = MATH_INT( t );
		if( (t - i) == 0.0 ){
			break;
		}
	}

	return p.toDouble();
}

// 最大公約数
double MATH_GCD( double x, double y ){
	if( MATH_ISNAN( x ) ) return x;
	if( MATH_ISNAN( y ) ) return y;
	x = MATH_INT( x );
	y = MATH_INT( y );
	double t;
	while( y != 0 ){
		t = MATH_MOD( x, y );
		x = y;
		y = t;
	}
	return x;
}

// 最小公倍数
double MATH_LCM( double x, double y ){
	if( MATH_ISNAN( x ) ) return x;
	if( MATH_ISNAN( y ) ) return y;
	x = MATH_INT( x );
	y = MATH_INT( y );
	double g = MATH_GCD( x, y );
	if( g == 0 ){
		return 0;
	}
	return x * y / g;
}

// 文字列を浮動小数点数値に変換する
double stringToFloat( String str, int top, ParamInteger stop ){
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
				if( (charCodeAt( str, i ) >= MATH_CHAR_CODE_0) && (charCodeAt( str, i ) <= MATH_CHAR_CODE_9) ){
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
					if( (charCodeAt( str, i + 1 ) >= MATH_CHAR_CODE_0) && (charCodeAt( str, i + 1 ) <= MATH_CHAR_CODE_9) ){
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

String charAt( String str, int i ){
	if( i >= str.length ){
		return "";
	}
	return str.substring( i, i + 1 );
}
int charCodeAt( String str, int i ){
	List<int> code = utf8.encode( charAt( str, i ) );
	if( code.isEmpty ){
		return 0;
	}
	return code[0];
}

// 文字列を整数値に変換する
int stringToInt( String str, int top, ParamInteger stop, int radix ){
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
		if( (chr >= MATH_CHAR_CODE_0) && (chr < MATH_CHAR_CODE_0 + num) ){
			val += chr - MATH_CHAR_CODE_0;
			i++;
		} else if( (chr >= MATH_CHAR_CODE_LA) && (chr < MATH_CHAR_CODE_LA + (radix - 10)) ){
			val += 10 + (chr - MATH_CHAR_CODE_LA);
			i++;
		} else if( (chr >= MATH_CHAR_CODE_UA) && (chr < MATH_CHAR_CODE_UA + (radix - 10)) ){
			val += 10 + (chr - MATH_CHAR_CODE_UA);
			i++;
		} else {
			break;
		}
	}
	stop.set( i );
	return swi ? -val : val;
}

// 浮動小数点数表記文字列の最適化
String _trimFloatStr( String str ){
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
String floatToExponential( double val, [int? width] ){
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
String floatToFixed( double val, [int? width] ){
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
String floatToString( double val, [int? width] ){
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
String floatToStringPoint( double val, [int? width] ){
	String str = floatToString( val, width );
	if( !str.contains( "." ) ){
		str += ".0";
	}
	return str;
}

// 整数を文字列に変換する
String intToString( double val, int radix, [int? width] ){
	if( MATH_ISNAN( val ) ){
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
		str += charAt( chr, MATH_MOD( val, radix.toDouble() ).toInt() );
		val = MATH_DIV( val, radix.toDouble() );
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
