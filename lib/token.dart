/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import 'global.dart';
import 'gworld.dart';
import 'math/math.dart';
import 'math/matrix.dart';
import 'math/multiprec.dart';
import 'math/value.dart';
import 'param.dart';
import 'param/integer.dart';
import 'param/string.dart';
import 'proc.dart';

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

// トークン管理クラス
class ClipToken {
	static final List<String> _tokenOp = [
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

	static final List<String> _tokenFunc = [
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

	static final List<String> _tokenStat = [
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

	static final List<String> _tokenCommand = [
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

	static final List<String> _tokenSe = [
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

	static final List<String> _tokenDefine = [
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
	static final List<double> _valueDefine = List.filled( _tokenDefine.length, 0.0 );
	static void setDefineValue(){
		_valueDefine[0] = ClipMath.dblEpsilon;
		_valueDefine[1] = double.maxFinite;
		_valueDefine[2] = ClipMath.randMax.toDouble();
		_valueDefine[3] = 0;
		_valueDefine[4] = 1;
		_valueDefine[5] = ClipGWorld.bgColor().toDouble();
		_valueDefine[6] = DateTime.now().timeZoneOffset.inSeconds.toDouble();
		_valueDefine[7] = double.infinity;
		_valueDefine[8] = double.nan;
	}

	static int _indexOf( List<String> stringArray, String string ){
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
	static int _getCode = 0;
	static dynamic _getToken;
	static int curCode(){
		return _getCode;
	}
	static dynamic curToken(){
		return _getToken;
	}

	// コマンドの追加
	static void addCommand( ClipProc proc, List<String> nameArray, List<int Function( ClipProc, ClipParam, int, dynamic )> funcArray ){
		if( nameArray.length == funcArray.length ){
			_tokenCommand.addAll( nameArray );
			proc.addProcSubCommand( funcArray );
		}
	}
	static String commandName( int token ){
		return _tokenCommand[token - 1];
	}

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
		switch( ClipMath.charAt( string, 0 ) ){
		case '+':
			if( string.length == 1 ){
				op.set( ClipGlobal.opPlus );
				return true;
			}
			if( (string.length == 2) && (ClipMath.charAt( string, 1 ) == '+') ){
				op.set( ClipGlobal.opIncrement );
				return true;
			}
			break;
		case '-':
			if( string.length == 1 ){
				op.set( ClipGlobal.opMinus );
				return true;
			}
			if( (string.length == 2) && (ClipMath.charAt( string, 1 ) == '-') ){
				op.set( ClipGlobal.opDecrement );
				return true;
			}
			break;
		case '~':
			if( string.length == 1 ){
				op.set( ClipGlobal.opComplement );
				return true;
			}
			break;
		case '!':
			if( string.length == 1 ){
				op.set( ClipGlobal.opNot );
				return true;
			}
			if( (string.length == 2) && (ClipMath.charAt( string, 1 ) == '=') ){ // 過去互換用に[!=]表記を残す
				op.set( ClipGlobal.opNotEqual );
				return true;
			}
			break;
		case '<': // 過去互換用に残す
			if( string.length == 1 ){
				op.set( ClipGlobal.opLess );
				return true;
			}
			if( (string.length == 2) && (ClipMath.charAt( string, 1 ) == '=') ){
				op.set( ClipGlobal.opLessOrEq );
				return true;
			}
			break;
		case '>': // 過去互換用に残す
			if( string.length == 1 ){
				op.set( ClipGlobal.opGreat );
				return true;
			}
			if( (string.length == 2) && (ClipMath.charAt( string, 1 ) == '=') ){
				op.set( ClipGlobal.opGreatOrEq );
				return true;
			}
			break;
		case '=': // 過去互換用に残す
			if( (string.length == 2) && (ClipMath.charAt( string, 1 ) == '=') ){
				op.set( ClipGlobal.opEqual );
				return true;
			}
			break;
		case '&': // 過去互換用に残す
			if( (string.length == 2) && (ClipMath.charAt( string, 1 ) == '&') ){
				op.set( ClipGlobal.opLogAnd );
				return true;
			}
			break;
		case '|': // 過去互換用に残す
			if( (string.length == 2) && (ClipMath.charAt( string, 1 ) == '|') ){
				op.set( ClipGlobal.opLogOr );
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
			se.set( ClipGlobal.seFunc + se.val() );
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

		top = ClipGlobal.isCharEscape( string, 0 ) ? 1 : 0;
		switch( ClipMath.charAt( string, top ) ){
		case '+': top++  ; swi = false; break;
		case '-': top++  ; swi = true ; break;
		default : top = 0; swi = false; break;
		}

		if( ClipMath.charAt( string, top ) == '\'' ){
			value.ass( 0.0 );
			j = 0;
			for( i = 1; ; i++ ){
				if( top + i >= string.length ){
					break;
				}
				if( ClipGlobal.isCharEscape( string, top + i ) ){
					i++;
					if( top + i >= string.length ){
						break;
					}
					switch( ClipMath.charAt( string, top + i ) ){
					case 'b': tmp[0] = ClipMath.char( '\b' ).toDouble(); break;
					case 'f': tmp[0] = ClipMath.char( '\f' ).toDouble(); break;
					case 'n': tmp[0] = ClipMath.char( '\n' ).toDouble(); break;
					case 'r': tmp[0] = ClipMath.char( '\r' ).toDouble(); break;
					case 't': tmp[0] = ClipMath.char( '\t' ).toDouble(); break;
					case 'v': tmp[0] = ClipMath.char( '\v' ).toDouble(); break;
					default : tmp[0] = ClipMath.charCodeAt( string, top + i ).toDouble(); break;
					}
				} else {
					tmp[0] = ClipMath.charCodeAt( string, top + i ).toDouble();
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
		} else if( ClipGlobal.isCharEscape( string, top ) ){
			switch( ClipMath.charAt( string, top + 1 ) ){
			case 'b':
			case 'B':
				value.ass( ClipMath.stringToInt( string, top + 2, stop, 2 ) );
				break;
			case '0':
				value.ass( ClipMath.stringToInt( string, top + 2, stop, 8 ) );
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
				value.ass( ClipMath.stringToInt( string, top + 1, stop, 10 ) );
				break;
			case 'x':
			case 'X':
				value.ass( ClipMath.stringToInt( string, top + 2, stop, 16 ) );
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
			if( (param.mode() & ClipGlobal.modeComplex) != 0 ){
				tmp[0] = ClipMath.stringToFloat( string, top, stop );
				switch( ClipMath.charAt( string, stop.val() ) ){
				case '\\':
				case ClipGlobal.charUtf8Yen:
				case '+':
				case '-':
					// 実数部
					if( stop.val() == top ){
						return false;
					}
					value.setReal( swi ? -tmp[0] : tmp[0] );

					// 虚数部
					if( ClipGlobal.isCharEscape( string, stop.val() ) ){
						stop.add( 1 );
					}
					switch( ClipMath.charAt( string, stop.val() ) ){
					case '+': swi = false; break;
					case '-': swi = true ; break;
					default : return false;
					}
					top = stop.val() + 1;
					tmp[0] = ClipMath.stringToFloat( string, top, stop );
					if( (ClipMath.charAt( string, stop.val() ) != 'i') && (ClipMath.charAt( string, stop.val() ) != 'I') ){
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
						switch( ClipMath.charAt( string, stop.val() ) ){
						case 'd': case 'D': value.angToAng( ClipMath.angTypeDeg , ClipMath.complexAngType() ); break;
						case 'g': case 'G': value.angToAng( ClipMath.angTypeGrad, ClipMath.complexAngType() ); break;
						case 'r': case 'R': value.angToAng( ClipMath.angTypeRad , ClipMath.complexAngType() ); break;
						default : return false;
						}
					}
					break;
				}
			} else if( (param.mode() & (ClipGlobal.modeFFloat | ClipGlobal.modeFract)) != 0 ){
				tmp[0] = ClipMath.stringToFloat( string, top, stop );
				switch( ClipMath.charAt( string, stop.val() ) ){
				case '_':
				case ClipGlobal.charFract:
					if( stop.val() == top ){
						return false;
					}
					value.fractSetMinus( swi );
					value.setNum( tmp[0] );

					if( ClipGlobal.isCharEscape( string, stop.val() + 1 ) ){
						top = stop.val() + 2;
					} else {
						top = stop.val() + 1;
					}
					tmp[0] = ClipMath.stringToFloat( string, top, stop );
					switch( ClipMath.charAt( string, stop.val() ) ){
					case '_':
					case ClipGlobal.charFract:
						if( stop.val() == top ){
							return false;
						}

						if( ClipGlobal.isCharEscape( string, stop.val() + 1 ) ){
							top = stop.val() + 2;
						} else {
							top = stop.val() + 1;
						}
						tmp[1] = ClipMath.stringToFloat( string, top, stop );
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
					switch( ClipMath.charAt( string, stop.val() ) ){
					case 'd': case 'D': value.angToAng( ClipMath.angTypeDeg , ClipMath.complexAngType() ); break;
					case 'g': case 'G': value.angToAng( ClipMath.angTypeGrad, ClipMath.complexAngType() ); break;
					case 'r': case 'R': value.angToAng( ClipMath.angTypeRad , ClipMath.complexAngType() ); break;
					default : return false;
					}
				}
			} else if( (param.mode() & ClipGlobal.modeTime) != 0 ){
				bool _break = false;
				for( i = 0; i < 4; i++ ){
					if( ClipGlobal.isCharEscape( string, top ) ){
						top++;
					}
					tmp[i] = ClipMath.stringToFloat( string, top, stop );
					if( stop.val() == top ){
						return false;
					}
					if( stop.val() >= string.length ){
						break;
					}
					switch( ClipMath.charAt( string, stop.val() ) ){
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
						switch( ClipMath.charAt( string, stop.val() ) ){
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
						switch( ClipMath.charAt( string, stop.val() ) ){
						case 'h': case 'H': return false;
						case 'm': case 'M': value.setHour( tmp[0] ); value.setMin  ( tmp[1] ); value.timeReduce(); break;
						case 's': case 'S': value.setMin ( tmp[0] ); value.setSec  ( tmp[1] ); value.timeReduce(); break;
						case 'f': case 'F': value.setSec ( tmp[0] ); value.setFrame( tmp[1] ); value.timeReduce(); break;
						}
					} else {
						switch( param.mode() & ClipGlobal.modeMask ){
						case ClipGlobal.modeHTime:
						case ClipGlobal.modeMTime: value.setHour( tmp[0] ); value.setMin  ( tmp[1] ); value.timeReduce(); break;
						case ClipGlobal.modeSTime: value.setMin ( tmp[0] ); value.setSec  ( tmp[1] ); value.timeReduce(); break;
						case ClipGlobal.modeFTime: value.setSec ( tmp[0] ); value.setFrame( tmp[1] ); value.timeReduce(); break;
						}
					}
					break;
				case 2:
					if( stop.val() < string.length ){
						switch( ClipMath.charAt( string, stop.val() ) ){
						case 'h': case 'H':
						case 'm': case 'M': return false;
						case 's': case 'S': value.setHour( tmp[0] ); value.setMin( tmp[1] ); value.setSec  ( tmp[2] ); value.timeReduce(); break;
						case 'f': case 'F': value.setMin ( tmp[0] ); value.setSec( tmp[1] ); value.setFrame( tmp[2] ); value.timeReduce(); break;
						}
					} else {
						switch( param.mode() & ClipGlobal.modeMask ){
						case ClipGlobal.modeHTime:
						case ClipGlobal.modeMTime:
						case ClipGlobal.modeSTime: value.setHour( tmp[0] ); value.setMin( tmp[1] ); value.setSec  ( tmp[2] ); value.timeReduce(); break;
						case ClipGlobal.modeFTime: value.setMin ( tmp[0] ); value.setSec( tmp[1] ); value.setFrame( tmp[2] ); value.timeReduce(); break;
						}
					}
					break;
				case 3:
					if( stop.val() < string.length ){
						switch( ClipMath.charAt( string, stop.val() ) ){
						case 'h': case 'H':
						case 'm': case 'M':
						case 's': case 'S': return false;
						case 'f': case 'F': value.setHour( tmp[0] ); value.setMin( tmp[1] ); value.setSec( tmp[2] ); value.setFrame( tmp[3] ); value.timeReduce(); break;
						}
					} else {
						switch( param.mode() & ClipGlobal.modeMask ){
						case ClipGlobal.modeHTime:
						case ClipGlobal.modeMTime:
						case ClipGlobal.modeSTime:
						case ClipGlobal.modeFTime: value.setHour( tmp[0] ); value.setMin( tmp[1] ); value.setSec( tmp[2] ); value.setFrame( tmp[3] ); value.timeReduce(); break;
						}
					}
					break;
				}
			} else if( (param.mode() & ClipGlobal.modeInt) != 0 ){
				value.ass( ClipMath.stringToInt( string, top, stop, param.radix() ) );
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
		switch( param.mode() & ClipGlobal.modeMask ){
		case ClipGlobal.modeEFloat:
		case ClipGlobal.modeEComplex:
			str = ClipMath.floatToExponential( value, (prec == 0) ? ClipMath.eprec( value ).toInt() : prec );
			break;
		case ClipGlobal.modeFFloat:
		case ClipGlobal.modeFComplex:
			str = ClipMath.floatToFixed( value, (prec == 0) ? ClipMath.fprec( value ).toInt() : prec );
			break;
		case ClipGlobal.modeGFloat:
		case ClipGlobal.modeGComplex:
			str = ClipMath.floatToString( value, (prec == 0) ? 15 : prec );
			break;
		}
		return str;
	}

	void valueToString( ClipParam param, MathValue value, ParamString real, ParamString imag ){
		switch( param.mode() & ClipGlobal.modeMask ){
		case ClipGlobal.modeEComplex:
		case ClipGlobal.modeFComplex:
		case ClipGlobal.modeGComplex:
			if( ClipMath.isZero( value.imag() ) ){
				real.set( _floatToString( param, value.real() ) );
				imag.set( "" );
			} else if( ClipMath.isZero( value.real() ) ){
				real.set( "" );
				imag.set( "${_floatToString( param, value.imag() )}i" );
			} else {
				real.set( _floatToString( param, value.real() ) );
				imag.set( (value.imag() > 0.0) ? "+" : "" );
				imag.add( "${_floatToString( param, value.imag() )}i" );
			}
			break;
		case ClipGlobal.modeEFloat:
		case ClipGlobal.modeFFloat:
		case ClipGlobal.modeGFloat:
			real.set( _floatToString( param, value.real() ) );
			imag.set( "" );
			break;
		case ClipGlobal.modeMFract:
			if( (value.denom() != 0) && (ClipMath.div( value.num(), value.denom() ) != 0) ){
				if( ClipMath.mod( value.num(), value.denom() ) != 0 ){
					real.set( value.fractMinus() ? "-" : "" );
					real.add( "${ClipMath.div( value.num(), value.denom() ).toInt()}" );
					real.add( ClipGlobal.charFract );
					real.add( "${ClipMath.mod( value.num(), value.denom() ).toInt()}" );
					real.add( ClipGlobal.charFract );
					real.add( "${value.denom().toInt()}" );
				} else {
					real.set( value.fractMinus() ? "-" : "" );
					real.add( "${ClipMath.div( value.num(), value.denom() ).toInt()}" );
				}
				imag.set( "" );
				break;
			}
			// そのまま下に流す
			continue caseClipModeIFract;
		caseClipModeIFract:
		case ClipGlobal.modeIFract:
			if( value.denom() == 0 ){
				real.set( "${value.toFloat()}" );
			} else if( value.denom() == 1 ){
				real.set( value.fractMinus() ? "-" : "" );
				real.add( "${value.num().toInt()}" );
			} else {
				real.set( value.fractMinus() ? "-" : "" );
				real.add( "${value.num().toInt()}" );
				real.add( ClipGlobal.charFract );
				real.add( "${value.denom().toInt()}" );
			}
			imag.set( "" );
			break;
		case ClipGlobal.modeHTime:
			real.set( value.timeMinus() ? "-" : "" );
			real.add( ((value.hour() < 10.0) ? "0" : "") + ClipMath.floatToString( value.hour(), ClipGlobal.defPrec ) );
			imag.set( "" );
			break;
		case ClipGlobal.modeMTime:
			if( ClipMath.toInt( value.hour() ) != 0 ){
				real.set( value.timeMinus() ? "-" : "" );
				real.add( ((value.hour() < 10.0) ? "0" : "") + ClipMath.floatToString( ClipMath.toInt( value.hour() ) ) );
				real.add( ":" );
				real.add( ((value.min () < 10.0) ? "0" : "") + ClipMath.floatToString( value.min(), ClipGlobal.defPrec ) );
			} else {
				real.set( value.timeMinus() ? "-" : "" );
				real.add( ((value.min() < 10.0) ? "0" : "") + ClipMath.floatToString( value.min(), ClipGlobal.defPrec ) );
			}
			imag.set( "" );
			break;
		case ClipGlobal.modeSTime:
			if( ClipMath.toInt( value.hour() ) != 0 ){
				real.set( value.timeMinus() ? "-" : "" );
				real.add( ((value.hour() < 10.0) ? "0" : "") + ClipMath.floatToString( ClipMath.toInt( value.hour() ) ) );
				real.add( ":" );
				real.add( ((value.min () < 10.0) ? "0" : "") + ClipMath.floatToString( ClipMath.toInt( value.min() ) ) );
				real.add( ":" );
				real.add( ((value.sec () < 10.0) ? "0" : "") + ClipMath.floatToString( value.sec(), ClipGlobal.defPrec ) );
			} else if( ClipMath.toInt( value.min() ) != 0 ){
				real.set( value.timeMinus() ? "-" : "" );
				real.add( ((value.min() < 10.0) ? "0" : "") + ClipMath.floatToString( ClipMath.toInt( value.min() ) ) );
				real.add( ":" );
				real.add( ((value.sec() < 10.0) ? "0" : "") + ClipMath.floatToString( value.sec(), ClipGlobal.defPrec ) );
			} else {
				real.set( value.timeMinus() ? "-" : "" );
				real.add( ((value.sec() < 10.0) ? "0" : "") + ClipMath.floatToString( value.sec(), ClipGlobal.defPrec ) );
			}
			imag.set( "" );
			break;
		case ClipGlobal.modeFTime:
			if( ClipMath.toInt( value.hour() ) != 0 ){
				real.set( value.timeMinus() ? "-" : "" );
				real.add( ((value.hour () < 10.0) ? "0" : "") + ClipMath.floatToString( ClipMath.toInt( value.hour() ) ) );
				real.add( ":" );
				real.add( ((value.min  () < 10.0) ? "0" : "") + ClipMath.floatToString( ClipMath.toInt( value.min() ) ) );
				real.add( ":" );
				real.add( ((value.sec  () < 10.0) ? "0" : "") + ClipMath.floatToString( ClipMath.toInt( value.sec() ) ) );
				real.add( ":" );
				real.add( ((value.frame() < 10.0) ? "0" : "") + ClipMath.floatToString( value.frame(), ClipGlobal.defPrec ) );
			} else if( ClipMath.toInt( value.min() ) != 0 ){
				real.set( value.timeMinus() ? "-" : "" );
				real.add( ((value.min  () < 10.0) ? "0" : "") + ClipMath.floatToString( ClipMath.toInt( value.min() ) ) );
				real.add( ":" );
				real.add( ((value.sec  () < 10.0) ? "0" : "") + ClipMath.floatToString( ClipMath.toInt( value.sec() ) ) );
				real.add( ":" );
				real.add( ((value.frame() < 10.0) ? "0" : "") + ClipMath.floatToString( value.frame(), ClipGlobal.defPrec ) );
			} else if( ClipMath.toInt( value.sec() ) != 0 ){
				real.set( value.timeMinus() ? "-" : "" );
				real.add( ((value.sec  () < 10.0) ? "0" : "") + ClipMath.floatToString( ClipMath.toInt( value.sec() ) ) );
				real.add( ":" );
				real.add( ((value.frame() < 10.0) ? "0" : "") + ClipMath.floatToString( value.frame(), ClipGlobal.defPrec ) );
			} else {
				real.set( value.timeMinus() ? "-" : "" );
				real.add( ((value.frame() < 10.0) ? "0" : "") + ClipMath.floatToString( value.frame(), ClipGlobal.defPrec ) );
			}
			imag.set( "" );
			break;
		case ClipGlobal.modeSChar:
			real.set( ClipMath.intToString( ClipMath.signed( value.toFloat(), ClipMath.umax8, ClipMath.smin8, ClipMath.smax8 ), param.radix() ) );
			imag.set( "" );
			break;
		case ClipGlobal.modeUChar:
			real.set( ClipMath.intToString( ClipMath.unsigned( value.toFloat(), ClipMath.umax8 ), param.radix() ) );
			imag.set( "" );
			break;
		case ClipGlobal.modeSShort:
			real.set( ClipMath.intToString( ClipMath.signed( value.toFloat(), ClipMath.umax16, ClipMath.smin16, ClipMath.smax16 ), param.radix() ) );
			imag.set( "" );
			break;
		case ClipGlobal.modeUShort:
			real.set( ClipMath.intToString( ClipMath.unsigned( value.toFloat(), ClipMath.umax16 ), param.radix() ) );
			imag.set( "" );
			break;
		case ClipGlobal.modeSLong:
			real.set( ClipMath.intToString( ClipMath.signed( value.toFloat(), ClipMath.umax32, ClipMath.smin32, ClipMath.smax32 ), param.radix() ) );
			imag.set( "" );
			break;
		case ClipGlobal.modeULong:
			real.set( ClipMath.intToString( ClipMath.unsigned( value.toFloat(), ClipMath.umax32 ), param.radix() ) );
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
				switch( ClipMath.charAt( src, top ) ){
				case '+':
				case '-':
				case '.':
				case 'e':
				case 'E':
				case 'i':
				case 'I':
				case '_':
				case ClipGlobal.charFract:
				case ':':
					if( ClipMath.charAt( src, top ) == '.' ){
						_float = true;
					}
					dst += ClipMath.charAt( src, top );
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
				switch( ClipMath.charAt( src, end ) ){
				case '+':
				case '-':
				case '.':
				case 'e':
				case 'E':
				case 'i':
				case 'I':
				case '_':
				case ClipGlobal.charFract:
				case ':':
					_break = true;
					break;
				}
				if( _break ){
					break;
				}
			}

			for( len = end - top; len > 0; len-- ){
				dst += ClipMath.charAt( src, top );
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
		case ClipGlobal.codeTop:
		case ClipGlobal.codeEnd:
		case ClipGlobal.codeArrayTop:
		case ClipGlobal.codeArrayEnd:
		case ClipGlobal.codeParamAns:
		case ClipGlobal.codeParamArray:
			return null;
		case ClipGlobal.codeConstant:
			return MathValue.dup( token );
		case ClipGlobal.codeMatrix:
			return MathMatrix.dup( token );
		case ClipGlobal.codeMultiPrec:
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
			case ClipGlobal.codeConstant:
				MathValue.deleteValue( token );
				break;
			case ClipGlobal.codeMatrix:
				MathMatrix.deleteMatrix( token );
				break;
			}
		}
	}

	// トークン文字列を確保する
	void _newToken( ClipTokenData cur, ClipParam param, String token, int len, bool strToVal ){
		int i;
		String tmp;
		ParamInteger code = ParamInteger();

		switch( ClipMath.charCodeAt( token, 0 ) ){
		case ClipGlobal.codeTop:
		case ClipGlobal.codeEnd:
		case ClipGlobal.codeArrayTop:
		case ClipGlobal.codeArrayEnd:
		case ClipGlobal.codeParamArray:
			cur._code  = ClipMath.charCodeAt( token, 0 );
			cur._token = null;
			break;
		case ClipGlobal.codeOperator:
			cur._code  = ClipMath.charCodeAt( token, 0 );
			cur._token = ClipMath.charCodeAt( token, 1 );
			break;
		default:
			if( ClipMath.charAt( token, 0 ) == '@' ){
				if( len == 1 ){
					cur._code  = ClipGlobal.codeArray;
					cur._token = 0;
				} else if( (len > 2) && (ClipMath.charAt( token, 1 ) == '@') ){
					cur._code  = ClipGlobal.codeArray;
					cur._token = ClipMath.charCodeAt( token, 2 );
				} else {
					cur._code  = ClipGlobal.codeVariable;
					cur._token = ClipMath.charCodeAt( token, 1 );
				}
				break;
			}

			if( ClipMath.charAt( token, 0 ) == '&' ){
				if( len == 1 ){
					cur._code  = ClipGlobal.codeParamAns;
					cur._token = null;
					break;
				}
				// そのまま下に流す
			}

			tmp = token.substring( 0, len );

			if( ClipMath.charAt( tmp, 0 ) == '\$' ){
				if( checkSe( tmp.substring( 1, len ).toLowerCase(), code ) ){
					switch( code.val() ){
					case ClipGlobal.seLoopStart:
						cur._code  = ClipGlobal.codeStatement;
						cur._token = ClipGlobal.statStart;
						break;
					case ClipGlobal.seLoopEnd:
						cur._code  = ClipGlobal.codeStatement;
						cur._token = ClipGlobal.statEnd;
						break;
					case ClipGlobal.seLoopEndInc:
						cur._code  = ClipGlobal.codeStatement;
						cur._token = ClipGlobal.statEndInc;
						break;
					case ClipGlobal.seLoopEndDec:
						cur._code  = ClipGlobal.codeStatement;
						cur._token = ClipGlobal.statEndDec;
						break;
					case ClipGlobal.seLoopEndEq:
						cur._code  = ClipGlobal.codeStatement;
						cur._token = ClipGlobal.statEndEq;
						break;
					case ClipGlobal.seLoopEndEqInc:
						cur._code  = ClipGlobal.codeStatement;
						cur._token = ClipGlobal.statEndEqInc;
						break;
					case ClipGlobal.seLoopEndEqDec:
						cur._code  = ClipGlobal.codeStatement;
						cur._token = ClipGlobal.statEndEqDec;
						break;
					case ClipGlobal.seLoopCont:
						cur._code  = ClipGlobal.codeStatement;
						cur._token = ClipGlobal.statCont;
						break;
					case ClipGlobal.seContinue:
						cur._code  = ClipGlobal.codeStatement;
						cur._token = ClipGlobal.statContinue2;
						break;
					case ClipGlobal.seBreak:
						cur._code  = ClipGlobal.codeStatement;
						cur._token = ClipGlobal.statBreak2;
						break;
					case ClipGlobal.seReturn:
						cur._code  = ClipGlobal.codeStatement;
						cur._token = ClipGlobal.statReturn2;
						break;
					case ClipGlobal.seReturnAns:
						cur._code  = ClipGlobal.codeStatement;
						cur._token = ClipGlobal.statReturn3;
						break;
					default:
						cur._code  = ClipGlobal.codeSe;
						cur._token = code.val();
						break;
					}
				} else {
					cur._code  = ClipGlobal.codeSe;
					cur._token = ClipGlobal.seNull;
				}
			} else if( checkSqOp( tmp, code ) ){
				cur._code  = ClipGlobal.codeOperator;
				cur._token = code.val();
			} else if( ClipMath.charAt( tmp, 0 ) == ':' ){
				cur._code = ClipGlobal.codeCommand;
				if( checkCommand( tmp.substring( 1, len ), code ) ){
					cur._token = code.val();
				} else {
					cur._token = ClipGlobal.commandNull;
				}
			} else if( ClipMath.charAt( tmp, 0 ) == '!' ){
				cur._code  = ClipGlobal.codeExtFunc;
				cur._token = tmp.substring( 1, len );
			} else if( ClipMath.charAt( tmp, 0 ) == '"' ){
				cur._code  = ClipGlobal.codeString;
				cur._token = "";
				for( i = 1; ; i++ ){
					if( i >= tmp.length ){
						break;
					}
					if( ClipGlobal.isCharEscape( tmp, i ) ){
						i++;
						if( i >= tmp.length ){
							break;
						}
						switch( ClipMath.charAt( tmp, i ) ){
						case 'b': cur._token += '\b'; break;
						case 'f': cur._token += '\f'; break;
						case 'n': cur._token += '\n'; break;
						case 'r': cur._token += '\r'; break;
						case 't': cur._token += '\t'; break;
						case 'v': cur._token += '\v'; break;
						default : cur._token += ClipMath.charAt( tmp, i ); break;
						}
					} else {
						cur._token += ClipMath.charAt( tmp, i );
					}
				}
			} else if( checkFunc( tmp, code ) ){
				cur._code  = ClipGlobal.codeFunction;
				cur._token = code.val();
			} else if( checkStat( tmp, code ) ){
				cur._code  = ClipGlobal.codeStatement;
				cur._token = code.val();
			} else {
				cur._token = MathValue();
				if( checkDefine( tmp, cur._token ) ){
					cur._code = ClipGlobal.codeConstant;
				} else if( strToVal && stringToValue( param, tmp, cur._token ) ){
					cur._code = ClipGlobal.codeConstant;
				} else {
					cur._code  = ClipGlobal.codeLabel;
					cur._token = tmp;
				}
			}

			break;
		}
	}
	void _newTokenValue( ClipTokenData cur, MathValue value ){
		cur._code  = ClipGlobal.codeConstant;
		cur._token = MathValue.dup( value );
	}
	void _newTokenMatrix( ClipTokenData cur, MathMatrix value ){
		cur._code  = ClipGlobal.codeMatrix;
		cur._token = MathMatrix.dup( value );
	}
	void _newTokenMultiPrec( ClipTokenData cur, MPData value ){
		cur._code  = ClipGlobal.codeMultiPrec;
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
		if( (ClipMath.charAt( token, 0 ) != '"') && (ClipMath.charAt( token, len - 1 ) == '!') ){
			if( len == 1 ){
				token = String.fromCharCode( ClipGlobal.codeOperator ) + String.fromCharCode( ClipGlobal.opFact );
			} else if( ClipMath.charAt( token, len - 2 ) != '@' ){
				addFact = true;
				token = token.substring( 0, len - 1 );
			}
		}
		_newToken( _addToken(), param, token, len, strToVal );
		if( addFact ){
			token = String.fromCharCode( ClipGlobal.codeOperator ) + String.fromCharCode( ClipGlobal.opFact );
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
			return ClipGlobal.errToken;
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

		return ClipGlobal.noErr;
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
			if( ClipGlobal.isCharEscape( line, cur ) ){
				switch( ClipMath.charAt( line, cur + 1 ) ){
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
				case ClipGlobal.charUtf8Yen:
					if( len == 0 ) token = "";
					token += ClipMath.charAt( line, cur );
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
				token += ClipMath.charAt( line, cur );
				len++;
			} else if( (ClipMath.charAt( line, cur ) == '[') && !strFlag ){
				if( len > 0 ){
					add( param, token, len, strToVal );
					len = 0;
				}
				strFlag = true;
			} else if( (ClipMath.charAt( line, cur ) == ']') && strFlag ){
				if( len == 0 ){
					token = String.fromCharCode( ClipGlobal.codeParamArray );
					add( param, token, 1, strToVal );
				} else {
					addSq( param, token, len, strToVal );
					len = 0;
				}
				strFlag = false;
			} else if( strFlag ){
				if( len == 0 ) token = "";
				token += ClipMath.charAt( line, cur );
				len++;
			} else {
				String curChar = ClipMath.charAt( line, cur );
				if( ClipMath.charCodeAt( line, cur ) == ClipGlobal.charCodeSpace ){
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
						token = String.fromCharCode( ClipGlobal.codeTop );
						if( !formatSeFlag ){
							if( topCount >= 0 ){
								topCount++;
							}
						}
						break;
					case ')':
						token = String.fromCharCode( ClipGlobal.codeEnd );
						if( !formatSeFlag ){
							topCount--;
						}
						break;
					case '{':
						token = String.fromCharCode( ClipGlobal.codeArrayTop );
						formatSeFlag = true;
						break;
					case '}':
						token = String.fromCharCode( ClipGlobal.codeArrayEnd );
						formatSeFlag = false;
						break;
					}
					add( param, token, 1, strToVal );
					break;
				case ':':
					if( len == 0 ) token = "";
					token += curChar;
					len++;
					if( ClipMath.charAt( token, 0 ) == '@' ){
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
					token = String.fromCharCode( ClipGlobal.codeOperator );
					switch( curChar ){
					case '?': token += String.fromCharCode( ClipGlobal.opConditional ); break;
					case ',': token += String.fromCharCode( ClipGlobal.opComma       ); break;
					case '=':
						if( ClipMath.charAt( line, cur + 1 ) == '=' ){
							token += String.fromCharCode( ClipGlobal.opEqual );
							cur++;
						} else {
							token += String.fromCharCode( ClipGlobal.opAss );
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
					token = String.fromCharCode( ClipGlobal.codeOperator );
					switch( ClipMath.charAt( line, cur + 1 ) ){
					case '&': token += String.fromCharCode( ClipGlobal.opLogAnd    ); cur++; break;
					case '=': token += String.fromCharCode( ClipGlobal.opAndAndAss ); cur++; break;
					default : token += String.fromCharCode( ClipGlobal.opAnd       );        break;
					}
					add( param, token, 2, strToVal );
					break;
				case '|':
					if( len > 0 ){
						add( param, token, len, strToVal );
						len = 0;
					}
					token = String.fromCharCode( ClipGlobal.codeOperator );
					switch( ClipMath.charAt( line, cur + 1 ) ){
					case '|': token += String.fromCharCode( ClipGlobal.opLogOr    ); cur++; break;
					case '=': token += String.fromCharCode( ClipGlobal.opOrAndAss ); cur++; break;
					default : token += String.fromCharCode( ClipGlobal.opOr       );        break;
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
					token = String.fromCharCode( ClipGlobal.codeOperator );
					if( ClipMath.charAt( line, cur + 1 ) == '=' ){
						switch( curChar ){
						case '*': token += String.fromCharCode( ClipGlobal.opMulAndAss ); break;
						case '/': token += String.fromCharCode( ClipGlobal.opDivAndAss ); break;
						case '%': token += String.fromCharCode( ClipGlobal.opModAndAss ); break;
						case '^':
							if( param.enableOpPow() && ((param.mode() & ClipGlobal.modeInt) == 0) ){
								token += String.fromCharCode( ClipGlobal.opPowAndAss );
							} else {
								token += String.fromCharCode( ClipGlobal.opXorAndAss );
							}
							break;
						}
						cur++;
					} else {
						switch( curChar ){
						case '*':
							if( ClipMath.charAt( line, cur + 1 ) == '*' ){
								if( ClipMath.charAt( line, cur + 2 ) == '=' ){
									token += String.fromCharCode( ClipGlobal.opPowAndAss );
									cur += 2;
								} else {
									token += String.fromCharCode( ClipGlobal.opPow );
									cur++;
								}
							} else {
								token += String.fromCharCode( ClipGlobal.opMul );
							}
							break;
						case '/': token += String.fromCharCode( ClipGlobal.opDiv ); break;
						case '%': token += String.fromCharCode( ClipGlobal.opMod ); break;
						case '^':
							if( param.enableOpPow() && ((param.mode() & ClipGlobal.modeInt) == 0) ){
								token += String.fromCharCode( ClipGlobal.opPow );
							} else {
								token += String.fromCharCode( ClipGlobal.opXor );
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
					token = String.fromCharCode( ClipGlobal.codeOperator );
					switch( ClipMath.charAt( line, cur + 1 ) ){
					case '=': token += String.fromCharCode( ClipGlobal.opAddAndAss  ); cur++; break;
					case '+': token += String.fromCharCode( ClipGlobal.opPostfixInc ); cur++; break;
					default : token += String.fromCharCode( ClipGlobal.opAdd        );        break;
					}
					add( param, token, 2, strToVal );
					break;
				case '-':
					if( len > 0 ){
						add( param, token, len, strToVal );
						len = 0;
					}
					token = String.fromCharCode( ClipGlobal.codeOperator );
					switch( ClipMath.charAt( line, cur + 1 ) ){
					case '=': token += String.fromCharCode( ClipGlobal.opSubAndAss  ); cur++; break;
					case '-': token += String.fromCharCode( ClipGlobal.opPostfixDec ); cur++; break;
					default : token += String.fromCharCode( ClipGlobal.opSub        );        break;
					}
					add( param, token, 2, strToVal );
					break;
				case '<':
				case '>':
					if( len > 0 ){
						add( param, token, len, strToVal );
						len = 0;
					}
					token = String.fromCharCode( ClipGlobal.codeOperator );
					if( ClipMath.charAt( line, cur + 1 ) == curChar ){
						if( ClipMath.charAt( line, cur + 2 ) == '=' ){
							switch( curChar ){
							case '<': token += String.fromCharCode( ClipGlobal.opShiftLAndAss ); break;
							case '>': token += String.fromCharCode( ClipGlobal.opShiftRAndAss ); break;
							}
							cur += 2;
						} else {
							switch( curChar ){
							case '<': token += String.fromCharCode( ClipGlobal.opShiftL ); break;
							case '>': token += String.fromCharCode( ClipGlobal.opShiftR ); break;
							}
							cur++;
						}
					} else {
						if( ClipMath.charAt( line, cur + 1 ) == '=' ){
							switch( curChar ){
							case '<': token += String.fromCharCode( ClipGlobal.opLessOrEq  ); break;
							case '>': token += String.fromCharCode( ClipGlobal.opGreatOrEq ); break;
							}
							cur++;
						} else {
							switch( curChar ){
							case '<': token += String.fromCharCode( ClipGlobal.opLess  ); break;
							case '>': token += String.fromCharCode( ClipGlobal.opGreat ); break;
							}
						}
					}
					add( param, token, 2, strToVal );
					break;
				case '!':
					if( ClipMath.charAt( line, cur + 1 ) == '=' ){
						if( len > 0 ){
							add( param, token, len, strToVal );
							len = 0;
						}
						token = String.fromCharCode( ClipGlobal.codeOperator ) + String.fromCharCode( ClipGlobal.opNotEqual );
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
					if( ((param.mode() & ClipGlobal.modeInt) == 0) && (len > 0) ){
						if( (ClipMath.charAt( line, cur + 1 ) == '+') || (ClipMath.charAt( line, cur + 1 ) == '-') ){
							bool _break = false;
							for( int i = 0; i < len; i++ ){
								switch( ClipMath.charAt( token, i ) ){
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
								token += ClipMath.charAt( line, cur );
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
			if( _top!._code == ClipGlobal.codeSe ){
				if( topCount != 0 ){
					return ClipGlobal.procErrSeOperand;
				}
			}
		}

		return ClipGlobal.noErr;
	}

	// トークンを整える
	int _checkOp( int op ){
		switch( op ){
		case ClipGlobal.opPostfixInc:
		case ClipGlobal.opPostfixDec:
		case ClipGlobal.opFact:
			return 15;
		case ClipGlobal.opIncrement:
		case ClipGlobal.opDecrement:
		case ClipGlobal.opComplement:
		case ClipGlobal.opNot:
		case ClipGlobal.opMinus:
		case ClipGlobal.opPlus:
		case ClipGlobal.opPow:
			return 14;
		case ClipGlobal.opMul:
		case ClipGlobal.opDiv:
		case ClipGlobal.opMod:
			return 13;
		case ClipGlobal.opAdd:
		case ClipGlobal.opSub:
			return 12;
		case ClipGlobal.opShiftL:
		case ClipGlobal.opShiftR:
			return 11;
		case ClipGlobal.opLess:
		case ClipGlobal.opLessOrEq:
		case ClipGlobal.opGreat:
		case ClipGlobal.opGreatOrEq:
			return 10;
		case ClipGlobal.opEqual:
		case ClipGlobal.opNotEqual:
			return 9;
		case ClipGlobal.opAnd:
			return 8;
		case ClipGlobal.opXor:
			return 7;
		case ClipGlobal.opOr:
			return 6;
		case ClipGlobal.opLogAnd:
			return 5;
		case ClipGlobal.opLogOr:
			return 4;
		case ClipGlobal.opConditional:
			return 3;
		case ClipGlobal.opAss:
		case ClipGlobal.opMulAndAss:
		case ClipGlobal.opDivAndAss:
		case ClipGlobal.opModAndAss:
		case ClipGlobal.opAddAndAss:
		case ClipGlobal.opSubAndAss:
		case ClipGlobal.opShiftLAndAss:
		case ClipGlobal.opShiftRAndAss:
		case ClipGlobal.opAndAndAss:
		case ClipGlobal.opOrAndAss:
		case ClipGlobal.opXorAndAss:
		case ClipGlobal.opPowAndAss:
			return 2;
		case ClipGlobal.opComma:
			return 1;
		}
		return 0;
	}
	int _format( ClipTokenData? top, ClipParam param, bool strToVal ){
		int level, topLevel = 0;
		int assLevel = _checkOp( ClipGlobal.opAss );
		int posLevel = _checkOp( ClipGlobal.opPostfixInc );
		int retTop, retEnd;
		ClipTokenData? tmpTop;
		ClipTokenData? tmpEnd;

		// 演算子の優先順位に従って括弧を付ける
		int i;
		ClipTokenData? cur = top;
		while( cur != null ){
			if( cur._code == ClipGlobal.codeOperator ){
				// 自分自身の演算子の優先レベルを調べておく
				level = _checkOp( cur._token );

				retTop = 0;
				retEnd = 0;

				// 前方検索
				i = 0;
				tmpTop = cur._before;
				while( tmpTop != null ){
					switch( tmpTop._code ){
					case ClipGlobal.codeTop:
						if( i > 0 ){
							i--;
						} else {
							retTop = 1;
						}
						break;
					case ClipGlobal.codeEnd:
						i++;
						break;
					case ClipGlobal.codeStatement:
						_ins( tmpTop._next, param, String.fromCharCode( ClipGlobal.codeTop ), 1, strToVal );
						retTop = 1;
						break;
					case ClipGlobal.codeOperator:
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
							case ClipGlobal.codeTop:
								i++;
								break;
							case ClipGlobal.codeEnd:
								if( i > 0 ){
									i--;
								} else {
									retEnd = 1;
								}
								break;
							case ClipGlobal.codeOperator:
								if( tmpEnd._token == ClipGlobal.opComma ){
									if( i > 0 ){
										i--;
									} else {
										retEnd = 1;
									}
								} else if( i == 0 ){
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

						_ins( tmpTop._next, param, String.fromCharCode( ClipGlobal.codeTop ), 1, strToVal );
						if( retEnd > 0 ){
							_ins( tmpEnd, param, String.fromCharCode( ClipGlobal.codeEnd ), 1, strToVal );
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

		return ClipGlobal.noErr;
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
			if( cur._code == ClipGlobal.codeArrayTop ){
				cur._code = ClipGlobal.codeTop;
				tmpTop = cur._next;
			} else if( cur._code == ClipGlobal.codeArrayEnd ){
				cur._code = ClipGlobal.codeEnd;
				if( tmpTop == null ){
					return ClipGlobal.procErrSeOperand;
				} else {
					saveBefore = tmpTop._before;
					tmpTop._before = null;
					saveNext = cur._before!._next;
					cur._before!._next = null;
					if( (ret = _format( tmpTop, param, strToVal )) != ClipGlobal.noErr ){
						return ret;
					}
					tmpTop._before = saveBefore;

					// 括弧開きを整える
					i = 0;
					cur2 = tmpTop;
					while( cur2 != null ){
						switch( cur2._code ){
						case ClipGlobal.codeTop:
							i++;
							break;
						case ClipGlobal.codeEnd:
							i--;
							for( ; i < 0; i++ ){
								_ins( tmpTop, param, String.fromCharCode( ClipGlobal.codeTop ), 1, strToVal );
							}
							break;
						}
						cur2 = cur2._next;
					}

					cur._before!._next = saveNext;

					// 括弧閉じを整える
					for( ; i > 0; i-- ){
						_ins( cur, param, String.fromCharCode( ClipGlobal.codeEnd ), 1, strToVal );
					}

					tmpTop = null;
				}
			}
			cur = cur._next;
		}
		if( tmpTop != null ){
			return ClipGlobal.procErrSeOperand;
		}

		return ClipGlobal.noErr;
	}
	int format( ClipParam param, bool strToVal ){
		int ret;

		if( _top != null ){
			if( _top!._code == ClipGlobal.codeSe ){
				return _formatSe( param, strToVal );
			} else if( _top!._code == ClipGlobal.codeStatement ){
				switch( _top!._token ){
				case ClipGlobal.statStart:
				case ClipGlobal.statEnd:
				case ClipGlobal.statEndInc:
				case ClipGlobal.statEndDec:
				case ClipGlobal.statEndEq:
				case ClipGlobal.statEndEqInc:
				case ClipGlobal.statEndEqDec:
				case ClipGlobal.statCont:
				case ClipGlobal.statContinue2:
				case ClipGlobal.statBreak2:
				case ClipGlobal.statReturn2:
				case ClipGlobal.statReturn3:
					return _formatSe( param, strToVal );
				case ClipGlobal.statDo:
				case ClipGlobal.statEndWhile:
				case ClipGlobal.statNext:
				case ClipGlobal.statEndFunc:
				case ClipGlobal.statElse:
				case ClipGlobal.statEndIf:
				case ClipGlobal.statDefault:
				case ClipGlobal.statEndSwi:
				case ClipGlobal.statBreakSwi:
				case ClipGlobal.statContinue:
				case ClipGlobal.statBreak:
					if( _top!._next != null ){
						return ClipGlobal.procWarnDeadToken;
					}
					return ClipGlobal.noErr;
				}
			}
		}

		// 演算子の優先順位に従って括弧を付ける
		if( (ret = _format( _top, param, strToVal )) != ClipGlobal.noErr ){
			return ret;
		}

		// 括弧を整える
		int i = 0;
		ClipTokenData? cur = _top;
		while( cur != null ){
			switch( cur._code ){
			case ClipGlobal.codeTop:
				i++;
				break;
			case ClipGlobal.codeEnd:
				i--;
				for( ; i < 0; i++ ){
					_ins( _top, param, String.fromCharCode( ClipGlobal.codeTop ), 1, strToVal );
				}
				break;
			}
			cur = cur._next;
		}
		for( ; i > 0; i-- ){
			add( param, String.fromCharCode( ClipGlobal.codeEnd ), 1, strToVal );
		}

		return ClipGlobal.noErr;
	}

	// トークン・リストを構築する
	int regString( ClipParam param, String line, bool strToVal ){
		int ret;
		if( (ret = separate( param, line, strToVal )) != ClipGlobal.noErr ){
			return ret;
		}
		if( (ret = format( param, strToVal )) != ClipGlobal.noErr ){
			return ret;
		}
		return ClipGlobal.noErr;
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

		return ClipGlobal.noErr;
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

		_getCode  = _get!._code;
		_getToken = _get!._token;

		_get = _get!._next;
		return true;
	}
	bool getTokenParam( ClipParam param ){
		if( _get == null ){
			return false;
		}

		if( _get!._code == ClipGlobal.codeLabel ){
			// 重要：関数、ローカル、グローバルの順にチェックすること！
			if( param.func().search( _get!._token, false, null ) != null ){
				// 関数
				_getCode = _get!._code;
			} else if( param.variable().label().checkLabel( _get!._token ) >= 0 ){
				// ローカル変数
				_getCode = ClipGlobal.codeAutoVar;
			} else if( param.array().label().checkLabel( _get!._token ) >= 0 ){
				// ローカル配列
				_getCode = ClipGlobal.codeAutoArray;
			} else if( ClipProc.globalParam().variable().label().checkLabel( _get!._token ) >= 0 ){
				// グローバル変数
				_getCode = ClipGlobal.codeGlobalVar;
			} else if( ClipProc.globalParam().array().label().checkLabel( _get!._token ) >= 0 ){
				// グローバル配列
				_getCode = ClipGlobal.codeGlobalArray;
			} else {
				MathValue value = MathValue();
				if( stringToValue( param, _get!._token, value ) ){
					_get!._code  = ClipGlobal.codeConstant;
					_get!._token = value;
				}
				_getCode = _get!._code;
			}
		} else {
			_getCode = _get!._code;
		}
		_getToken = _get!._token;

		_get = _get!._next;
		return true;
	}
	bool getTokenLock(){
		if( _get == null ){
			return false;
		}

		_getCode  = _get!._code;
		_getToken = _get!._token;

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
		if( (_get == null) || (_get!._code != ClipGlobal.codeOperator) || (_get!._token != ClipGlobal.opComma) ){
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
		case ClipGlobal.codeTop:
			string = "(";
			break;
		case ClipGlobal.codeEnd:
			string = ")";
			break;
		case ClipGlobal.codeArrayTop:
			string = "{";
			break;
		case ClipGlobal.codeArrayEnd:
			string = "}";
			break;
		case ClipGlobal.codeParamAns:
			string = "&";
			break;
		case ClipGlobal.codeParamArray:
			string = "[]";
			break;
		case ClipGlobal.codeVariable:
			if( param.variable().label().label(token) != null ){
				string = param.variable().label().label(token)!;
			} else if( token == 0 ){
				string = "@";
			} else {
				string = "@${String.fromCharCode( token )}";
			}
			break;
		case ClipGlobal.codeArray:
			if( param.array().label().label(token) != null ){
				string = param.array().label().label(token)!;
			} else {
				string = "@@${String.fromCharCode( token )}";
			}
			break;
		case ClipGlobal.codeAutoVar:
		case ClipGlobal.codeAutoArray:
		case ClipGlobal.codeGlobalVar:
		case ClipGlobal.codeGlobalArray:
		case ClipGlobal.codeLabel:
			string = token;
			break;
		case ClipGlobal.codeOperator:
			string = _tokenOp[token];
			break;
		case ClipGlobal.codeSe:
			string = "\$";
			if( token == ClipGlobal.seNull ){
				break;
			} else if( token - 1 < _tokenSe.length ){
				string += _tokenSe[token - 1];
				break;
			}
			token -= ClipGlobal.seFunc;
			// そのまま下に流す
			continue caseClipGlobalCodeFunction;
		caseClipGlobalCodeFunction:
		case ClipGlobal.codeFunction:
			string += _tokenFunc[token];
			break;
		case ClipGlobal.codeStatement:
			string = _tokenStat[token];
			break;
		case ClipGlobal.codeExtFunc:
			string = "!$token";
			break;
		case ClipGlobal.codeCommand:
			string = ":";
			if( token != ClipGlobal.commandNull ){
				string += _tokenCommand[token - 1];
			}
			break;
		case ClipGlobal.codeConstant:
			valueToString( param, token, real, imag );
			tmp = real.str() + imag.str();
			cur = 0;
			do {
				switch( ClipMath.charAt( tmp, cur ) ){
				case '-':
				case '+':
					string += '\\';
					break;
				}
				string += ClipMath.charAt( tmp, cur );
				cur++;
			} while( cur < tmp.length );
			break;
		case ClipGlobal.codeString:
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
		if( ClipMath.charAt( string, 0 ) == '\$' ){
			return string.toUpperCase();
		}
		return string;
	}
}
