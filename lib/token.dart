/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import 'global.dart';
import 'gworld.dart';
import 'math/math.dart';
import 'math/math_env.dart';
import 'math/matrix.dart';
import 'math/multiprec.dart';
import 'math/value.dart';
import 'param.dart';
import 'param/integer.dart';
import 'param/string.dart';
import 'proc.dart';

List<String> _tokenOp = [
	"[++]",
	"[--]",
	"[~]",
	"[!]",
	"[-]",
	"[+]",
	"++",
	"--",
	"*",
	"/",
	"%",
	"+",
	"-",
	"<<",
	">>",
	"<",
	"<=",
	">",
	">=",
	"==",
	"!=",
	"&",
	"^",
	"|",
	"&&",
	"||",
	"?",
	"=",
	"*=",
	"/=",
	"%=",
	"+=",
	"-=",
	"<<=",
	">>=",
	"&=",
	"|=",
	"^=",
	",",
	"**",
	"**=",
	"!"
];

List<String> _tokenFunc = [
	"defined",
	"indexof",
	"isinf",
	"isnan",
	"rand",
	"time",
	"mktime",
	"tm_sec",
	"tm_min",
	"tm_hour",
	"tm_mday",
	"tm_mon",
	"tm_year",
	"tm_wday",
	"tm_yday",
	"tm_xmon",
	"tm_xyear",
	"a2d",
	"a2g",
	"a2r",
	"d2a",
	"d2g",
	"d2r",
	"g2a",
	"g2d",
	"g2r",
	"r2a",
	"r2d",
	"r2g",
	"sin",
	"cos",
	"tan",
	"asin",
	"acos",
	"atan",
	"atan2",
	"sinh",
	"cosh",
	"tanh",
	"asinh",
	"acosh",
	"atanh",
	"exp",
	"exp10",
	"ln",
	"log",
	"log10",
	"pow",
	"sqr",
	"sqrt",
	"ceil",
	"floor",
	"abs",
	"ldexp",
	"frexp",
	"modf",
	"fact",
	"int",
	"real",
	"imag",
	"arg",
	"norm",
	"conjg",
	"polar",
	"num",
	"denom",
	"row",
	"col",
	"trans",
	"strcmp",
	"stricmp",
	"strlen",
	"gwidth",
	"gheight",
	"gcolor",
	"gcolor24",
	"gcx",
	"gcy",
	"wcx",
	"wcy",
	"gget",
	"wget",
	"gx",
	"gy",
	"wx",
	"wy",
	"mkcolor",
	"mkcolors",
	"col_getr",
	"col_getg",
	"col_getb",
	"call",
	"eval",
	"mp",
	"mround"
];

List<String> _tokenStat = [
	"\$LOOPSTART",
	"\$LOOPEND",
	"\$LOOPEND_I",
	"\$LOOPEND_D",
	"\$LOOPENDE",
	"\$LOOPENDE_I",
	"\$LOOPENDE_D",
	"\$LOOPCONT",
	"do",
	"until",
	"while",
	"endwhile",
	"for",
	"for",
	"next",
	"func",
	"endfunc",
	"end",
	"if",
	"elif",
	"else",
	"endif",
	"switch",
	"case",
	"default",
	"endswi",
	"breakswi",
	"continue",
	"break",
	"\$CONTINUE",
	"\$BREAK",
	"assert",
	"return",
	"\$RETURN",
	"\$RETURN_A"
];

List<String> _tokenCommand = [
	"efloat",
	"float",
	"gfloat",
	"ecomplex",
	"complex",
	"gcomplex",
	"prec",
	"fract",
	"mfract",
	"htime",
	"mtime",
	"time",
	"ftime",
	"fps",
	"char",
	"uchar",
	"short",
	"ushort",
	"long",
	"ulong",
	"int",
	"uint",
	"radix",
	"mfloat",
	"mint",
	"ptype",
	"rad",
	"deg",
	"grad",
	"angle",
	"ans",
	"assert",
	"warn",
	"param",
	"params",
	"define",
	"enum",
	"undef",
	"var",
	"array",
	"local",
	"global",
	"label",
	"parent",
	"real",
	"imag",
	"num",
	"denom",
	"mat",
	"trans",
	"srand",
	"localtime",
	"arraycopy",
	"arrayfill",
	"strcpy",
	"strcat",
	"strlwr",
	"strupr",
	"clear",
	"error",
	"print",
	"println",
	"sprint",
	"scan",
	"gworld",
	"gworld24",
	"gclear",
	"gcolor",
	"gfill",
	"gmove",
	"gtext",
	"gtextr",
	"gtextl",
	"gtextrl",
	"gline",
	"gput",
	"gput24",
	"gget",
	"gget24",
	"gupdate",
	"window",
	"wfill",
	"wmove",
	"wtext",
	"wtextr",
	"wtextl",
	"wtextrl",
	"wline",
	"wput",
	"wget",
	"rectangular",
	"parametric",
	"polar",
	"logscale",
	"nologscale",
	"plot",
	"replot",
	"calculator",
	"include",
	"base",
	"namespace",
	"use",
	"unuse",
	"dump",
	"log"
];

List<String> _tokenSe = [
	"inc",
	"dec",
	"neg",
	"cmp",
	"not",
	"minus",
	"set",
	"setc",
	"setf",
	"setm",
	"mul",
	"div",
	"mod",
	"add",
	"adds", // saturate
	"sub",
	"subs", // saturate
	"pow",
	"shiftl",
	"shiftr",
	"and",
	"or",
	"xor",
	"lt", // less than
	"le",
	"gt", // greater than
	"ge",
	"eq",
	"neq",
	"logand",
	"logor",
	"mul_a",
	"div_a",
	"mod_a",
	"add_a",
	"adds_a", // saturate
	"sub_a",
	"subs_a", // saturate
	"pow_a",
	"shiftl_a",
	"shiftr_a",
	"and_a",
	"or_a",
	"xor_a",
	"lt_a", // less than
	"le_a",
	"gt_a", // greater than
	"ge_a",
	"eq_a",
	"neq_a",
	"logand_a",
	"logor_a",
	"cnd",
	"set_f",
	"set_t",
	"set_z",
	"sat", // saturate
	"sets", // saturate
	"loopstart",
	"loopend",
	"loopend_i",
	"loopend_d",
	"loopende",
	"loopende_i",
	"loopende_d",
	"loopcont",
	"continue",
	"break",
	"return",
	"return_a"
];

List<String> _tokenDefine = [
	"DBL_EPSILON",
	"HUGE_VAL",
	"RAND_MAX",
	"FALSE",
	"TRUE",
	"BG_COLOR",
	"TIME_ZONE",
	"INFINITY",
	"NAN"
];
List<double> _valueDefine = List.filled( _tokenDefine.length, 0.0 );
void setDefineValue(){
	_valueDefine[0] = MATH_DBL_EPSILON;
	_valueDefine[1] = double.maxFinite;
	_valueDefine[2] = MATH_RAND_MAX.toDouble();
	_valueDefine[3] = 0;
	_valueDefine[4] = 1;
	_valueDefine[5] = gWorldBgColor().toDouble();
	_valueDefine[6] = DateTime.now().timeZoneOffset.inSeconds.toDouble();
	_valueDefine[7] = double.infinity;
	_valueDefine[8] = double.nan;
}

int _indexOf( List<String> stringArray, String string ){
//	return stringArray.indexOf( string );
	int len = stringArray.length;
	for( int i = 0; i < len; i++ ){
		if( stringArray[i] == string ){
			return i;
		}
	}
	return -1;
}

// getToken用
int _get_code = 0;
dynamic _get_token;
int getCode(){
	return _get_code;
}
dynamic getToken(){
	return _get_token;
}

// トークン・データ
class ClipTokenData {
	late int _code; // 識別コード
	late dynamic _token; // トークン値
	late ClipTokenData? _before; // 前のトークン・データ
	late ClipTokenData? _next; // 次のトークン・データ
	ClipTokenData(){
		_code   = 0;
		_token  = null;
		_before = null;
		_next   = null;
	}
	void setCode( int code ){
		_code = code;
	}
	int code(){
		return _code;
	}
	void setToken( dynamic token ){
		_token = token;
	}
	dynamic token(){
		return _token;
	}
	ClipTokenData? next(){
		return _next;
	}
}

// コマンドの追加
void addCommand( ClipProc proc, List<String> nameArray, List<int Function( ClipProc, ClipParam, int, dynamic )> funcArray ){
	if( nameArray.length == funcArray.length ){
		_tokenCommand.addAll( nameArray );
		proc.addProcSubCommand( funcArray );
	}
}
String commandName( int token ){
	return _tokenCommand[token - 1];
}

// トークン管理クラス
class ClipToken {
	// トークン・リスト
	late ClipTokenData? _top;
	late ClipTokenData? _end;
	late ClipTokenData? _get;

	ClipToken(){
		_top = null;
		_end = null;
		_get = null;
	}

	ClipTokenData? top(){
		return _top;
	}
	ClipTokenData? get(){
		return _get;
	}

	// 文字列が角括弧（Square Bracket）付き演算子かどうかチェックする
	bool checkSqOp( String string, ParamInteger op ){
		switch( charAt( string, 0 ) ){
		case '+':
			if( string.length == 1 ){
				op.set( CLIP_OP_PLUS );
				return true;
			}
			if( (string.length == 2) && (charAt( string, 1 ) == '+') ){
				op.set( CLIP_OP_INCREMENT );
				return true;
			}
			break;
		case '-':
			if( string.length == 1 ){
				op.set( CLIP_OP_MINUS );
				return true;
			}
			if( (string.length == 2) && (charAt( string, 1 ) == '-') ){
				op.set( CLIP_OP_DECREMENT );
				return true;
			}
			break;
		case '~':
			if( string.length == 1 ){
				op.set( CLIP_OP_COMPLEMENT );
				return true;
			}
			break;
		case '!':
			if( string.length == 1 ){
				op.set( CLIP_OP_NOT );
				return true;
			}
			if( (string.length == 2) && (charAt( string, 1 ) == '=') ){ // 過去互換用に[!=]表記を残す
				op.set( CLIP_OP_NOTEQUAL );
				return true;
			}
			break;
		case '<': // 過去互換用に残す
			if( string.length == 1 ){
				op.set( CLIP_OP_LESS );
				return true;
			}
			if( (string.length == 2) && (charAt( string, 1 ) == '=') ){
				op.set( CLIP_OP_LESSOREQ );
				return true;
			}
			break;
		case '>': // 過去互換用に残す
			if( string.length == 1 ){
				op.set( CLIP_OP_GREAT );
				return true;
			}
			if( (string.length == 2) && (charAt( string, 1 ) == '=') ){
				op.set( CLIP_OP_GREATOREQ );
				return true;
			}
			break;
		case '=': // 過去互換用に残す
			if( (string.length == 2) && (charAt( string, 1 ) == '=') ){
				op.set( CLIP_OP_EQUAL );
				return true;
			}
			break;
		case '&': // 過去互換用に残す
			if( (string.length == 2) && (charAt( string, 1 ) == '&') ){
				op.set( CLIP_OP_LOGAND );
				return true;
			}
			break;
		case '|': // 過去互換用に残す
			if( (string.length == 2) && (charAt( string, 1 ) == '|') ){
				op.set( CLIP_OP_LOGOR );
				return true;
			}
			break;
		}
		return false;
	}

	// 文字列が関数名かどうかチェックする
	bool checkFunc( String string, ParamInteger func ){
		func.set( _indexOf( _tokenFunc, string ) );
		return (func.val() >= 0);
	}

	// 文字列が文かどうかチェックする
	bool checkStat( String string, ParamInteger stat ){
		stat.set( _indexOf( _tokenStat, string ) );
		return (stat.val() >= 0);
	}

	// 文字列がコマンドかどうかチェックする
	bool checkCommand( String string, ParamInteger command ){
		command.set( _indexOf( _tokenCommand, string ) + 1 );
		return (command.val() >= 1);
	}

	// 文字列が単一式かどうかチェックする
	bool checkSe( String string, ParamInteger se ){
		se.set( _indexOf( _tokenSe, string ) + 1 );
		if( se.val() >= 1 ){
				return true;
		}

		if( checkFunc( string, se ) ){
			se.set( CLIP_SE_FUNC + se.val() );
			return true;
		}

		return false;
	}

	// 文字列が定義定数かどうかチェックする
	bool checkDefine( String string, MathValue value ){
		int define = _indexOf( _tokenDefine, string );
		if( define >= 0 ){
			value.ass( _valueDefine[define] );
			return true;
		}
		return false;
	}

	// 文字列を浮動小数点数値に変換する
	bool stringToValue( ClipParam param, String string, MathValue value ){
		int i, j;
		bool swi;
		int top;
		ParamInteger stop = ParamInteger();
		List<double> tmp = List.filled( 4, 0.0 );

		top = isCharEscape( string, 0 ) ? 1 : 0;
		switch( charAt( string, top ) ){
		case '+': top++  ; swi = false; break;
		case '-': top++  ; swi = true ; break;
		default : top = 0; swi = false; break;
		}

		if( charAt( string, top ) == '\'' ){
			value.ass( 0.0 );
			j = 0;
			for( i = 1; ; i++ ){
				if( top + i >= string.length ){
					break;
				}
				if( isCharEscape( string, top + i ) ){
					i++;
					if( top + i >= string.length ){
						break;
					}
					switch( charAt( string, top + i ) ){
					case 'b': tmp[0] = MATH_CHAR( '\b' ).toDouble(); break;
					case 'f': tmp[0] = MATH_CHAR( '\f' ).toDouble(); break;
					case 'n': tmp[0] = MATH_CHAR( '\n' ).toDouble(); break;
					case 'r': tmp[0] = MATH_CHAR( '\r' ).toDouble(); break;
					case 't': tmp[0] = MATH_CHAR( '\t' ).toDouble(); break;
					case 'v': tmp[0] = MATH_CHAR( '\v' ).toDouble(); break;
					default : tmp[0] = charCodeAt( string, top + i ).toDouble(); break;
					}
				} else {
					tmp[0] = charCodeAt( string, top + i ).toDouble();
				}
				value.ass( value.toFloat() * 256 + tmp[0] );
				j++;
				if( j >= 4 ){
					break;
				}
			}
			if( swi ){
				value.ass( value.minus() );
			}
		} else if( isCharEscape( string, top ) ){
			switch( charAt( string, top + 1 ) ){
			case 'b':
			case 'B':
				value.ass( stringToInt( string, top + 2, stop, 2 ) );
				break;
			case '0':
				value.ass( stringToInt( string, top + 2, stop, 8 ) );
				break;
			case '1':
			case '2':
			case '3':
			case '4':
			case '5':
			case '6':
			case '7':
			case '8':
			case '9':
				value.ass( stringToInt( string, top + 1, stop, 10 ) );
				break;
			case 'x':
			case 'X':
				value.ass( stringToInt( string, top + 2, stop, 16 ) );
				break;
			default:
				return false;
			}
			if( stop.val() < string.length ){
				return false;
			}
			if( swi ){
				value.ass( value.minus() );
			}
		} else {
			if( (param.mode() & CLIP_MODE_COMPLEX) != 0 ){
				tmp[0] = stringToFloat( string, top, stop );
				switch( charAt( string, stop.val() ) ){
				case '\\':
				case CLIP_CHAR_UTF8_YEN:
				case '+':
				case '-':
					// 実数部
					if( stop.val() == top ){
						return false;
					}
					value.setReal( swi ? -tmp[0] : tmp[0] );

					// 虚数部
					if( isCharEscape( string, stop.val() ) ){
						stop.add( 1 );
					}
					switch( charAt( string, stop.val() ) ){
					case '+': swi = false; break;
					case '-': swi = true ; break;
					default : return false;
					}
					top = stop.val() + 1;
					tmp[0] = stringToFloat( string, top, stop );
					if( (charAt( string, stop.val() ) != 'i') && (charAt( string, stop.val() ) != 'I') ){
						return false;
					} else {
						if( stop.val() + 1 < string.length ){
							return false;
						}
						if( stop.val() == top ){
							value.setImag( swi ? -1.0 : 1.0 );
						} else {
							value.setImag( swi ? -tmp[0] : tmp[0] );
						}
					}

					break;
				case 'i':
				case 'I':
					if( stop.val() + 1 < string.length ){
						return false;
					}

					// 実数部
					value.setReal( 0.0 );

					// 虚数部
					if( stop.val() == top ){
						value.setImag( swi ? -1.0 : 1.0 );
					} else {
						value.setImag( swi ? -tmp[0] : tmp[0] );
					}

					break;
				default:
					if( stop.val() == top ){
						return false;
					}
					value.ass( swi ? -tmp[0] : tmp[0] );
					if( stop.val() < string.length ){
						switch( charAt( string, stop.val() ) ){
						case 'd': case 'D': value.angToAng( MATH_ANG_TYPE_DEG , complexAngType() ); break;
						case 'g': case 'G': value.angToAng( MATH_ANG_TYPE_GRAD, complexAngType() ); break;
						case 'r': case 'R': value.angToAng( MATH_ANG_TYPE_RAD , complexAngType() ); break;
						default : return false;
						}
					}
					break;
				}
			} else if( (param.mode() & (CLIP_MODE_FLOAT | CLIP_MODE_FRACT)) != 0 ){
				tmp[0] = stringToFloat( string, top, stop );
				switch( charAt( string, stop.val() ) ){
				case '_':
				case CLIP_CHAR_FRACT:
					if( stop.val() == top ){
						return false;
					}
					value.fractSetMinus( swi );
					value.setNum( tmp[0] );

					if( isCharEscape( string, stop.val() + 1 ) ){
						top = stop.val() + 2;
					} else {
						top = stop.val() + 1;
					}
					tmp[0] = stringToFloat( string, top, stop );
					switch( charAt( string, stop.val() ) ){
					case '_':
					case CLIP_CHAR_FRACT:
						if( stop.val() == top ){
							return false;
						}

						if( isCharEscape( string, stop.val() + 1 ) ){
							top = stop.val() + 2;
						} else {
							top = stop.val() + 1;
						}
						tmp[1] = stringToFloat( string, top, stop );
						if( (tmp[0] < 0.0) || (tmp[1] < 0.0) ){
							return false;
						}
						value.setDenom( tmp[1] );
						value.setNum  ( value.num() * value.denom() + tmp[0] );
						value.fractReduce();
						break;
					default:
						if( tmp[0] < 0.0 ){
							return false;
						}
						value.setDenom( tmp[0] );
						value.fractReduce();
						break;
					}
					break;
				default:
					if( stop.val() == top ){
						return false;
					}
					value.ass( swi ? -tmp[0] : tmp[0] );
					break;
				}
				if( stop.val() < string.length ){
					switch( charAt( string, stop.val() ) ){
					case 'd': case 'D': value.angToAng( MATH_ANG_TYPE_DEG , complexAngType() ); break;
					case 'g': case 'G': value.angToAng( MATH_ANG_TYPE_GRAD, complexAngType() ); break;
					case 'r': case 'R': value.angToAng( MATH_ANG_TYPE_RAD , complexAngType() ); break;
					default : return false;
					}
				}
			} else if( (param.mode() & CLIP_MODE_TIME) != 0 ){
				bool _break = false;
				for( i = 0; i < 4; i++ ){
					if( isCharEscape( string, top ) ){
						top++;
					}
					tmp[i] = stringToFloat( string, top, stop );
					if( stop.val() == top ){
						return false;
					}
					if( stop.val() >= string.length ){
						break;
					}
					switch( charAt( string, stop.val() ) ){
					case 'h':
					case 'H':
					case 'm':
					case 'M':
					case 's':
					case 'S':
					case 'f':
					case 'F':
						if( stop.val() + 1 < string.length ){
							return false;
						}
						_break = true;
						break;
					case ':':
						break;
					default:
						return false;
					}
					if( _break ){
						break;
					}
					top = stop.val() + 1;
				}
				value.timeSetMinus( swi );
				switch( i ){
				case 0:
					if( stop.val() < string.length ){
						switch( charAt( string, stop.val() ) ){
						case 'h': case 'H': value.setHour ( tmp[0] ); value.timeReduce(); break;
						case 'm': case 'M': value.setMin  ( tmp[0] ); value.timeReduce(); break;
						case 's': case 'S': value.setSec  ( tmp[0] ); value.timeReduce(); break;
						case 'f': case 'F': value.setFrame( tmp[0] ); value.timeReduce(); break;
						}
					} else {
						value.setSec( tmp[0] );
						value.timeReduce();
					}
					break;
				case 1:
					if( stop.val() < string.length ){
						switch( charAt( string, stop.val() ) ){
						case 'h': case 'H': return false;
						case 'm': case 'M': value.setHour( tmp[0] ); value.setMin  ( tmp[1] ); value.timeReduce(); break;
						case 's': case 'S': value.setMin ( tmp[0] ); value.setSec  ( tmp[1] ); value.timeReduce(); break;
						case 'f': case 'F': value.setSec ( tmp[0] ); value.setFrame( tmp[1] ); value.timeReduce(); break;
						}
					} else {
						switch( param.mode() & CLIP_MODE_MASK ){
						case CLIP_MODE_H_TIME:
						case CLIP_MODE_M_TIME: value.setHour( tmp[0] ); value.setMin  ( tmp[1] ); value.timeReduce(); break;
						case CLIP_MODE_S_TIME: value.setMin ( tmp[0] ); value.setSec  ( tmp[1] ); value.timeReduce(); break;
						case CLIP_MODE_F_TIME: value.setSec ( tmp[0] ); value.setFrame( tmp[1] ); value.timeReduce(); break;
						}
					}
					break;
				case 2:
					if( stop.val() < string.length ){
						switch( charAt( string, stop.val() ) ){
						case 'h': case 'H':
						case 'm': case 'M': return false;
						case 's': case 'S': value.setHour( tmp[0] ); value.setMin( tmp[1] ); value.setSec  ( tmp[2] ); value.timeReduce(); break;
						case 'f': case 'F': value.setMin ( tmp[0] ); value.setSec( tmp[1] ); value.setFrame( tmp[2] ); value.timeReduce(); break;
						}
					} else {
						switch( param.mode() & CLIP_MODE_MASK ){
						case CLIP_MODE_H_TIME:
						case CLIP_MODE_M_TIME:
						case CLIP_MODE_S_TIME: value.setHour( tmp[0] ); value.setMin( tmp[1] ); value.setSec  ( tmp[2] ); value.timeReduce(); break;
						case CLIP_MODE_F_TIME: value.setMin ( tmp[0] ); value.setSec( tmp[1] ); value.setFrame( tmp[2] ); value.timeReduce(); break;
						}
					}
					break;
				case 3:
					if( stop.val() < string.length ){
						switch( charAt( string, stop.val() ) ){
						case 'h': case 'H':
						case 'm': case 'M':
						case 's': case 'S': return false;
						case 'f': case 'F': value.setHour( tmp[0] ); value.setMin( tmp[1] ); value.setSec( tmp[2] ); value.setFrame( tmp[3] ); value.timeReduce(); break;
						}
					} else {
						switch( param.mode() & CLIP_MODE_MASK ){
						case CLIP_MODE_H_TIME:
						case CLIP_MODE_M_TIME:
						case CLIP_MODE_S_TIME:
						case CLIP_MODE_F_TIME: value.setHour( tmp[0] ); value.setMin( tmp[1] ); value.setSec( tmp[2] ); value.setFrame( tmp[3] ); value.timeReduce(); break;
						}
					}
					break;
				}
			} else if( (param.mode() & CLIP_MODE_INT) != 0 ){
				value.ass( stringToInt( string, top, stop, param.radix() ) );
				if( stop.val() < string.length ){
					return false;
				}
				if( swi ){
					value.ass( value.minus() );
				}
			}
		}

		return true;
	}

	// 浮動小数点数値を文字列に変換する
	String _floatToString( ClipParam param, double value ){
		String str = "";
		int prec = param.prec();
		switch( param.mode() & CLIP_MODE_MASK ){
		case CLIP_MODE_E_FLOAT:
		case CLIP_MODE_E_COMPLEX:
			str = floatToExponential( value, (prec == 0) ? MATH_EPREC( value ).toInt() : prec );
			break;
		case CLIP_MODE_F_FLOAT:
		case CLIP_MODE_F_COMPLEX:
			str = floatToFixed( value, (prec == 0) ? MATH_FPREC( value ).toInt() : prec );
			break;
		case CLIP_MODE_G_FLOAT:
		case CLIP_MODE_G_COMPLEX:
			str = floatToString( value, (prec == 0) ? 15 : prec );
			break;
		}
		return str;
	}

	void valueToString( ClipParam param, MathValue value, ParamString real, ParamString imag ){
		switch( param.mode() & CLIP_MODE_MASK ){
		case CLIP_MODE_E_COMPLEX:
		case CLIP_MODE_F_COMPLEX:
		case CLIP_MODE_G_COMPLEX:
			if( MATH_ISZERO( value.imag() ) ){
				real.set( _floatToString( param, value.real() ) );
				imag.set( "" );
			} else if( MATH_ISZERO( value.real() ) ){
				real.set( "" );
				imag.set( "${_floatToString( param, value.imag() )}i" );
			} else {
				real.set( _floatToString( param, value.real() ) );
				imag.set( (value.imag() > 0.0) ? "+" : "" );
				imag.add( "${_floatToString( param, value.imag() )}i" );
			}
			break;
		case CLIP_MODE_E_FLOAT:
		case CLIP_MODE_F_FLOAT:
		case CLIP_MODE_G_FLOAT:
			real.set( _floatToString( param, value.real() ) );
			imag.set( "" );
			break;
		case CLIP_MODE_M_FRACT:
			if( (value.denom() != 0) && (MATH_DIV( value.num(), value.denom() ) != 0) ){
				if( MATH_MOD( value.num(), value.denom() ) != 0 ){
					real.set( value.fractMinus() ? "-" : "" );
					real.add( "${MATH_DIV( value.num(), value.denom() ).toInt()}" );
					real.add( CLIP_CHAR_FRACT );
					real.add( "${MATH_MOD( value.num(), value.denom() ).toInt()}" );
					real.add( CLIP_CHAR_FRACT );
					real.add( "${value.denom().toInt()}" );
				} else {
					real.set( value.fractMinus() ? "-" : "" );
					real.add( "${MATH_DIV( value.num(), value.denom() ).toInt()}" );
				}
				imag.set( "" );
				break;
			}
			// そのまま下に流す
			continue case_CLIP_MODE_I_FRACT;
		case_CLIP_MODE_I_FRACT:
		case CLIP_MODE_I_FRACT:
			if( value.denom() == 0 ){
				real.set( "${value.toFloat()}" );
			} else if( value.denom() == 1 ){
				real.set( value.fractMinus() ? "-" : "" );
				real.add( "${value.num().toInt()}" );
			} else {
				real.set( value.fractMinus() ? "-" : "" );
				real.add( "${value.num().toInt()}" );
				real.add( CLIP_CHAR_FRACT );
				real.add( "${value.denom().toInt()}" );
			}
			imag.set( "" );
			break;
		case CLIP_MODE_H_TIME:
			real.set( value.timeMinus() ? "-" : "" );
			real.add( ((value.hour() < 10.0) ? "0" : "") + floatToString( value.hour(), CLIP_DEFPREC ) );
			imag.set( "" );
			break;
		case CLIP_MODE_M_TIME:
			if( MATH_INT( value.hour() ) != 0 ){
				real.set( value.timeMinus() ? "-" : "" );
				real.add( ((value.hour() < 10.0) ? "0" : "") + floatToString( MATH_INT( value.hour() ) ) );
				real.add( ":" );
				real.add( ((value.min () < 10.0) ? "0" : "") + floatToString( value.min(), CLIP_DEFPREC ) );
			} else {
				real.set( value.timeMinus() ? "-" : "" );
				real.add( ((value.min() < 10.0) ? "0" : "") + floatToString( value.min(), CLIP_DEFPREC ) );
			}
			imag.set( "" );
			break;
		case CLIP_MODE_S_TIME:
			if( MATH_INT( value.hour() ) != 0 ){
				real.set( value.timeMinus() ? "-" : "" );
				real.add( ((value.hour() < 10.0) ? "0" : "") + floatToString( MATH_INT( value.hour() ) ) );
				real.add( ":" );
				real.add( ((value.min () < 10.0) ? "0" : "") + floatToString( MATH_INT( value.min() ) ) );
				real.add( ":" );
				real.add( ((value.sec () < 10.0) ? "0" : "") + floatToString( value.sec(), CLIP_DEFPREC ) );
			} else if( MATH_INT( value.min() ) != 0 ){
				real.set( value.timeMinus() ? "-" : "" );
				real.add( ((value.min() < 10.0) ? "0" : "") + floatToString( MATH_INT( value.min() ) ) );
				real.add( ":" );
				real.add( ((value.sec() < 10.0) ? "0" : "") + floatToString( value.sec(), CLIP_DEFPREC ) );
			} else {
				real.set( value.timeMinus() ? "-" : "" );
				real.add( ((value.sec() < 10.0) ? "0" : "") + floatToString( value.sec(), CLIP_DEFPREC ) );
			}
			imag.set( "" );
			break;
		case CLIP_MODE_F_TIME:
			if( MATH_INT( value.hour() ) != 0 ){
				real.set( value.timeMinus() ? "-" : "" );
				real.add( ((value.hour () < 10.0) ? "0" : "") + floatToString( MATH_INT( value.hour() ) ) );
				real.add( ":" );
				real.add( ((value.min  () < 10.0) ? "0" : "") + floatToString( MATH_INT( value.min() ) ) );
				real.add( ":" );
				real.add( ((value.sec  () < 10.0) ? "0" : "") + floatToString( MATH_INT( value.sec() ) ) );
				real.add( ":" );
				real.add( ((value.frame() < 10.0) ? "0" : "") + floatToString( value.frame(), CLIP_DEFPREC ) );
			} else if( MATH_INT( value.min() ) != 0 ){
				real.set( value.timeMinus() ? "-" : "" );
				real.add( ((value.min  () < 10.0) ? "0" : "") + floatToString( MATH_INT( value.min() ) ) );
				real.add( ":" );
				real.add( ((value.sec  () < 10.0) ? "0" : "") + floatToString( MATH_INT( value.sec() ) ) );
				real.add( ":" );
				real.add( ((value.frame() < 10.0) ? "0" : "") + floatToString( value.frame(), CLIP_DEFPREC ) );
			} else if( MATH_INT( value.sec() ) != 0 ){
				real.set( value.timeMinus() ? "-" : "" );
				real.add( ((value.sec  () < 10.0) ? "0" : "") + floatToString( MATH_INT( value.sec() ) ) );
				real.add( ":" );
				real.add( ((value.frame() < 10.0) ? "0" : "") + floatToString( value.frame(), CLIP_DEFPREC ) );
			} else {
				real.set( value.timeMinus() ? "-" : "" );
				real.add( ((value.frame() < 10.0) ? "0" : "") + floatToString( value.frame(), CLIP_DEFPREC ) );
			}
			imag.set( "" );
			break;
		case CLIP_MODE_S_CHAR:
			real.set( intToString( MATH_SIGNED( value.toFloat(), MATH_UMAX_8, MATH_SMIN_8, MATH_SMAX_8 ), param.radix() ) );
			imag.set( "" );
			break;
		case CLIP_MODE_U_CHAR:
			real.set( intToString( MATH_UNSIGNED( value.toFloat(), MATH_UMAX_8 ), param.radix() ) );
			imag.set( "" );
			break;
		case CLIP_MODE_S_SHORT:
			real.set( intToString( MATH_SIGNED( value.toFloat(), MATH_UMAX_16, MATH_SMIN_16, MATH_SMAX_16 ), param.radix() ) );
			imag.set( "" );
			break;
		case CLIP_MODE_U_SHORT:
			real.set( intToString( MATH_UNSIGNED( value.toFloat(), MATH_UMAX_16 ), param.radix() ) );
			imag.set( "" );
			break;
		case CLIP_MODE_S_LONG:
			real.set( intToString( MATH_SIGNED( value.toFloat(), MATH_UMAX_32, MATH_SMIN_32, MATH_SMAX_32 ), param.radix() ) );
			imag.set( "" );
			break;
		case CLIP_MODE_U_LONG:
			real.set( intToString( MATH_UNSIGNED( value.toFloat(), MATH_UMAX_32 ), param.radix() ) );
			imag.set( "" );
			break;
		}
	}

	void sepString( ParamString string, String sep ){
		String src = "";
		String dst = "";
		int top;
		int end;
		bool _float;
		bool _break;
		int len;

		src = string.str();
		dst = "";
		top = 0;
		while( true ){
			_float = false;

			// 先頭を求める
			_break = false;
			for( ; top < src.length; top++ ){
				switch( charAt( src, top ) ){
				case '+':
				case '-':
				case '.':
				case 'e':
				case 'E':
				case 'i':
				case 'I':
				case '_':
				case CLIP_CHAR_FRACT:
				case ':':
					if( charAt( src, top ) == '.' ){
						_float = true;
					}
					dst += charAt( src, top );
					break;
				default:
					_break = true;
					break;
				}
				if( _break ){
					break;
				}
			}
			if( top >= src.length ){
				break;
			}

			// 末尾を求める
			_break = false;
			for( end = top + 1; end < src.length; end++ ){
				switch( charAt( src, end ) ){
				case '+':
				case '-':
				case '.':
				case 'e':
				case 'E':
				case 'i':
				case 'I':
				case '_':
				case CLIP_CHAR_FRACT:
				case ':':
					_break = true;
					break;
				}
				if( _break ){
					break;
				}
			}

			for( len = end - top; len > 0; len-- ){
				dst += charAt( src, top );
				top++;
				if( !_float && (len != 1) && ((len % 3) == 1) ){
					dst += sep;
				}
			}
		}

		string.set( dst );
	}

	// トークン文字列を確保する
	dynamic newToken( int code, dynamic token ){
		switch( code ){
		case CLIP_CODE_TOP:
		case CLIP_CODE_END:
		case CLIP_CODE_ARRAY_TOP:
		case CLIP_CODE_ARRAY_END:
		case CLIP_CODE_PARAM_ANS:
		case CLIP_CODE_PARAM_ARRAY:
			return null;
		case CLIP_CODE_CONSTANT:
			return dupValue( token );
		case CLIP_CODE_MATRIX:
			return dupMatrix( token );
		case CLIP_CODE_MULTIPREC:
			{
				MPData a = token;
				return a.clone();
			}
		}
		return token;
	}

	// トークン文字列を解放する
	void delToken( int code, dynamic token ){
		if( token != null ){
			switch( code ){
			case CLIP_CODE_CONSTANT:
				deleteValue( token );
				break;
			case CLIP_CODE_MATRIX:
				deleteMatrix( token );
				break;
			}
		}
	}

	// トークン文字列を確保する
	void _newToken( ClipTokenData cur, ClipParam param, String token, int len, bool strToVal ){
		int i;
		String tmp;
		ParamInteger code = ParamInteger();

		switch( charCodeAt( token, 0 ) ){
		case CLIP_CODE_TOP:
		case CLIP_CODE_END:
		case CLIP_CODE_ARRAY_TOP:
		case CLIP_CODE_ARRAY_END:
		case CLIP_CODE_PARAM_ARRAY:
			cur._code  = charCodeAt( token, 0 );
			cur._token = null;
			break;
		case CLIP_CODE_OPERATOR:
			cur._code  = charCodeAt( token, 0 );
			cur._token = charCodeAt( token, 1 );
			break;
		default:
			if( charAt( token, 0 ) == '@' ){
				if( len == 1 ){
					cur._code  = CLIP_CODE_ARRAY;
					cur._token = 0;
				} else if( (len > 2) && (charAt( token, 1 ) == '@') ){
					cur._code  = CLIP_CODE_ARRAY;
					cur._token = charCodeAt( token, 2 );
				} else {
					cur._code  = CLIP_CODE_VARIABLE;
					cur._token = charCodeAt( token, 1 );
				}
				break;
			}

			if( charAt( token, 0 ) == '&' ){
				if( len == 1 ){
					cur._code  = CLIP_CODE_PARAM_ANS;
					cur._token = null;
					break;
				}
				// そのまま下に流す
			}

			tmp = token.substring( 0, len );

			if( charAt( tmp, 0 ) == '\$' ){
				if( checkSe( tmp.substring( 1, len ).toLowerCase(), code ) ){
					switch( code.val() ){
					case CLIP_SE_LOOPSTART:
						cur._code  = CLIP_CODE_STATEMENT;
						cur._token = CLIP_STAT_START;
						break;
					case CLIP_SE_LOOPEND:
						cur._code  = CLIP_CODE_STATEMENT;
						cur._token = CLIP_STAT_END;
						break;
					case CLIP_SE_LOOPEND_INC:
						cur._code  = CLIP_CODE_STATEMENT;
						cur._token = CLIP_STAT_END_INC;
						break;
					case CLIP_SE_LOOPEND_DEC:
						cur._code  = CLIP_CODE_STATEMENT;
						cur._token = CLIP_STAT_END_DEC;
						break;
					case CLIP_SE_LOOPENDEQ:
						cur._code  = CLIP_CODE_STATEMENT;
						cur._token = CLIP_STAT_ENDEQ;
						break;
					case CLIP_SE_LOOPENDEQ_INC:
						cur._code  = CLIP_CODE_STATEMENT;
						cur._token = CLIP_STAT_ENDEQ_INC;
						break;
					case CLIP_SE_LOOPENDEQ_DEC:
						cur._code  = CLIP_CODE_STATEMENT;
						cur._token = CLIP_STAT_ENDEQ_DEC;
						break;
					case CLIP_SE_LOOPCONT:
						cur._code  = CLIP_CODE_STATEMENT;
						cur._token = CLIP_STAT_CONT;
						break;
					case CLIP_SE_CONTINUE:
						cur._code  = CLIP_CODE_STATEMENT;
						cur._token = CLIP_STAT_CONTINUE2;
						break;
					case CLIP_SE_BREAK:
						cur._code  = CLIP_CODE_STATEMENT;
						cur._token = CLIP_STAT_BREAK2;
						break;
					case CLIP_SE_RETURN:
						cur._code  = CLIP_CODE_STATEMENT;
						cur._token = CLIP_STAT_RETURN2;
						break;
					case CLIP_SE_RETURN_ANS:
						cur._code  = CLIP_CODE_STATEMENT;
						cur._token = CLIP_STAT_RETURN3;
						break;
					default:
						cur._code  = CLIP_CODE_SE;
						cur._token = code.val();
						break;
					}
				} else {
					cur._code  = CLIP_CODE_SE;
					cur._token = CLIP_SE_NULL;
				}
			} else if( checkSqOp( tmp, code ) ){
				cur._code  = CLIP_CODE_OPERATOR;
				cur._token = code.val();
			} else if( charAt( tmp, 0 ) == ':' ){
				cur._code = CLIP_CODE_COMMAND;
				if( checkCommand( tmp.substring( 1, len ), code ) ){
					cur._token = code.val();
				} else {
					cur._token = CLIP_COMMAND_NULL;
				}
			} else if( charAt( tmp, 0 ) == '!' ){
				cur._code  = CLIP_CODE_EXTFUNC;
				cur._token = tmp.substring( 1, len ).toLowerCase();
			} else if( charAt( tmp, 0 ) == '"' ){
				cur._code  = CLIP_CODE_STRING;
				cur._token = "";
				for( i = 1; ; i++ ){
					if( i >= tmp.length ){
						break;
					}
					if( isCharEscape( tmp, i ) ){
						i++;
						if( i >= tmp.length ){
							break;
						}
						switch( charAt( tmp, i ) ){
						case 'b': cur._token += '\b'; break;
						case 'f': cur._token += '\f'; break;
						case 'n': cur._token += '\n'; break;
						case 'r': cur._token += '\r'; break;
						case 't': cur._token += '\t'; break;
						case 'v': cur._token += '\v'; break;
						default : cur._token += charAt( tmp, i ); break;
						}
					} else {
						cur._token += charAt( tmp, i );
					}
				}
			} else if( checkFunc( tmp.toLowerCase(), code ) ){
				cur._code  = CLIP_CODE_FUNCTION;
				cur._token = code.val();
			} else if( checkStat( tmp, code ) ){
				cur._code  = CLIP_CODE_STATEMENT;
				cur._token = code.val();
			} else {
				cur._token = MathValue();
				if( checkDefine( tmp, cur._token ) ){
					cur._code = CLIP_CODE_CONSTANT;
				} else if( strToVal && stringToValue( param, tmp, cur._token ) ){
					cur._code = CLIP_CODE_CONSTANT;
				} else {
					cur._code  = CLIP_CODE_LABEL;
					cur._token = tmp;
				}
			}

			break;
		}
	}
	void _newTokenValue( ClipTokenData cur, MathValue value ){
		cur._code  = CLIP_CODE_CONSTANT;
		cur._token = dupValue( value );
	}
	void _newTokenMatrix( ClipTokenData cur, MathMatrix value ){
		cur._code  = CLIP_CODE_MATRIX;
		cur._token = dupMatrix( value );
	}
	void _newTokenMultiPrec( ClipTokenData cur, MPData value ){
		cur._code  = CLIP_CODE_MULTIPREC;
		cur._token = value.clone();
	}

	// トークン文字列を解放する
	void _delToken( ClipTokenData cur ){
		delToken( cur._code, cur._token );
		cur._token = null;
	}

	// リストを検索する
	ClipTokenData? _searchList( int num ){
		int tmp = 0;
		ClipTokenData? cur = _top;
		while( true ){
			if( cur == null ){
				return null;
			}
			if( tmp == num ){
				break;
			}
			tmp++;
			cur = cur._next;
		}
		return cur;
	}

	// トークンを追加する
	ClipTokenData _addToken(){
		ClipTokenData tmp = ClipTokenData();
		if( _top == null ){
			// 先頭に登録する
			_top = tmp;
			_end = tmp;
		} else {
			// 最後尾に追加する
			tmp._before = _end;
			_end!._next = tmp;
			_end        = tmp;
		}
		return tmp;
	}
	void add( ClipParam param, String token, int len, bool strToVal ){
		bool addFact = false;
		if( (charAt( token, 0 ) != '"') && (charAt( token, len - 1 ) == '!') ){
			if( len == 1 ){
				token = String.fromCharCode( CLIP_CODE_OPERATOR ) + String.fromCharCode( CLIP_OP_FACT );
			} else if( charAt( token, len - 2 ) != '@' ){
				addFact = true;
				token = token.substring( 0, len - 1 );
			}
		}
		_newToken( _addToken(), param, token, len, strToVal );
		if( addFact ){
			token = String.fromCharCode( CLIP_CODE_OPERATOR ) + String.fromCharCode( CLIP_OP_FACT );
			_newToken( _addToken(), param, token, 1, strToVal );
		}
	}
	void addSq( ClipParam param, String token, int len, bool strToVal ){ // Square Bracket
		_newToken( _addToken(), param, token, len, strToVal );
	}
	void addValue( MathValue value ){
		_newTokenValue( _addToken(), value );
	}
	void addMatrix( MathMatrix value ){
		_newTokenMatrix( _addToken(), value );
	}
	void addMultiPrec( MPData value ){
		_newTokenMultiPrec( _addToken(), value );
	}
	void addCode( int code, dynamic token ){
		ClipTokenData tmp = _addToken();
		tmp._code  = code;
		tmp._token = newToken( code, token );
	}

	// トークンを挿入する
	ClipTokenData _insToken( ClipTokenData cur ){
		ClipTokenData tmp = ClipTokenData();
		tmp._before = cur._before;
		tmp._next   = cur;
		if( cur._before != null ){
			cur._before!._next = tmp;
		} else {
			_top = tmp;
		}
		cur._before = tmp;
		return tmp;
	}
	void _ins( ClipTokenData? cur, ClipParam param, String token, int len, bool strToVal ){
		if( cur == null ){
			add( param, token, len, strToVal );
		} else {
			_newToken( _insToken( cur ), param, token, len, strToVal );
		}
	}
	void _insValue( ClipTokenData? cur, MathValue value ){
		if( cur == null ){
			addValue( value );
		} else {
			_newTokenValue( _insToken( cur ), value );
		}
	}
	void _insMatrix( ClipTokenData? cur, MathMatrix value ){
		if( cur == null ){
			addMatrix( value );
		} else {
			_newTokenMatrix( _insToken( cur ), value );
		}
	}
	void _insMultiPrec( ClipTokenData? cur, MPData value ){
		if( cur == null ){
			addMultiPrec( value );
		} else {
			_newTokenMultiPrec( _insToken( cur ), value );
		}
	}
	void _insCode( ClipTokenData? cur, int code, dynamic token ){
		if( cur == null ){
			addCode( code, token );
		} else {
			ClipTokenData tmp = _insToken( cur );
			tmp._code  = code;
			tmp._token = newToken( code, token );
		}
	}
	void ins( int num, ClipParam param, String token, int len, bool strToVal ){
		_ins( _searchList( num ), param, token, len, strToVal );
	}
	void insValue( int num, MathValue value ){
		_insValue( _searchList( num ), value );
	}
	void insMatrix( int num, MathMatrix value ){
		_insMatrix( _searchList( num ), value );
	}
	void insMultiPrec( int num, MPData value ){
		_insMultiPrec( _searchList( num ), value );
	}
	void insCode( int num, int code, dynamic token ){
		_insCode( _searchList( num ), code, token );
	}

	// トークンを削除する
	int del( int num ){
		ClipTokenData? tmp;

		if( num == 0 ){
			tmp = _top;
		} else if( num < 0 ){
			tmp = _end;
		} else {
			tmp = _searchList( num );
		}
		if( tmp == null ){
			return CLIP_ERR_TOKEN;
		}

		if( tmp._before != null ){
			tmp._before!._next = tmp._next;
		} else {
			_top = tmp._next;
		}
		if( tmp._next != null ){
			tmp._next!._before = tmp._before;
		} else {
			_end = tmp._before;
		}

		// トークン文字列の解放
		_delToken( tmp );

		return CLIP_NO_ERR;
	}

	// 全トークンを削除する
	void delAll(){
		ClipTokenData? cur;
		ClipTokenData tmp;

		cur = _top;
		while( cur != null ){
			tmp = cur;
			cur = cur._next;

			// トークン文字列の解放
			_delToken( tmp );
		}
		_top = null;
	}

	// 文字列をトークン毎に分割する
	int separate( ClipParam param, String line, bool strToVal ){
		int cur;
		String token = "";
		int len = 0;
		bool strFlag = false;
		int topCount = 0;
		bool formatSeFlag = false;

		// 全トークンを削除する
		delAll();

		cur = 0;
		while( cur < line.length ){
			if( isCharEscape( line, cur ) ){
				switch( charAt( line, cur + 1 ) ){
				case '0':
				case '1':
				case '2':
				case '3':
				case '4':
				case '5':
				case '6':
				case '7':
				case '8':
				case '9':
				case 'b':
				case 'B':
				case 'f':
				case 'n':
				case 'r':
				case 't':
				case 'v':
				case 'x':
				case 'X':
					break;
				case '\\':
				case CLIP_CHAR_UTF8_YEN:
					if( len == 0 ) token = "";
					token += charAt( line, cur );
					len++;
					// そのまま下に流す
					continue _default;
				_default:
				default:
					cur++;
					if( cur >= line.length ){
						continue;
					}
					break;
				}
				if( len == 0 ) token = "";
				token += charAt( line, cur );
				len++;
			} else if( (charAt( line, cur ) == '[') && !strFlag ){
				if( len > 0 ){
					add( param, token, len, strToVal );
					len = 0;
				}
				strFlag = true;
			} else if( (charAt( line, cur ) == ']') && strFlag ){
				if( len == 0 ){
					token = String.fromCharCode( CLIP_CODE_PARAM_ARRAY );
					add( param, token, 1, strToVal );
				} else {
					addSq( param, token, len, strToVal );
					len = 0;
				}
				strFlag = false;
			} else if( strFlag ){
				if( len == 0 ) token = "";
				token += charAt( line, cur );
				len++;
			} else {
				String curChar = charAt( line, cur );
				if( charCodeAt( line, cur ) == CLIP_CHAR_CODE_SPACE ){
					curChar = ' ';
				}
				switch( curChar ){
				case ' ':
				case '\t':
				case '\r':
				case '\n':
					if( len > 0 ){
						add( param, token, len, strToVal );
						len = 0;
					}
					break;
				case '(':
				case ')':
				case '{':
				case '}':
					if( len > 0 ){
						add( param, token, len, strToVal );
						len = 0;
					}
					switch( curChar ){
					case '(':
						token = String.fromCharCode( CLIP_CODE_TOP );
						if( !formatSeFlag ){
							if( topCount >= 0 ){
								topCount++;
							}
						}
						break;
					case ')':
						token = String.fromCharCode( CLIP_CODE_END );
						if( !formatSeFlag ){
							topCount--;
						}
						break;
					case '{':
						token = String.fromCharCode( CLIP_CODE_ARRAY_TOP );
						formatSeFlag = true;
						break;
					case '}':
						token = String.fromCharCode( CLIP_CODE_ARRAY_END );
						formatSeFlag = false;
						break;
					}
					add( param, token, 1, strToVal );
					break;
				case ':':
					if( len == 0 ) token = "";
					token += curChar;
					len++;
					if( charAt( token, 0 ) == '@' ){
						add( param, token, len, strToVal );
						len = 0;
					}
					break;
				case '?':
				case '=':
				case ',':
					if( len > 0 ){
						add( param, token, len, strToVal );
						len = 0;
					}
					token = String.fromCharCode( CLIP_CODE_OPERATOR );
					switch( curChar ){
					case '?': token += String.fromCharCode( CLIP_OP_CONDITIONAL ); break;
					case ',': token += String.fromCharCode( CLIP_OP_COMMA       ); break;
					case '=':
						if( charAt( line, cur + 1 ) == '=' ){
							token += String.fromCharCode( CLIP_OP_EQUAL );
							cur++;
						} else {
							token += String.fromCharCode( CLIP_OP_ASS );
						}
						break;
					}
					add( param, token, 2, strToVal );
					break;
				case '&':
					if( len > 0 ){
						add( param, token, len, strToVal );
						len = 0;
					}
					token = String.fromCharCode( CLIP_CODE_OPERATOR );
					switch( charAt( line, cur + 1 ) ){
					case '&': token += String.fromCharCode( CLIP_OP_LOGAND    ); cur++; break;
					case '=': token += String.fromCharCode( CLIP_OP_ANDANDASS ); cur++; break;
					default : token += String.fromCharCode( CLIP_OP_AND       );        break;
					}
					add( param, token, 2, strToVal );
					break;
				case '|':
					if( len > 0 ){
						add( param, token, len, strToVal );
						len = 0;
					}
					token = String.fromCharCode( CLIP_CODE_OPERATOR );
					switch( charAt( line, cur + 1 ) ){
					case '|': token += String.fromCharCode( CLIP_OP_LOGOR    ); cur++; break;
					case '=': token += String.fromCharCode( CLIP_OP_ORANDASS ); cur++; break;
					default : token += String.fromCharCode( CLIP_OP_OR       );        break;
					}
					add( param, token, 2, strToVal );
					break;
				case '*':
				case '/':
				case '%':
				case '^':
					if( len > 0 ){
						add( param, token, len, strToVal );
						len = 0;
					}
					token = String.fromCharCode( CLIP_CODE_OPERATOR );
					if( charAt( line, cur + 1 ) == '=' ){
						switch( curChar ){
						case '*': token += String.fromCharCode( CLIP_OP_MULANDASS ); break;
						case '/': token += String.fromCharCode( CLIP_OP_DIVANDASS ); break;
						case '%': token += String.fromCharCode( CLIP_OP_MODANDASS ); break;
						case '^':
							if( param.enableOpPow() && ((param.mode() & CLIP_MODE_INT) == 0) ){
								token += String.fromCharCode( CLIP_OP_POWANDASS );
							} else {
								token += String.fromCharCode( CLIP_OP_XORANDASS );
							}
							break;
						}
						cur++;
					} else {
						switch( curChar ){
						case '*':
							if( charAt( line, cur + 1 ) == '*' ){
								if( charAt( line, cur + 2 ) == '=' ){
									token += String.fromCharCode( CLIP_OP_POWANDASS );
									cur += 2;
								} else {
									token += String.fromCharCode( CLIP_OP_POW );
									cur++;
								}
							} else {
								token += String.fromCharCode( CLIP_OP_MUL );
							}
							break;
						case '/': token += String.fromCharCode( CLIP_OP_DIV ); break;
						case '%': token += String.fromCharCode( CLIP_OP_MOD ); break;
						case '^':
							if( param.enableOpPow() && ((param.mode() & CLIP_MODE_INT) == 0) ){
								token += String.fromCharCode( CLIP_OP_POW );
							} else {
								token += String.fromCharCode( CLIP_OP_XOR );
							}
							break;
						}
					}
					add( param, token, 2, strToVal );
					break;
				case '+':
					if( len > 0 ){
						add( param, token, len, strToVal );
						len = 0;
					}
					token = String.fromCharCode( CLIP_CODE_OPERATOR );
					switch( charAt( line, cur + 1 ) ){
					case '=': token += String.fromCharCode( CLIP_OP_ADDANDASS  ); cur++; break;
					case '+': token += String.fromCharCode( CLIP_OP_POSTFIXINC ); cur++; break;
					default : token += String.fromCharCode( CLIP_OP_ADD        );        break;
					}
					add( param, token, 2, strToVal );
					break;
				case '-':
					if( len > 0 ){
						add( param, token, len, strToVal );
						len = 0;
					}
					token = String.fromCharCode( CLIP_CODE_OPERATOR );
					switch( charAt( line, cur + 1 ) ){
					case '=': token += String.fromCharCode( CLIP_OP_SUBANDASS  ); cur++; break;
					case '-': token += String.fromCharCode( CLIP_OP_POSTFIXDEC ); cur++; break;
					default : token += String.fromCharCode( CLIP_OP_SUB        );        break;
					}
					add( param, token, 2, strToVal );
					break;
				case '<':
				case '>':
					if( len > 0 ){
						add( param, token, len, strToVal );
						len = 0;
					}
					token = String.fromCharCode( CLIP_CODE_OPERATOR );
					if( charAt( line, cur + 1 ) == curChar ){
						if( charAt( line, cur + 2 ) == '=' ){
							switch( curChar ){
							case '<': token += String.fromCharCode( CLIP_OP_SHIFTLANDASS ); break;
							case '>': token += String.fromCharCode( CLIP_OP_SHIFTRANDASS ); break;
							}
							cur += 2;
						} else {
							switch( curChar ){
							case '<': token += String.fromCharCode( CLIP_OP_SHIFTL ); break;
							case '>': token += String.fromCharCode( CLIP_OP_SHIFTR ); break;
							}
							cur++;
						}
					} else {
						if( charAt( line, cur + 1 ) == '=' ){
							switch( curChar ){
							case '<': token += String.fromCharCode( CLIP_OP_LESSOREQ  ); break;
							case '>': token += String.fromCharCode( CLIP_OP_GREATOREQ ); break;
							}
							cur++;
						} else {
							switch( curChar ){
							case '<': token += String.fromCharCode( CLIP_OP_LESS  ); break;
							case '>': token += String.fromCharCode( CLIP_OP_GREAT ); break;
							}
						}
					}
					add( param, token, 2, strToVal );
					break;
				case '!':
					if( charAt( line, cur + 1 ) == '=' ){
						if( len > 0 ){
							add( param, token, len, strToVal );
							len = 0;
						}
						token = String.fromCharCode( CLIP_CODE_OPERATOR ) + String.fromCharCode( CLIP_OP_NOTEQUAL );
						cur++;
						add( param, token, 2, strToVal );
					} else {
						if( len == 0 ) token = "";
						token += curChar;
						len++;
					}
					break;
				case 'e':
				case 'E':
					if( ((param.mode() & CLIP_MODE_INT) == 0) && (len > 0) ){
						if( (charAt( line, cur + 1 ) == '+') || (charAt( line, cur + 1 ) == '-') ){
							bool _break = false;
							for( int i = 0; i < len; i++ ){
								switch( charAt( token, i ) ){
								case '+':
								case '-':
								case '0':
								case '1':
								case '2':
								case '3':
								case '4':
								case '5':
								case '6':
								case '7':
								case '8':
								case '9':
								case '.':
									break;
								default:
									_break = true;
									break;
								}
								if( _break ){
									break;
								}
							}
							if( !_break ){
								token += curChar;
								cur++;
								token += charAt( line, cur );
								len += 2;
								break;
							}
						}
					}
					// そのまま下に流す
					continue _default;
				_default:
				default:
					if( len == 0 ) token = "";
					token += curChar;
					len++;
					break;
				}
			}
			cur++;
		}
		if( len > 0 ){
			add( param, token, len, strToVal );
		}

		if( _top != null ){
			if( _top!._code == CLIP_CODE_SE ){
				if( topCount != 0 ){
					return CLIP_PROC_ERR_SE_OPERAND;
				}
			}
		}

		return CLIP_NO_ERR;
	}

	// トークンを整える
	int _checkOp( int op ){
		switch( op ){
		case CLIP_OP_POSTFIXINC:
		case CLIP_OP_POSTFIXDEC:
		case CLIP_OP_FACT:
			return 15;
		case CLIP_OP_INCREMENT:
		case CLIP_OP_DECREMENT:
		case CLIP_OP_COMPLEMENT:
		case CLIP_OP_NOT:
		case CLIP_OP_MINUS:
		case CLIP_OP_PLUS:
		case CLIP_OP_POW:
			return 14;
		case CLIP_OP_MUL:
		case CLIP_OP_DIV:
		case CLIP_OP_MOD:
			return 13;
		case CLIP_OP_ADD:
		case CLIP_OP_SUB:
			return 12;
		case CLIP_OP_SHIFTL:
		case CLIP_OP_SHIFTR:
			return 11;
		case CLIP_OP_LESS:
		case CLIP_OP_LESSOREQ:
		case CLIP_OP_GREAT:
		case CLIP_OP_GREATOREQ:
			return 10;
		case CLIP_OP_EQUAL:
		case CLIP_OP_NOTEQUAL:
			return 9;
		case CLIP_OP_AND:
			return 8;
		case CLIP_OP_XOR:
			return 7;
		case CLIP_OP_OR:
			return 6;
		case CLIP_OP_LOGAND:
			return 5;
		case CLIP_OP_LOGOR:
			return 4;
		case CLIP_OP_CONDITIONAL:
			return 3;
		case CLIP_OP_ASS:
		case CLIP_OP_MULANDASS:
		case CLIP_OP_DIVANDASS:
		case CLIP_OP_MODANDASS:
		case CLIP_OP_ADDANDASS:
		case CLIP_OP_SUBANDASS:
		case CLIP_OP_SHIFTLANDASS:
		case CLIP_OP_SHIFTRANDASS:
		case CLIP_OP_ANDANDASS:
		case CLIP_OP_ORANDASS:
		case CLIP_OP_XORANDASS:
		case CLIP_OP_POWANDASS:
			return 2;
		case CLIP_OP_COMMA:
			return 1;
		}
		return 0;
	}
	int _format( ClipTokenData? top, ClipParam param, bool strToVal ){
		int level, topLevel = 0;
		int assLevel = _checkOp( CLIP_OP_ASS );
		int posLevel = _checkOp( CLIP_OP_POSTFIXINC );
		int retTop, retEnd;
		ClipTokenData? tmpTop;
		ClipTokenData? tmpEnd;

		// 演算子の優先順位に従って括弧を付ける
		int i;
		ClipTokenData? cur = top;
		while( cur != null ){
			if( cur._code == CLIP_CODE_OPERATOR ){
				// 自分自身の演算子の優先レベルを調べておく
				level = _checkOp( cur._token );

				retTop = 0;
				retEnd = 0;

				// 前方検索
				i = 0;
				tmpTop = cur._before;
				while( tmpTop != null ){
					switch( tmpTop._code ){
					case CLIP_CODE_TOP:
						if( i > 0 ){
							i--;
						} else {
							retTop = 1;
						}
						break;
					case CLIP_CODE_END:
						i++;
						break;
					case CLIP_CODE_STATEMENT:
						_ins( tmpTop._next, param, String.fromCharCode( CLIP_CODE_TOP ), 1, strToVal );
						retTop = 1;
						break;
					case CLIP_CODE_OPERATOR:
						if( i == 0 ){
							topLevel = _checkOp( tmpTop._token );
							if( ((topLevel == assLevel) && (level == assLevel)) || (topLevel < level) ){
								retTop = 2;
							}
						}
						break;
					}

					if( retTop == 2 ){
						// 後方検索
						i = 0;
						tmpEnd = cur._next;
						while( tmpEnd != null ){
							switch( tmpEnd._code ){
							case CLIP_CODE_TOP:
								i++;
								break;
							case CLIP_CODE_END:
								if( i > 0 ){
									i--;
								} else {
									retEnd = 1;
								}
								break;
							case CLIP_CODE_OPERATOR:
								if( i == 0 ){
									if( (topLevel != assLevel) && ((level == posLevel) || (_checkOp( tmpEnd._token ) <= topLevel)) ){
										retEnd = 2;
									}
								}
								break;
							}

							if( retEnd > 0 ){
								break;
							}
							tmpEnd = tmpEnd._next;
						}

						_ins( tmpTop._next, param, String.fromCharCode( CLIP_CODE_TOP ), 1, strToVal );
						if( retEnd > 0 ){
							_ins( tmpEnd, param, String.fromCharCode( CLIP_CODE_END ), 1, strToVal );
						}
					}

					if( retTop > 0 ){
						break;
					}
					tmpTop = tmpTop._before;
				}
			}
			cur = cur._next;
		}

		return CLIP_NO_ERR;
	}
	int _formatSe( ClipParam param, bool strToVal ){
		int i;
		ClipTokenData? tmpTop;
		ClipTokenData? saveBefore;
		ClipTokenData? saveNext;
		int ret;

		ClipTokenData? cur = _top;
		ClipTokenData? cur2;
		while( cur != null ){
			if( cur._code == CLIP_CODE_ARRAY_TOP ){
				cur._code = CLIP_CODE_TOP;
				tmpTop = cur._next;
			} else if( cur._code == CLIP_CODE_ARRAY_END ){
				cur._code = CLIP_CODE_END;
				if( tmpTop == null ){
					return CLIP_PROC_ERR_SE_OPERAND;
				} else {
					saveBefore = tmpTop._before;
					tmpTop._before = null;
					saveNext = cur._before!._next;
					cur._before!._next = null;
					if( (ret = _format( tmpTop, param, strToVal )) != CLIP_NO_ERR ){
						return ret;
					}
					tmpTop._before = saveBefore;

					// 括弧開きを整える
					i = 0;
					cur2 = tmpTop;
					while( cur2 != null ){
						switch( cur2._code ){
						case CLIP_CODE_TOP:
							i++;
							break;
						case CLIP_CODE_END:
							i--;
							for( ; i < 0; i++ ){
								_ins( tmpTop, param, String.fromCharCode( CLIP_CODE_TOP ), 1, strToVal );
							}
							break;
						}
						cur2 = cur2._next;
					}

					cur._before!._next = saveNext;

					// 括弧閉じを整える
					for( ; i > 0; i-- ){
						_ins( cur, param, String.fromCharCode( CLIP_CODE_END ), 1, strToVal );
					}

					tmpTop = null;
				}
			}
			cur = cur._next;
		}
		if( tmpTop != null ){
			return CLIP_PROC_ERR_SE_OPERAND;
		}

		return CLIP_NO_ERR;
	}
	int format( ClipParam param, bool strToVal ){
		int ret;

		if( _top != null ){
			if( _top!._code == CLIP_CODE_SE ){
				return _formatSe( param, strToVal );
			} else if( _top!._code == CLIP_CODE_STATEMENT ){
				switch( _top!._token ){
				case CLIP_STAT_START:
				case CLIP_STAT_END:
				case CLIP_STAT_END_INC:
				case CLIP_STAT_END_DEC:
				case CLIP_STAT_ENDEQ:
				case CLIP_STAT_ENDEQ_INC:
				case CLIP_STAT_ENDEQ_DEC:
				case CLIP_STAT_CONT:
				case CLIP_STAT_CONTINUE2:
				case CLIP_STAT_BREAK2:
				case CLIP_STAT_RETURN2:
				case CLIP_STAT_RETURN3:
					return _formatSe( param, strToVal );
				case CLIP_STAT_DO:
				case CLIP_STAT_ENDWHILE:
				case CLIP_STAT_NEXT:
				case CLIP_STAT_ENDFUNC:
				case CLIP_STAT_ELSE:
				case CLIP_STAT_ENDIF:
				case CLIP_STAT_DEFAULT:
				case CLIP_STAT_ENDSWI:
				case CLIP_STAT_BREAKSWI:
				case CLIP_STAT_CONTINUE:
				case CLIP_STAT_BREAK:
					if( _top!._next != null ){
						return CLIP_PROC_WARN_DEAD_TOKEN;
					}
					return CLIP_NO_ERR;
				}
			}
		}

		// 演算子の優先順位に従って括弧を付ける
		if( (ret = _format( _top, param, strToVal )) != CLIP_NO_ERR ){
			return ret;
		}

		// 括弧を整える
		int i = 0;
		ClipTokenData? cur = _top;
		while( cur != null ){
			switch( cur._code ){
			case CLIP_CODE_TOP:
				i++;
				break;
			case CLIP_CODE_END:
				i--;
				for( ; i < 0; i++ ){
					_ins( _top, param, String.fromCharCode( CLIP_CODE_TOP ), 1, strToVal );
				}
				break;
			}
			cur = cur._next;
		}
		for( ; i > 0; i-- ){
			add( param, String.fromCharCode( CLIP_CODE_END ), 1, strToVal );
		}

		return CLIP_NO_ERR;
	}

	// トークン・リストを構築する
	int regString( ClipParam param, String line, bool strToVal ){
		int ret;
		if( (ret = separate( param, line, strToVal )) != CLIP_NO_ERR ){
			return ret;
		}
		if( (ret = format( param, strToVal )) != CLIP_NO_ERR ){
			return ret;
		}
		return CLIP_NO_ERR;
	}

	// トークン・リストをコピーする
	int dup( ClipToken dst ){
		ClipTokenData? srcCur;
		ClipTokenData dstCur;
		ClipTokenData tmp;

		// 初期化
		dst._top = null;
		dst._end = null;
		dst._get = null;

		if( _top != null ){
			// 先頭に登録する
			dstCur   = ClipTokenData();
			dst._top = dstCur;

			dstCur._code  = _top!._code;
			dstCur._token = newToken( _top!._code, _top!._token );

			srcCur = _top!._next;

			while( srcCur != null ){
				// 最後尾に追加する
				tmp          = ClipTokenData();
				tmp._before  = dstCur;
				dstCur._next = tmp;
				dstCur       = tmp;

				dstCur._code  = srcCur._code;
				dstCur._token = newToken( srcCur._code, srcCur._token );

				srcCur = srcCur._next;
			}

			dstCur._next = null;
			dst._end     = dstCur;
		}

		return CLIP_NO_ERR;
	}

	// カレント・トークンをロックする
	ClipTokenData? lock(){
		return _get;
	}
	void unlock( ClipTokenData? lock ){
		_get = lock;
	}

	// トークンを確認する
	void beginGetToken( [int? num] ){
		_get = (num == null) ? _top : _searchList( num );
	}
	bool getToken(){
		if( _get == null ){
			return false;
		}

		_get_code  = _get!._code;
		_get_token = _get!._token;

		_get = _get!._next;
		return true;
	}
	bool getTokenParam( ClipParam param ){
		if( _get == null ){
			return false;
		}

		if( _get!._code == CLIP_CODE_LABEL ){
			// 重要：関数、ローカル、グローバルの順にチェックすること！
			if( param.func().search( _get!._token, false, null ) != null ){
				// 関数
				_get_code = _get!._code;
			} else if( param.variable().label().checkLabel( _get!._token ) >= 0 ){
				// ローカル変数
				_get_code = CLIP_CODE_AUTO_VAR;
			} else if( param.array().label().checkLabel( _get!._token ) >= 0 ){
				// ローカル配列
				_get_code = CLIP_CODE_AUTO_ARRAY;
			} else if( globalParam().variable().label().checkLabel( _get!._token ) >= 0 ){
				// グローバル変数
				_get_code = CLIP_CODE_GLOBAL_VAR;
			} else if( globalParam().array().label().checkLabel( _get!._token ) >= 0 ){
				// グローバル配列
				_get_code = CLIP_CODE_GLOBAL_ARRAY;
			} else {
				MathValue value = MathValue();
				if( stringToValue( param, _get!._token, value ) ){
					_get!._code  = CLIP_CODE_CONSTANT;
					_get!._token = value;
				}
				_get_code = _get!._code;
			}
		} else {
			_get_code = _get!._code;
		}
		_get_token = _get!._token;

		_get = _get!._next;
		return true;
	}
	bool getTokenLock(){
		if( _get == null ){
			return false;
		}

		_get_code  = _get!._code;
		_get_token = _get!._token;

		return true;
	}
	bool checkToken( int code ){
		return (_get != null) && (_get!._code != code);
	}
	void skipToken(){
		if( _get != null ){
			_get = _get!._next;
		}
	}
	bool skipComma(){
		if( (_get == null) || (_get!._code != CLIP_CODE_OPERATOR) || (_get!._token != CLIP_OP_COMMA) ){
			return false;
		}
		_get = _get!._next;
		return true;
	}

	// トークン数を確認する
	int count(){
		int ret = 0;
		ClipTokenData? cur = _top;
		while( cur != null ){
			ret++;
			cur = cur._next;
		}
		return ret;
	}

	// トークン文字列を確認する
	String tokenString( ClipParam param, int code, dynamic token ){
		String string = "";
		ParamString real = ParamString();
		ParamString imag = ParamString();
		String tmp = "";
		int cur;

		switch( code ){
		case CLIP_CODE_TOP:
			string = "(";
			break;
		case CLIP_CODE_END:
			string = ")";
			break;
		case CLIP_CODE_ARRAY_TOP:
			string = "{";
			break;
		case CLIP_CODE_ARRAY_END:
			string = "}";
			break;
		case CLIP_CODE_PARAM_ANS:
			string = "&";
			break;
		case CLIP_CODE_PARAM_ARRAY:
			string = "[]";
			break;
		case CLIP_CODE_VARIABLE:
			if( param.variable().label().label(token) != null ){
				string = param.variable().label().label(token)!;
			} else if( token == 0 ){
				string = "@";
			} else {
				string = "@${String.fromCharCode( token )}";
			}
			break;
		case CLIP_CODE_ARRAY:
			if( param.array().label().label(token) != null ){
				string = param.array().label().label(token)!;
			} else {
				string = "@@${String.fromCharCode( token )}";
			}
			break;
		case CLIP_CODE_AUTO_VAR:
		case CLIP_CODE_AUTO_ARRAY:
		case CLIP_CODE_GLOBAL_VAR:
		case CLIP_CODE_GLOBAL_ARRAY:
		case CLIP_CODE_LABEL:
			string = token;
			break;
		case CLIP_CODE_OPERATOR:
			string = _tokenOp[token];
			break;
		case CLIP_CODE_SE:
			string = "\$";
			if( token == CLIP_SE_NULL ){
				break;
			} else if( token - 1 < _tokenSe.length ){
				string += _tokenSe[token - 1];
				break;
			}
			token -= CLIP_SE_FUNC;
			// そのまま下に流す
			continue case_CLIP_CODE_FUNCTION;
		case_CLIP_CODE_FUNCTION:
		case CLIP_CODE_FUNCTION:
			string += _tokenFunc[token];
			break;
		case CLIP_CODE_STATEMENT:
			string = _tokenStat[token];
			break;
		case CLIP_CODE_EXTFUNC:
			string = "!$token";
			break;
		case CLIP_CODE_COMMAND:
			string = ":";
			if( token != CLIP_COMMAND_NULL ){
				string += _tokenCommand[token - 1];
			}
			break;
		case CLIP_CODE_CONSTANT:
			valueToString( param, token, real, imag );
			tmp = real.str() + imag.str();
			cur = 0;
			do {
				switch( charAt( tmp, cur ) ){
				case '-':
				case '+':
					string += '\\';
					break;
				}
				string += charAt( tmp, cur );
				cur++;
			} while( cur < tmp.length );
			break;
		case CLIP_CODE_STRING:
			cur = 0;
			do {
				if( token.charAt( cur ) == ']' ){
					tmp += '\\';
				}
				tmp += token.charAt( cur );
				cur++;
			} while( cur < token.length );
			string = "[\"$tmp]";
			break;
		default:
			string = "";
			break;
		}
		if( charAt( string, 0 ) == '\$' ){
			return string.toUpperCase();
		}
		return string;
	}
}
