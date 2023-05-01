/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import 'array.dart';
import 'func.dart';
import 'global.dart';
import 'graph.dart';
import 'gworld.dart';
import 'line.dart';
import 'loop.dart';
import 'math/complex.dart';
import 'math/math.dart';
import 'math/math_env.dart';
import 'math/matrix.dart';
import 'math/multiprec.dart';
import 'math/value.dart';
import 'param.dart';
import 'param/boolean.dart';
import 'param/float.dart';
import 'param/integer.dart';
import 'param/string.dart';
import 'system/tm.dart';
import 'token.dart';

List<double> CLIP_MIN_VALUE = [ MATH_SMIN_8, 0              , MATH_SMIN_16, 0               , MATH_SMIN_32, 0                ];
List<double> CLIP_MAX_VALUE = [ MATH_SMAX_8, MATH_UMAX_8 - 1, MATH_SMAX_16, MATH_UMAX_16 - 1, MATH_SMAX_32, MATH_UMAX_32 - 1 ];

late ClipProcEnv _proc_env;
class ClipProcEnv {
	late ClipGraph _proc_graph; // グラフ描画サポート
	late ClipGWorld _proc_gworld; // グラフィック描画サポート
	late ClipFunc _proc_func; // 外部関数キャッシュ
	late ClipParam? _global_param; // グローバル計算パラメータ
	late bool _proc_warn_flow; // オーバーフロー／アンダーフローの警告を発生させるかどうか
	late bool _proc_trace; // トレース表示するかどうか
	late int _proc_loop_max; // ループ回数
	late int _proc_loop_count;
	late int _proc_loop_count_max;
	late int _proc_loop_total;

	late MathEnv _math_env;

	ClipProcEnv(){
		_proc_graph          = ClipGraph();
		_proc_gworld         = _proc_graph.gWorld();
		_proc_func           = ClipFunc();
		_global_param        = null;
		_proc_warn_flow      = false;
		_proc_trace          = false;
		_proc_loop_max       = 0;
		_proc_loop_count     = 0;
		_proc_loop_count_max = 0;
		_proc_loop_total     = 0;

		_math_env = MathEnv();
	}
}
void setProcEnv( ClipProcEnv env ){
	_proc_env = env;
	setMathEnv( env._math_env );
}

ClipGraph procGraph(){
	return _proc_env._proc_graph;
}
ClipGWorld procGWorld(){
	return _proc_env._proc_gworld;
}
ClipFunc procFunc(){
	return _proc_env._proc_func;
}

void setGlobalParam( ClipParam param ){
	_proc_env._global_param = param;
}
ClipParam globalParam(){
	return _proc_env._global_param!;
}

void setProcWarnFlowFlag( bool flag ){
	_proc_env._proc_warn_flow = flag;
}
bool procWarnFlowFlag(){
	return _proc_env._proc_warn_flow;
}

void setProcTraceFlag( bool flag ){
	_proc_env._proc_trace = flag;
}
bool procTraceFlag(){
	return _proc_env._proc_trace;
}

void setProcLoopMax( int max ){
	_proc_env._proc_loop_max = max;
}
int procLoopMax(){
	return _proc_env._proc_loop_max;
}
void initProcLoopCount(){
	_proc_env._proc_loop_count     = 0;
	_proc_env._proc_loop_count_max = 0;
	_proc_env._proc_loop_total     = 0;
}
void resetProcLoopCount(){
	if( _proc_env._proc_loop_count_max < _proc_env._proc_loop_count ){
		_proc_env._proc_loop_count_max = _proc_env._proc_loop_count;
	}
	_proc_env._proc_loop_count = 0;
}
void setProcLoopCount( int count ){
	_proc_env._proc_loop_count = count;
}
int procLoopCount(){
	return _proc_env._proc_loop_count;
}
int procLoopCountMax(){
	return _proc_env._proc_loop_count_max;
}
void incProcLoopTotal(){
	_proc_env._proc_loop_total++;
}
int procLoopTotal(){
	return _proc_env._proc_loop_total;
}

class ClipProcVal {
	late ClipProc _proc;
	late ClipParam? _param;
	late MathMatrix _mat;
	late MPData _mp;
	late bool _mpFlag;

	ClipProcVal( ClipProc proc, [ClipParam? param] ){
		_proc   = proc;
		_param  = param;
		_mat    = MathMatrix();
		_mp     = MPData();
		_mpFlag = false;
	}

	ClipProcVal setParam( ClipParam param ){
		_param = param;
		return this;
	}
	MathMatrix mat(){
		if( _mpFlag ){
			String str = _proc_mp.fnum2str( _mp, _param!.mpPrec() );
			double val = stringToFloat( str, 0, ParamInteger() );
			_mat.ass( val );
			_proc._updateMatrix( _param!, _mat );
		}
		_mpFlag = false;
		return _mat;
	}
	void matAss( dynamic val ){
		mat().ass( val );
	}
	MPData mp(){
		if( _mpFlag ){
			if( (_param!.mode() == CLIP_MODE_I_MULTIPREC) && (_proc_mp.getPrec( _mp ) > 0) ){
				_proc_mp.ftrunc( _mp, _mp );
			}
		} else {
			_proc._updateMatrix( _param!, _mat );
			double val = _mat.mat(0).toFloat();
			String str = floatToFixed( val, MATH_FPREC( val ).toInt() );
			_proc_mp.fstr2num( _mp, str );
		}
		_mpFlag = true;
		return _mp;
	}
	void setMpFlag( bool flag ){
		_mpFlag = flag;
	}
	bool mpFlag(){
		return _mpFlag;
	}
}
List<ClipProcVal> newProcValArray( int len, ClipProc proc, [ClipParam? param] ){
	List<ClipProcVal> a = List.filled( len, ClipProcVal( proc, param ) );
	for( var i = 0; i < len; i++ ){
		a[i] = ClipProcVal( proc, param );
	}
	return a;
}

class _ClipInc {
	late bool _flag;

	late int _code;
	late dynamic _token;
	late List<int>? _array;
	late int _arraySize;

	late _ClipInc? _next;

	_ClipInc(){
		_flag = false;

		_code      = 0;
		_token     = null;
		_array     = null;
		_arraySize = 0;

		_next = null;
	}
}

class ClipProcPrint {
	late String? _string;
	late ClipProcPrint? _next;

	ClipProcPrint(){
		_string = null;
		_next   = null;
	}

	String? string(){
		return _string;
	}
	ClipProcPrint? next(){
		return _next;
	}
}

class ClipProcScan {
	late String? _title;
	late int _code;
	late dynamic _token;
	late ClipProcScan? _before;
	late ClipProcScan? _next;

	ClipProcScan(){
		_title  = null;
		_code   = 0;
		_token  = null;
		_before = null;
		_next   = null;
	}

	String title(){
		if( _title == null ){
			return "";
		}
		return _title!;
	}
	ClipProcScan? next(){
		return _next;
	}
	String getDefString( ClipProc proc, ClipParam param ){
		String defString = "";

		switch( _code ){
		case CLIP_CODE_GLOBAL_ARRAY:
			param = globalParam();
			// そのまま下に流す
			continue case_CLIP_CODE_ARRAY;
		case_CLIP_CODE_ARRAY:
		case CLIP_CODE_ARRAY:
		case CLIP_CODE_AUTO_ARRAY:
			defString = proc.strGet( param.array(), proc.arrayIndexDirect( param, _code, _token ) );
			break;
		case CLIP_CODE_GLOBAL_VAR:
			param = globalParam();
			// そのまま下に流す
			continue _default;
		_default:
		default:
			ParamString real = ParamString();
			ParamString imag = ParamString();
			_proc_token.valueToString( param, param.val( proc.varIndexDirect( param, _code, _token ) ), real, imag );
			defString = real.str() + imag.str();
			break;
		}

		return defString;
	}
	void setNewValue( String newString, ClipProc proc, ClipParam param ){
		switch( _code ){
		case CLIP_CODE_GLOBAL_ARRAY:
			param = globalParam();
			// そのまま下に流す
			continue case_CLIP_CODE_ARRAY;
		case_CLIP_CODE_ARRAY:
		case CLIP_CODE_ARRAY:
		case CLIP_CODE_AUTO_ARRAY:
			proc.strSet( param.array(), proc.arrayIndexDirect( param, _code, _token ), newString );
			break;
		default:
			MathValue value = MathValue();
			if( _proc_token.stringToValue( param, newString, value ) ){
				ParamBoolean moveFlag = ParamBoolean();
				int index = proc.varIndexDirectMove( param, _code, _token, moveFlag );
				param.setVal( index, value, moveFlag.val() );
			}
			break;
		}
	}
}

class ClipProcUsage {
	late String? _string;
	late ClipProcUsage? _next;
	ClipProcUsage(){
		_string = null;
		_next   = null;
	}
}

class _ClipProcInfo {
	late int _assCode;
	late dynamic _assToken;

	late List<int>? _curArray;
	late int _curArraySize;

	_ClipProcInfo(){
		_assCode  = CLIP_CODE_NULL;
		_assToken = null;

		_curArray     = null;
		_curArraySize = 0;
	}
}

class _ClipIndex {
	late ClipParam? _param;
	late int _index;

	_ClipIndex(){
		_param = null;
		_index = -1;
	}

	void set( ClipParam param, int index ){
		_param = param;
		_index = index;
	}
}

const int CLIP_STAT_IFMODE_DISABLE   = 0; // 無効（スキップ中）
const int CLIP_STAT_IFMODE_ENABLE    = 1; // 有効（開始前または実行中）
const int CLIP_STAT_IFMODE_PROCESSED = 2; // 実行済み（スキップ中）
//const int CLIP_STAT_IFMODE_STARTED   = 3; // 開始した

const int CLIP_STAT_SWIMODE_DISABLE   = 0; // 無効（スキップ中）
const int CLIP_STAT_SWIMODE_ENABLE    = 1; // 有効（開始前または実行中）
const int CLIP_STAT_SWIMODE_PROCESSED = 2; // 実行済み（スキップ中）
//const int CLIP_STAT_SWIMODE_STARTED   = 3; // 開始した

const int CLIP_STAT_MODE_NOT_START   = 0; // 開始前
const int CLIP_STAT_MODE_REGISTERING = 1; // 行データの取り込み中
const int CLIP_STAT_MODE_PROCESSING  = 2; // 制御処理実行中

const int CLIP_PROC_END_TYPE_WHILE  = 0;
const int CLIP_PROC_END_TYPE_FOR    = 1;
const int CLIP_PROC_END_TYPE_IF     = 2;
const int CLIP_PROC_END_TYPE_SWITCH = 3;

late ClipToken _proc_token; // 汎用ClipTokenオブジェクト
late MathValue _proc_val; // updateAns用
late MultiPrec _proc_mp; // 多倍長演算サポート
void initProc(){
	_proc_token = ClipToken();
	_proc_val   = MathValue();
	_proc_mp    = MultiPrec();
}
ClipToken procToken(){
	return _proc_token;
}
MultiPrec procMultiPrec(){
	return _proc_mp;
}

// 計算クラス
class ClipProc {
	late ClipProcVal _valAns;
	late ClipProcVal _valSeAns;

	late ClipLine? _procLine;

	late ClipLineData _defLine;
	late ClipLineData _curLine;

	late _ClipProcInfo _defInfo;
	late _ClipProcInfo _curInfo;

	late int _errCode;
	late dynamic _errToken;

	late int _parentMode;
	late int _parentMpPrec;
	late int _parentMpRound;
	late int _angType;
	late bool _angUpdateFlag;

	late int _parentAngType;

	// 各種フラグ
	late bool _quitFlag;
	late bool _printAns;
	late bool _printAssert;
	late bool _prevPrintAssert;
	late bool _printWarn;
	late bool _prevPrintWarn;
	late bool _gUpdateFlag;
	late bool _prevGUpdateFlag;

	// ifステートメント情報
	late List<int> _statIfMode;
	late int _statIfCnt;
	late int _statIfMax;

	// switchステートメント情報
	late List<int> _statSwiMode;
	late List<ClipProcVal> _statSwiVal;
	late int _statSwiCnt;
	late int _statSwiMax;

	// ループ・ステートメント情報
	late int _statMode;
	late ClipLoop? _stat;
	late int _loopCnt;

	// 配列の初期化データ情報
	late bool _initArrayFlag;
	late int _initArrayCnt;
	late int _initArrayMax;
	late int _initArrayIndex;
	late ParamBoolean _initArrayMoveFlag;
	late ClipToken? _initArray;

	late _ClipInc? _topInc;
	late _ClipInc? _endInc;

	late ClipProcUsage? _topUsage;
	late ClipProcUsage? _curUsage;

	late List<int> _endType;
	late int _endCnt;

	ClipProc( int parentMode, int parentMpPrec, int parentMpRound, bool printAns, bool printAssert, bool printWarn, bool gUpdateFlag ){
		_valAns   = ClipProcVal( this );
		_valSeAns = ClipProcVal( this );

		_procLine = null;

		_defLine = ClipLineData();
		_curLine = _defLine;

		_defInfo = _ClipProcInfo();
		_curInfo = _defInfo;

		_errCode  = 0;
		_errToken = null;

		_parentMode    = parentMode;
		_parentMpPrec  = parentMpPrec;
		_parentMpRound = parentMpRound;
		_angType       = MATH_ANG_TYPE_RAD;
		_angUpdateFlag = false;

		_parentAngType = complexAngType();
		setComplexAngType( _angType );

		// 各種フラグ
		_quitFlag        = false;
		_printAns        = printAns;
		_printAssert     = printAssert;
		_prevPrintAssert = printAssert;
		_printWarn       = printWarn;
		_prevPrintWarn   = printWarn;
		_gUpdateFlag     = gUpdateFlag;
		_prevGUpdateFlag = gUpdateFlag;

		// ifステートメント情報
		_statIfMode    = List.filled( 16, 0 );
		_statIfMode[0] = CLIP_STAT_IFMODE_ENABLE;
		_statIfCnt     = 0;
		_statIfMax     = 15;

		// switchステートメント情報
		_statSwiMode    = List.filled( 16, 0 );
		_statSwiMode[0] = CLIP_STAT_SWIMODE_ENABLE;
		_statSwiVal     = newProcValArray( 16, this );
		_statSwiCnt     = 0;
		_statSwiMax     = 15;

		// ループ・ステートメント情報
		_statMode = CLIP_STAT_MODE_NOT_START;
		_stat     = null;
		_loopCnt  = 0;

		// 配列の初期化データ情報
		_initArrayFlag     = false;
		_initArrayCnt      = 0;
		_initArrayMax      = 0;
		_initArrayIndex    = 0;
		_initArrayMoveFlag = ParamBoolean();
		_initArray         = null;

		_topInc = null;
		_endInc = null;

		_topUsage = null;
		_curUsage = null;

		_endType = List.filled( 16, 0 );
		_endCnt  = 0;
	}

	void end(){
		setComplexAngType( _parentAngType );
	}

//	curLine(){
//		return _curLine._token;
//	}
//	setCurLine( token ){
//		_curLine._token = token;
//	}
//	curNum(){
//		return _curLine.num();
//	}
//	curComment(){
//		return _curLine._comment;
//	}

	// 外部関数キャッシュのサイズを設定する
	void setFuncCacheSize( int size ){
		procFunc().setMaxNum( size );
	}

	// 外部関数キャッシュのサイズを確認する
	int funcCacheSize(){
		return procFunc().maxNum();
	}

	// 外部関数キャッシュをクリアする
	void clearFuncCache( String name ){
		ClipFuncData? curFunc;
		if( (curFunc = procFunc().search( name, false, null )) != null ){
			procFunc().del( curFunc! );
		}
	}
	void clearAllFuncCache(){
		procFunc().delAll();
	}

	bool getFuncCacheInfo( int num, ClipFuncInfo info ){
		return procFunc().getInfo( num, info );
	}

	bool canClearFuncCache(){
		return procFunc().canDel();
	}

	// 終了要求
//	postQuit(){
//		_quitFlag = true;
//	}

	void setAnsFlag( bool flag ){
		_printAns = flag;
	}
	bool ansFlag(){
		return _printAns;
	}

	void _setFlag( int flag, ParamBoolean newFlag, ParamBoolean prevFlag ){
		if( flag < 0 ){
			var tmpFlag = newFlag.val();
			newFlag .set( prevFlag.val() );
			prevFlag.set( tmpFlag );
		} else {
			prevFlag.set( newFlag.val() );
			newFlag .set( flag != 0 );
		}
	}

	void setAssertFlag( int flag ){
		ParamBoolean printAssert     = ParamBoolean( _printAssert     );
		ParamBoolean prevPrintAssert = ParamBoolean( _prevPrintAssert );
		_setFlag( flag, printAssert, prevPrintAssert );
		_printAssert     = printAssert    .val();
		_prevPrintAssert = prevPrintAssert.val();
	}
//	assertFlag(){
//		return _printAssert;
//	}

	void setWarnFlag( int flag ){
		ParamBoolean printWarn     = ParamBoolean( _printWarn     );
		ParamBoolean prevPrintWarn = ParamBoolean( _prevPrintWarn );
		_setFlag( flag, printWarn, prevPrintWarn );
		_printWarn     = printWarn    .val();
		_prevPrintWarn = prevPrintWarn.val();
	}
//	warnFlag(){
//		return _printWarn;
//	}

	void setGUpdateFlag( int flag ){
		ParamBoolean gUpdateFlag     = ParamBoolean( _gUpdateFlag     );
		ParamBoolean prevGUpdateFlag = ParamBoolean( _prevGUpdateFlag );
		_setFlag( flag, gUpdateFlag, prevGUpdateFlag );
		_gUpdateFlag     = gUpdateFlag    .val();
		_prevGUpdateFlag = prevGUpdateFlag.val();
	}
//	gUpdateFlag(){
//		return _gUpdateFlag;
//	}

	void setAngType( int type, bool updateFlag ){
		_angType       = type;
		_angUpdateFlag = updateFlag;
		setComplexAngType( _angType );
	}
	void getAngType( ParamInteger type, ParamBoolean updateFlag ){
		type.set( _angType );
		updateFlag.set( _angUpdateFlag );
	}

	int _index( ClipParam param, int code, dynamic token ){
		if( token == MATH_CHAR_CODE_COLON ){
			ClipProcVal value = ClipProcVal( this, param );
			if( _const( param, code, token, value ) == CLIP_NO_ERR ){
				return MATH_UNSIGNED( value.mat().mat(0).toFloat(), MATH_UMAX_8.toDouble() ).toInt();
			}
		}
		return token;
	}
	int varIndexParam( ClipParam param, dynamic token ){
		return _index( param, CLIP_CODE_VARIABLE, token );
	}
	int autoVarIndex( ClipParam param, dynamic token ){
		return param.variable().label().checkLabel( token );
	}
	int varIndexIndirect( ClipParam param, int code, dynamic token ){
		return (code == CLIP_CODE_VARIABLE) ? _index( param, code, token ) : autoVarIndex( param, token );
	}
	int varIndexIndirectMove( ClipParam param, int code, dynamic token, ParamBoolean moveFlag ){
		moveFlag.set( code == CLIP_CODE_VARIABLE );
		return moveFlag.val() ? _index( param, code, token ) : autoVarIndex( param, token );
	}
	int varIndexDirect( ClipParam param, int code, dynamic token ){
		return (code == CLIP_CODE_VARIABLE) ? token : autoVarIndex( param, token );
	}
	int varIndexDirectMove( ClipParam param, int code, dynamic token, ParamBoolean moveFlag ){
		moveFlag.set( code == CLIP_CODE_VARIABLE );
		return moveFlag.val() ? token : autoVarIndex( param, token );
	}
	int arrayIndexParam( ClipParam param, dynamic token ){
		return _index( param, CLIP_CODE_ARRAY, token );
	}
	int autoArrayIndex( ClipParam param, dynamic token ){
		return param.array().label().checkLabel( token );
	}
	int arrayIndexIndirect( ClipParam param, int code, dynamic token ){
		return (code == CLIP_CODE_ARRAY) ? _index( param, code, token ) : autoArrayIndex( param, token );
	}
	int arrayIndexIndirectMove( ClipParam param, int code, dynamic token, ParamBoolean moveFlag ){
		moveFlag.set( code == CLIP_CODE_ARRAY );
		return moveFlag.val() ? _index( param, code, token ) : autoArrayIndex( param, token );
	}
	int arrayIndexDirect( ClipParam param, int code, dynamic token ){
		return (code == CLIP_CODE_ARRAY) ? token : autoArrayIndex( param, token );
	}
	int arrayIndexDirectMove( ClipParam param, int code, dynamic token, ParamBoolean moveFlag ){
		moveFlag.set( code == CLIP_CODE_ARRAY );
		return moveFlag.val() ? token : autoArrayIndex( param, token );
	}

	// 文字列を設定する
	void _strSet( ClipArray array, int index, int top, String str ){
		int src, dst;
		List<int> dst2 = List.filled( 1, 0 );
		array.resizeVector( index, top + str.length, 0.0, false );
		dst = top;
		for( src = 0; src < str.length; src++, dst++ ){
			dst2[0] = dst;
			array.set( index, dst2, 1, charCodeAt( str, src ).toDouble(), false );
		}
	}
	void strSet( ClipArray array, int index, String str ){
		_strSet( array, index, 0, str );
	}
	void strCat( ClipArray array, int index, String str ){
		_strSet( array, index, strLen( array, index ), str );
	}

	// 文字列を取得する
	String strGet( ClipArray array, int index ){
		String str = "";
		int len = strLen( array, index );
		for( int i = 0; i < len; i++ ){
			str += String.fromCharCode( MATH_INT( array.val( index, i ).toFloat() ).toInt() );
		}
		return str;
	}

	// 文字列の長さを取得する
	int strLen( ClipArray array, int index ){
		int len;
		for( len = 0; ; len++ ){
			if( array.val( index, len ).toFloat() == 0 ){
				break;
			}
		}
		return len;
	}

	// 文字列中の文字を小文字に変換する
	void strLwr( ClipArray array, int index ){
		int chr;
		List<int> dst = List.filled( 1, 0 );
		for( int i = 0; ; i++ ){
			if( (chr = array.val( index, i ).toFloat().toInt()) == 0 ){
				break;
			}
			if( (chr >= MATH_CHAR_CODE_UA) && (chr <= MATH_CHAR_CODE_UZ) ){
				dst[0] = i;
				array.set( index, dst, 1, (chr - MATH_CHAR_CODE_UA + MATH_CHAR_CODE_LA).toDouble(), false );
			}
		}
	}

	// 文字列中の文字を大文字に変換する
	void strUpr( ClipArray array, int index ){
		int chr;
		List<int> dst = List.filled( 1, 0 );
		for( int i = 0; ; i++ ){
			if( (chr = array.val( index, i ).toFloat().toInt()) == 0 ){
				break;
			}
			if( (chr >= MATH_CHAR_CODE_LA) && (chr <= MATH_CHAR_CODE_LZ) ){
				dst[0] = i;
				array.set( index, dst, 1, (chr - MATH_CHAR_CODE_LA + MATH_CHAR_CODE_UA).toDouble(), false );
			}
		}
	}

	// 計算する
	void _setError( int code, dynamic token ){
		_errCode  = code;
		_errToken = token;
	}
	int _retError( int err, int code, dynamic token ){
		_setError( code, token );
		return err;
	}
	void _updateMatrix( ClipParam param, MathMatrix mat ){
		int i;

		if( (param.mode() & CLIP_MODE_FLOAT) != 0 ){
			for( i = 0; i < mat.len(); i++ ){
				mat.mat(i).setImag( 0.0 );
			}
		} else if( (param.mode() & CLIP_MODE_INT) != 0 ){
			if( _printWarn && procWarnFlowFlag() ){
				int index = (param.mode() & 0x000F);
				double minValue = CLIP_MIN_VALUE[index];
				double maxValue = CLIP_MAX_VALUE[index];
				int intValue;
				for( i = 0; i < mat.len(); i++ ){
					intValue = MATH_INT( mat.mat(i).toFloat() ).toInt();
					if( (intValue < minValue) || (intValue > maxValue) ){
						_errorProc( (intValue < minValue) ? CLIP_PROC_WARN_UNDERFLOW : CLIP_PROC_WARN_OVERFLOW, _curLine.num(), param, CLIP_CODE_LABEL, "$intValue" );
					}
				}
			}

			switch( param.mode() & CLIP_MODE_MASK ){
			case CLIP_MODE_S_CHAR:
				for( i = 0; i < mat.len(); i++ ){
					mat.mat(i).ass( MATH_SIGNED( mat.mat(i).toFloat(), MATH_UMAX_8, MATH_SMIN_8, MATH_SMAX_8 ) );
				}
				break;
			case CLIP_MODE_U_CHAR:
				for( i = 0; i < mat.len(); i++ ){
					mat.mat(i).ass( MATH_UNSIGNED( mat.mat(i).toFloat(), MATH_UMAX_8 ) );
				}
				break;
			case CLIP_MODE_S_SHORT:
				for( i = 0; i < mat.len(); i++ ){
					mat.mat(i).ass( MATH_SIGNED( mat.mat(i).toFloat(), MATH_UMAX_16, MATH_SMIN_16, MATH_SMAX_16 ) );
				}
				break;
			case CLIP_MODE_U_SHORT:
				for( i = 0; i < mat.len(); i++ ){
					mat.mat(i).ass( MATH_UNSIGNED( mat.mat(i).toFloat(), MATH_UMAX_16 ) );
				}
				break;
			case CLIP_MODE_S_LONG:
				for( i = 0; i < mat.len(); i++ ){
					mat.mat(i).ass( MATH_SIGNED( mat.mat(i).toFloat(), MATH_UMAX_32, MATH_SMIN_32, MATH_SMAX_32 ) );
				}
				break;
			case CLIP_MODE_U_LONG:
				for( i = 0; i < mat.len(); i++ ){
					mat.mat(i).ass( MATH_UNSIGNED( mat.mat(i).toFloat(), MATH_UMAX_32 ) );
				}
				break;
			}
		}
	}
	void _updateArrayNode( ClipParam param, ClipArrayNode node ){
		int i;

		if( node.nodeNum() > 0 ){
			for( i = 0; i < node.nodeNum(); i++ ){
				_updateArrayNode( param, node.node(i) );
			}
		}

		if( node.vectorNum() > 0 ){
			if( (param.mode() & CLIP_MODE_FLOAT) != 0 ){
				for( i = 0; i < node.vectorNum(); i++ ){
					node.vector(i).setImag( 0.0 );
				}
			} else if( (param.mode() & CLIP_MODE_INT) != 0 ){
				if( _printWarn && procWarnFlowFlag() ){
					int index = (param.mode() & 0x000F);
					int minValue = CLIP_MIN_VALUE[index].toInt();
					int maxValue = CLIP_MAX_VALUE[index].toInt();
					int intValue;
					for( i = 0; i < node.vectorNum(); i++ ){
						intValue = MATH_INT( node.vector(i).toFloat() ).toInt();
						if( (intValue < minValue) || (intValue > maxValue) ){
							_errorProc( (intValue < minValue) ? CLIP_PROC_WARN_UNDERFLOW : CLIP_PROC_WARN_OVERFLOW, _curLine.num(), param, CLIP_CODE_LABEL, "$intValue" );
						}
					}
				}

				switch( param.mode() & CLIP_MODE_MASK ){
				case CLIP_MODE_S_CHAR:
					for( i = 0; i < node.vectorNum(); i++ ){
						node.vector(i).ass( MATH_SIGNED( node.vector(i).toFloat(), MATH_UMAX_8, MATH_SMIN_8, MATH_SMAX_8 ) );
					}
					break;
				case CLIP_MODE_U_CHAR:
					for( i = 0; i < node.vectorNum(); i++ ){
						node.vector(i).ass( MATH_UNSIGNED( node.vector(i).toFloat(), MATH_UMAX_8 ) );
					}
					break;
				case CLIP_MODE_S_SHORT:
					for( i = 0; i < node.vectorNum(); i++ ){
						node.vector(i).ass( MATH_SIGNED( node.vector(i).toFloat(), MATH_UMAX_16, MATH_SMIN_16, MATH_SMAX_16 ) );
					}
					break;
				case CLIP_MODE_U_SHORT:
					for( i = 0; i < node.vectorNum(); i++ ){
						node.vector(i).ass( MATH_UNSIGNED( node.vector(i).toFloat(), MATH_UMAX_16 ) );
					}
					break;
				case CLIP_MODE_S_LONG:
					for( i = 0; i < node.vectorNum(); i++ ){
						node.vector(i).ass( MATH_SIGNED( node.vector(i).toFloat(), MATH_UMAX_32, MATH_SMIN_32, MATH_SMAX_32 ) );
					}
					break;
				case CLIP_MODE_U_LONG:
					for( i = 0; i < node.vectorNum(); i++ ){
						node.vector(i).ass( MATH_UNSIGNED( node.vector(i).toFloat(), MATH_UMAX_32 ) );
					}
					break;
				}
			}
		}
	}
	void _updateArray( ClipParam param, ClipArray array, int index ){
		_updateArrayNode( param, array.node(index) );
		_updateMatrix( param, array.matrix(index) );
	}
	void _updateValue( ClipParam param, MathValue val ){
		if( (param.mode() & CLIP_MODE_FLOAT) != 0 ){
			val.setImag( 0.0 );
		} else if( (param.mode() & CLIP_MODE_INT) != 0 ){
			if( _printWarn && procWarnFlowFlag() ){
				int index = (param.mode() & 0x000F);
				int minValue = CLIP_MIN_VALUE[index].toInt();
				int maxValue = CLIP_MAX_VALUE[index].toInt();
				int intValue = MATH_INT( val.toFloat() ).toInt();
				if( (intValue < minValue) || (intValue > maxValue) ){
					_errorProc( (intValue < minValue) ? CLIP_PROC_WARN_UNDERFLOW : CLIP_PROC_WARN_OVERFLOW, _curLine.num(), param, CLIP_CODE_LABEL, "$intValue" );
				}
			}

			switch( param.mode() & CLIP_MODE_MASK ){
			case CLIP_MODE_S_CHAR:
				val.ass( MATH_SIGNED( val.toFloat(), MATH_UMAX_8, MATH_SMIN_8, MATH_SMAX_8 ) );
				break;
			case CLIP_MODE_U_CHAR:
				val.ass( MATH_UNSIGNED( val.toFloat(), MATH_UMAX_8 ) );
				break;
			case CLIP_MODE_S_SHORT:
				val.ass( MATH_SIGNED( val.toFloat(), MATH_UMAX_16, MATH_SMIN_16, MATH_SMAX_16 ) );
				break;
			case CLIP_MODE_U_SHORT:
				val.ass( MATH_UNSIGNED( val.toFloat(), MATH_UMAX_16 ) );
				break;
			case CLIP_MODE_S_LONG:
				val.ass( MATH_SIGNED( val.toFloat(), MATH_UMAX_32, MATH_SMIN_32, MATH_SMAX_32 ) );
				break;
			case CLIP_MODE_U_LONG:
				val.ass( MATH_UNSIGNED( val.toFloat(), MATH_UMAX_32 ) );
				break;
			}
		}
	}
	int _procInitArray( ClipParam param ){
		bool flag;
		int code;
		dynamic token;
		int ret = CLIP_NO_ERR;
		List<int>? arrayList;
		List<int>? resizeList;
		ClipToken? saveLine;
		ClipTokenData? lock;
		ClipProcVal value = ClipProcVal( this, param );

		flag = false;
		while( _curLine.token()!.getToken() ){
			code  = getCode();
			token = getToken();
			_initArray!.addCode( code, token );
			if( code == CLIP_CODE_ARRAY_TOP ){
				_initArrayCnt++;
				if( _initArrayCnt > _initArrayMax ){
					_initArrayMax = _initArrayCnt;
				}
			} else if( code == CLIP_CODE_ARRAY_END ){
				if( _initArrayCnt <= 0 ){
					ret = _retError( CLIP_PROC_ERR_ARRAY, code, token );
					flag = true;
					break;
				}
				_initArrayCnt--;
				if( _initArrayCnt <= 0 ){
					arrayList  = List.filled( _initArrayMax + 1, 0 );
					resizeList = List.filled( 3, 0 );
					resizeList[0] = 0;
					resizeList[1] = 0;
					resizeList[2] = -1;
					saveLine = _curLine.token();
					_curLine.setToken( _initArray! );
					_initArray!.beginGetToken();
					while( true ){
						lock = _initArray!.lock();
						if( !(_initArray!.getToken()) ){
							break;
						}
						code  = getCode();
						token = getToken();
						if( code == CLIP_CODE_ARRAY_TOP ){
							_initArrayCnt++;
							arrayList[_initArrayCnt - 1] = 0;
							arrayList[_initArrayCnt    ] = -1;
						} else if( code == CLIP_CODE_ARRAY_END ){
							_initArrayCnt--;
							if( _initArrayCnt > 0 ){
								arrayList[_initArrayCnt - 1]++;
								arrayList[_initArrayCnt    ] = -1;
							}
						} else {
							_initArray!.unlock( lock );
							if( _const( param, code, token, value ) == CLIP_NO_ERR ){
								if( _initArrayCnt == 2 ){
									if( resizeList[0] < arrayList[0] ){
										resizeList[0] = arrayList[0];
									}
									if( resizeList[1] < arrayList[1] ){
										resizeList[1] = arrayList[1];
									}
								}
								param.array().resize(
									_initArrayIndex,
									resizeList, arrayList, _initArrayCnt,
									value.mat().mat(0),
									_initArrayMoveFlag.val()
									);
								arrayList[_initArrayCnt - 1]++;
							} else {
								ret = _retError( CLIP_PROC_ERR_ARRAY, code, token );
								flag = true;
								break;
							}
						}
					}
					_curLine.setToken( saveLine );
					arrayList  = null;
					resizeList = null;

					flag = true;
					break;
				}
			}
		}
		if( flag ){
			_initArrayFlag = false;
			_initArray = null;
		}

		return (ret == CLIP_NO_ERR) ? CLIP_PROC_SUB_END : ret;
	}
	void _getArrayInfo( ClipParam param, int code, dynamic token ){
		ClipTokenData? lock;
		ClipProcVal value = ClipProcVal( this, param );
		int index;

		_curInfo._curArray = List.filled( 16, 0 );
		for( _curInfo._curArraySize = 0; ; _curInfo._curArraySize++ ){
			lock = _curLine.token()!.lock();
			if( _const( param, code, token, value ) != CLIP_NO_ERR ){
				_curLine.token()!.unlock( lock );
				break;
			}
			index = MATH_INT( value.mat().mat(0).toFloat() ).toInt() - param.base();
			if( index < 0 ){
				_errorProc( CLIP_PROC_WARN_ARRAY, _curLine.num(), param, CLIP_CODE_NULL, null );
				_curInfo._curArray![_curInfo._curArraySize] = CLIP_INVALID_ARRAY_INDEX;
			} else {
				_curInfo._curArray![_curInfo._curArraySize] = index;
			}
		}
		_curInfo._curArray![_curInfo._curArraySize] = -1;
	}
	bool _getParams( ClipParam parentParam, int code, dynamic token, ClipToken funcParam, bool seFlag ){
		ClipTokenData? lock;
		int newCode;
		dynamic newToken;
		ClipProcVal tmpValue = ClipProcVal( this, parentParam );

		while( _curLine.token()!.get() != null ){
			if( seFlag ){
				if( !(_curLine.token()!.skipComma()) ){
					return false;
				}
			}

			lock = _curLine.token()!.lock();
			if( !(_curLine.token()!.getTokenParam( parentParam )) ){
				break;
			}
			newCode  = getCode();
			newToken = getToken();
			if(
				((newCode & (CLIP_CODE_VAR_MASK | CLIP_CODE_ARRAY_MASK)) != 0) ||
				(newCode == CLIP_CODE_CONSTANT) ||
				(newCode == CLIP_CODE_MULTIPREC) ||
				(newCode == CLIP_CODE_STRING)
			){
				funcParam.addCode( newCode, newToken );
			} else {
				_curLine.token()!.unlock( lock );
				if( _const( parentParam, code, token, tmpValue ) == CLIP_NO_ERR ){
					if( tmpValue.mpFlag() ){
						funcParam.addMultiPrec( tmpValue._mp );
					} else if( tmpValue._mat.len() > 1 ){
						funcParam.addMatrix( tmpValue._mat );
					} else {
						funcParam.addValue( tmpValue._mat.mat(0) );
					}
				} else {
					_curLine.token()!.unlock( lock );
					break;
				}
			}
		}

		return true;
	}
	void _formatError( String format, String? funcName, ParamString error ){
		if( funcName == null ){
			error.set( format );
		} else {
			_formatFuncName( format, funcName, error );
		}
	}
	bool _checkSkipLoop(){
		return (_statMode == CLIP_STAT_MODE_PROCESSING) && _stat!.checkBreak();
	}
	bool _checkSkipIf(){
		return ((_statIfMode[_statIfCnt] == CLIP_STAT_IFMODE_DISABLE) || (_statIfMode[_statIfCnt] == CLIP_STAT_IFMODE_PROCESSED)) ? true : _checkSkipLoop();
	}
	bool _checkSkipSwi(){
		return ((_statSwiMode[_statSwiCnt] == CLIP_STAT_SWIMODE_DISABLE) || (_statSwiMode[_statSwiCnt] == CLIP_STAT_SWIMODE_PROCESSED)) ? true : _checkSkipLoop();
	}
	bool _checkSkip(){
		return (
			((_statIfMode [_statIfCnt ] == CLIP_STAT_IFMODE_DISABLE ) || (_statIfMode [_statIfCnt ] == CLIP_STAT_IFMODE_PROCESSED )) ||
			((_statSwiMode[_statSwiCnt] == CLIP_STAT_SWIMODE_DISABLE) || (_statSwiMode[_statSwiCnt] == CLIP_STAT_SWIMODE_PROCESSED))
			) ? true : _checkSkipLoop();
	}
	int _processLoop( ClipParam param ){
		int code;
		dynamic token;

		_curLine.token()!.beginGetToken();
		if( !(_curLine.token()!.getTokenLock()) ){
			return CLIP_PROC_SUB_END;
		}
		code  = getCode();
		token = getToken();

		switch( code ){
		case CLIP_CODE_STATEMENT:
			if( !(param.enableStat()) ){
				return CLIP_LOOP_ERR_STAT;
			}

			_setError( code, token );

			return _procSubLoop[token]( this );
		case CLIP_CODE_COMMAND:
			if( !(param.enableCommand()) ){
				return CLIP_LOOP_ERR_COMMAND;
			}
			break;
		case CLIP_CODE_SE:
			param.setSeFlag( true );
			param.setSeToken( token );
			break;
		}

		return _checkSkip() ? CLIP_PROC_SUB_END : CLIP_NO_ERR;
	}
	int _constFirst( ClipParam param, int code, dynamic token, ClipProcVal value ){
		int newCode;
		dynamic newToken;

		if( !(_curLine.token()!.getTokenParam( param )) ){
			return _retError( CLIP_PROC_ERR_RVALUE_NULL, code, token );
		}
		newCode  = getCode();
		newToken = getToken();

		_proc_token.delToken( _curInfo._assCode, _curInfo._assToken );
		_curInfo._assCode = newCode;
		_curInfo._assToken = _proc_token.newToken( newCode, newToken );

		if( newCode == CLIP_CODE_VARIABLE ){
			return _procVariableFirst( param, newToken, value );
		} else if( newCode == CLIP_CODE_ARRAY ){
			return _procArrayFirst( param, newToken, value );
		} else if( (newCode & CLIP_CODE_MASK) < CLIP_CODE_PROC_END ){
			return _procSub[newCode & CLIP_CODE_MASK]( this, param, newCode, newToken, value, false );
		} else {
			return _retError( CLIP_PROC_ERR_CONSTANT, newCode, newToken );
		}
	}
	int _const( ClipParam param, int code, dynamic token, ClipProcVal value ){
		int newCode;
		dynamic newToken;

		if( !(_curLine.token()!.getTokenParam( param )) ){
			return _retError( CLIP_PROC_ERR_RVALUE_NULL, code, token );
		}
		newCode  = getCode();
		newToken = getToken();

		if( (newCode & CLIP_CODE_MASK) < CLIP_CODE_PROC_END ){
			return _procSub[newCode & CLIP_CODE_MASK]( this, param, newCode, newToken, value, false );
		} else {
			return _retError( CLIP_PROC_ERR_CONSTANT, newCode, newToken );
		}
	}
	int _constSkip( int code, dynamic token ){
		int subStep;
		ClipTokenData? lock;

		subStep = 0;
		while( true ){
			lock = _curLine.token()!.lock();
			if( _curLine.token()!.getToken() ){
				switch( getCode() ){
				case CLIP_CODE_TOP:
					subStep++;
					break;
				case CLIP_CODE_END:
					subStep--;
					if( subStep < 0 ){
						_curLine.token()!.unlock( lock );
						return CLIP_NO_ERR;
					}
					break;
				case CLIP_CODE_OPERATOR:
					if( subStep <= 0 ){
						_curLine.token()!.unlock( lock );
						return CLIP_NO_ERR;
					}
					break;
				}
			} else {
				break;
			}
		}

		return CLIP_NO_ERR;
	}
	int _constSkipConditional( int code, dynamic token ){
		int subStep;

		subStep = 0;
		while( true ){
			if( _curLine.token()!.getToken() ){
				switch( getCode() ){
				case CLIP_CODE_TOP:
					subStep++;
					break;
				case CLIP_CODE_END:
					subStep--;
					if( subStep < 0 ){
						return _retError( CLIP_PROC_ERR_RVALUE_NULL, code, token );
					}
					break;
				}
				if( subStep == 0 ){
					break;
				}
			} else {
				return _retError( CLIP_PROC_ERR_RVALUE_NULL, code, token );
			}
		}

		return CLIP_NO_ERR;
	}
	bool _getString( ClipParam param, ParamString string ){
		int code;
		dynamic token;
		if( _curLine.token()!.getTokenParam( param ) ){
			code  = getCode();
			token = getToken();
			if( code == CLIP_CODE_STRING ){
				string.set( token );
			} else if( (code & CLIP_CODE_ARRAY_MASK) != 0 ){
				if( code == CLIP_CODE_GLOBAL_ARRAY ){
					param = globalParam();
				}
				var arrayIndex = arrayIndexIndirect( param, code, token );
				string.set( strGet( param.array(), arrayIndex ) );
			} else {
				string.set( null );
			}
		} else {
			string.set( null );
			return false;
		}
		return true;
	}
	int _processOp( ClipParam param, ClipProcVal value ){
		int code;
		dynamic token;

		if( !(_curLine.token()!.getToken()) ){
			return _retError( CLIP_PROC_ERR_OPERATOR, CLIP_CODE_NULL, null );
		}
		code  = getCode();
		token = getToken();

		if( (code == CLIP_CODE_OPERATOR) && (token >= CLIP_OP_UNARY_END) ){
			return _procSubOp[token]( this, param, code, token, value );
		} else {
			return _retError( CLIP_PROC_ERR_OPERATOR, code, token );
		}
	}
	int _regInc( bool flag, ClipParam param, int code, dynamic token ){
		switch( _curInfo._assCode ){
		case CLIP_CODE_VARIABLE:
			if( param.variable().isLocked( _curInfo._assToken ) ){
				return _retError( CLIP_PROC_ERR_ASS, code, token );
			}
			_regIncSub( flag, _curInfo._assCode, _curInfo._assToken, null, 0 );
			break;
		case CLIP_CODE_GLOBAL_VAR:
			param = globalParam();
			// そのまま下に流す
			continue case_CLIP_CODE_AUTO_VAR;
		case_CLIP_CODE_AUTO_VAR:
		case CLIP_CODE_AUTO_VAR:
			if( param.variable().isLocked( autoVarIndex( param, _curInfo._assToken ) ) ){
				return _retError( CLIP_PROC_ERR_ASS, code, token );
			}
			_regIncSub( flag, _curInfo._assCode, _curInfo._assToken, null, 0 );
			break;
		case CLIP_CODE_ARRAY:
		case CLIP_CODE_AUTO_ARRAY:
		case CLIP_CODE_GLOBAL_ARRAY:
			if( !(param.mpFlag()) && (_curInfo._curArraySize == 0) ){
				return _retError( CLIP_PROC_ERR_LVALUE, code, token );
			} else {
				_regIncSub( flag, _curInfo._assCode, _curInfo._assToken, _curInfo._curArray, _curInfo._curArraySize );
			}
			break;
		default:
			return _retError( CLIP_PROC_ERR_LVALUE, code, token );
		}
		return CLIP_NO_ERR;
	}
	_ClipInc _regIncSub( bool flag, int code, dynamic token, [List<int>? array, int arraySize = 0] ){
		_ClipInc tmpInc = _ClipInc();

		if( _topInc == null ){
			// 先頭に登録する
			tmpInc._next = null;
			_topInc      = tmpInc;
			_endInc      = tmpInc;
		} else {
			// 最後尾に追加する
			tmpInc._next   = null;
			_endInc!._next = tmpInc;
			_endInc        = tmpInc;
		}

		tmpInc._flag  = flag;
		tmpInc._code  = code;
		tmpInc._token = _proc_token.newToken( code, token );
		if( array == null ){
			tmpInc._array = null;
		} else {
			tmpInc._array = List.filled( arraySize + 1, 0 );
			for( var i = 0; i < arraySize; i++ ){
				tmpInc._array![i] = array[i];
			}
			tmpInc._array![arraySize] = -1;
			tmpInc._arraySize = arraySize;
		}

		return tmpInc;
	}
	void _delInc(){
		_ClipInc? cur;
		_ClipInc tmp;

		cur = _topInc;
		while( cur != null ){
			tmp = cur;
			cur = cur._next;

			_proc_token.delToken( tmp._code, tmp._token );
			if( tmp._array != null ){
				tmp._array = null;
			}
		}
		_topInc = null;
	}
	void _processInc( ClipParam param ){
		_ClipInc? cur;
		int index;
		MathValue val = MathValue();

		cur = _topInc;
		while( cur != null ){
			switch( cur._code ){
			case CLIP_CODE_VARIABLE:
				index = cur._token;
				val.ass( param.val( index ) );

				_updateValue( param, val );
				if( cur._flag ){
					val.addAndAss( 1.0 );
				} else {
					val.subAndAss( 1.0 );
				}

				param.setVal( index, val, true );
				break;
			case CLIP_CODE_AUTO_VAR:
				index = autoVarIndex( param, cur._token );
				val.ass( param.val( index ) );

				_updateValue( param, val );
				if( cur._flag ){
					val.addAndAss( 1.0 );
				} else {
					val.subAndAss( 1.0 );
				}

				param.setVal( index, val, false );
				break;
			case CLIP_CODE_GLOBAL_VAR:
				index = autoVarIndex( globalParam(), cur._token );
				val.ass( globalParam().val( index ) );

				_updateValue( globalParam(), val );
				if( cur._flag ){
					val.addAndAss( 1.0 );
				} else {
					val.subAndAss( 1.0 );
				}

				globalParam().setVal( index, val, false );
				break;
			case CLIP_CODE_ARRAY:
				index = cur._token;
				if( cur._arraySize == 0 ){
					param.array().move( index );
					if( cur._flag ){
						_proc_mp.fadd( param.array().mp(index), param.array().mp(index), _proc_mp.F( "1.0" ) );
					} else {
						_proc_mp.fsub( param.array().mp(index), param.array().mp(index), _proc_mp.F( "1.0" ) );
					}
				} else {
					val.ass( param.array().val( index, cur._array!, cur._arraySize ) );

					_updateValue( param, val );
					if( cur._flag ){
						val.addAndAss( 1.0 );
					} else {
						val.subAndAss( 1.0 );
					}

					param.array().set( index, cur._array!, cur._arraySize, val, true );
				}
				break;
			case CLIP_CODE_AUTO_ARRAY:
				index = autoArrayIndex( param, cur._token );
				if( cur._arraySize == 0 ){
					if( cur._flag ){
						_proc_mp.fadd( param.array().mp(index), param.array().mp(index), _proc_mp.F( "1.0" ) );
					} else {
						_proc_mp.fsub( param.array().mp(index), param.array().mp(index), _proc_mp.F( "1.0" ) );
					}
				} else {
					val.ass( param.array().val( index, cur._array!, cur._arraySize ) );

					_updateValue( param, val );
					if( cur._flag ){
						val.addAndAss( 1.0 );
					} else {
						val.subAndAss( 1.0 );
					}

					param.array().set( index, cur._array!, cur._arraySize, val, false );
				}
				break;
			case CLIP_CODE_GLOBAL_ARRAY:
				index = autoArrayIndex( globalParam(), cur._token );
				if( cur._arraySize == 0 ){
					if( cur._flag ){
						_proc_mp.fadd( globalParam().array().mp(index), globalParam().array().mp(index), _proc_mp.F( "1.0" ) );
					} else {
						_proc_mp.fsub( globalParam().array().mp(index), globalParam().array().mp(index), _proc_mp.F( "1.0" ) );
					}
				} else {
					val.ass( globalParam().array().val( index, cur._array, cur._arraySize ) );

					_updateValue( globalParam(), val );
					if( cur._flag ){
						val.addAndAss( 1.0 );
					} else {
						val.subAndAss( 1.0 );
					}

					globalParam().array().set( index, cur._array!, cur._arraySize, val, false );
				}
				break;
			}
			cur = cur._next;
		}

		_delInc();
	}
	int _processSub( ClipParam param, ClipProcVal value ){
		int ret = CLIP_NO_ERR;
		ClipTokenData? lock;
		int code;
		dynamic token;

		_ClipProcInfo savInfo;
		_ClipProcInfo subInfo = _ClipProcInfo();
		savInfo = _curInfo;
		_curInfo = subInfo;

		lock = _curLine.token()!.lock();
		if( (ret = _processOp( param, value )) != CLIP_NO_ERR ){
			_curLine.token()!.unlock( lock );
			if( (ret = _constFirst( param, CLIP_CODE_NULL, null, value )) != CLIP_NO_ERR ){
				_curInfo = savInfo;
				_proc_token.delToken( subInfo._assCode, subInfo._assToken );
				subInfo._curArray = null;
				return ret;
			}

			ClipProcVal tmpValue1 = ClipProcVal( this, param );

			lock = _curLine.token()!.lock();
			if( _const( param, CLIP_CODE_NULL, null, tmpValue1 ) != CLIP_NO_ERR ){
				_curLine.token()!.unlock( lock );
			} else if( (param.mode() & CLIP_MODE_COMPLEX) != 0 ){
				if( _curLine.token()!.checkToken( CLIP_CODE_END ) ){
					_curLine.token()!.getToken();
					code  = getCode();
					token = getToken();

					_curInfo = savInfo;
					_proc_token.delToken( subInfo._assCode, subInfo._assToken );
					subInfo._curArray = null;
					return _retError( CLIP_PROC_ERR_COMPLEX, code, token );
				} else {
					value.mat().mat(0).setImag( tmpValue1.mat().mat(0).real() );

					_curLine.token()!.getToken();

					_curInfo = savInfo;
					_proc_token.delToken( subInfo._assCode, subInfo._assToken );
					subInfo._curArray = null;
					return CLIP_NO_ERR;
				}
			} else if( (param.mode() & (CLIP_MODE_FLOAT | CLIP_MODE_FRACT)) != 0 ){
				ClipProcVal tmpValue2 = ClipProcVal( this, param );

				lock = _curLine.token()!.lock();
				if( _const( param, CLIP_CODE_NULL, null, tmpValue2 ) != CLIP_NO_ERR ){
					value.mat().divAndAss( tmpValue1.mat().mat(0).toFloat() );

					_curLine.token()!.unlock( lock );
				} else if( _curLine.token()!.checkToken( CLIP_CODE_END ) ){
					_curLine.token()!.getToken();
					code  = getCode();
					token = getToken();

					_curInfo = savInfo;
					_proc_token.delToken( subInfo._assCode, subInfo._assToken );
					subInfo._curArray = null;
					return _retError( CLIP_PROC_ERR_FRACT, code, token );
				} else {
					tmpValue1.mat().divAndAss( tmpValue2.mat().mat(0).toFloat() );
					value.mat().addAndAss( tmpValue1.mat() );

					_curLine.token()!.getToken();

					_curInfo = savInfo;
					_proc_token.delToken( subInfo._assCode, subInfo._assToken );
					subInfo._curArray = null;
					return CLIP_NO_ERR;
				}
			}
		}

		while( _curLine.token()!.checkToken( CLIP_CODE_END ) ){
			if( (ret = _processOp( param, value )) != CLIP_NO_ERR ){
				_curInfo = savInfo;
				_proc_token.delToken( subInfo._assCode, subInfo._assToken );
				subInfo._curArray = null;
				return ret;
			}
		}

		_curLine.token()!.getToken();

		_curInfo = savInfo;
		_proc_token.delToken( subInfo._assCode, subInfo._assToken );
		subInfo._curArray = null;
		return ret;
	}
	int _processSe( ClipParam param, ClipProcVal value ){
		int ret;

		if( (ret = _constFirst( param, CLIP_CODE_SE, param.seToken(), value )) != CLIP_NO_ERR ){
			return ret;
		}

		List<int>? saveArray = _curInfo._curArray;
		int saveArraySize   = _curInfo._curArraySize;

		if( param.seToken() < CLIP_SE_FUNC ){
			ret = _procSubSe[param.seToken()]( this, param, CLIP_CODE_SE, param.seToken(), value );
		} else {
			ret = _procFunc( this, param, CLIP_CODE_FUNCTION, param.seToken() - CLIP_SE_FUNC, value, true );
		}

		if( ret == CLIP_NO_ERR ){
			if( _curLine.token()!.get() != null ){
				ret = _retError( CLIP_PROC_ERR_SE_OPERAND, CLIP_CODE_SE, param.seToken() );
			} else {
				if( !(param.mpFlag()) ){
					_updateMatrix( param, value.mat() );
				}
				ret = _assVal( param, CLIP_CODE_SE, param.seToken(), saveArray, saveArraySize, value );
			}
		}

		saveArray = null;

		return ret;
	}
	bool _processFirst( ClipParam param, ParamInteger ret ){
		if( _curLine.token()!.top() == null ){
			ret.set( CLIP_PROC_END );
			return false;
		}

		// インクリメント情報を消去する
		if( _topInc != null ){
			_delInc();
		}

		if( procTraceFlag() ){
			printTrace( param, _curLine.token()!, _curLine.num(), _curLine.comment(), _checkSkip() );
		}

		return true;
	}
	void _processNext( ClipParam param, ParamInteger ret ){
		while( true ){
			if( ret.set( _processLoop( param ) ).val() != CLIP_NO_ERR ){
				break;
			}

			if( _initArrayFlag ){
				_curLine.token()!.beginGetToken();
				ret.set( _procInitArray( param ) );
				break;
			}

			param.setAssFlag( false );
			param.setSubStep( 0 );

			param.setMpFlag( param.isMultiPrec() );

			_curLine.token()!.beginGetToken();
			if( param.seFlag() ){
				_curLine.token()!.skipToken();
				if( ret.set( _processSe( param, _valSeAns.setParam( param ) ) ).val() != CLIP_NO_ERR ){
					break;
				}

				param.setMpFlag( _valAns.mpFlag() );
			} else {
				if( _valAns.mpFlag() ){
					_valAns._mp.attach( param.array().mp(0).clone() );
				} else {
					_valAns._mat.ass( param.array().matrix(0) );
				}

				if( ret.set( _processSub( param, _valAns.setParam( param ) ) ).val() != CLIP_NO_ERR ){
					break;
				}

				param.setMpFlag( _valAns.mpFlag() );

				if( !(param.assFlag()) ){
					// 計算結果用変数の値を更新
					param.array().move( 0 );
					if( _valAns.mpFlag() ){
						param.array().mp(0).attach( _valAns._mp.clone() );
					} else {
						param.array().matrix(0).ass( _valAns._mat );
						if( param.isMultiPrec() ){
							param.array().mp(0).attach( _valAns._mp.clone() );
						}
					}
				}
			}

			ret.set( CLIP_PROC_END );
			break;
		}

		// 計算結果の表示前に、インクリメントさせる
		if( _topInc != null ){
			_processInc( param );
		}

		if( param.seFlag() ){
			param.setSeFlag( false );
		} else {
			if( (_curLine.next() == null) && _printAns && !(param.assFlag()) ){
				if( ret.val() == CLIP_PROC_END ){
					printAns( param );
				}
			}
		}
	}
	bool _regProcess( ClipLineData line, ParamInteger err ){
		_curLine = line;

		if( _statMode == CLIP_STAT_MODE_REGISTERING ){
			err.set( _stat!.regLine( _curLine ) );
			switch( err.val() ){
			case CLIP_LOOP_CONT:
				break;
			case CLIP_PROC_END:
				_statMode = CLIP_STAT_MODE_PROCESSING;
				break;
			default:
				_statMode = CLIP_STAT_MODE_NOT_START;
				return false;
			}
		}
		return true;
	}
	bool _process( ClipParam param, ParamInteger err ){
		switch( _statMode ){
		case CLIP_STAT_MODE_NOT_START:
			if( _processFirst( param, err ) ){
				_processNext( param, err );
				if( ((err.val() != CLIP_PROC_END) && (err.val() != CLIP_PROC_SUB_END)) || _quitFlag ){
					return false;
				}
			}
			break;
		case CLIP_STAT_MODE_PROCESSING:
			ClipLineData? line;
			while( (line = _stat!.getLine()) != null ){
				_curLine = line!;
				if( _processFirst( param, err ) ){
					_processNext( param, err );
					if( ((err.val() != CLIP_PROC_END) && (err.val() != CLIP_PROC_SUB_END)) || _quitFlag ){
						_statMode = CLIP_STAT_MODE_NOT_START;
						return false;
					}
				}
			}
			_statMode = CLIP_STAT_MODE_NOT_START;
			break;
		}
		return true;
	}
	bool beginProcess( dynamic line, ClipParam param, ParamInteger err ){
		if( line is ClipLine ){
			_procLine = line.dup();

			err.set( CLIP_NO_ERR );
			_procLine!.beginGetLine();
			return true;
		}

		_procLine = ClipLine( param.lineNum() );

		if( err.set( _procLine!.regString( param, line, _statMode != CLIP_STAT_MODE_REGISTERING ) ).val() == CLIP_NO_ERR ){
			_procLine!.beginGetLine();
			return true;
		}

		return false;
	}
	bool process( ClipParam param, ParamInteger err ){
		ClipLineData? line;

		if( (line = _procLine!.getLine()) == null ){
			return false;
		}

		// 置き換え
		ClipTokenData? cur = line!.token()!.top();
		if( cur != null ){
			if( (cur.code() != CLIP_CODE_COMMAND) || ((cur.token() != CLIP_COMMAND_USE) && (cur.token() != CLIP_COMMAND_UNUSE)) ){
				while( cur != null ){
					switch( cur.code() ){
					case CLIP_CODE_LABEL:
					case CLIP_CODE_FUNCTION:
					case CLIP_CODE_EXTFUNC:
						param.replace( cur );
						break;
					}
					cur = cur.next();
				}
			}
		}

		if( !_regProcess( line, err ) ){
			return false;
		}
		if( !_process( param, err ) ){
			return false;
		}

		if( err.val() >= CLIP_ERR_START ){
			if( _quitFlag ){
				_errorProc( err.val(), _curLine.num(), param, _errCode, _errToken );
			} else if( err.val() == CLIP_LOOP_STOP ){
			} else {
				_errorProc( err.val(), _curLine.num(), param, _errCode, _errToken );
			}
		}

		if( (_statMode == CLIP_STAT_MODE_NOT_START) && (_stat != null) ){
			// 制御構造管理クラスを消去する
			_stat = null;
		}

		return true;
	}
	int termProcess( ClipParam param, ParamInteger err ){
		int ret;

		if( _quitFlag ){
			if( err.val() >= CLIP_ERR_START ){
				_errorProc( err.val(), _curLine.num(), param, _errCode, _errToken );
			}
			ret = CLIP_PROC_END;
		} else if( err.val() == CLIP_LOOP_STOP ){
			ret = CLIP_LOOP_STOP;
		} else {
			if( err.val() >= CLIP_ERR_START ){
				ret = _errorProc( err.val(), _curLine.num(), param, _errCode, _errToken ) ? CLIP_LOOP_STOP : CLIP_LOOP_CONT;
			} else {
				ret = CLIP_LOOP_CONT;
			}
		}

		if( (_statMode == CLIP_STAT_MODE_NOT_START) && (_stat != null) ){
			// 制御構造管理クラスを消去する
			_stat = null;
		}

		_curLine = _defLine;
		_procLine = null;

		return ret;
	}
	void resetLoopCount(){
		if( _loopCnt > procLoopCount() ){
			setProcLoopCount( _loopCnt );
		}
		_loopCnt = 0;
	}
	int processLoop( dynamic line, ClipParam param ){
		resetLoopCount();

		ParamInteger err = ParamInteger();
		if( beginProcess( line, param, err ) ){
			while( process( param, err ) ){}
		}
		termProcess( param, err );

		return err.val();
	}

	// テストする
	bool beginTestProcess( String line, ClipParam param, ParamInteger err ){
		_procLine = ClipLine( param.lineNum() );

		if( err.set( _procLine!.regString( param, line, false ) ).val() == CLIP_NO_ERR ){
			_procLine!.beginGetLine();
			return true;
		}

		return false;
	}
	bool testProcess( ClipParam param, ParamInteger err ){
		ClipLineData? line;

		if( (line = _procLine!.getLine()) == null ){
			return false;
		}

		printTest( param, line!.token()!, line.num(), line.comment() );

		return true;
	}
	int termTestProcess( ClipParam param, ParamInteger err ){
		int ret;

		if( err.val() >= CLIP_ERR_START ){
			ret = _errorProc( err.val(), _curLine.num(), param, _errCode, _errToken ) ? CLIP_LOOP_STOP : CLIP_LOOP_CONT;
		} else {
			ret = CLIP_LOOP_CONT;
		}

		_procLine = null;

		return ret;
	}
	int testProcessLoop( String line, ClipParam param ){
		resetLoopCount();

		ParamInteger err = ParamInteger();
		if( beginTestProcess( line, param, err ) ){
			while( testProcess( param, err ) ){}
		}
		termTestProcess( param, err );
		return err.val();
	}

	// 外部関数の引数を取り込む
	int getParam( ClipToken funcParam, ClipParam parentParam, ClipParam childParam ){
		int code;
		dynamic token;
		int index;

		ClipToken? saveLine = _curLine.token();
		_curLine.setToken( funcParam );

		int i = MATH_CHAR_CODE_0;
		int j = 0;
		childParam.initUpdateParam();
		funcParam.beginGetToken();
		while( funcParam.getTokenParam( parentParam ) ){
			code  = getCode();
			token = getToken();
			if( j > 9 ){
				_curLine.setToken( saveLine );
				return _retError( CLIP_PROC_ERR_FUNC_PARANUM, code, token );
			}
			childParam.updateParamCodeArray().add( code );
			childParam.updateParamIndexArray().add( 0 );
			switch( code ){
			case CLIP_CODE_VARIABLE:
				index = varIndexParam( parentParam, token );
				childParam.setUpdateParamIndex( j, index );
				childParam.variable().set( i, parentParam.val( index ), true );
				_updateValue( parentParam, childParam.variable().val( i ) );
				break;
			case CLIP_CODE_AUTO_VAR:
				index = autoVarIndex( parentParam, token );
				childParam.setUpdateParamIndex( j, index );
				childParam.variable().set( i, parentParam.val( index ), true );
				_updateValue( parentParam, childParam.variable().val( i ) );
				break;
			case CLIP_CODE_GLOBAL_VAR:
				index = autoVarIndex( globalParam(), token );
				childParam.setUpdateParamIndex( j, index );
				childParam.variable().set( i, globalParam().val( index ), true );
				_updateValue( globalParam(), childParam.variable().val( i ) );
				break;
			case CLIP_CODE_ARRAY:
				index = arrayIndexParam( parentParam, token );
				childParam.setUpdateParamIndex( j, index );
				parentParam.array().dup( childParam.array(), index, i, true );
				_updateArray( parentParam, childParam.array(), i );
				if( token == 0 ){
					childParam.variable().set( i, parentParam.val( 0 ), true );
					_updateValue( parentParam, childParam.variable().val( i ) );
				}
				break;
			case CLIP_CODE_AUTO_ARRAY:
				index = autoArrayIndex( parentParam, token );
				childParam.setUpdateParamIndex( j, index );
				parentParam.array().dup( childParam.array(), index, i, true );
				_updateArray( parentParam, childParam.array(), i );
				break;
			case CLIP_CODE_GLOBAL_ARRAY:
				index = autoArrayIndex( globalParam(), token );
				childParam.setUpdateParamIndex( j, index );
				globalParam().array().dup( childParam.array(), index, i, true );
				_updateArray( globalParam(), childParam.array(), i );
				break;
			case CLIP_CODE_STRING:
				strSet( childParam.array(), i, token );
				break;
			case CLIP_CODE_CONSTANT:
				childParam.variable().set( i, token, true );
				_updateValue( parentParam, childParam.variable().val( i ) );
				break;
			case CLIP_CODE_MATRIX:
				childParam.array().setMatrix( i, token, true );
				_updateMatrix( parentParam, childParam.array().matrix(i) );
				break;
			case CLIP_CODE_MULTIPREC:
				childParam.array().move( i );
				childParam.array().mp(i).attach( (token as MPData).clone() );

				{
					var str = _proc_mp.fnum2str( childParam.array().mp(i), parentParam.mpPrec() );
					var val = stringToFloat( str, 0, ParamInteger() );
					childParam.variable().set( i, val, true );
					_updateValue( parentParam, childParam.variable().val( i ) );
				}

				break;
			default:
				_curLine.setToken( saveLine );
				return _retError( CLIP_PROC_ERR_FUNC_PARACODE, code, token );
			}
			i++;
			j++;
		}

		_curLine.setToken( saveLine );

		childParam.variable().set( MATH_CHAR_CODE_EX, j, true );

		return CLIP_NO_ERR;
	}

	// 外部関数の引数に指定されている変数の値を更新する
	int updateParam( ClipParam parentParam, ClipParam childParam ){
		int i, j;
		int index;

		j = childParam.updateParamCodeArray().length;
		for( i = 0; i < j; i++ ){
			if( childParam.updateParam(i) ){
				switch( childParam.updateParamCode(i) ){
				case CLIP_CODE_VARIABLE:
					index = childParam.updateParamIndex(i);
					if( parentParam.repVal( index, childParam.variable().val( i + MATH_CHAR_CODE_0 ), true ) ){
						if( index == 0 ){
							_updateMatrix( childParam, parentParam.array().matrix(index) );
						} else {
							_updateValue( childParam, parentParam.variable().val( index ) );
						}
					}
					break;
				case CLIP_CODE_AUTO_VAR:
					index = childParam.updateParamIndex(i);
					if( parentParam.repVal( index, childParam.variable().val( i + MATH_CHAR_CODE_0 ), false ) ){
						if( index == 0 ){
							_updateMatrix( childParam, parentParam.array().matrix(index) );
						} else {
							_updateValue( childParam, parentParam.variable().val( index ) );
						}
					}
					break;
				case CLIP_CODE_GLOBAL_VAR:
					index = childParam.updateParamIndex(i);
					if( globalParam().repVal( index, childParam.variable().val( i + MATH_CHAR_CODE_0 ), false ) ){
						if( index == 0 ){
							_updateMatrix( childParam, globalParam().array().matrix(index) );
						} else {
							_updateValue( childParam, globalParam().variable().val( index ) );
						}
					}
					break;
				case CLIP_CODE_ARRAY:
					childParam.array().rep( parentParam.array(), i + MATH_CHAR_CODE_0, childParam.updateParamIndex(i), true );
					break;
				case CLIP_CODE_AUTO_ARRAY:
					childParam.array().rep( parentParam.array(), i + MATH_CHAR_CODE_0, childParam.updateParamIndex(i), false );
					break;
				case CLIP_CODE_GLOBAL_ARRAY:
					childParam.array().rep( globalParam().array(), i + MATH_CHAR_CODE_0, childParam.updateParamIndex(i), false );
					break;
				}
			}
		}

		return CLIP_NO_ERR;
	}

	// 親プロセスの変数・配列を更新する
	void updateParent( ClipParam parentParam, ClipParam childParam ){
		int i, j;
		int index;

		// 変数
		j = childParam.updateParentVarArray().length;
		for( i = 0; i < j; i++ ){
			index = childParam.updateParentVar(i);
			parentParam.repVal( index, childParam.variable().val( index ), true );
			if( index == 0 ){
				_updateMatrix( childParam, parentParam.array().matrix(index) );
			} else {
				_updateValue( childParam, parentParam.variable().val( index ) );
			}
		}

		// 配列
		j = childParam.updateParentArrayArray().length;
		for( i = 0; i < j; i++ ){
			index = childParam.updateParentArray(i);
			childParam.array().rep( parentParam.array(), index, index, true );
		}
	}

	// 計算結果の値を更新する
	void updateAns( ClipParam childParam ){
		if( _angUpdateFlag && (complexAngType() != _parentAngType) ){
			// 計算結果を親プロセスの角度の単位に変換する
			_proc_val.ass( childParam.array().matrix(0).mat(0) );
			_proc_val.angToAng( _angType, _parentAngType );
			childParam.array().setMatrix( 0, _proc_val, true );
		}
	}

	List<String>? getExtFuncData( ParamString func, [String? nameSpace] ){
		String saveFunc = "";
		saveFunc = func.str();
		List<String>? data = getExtFuncDataDirect( saveFunc );
		if( data != null ){
			return data;
		}
		int tmp = saveFunc.indexOf( ":" );
		if( tmp == 0 ){
			func.set( saveFunc.substring( 1 ) );
		} else if( (nameSpace != null) && (tmp < 0) ){
			func.set( "$nameSpace:$saveFunc" );
		}
		return getExtFuncDataNameSpace( func.str() );
	}

	ClipFuncData? newFuncCache( String func, ClipParam childParam, String? nameSpace ){
		ClipFuncData curFunc;

		if( procFunc().maxNum() == 0 ){
			return null;
		}

		ParamString func2 = ParamString( func );
		List<String>? fileData = getExtFuncData( func2, nameSpace );
		if( fileData == null ){
			return null;
		}

		curFunc = procFunc().create( func2.str() )!;
		for( int i = 0; i < fileData.length; i++ ){
			if( curFunc.line().regString( childParam, fileData[i], false ) == CLIP_PROC_WARN_DEAD_TOKEN ){
				errorProc( CLIP_PROC_WARN_DEAD_TOKEN, curFunc.line().nextNum() - 1, func, "" );
			}
		}

		return curFunc;
	}

	// 外部関数を実行する
	bool _beginMain( String func, ClipParam childParam, ParamInteger step, ParamInteger err, ParamInteger ret, ClipToken? funcParam, ClipParam? parentParam ){
		if( parentParam != null ){
			parentParam.updateMode();
			parentParam.updateFps ();

			childParam.setParent( parentParam );
		}

		childParam.setFileFlag( false );
		childParam.setFileData( null );

		if( (parentParam != null) && (funcParam != null) ){
			// 外部関数の引数を取り込む
			if( err.set( getParam( funcParam, parentParam, childParam ) ).val() != CLIP_NO_ERR ){
				_errorProc( err.val(), 0, childParam, _errCode, _errToken );
				ret.set( CLIP_LOOP_STOP );
				return false;
			}
		}

		childParam.updateMode();
		childParam.updateFps ();

		ParamString func2 = ParamString( func );
		childParam.setFileData( getExtFuncData( func2, (parentParam == null) ? null : parentParam.nameSpace() ) );
		childParam.setFileDataGet( 0 );

		if( childParam.fileDataArray() == null ){
			_errorProc( CLIP_PROC_ERR_FUNC_OPEN, 0, childParam, CLIP_CODE_EXTFUNC, func );
			ret.set( CLIP_LOOP_STOP );
			return false;
		}

		childParam.setFileFlag( true );
		childParam.setFileLine( null );

		childParam.setFunc( func2.str(), 0 );
		childParam.setLineNum( 1 );

		step.set( 0 );
		return true;
	}
	bool _beginMainCache( ClipFuncData func, ClipParam childParam, ParamInteger step, ParamInteger err, ParamInteger ret, ClipToken? funcParam, ClipParam? parentParam ){
		if( parentParam != null ){
			parentParam.updateMode();
			parentParam.updateFps ();

			childParam.setParent( parentParam );
		}

		childParam.setFileFlag( true );
		childParam.setFileData( null );
		childParam.setFileLine( func.line() );

		if( (parentParam != null) && (funcParam != null) ){
			// 外部関数の引数を取り込む
			if( err.set( getParam( funcParam, parentParam, childParam ) ).val() != CLIP_NO_ERR ){
				_errorProc( err.val(), 0, childParam, _errCode, _errToken );
				ret.set( CLIP_LOOP_STOP );
				return false;
			}
		}

		childParam.updateMode();
		childParam.updateFps ();

		childParam.setFunc( func.info().name(), func.topNum() );
		childParam.setLineNum( 1 );

		step.set( 0 );
		return true;
	}
	void _termMain( String func, ClipParam childParam, ClipParam? parentParam ){
		if( childParam.fileFlag() ){
			childParam.setFileData( null );

			if( parentParam != null ){
				// 外部関数の引数に指定されている変数の値を更新する
				updateParam( parentParam, childParam );

				// 親プロセスの変数・配列を更新する
				updateParent( parentParam, childParam );
			}
		}

		// 計算結果の値を更新する
		updateAns( childParam );

		if( parentParam != null ){
			parentParam.updateMode();
			parentParam.updateFps ();
		}
	}
	void _termMainCache( ClipFuncData func, ClipParam childParam, ClipParam? parentParam ){
		if( parentParam != null ){
			// 外部関数の引数に指定されている変数の値を更新する
			updateParam( parentParam, childParam );

			// 親プロセスの変数・配列を更新する
			updateParent( parentParam, childParam );
		}

		// 計算結果の値を更新する
		updateAns( childParam );

		if( parentParam != null ){
			parentParam.updateMode();
			parentParam.updateFps ();
		}
	}
	bool beginMain( dynamic func, ClipParam childParam, ParamInteger step, ParamInteger err, ParamInteger ret, ClipToken? funcParam, ClipParam? parentParam ){
		if( func is ClipFuncData ){
			return _beginMainCache( func, childParam, step, err, ret, funcParam, parentParam );
		}
		return _beginMain( func, childParam, step, err, ret, funcParam, parentParam );
	}
	bool main( dynamic func, ClipParam childParam, ParamInteger step, ParamInteger err, ParamInteger ret ){
		if( func is ClipFuncData ){
			return _procMainCache[step.val()]( this, func, childParam, step, err, ret );
		}
		return _procMain[step.val()]( this, func, childParam, step, err, ret );
	}
	void termMain( dynamic func, ClipParam childParam, ClipParam? parentParam ){
		if( func is ClipFuncData ){
			_termMainCache( func, childParam, parentParam );
		} else {
			_termMain( func, childParam, parentParam );
		}
	}
	String getFuncName( dynamic func ){
		if( func is ClipFuncData ){
			return func.info().name();
		}
		return func;
	}
	MPData mpRound( ClipParam param, MPData val ){
		MPData tmp = MPData();
		if( (param.mode() == CLIP_MODE_I_MULTIPREC) && (_proc_mp.getPrec( val ) > 0) ){
			_proc_mp.ftrunc( tmp, val );
		} else {
			_proc_mp.fset( tmp, val );
			_proc_mp.fround( tmp, param.mpPrec(), param.mpRound() );
		}
		return tmp;
	}
	String mpNum2Str( ClipParam param, MPData val ){
		MPData tmp = mpRound( param, val );
		return _proc_mp.fnum2str( tmp, param.mpPrec() );
	}
	int mpfCmp( ClipParam param, MPData val1, MPData val2 ){
		MPData tmp1 = mpRound( param, val1 );
		MPData tmp2 = mpRound( param, val2 );
		return _proc_mp.fcmp( tmp1, tmp2 );
	}
	void printAns( ClipParam childParam ){
		if( childParam.mpFlag() ){
			printAnsMultiPrec( mpNum2Str( childParam, childParam.array().mp(0) ) );
		} else if( childParam.array().matrix(0).len() > 1 ){
			printAnsMatrix( childParam, childParam.array().makeToken( ClipToken(), 0 ) );
		} else {
			ParamString real = ParamString();
			ParamString imag = ParamString();
			_proc_token.valueToString( childParam, childParam.val( 0 ), real, imag );
			printAnsComplex( real.str(), imag.str() );
		}
	}
	void initInternalProc( ClipProc childProc, ClipFuncData func, ClipParam childParam, ClipParam? parentParam ){
		if( parentParam != null ){
			// 定義定数をコピーする
			parentParam.dupDefine( childParam );

			// ユーザー定義関数を取り込む
			childParam.func().openAll( parentParam.func() );

			childParam.setDefNameSpace( parentParam.defNameSpace() );
		}

		// 関数の引数用変数にラベルを設定する
		childParam.setLabel( func.label() );
	}
	int mainLoop( dynamic func, ClipParam childParam, ClipToken? funcParam, ClipParam? parentParam ){
		resetLoopCount();

		ParamInteger step = ParamInteger();
		ParamInteger err = ParamInteger();
		ParamInteger ret = ParamInteger();
		if( beginMain( func, childParam, step, err, ret, funcParam, parentParam ) ){
			while( main( func, childParam, step, err, ret ) ){}
		}
		termMain( func, childParam, parentParam );
		return ret.val();
	}

	// 外部関数をテストする
	bool beginTest( String func, ClipParam childParam, ParamInteger step, ParamInteger err, ParamInteger ret ){
		return _beginMain( func, childParam, step, err, ret, null, null );
	}
	bool test( String func, ClipParam childParam, ParamInteger step, ParamInteger err, ParamInteger ret ){
		return _procTest[step.val()]( this, func, childParam, step, err, ret );
	}
	void termTest( String func, ClipParam childParam ){
		_termMain( func, childParam, null );
	}
	int testLoop( String func, ClipParam childParam ){
		resetLoopCount();

		ParamInteger step = ParamInteger();
		ParamInteger err = ParamInteger();
		ParamInteger ret = ParamInteger();
		if( beginTest( func, childParam, step, err, ret ) ){
			while( test( func, childParam, step, err, ret ) ){}
		}
		termTest( func, childParam );
		return ret.val();
	}

	int _firstChar( String line ){
		int i = 0;
		if( i < line.length ){
			while( isCharSpace( line, i ) || (charAt( line, i ) == '\t') ){
				i++;
				if( i >= line.length ){
					break;
				}
			}
		}
		return i;
	}
	void _formatFuncName( String format, String funcName, ParamString usage ){
		int i;

		int cur = 0;
		while( true ){
			if( (cur >= format.length) || isCharEnter( format, cur ) ){
				break;
			} else if( isCharEscape( format, cur ) ){
				cur++;
				if( (cur >= format.length) || isCharEnter( format, cur ) ){
					break;
				}
				usage.add( charAt( format, cur ) );
			} else if( charAt( format, cur ) == '-' ){
				for( i = 0; i < funcName.length; i++ ){
					usage.add( charAt( funcName, i ) );
				}
			} else {
				usage.add( charAt( format, cur ) );
			}
			cur++;
		}
	}
	void _addUsage( String format, String funcName ){
		ParamString usage = ParamString();
		ClipProcUsage tmpUsage;

		_formatFuncName( format, funcName, usage );

		if( _topUsage == null ){
			_topUsage = ClipProcUsage();
			_curUsage = _topUsage;
		} else {
			tmpUsage = ClipProcUsage();
			_curUsage!._next = tmpUsage;
			_curUsage = tmpUsage;
		}
		_curUsage!._string = "";
		_curUsage!._string = usage.str();
	}
	void usage( String func, ClipParam childParam, bool cacheFlag ){
		ClipFuncData? curFunc;

		if( (curFunc = procFunc().search( func, false, null )) == null ){
			if( cacheFlag ){
				curFunc = newFuncCache( func, childParam, null );
			}
		}

		_topUsage = null;

		if( curFunc != null ){
			ClipLineData? line;
			curFunc.line().beginGetLine();
			while( (line = curFunc.line().getLine()) != null ){
				if( (line!.token()!.count() == 0) && (line.comment() != null) ){
					if( charAt( line.comment()!, 0 ) != '!' ){
						_addUsage( line.comment()!, func );
					}
				} else {
					break;
				}
			}
		} else {
			int cur;

			ParamString func2 = ParamString( func );
			List<String>? fileData = getExtFuncData( func2, null );
			if( fileData == null ){
				_errorProc( CLIP_PROC_ERR_FUNC_OPEN, 0, childParam, CLIP_CODE_EXTFUNC, func );
				return;
			}

			for( int i = 0; i < fileData.length; i++ ){
				String string = fileData[i];
				cur = _firstChar( string );
				if( (cur < string.length) && (charAt( string, cur ) == '#') ){
					cur++;
					if( (cur < string.length) && (charAt( string, cur ) == '!') ){
					} else if( cur >= string.length ){
						_addUsage( "", func );
					} else {
						_addUsage( string.substring( cur ), func );
					}
				} else {
					break;
				}
			}
		}

		doCommandUsage( _topUsage );

		ClipProcUsage? tmpUsage;
		_curUsage = _topUsage;
		while( _curUsage != null ){
			tmpUsage = _curUsage;
			_curUsage = _curUsage!._next;
			if( tmpUsage!._string != null ){
				tmpUsage._string = null;
			}
		}
	}

	void getAns( ClipParam childParam, ClipProcVal value, ClipParam parentParam ){
		if( childParam.ansFlag() ){
			if( childParam.mpFlag() && parentParam.mpFlag() ){
				if( (parentParam.mode() == CLIP_MODE_I_MULTIPREC) && (_proc_mp.getPrec( childParam.array().mp(0) ) > 0) ){
					_proc_mp.ftrunc( value.mp(), childParam.array().mp(0) );
				} else {
					_proc_mp.fset( value.mp(), childParam.array().mp(0) );
				}
			} else {
				if( childParam.mpFlag() ){
					_proc_mp.fset( value.mp(), childParam.array().mp(0) );
				} else {
					value.matAss( childParam.array().matrix(0) );
				}
				_updateMatrix( parentParam, value.mat() );
			}
		} else {
			if( parentParam.subStep() == 0 ){
				parentParam.setAssFlag( true );
			}
		}
	}

	bool _assertProc( int num, ClipParam param ){
		return assertProc(
			param.fileFlag() ? ((param.topNum() > 0) ? num - param.topNum() + 1 : num) : 0,
			(param.funcName() == null) ? "" : param.funcName()
			);
	}
	bool _errorProc( int err, int num, ClipParam param, int code, dynamic token ){
		if( (err & CLIP_PROC_WARN) != 0 ){
			if( !_printWarn ){
				// 警告レベルで、警告メッセージOFFの場合は処理を行わない
				return false;
			}
			errorProc(
				err,
				param.fileFlag() ? ((param.topNum() > 0) ? num - param.topNum() + 1 : num) : 0,
				(param.funcName() == null) ? "" : param.funcName()!,
				_proc_token.tokenString( param, code, token )
				);
		} else if( (err & CLIP_PROC_ERR) != 0 ){
			errorProc(
				err,
				param.fileFlag() ? ((param.topNum() > 0) ? num - param.topNum() + 1 : num) : 0,
				(param.funcName() == null) ? "" : param.funcName()!,
				_proc_token.tokenString( param, code, token )
				);
		} else if( err >= CLIP_ERR_START ){
			errorProc(
				err,
				param.fileFlag() ? ((param.topNum() > 0) ? num - param.topNum() + 1 : num) : 0,
				(param.funcName() == null) ? "" : param.funcName()!,
				""
				);
		}
		return (((err & CLIP_ERROR) != 0) && param.fileFlag());
	}
	void doCommandPlotSub( ClipProc childProc, ClipParam childParam, ClipGraph graph, double start, double end, double step ){
		childProc.setAngType( _angType, false );
		switch( graph.mode() ){
		case CLIP_GRAPH_MODE_RECT:
			childParam.variable().label().setLabel( MATH_CHAR( 'x' ), "x", true );
			graph.setIndex( MATH_CHAR( 'x' ) );
			break;
		case CLIP_GRAPH_MODE_PARAM:
		case CLIP_GRAPH_MODE_POLAR:
			childParam.variable().label().setLabel( MATH_CHAR( 't' ), "t", true );
			graph.setIndex( MATH_CHAR( 't' ) );
			break;
		}
		graph.setStart( start );
		graph.setEnd  ( end   );
		graph.setStep ( step  );
		onStartPlot();
		graph.plot( childProc, childParam );
		onEndPlot();
	}
	void doCommandRePlotSub( ClipProc childProc, ClipParam childParam, ClipGraph graph, double start, double end, double step ){
		childProc.setAngType( _angType, false );
		switch( graph.mode() ){
		case CLIP_GRAPH_MODE_RECT:
			childParam.variable().label().setLabel( MATH_CHAR( 'x' ), "x", true );
			graph.setIndex( MATH_CHAR( 'x' ) );
			break;
		case CLIP_GRAPH_MODE_PARAM:
		case CLIP_GRAPH_MODE_POLAR:
			childParam.variable().label().setLabel( MATH_CHAR( 't' ), "t", true );
			graph.setIndex( MATH_CHAR( 't' ) );
			break;
		}
		graph.setStart( start );
		graph.setEnd  ( end   );
		graph.setStep ( step  );
		onStartRePlot();
		graph.rePlot( childProc, childParam );
		onEndRePlot();
	}

	int _getSeOperand( ClipParam param, int code, dynamic token, ClipProcVal value ){
		if( _curLine.token()!.skipComma() ){
			return _const( param, code, token, value );
		}
		return _retError( CLIP_PROC_ERR_SE_OPERAND, code, token );
	}
	int _skipSeOperand( int code, dynamic token ){
		if( _curLine.token()!.skipComma() ){
			return _constSkip( code, token );
		}
		return _retError( CLIP_PROC_ERR_SE_OPERAND, code, token );
	}

	static int _seNull( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		return CLIP_PROC_ERR_SE_NULL;
	}
	static int _seIncrement( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		if( param.mpFlag() ){
			_proc_mp.fadd( value.mp(), value.mp(), _proc_mp.F( "1.0" ) );
		} else {
			value.mat().addAndAss( 1.0 );
		}
		return CLIP_NO_ERR;
	}
	static int _seDecrement( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		if( param.mpFlag() ){
			_proc_mp.fsub( value.mp(), value.mp(), _proc_mp.F( "1.0" ) );
		} else {
			value.mat().subAndAss( 1.0 );
		}
		return CLIP_NO_ERR;
	}
	static int _seNegative( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				_proc_mp.fneg( value.mp() );
			} else {
				_proc_mp.neg( value.mp() );
			}
		} else {
			value.matAss( value.mat().minus() );
		}
		return CLIP_NO_ERR;
	}
	static int _seComplement( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( ~MATH_INT( tmpValue.mat().mat(0).toFloat() ).toInt() );
		return CLIP_NO_ERR;
	}
	static int _seNot( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( (MATH_INT( tmpValue.mat().mat(0).toFloat() ) == 0) ? 1 : 0 );
		return CLIP_NO_ERR;
	}
	static int _seMinus( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				_proc_mp.fneg( value.mp(), tmpValue.mp() );
			} else {
				_proc_mp.neg( value.mp(), tmpValue.mp() );
			}
		} else {
			value.matAss( tmpValue.mat().minus() );
		}
		return CLIP_NO_ERR;
	}
	static int _seSet( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		return CLIP_NO_ERR;
	}
	static int _seSetC( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		value.mat().mat(0).setImag( tmpValue.mat().mat(0).real() );
		return CLIP_NO_ERR;
	}
	static int _seSetF( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		value.mat().divAndAss( tmpValue.mat().mat(0).toFloat() );
		return CLIP_NO_ERR;
	}
	static int _seSetM( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		List<ClipProcVal> tmpValue = newProcValArray( 2, _this, param );

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue[0] )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue[1] )) != CLIP_NO_ERR ){
			return ret;
		}

		tmpValue[0].mat().divAndAss( tmpValue[1].mat().mat(0).toFloat() );
		value.mat().addAndAss( tmpValue[0].mat().mat(0).toFloat() );
		return CLIP_NO_ERR;
	}
	static int _seMul( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				_proc_mp.fmul( value.mp(), value.mp(), tmpValue.mp(), param.mpPrec() + 1 );
			} else {
				_proc_mp.mul( value.mp(), value.mp(), tmpValue.mp() );
			}
		} else {
			value.mat().mulAndAss( tmpValue.mat() );
		}
		return CLIP_NO_ERR;
	}
	static int _seDiv( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				if( _this._printWarn && (_proc_mp.fcmp( tmpValue.mp(), _proc_mp.F( "0.0" ) ) == 0) ){
					_this._errorProc( CLIP_PROC_WARN_DIV, _this._curLine.num(), param, CLIP_CODE_NULL, null );
				}
				_proc_mp.fdiv2( value.mp(), value.mp(), tmpValue.mp(), param.mpPrec() + 1 );
			} else {
				if( _this._printWarn && (_proc_mp.cmp( tmpValue.mp(), _proc_mp.I( "0" ) ) == 0) ){
					_this._errorProc( CLIP_PROC_WARN_DIV, _this._curLine.num(), param, CLIP_CODE_NULL, null );
				}
				_proc_mp.div( value.mp(), value.mp(), tmpValue.mp() );
			}
		} else {
			if( _this._printWarn && tmpValue.mat().equal( 0.0 ) ){
				_this._errorProc( CLIP_PROC_WARN_DIV, _this._curLine.num(), param, CLIP_CODE_NULL, null );
			}
			value.mat().divAndAss( tmpValue.mat() );
		}
		return CLIP_NO_ERR;
	}
	static int _seMod( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( _proc_mp.getPrec( value.mp() ) > 0 ){
				_proc_mp.ftrunc( value.mp(), value.mp() );
			}
			if( _proc_mp.getPrec( tmpValue.mp() ) > 0 ){
				_proc_mp.ftrunc( tmpValue.mp(), tmpValue.mp() );
			}
			if( _this._printWarn && (_proc_mp.cmp( tmpValue.mp(), _proc_mp.I( "0" ) ) == 0) ){
				_this._errorProc( CLIP_PROC_WARN_DIV, _this._curLine.num(), param, CLIP_CODE_NULL, null );
			}
			_proc_mp.div( MPData(), value.mp(), tmpValue.mp(), value.mp() );
		} else {
			if( _this._printWarn && tmpValue.mat().equal( 0.0 ) ){
				_this._errorProc( CLIP_PROC_WARN_DIV, _this._curLine.num(), param, CLIP_CODE_NULL, null );
			}
			value.mat().modAndAss( tmpValue.mat() );
		}
		return CLIP_NO_ERR;
	}
	static int _seAdd( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				_proc_mp.fadd( value.mp(), value.mp(), tmpValue.mp() );
			} else {
				_proc_mp.add( value.mp(), value.mp(), tmpValue.mp() );
			}
		} else {
			value.mat().addAndAss( tmpValue.mat() );
		}
		return CLIP_NO_ERR;
	}
	static int _seAddS( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		List<ClipProcVal> tmpValue = newProcValArray( 3, _this, param );

		if( (ret = _this._getSeOperand( param, code, token, tmpValue[0] )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue[1] )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue[2] )) != CLIP_NO_ERR ){
			return ret;
		}

		double a = value.mat().mat(0).toFloat() + tmpValue[0].mat().mat(0).toFloat();
		double b = tmpValue[1].mat().mat(0).toFloat();
		double c = tmpValue[2].mat().mat(0).toFloat();
		if( a < b ){
			value.matAss( b );
		} else if( a > c ){
			value.matAss( c );
		} else {
			value.matAss( a );
		}

		return CLIP_NO_ERR;
	}
	static int _seSub( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				_proc_mp.fsub( value.mp(), value.mp(), tmpValue.mp() );
			} else {
				_proc_mp.sub( value.mp(), value.mp(), tmpValue.mp() );
			}
		} else {
			value.mat().subAndAss( tmpValue.mat() );
		}
		return CLIP_NO_ERR;
	}
	static int _seSubS( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		List<ClipProcVal> tmpValue = newProcValArray( 3, _this, param );

		if( (ret = _this._getSeOperand( param, code, token, tmpValue[0] )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue[1] )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue[2] )) != CLIP_NO_ERR ){
			return ret;
		}

		double a = value.mat().mat(0).toFloat() - tmpValue[0].mat().mat(0).toFloat();
		double b = tmpValue[1].mat().mat(0).toFloat();
		double c = tmpValue[2].mat().mat(0).toFloat();
		if( a < b ){
			value.matAss( b );
		} else if( a > c ){
			value.matAss( c );
		} else {
			value.matAss( a );
		}

		return CLIP_NO_ERR;
	}
	static int _sePow( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			int y = MATH_INT( tmpValue.mat().mat(0).toFloat() ).toInt();
			MPData x = MPData();
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				_proc_mp.fset( x, value.mp() );
				for( int i = 1; i < y; i++ ){
					_proc_mp.fmul( value.mp(), value.mp(), x, param.mpPrec() + 1 );
				}
			} else {
				_proc_mp.set( x, value.mp() );
				for( int i = 1; i < y; i++ ){
					_proc_mp.mul( value.mp(), value.mp(), x );
				}
			}
		} else {
			value.matAss( value.mat().mat(0).pow( tmpValue.mat().mat(0) ) );
		}
		return CLIP_NO_ERR;
	}
	static int _seShiftL( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( MATH_SHIFTL( MATH_INT( value.mat().mat(0).toFloat() ), MATH_INT( tmpValue.mat().mat(0).toFloat() ) ) );
		return CLIP_NO_ERR;
	}
	static int _seShiftR( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( MATH_SHIFTR( MATH_INT( value.mat().mat(0).toFloat() ), MATH_INT( tmpValue.mat().mat(0).toFloat() ) ) );
		return CLIP_NO_ERR;
	}
	static int _seAND( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( MATH_AND( MATH_INT( value.mat().mat(0).toFloat() ), MATH_INT( tmpValue.mat().mat(0).toFloat() ) ) );
		return CLIP_NO_ERR;
	}
	static int _seOR( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( MATH_OR( MATH_INT( value.mat().mat(0).toFloat() ), MATH_INT( tmpValue.mat().mat(0).toFloat() ) ) );
		return CLIP_NO_ERR;
	}
	static int _seXOR( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( MATH_XOR( MATH_INT( value.mat().mat(0).toFloat() ), MATH_INT( tmpValue.mat().mat(0).toFloat() ) ) );
		return CLIP_NO_ERR;
	}
	static int _seLess( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				value.matAss( (_this.mpfCmp( param, value.mp(), tmpValue.mp() ) < 0) ? 1 : 0 );
			} else {
				value.matAss( (_proc_mp.cmp( value.mp(), tmpValue.mp() ) < 0) ? 1 : 0 );
			}
		} else {
			value.matAss( (value.mat().mat(0).toFloat() < tmpValue.mat().mat(0).toFloat()) ? 1 : 0 );
		}
		return CLIP_NO_ERR;
	}
	static int _seLessOrEq( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				value.matAss( (_this.mpfCmp( param, value.mp(), tmpValue.mp() ) <= 0) ? 1 : 0 );
			} else {
				value.matAss( (_proc_mp.cmp( value.mp(), tmpValue.mp() ) <= 0) ? 1 : 0 );
			}
		} else {
			value.matAss( (value.mat().mat(0).toFloat() <= tmpValue.mat().mat(0).toFloat()) ? 1 : 0 );
		}
		return CLIP_NO_ERR;
	}
	static int _seGreat( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				value.matAss( (_this.mpfCmp( param, value.mp(), tmpValue.mp() ) > 0) ? 1 : 0 );
			} else {
				value.matAss( (_proc_mp.cmp( value.mp(), tmpValue.mp() ) > 0) ? 1 : 0 );
			}
		} else {
			value.matAss( (value.mat().mat(0).toFloat() > tmpValue.mat().mat(0).toFloat()) ? 1 : 0 );
		}
		return CLIP_NO_ERR;
	}
	static int _seGreatOrEq( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				value.matAss( (_this.mpfCmp( param, value.mp(), tmpValue.mp() ) >= 0) ? 1 : 0 );
			} else {
				value.matAss( (_proc_mp.cmp( value.mp(), tmpValue.mp() ) >= 0) ? 1 : 0 );
			}
		} else {
			value.matAss( (value.mat().mat(0).toFloat() >= tmpValue.mat().mat(0).toFloat()) ? 1 : 0 );
		}
		return CLIP_NO_ERR;
	}
	static int _seEqual( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				value.matAss( (_this.mpfCmp( param, value.mp(), tmpValue.mp() ) == 0) ? 1 : 0 );
			} else {
				value.matAss( (_proc_mp.cmp( value.mp(), tmpValue.mp() ) == 0) ? 1 : 0 );
			}
		} else {
			value.matAss( value.mat().equal( tmpValue.mat() ) ? 1 : 0 );
		}
		return CLIP_NO_ERR;
	}
	static int _seNotEqual( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				value.matAss( (_this.mpfCmp( param, value.mp(), tmpValue.mp() ) != 0) ? 1 : 0 );
			} else {
				value.matAss( (_proc_mp.cmp( value.mp(), tmpValue.mp() ) != 0) ? 1 : 0 );
			}
		} else {
			value.matAss( value.mat().notEqual( tmpValue.mat() ) ? 1 : 0 );
		}
		return CLIP_NO_ERR;
	}
	static int _seLogAND( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;

		if( value.mat().notEqual( 0.0 ) ){
			ClipProcVal tmpValue = ClipProcVal( _this, param );

			if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
				return ret;
			}

			value.matAss( tmpValue.mat().notEqual( 0.0 ) ? 1 : 0 );
		} else {
			if( (ret = _this._skipSeOperand( code, token )) != CLIP_NO_ERR ){
				return ret;
			}

			value.matAss( 0 );
		}
		return CLIP_NO_ERR;
	}
	static int _seLogOR( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;

		if( value.mat().notEqual( 0.0 ) ){
			if( (ret = _this._skipSeOperand( code, token )) != CLIP_NO_ERR ){
				return ret;
			}

			value.matAss( 1 );
		} else {
			ClipProcVal tmpValue = ClipProcVal( _this, param );

			if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
				return ret;
			}

			value.matAss( tmpValue.mat().notEqual( 0.0 ) ? 1 : 0 );
		}
		return CLIP_NO_ERR;
	}
	static int _seMulAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				_proc_mp.fmul( value.mp(), value.mp(), tmpValue.mp(), param.mpPrec() + 1 );
			} else {
				_proc_mp.mul( value.mp(), value.mp(), tmpValue.mp() );
			}
		} else {
			value.mat().mulAndAss( tmpValue.mat() );
		}
		return CLIP_NO_ERR;
	}
	static int _seDivAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				if( _this._printWarn && (_proc_mp.fcmp( tmpValue.mp(), _proc_mp.F( "0.0" ) ) == 0) ){
					_this._errorProc( CLIP_PROC_WARN_DIV, _this._curLine.num(), param, CLIP_CODE_NULL, null );
				}
				_proc_mp.fdiv2( value.mp(), value.mp(), tmpValue.mp(), param.mpPrec() + 1 );
			} else {
				if( _this._printWarn && (_proc_mp.cmp( tmpValue.mp(), _proc_mp.I( "0" ) ) == 0) ){
					_this._errorProc( CLIP_PROC_WARN_DIV, _this._curLine.num(), param, CLIP_CODE_NULL, null );
				}
				_proc_mp.div( value.mp(), value.mp(), tmpValue.mp() );
			}
		} else {
			if( _this._printWarn && tmpValue.mat().equal( 0.0 ) ){
				_this._errorProc( CLIP_PROC_WARN_DIV, _this._curLine.num(), param, CLIP_CODE_NULL, null );
			}
			value.mat().divAndAss( tmpValue.mat() );
		}
		return CLIP_NO_ERR;
	}
	static int _seModAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( _proc_mp.getPrec( value.mp() ) > 0 ){
				_proc_mp.ftrunc( value.mp(), value.mp() );
			}
			if( _proc_mp.getPrec( tmpValue.mp() ) > 0 ){
				_proc_mp.ftrunc( tmpValue.mp(), tmpValue.mp() );
			}
			if( _this._printWarn && (_proc_mp.cmp( tmpValue.mp(), _proc_mp.I( "0" ) ) == 0) ){
				_this._errorProc( CLIP_PROC_WARN_DIV, _this._curLine.num(), param, CLIP_CODE_NULL, null );
			}
			_proc_mp.div( MPData(), value.mp(), tmpValue.mp(), value.mp() );
		} else {
			if( _this._printWarn && tmpValue.mat().equal( 0.0 ) ){
				_this._errorProc( CLIP_PROC_WARN_DIV, _this._curLine.num(), param, CLIP_CODE_NULL, null );
			}
			value.mat().modAndAss( tmpValue.mat() );
		}
		return CLIP_NO_ERR;
	}
	static int _seAddAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				_proc_mp.fadd( value.mp(), value.mp(), tmpValue.mp() );
			} else {
				_proc_mp.add( value.mp(), value.mp(), tmpValue.mp() );
			}
		} else {
			value.mat().addAndAss( tmpValue.mat() );
		}
		return CLIP_NO_ERR;
	}
	static int _seAddSAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		List<ClipProcVal> tmpValue = newProcValArray( 3, _this, param );

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue[0] )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue[1] )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue[2] )) != CLIP_NO_ERR ){
			return ret;
		}

		double a = value.mat().mat(0).toFloat() + tmpValue[0].mat().mat(0).toFloat();
		double b = tmpValue[1].mat().mat(0).toFloat();
		double c = tmpValue[2].mat().mat(0).toFloat();
		if( a < b ){
			value.matAss( b );
		} else if( a > c ){
			value.matAss( c );
		} else {
			value.matAss( a );
		}

		return CLIP_NO_ERR;
	}
	static int _seSubAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				_proc_mp.fsub( value.mp(), value.mp(), tmpValue.mp() );
			} else {
				_proc_mp.sub( value.mp(), value.mp(), tmpValue.mp() );
			}
		} else {
			value.mat().subAndAss( tmpValue.mat() );
		}
		return CLIP_NO_ERR;
	}
	static int _seSubSAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int  ret;
		List<ClipProcVal> tmpValue = newProcValArray( 3, _this, param );

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue[0] )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue[1] )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue[2] )) != CLIP_NO_ERR ){
			return ret;
		}

		double a = value.mat().mat(0).toFloat() - tmpValue[0].mat().mat(0).toFloat();
		double b = tmpValue[1].mat().mat(0).toFloat();
		double c = tmpValue[2].mat().mat(0).toFloat();
		if( a < b ){
			value.matAss( b );
		} else if( a > c ){
			value.matAss( c );
		} else {
			value.matAss( a );
		}

		return CLIP_NO_ERR;
	}
	static int _sePowAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			int y = MATH_INT( tmpValue.mat().mat(0).toFloat() ).toInt();
			MPData x = MPData();
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				_proc_mp.fset( x, value.mp() );
				for( int i = 1; i < y; i++ ){
					_proc_mp.fmul( value.mp(), value.mp(), x, param.mpPrec() + 1 );
				}
			} else {
				_proc_mp.set( x, value.mp() );
				for( int i = 1; i < y; i++ ){
					_proc_mp.mul( value.mp(), value.mp(), x );
				}
			}
		} else {
			value.matAss( value.mat().mat(0).pow( tmpValue.mat().mat(0) ) );
		}
		return CLIP_NO_ERR;
	}
	static int _seShiftLAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( MATH_SHIFTL( MATH_INT( value.mat().mat(0).toFloat() ), MATH_INT( tmpValue.mat().mat(0).toFloat() ) ) );
		return CLIP_NO_ERR;
	}
	static int _seShiftRAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( MATH_SHIFTR( MATH_INT( value.mat().mat(0).toFloat() ), MATH_INT( tmpValue.mat().mat(0).toFloat() ) ) );
		return CLIP_NO_ERR;
	}
	static int _seANDAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( MATH_AND( MATH_INT( value.mat().mat(0).toFloat() ), MATH_INT( tmpValue.mat().mat(0).toFloat() ) ) );
		return CLIP_NO_ERR;
	}
	static int _seORAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( MATH_OR( MATH_INT( value.mat().mat(0).toFloat() ), MATH_INT( tmpValue.mat().mat(0).toFloat() ) ) );
		return CLIP_NO_ERR;
	}
	static int _seXORAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( MATH_XOR( MATH_INT( value.mat().mat(0).toFloat() ), MATH_INT( tmpValue.mat().mat(0).toFloat() ) ) );
		return CLIP_NO_ERR;
	}
	static int _seLessAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				value.matAss( (_this.mpfCmp( param, value.mp(), tmpValue.mp() ) < 0) ? 1 : 0 );
			} else {
				value.matAss( (_proc_mp.cmp( value.mp(), tmpValue.mp() ) < 0) ? 1 : 0 );
			}
		} else {
			value.matAss( (value.mat().mat(0).toFloat() < tmpValue.mat().mat(0).toFloat()) ? 1 : 0 );
		}
		return CLIP_NO_ERR;
	}
	static int _seLessOrEqAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				value.matAss( (_this.mpfCmp( param, value.mp(), tmpValue.mp() ) <= 0) ? 1 : 0 );
			} else {
				value.matAss( (_proc_mp.cmp( value.mp(), tmpValue.mp() ) <= 0) ? 1 : 0 );
			}
		} else {
			value.matAss( (value.mat().mat(0).toFloat() <= tmpValue.mat().mat(0).toFloat()) ? 1 : 0 );
		}
		return CLIP_NO_ERR;
	}
	static int _seGreatAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				value.matAss( (_this.mpfCmp( param, value.mp(), tmpValue.mp() ) > 0) ? 1 : 0 );
			} else {
				value.matAss( (_proc_mp.cmp( value.mp(), tmpValue.mp() ) > 0) ? 1 : 0 );
			}
		} else {
			value.matAss( (value.mat().mat(0).toFloat() > tmpValue.mat().mat(0).toFloat()) ? 1 : 0 );
		}
		return CLIP_NO_ERR;
	}
	static int _seGreatOrEqAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				value.matAss( (_this.mpfCmp( param, value.mp(), tmpValue.mp() ) >= 0) ? 1 : 0 );
			} else {
				value.matAss( (_proc_mp.cmp( value.mp(), tmpValue.mp() ) >= 0) ? 1 : 0 );
			}
		} else {
			value.matAss( (value.mat().mat(0).toFloat() >= tmpValue.mat().mat(0).toFloat()) ? 1 : 0 );
		}
		return CLIP_NO_ERR;
	}
	static int _seEqualAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				value.matAss( (_this.mpfCmp( param, value.mp(), tmpValue.mp() ) == 0) ? 1 : 0 );
			} else {
				value.matAss( (_proc_mp.cmp( value.mp(), tmpValue.mp() ) == 0) ? 1 : 0 );
			}
		} else {
			value.matAss( value.mat().equal( tmpValue.mat() ) ? 1 : 0 );
		}
		return CLIP_NO_ERR;
	}
	static int _seNotEqualAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				value.matAss( (_this.mpfCmp( param, value.mp(), tmpValue.mp() ) != 0) ? 1 : 0 );
			} else {
				value.matAss( (_proc_mp.cmp( value.mp(), tmpValue.mp() ) != 0) ? 1 : 0 );
			}
		} else {
			value.matAss( value.mat().notEqual( tmpValue.mat() ) ? 1 : 0 );
		}
		return CLIP_NO_ERR;
	}
	static int _seLogANDAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		if( value.mat().notEqual( 0.0 ) ){
			ClipProcVal tmpValue = ClipProcVal( _this, param );

			if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
				return ret;
			}

			value.matAss( tmpValue.mat().notEqual( 0.0 ) ? 1 : 0 );
		} else {
			if( (ret = _this._skipSeOperand( code, token )) != CLIP_NO_ERR ){
				return ret;
			}

			value.matAss( 0 );
		}
		return CLIP_NO_ERR;
	}
	static int _seLogORAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		if( value.mat().notEqual( 0.0 ) ){
			if( (ret = _this._skipSeOperand( code, token )) != CLIP_NO_ERR ){
				return ret;
			}

			value.matAss( 1 );
		} else {
			var tmpValue = ClipProcVal( _this, param );

			if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
				return ret;
			}

			value.matAss( tmpValue.mat().notEqual( 0.0 ) ? 1 : 0 );
		}
		return CLIP_NO_ERR;
	}
	static int _seConditional( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );
		if( (ret = _this._getSeOperand( param, code, token, tmpValue )) == CLIP_NO_ERR ){
			if( tmpValue.mat().notEqual( 0.0 ) ){
				if( (ret = _this._getSeOperand( param, code, token, value )) == CLIP_NO_ERR ){
					ret = _this._skipSeOperand( code, token );
				}
			} else {
				if( (ret = _this._skipSeOperand( code, token )) == CLIP_NO_ERR ){
					ret = _this._getSeOperand( param, code, token, value );
				}
			}
		}
		return ret;
	}
	static int _seSetFALSE( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		value.matAss( 0 );
		return CLIP_NO_ERR;
	}
	static int _seSetTRUE( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		value.matAss( 1 );
		return CLIP_NO_ERR;
	}
	static int _seSetZero( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		if( param.mpFlag() ){
			_proc_mp.fset( value.mp(), _proc_mp.F( "0.0" ) );
		} else {
			value.matAss( 0.0 );
		}
		return CLIP_NO_ERR;
	}
	static int _seSaturate( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		List<ClipProcVal> tmpValue = newProcValArray( 2, _this, param );

		if( (ret = _this._getSeOperand( param, code, token, tmpValue[0] )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue[1] )) != CLIP_NO_ERR ){
			return ret;
		}

		double a = value.mat().mat(0).toFloat();
		double b = tmpValue[0].mat().mat(0).toFloat();
		double c = tmpValue[1].mat().mat(0).toFloat();
		if( a < b ){
			value.matAss( b );
		} else if( a > c ){
			value.matAss( c );
		}

		return CLIP_NO_ERR;
	}
	static int _seSetS( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		List<ClipProcVal> tmpValue = newProcValArray( 2, _this, param );

		if( (ret = _this._getSeOperand( param, code, token, value )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue[0] )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getSeOperand( param, code, token, tmpValue[1] )) != CLIP_NO_ERR ){
			return ret;
		}

		double a = value.mat().mat(0).toFloat();
		double b = tmpValue[0].mat().mat(0).toFloat();
		double c = tmpValue[1].mat().mat(0).toFloat();
		if( a < b ){
			value.matAss( b );
		} else if( a > c ){
			value.matAss( c );
		}

		return CLIP_NO_ERR;
	}

	void mpPow( ClipParam param, MPData ret, MPData x, int y ){
		x = _proc_mp.clone( x );
		if( param.mode() == CLIP_MODE_F_MULTIPREC ){
/*
			_proc_mp.fset( ret, x );
			for( int i = 1; i < y; i++ ){
				_proc_mp.fmul( ret, ret, x, param.mpPrec() + 1 );
			}
*/
			_proc_mp.fset( ret, _proc_mp.F( "1.0" ) );
			while( y > 0 ){
				if( (y % 2) == 0 ){
					_proc_mp.fmul( x, x, x, param.mpPrec() + 1 );
					y = y ~/ 2;
				} else {
					_proc_mp.fmul( ret, ret, x, param.mpPrec() + 1 );
					y--;
				}
			}
		} else {
/*
			_proc_mp.set( ret, x );
			for( int i = 1; i < y; i++ ){
				_proc_mp.mul( ret, ret, x );
			}
*/
			_proc_mp.set( ret, _proc_mp.I( "1" ) );
			while( y > 0 ){
				if( (y % 2) == 0 ){
					_proc_mp.mul( x, x, x );
					y = y ~/ 2;
				} else {
					_proc_mp.mul( ret, ret, x );
					y--;
				}
			}
		}
	}
	MPData _mpCombination( int n, int r ){
		MPData ret;

		ret = MPData();
		if( n < r ){
			_proc_mp.set( ret, _proc_mp.I( "0" ) );
			return ret;
		}
		if( n - r < r ) r = n - r;
		if( r == 0 ){
			_proc_mp.set( ret, _proc_mp.I( "1" ) );
			return ret;
		}
		if( r == 1 ){
			_proc_mp.str2num( ret, "$n" );
			return ret;
		}

		List<int> numer = List.filled( r, 0 );
		List<int> denom = List.filled( r, 0 );

		int i, k;
		int pivot;
		int offset;

		for( i = 0; i < r; i++ ){
			numer[i] = n - r + i + 1;
			denom[i] = i + 1;
		}

		for( k = 2; k <= r; k++ ){
			pivot = denom[k - 1];
			if( pivot > 1 ){
				offset = MATH_IMOD( n - r, k );
				for( i = k - 1; i < r; i += k ){
					numer[i - offset] = numer[i - offset] ~/ pivot;
					denom[i] = denom[i] ~/ pivot;
				}
			}
		}

		ret = MPData();
		_proc_mp.set( ret, _proc_mp.I( "1" ) );
		MPData ii = MPData();
		for( i = 0; i < r; i++ ){
			if( numer[i] > 1 ){
				_proc_mp.str2num( ii, "${numer[i]}" );
				_proc_mp.mul( ret, ret, ii );
			}
		}
		return ret;
	}
	MPData _mpFactorial( int n ){
		if( n == 0 ){
			MPData ret = MPData();
			_proc_mp.set( ret, _proc_mp.I( "1" ) );
			return ret;
		}
		MPData value = _mpFactorial( n ~/ 2 );
		_proc_mp.mul( value, value, value );
		_proc_mp.mul( value, value, _mpCombination( n, n ~/ 2 ) );
		if( (n & 1) != 0 ){
			MPData tmp = MPData();
			_proc_mp.str2num( tmp, "${(n + 1) ~/ 2}" );
			_proc_mp.mul( value, value, tmp );
		}
		return value;
	}
	void mpFactorial( MPData ret, int x ){
		bool m = false;
		if( x < 0 ){
			m = true;
			x = 0 - x;
		}
//		_proc_mp.str2num( ret, "1" );
//		MPData ii = MPData();
//		for( int i = 2; i <= x; i++ ){
//			_proc_mp.str2num( ii, "$i" );
//			_proc_mp.mul( ret, ret, ii );
//		}
		_proc_mp.set( ret, _mpFactorial( x ) );
		if( m ){
			_proc_mp.neg( ret );
		}
	}

	int _getFuncParam( ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;

		if( seFlag ){
			if( !(_curLine.token()!.skipComma()) ){
				return _retError( CLIP_PROC_ERR_SE_OPERAND, code, token );
			}
		}

		ret = _const( param, code, token, value );
		if( ret == CLIP_PROC_ERR_RVALUE_NULL ){
			return _retError( CLIP_PROC_ERR_FUNCTION, code, token );
		}
		return ret;
	}
	int _getFuncParamIndex( ClipParam param, int code, dynamic token, _ClipIndex index, ParamBoolean moveFlag, bool seFlag ){
		dynamic newToken;

		if( seFlag ){
			if( !(_curLine.token()!.skipComma()) ){
				return _retError( CLIP_PROC_ERR_SE_OPERAND, code, token );
			}
		}

		if( !(_curLine.token()!.getTokenParam( param )) ){
			return _retError( CLIP_PROC_ERR_FUNCTION, code, token );
		}
		newToken = getToken();
		switch( getCode() ){
		case CLIP_CODE_VARIABLE:
			index.set( param, varIndexParam( param, newToken ) );
			moveFlag.set( true );
			break;
		case CLIP_CODE_GLOBAL_VAR:
			param = globalParam();
			// そのまま下に流す
			continue case_CLIP_CODE_AUTO_VAR;
		case_CLIP_CODE_AUTO_VAR:
		case CLIP_CODE_AUTO_VAR:
			index.set( param, autoVarIndex( param, newToken ) );
			moveFlag.set( false );
			break;
		default:
			return _retError( CLIP_PROC_ERR_FUNCTION, code, token );
		}

		return CLIP_NO_ERR;
	}
	_ClipIndex? _getFuncParamArray( ClipParam param, int code, dynamic token, ParamBoolean moveFlag, bool seFlag ){
		ClipTokenData? lock = _curLine.token()!.lock();
		if( seFlag ){
			if( !(_curLine.token()!.skipComma()) ){
				_curLine.token()!.unlock( lock );
				return null;
			}
		}
		_ClipIndex index = _ClipIndex();
		if( _curLine.token()!.getTokenParam( param ) ){
			int newCode  = getCode();
			dynamic newToken = getToken();
			switch( newCode ){
			case CLIP_CODE_GLOBAL_ARRAY:
				param = globalParam();
				// そのまま下に流す
				continue case_CLIP_CODE_ARRAY;
			case_CLIP_CODE_ARRAY:
			case CLIP_CODE_ARRAY:
			case CLIP_CODE_AUTO_ARRAY:
				index.set( param, arrayIndexIndirectMove( param, newCode, newToken, moveFlag ) );
				break;
			case CLIP_CODE_LABEL:
			case CLIP_CODE_GLOBAL_VAR:
				index.set( param, param.array().label().checkLabel( newToken ) );
				moveFlag.set( false );
				break;
			default:
				_curLine.token()!.unlock( lock );
				return null;
			}
		} else {
			_curLine.token()!.unlock( lock );
			return null;
		}
		if( index._index < 0 ){
			return null;
		}
		return index;
	}

	static int _funcDefined( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int newCode;

		if( seFlag ){
			if( !(_this._curLine.token()!.skipComma()) ){
				return _this._retError( CLIP_PROC_ERR_SE_OPERAND, code, token );
			}
		}

		if( _this._curLine.token()!.getTokenParam( param ) ){
			newCode = getCode();
			value.matAss( ((newCode == CLIP_CODE_LABEL) || (newCode == CLIP_CODE_GLOBAL_VAR) || (newCode == CLIP_CODE_GLOBAL_ARRAY)) ? 0.0 : 1.0 );
			return CLIP_NO_ERR;
		}

		return _this._retError( CLIP_PROC_ERR_FUNCTION, code, token );
	}
	static int _funcIndexOf( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int newToken;

		if( seFlag ){
			if( !(_this._curLine.token()!.skipComma()) ){
				return _this._retError( CLIP_PROC_ERR_SE_OPERAND, code, token );
			}
		}

		if( _this._curLine.token()!.getTokenParam( param ) ){
			newToken = getToken();
			switch( getCode() ){
			case CLIP_CODE_AUTO_VAR:
				value.matAss( _this.autoVarIndex( param, newToken ) );
				return CLIP_NO_ERR;
			case CLIP_CODE_AUTO_ARRAY:
				value.matAss( _this.autoArrayIndex( param, newToken ) );
				return CLIP_NO_ERR;
			case CLIP_CODE_GLOBAL_VAR:
			case CLIP_CODE_GLOBAL_ARRAY:
				break;
			}
		}

		return _this._retError( CLIP_PROC_ERR_FUNCTION, code, token );
	}
	static int _funcIsInf( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( MATH_ISINF( tmpValue.mat().mat(0).toFloat() ) ? 1.0 : 0.0 );
		return CLIP_NO_ERR;
	}
	static int _funcIsNaN( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( MATH_ISNAN( tmpValue.mat().mat(0).toFloat() ) ? 1.0 : 0.0 );
		return CLIP_NO_ERR;
	}
	static int _funcRand( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		value.matAss( MATH_RAND() );
		return CLIP_NO_ERR;
	}
	static int _funcTime( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		value.matAss( DateTime.now().millisecondsSinceEpoch ~/ 1000 );
		return CLIP_NO_ERR;
	}
	static int _funcMkTime( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int i;
		ParamString? format = ParamString();
		bool errFlag;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( seFlag ){
			if( !(_this._curLine.token()!.skipComma()) ){
				return _this._retError( CLIP_PROC_ERR_SE_OPERAND, code, token );
			}
		}

		// 書式制御文字列の取得
		_this._getString( param, format );
		if( format.isNull() ){
			return _this._retError( CLIP_PROC_ERR_STRING, code, token );
		}

		Tm tm = Tm();
		int t = tm.time();
		tm.localtime( t );

		errFlag = false;
		for( i = 0; i < format.str().length; i++ ){
			if( charAt( format.str(), i ) == '%' ){
				i++;
				if( i >= format.str().length ){
					errFlag = true;
					break;
				}

				if( _this._getFuncParam( param, code, token, tmpValue, seFlag ) != CLIP_NO_ERR ){
					errFlag = true;
					break;
				}

				switch( charAt( format.str(), i ) ){
				case 's': tm.sec  = MATH_INT( tmpValue.mat().mat(0).toFloat() ).toInt(); break;
				case 'm': tm.min  = MATH_INT( tmpValue.mat().mat(0).toFloat() ).toInt(); break;
				case 'h': tm.hour = MATH_INT( tmpValue.mat().mat(0).toFloat() ).toInt(); break;
				case 'D': tm.mday = MATH_INT( tmpValue.mat().mat(0).toFloat() ).toInt(); break;
				case 'M': tm.mon  = MATH_INT( tmpValue.mat().mat(0).toFloat() ).toInt(); break;
				case 'Y': tm.year = MATH_INT( tmpValue.mat().mat(0).toFloat() ).toInt(); break;
				case 'w': tm.wday = MATH_INT( tmpValue.mat().mat(0).toFloat() ).toInt(); break;
				case 'y': tm.yday = MATH_INT( tmpValue.mat().mat(0).toFloat() ).toInt(); break;
				default:
					errFlag = true;
					break;
				}

				if( errFlag ){
					break;
				}
			}
		}

		// 書式制御文字列の解放
		format = null;

		if( errFlag ){
			return _this._retError( CLIP_PROC_ERR_FUNCTION, code, token );
		}

		value.matAss( tm.mktime() );

		return CLIP_NO_ERR;
	}
	static int _funcTmSec( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		Tm tm = Tm();
		int t = tm.time();
		value.matAss( tm.localtime( t ).sec );
		return CLIP_NO_ERR;
	}
	static int _funcTmMin( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		Tm tm = Tm();
		int t = tm.time();
		value.matAss( tm.localtime( t ).min );
		return CLIP_NO_ERR;
	}
	static int _funcTmHour( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		Tm tm = Tm();
		int t = tm.time();
		value.matAss( tm.localtime( t ).hour );
		return CLIP_NO_ERR;
	}
	static int _funcTmMDay( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		Tm tm = Tm();
		int t = tm.time();
		value.matAss( tm.localtime( t ).mday );
		return CLIP_NO_ERR;
	}
	static int _funcTmMon( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		Tm tm = Tm();
		int t = tm.time();
		value.matAss( tm.localtime( t ).mon );
		return CLIP_NO_ERR;
	}
	static int _funcTmYear( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		Tm tm = Tm();
		int t = tm.time();
		value.matAss( tm.localtime( t ).year );
		return CLIP_NO_ERR;
	}
	static int _funcTmWDay( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		Tm tm = Tm();
		int t = tm.time();
		value.matAss( tm.localtime( t ).wday );
		return CLIP_NO_ERR;
	}
	static int _funcTmYDay( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		Tm tm = Tm();
		int t = tm.time();
		value.matAss( tm.localtime( t ).yday );
		return CLIP_NO_ERR;
	}
	static int _funcTmXMon( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		Tm tm = Tm();
		int t = tm.time();
		value.matAss( tm.localtime( t ).mon + 1 );
		return CLIP_NO_ERR;
	}
	static int _funcTmXYear( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		Tm tm = Tm();
		int t = tm.time();
		value.matAss( 1900 + tm.localtime( t ).year );
		return CLIP_NO_ERR;
	}
	static int _funcA2D( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;

		if( (ret = _this._getFuncParam( param, code, token, value, seFlag )) != CLIP_NO_ERR ){
			return ret;

		}

		value.mat().mat(0).angToAng( complexAngType(), MATH_ANG_TYPE_DEG );
		return CLIP_NO_ERR;
	}
	static int _funcA2G( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;

		if( (ret = _this._getFuncParam( param, code, token, value, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.mat().mat(0).angToAng( complexAngType(), MATH_ANG_TYPE_GRAD );
		return CLIP_NO_ERR;
	}
	static int _funcA2R( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;

		if( (ret = _this._getFuncParam( param, code, token, value, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.mat().mat(0).angToAng( complexAngType(), MATH_ANG_TYPE_RAD );
		return CLIP_NO_ERR;
	}
	static int _funcD2A( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;

		if( (ret = _this._getFuncParam( param, code, token, value, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.mat().mat(0).angToAng( MATH_ANG_TYPE_DEG, complexAngType() );
		return CLIP_NO_ERR;
	}
	static int _funcD2G( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;

		if( (ret = _this._getFuncParam( param, code, token, value, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.mat().mat(0).angToAng( MATH_ANG_TYPE_DEG, MATH_ANG_TYPE_GRAD );
		return CLIP_NO_ERR;
	}
	static int _funcD2R( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;

		if( (ret = _this._getFuncParam( param, code, token, value, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.mat().mat(0).angToAng( MATH_ANG_TYPE_DEG, MATH_ANG_TYPE_RAD );
		return CLIP_NO_ERR;
	}
	static int _funcG2A( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;

		if( (ret = _this._getFuncParam( param, code, token, value, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.mat().mat(0).angToAng( MATH_ANG_TYPE_GRAD, complexAngType() );
		return CLIP_NO_ERR;
	}
	static int _funcG2D( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;

		if( (ret = _this._getFuncParam( param, code, token, value, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.mat().mat(0).angToAng( MATH_ANG_TYPE_GRAD, MATH_ANG_TYPE_DEG );
		return CLIP_NO_ERR;
	}
	static int _funcG2R( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;

		if( (ret = _this._getFuncParam( param, code, token, value, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.mat().mat(0).angToAng( MATH_ANG_TYPE_GRAD, MATH_ANG_TYPE_RAD );
		return CLIP_NO_ERR;
	}
	static int _funcR2A( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;

		if( (ret = _this._getFuncParam( param, code, token, value, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.mat().mat(0).angToAng( MATH_ANG_TYPE_RAD, complexAngType() );
		return CLIP_NO_ERR;
	}
	static int _funcR2D( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;

		if( (ret = _this._getFuncParam( param, code, token, value, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.mat().mat(0).angToAng( MATH_ANG_TYPE_RAD, MATH_ANG_TYPE_DEG );
		return CLIP_NO_ERR;
	}
	static int _funcR2G( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;

		if( (ret = _this._getFuncParam( param, code, token, value, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.mat().mat(0).angToAng( MATH_ANG_TYPE_RAD, MATH_ANG_TYPE_GRAD );
		return CLIP_NO_ERR;
	}
	static int _funcSin( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( tmpValue.mat().mat(0).sin() );
		return CLIP_NO_ERR;
	}
	static int _funcCos( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( tmpValue.mat().mat(0).cos() );
		return CLIP_NO_ERR;
	}
	static int _funcTan( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( tmpValue.mat().mat(0).tan() );
		return CLIP_NO_ERR;
	}
	static int _funcASin( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( tmpValue.mat().mat(0).asin() );
		if( valueError() ){
			_this._errorProc( CLIP_PROC_WARN_ASIN, _this._curLine.num(), param, CLIP_CODE_NULL, null );
			clearValueError();
		}
		return CLIP_NO_ERR;
	}
	static int _funcACos( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( tmpValue.mat().mat(0).acos() );
		if( valueError() ){
			_this._errorProc( CLIP_PROC_WARN_ACOS, _this._curLine.num(), param, CLIP_CODE_NULL, null );
			clearValueError();
		}
		return CLIP_NO_ERR;
	}
	static int _funcATan( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( tmpValue.mat().mat(0).atan() );
		return CLIP_NO_ERR;
	}
	static int _funcATan2( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		List<ClipProcVal> tmpValue = newProcValArray( 2, _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue[0], seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getFuncParam( param, code, token, tmpValue[1], seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( fatan2( tmpValue[0].mat().mat(0).toFloat(), tmpValue[1].mat().mat(0).toFloat() ) );
		return CLIP_NO_ERR;
	}
	static int _funcSinH( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( tmpValue.mat().mat(0).sinh() );
		return CLIP_NO_ERR;
	}
	static int _funcCosH( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( tmpValue.mat().mat(0).cosh() );
		return CLIP_NO_ERR;
	}
	static int _funcTanH( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( tmpValue.mat().mat(0).tanh() );
		return CLIP_NO_ERR;
	}
	static int _funcASinH( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( tmpValue.mat().mat(0).asinh() );
		return CLIP_NO_ERR;
	}
	static int _funcACosH( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( tmpValue.mat().mat(0).acosh() );
		if( valueError() ){
			_this._errorProc( CLIP_PROC_WARN_ACOSH, _this._curLine.num(), param, CLIP_CODE_NULL, null );
			clearValueError();
		}
		return CLIP_NO_ERR;
	}
	static int _funcATanH( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( tmpValue.mat().mat(0).atanh() );
		if( valueError() ){
			_this._errorProc( CLIP_PROC_WARN_ATANH, _this._curLine.num(), param, CLIP_CODE_NULL, null );
			clearValueError();
		}
		return CLIP_NO_ERR;
	}
	static int _funcExp( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( tmpValue.mat().mat(0).exp() );
		return CLIP_NO_ERR;
	}
	static int _funcExp10( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( tmpValue.mat().mat(0).exp10() );
		return CLIP_NO_ERR;
	}
	static int _funcLn( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( tmpValue.mat().mat(0).log() );
		if( valueError() ){
			_this._errorProc( CLIP_PROC_WARN_LOG, _this._curLine.num(), param, CLIP_CODE_NULL, null );
			clearValueError();
		}
		return CLIP_NO_ERR;
	}
	static int _funcLog( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.isCalculator() ){
			value.matAss( tmpValue.mat().mat(0).log10() );
		} else {
			value.matAss( tmpValue.mat().mat(0).log() );
		}
		if( valueError() ){
			_this._errorProc( param.isCalculator() ? CLIP_PROC_WARN_LOG10 : CLIP_PROC_WARN_LOG, _this._curLine.num(), param, CLIP_CODE_NULL, null );
			clearValueError();
		}
		return CLIP_NO_ERR;
	}
	static int _funcLog10( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( tmpValue.mat().mat(0).log10() );
		if( valueError() ){
			_this._errorProc( CLIP_PROC_WARN_LOG10, _this._curLine.num(), param, CLIP_CODE_NULL, null );
			clearValueError();
		}
		return CLIP_NO_ERR;
	}
	static int _funcPow( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		List<ClipProcVal> tmpValue = newProcValArray( 2, _this, param );

		_ClipIndex? index;
		ParamBoolean moveFlag = ParamBoolean();

		if( param.mpFlag() && ((index = _this._getFuncParamArray( param, code, token, moveFlag, seFlag )) != null) ){
			tmpValue[0]._mp.attach( index!._param!.array().mp(index._index) );
			tmpValue[0].setMpFlag( true );
		} else if( (ret = _this._getFuncParam( param, code, token, tmpValue[0], seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getFuncParam( param, code, token, tmpValue[1], seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			_this.mpPow( param, value.mp(), tmpValue[0].mp(), MATH_INT( tmpValue[1].mat().mat(0).toFloat() ).toInt() );
		} else {
			value.matAss( tmpValue[0].mat().mat(0).pow( tmpValue[1].mat().mat(0) ) );
		}
		return CLIP_NO_ERR;
	}
	static int _funcSqr( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				_proc_mp.fmul( value.mp(), tmpValue.mp(), tmpValue.mp(), param.mpPrec() + 1 );
			} else {
				_proc_mp.mul( value.mp(), tmpValue.mp(), tmpValue.mp() );
			}
		} else {
			value.matAss( tmpValue.mat().mat(0).sqr() );
		}
		return CLIP_NO_ERR;
	}
	static int _funcSqrt( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				if( _proc_mp.fsqrt2( value.mp(), tmpValue.mp(), param.mpPrec() + 1, 4 ) ){
					_this._errorProc( CLIP_PROC_WARN_SQRT, _this._curLine.num(), param, CLIP_CODE_NULL, null );
				}
			} else {
				if( _proc_mp.sqrt( value.mp(), tmpValue.mp() ) ){
					_this._errorProc( CLIP_PROC_WARN_SQRT, _this._curLine.num(), param, CLIP_CODE_NULL, null );
				}
			}
		} else {
			value.matAss( tmpValue.mat().mat(0).sqrt() );
			if( valueError() ){
				_this._errorProc( CLIP_PROC_WARN_SQRT, _this._curLine.num(), param, CLIP_CODE_NULL, null );
				clearValueError();
			}
		}
		return CLIP_NO_ERR;
	}
	static int _funcCeil( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( tmpValue.mat().mat(0).ceil() );
		return CLIP_NO_ERR;
	}
	static int _funcFloor( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( tmpValue.mat().mat(0).floor() );
		return CLIP_NO_ERR;
	}
	static int _funcAbs( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				_proc_mp.fabs( value.mp(), tmpValue.mp() );
			} else {
				_proc_mp.abs( value.mp(), tmpValue.mp() );
			}
		} else {
			value.matAss( tmpValue.mat().mat(0).abs() );
		}
		return CLIP_NO_ERR;
	}
	static int _funcLdexp( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		List<ClipProcVal> tmpValue = newProcValArray( 2, _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue[0], seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getFuncParam( param, code, token, tmpValue[1], seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( tmpValue[0].mat().mat(0).ldexp( MATH_INT( tmpValue[1].mat().mat(0).toFloat() ).toInt() ) );
		return CLIP_NO_ERR;
	}
	static int _funcFrexp( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );
		_ClipIndex index = _ClipIndex();
		ParamBoolean moveFlag = ParamBoolean();

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getFuncParamIndex( param, code, token, index, moveFlag, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		ParamInteger _n = ParamInteger();
		value.matAss( tmpValue.mat().mat(0).frexp( _n ) );
		if( !(index._param!.setVal( index._index, _n.val(), moveFlag.val() )) ){
			return _this._retError( CLIP_PROC_ERR_ASS, code, token );
		}
		return CLIP_NO_ERR;
	}
	static int _funcModf( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );
		_ClipIndex index = _ClipIndex();
		ParamBoolean moveFlag = ParamBoolean();

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getFuncParamIndex( param, code, token, index, moveFlag, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		ParamFloat _f = ParamFloat();
		value.matAss( tmpValue.mat().mat(0).modf( _f ) );
		if( !(index._param!.setVal( index._index, _f.val(), moveFlag.val() )) ){
			return _this._retError( CLIP_PROC_ERR_ASS, code, token );
		}
		return CLIP_NO_ERR;
	}
	static int _funcFact( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			_this.mpFactorial( value.mp(), MATH_INT( tmpValue.mat().mat(0).toFloat() ).toInt() );
		} else {
			value.matAss( tmpValue.mat().mat(0).factorial() );
		}
		return CLIP_NO_ERR;
	}
	static int _funcInt( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		if( param.mpFlag() ){
			if( _proc_mp.getPrec( tmpValue.mp() ) > 0 ){
				_proc_mp.ftrunc( value.mp(), tmpValue.mp() );
			} else {
				_proc_mp.fset( value.mp(), tmpValue.mp() );
			}
		} else {
			value.mat().mat(0).setReal( MATH_INT( tmpValue.mat().mat(0).real() ) );
			value.mat().mat(0).setImag( MATH_INT( tmpValue.mat().mat(0).imag() ) );
		}
		return CLIP_NO_ERR;
	}
	static int _funcReal( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( tmpValue.mat().mat(0).real() );
		return CLIP_NO_ERR;
	}
	static int _funcImag( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( tmpValue.mat().mat(0).imag() );
		return CLIP_NO_ERR;
	}
	static int _funcArg( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( tmpValue.mat().mat(0).farg() );
		return CLIP_NO_ERR;
	}
	static int _funcNorm( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( tmpValue.mat().mat(0).fnorm() );
		return CLIP_NO_ERR;
	}
	static int _funcConjg( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( tmpValue.mat().mat(0).conjg() );
		return CLIP_NO_ERR;
	}
	static int _funcPolar( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		List<ClipProcVal> tmpValue = newProcValArray( 2, _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue[0], seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getFuncParam( param, code, token, tmpValue[1], seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.mat().mat(0).polar( tmpValue[0].mat().mat(0).toFloat(), tmpValue[1].mat().mat(0).toFloat() );
		return CLIP_NO_ERR;
	}
	static int _funcNum( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		if( tmpValue.mat().mat(0).fractMinus() ){
			value.matAss( -tmpValue.mat().mat(0).num() );
		} else {
			value.matAss( tmpValue.mat().mat(0).num() );
		}
		return CLIP_NO_ERR;
	}
	static int _funcDenom( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( tmpValue.mat().mat(0).denom() );
		return CLIP_NO_ERR;
	}
	static int _funcRow( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		_ClipIndex? index;
		ParamBoolean moveFlag = ParamBoolean();

		if( (index = _this._getFuncParamArray( param, code, token, moveFlag, seFlag )) != null ){
			value.matAss( index!._param!.array().matrix(index._index).row().toDouble() );
		} else {
			int ret;
			ClipProcVal tmpValue = ClipProcVal( _this, param );

			if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
				return ret;
			}

			value.matAss( tmpValue.mat().row().toDouble() );
		}
		return CLIP_NO_ERR;
	}
	static int _funcCol( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		_ClipIndex? index;
		ParamBoolean moveFlag = ParamBoolean();

		if( (index = _this._getFuncParamArray( param, code, token, moveFlag, seFlag )) != null ){
			value.matAss( index!._param!.array().matrix(index._index).col().toDouble() );
		} else {
			int ret;
			ClipProcVal tmpValue = ClipProcVal( _this, param );

			if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
				return ret;
			}

			value.matAss( tmpValue.mat().col().toDouble() );
		}
		return CLIP_NO_ERR;
	}
	static int _funcTrans( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		_ClipIndex? index;
		ParamBoolean moveFlag = ParamBoolean();

		if( (index = _this._getFuncParamArray( param, code, token, moveFlag, seFlag )) != null ){
			value.matAss( index!._param!.array().matrix(index._index).trans() );
		} else {
			int ret;
			ClipProcVal tmpValue = ClipProcVal( _this, param );

			if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
				return ret;
			}

			value.matAss( tmpValue.mat().trans() );
		}
		return CLIP_NO_ERR;
	}
	static int _funcStrCmp( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		if( seFlag ){
			if( !(_this._curLine.token()!.skipComma()) ){
				return _this._retError( CLIP_PROC_ERR_SE_OPERAND, code, token );
			}
		}

		ParamString string1 = ParamString();
		if( _this._getString( param, string1 ) ){
			if( seFlag ){
				if( !(_this._curLine.token()!.skipComma()) ){
					return _this._retError( CLIP_PROC_ERR_SE_OPERAND, code, token );
				}
			}

			ParamString string2 = ParamString();
			if( _this._getString( param, string2 ) ){
				String str1 = string1.str();
				String str2 = string2.str();
				int val = str1.length - str2.length;
				if( val == 0 ){
					int i;
					switch( token ){
					case CLIP_FUNC_STRCMP:
						for( i = 0; i < str1.length; i++ ){
							val = charCodeAt( str1, i ) - charCodeAt( str2, i );
							if( val != 0 ){
								break;
							}
						}
						break;
					case CLIP_FUNC_STRICMP:
						int chr1, chr2;
						for( i = 0; i < str1.length; i++ ){
							chr1 = charCodeAt( str1, i );
							if( (chr1 >= MATH_CHAR_CODE_UA) && (chr1 <= MATH_CHAR_CODE_UZ) ){
								chr1 = chr1 - MATH_CHAR_CODE_UA + MATH_CHAR_CODE_LA;
							}
							chr2 = charCodeAt( str2, i );
							if( (chr2 >= MATH_CHAR_CODE_UA) && (chr2 <= MATH_CHAR_CODE_UZ) ){
								chr2 = chr2 - MATH_CHAR_CODE_UA + MATH_CHAR_CODE_LA;
							}
							val = chr1 - chr2;
							if( val != 0 ){
								break;
							}
						}
						break;
					}
				}
				value.matAss( val );
				return CLIP_NO_ERR;
			}
		}
		return _this._retError( CLIP_PROC_ERR_FUNCTION, code, token );
	}
	static int _funcStrLen( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		if( seFlag ){
			if( !(_this._curLine.token()!.skipComma()) ){
				return _this._retError( CLIP_PROC_ERR_SE_OPERAND, code, token );
			}
		}

		ParamString string = ParamString();
		if( _this._getString( param, string ) ){
			value.matAss( string.str().length );
			return CLIP_NO_ERR;
		}
		return _this._retError( CLIP_PROC_ERR_FUNCTION, code, token );
	}
	static int _funcGWidth( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		value.matAss( procGWorld().width().toDouble() );
		return CLIP_NO_ERR;
	}
	static int _funcGHeight( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		value.matAss( procGWorld().height().toDouble() );
		return CLIP_NO_ERR;
	}
	static int _funcGColor( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		if( procGWorld().rgbFlag() ){
			value.matAss( procGWorld().color().toDouble() );
			return CLIP_NO_ERR;
		}

		ClipTokenData? lock;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		lock = _this._curLine.token()!.lock();
		if( _this._getFuncParam( param, code, token, tmpValue, seFlag ) == CLIP_NO_ERR ){
			procGWorld().setColor( doFuncGColor( MATH_UNSIGNED( tmpValue.mat().mat(0).toFloat(), MATH_UMAX_24 ).toInt() ) );
		} else {
			_this._curLine.token()!.unlock( lock );
		}

		value.matAss( (token == CLIP_FUNC_GCOLOR) ? procGWorld().color() : doFuncGColor24( procGWorld().color() ) );
		return CLIP_NO_ERR;
	}
	static int _funcGCX( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		value.matAss( procGWorld().imgMoveX().toDouble() );
		return CLIP_NO_ERR;
	}
	static int _funcGCY( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		value.matAss( procGWorld().imgMoveY().toDouble() );
		return CLIP_NO_ERR;
	}
	static int _funcWCX( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		value.matAss( procGWorld().wndMoveX() );
		return CLIP_NO_ERR;
	}
	static int _funcWCY( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		value.matAss( procGWorld().wndMoveY() );
		return CLIP_NO_ERR;
	}
	static int _funcGGet( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		List<ClipProcVal> tmpValue = newProcValArray( 2, _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue[0], seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getFuncParam( param, code, token, tmpValue[1], seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( procGWorld().get( MATH_INT( tmpValue[0].mat().mat(0).toFloat() ).toInt(), MATH_INT( tmpValue[1].mat().mat(0).toFloat() ).toInt() ) );
		return CLIP_NO_ERR;
	}
	static int _funcWGet( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		List<ClipProcVal> tmpValue = newProcValArray( 2, _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue[0], seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getFuncParam( param, code, token, tmpValue[1], seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( procGWorld().wndGet( tmpValue[0].mat().mat(0).toFloat(), tmpValue[1].mat().mat(0).toFloat() ) );
		return CLIP_NO_ERR;
	}
	static int _funcGX( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( procGWorld().imgPosX( tmpValue.mat().mat(0).toFloat() ) );
		return CLIP_NO_ERR;
	}
	static int _funcGY( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( procGWorld().imgPosY( tmpValue.mat().mat(0).toFloat() ) );
		return CLIP_NO_ERR;
	}
	static int _funcWX( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( procGWorld().wndPosX( MATH_INT( tmpValue.mat().mat(0).toFloat() ).toInt() ) );
		return CLIP_NO_ERR;
	}
	static int _funcWY( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( procGWorld().wndPosY( MATH_INT( tmpValue.mat().mat(0).toFloat() ).toInt() ) );
		return CLIP_NO_ERR;
	}
	static int _funcMkColor( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		List<ClipProcVal> tmpValue = newProcValArray( 3, _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue[0], seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getFuncParam( param, code, token, tmpValue[1], seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getFuncParam( param, code, token, tmpValue[2], seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		int r = MATH_INT( tmpValue[0].mat().mat(0).toFloat() ).toInt();
		int g = MATH_INT( tmpValue[1].mat().mat(0).toFloat() ).toInt();
		int b = MATH_INT( tmpValue[2].mat().mat(0).toFloat() ).toInt();
		value.matAss( MATH_SHIFTL( r.toDouble(), 16 ) + MATH_SHIFTL( g.toDouble(), 8 ) + b );
		return CLIP_NO_ERR;
	}
	static int _funcMkColorS( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		List<ClipProcVal> tmpValue = newProcValArray( 3, _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue[0], seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getFuncParam( param, code, token, tmpValue[1], seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (ret = _this._getFuncParam( param, code, token, tmpValue[2], seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		int r = MATH_INT( tmpValue[0].mat().mat(0).toFloat() ).toInt();
		int g = MATH_INT( tmpValue[1].mat().mat(0).toFloat() ).toInt();
		int b = MATH_INT( tmpValue[2].mat().mat(0).toFloat() ).toInt();
		if( r < 0 ){ r = 0; } else if( r > 255 ){ r = 255; }
		if( g < 0 ){ g = 0; } else if( g > 255 ){ g = 255; }
		if( b < 0 ){ b = 0; } else if( b > 255 ){ b = 255; }
		value.matAss( MATH_SHIFTL( r.toDouble(), 16 ) + MATH_SHIFTL( g.toDouble(), 8 ) + b );
		return CLIP_NO_ERR;
	}
	static int _funcColGetR( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( MATH_SHIFTR( MATH_AND( MATH_INT( tmpValue.mat().mat(0).toFloat() ), 0xFF0000 ), 16 ) );
		return CLIP_NO_ERR;
	}
	static int _funcColGetG( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( MATH_SHIFTR( MATH_AND( MATH_INT( tmpValue.mat().mat(0).toFloat() ), 0x00FF00 ), 8 ) );
		return CLIP_NO_ERR;
	}
	static int _funcColGetB( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		value.matAss( MATH_AND( MATH_INT( tmpValue.mat().mat(0).toFloat() ), 0x0000FF ) );
		return CLIP_NO_ERR;
	}
	static int _funcCall( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;

		if( seFlag ){
			if( !(_this._curLine.token()!.skipComma()) ){
				return _this._retError( CLIP_PROC_ERR_SE_OPERAND, code, token );
			}
		}

		ParamString func = ParamString();
		_this._getString( param, func );
		if( func.isNull() ){
			return _this._retError( CLIP_PROC_ERR_STRING, code, token );
		}

		if( charAt( func.str(), 0 ) == '!' ){
			ret = _procExtFunc( _this, param, CLIP_CODE_EXTFUNC, func.str().substring( 1 ), value, seFlag );
			if( ret != CLIP_NO_ERR ){
				ret = _this._retError( CLIP_PROC_ERR_CALL, code, token );
			}
		} else {
			ParamInteger _func = ParamInteger();
			if( _proc_token.checkFunc( func.str(), _func ) ){
				ret = _procFunc( _this, param, CLIP_CODE_FUNCTION, _func.val(), value, seFlag );
			} else {
				ret = _procLabel( _this, param, CLIP_CODE_LABEL, func.str(), value, seFlag );
				if( ret != CLIP_NO_ERR ){
					ret = _this._retError( CLIP_PROC_ERR_CALL, code, token );
				}
			}
		}
		return ret;
	}
	void initEvalProc( ClipParam childParam, ClipParam parentParam ){
		childParam.setEnableCommand( false );
		childParam.setEnableStat( false );

		// ユーザー定義関数を取り込む
		childParam.func().openAll( parentParam.func() );

		childParam.setDefNameSpace( parentParam.defNameSpace() );
	}
	static int _funcEval( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;

		if( seFlag ){
			if( !(_this._curLine.token()!.skipComma()) ){
				return _this._retError( CLIP_PROC_ERR_SE_OPERAND, code, token );
			}
		}

		ParamString string = ParamString();
		_this._getString( param, string );
		if( string.isNull() ){
			return _this._retError( CLIP_PROC_ERR_STRING, code, token );
		}

		// 親プロセスの環境を受け継いで、子プロセスを実行する
		ClipProc childProc = ClipProc( param.mode(), param.mpPrec(), param.mpRound(), false, _this._printAssert, _this._printWarn, _this._gUpdateFlag );
		ClipParam childParam = ClipParam( _this._curLine.num(), param, true );
		_this.initEvalProc( childParam, param );
		ret = doFuncEval( _this, childProc, childParam, string.str(), value );
		childProc.end();
		childParam.end();

		return (ret == CLIP_NO_ERR) ? CLIP_NO_ERR : _this._retError( CLIP_PROC_ERR_EVAL, code, token );
	}
	int doFuncEvalSub( ClipProc childProc, ClipParam childParam, String string, ClipProcVal value ){
		int ret;
		childProc.setAngType( _angType, false );
		if( (ret = childProc.processLoop( string, childParam )) == CLIP_PROC_END ){
			value.matAss( childParam.array().matrix(0) );
			return CLIP_NO_ERR;
		}
		return ret;
	}
	static int _funcMp( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		bool ret;

		if( seFlag ){
			if( !(_this._curLine.token()!.skipComma()) ){
				return _this._retError( CLIP_PROC_ERR_SE_OPERAND, code, token );
			}
		}

		ParamString string = ParamString();
		_this._getString( param, string );
		if( string.isNull() ){
			return _this._retError( CLIP_PROC_ERR_STRING, code, token );
		}

		if( param.mode() == CLIP_MODE_F_MULTIPREC ){
			ret = _proc_mp.fstr2num( value.mp(), string.str() );
		} else {
			ret = _proc_mp.str2num( value.mp(), string.str() );
		}

		return ret ? CLIP_NO_ERR : _this._retError( CLIP_PROC_ERR_MULTIPREC, CLIP_CODE_LABEL, string.str() );
	}
	static int _funcMRound( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._getFuncParam( param, code, token, tmpValue, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}

		if( (param.mode() == CLIP_MODE_I_MULTIPREC) && (_proc_mp.getPrec( tmpValue.mp() ) > 0) ){
			_proc_mp.ftrunc( value.mp(), tmpValue.mp() );
		} else {
			_proc_mp.fset( value.mp(), tmpValue.mp() );
			_proc_mp.fround( value.mp(), param.mpPrec(), param.mpRound() );
		}
		return CLIP_NO_ERR;
	}

	int _incVal( ClipParam param, int code, dynamic token, ClipProcVal value, bool incFlag ){
		switch( _curInfo._assCode ){
		case CLIP_CODE_VARIABLE:
			if( incFlag ){
				value.mat().addAndAss( 1.0 );
			} else {
				value.mat().subAndAss( 1.0 );
			}
			if( !(param.setVal( _curInfo._assToken, value.mat().mat(0), true )) ){
				return _retError( CLIP_PROC_ERR_ASS, code, token );
			}
			break;
		case CLIP_CODE_GLOBAL_VAR:
			param = globalParam();
			// そのまま下に流す
			continue case_CLIP_CODE_AUTO_VAR;
		case_CLIP_CODE_AUTO_VAR:
		case CLIP_CODE_AUTO_VAR:
			if( incFlag ){
				value.mat().addAndAss( 1.0 );
			} else {
				value.mat().subAndAss( 1.0 );
			}
			if( !(param.setVal( autoVarIndex( param, _curInfo._assToken ), value.mat().mat(0), false )) ){
				return _retError( CLIP_PROC_ERR_ASS, code, token );
			}
			break;
		case CLIP_CODE_ARRAY:
			if( _curInfo._curArraySize == 0 ){
				if( param.mpFlag() ){
					param.array().move( _curInfo._assToken );
					if( incFlag ){
						_proc_mp.fadd( param.array().mp(_curInfo._assToken), value.mp(), _proc_mp.F( "1.0" ) );
					} else {
						_proc_mp.fsub( param.array().mp(_curInfo._assToken), value.mp(), _proc_mp.F( "1.0" ) );
					}
				} else {
					return _retError( CLIP_PROC_ERR_RVALUE, code, token );
				}
			} else {
				if( incFlag ){
					value.mat().addAndAss( 1.0 );
				} else {
					value.mat().subAndAss( 1.0 );
				}
				param.array().set(
					_curInfo._assToken,
					_curInfo._curArray, _curInfo._curArraySize,
					value.mat().mat(0), true
					);
			}
			break;
		case CLIP_CODE_GLOBAL_ARRAY:
			param = globalParam();
			// そのまま下に流す
			continue case_CLIP_CODE_AUTO_ARRAY;
		case_CLIP_CODE_AUTO_ARRAY:
		case CLIP_CODE_AUTO_ARRAY:
			if( _curInfo._curArraySize == 0 ){
				if( param.mpFlag() ){
					var index = autoArrayIndex( param, _curInfo._assToken );
					if( incFlag ){
						_proc_mp.fadd( param.array().mp(index), value.mp(), _proc_mp.F( "1.0" ) );
					} else {
						_proc_mp.fsub( param.array().mp(index), value.mp(), _proc_mp.F( "1.0" ) );
					}
				} else {
					return _retError( CLIP_PROC_ERR_RVALUE, code, token );
				}
			} else {
				if( incFlag ){
					value.mat().addAndAss( 1.0 );
				} else {
					value.mat().subAndAss( 1.0 );
				}
				param.array().set(
					autoArrayIndex( param, _curInfo._assToken ),
					_curInfo._curArray, _curInfo._curArraySize,
					value.mat().mat(0), false
					);
			}
			break;
		default:
			return _retError( CLIP_PROC_ERR_RVALUE, code, token );
		}
		return CLIP_NO_ERR;
	}
	int _assVal( ClipParam param, int code, dynamic token, List<int>? array, int arraySize, ClipProcVal value ){
		switch( _curInfo._assCode ){
		case CLIP_CODE_VARIABLE:
			if( !(param.setVal( _curInfo._assToken, value.mat().mat(0), true )) ){
				return _retError( CLIP_PROC_ERR_ASS, code, token );
			}
			break;
		case CLIP_CODE_GLOBAL_VAR:
			param = globalParam();
			// そのまま下に流す
			continue case_CLIP_CODE_AUTO_VAR;
		case_CLIP_CODE_AUTO_VAR:
		case CLIP_CODE_AUTO_VAR:
			if( !(param.setVal( autoVarIndex( param, _curInfo._assToken ), value.mat().mat(0), false )) ){
				return _retError( CLIP_PROC_ERR_ASS, code, token );
			}
			break;
		case CLIP_CODE_ARRAY:
			if( arraySize == 0 ){
				if( param.mpFlag() ){
					param.array().move( _curInfo._assToken );
					param.array().mp(_curInfo._assToken).attach( value.mp().clone() );
				} else {
					param.array().setMatrix( _curInfo._assToken, value.mat(), true );
				}
			} else {
				param.array().set( _curInfo._assToken, array, arraySize, value.mat().mat(0), true );
			}
			break;
		case CLIP_CODE_GLOBAL_ARRAY:
			param = globalParam();
			// そのまま下に流す
			continue case_CLIP_CODE_AUTO_ARRAY;
		case_CLIP_CODE_AUTO_ARRAY:
		case CLIP_CODE_AUTO_ARRAY:
			if( arraySize == 0 ){
				if( param.mpFlag() ){
					param.array().mp(autoArrayIndex( param, _curInfo._assToken )).attach( value.mp().clone() );
				} else {
					param.array().setMatrix( autoArrayIndex( param, _curInfo._assToken ), value.mat(), false );
				}
			} else {
				param.array().set( autoArrayIndex( param, _curInfo._assToken ), array, arraySize, value.mat().mat(0), false );
			}
			break;
		default:
			return _retError( CLIP_PROC_ERR_LVALUE, code, token );
		}
		return CLIP_NO_ERR;
	}

	static int _unaryIncrement( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;

		if( param.subStep() == 0 ){
			param.setAssFlag( true );
		}
		if( (ret = _this._constFirst( param, code, token, value )) == CLIP_NO_ERR ){
			return _this._incVal( param, code, token, value, true );
		}
		return ret;
	}
	static int _unaryDecrement( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;

		if( param.subStep() == 0 ){
			param.setAssFlag( true );
		}
		if( (ret = _this._constFirst( param, code, token, value )) == CLIP_NO_ERR ){
			return _this._incVal( param, code, token, value, false );
		}
		return ret;
	}
	static int _unaryComplement( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			value.matAss( ~MATH_INT( rightValue.mat().mat(0).toFloat() ).toInt() );
			_this._updateMatrix( param, value.mat() );
		}
		return ret;
	}
	static int _unaryNot( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			value.matAss( (MATH_INT( rightValue.mat().mat(0).toFloat() ) == 0) ? 1 : 0 );
			_this._updateMatrix( param, value.mat() );
		}
		return ret;
	}
	static int _unaryMinus( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			if( param.mpFlag() ){
				if( param.mode() == CLIP_MODE_F_MULTIPREC ){
					_proc_mp.fneg( value.mp(), rightValue.mp() );
				} else {
					_proc_mp.neg( value.mp(), rightValue.mp() );
				}
			} else {
				value.matAss( rightValue.mat().minus() );
				_this._updateMatrix( param, value.mat() );
			}
		}
		return ret;
	}
	static int _unaryPlus( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			if( param.mpFlag() ){
				if( param.mode() == CLIP_MODE_F_MULTIPREC ){
					_proc_mp.fset( value.mp(), rightValue.mp() );
				} else {
					_proc_mp.set( value.mp(), rightValue.mp() );
				}
			} else {
				value.matAss( rightValue.mat() );
				_this._updateMatrix( param, value.mat() );
			}
		}
		return ret;
	}

	static int _opPostfixInc( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		return _this._regInc( true/*インクリメント*/, param, code, token );
	}
	static int _opPostfixDec( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		return _this._regInc( false/*デクリメント*/, param, code, token );
	}
	static int _opMul( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( false );
		}

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			if( param.mpFlag() ){
				if( param.mode() == CLIP_MODE_F_MULTIPREC ){
					_proc_mp.fmul( value.mp(), value.mp(), rightValue.mp(), param.mpPrec() + 1 );
				} else {
					_proc_mp.mul( value.mp(), value.mp(), rightValue.mp() );
				}
			} else {
				value.mat().mulAndAss( rightValue.mat() );
				_this._updateMatrix( param, value.mat() );
			}
		}
		return ret;
	}
	static int _opDiv( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( false );
		}

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			if( param.mpFlag() ){
				if( param.mode() == CLIP_MODE_F_MULTIPREC ){
					if( _this._printWarn && (_proc_mp.fcmp( rightValue.mp(), _proc_mp.F( "0.0" ) ) == 0) ){
						_this._errorProc( CLIP_PROC_WARN_DIV, _this._curLine.num(), param, CLIP_CODE_NULL, null );
					}
					_proc_mp.fdiv2( value.mp(), value.mp(), rightValue.mp(), param.mpPrec() + 1 );
				} else {
					if( _this._printWarn && (_proc_mp.cmp( rightValue.mp(), _proc_mp.I( "0" ) ) == 0) ){
						_this._errorProc( CLIP_PROC_WARN_DIV, _this._curLine.num(), param, CLIP_CODE_NULL, null );
					}
					_proc_mp.div( value.mp(), value.mp(), rightValue.mp() );
				}
			} else {
				if( _this._printWarn && rightValue.mat().equal( 0.0 ) ){
					_this._errorProc( CLIP_PROC_WARN_DIV, _this._curLine.num(), param, CLIP_CODE_NULL, null );
				}
				value.mat().divAndAss( rightValue.mat() );
				_this._updateMatrix( param, value.mat() );
			}
		}
		return ret;
	}
	static int _opMod( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( false );
		}

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			if( param.mpFlag() ){
				if( _proc_mp.getPrec( value.mp() ) > 0 ){
					_proc_mp.ftrunc( value.mp(), value.mp() );
				}
				if( _proc_mp.getPrec( rightValue.mp() ) > 0 ){
					_proc_mp.ftrunc( rightValue.mp(), rightValue.mp() );
				}
				if( _this._printWarn && (_proc_mp.cmp( rightValue.mp(), _proc_mp.I( "0" ) ) == 0) ){
					_this._errorProc( CLIP_PROC_WARN_DIV, _this._curLine.num(), param, CLIP_CODE_NULL, null );
				}
				_proc_mp.div( MPData(), value.mp(), rightValue.mp(), value.mp() );
			} else {
				if( _this._printWarn && rightValue.mat().equal( 0.0 ) ){
					_this._errorProc( CLIP_PROC_WARN_DIV, _this._curLine.num(), param, CLIP_CODE_NULL, null );
				}
				value.mat().modAndAss( rightValue.mat() );
				_this._updateMatrix( param, value.mat() );
			}
		}
		return ret;
	}
	static int _opAdd( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( false );
		}

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			if( param.mpFlag() ){
				if( param.mode() == CLIP_MODE_F_MULTIPREC ){
					_proc_mp.fadd( value.mp(), value.mp(), rightValue.mp() );
				} else {
					_proc_mp.add( value.mp(), value.mp(), rightValue.mp() );
				}
			} else {
				value.mat().addAndAss( rightValue.mat() );
				_this._updateMatrix( param, value.mat() );
			}
		}
		return ret;
	}
	static int _opSub( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( false );
		}

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			if( param.mpFlag() ){
				if( param.mode() == CLIP_MODE_F_MULTIPREC ){
					_proc_mp.fsub( value.mp(), value.mp(), rightValue.mp() );
				} else {
					_proc_mp.sub( value.mp(), value.mp(), rightValue.mp() );
				}
			} else {
				value.mat().subAndAss( rightValue.mat() );
				_this._updateMatrix( param, value.mat() );
			}
		}
		return ret;
	}
	static int _opShiftL( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( false );
		}

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			value.matAss( MATH_SHIFTL( MATH_INT( value.mat().mat(0).toFloat() ), MATH_INT( rightValue.mat().mat(0).toFloat() ) ) );
			_this._updateMatrix( param, value.mat() );
		}
		return ret;
	}
	static int _opShiftR( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( false );
		}

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			value.matAss( MATH_SHIFTR( MATH_INT( value.mat().mat(0).toFloat() ), MATH_INT( rightValue.mat().mat(0).toFloat() ) ) );
			_this._updateMatrix( param, value.mat() );
		}
		return ret;
	}
	static int _opLess( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( false );
		}

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			if( param.mpFlag() ){
				if( param.mode() == CLIP_MODE_F_MULTIPREC ){
					value.matAss( (_this.mpfCmp( param, value.mp(), rightValue.mp() ) < 0) ? 1 : 0 );
				} else {
					value.matAss( (_proc_mp.cmp( value.mp(), rightValue.mp() ) < 0) ? 1 : 0 );
				}
			} else {
				value.matAss( (value.mat().mat(0).toFloat() < rightValue.mat().mat(0).toFloat()) ? 1 : 0 );
			}
		}
		return ret;
	}
	static int _opLessOrEq( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( false );
		}

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			if( param.mpFlag() ){
				if( param.mode() == CLIP_MODE_F_MULTIPREC ){
					value.matAss( (_this.mpfCmp( param, value.mp(), rightValue.mp() ) <= 0) ? 1 : 0 );
				} else {
					value.matAss( (_proc_mp.cmp( value.mp(), rightValue.mp() ) <= 0) ? 1 : 0 );
				}
			} else {
				value.matAss( (value.mat().mat(0).toFloat() <= rightValue.mat().mat(0).toFloat()) ? 1 : 0 );
			}
		}
		return ret;
	}
	static int _opGreat( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( false );
		}

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			if( param.mpFlag() ){
				if( param.mode() == CLIP_MODE_F_MULTIPREC ){
					value.matAss( (_this.mpfCmp( param, value.mp(), rightValue.mp() ) > 0) ? 1 : 0 );
				} else {
					value.matAss( (_proc_mp.cmp( value.mp(), rightValue.mp() ) > 0) ? 1 : 0 );
				}
			} else {
				value.matAss( (value.mat().mat(0).toFloat() > rightValue.mat().mat(0).toFloat()) ? 1 : 0 );
			}
		}
		return ret;
	}
	static int _opGreatOrEq( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( false );
		}

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			if( param.mpFlag() ){
				if( param.mode() == CLIP_MODE_F_MULTIPREC ){
					value.matAss( (_this.mpfCmp( param, value.mp(), rightValue.mp() ) >= 0) ? 1 : 0 );
				} else {
					value.matAss( (_proc_mp.cmp( value.mp(), rightValue.mp() ) >= 0) ? 1 : 0 );
				}
			} else {
				value.matAss( (value.mat().mat(0).toFloat() >= rightValue.mat().mat(0).toFloat()) ? 1 : 0 );
			}
		}
		return ret;
	}
	static int _opEqual( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( false );
		}

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			if( param.mpFlag() ){
				if( param.mode() == CLIP_MODE_F_MULTIPREC ){
					value.matAss( (_this.mpfCmp( param, value.mp(), rightValue.mp() ) == 0) ? 1 : 0 );
				} else {
					value.matAss( (_proc_mp.cmp( value.mp(), rightValue.mp() ) == 0) ? 1 : 0 );
				}
			} else {
				value.matAss( value.mat().equal( rightValue.mat() ) ? 1 : 0 );
			}
		}
		return ret;
	}
	static int _opNotEqual( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( false );
		}

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			if( param.mpFlag() ){
				if( param.mode() == CLIP_MODE_F_MULTIPREC ){
					value.matAss( (_this.mpfCmp( param, value.mp(), rightValue.mp() ) != 0) ? 1 : 0 );
				} else {
					value.matAss( (_proc_mp.cmp( value.mp(), rightValue.mp() ) != 0) ? 1 : 0 );
				}
			} else {
				value.matAss( value.mat().notEqual( rightValue.mat() ) ? 1 : 0 );
			}
		}
		return ret;
	}
	static int _opAND( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( false );
		}

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			value.matAss( MATH_AND( MATH_INT( value.mat().mat(0).toFloat() ), MATH_INT( rightValue.mat().mat(0).toFloat() ) ) );
			_this._updateMatrix( param, value.mat() );
		}
		return ret;
	}
	static int _opXOR( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( false );
		}

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			value.matAss( MATH_XOR( MATH_INT( value.mat().mat(0).toFloat() ), MATH_INT( rightValue.mat().mat(0).toFloat() ) ) );
			_this._updateMatrix( param, value.mat() );
		}
		return ret;
	}
	static int _opOR( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( false );
		}

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			value.matAss( MATH_OR( MATH_INT( value.mat().mat(0).toFloat() ), MATH_INT( rightValue.mat().mat(0).toFloat() ) ) );
			_this._updateMatrix( param, value.mat() );
		}
		return ret;
	}
	static int _opLogAND( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;

		if( param.subStep() == 0 ){
			param.setAssFlag( false );
		}

		if( value.mat().notEqual( 0.0 ) ){
			ClipProcVal rightValue = ClipProcVal( _this, param );

			if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
				value.matAss( rightValue.mat().notEqual( 0.0 ) ? 1 : 0 );
			}
		} else {
			if( (ret = _this._constSkip( code, token )) == CLIP_NO_ERR ){
				value.matAss( 0 );
			}
		}
		return ret;
	}
	static int _opLogOR( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;

		if( param.subStep() == 0 ){
			param.setAssFlag( false );
		}

		if( value.mat().notEqual( 0.0 ) ){
			if( (ret = _this._constSkip( code, token )) == CLIP_NO_ERR ){
				value.matAss( 1 );
			}
		} else {
			ClipProcVal rightValue = ClipProcVal( _this, param );

			if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
				value.matAss( rightValue.mat().notEqual( 0.0 ) ? 1 : 0 );
			}
		}
		return ret;
	}
	static int _opConditional( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		if( param.subStep() == 0 ){
			param.setAssFlag( false );
		}

		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				if( _proc_mp.fcmp( value.mp(), _proc_mp.F( "0.0" ) ) != 0 ){
					if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
						if( _this._constSkipConditional( code, token ) == CLIP_NO_ERR ){
							return CLIP_NO_ERR;
						}
					}
				} else {
					if( _this._constSkipConditional( code, token ) == CLIP_NO_ERR ){
						if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
							return CLIP_NO_ERR;
						}
					}
				}
			} else {
				if( _proc_mp.cmp( value.mp(), _proc_mp.I( "0" ) ) != 0 ){
					if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
						if( _this._constSkipConditional( code, token ) == CLIP_NO_ERR ){
							return CLIP_NO_ERR;
						}
					}
				} else {
					if( _this._constSkipConditional( code, token ) == CLIP_NO_ERR ){
						if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
							return CLIP_NO_ERR;
						}
					}
				}
			}
		} else {
			if( value.mat().notEqual( 0.0 ) ){
				if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
					_this._updateMatrix( param, value.mat() );
					if( _this._constSkipConditional( code, token ) == CLIP_NO_ERR ){
						return CLIP_NO_ERR;
					}
				}
			} else {
				if( _this._constSkipConditional( code, token ) == CLIP_NO_ERR ){
					if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
						_this._updateMatrix( param, value.mat() );
						return CLIP_NO_ERR;
					}
				}
			}
		}
		return _this._retError( CLIP_PROC_ERR_CONDITIONAL, code, token );
	}
	static int _opAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;

		if( param.subStep() == 0 ){
			param.setAssFlag( true );
		}

		List<int>? saveArray = _this._curInfo._curArray;
		int saveArraySize    = _this._curInfo._curArraySize;

		if( (ret = _this._const( param, code, token, value )) == CLIP_NO_ERR ){
			if( !(param.mpFlag()) ){
				_this._updateMatrix( param, value.mat() );
			}
			ret = _this._assVal( param, code, token, saveArray, saveArraySize, value );
		}

		saveArray = null;

		return ret;
	}
	static int _opMulAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( true );
		}

		List<int>? saveArray = _this._curInfo._curArray;
		int saveArraySize    = _this._curInfo._curArraySize;

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			if( param.mpFlag() ){
				if( param.mode() == CLIP_MODE_F_MULTIPREC ){
					_proc_mp.fmul( value.mp(), value.mp(), rightValue.mp(), param.mpPrec() + 1 );
				} else {
					_proc_mp.mul( value.mp(), value.mp(), rightValue.mp() );
				}
			} else {
				value.mat().mulAndAss( rightValue.mat() );
				_this._updateMatrix( param, value.mat() );
			}
			ret = _this._assVal( param, code, token, saveArray, saveArraySize, value );
		}

		saveArray = null;

		return ret;
	}
	static int _opDivAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( true );
		}

		List<int>? saveArray = _this._curInfo._curArray;
		int saveArraySize    = _this._curInfo._curArraySize;

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			if( param.mpFlag() ){
				if( param.mode() == CLIP_MODE_F_MULTIPREC ){
					if( _this._printWarn && (_proc_mp.fcmp( rightValue.mp(), _proc_mp.F( "0.0" ) ) == 0) ){
						_this._errorProc( CLIP_PROC_WARN_DIV, _this._curLine.num(), param, CLIP_CODE_NULL, null );
					}
					_proc_mp.fdiv2( value.mp(), value.mp(), rightValue.mp(), param.mpPrec() + 1 );
				} else {
					if( _this._printWarn && (_proc_mp.cmp( rightValue.mp(), _proc_mp.I( "0" ) ) == 0) ){
						_this._errorProc( CLIP_PROC_WARN_DIV, _this._curLine.num(), param, CLIP_CODE_NULL, null );
					}
					_proc_mp.div( value.mp(), value.mp(), rightValue.mp() );
				}
			} else {
				if( _this._printWarn && rightValue.mat().equal( 0.0 ) ){
					_this._errorProc( CLIP_PROC_WARN_DIV, _this._curLine.num(), param, CLIP_CODE_NULL, null );
				}
				value.mat().divAndAss( rightValue.mat() );
				_this._updateMatrix( param, value.mat() );
			}
			ret = _this._assVal( param, code, token, saveArray, saveArraySize, value );
		}

		saveArray = null;

		return ret;
	}
	static int _opModAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( true );
		}

		List<int>? saveArray = _this._curInfo._curArray;
		int saveArraySize    = _this._curInfo._curArraySize;

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			if( param.mpFlag() ){
				if( _proc_mp.getPrec( value.mp() ) > 0 ){
					_proc_mp.ftrunc( value.mp(), value.mp() );
				}
				if( _proc_mp.getPrec( rightValue.mp() ) > 0 ){
					_proc_mp.ftrunc( rightValue.mp(), rightValue.mp() );
				}
				if( _this._printWarn && (_proc_mp.cmp( rightValue.mp(), _proc_mp.I( "0" ) ) == 0) ){
					_this._errorProc( CLIP_PROC_WARN_DIV, _this._curLine.num(), param, CLIP_CODE_NULL, null );
				}
				_proc_mp.div( MPData(), value.mp(), rightValue.mp(), value.mp() );
			} else {
				if( _this._printWarn && rightValue.mat().equal( 0.0 ) ){
					_this._errorProc( CLIP_PROC_WARN_DIV, _this._curLine.num(), param, CLIP_CODE_NULL, null );
				}
				value.mat().modAndAss( rightValue.mat() );
				_this._updateMatrix( param, value.mat() );
			}
			ret = _this._assVal( param, code, token, saveArray, saveArraySize, value );
		}

		saveArray = null;

		return ret;
	}
	static int _opAddAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( true );
		}

		List<int>? saveArray = _this._curInfo._curArray;
		int saveArraySize    = _this._curInfo._curArraySize;

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			if( param.mpFlag() ){
				if( param.mode() == CLIP_MODE_F_MULTIPREC ){
					_proc_mp.fadd( value.mp(), value.mp(), rightValue.mp() );
				} else {
					_proc_mp.add( value.mp(), value.mp(), rightValue.mp() );
				}
			} else {
				value.mat().addAndAss( rightValue.mat() );
				_this._updateMatrix( param, value.mat() );
			}
			ret = _this._assVal( param, code, token, saveArray, saveArraySize, value );
		}

		saveArray = null;

		return ret;
	}
	static int _opSubAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( true );
		}

		List<int>? saveArray = _this._curInfo._curArray;
		int saveArraySize    = _this._curInfo._curArraySize;

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			if( param.mpFlag() ){
				if( param.mode() == CLIP_MODE_F_MULTIPREC ){
					_proc_mp.fsub( value.mp(), value.mp(), rightValue.mp() );
				} else {
					_proc_mp.sub( value.mp(), value.mp(), rightValue.mp() );
				}
			} else {
				value.mat().subAndAss( rightValue.mat() );
				_this._updateMatrix( param, value.mat() );
			}
			ret = _this._assVal( param, code, token, saveArray, saveArraySize, value );
		}

		saveArray = null;

		return ret;
	}
	static int _opShiftLAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( true );
		}

		List<int>? saveArray = _this._curInfo._curArray;
		int saveArraySize    = _this._curInfo._curArraySize;

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			value.matAss( MATH_SHIFTL( MATH_INT( value.mat().mat(0).toFloat() ), MATH_INT( rightValue.mat().mat(0).toFloat() ) ) );
			_this._updateMatrix( param, value.mat() );
			ret = _this._assVal( param, code, token, saveArray, saveArraySize, value );
		}

		saveArray = null;

		return ret;
	}
	static int _opShiftRAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( true );
		}

		List<int>? saveArray = _this._curInfo._curArray;
		int saveArraySize    = _this._curInfo._curArraySize;

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			value.matAss( MATH_SHIFTR( MATH_INT( value.mat().mat(0).toFloat() ), MATH_INT( rightValue.mat().mat(0).toFloat() ) ) );
			_this._updateMatrix( param, value.mat() );
			ret = _this._assVal( param, code, token, saveArray, saveArraySize, value );
		}

		saveArray = null;

		return ret;
	}
	static int _opANDAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( true );
		}

		List<int>? saveArray = _this._curInfo._curArray;
		int saveArraySize    = _this._curInfo._curArraySize;

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			value.matAss( MATH_AND( MATH_INT( value.mat().mat(0).toFloat() ), MATH_INT( rightValue.mat().mat(0).toFloat() ) ) );
			_this._updateMatrix( param, value.mat() );
			ret = _this._assVal( param, code, token, saveArray, saveArraySize, value );
		}

		saveArray = null;

		return ret;
	}
	static int _opORAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( true );
		}

		List<int>? saveArray = _this._curInfo._curArray;
		int saveArraySize    = _this._curInfo._curArraySize;

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			value.matAss( MATH_OR( MATH_INT( value.mat().mat(0).toFloat() ), MATH_INT( rightValue.mat().mat(0).toFloat() ) ) );
			_this._updateMatrix( param, value.mat() );
			ret = _this._assVal( param, code, token, saveArray, saveArraySize, value );
		}

		saveArray = null;

		return ret;
	}
	static int _opXORAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( true );
		}

		List<int>? saveArray = _this._curInfo._curArray;
		int saveArraySize    = _this._curInfo._curArraySize;

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			value.matAss( MATH_XOR( MATH_INT( value.mat().mat(0).toFloat() ), MATH_INT( rightValue.mat().mat(0).toFloat() ) ) );
			_this._updateMatrix( param, value.mat() );
			ret = _this._assVal( param, code, token, saveArray, saveArraySize, value );
		}

		saveArray = null;

		return ret;
	}
	static int _opComma( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;

		if( param.subStep() == 0 ){
			param.setAssFlag( false );
		}

		if( (ret = _this._const( param, code, token, value )) == CLIP_NO_ERR ){
			if( !(param.mpFlag()) ){
				_this._updateMatrix( param, value.mat() );
			}
		}
		return ret;
	}
	static int _opPow( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( false );
		}

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			if( param.mpFlag() ){
				_this.mpPow( param, value.mp(), value.mp(), MATH_INT( rightValue.mat().mat(0).toFloat() ).toInt() );
			} else {
				value.matAss( value.mat().mat(0).pow( rightValue.mat().mat(0) ) );
				_this._updateMatrix( param, value.mat() );
			}
		}
		return ret;
	}
	static int _opPowAndAss( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		int ret;
		ClipProcVal rightValue = ClipProcVal( _this, param );

		if( param.subStep() == 0 ){
			param.setAssFlag( false );
		}

		List<int>? saveArray = _this._curInfo._curArray;
		int saveArraySize    = _this._curInfo._curArraySize;

		if( (ret = _this._const( param, code, token, rightValue )) == CLIP_NO_ERR ){
			if( param.mpFlag() ){
				_this.mpPow( param, value.mp(), value.mp(), MATH_INT( rightValue.mat().mat(0).toFloat() ).toInt() );
			} else {
				value.matAss( value.mat().mat(0).pow( rightValue.mat().mat(0) ) );
				_this._updateMatrix( param, value.mat() );
			}
			ret = _this._assVal( param, code, token, saveArray, saveArraySize, value );
		}

		saveArray = null;

		return ret;
	}
	static int _opFact( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value ){
		if( param.mpFlag() ){
			int tmp = MATH_INT( value.mat().mat(0).toFloat() ).toInt();
			_this.mpFactorial( value.mp(), tmp );
		} else {
			value.matAss( value.mat().mat(0).factorial() );
		}
		return CLIP_NO_ERR;
	}

	static int _loopBegin( ClipProc _this ){
		if( _this._statMode == CLIP_STAT_MODE_NOT_START ){
			int ret;

			_this._statMode = CLIP_STAT_MODE_REGISTERING;
			_this._stat = ClipLoop();
			if( (ret = _this._stat!.regLine( _this._curLine )) != CLIP_LOOP_CONT ){
				_this._stat = null;
				_this._statMode = CLIP_STAT_MODE_NOT_START;
				return ret;
			}
			return CLIP_PROC_SUB_END;
		} else if( _this._statMode == CLIP_STAT_MODE_PROCESSING ){
			if( _this._checkSkip() ){
				_this._stat!.doBreak();
				return CLIP_PROC_SUB_END;
			}
		}
		return CLIP_NO_ERR;
	}
	static int _loopEnd( ClipProc _this ){
		if( _this._statMode == CLIP_STAT_MODE_PROCESSING ){
			if( _this._checkSkip() ){
				bool _continue = _this._stat!.checkContinue();

				_this._stat!.doBreak();
				_this._stat!.doEnd();

				if( !_continue ){
					return CLIP_PROC_SUB_END;
				}
			}
		}
		return CLIP_NO_ERR;
	}
	static int _loopCont( ClipProc _this ){
		if( _this._statMode == CLIP_STAT_MODE_PROCESSING ){
			if( _this._checkSkip() ){
				_this._stat!.doBreak();
				_this._stat!.doEnd();
				return CLIP_PROC_SUB_END;
			}
		}
		return CLIP_NO_ERR;
	}
	static int _loopUntil( ClipProc _this ){
		if( _this._statMode == CLIP_STAT_MODE_PROCESSING ){
			if( _this._checkSkip() ){
				bool _continue = _this._stat!.checkContinue();

				_this._stat!.doBreak();
				_this._stat!.doEnd();

				if( !_continue ){
					return CLIP_PROC_SUB_END;
				}
			}
		}
		return CLIP_NO_ERR;
	}
	static int _loopWhile( ClipProc _this ){
		if( _this._statMode == CLIP_STAT_MODE_PROCESSING ){
			_this._endType[_this._endCnt] = CLIP_PROC_END_TYPE_WHILE;
			_this._endCnt++;
		}

		return _loopBegin( _this );
	}
	static int _loopEndWhile( ClipProc _this ){
		if( _this._statMode == CLIP_STAT_MODE_PROCESSING ){
			if( _this._endCnt > 0 ){
				_this._endCnt--;
			}

			if( _this._checkSkip() ){
				_this._stat!.doBreak();
				_this._stat!.doEnd();
				return CLIP_PROC_SUB_END;
			}
		}
		return CLIP_NO_ERR;
	}
	static int _loopFor( ClipProc _this ){
		if( _this._statMode == CLIP_STAT_MODE_PROCESSING ){
			_this._endType[_this._endCnt] = CLIP_PROC_END_TYPE_FOR;
			_this._endCnt++;
		}

		return _loopBegin( _this );
	}
	static int _loopNext( ClipProc _this ){
		if( _this._statMode == CLIP_STAT_MODE_PROCESSING ){
			if( _this._endCnt > 0 ){
				_this._endCnt--;
			}

			if( _this._checkSkip() ){
				_this._stat!.doBreak();
				_this._stat!.doEnd();
				return CLIP_PROC_SUB_END;
			}
		}
		return CLIP_NO_ERR;
	}
	static int _loopFunc( ClipProc _this ){
		return _loopBegin( _this );
	}
	static int _loopEndFunc( ClipProc _this ){
		if( _this._statMode == CLIP_STAT_MODE_PROCESSING ){
			if( _this._checkSkip() ){
				_this._stat!.doBreak();
				_this._stat!.doEnd();
				return CLIP_PROC_SUB_END;
			}
		}
		return CLIP_NO_ERR;
	}
	static int _loopMultiEnd( ClipProc _this ){
		if( _this._endCnt > 0 ){
			switch( _this._endType[_this._endCnt - 1] ){
			case CLIP_PROC_END_TYPE_WHILE:
				return _loopEndWhile( _this );
			case CLIP_PROC_END_TYPE_FOR:
				return _loopNext( _this );
			case CLIP_PROC_END_TYPE_IF:
				return _loopEndIf( _this );
			case CLIP_PROC_END_TYPE_SWITCH:
				return _loopEndSwi( _this );
			}
		}
		return CLIP_PROC_ERR_STAT_END;
	}
	static int _loopIf( ClipProc _this ){
		_this._endType[_this._endCnt] = CLIP_PROC_END_TYPE_IF;
		_this._endCnt++;

//		if( _this._statIfMode[_this._statIfCnt] != CLIP_STAT_IFMODE_STARTED ){
			_this._statIfCnt++;
			if( _this._statIfCnt > _this._statIfMax ){
				_this._statIfCnt--;
				return CLIP_PROC_ERR_STAT_IF;
			}
			if( _this._checkSkipSwi() || ((_this._statIfMode[_this._statIfCnt - 1] == CLIP_STAT_IFMODE_DISABLE) || (_this._statIfMode[_this._statIfCnt - 1] == CLIP_STAT_IFMODE_PROCESSED)) ){
				_this._statIfMode[_this._statIfCnt] = CLIP_STAT_IFMODE_PROCESSED;
				return CLIP_PROC_SUB_END;
			} else {
//				_this._statIfMode[_this._statIfCnt] = CLIP_STAT_IFMODE_STARTED;
				_this._statIfMode[_this._statIfCnt] = CLIP_STAT_IFMODE_ENABLE;
			}
//		}
		return CLIP_NO_ERR;
	}
	static int _loopElIf( ClipProc _this ){
		if( _this._statIfCnt == 0 ){
			return CLIP_PROC_ERR_STAT_ENDIF;
		}
		if( _this._statIfMode[_this._statIfCnt] == CLIP_STAT_IFMODE_PROCESSED ){
			return CLIP_PROC_SUB_END;
		}
		return CLIP_NO_ERR;
	}
	static int _loopElse( ClipProc _this ){
		if( _this._statIfCnt == 0 ){
			return CLIP_PROC_ERR_STAT_ENDIF;
		}
		if( _this._statIfMode[_this._statIfCnt] == CLIP_STAT_IFMODE_PROCESSED ){
			return CLIP_PROC_SUB_END;
		}
		return CLIP_NO_ERR;
	}
	static int _loopEndIf( ClipProc _this ){
		if( _this._endCnt > 0 ){
			_this._endCnt--;
		}

		if( _this._statIfCnt == 0 ){
			return CLIP_PROC_ERR_STAT_ENDIF;
		}
		_this._statIfCnt--;
		if( _this._statIfMode[_this._statIfCnt] == CLIP_STAT_IFMODE_PROCESSED ){
			return CLIP_PROC_SUB_END;
		}
		return CLIP_NO_ERR;
	}
	static int _loopSwitch( ClipProc _this ){
		_this._endType[_this._endCnt] = CLIP_PROC_END_TYPE_SWITCH;
		_this._endCnt++;

//		if( _this._statSwiMode[_this._statSwiCnt] != CLIP_STAT_SWIMODE_STARTED ){
			_this._statSwiCnt++;
			if( _this._statSwiCnt > _this._statSwiMax ){
				_this._statSwiCnt--;
				return CLIP_PROC_ERR_STAT_SWITCH;
			}
			if( _this._checkSkipIf() || ((_this._statSwiMode[_this._statSwiCnt - 1] == CLIP_STAT_SWIMODE_DISABLE) || (_this._statSwiMode[_this._statSwiCnt - 1] == CLIP_STAT_SWIMODE_PROCESSED)) ){
				_this._statSwiMode[_this._statSwiCnt] = CLIP_STAT_SWIMODE_PROCESSED;
				return CLIP_PROC_SUB_END;
			} else {
//				_this._statSwiMode[_this._statSwiCnt] = CLIP_STAT_SWIMODE_STARTED;
				_this._statSwiMode[_this._statSwiCnt] = CLIP_STAT_SWIMODE_ENABLE;
			}
//		}
		return CLIP_NO_ERR;
	}
	static int _loopCase( ClipProc _this ){
		if( _this._statSwiCnt == 0 ){
			return CLIP_PROC_ERR_STAT_ENDSWI;
		}
		if( _this._statSwiMode[_this._statSwiCnt] == CLIP_STAT_SWIMODE_PROCESSED ){
			return CLIP_PROC_SUB_END;
		}
		return CLIP_NO_ERR;
	}
	static int _loopDefault( ClipProc _this ){
		if( _this._statSwiCnt == 0 ){
			return CLIP_PROC_ERR_STAT_ENDSWI;
		}
		if( _this._statSwiMode[_this._statSwiCnt] == CLIP_STAT_SWIMODE_PROCESSED ){
			return CLIP_PROC_SUB_END;
		}
		return CLIP_NO_ERR;
	}
	static int _loopEndSwi( ClipProc _this ){
		if( _this._endCnt > 0 ){
			_this._endCnt--;
		}

		if( _this._statSwiCnt == 0 ){
			return CLIP_PROC_ERR_STAT_ENDSWI;
		}
		_this._statSwiCnt--;
		if( _this._statSwiMode[_this._statSwiCnt] == CLIP_STAT_SWIMODE_PROCESSED ){
			return CLIP_PROC_SUB_END;
		}
		return CLIP_NO_ERR;
	}
	static int _loopBreakSwi( ClipProc _this ){
		if( _this._statSwiCnt == 0 ){
			return CLIP_PROC_ERR_STAT_ENDSWI;
		}
		if( _this._statSwiMode[_this._statSwiCnt] == CLIP_STAT_SWIMODE_PROCESSED ){
			return CLIP_PROC_SUB_END;
		}
		return CLIP_NO_ERR;
	}
	static int _loopContinue( ClipProc _this ){
		if( _this._statMode == CLIP_STAT_MODE_PROCESSING ){
			if( _this._checkSkip() ){
				return CLIP_PROC_SUB_END;
			}
		}
		return CLIP_NO_ERR;
	}
	static int _loopBreak( ClipProc _this ){
		if( (_this._endCnt > 0) && (_this._endType[_this._endCnt - 1] == CLIP_PROC_END_TYPE_SWITCH) ){
			return _loopBreakSwi( _this );
		}

		if( _this._statMode == CLIP_STAT_MODE_PROCESSING ){
			if( _this._checkSkip() ){
				return CLIP_PROC_SUB_END;
			}
		}
		return CLIP_NO_ERR;
	}
	static int _loopAssert( ClipProc _this ){
		if( _this._checkSkip() ){
			return CLIP_PROC_SUB_END;
		}
		return CLIP_NO_ERR;
	}
	static int _loopReturn( ClipProc _this ){
		if( _this._checkSkip() ){
			return CLIP_PROC_SUB_END;
		}
		return CLIP_NO_ERR;
	}

	void _doStatBreak(){
		_stat!.doBreak();

		resetLoopCount();
	}
	static int _statStart( ClipProc _this, ClipParam param, int code, dynamic token ){
		if( _this._statMode == CLIP_STAT_MODE_PROCESSING ){
			_this._loopCnt++;
			incProcLoopTotal();
			if( (procLoopMax() > 0) && (_this._loopCnt > procLoopMax()) ){
				return CLIP_PROC_ERR_STAT_LOOP;
			}
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statEnd( ClipProc _this, ClipParam param, int code, dynamic token ){
		if( _this._statMode == CLIP_STAT_MODE_NOT_START ){
			return CLIP_PROC_ERR_SE_LOOPEND;
		} else if( _this._statMode == CLIP_STAT_MODE_PROCESSING ){
			int ret;
			List<ClipProcVal> tmpValue = newProcValArray( 2, _this, param );

			if( (ret = _this._constFirst( param, code, token, tmpValue[0] )) != CLIP_NO_ERR ){
				return ret;
			}

			List<int>? saveArray = _this._curInfo._curArray;
			int saveArraySize    = _this._curInfo._curArraySize;

			if( (ret = _this._getSeOperand( param, code, token, tmpValue[1] )) != CLIP_NO_ERR ){
				return ret;
			}
			int stop = MATH_INT( tmpValue[1].mat().mat(0).toFloat() ).toInt();

			if( (ret = _this._getSeOperand( param, code, token, tmpValue[1] )) != CLIP_NO_ERR ){
				return ret;
			}
			int step = MATH_INT( tmpValue[1].mat().mat(0).toFloat() ).toInt();
			if( step == 0 ){
				return _this._retError( CLIP_PROC_ERR_SE_OPERAND, code, token );
			}

			if( _this._curLine.token()!.get() != null ){
				return _this._retError( CLIP_PROC_ERR_SE_OPERAND, code, token );
			}

			tmpValue[0].mat().addAndAss( step );
//			_this._updateMatrix( param, tmpValue[0].mat() );
			ret = _this._assVal( param, code, token, saveArray, saveArraySize, tmpValue[0] );

			saveArray = null;

			if( ret != CLIP_NO_ERR ){
				return ret;
			}

			bool _break;
			if( step < 0 ){
				_break = (MATH_INT( tmpValue[0].mat().mat(0).toFloat() ) <= stop);
			} else {
				_break = (MATH_INT( tmpValue[0].mat().mat(0).toFloat() ) >= stop);
			}
			if( _break ){
				_this._doStatBreak();
			}
			_this._stat!.doEnd();
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statEndInc( ClipProc _this, ClipParam param, int code, dynamic token ){
		if( _this._statMode == CLIP_STAT_MODE_NOT_START ){
			return CLIP_PROC_ERR_SE_LOOPEND;
		} else if( _this._statMode == CLIP_STAT_MODE_PROCESSING ){
			int ret;
			List<ClipProcVal> tmpValue = newProcValArray( 2, _this, param );

			if( (ret = _this._constFirst( param, code, token, tmpValue[0] )) != CLIP_NO_ERR ){
				return ret;
			}

			List<int>? saveArray = _this._curInfo._curArray;
			int saveArraySize    = _this._curInfo._curArraySize;

			if( (ret = _this._getSeOperand( param, code, token, tmpValue[1] )) != CLIP_NO_ERR ){
				return ret;
			}

			if( _this._curLine.token()!.get() != null ){
				return _this._retError( CLIP_PROC_ERR_SE_OPERAND, code, token );
			}

			tmpValue[0].mat().addAndAss( 1 );
//			_this._updateMatrix( param, tmpValue[0].mat() );
			ret = _this._assVal( param, code, token, saveArray, saveArraySize, tmpValue[0] );

			saveArray = null;

			if( ret != CLIP_NO_ERR ){
				return ret;
			}

			if( MATH_INT( tmpValue[0].mat().mat(0).toFloat() ) >= MATH_INT( tmpValue[1].mat().mat(0).toFloat() ) ){
				_this._doStatBreak();
			}
			_this._stat!.doEnd();
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statEndDec( ClipProc _this, ClipParam param, int code, dynamic token ){
		if( _this._statMode == CLIP_STAT_MODE_NOT_START ){
			return CLIP_PROC_ERR_SE_LOOPEND;
		} else if( _this._statMode == CLIP_STAT_MODE_PROCESSING ){
			int ret;
			List<ClipProcVal> tmpValue = newProcValArray( 2, _this, param );

			if( (ret = _this._constFirst( param, code, token, tmpValue[0] )) != CLIP_NO_ERR ){
				return ret;
			}

			List<int>? saveArray = _this._curInfo._curArray;
			int saveArraySize    = _this._curInfo._curArraySize;

			if( (ret = _this._getSeOperand( param, code, token, tmpValue[1] )) != CLIP_NO_ERR ){
				return ret;
			}

			if( _this._curLine.token()!.get() != null ){
				return _this._retError( CLIP_PROC_ERR_SE_OPERAND, code, token );
			}

			tmpValue[0].mat().subAndAss( 1 );
//			_this._updateMatrix( param, tmpValue[0].mat() );
			ret = _this._assVal( param, code, token, saveArray, saveArraySize, tmpValue[0] );

			saveArray = null;

			if( ret != CLIP_NO_ERR ){
				return ret;
			}

			if( MATH_INT( tmpValue[0].mat().mat(0).toFloat() ) <= MATH_INT( tmpValue[1].mat().mat(0).toFloat() ) ){
				_this._doStatBreak();
			}
			_this._stat!.doEnd();
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statEndEq( ClipProc _this, ClipParam param, int code, dynamic token ){
		if( _this._statMode == CLIP_STAT_MODE_NOT_START ){
			return CLIP_PROC_ERR_SE_LOOPEND;
		} else if( _this._statMode == CLIP_STAT_MODE_PROCESSING ){
			int ret;
			List<ClipProcVal> tmpValue = newProcValArray( 2, _this, param );

			if( (ret = _this._constFirst( param, code, token, tmpValue[0] )) != CLIP_NO_ERR ){
				return ret;
			}

			List<int>? saveArray = _this._curInfo._curArray;
			int saveArraySize    = _this._curInfo._curArraySize;

			if( (ret = _this._getSeOperand( param, code, token, tmpValue[1] )) != CLIP_NO_ERR ){
				return ret;
			}
			int stop = MATH_INT( tmpValue[1].mat().mat(0).toFloat() ).toInt();

			if( (ret = _this._getSeOperand( param, code, token, tmpValue[1] )) != CLIP_NO_ERR ){
				return ret;
			}
			int step = MATH_INT( tmpValue[1].mat().mat(0).toFloat() ).toInt();
			if( step == 0 ){
				return _this._retError( CLIP_PROC_ERR_SE_OPERAND, code, token );
			}

			if( _this._curLine.token()!.get() != null ){
				return _this._retError( CLIP_PROC_ERR_SE_OPERAND, code, token );
			}

			tmpValue[0].mat().addAndAss( step );
//			_this._updateMatrix( param, tmpValue[0].mat() );
			ret = _this._assVal( param, code, token, saveArray, saveArraySize, tmpValue[0] );

			saveArray = null;

			if( ret != CLIP_NO_ERR ){
				return ret;
			}

			bool _break;
			if( step < 0 ){
				_break = (MATH_INT( tmpValue[0].mat().mat(0).toFloat() ) < stop);
			} else {
				_break = (MATH_INT( tmpValue[0].mat().mat(0).toFloat() ) > stop);
			}
			if( _break ){
				_this._doStatBreak();
			}
			_this._stat!.doEnd();
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statEndEqInc( ClipProc _this, ClipParam param, int code, dynamic token ){
		if( _this._statMode == CLIP_STAT_MODE_NOT_START ){
			return CLIP_PROC_ERR_SE_LOOPEND;
		} else if( _this._statMode == CLIP_STAT_MODE_PROCESSING ){
			int ret;
			List<ClipProcVal> tmpValue = newProcValArray( 2, _this, param );

			if( (ret = _this._constFirst( param, code, token, tmpValue[0] )) != CLIP_NO_ERR ){
				return ret;
			}

			List<int>? saveArray = _this._curInfo._curArray;
			int saveArraySize    = _this._curInfo._curArraySize;

			if( (ret = _this._getSeOperand( param, code, token, tmpValue[1] )) != CLIP_NO_ERR ){
				return ret;
			}

			if( _this._curLine.token()!.get() != null ){
				return _this._retError( CLIP_PROC_ERR_SE_OPERAND, code, token );
			}

			tmpValue[0].mat().addAndAss( 1 );
//			_this._updateMatrix( param, tmpValue[0].mat() );
			ret = _this._assVal( param, code, token, saveArray, saveArraySize, tmpValue[0] );

			saveArray = null;

			if( ret != CLIP_NO_ERR ){
				return ret;
			}

			if( MATH_INT( tmpValue[0].mat().mat(0).toFloat() ) > MATH_INT( tmpValue[1].mat().mat(0).toFloat() ) ){
				_this._doStatBreak();
			}
			_this._stat!.doEnd();
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statEndEqDec( ClipProc _this, ClipParam param, int code, dynamic token ){
		if( _this._statMode == CLIP_STAT_MODE_NOT_START ){
			return CLIP_PROC_ERR_SE_LOOPEND;
		} else if( _this._statMode == CLIP_STAT_MODE_PROCESSING ){
			int ret;
			List<ClipProcVal> tmpValue = newProcValArray( 2, _this, param );

			if( (ret = _this._constFirst( param, code, token, tmpValue[0] )) != CLIP_NO_ERR ){
				return ret;
			}

			List<int>? saveArray = _this._curInfo._curArray;
			int saveArraySize    = _this._curInfo._curArraySize;

			if( (ret = _this._getSeOperand( param, code, token, tmpValue[1] )) != CLIP_NO_ERR ){
				return ret;
			}

			if( _this._curLine.token()!.get() != null ){
				return _this._retError( CLIP_PROC_ERR_SE_OPERAND, code, token );
			}

			tmpValue[0].mat().subAndAss( 1 );
//			_this._updateMatrix( param, tmpValue[0].mat() );
			ret = _this._assVal( param, code, token, saveArray, saveArraySize, tmpValue[0] );

			saveArray = null;

			if( ret != CLIP_NO_ERR ){
				return ret;
			}

			if( MATH_INT( tmpValue[0].mat().mat(0).toFloat() ) < MATH_INT( tmpValue[1].mat().mat(0).toFloat() ) ){
				_this._doStatBreak();
			}
			_this._stat!.doEnd();
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statCont( ClipProc _this, ClipParam param, int code, dynamic token ){
		switch( _this._statMode ){
		case CLIP_STAT_MODE_NOT_START:
			return CLIP_PROC_ERR_SE_LOOPCONT;
		case CLIP_STAT_MODE_PROCESSING:
			_this._stat!.doEnd();
			break;
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statDo( ClipProc _this, ClipParam param, int code, dynamic token ){
		if( _this._statMode == CLIP_STAT_MODE_PROCESSING ){
			_this._loopCnt++;
			incProcLoopTotal();
			if( (procLoopMax() > 0) && (_this._loopCnt > procLoopMax()) ){
				return CLIP_PROC_ERR_STAT_LOOP;
			}
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statUntil( ClipProc _this, ClipParam param, int code, dynamic token ){
		if( _this._statMode == CLIP_STAT_MODE_NOT_START ){
			return CLIP_PROC_ERR_STAT_UNTIL;
		} else if( _this._statMode == CLIP_STAT_MODE_PROCESSING ){
			int ret;
			ClipProcVal tmpValue = ClipProcVal( _this, param );

			if( (ret = _this._const( param, code, token, tmpValue )) != CLIP_NO_ERR ){
				return ret;
			}
			if( tmpValue.mat().equal( 0.0 ) ){
				_this._doStatBreak();
			}
			_this._stat!.doEnd();
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statWhile( ClipProc _this, ClipParam param, int code, dynamic token ){
		if( _this._statMode == CLIP_STAT_MODE_PROCESSING ){
			_this._loopCnt++;
			incProcLoopTotal();
			if( (procLoopMax() > 0) && (_this._loopCnt > procLoopMax()) ){
				return CLIP_PROC_ERR_STAT_LOOP;
			}

			int ret;
			ClipProcVal tmpValue = ClipProcVal( _this, param );

			if( (ret = _this._const( param, code, token, tmpValue )) != CLIP_NO_ERR ){
				return ret;
			}
			if( tmpValue.mat().equal( 0.0 ) ){
				_this._doStatBreak();
			}
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statEndWhile( ClipProc _this, ClipParam param, int code, dynamic token ){
		switch( _this._statMode ){
		case CLIP_STAT_MODE_NOT_START:
			return CLIP_PROC_ERR_STAT_ENDWHILE;
		case CLIP_STAT_MODE_PROCESSING:
			_this._stat!.doEnd();
			break;
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statFor( ClipProc _this, ClipParam param, int code, dynamic token ){
		if( _this._statMode == CLIP_STAT_MODE_PROCESSING ){
			_this._loopCnt++;
			incProcLoopTotal();
			if( (procLoopMax() > 0) && (_this._loopCnt > procLoopMax()) ){
				return CLIP_PROC_ERR_STAT_LOOP;
			}

			int ret;
			ClipProcVal tmpValue = ClipProcVal( _this, param );

			if( (ret = _this._const( param, code, token, tmpValue )) != CLIP_NO_ERR ){
				return ret;
			}
			if( tmpValue.mat().equal( 0.0 ) ){
				_this._doStatBreak();
			}
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statFor2( ClipProc _this, ClipParam param, int code, dynamic token ){
		if( _this._statMode == CLIP_STAT_MODE_PROCESSING ){
			_this._loopCnt++;
			incProcLoopTotal();
			if( (procLoopMax() > 0) && (_this._loopCnt > procLoopMax()) ){
				return CLIP_PROC_ERR_STAT_LOOP;
			}
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statNext( ClipProc _this, ClipParam param, int code, dynamic token ){
		switch( _this._statMode ){
		case CLIP_STAT_MODE_NOT_START:
			return CLIP_PROC_ERR_STAT_NEXT;
		case CLIP_STAT_MODE_PROCESSING:
			_this._stat!.doEnd();
			break;
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statFunc( ClipProc _this, ClipParam param, int code, dynamic token ){
		int i;

		if( _this._statMode == CLIP_STAT_MODE_PROCESSING ){
			int newCode = 0;
			dynamic newToken;

			if( _this._curLine.token()!.getTokenParam( param ) ){
				newCode  = getCode();
				newToken = getToken();
				if( newCode == CLIP_CODE_TOP ){
					if( !(_this._curLine.token()!.getTokenParam( param )) ){
						return _this._retError( CLIP_PROC_ERR_STAT_FUNCNAME, newCode, newToken );
					}
					newCode  = getCode();
					newToken = getToken();
				}
				if( (newCode == CLIP_CODE_LABEL) || (newCode == CLIP_CODE_GLOBAL_VAR) || (newCode == CLIP_CODE_GLOBAL_ARRAY) ){
					_this._stat!.doBreak();

					if( param.func().search( newToken, false, null ) != null ){
						return _this._retError( CLIP_PROC_ERR_STAT_FUNCNAME, newCode, newToken );
					}
					ClipFuncData? func;
					if( (func = param.func().create( newToken, _this._curLine.num() + 1 )) != null ){
						// 関数パラメータのラベルを取り込む
						i = 0;
						while( _this._curLine.token()!.getToken() ){
							newCode  = getCode();
							newToken = getToken();
							switch( newCode ){
							case CLIP_CODE_TOP:
							case CLIP_CODE_END:
								break;
							case CLIP_CODE_PARAM_ANS:
							case CLIP_CODE_PARAM_ARRAY:
							case CLIP_CODE_OPERATOR:
								func!.label().addCode( newCode, newToken );
								break;
							case CLIP_CODE_LABEL:
								if( i <= 9 ){
									func!.label().addCode( newCode, newToken );
									i++;
									break;
								}
								// そのまま下に流す
								continue _default;
							_default:
							default:
								param.func().del( func! );
								return _this._retError( CLIP_PROC_ERR_STAT_FUNCPARAM, newCode, newToken );
							}
						}

						// 関数の記述を取り込む
						ClipLineData? line;
						while( (line = _this._stat!.getLine()) != null ){
							_this._curLine = line!;
							func!.line().regLine( _this._curLine );
						}
					} else {
						return CLIP_PROC_ERR_STAT_FUNC;
					}

					return CLIP_PROC_SUB_END;
				}
			}
			return _this._retError( CLIP_PROC_ERR_STAT_FUNCNAME, newCode, newToken );
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statEndFunc( ClipProc _this, ClipParam param, int code, dynamic token ){
		switch( _this._statMode ){
		case CLIP_STAT_MODE_NOT_START:
			return CLIP_PROC_ERR_STAT_ENDFUNC;
		case CLIP_STAT_MODE_PROCESSING:
			_this._stat!.doEnd();
			break;
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statMultiEnd( ClipProc _this, ClipParam param, int code, dynamic token ){
		switch( _this._endType[_this._endCnt] ){
		case CLIP_PROC_END_TYPE_WHILE:
			return _statEndWhile( _this, param, code, token );
		case CLIP_PROC_END_TYPE_FOR:
			return _statNext( _this, param, code, token );
		case CLIP_PROC_END_TYPE_IF:
			return _statEndIf( _this, param, code, token );
		case CLIP_PROC_END_TYPE_SWITCH:
			return _statEndSwi( _this, param, code, token );
		}

		switch( _this._statMode ){
		case CLIP_STAT_MODE_NOT_START:
			return CLIP_PROC_ERR_STAT_END;
		case CLIP_STAT_MODE_PROCESSING:
			_this._stat!.doEnd();
			break;
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statIf( ClipProc _this, ClipParam param, int code, dynamic token ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._const( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			_this._statIfCnt--;
			return ret;
		}
		_this._statIfMode[_this._statIfCnt] = (tmpValue.mat().notEqual( 0.0 ) ? CLIP_STAT_IFMODE_ENABLE : CLIP_STAT_IFMODE_DISABLE);
		return CLIP_PROC_SUB_END;
	}
	static int _statElIf( ClipProc _this, ClipParam param, int code, dynamic token ){
		if( _this._statIfMode[_this._statIfCnt] == CLIP_STAT_IFMODE_DISABLE ){
			int ret;
			ClipProcVal tmpValue = ClipProcVal( _this, param );

			if( (ret = _this._const( param, code, token, tmpValue )) != CLIP_NO_ERR ){
				return ret;
			}
			if( tmpValue.mat().notEqual( 0.0 ) ){
				_this._statIfMode[_this._statIfCnt] = CLIP_STAT_IFMODE_ENABLE;
			}
		} else if( _this._statIfMode[_this._statIfCnt] == CLIP_STAT_IFMODE_ENABLE ){
			_this._statIfMode[_this._statIfCnt] = CLIP_STAT_IFMODE_PROCESSED;
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statElse( ClipProc _this, ClipParam param, int code, dynamic token ){
		if( _this._statIfMode[_this._statIfCnt] == CLIP_STAT_IFMODE_DISABLE ){
			_this._statIfMode[_this._statIfCnt] = CLIP_STAT_IFMODE_ENABLE;
		} else if( _this._statIfMode[_this._statIfCnt] == CLIP_STAT_IFMODE_ENABLE ){
			_this._statIfMode[_this._statIfCnt] = CLIP_STAT_IFMODE_PROCESSED;
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statEndIf( ClipProc _this, ClipParam param, int code, dynamic token ){
		return CLIP_PROC_SUB_END;
	}
	static int _statSwitch( ClipProc _this, ClipParam param, int code, dynamic token ){
		int ret;

		if( (ret = _this._const( param, code, token, _this._statSwiVal[_this._statSwiCnt].setParam( param ) )) != CLIP_NO_ERR ){
			_this._statSwiCnt--;
			return ret;
		}
		_this._statSwiMode[_this._statSwiCnt] = CLIP_STAT_SWIMODE_DISABLE;
		return CLIP_PROC_SUB_END;
	}
	static int _statCase( ClipProc _this, ClipParam param, int code, dynamic token ){
		if( _this._statSwiMode[_this._statSwiCnt] == CLIP_STAT_SWIMODE_DISABLE ){
			int ret;
			ClipProcVal tmpValue = ClipProcVal( _this, param );

			if( (ret = _this._const( param, code, token, tmpValue )) != CLIP_NO_ERR ){
				return ret;
			}
			if( tmpValue.mat().equal( _this._statSwiVal[_this._statSwiCnt].setParam( param ).mat() ) ){
				_this._statSwiMode[_this._statSwiCnt] = CLIP_STAT_SWIMODE_ENABLE;
			}
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statDefault( ClipProc _this, ClipParam param, int code, dynamic token ){
		if( _this._statSwiMode[_this._statSwiCnt] == CLIP_STAT_SWIMODE_DISABLE ){
			_this._statSwiMode[_this._statSwiCnt] = CLIP_STAT_SWIMODE_ENABLE;
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statEndSwi( ClipProc _this, ClipParam param, int code, dynamic token ){
		return CLIP_PROC_SUB_END;
	}
	static int _statBreakSwi( ClipProc _this, ClipParam param, int code, dynamic token ){
		if( _this._statSwiMode[_this._statSwiCnt] == CLIP_STAT_SWIMODE_ENABLE ){
			if( _this._statIfMode[_this._statIfCnt] == CLIP_STAT_IFMODE_ENABLE ){
				_this._statSwiMode[_this._statSwiCnt] = CLIP_STAT_SWIMODE_PROCESSED;
			}
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statContinue( ClipProc _this, ClipParam param, int code, dynamic token ){
		switch( _this._statMode ){
		case CLIP_STAT_MODE_NOT_START:
			return CLIP_PROC_ERR_STAT_CONTINUE;
		case CLIP_STAT_MODE_PROCESSING:
			_this._stat!.doContinue();
			break;
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statBreak( ClipProc _this, ClipParam param, int code, dynamic token ){
		if( (_this._endCnt > 0) && (_this._endType[_this._endCnt - 1] == CLIP_PROC_END_TYPE_SWITCH) ){
			return _statBreakSwi( _this, param, code, token );
		}

		switch( _this._statMode ){
		case CLIP_STAT_MODE_NOT_START:
			return CLIP_PROC_ERR_STAT_BREAK;
		case CLIP_STAT_MODE_PROCESSING:
			_this._doStatBreak();
			break;
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statContinue2( ClipProc _this, ClipParam param, int code, dynamic token ){
		switch( _this._statMode ){
		case CLIP_STAT_MODE_NOT_START:
			return CLIP_PROC_ERR_SE_CONTINUE;
		case CLIP_STAT_MODE_PROCESSING:
			int ret;
			ClipProcVal tmpValue = ClipProcVal( _this, param );

			if( (ret = _this._const( param, code, token, tmpValue )) != CLIP_NO_ERR ){
				return CLIP_PROC_ERR_SE_OPERAND;
			}

			if( _this._curLine.token()!.get() != null ){
				return CLIP_PROC_ERR_SE_OPERAND;
			}

			if( tmpValue.mat().notEqual( 0.0 ) ){
				_this._stat!.doContinue();
			}

			break;
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statBreak2( ClipProc _this, ClipParam param, int code, dynamic token ){
		switch( _this._statMode ){
		case CLIP_STAT_MODE_NOT_START:
			return CLIP_PROC_ERR_SE_BREAK;
		case CLIP_STAT_MODE_PROCESSING:
			int ret;
			ClipProcVal tmpValue = ClipProcVal( _this, param );

			if( (ret = _this._const( param, code, token, tmpValue )) != CLIP_NO_ERR ){
				return CLIP_PROC_ERR_SE_OPERAND;
			}

			if( _this._curLine.token()!.get() != null ){
				return CLIP_PROC_ERR_SE_OPERAND;
			}

			if( tmpValue.mat().notEqual( 0.0 ) ){
				_this._doStatBreak();
			}

			break;
		}
		return CLIP_PROC_SUB_END;
	}
	static int _statAssert( ClipProc _this, ClipParam param, int code, dynamic token ){
		// 診断メッセージONの場合のみ処理を行う
		if( _this._printAssert ){
			int ret;
			ClipProcVal tmpValue = ClipProcVal( _this, param );

			if( (ret = _this._const( param, code, token, tmpValue )) == CLIP_NO_ERR ){
				if( tmpValue.mat().equal( 0.0 ) ){
					if( _this._assertProc( _this._curLine.num(), param ) ){
						return CLIP_ERR_ASSERT;
					}
				}
			} else {
				return ret;
			}
		}

		return CLIP_PROC_SUB_END;
	}
	static int _statReturn( ClipProc _this, ClipParam param, int code, dynamic token ){
		if( _this._curLine.token()!.getTokenLock() ){
			int ret;
			ClipProcVal tmpValue = ClipProcVal( _this, param );

			if( (ret = _this._const( param, code, token, tmpValue )) == CLIP_NO_ERR ){
				if( param.ansFlag() ){
					if( param.mpFlag() ){
						param.array().move( 0 );
						param.array().mp(0).attach( tmpValue.mp().clone() );
					} else {
						param.array().setMatrix( 0, tmpValue.mat(), true );
					}
				} else {
					_this._errorProc( CLIP_PROC_WARN_RETURN, _this._curLine.num(), param, CLIP_CODE_NULL, null );
				}
			} else {
				return ret;
			}
		}

		// 終了要求
		_this._quitFlag = true;

		return CLIP_PROC_SUB_END;
	}
	static int _statReturn2( ClipProc _this, ClipParam param, int code, dynamic token ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._const( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return CLIP_PROC_ERR_SE_OPERAND;
		}

		if( _this._curLine.token()!.get() != null ){
			return CLIP_PROC_ERR_SE_OPERAND;
		}

		if( tmpValue.mat().notEqual( 0.0 ) ){
			// 終了要求
			_this._quitFlag = true;
		}

		return CLIP_PROC_SUB_END;
	}
	static int _statReturn3( ClipProc _this, ClipParam param, int code, dynamic token ){
		int ret;
		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( (ret = _this._const( param, code, token, tmpValue )) != CLIP_NO_ERR ){
			return CLIP_PROC_ERR_SE_OPERAND;
		}

		bool tmp;
		if( param.mpFlag() ){
			if( param.mode() == CLIP_MODE_F_MULTIPREC ){
				tmp = (_proc_mp.fcmp( tmpValue.mp(), _proc_mp.F( "0.0" ) ) != 0);
			} else {
				tmp = (_proc_mp.cmp( tmpValue.mp(), _proc_mp.I( "0" ) ) != 0);
			}
		} else {
			tmp = tmpValue.mat().notEqual( 0.0 );
		}
		if( tmp ){
			if( (ret = _this._getSeOperand( param, code, token, tmpValue )) != CLIP_NO_ERR ){
				return CLIP_PROC_ERR_SE_OPERAND;
			}

			if( _this._curLine.token()!.get() != null ){
				return CLIP_PROC_ERR_SE_OPERAND;
			}

			if( param.ansFlag() ){
				if( param.mpFlag() ){
					param.array().move( 0 );
					param.array().mp(0).attach( tmpValue.mp().clone() );
				} else {
					param.array().setMatrix( 0, tmpValue.mat(), true );
				}
			} else {
				_this._errorProc( CLIP_PROC_WARN_SE_RETURN, _this._curLine.num(), param, CLIP_CODE_NULL, null );
			}

			// 終了要求
			_this._quitFlag = true;
		} else {
			if( (ret = _this._skipSeOperand( code, token )) != CLIP_NO_ERR ){
				return CLIP_PROC_ERR_SE_OPERAND;
			}

			if( _this._curLine.token()!.get() != null ){
				return CLIP_PROC_ERR_SE_OPERAND;
			}
		}

		return CLIP_PROC_SUB_END;
	}

	static int _commandNull( ClipProc _this, ClipParam param, int code, dynamic token ){
		return CLIP_PROC_ERR_COMMAND_NULL;
	}
	static int _commandEFloat( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		param.setMode( CLIP_MODE_E_FLOAT );
		if( globalParam() != param ){
			globalParam().setMode( CLIP_MODE_E_FLOAT );
		}
		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			param.setPrec( MATH_INT( value.mat().mat(0).toFloat() ).toInt() );
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandFFloat( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		param.setMode( CLIP_MODE_F_FLOAT );
		if( globalParam() != param ){
			globalParam().setMode( CLIP_MODE_F_FLOAT );
		}
		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			param.setPrec( MATH_INT( value.mat().mat(0).toFloat() ).toInt() );
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandGFloat( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		param.setMode( CLIP_MODE_G_FLOAT );
		if( globalParam() != param ){
			globalParam().setMode( CLIP_MODE_G_FLOAT );
		}
		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			param.setPrec( MATH_INT( value.mat().mat(0).toFloat() ).toInt() );
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandEComplex( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		param.setMode( CLIP_MODE_E_COMPLEX );
		if( globalParam() != param ){
			globalParam().setMode( CLIP_MODE_E_COMPLEX );
		}
		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			param.setPrec( MATH_INT( value.mat().mat(0).toFloat() ).toInt() );
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandFComplex( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		param.setMode( CLIP_MODE_F_COMPLEX );
		if( globalParam() != param ){
			globalParam().setMode( CLIP_MODE_F_COMPLEX );
		}
		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			param.setPrec( MATH_INT( value.mat().mat(0).toFloat() ).toInt() );
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandGComplex( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		param.setMode( CLIP_MODE_G_COMPLEX );
		if( globalParam() != param ){
			globalParam().setMode( CLIP_MODE_G_COMPLEX );
		}
		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			param.setPrec( MATH_INT( value.mat().mat(0).toFloat() ).toInt() );
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandPrec( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			param.setPrec( MATH_INT( value.mat().mat(0).toFloat() ).toInt() );
			return CLIP_PROC_SUB_END;
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandIFract( ClipProc _this, ClipParam param, int code, dynamic token ){
		param.setMode( CLIP_MODE_I_FRACT );
		if( globalParam() != param ){
			globalParam().setMode( CLIP_MODE_I_FRACT );
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandMFract( ClipProc _this, ClipParam param, int code, dynamic token ){
		param.setMode( CLIP_MODE_M_FRACT );
		if( globalParam() != param ){
			globalParam().setMode( CLIP_MODE_M_FRACT );
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandHTime( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		param.setMode( CLIP_MODE_H_TIME );
		if( globalParam() != param ){
			globalParam().setMode( CLIP_MODE_H_TIME );
		}
		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			double fps = value.mat().mat(0).toFloat();
			param.setFps( fps );
			if( globalParam() != param ){
				globalParam().setFps( fps );
			}
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandMTime( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		param.setMode( CLIP_MODE_M_TIME );
		if( globalParam() != param ){
			globalParam().setMode( CLIP_MODE_M_TIME );
		}
		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			double fps = value.mat().mat(0).toFloat();
			param.setFps( fps );
			if( globalParam() != param ){
				globalParam().setFps( fps );
			}
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandSTime( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		param.setMode( CLIP_MODE_S_TIME );
		if( globalParam() != param ){
			globalParam().setMode( CLIP_MODE_S_TIME );
		}
		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			double fps = value.mat().mat(0).toFloat();
			param.setFps( fps );
			if( globalParam() != param ){
				globalParam().setFps( fps );
			}
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandFTime( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		param.setMode( CLIP_MODE_F_TIME );
		if( globalParam() != param ){
			globalParam().setMode( CLIP_MODE_F_TIME );
		}
		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			double fps = value.mat().mat(0).toFloat();
			param.setFps( fps );
			if( globalParam() != param ){
				globalParam().setFps( fps );
			}
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandFps( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			double fps = value.mat().mat(0).toFloat();
			param.setFps( fps );
			if( globalParam() != param ){
				globalParam().setFps( fps );
			}
			return CLIP_PROC_SUB_END;
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandSChar( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		param.setMode( CLIP_MODE_S_CHAR );
		if( globalParam() != param ){
			globalParam().setMode( CLIP_MODE_S_CHAR );
		}
		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			param.setRadix( MATH_INT( value.mat().mat(0).toFloat() ).toInt() );
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandUChar( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		param.setMode( CLIP_MODE_U_CHAR );
		if( globalParam() != param ){
			globalParam().setMode( CLIP_MODE_U_CHAR );
		}
		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			param.setRadix( MATH_INT( value.mat().mat(0).toFloat() ).toInt() );
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandSShort( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		param.setMode( CLIP_MODE_S_SHORT );
		if( globalParam() != param ){
			globalParam().setMode( CLIP_MODE_S_SHORT );
		}
		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			param.setRadix( MATH_INT( value.mat().mat(0).toFloat() ).toInt() );
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandUShort( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		param.setMode( CLIP_MODE_U_SHORT );
		if( globalParam() != param ){
			globalParam().setMode( CLIP_MODE_U_SHORT );
		}
		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			param.setRadix( MATH_INT( value.mat().mat(0).toFloat() ).toInt() );
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandSLong( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		param.setMode( CLIP_MODE_S_LONG );
		if( globalParam() != param ){
			globalParam().setMode( CLIP_MODE_S_LONG );
		}
		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			param.setRadix( MATH_INT( value.mat().mat(0).toFloat() ).toInt() );
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandULong( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		param.setMode( CLIP_MODE_U_LONG );
		if( globalParam() != param ){
			globalParam().setMode( CLIP_MODE_U_LONG );
		}
		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			param.setRadix( MATH_INT( value.mat().mat(0).toFloat() ).toInt() );
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandSInt( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		param.setMode( CLIP_MODE_S_LONG );
		if( globalParam() != param ){
			globalParam().setMode( CLIP_MODE_S_LONG );
		}
		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			param.setRadix( MATH_INT( value.mat().mat(0).toFloat() ).toInt() );
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandUInt( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		param.setMode( CLIP_MODE_U_LONG );
		if( globalParam() != param ){
			globalParam().setMode( CLIP_MODE_U_LONG );
		}
		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			param.setRadix( MATH_INT( value.mat().mat(0).toFloat() ).toInt() );
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandRadix( ClipProc _this, ClipParam param, int code, dynamic token ){
		if( param.mode() == CLIP_MODE_I_MULTIPREC ){
			return _this._retError( CLIP_PROC_ERR_COMMAND_RADIX, code, token );
		}

		ClipProcVal value = ClipProcVal( _this, param );

		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			param.setRadix( MATH_INT( value.mat().mat(0).toFloat() ).toInt() );
			return CLIP_PROC_SUB_END;
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandFMultiPrec( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipTokenData? lock;
		ClipProcVal value = ClipProcVal( _this, param );

		param.setMode( CLIP_MODE_F_MULTIPREC );
		if( globalParam() != param ){
			globalParam().setMode( CLIP_MODE_F_MULTIPREC );
		}

		lock = _this._curLine.token()!.lock();
		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			int prec = MATH_INT( value.mat().mat(0).toFloat() ).toInt();
			param.mpSetPrec( prec );
			if( globalParam() != param ){
				globalParam().mpSetPrec( prec );
			}
		} else {
			_this._curLine.token()!.unlock( lock );
		}

		if( _this._curLine.token()!.getToken() ){
			if( getCode() == CLIP_CODE_LABEL ){
				if( !(param.mpSetRoundStr( getToken() )) ){
					return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
				}
			}
		}

		return CLIP_PROC_SUB_END;
	}
	static int _commandIMultiPrec( ClipProc _this, ClipParam param, int code, dynamic token ){
		param.setMode( CLIP_MODE_I_MULTIPREC );
		if( globalParam() != param ){
			globalParam().setMode( CLIP_MODE_I_MULTIPREC );
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandPType( ClipProc _this, ClipParam param, int code, dynamic token ){
		param.setMode( _this._parentMode );
		param.mpSetPrec( _this._parentMpPrec );
		param.mpSetRound( _this._parentMpRound );
		if( globalParam() != param ){
			globalParam().setMode( _this._parentMode );
			globalParam().mpSetPrec( _this._parentMpPrec );
			globalParam().mpSetRound( _this._parentMpRound );
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandRad( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		if( _this._const( param, code, token, value ) != CLIP_NO_ERR ){
			value.matAss( 0.0 );
		}
		_this.setAngType( MATH_ANG_TYPE_RAD, value.mat().notEqual( 0.0 ) );
		return CLIP_PROC_SUB_END;
	}
	static int _commandDeg( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		if( _this._const( param, code, token, value ) != CLIP_NO_ERR ){
			value.matAss( 0.0 );
		}
		_this.setAngType( MATH_ANG_TYPE_DEG, value.mat().notEqual( 0.0 ) );
		return CLIP_PROC_SUB_END;
	}
	static int _commandGrad( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		if( _this._const( param, code, token, value ) != CLIP_NO_ERR ){
			value.matAss( 0.0 );
		}
		_this.setAngType( MATH_ANG_TYPE_GRAD, value.mat().notEqual( 0.0 ) );
		return CLIP_PROC_SUB_END;
	}
	static int _commandAngle( ClipProc _this, ClipParam param, int code, dynamic token ){
		List<ClipProcVal> value = newProcValArray( 2, _this, param );

		if( _this._const( param, code, token, value[0] ) == CLIP_NO_ERR ){
			int tmp = MATH_UNSIGNED( value[0].mat().mat(0).toFloat(), MATH_UMAX_8 ).toInt();
			if( tmp < 10 ){
				value[1].matAss( param.variable().val( MATH_UNSIGNED( (MATH_CHAR_CODE_0 + tmp).toDouble(), MATH_UMAX_8 ).toInt() ) );
				value[1].mat().mat(0).angToAng( _this._parentAngType, _this._angType );
				param.variable().set( MATH_UNSIGNED( (MATH_CHAR_CODE_0 + tmp).toDouble(), MATH_UMAX_8 ).toInt(), value[1].mat().mat(0), true );
				return CLIP_PROC_SUB_END;
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandAns( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			param.setAnsFlag( MATH_INT( value.mat().mat(0).toFloat() ).toInt() );
			return CLIP_PROC_SUB_END;
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandAssert( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			_this.setAssertFlag( MATH_INT( value.mat().mat(0).toFloat() ).toInt() );
			return CLIP_PROC_SUB_END;
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandWarn( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipTokenData? lock;
		int newCode;
		dynamic newToken;
		ParamString error = ParamString();

		lock = _this._curLine.token()!.lock();
		if( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();
			if( newCode == CLIP_CODE_STRING ){
				if( _this._printWarn ){
					_this._formatError(
						newToken,
						param.fileFlag() ? param.funcName() : null,
						error
						);
					printWarn( error.str(), param.parentNum(), param.parentFunc() );
				}
				return CLIP_PROC_SUB_END;
			} else if( (newCode & CLIP_CODE_ARRAY_MASK) != 0 ){
				if( _this._printWarn ){
					if( newCode == CLIP_CODE_GLOBAL_ARRAY ){
						param = globalParam();
					}
					_this._formatError(
						_this.strGet( param.array(), _this.arrayIndexIndirect( param, newCode, newToken ) ),
						param.fileFlag() ? param.funcName() : null,
						error
						);
					printWarn( error.str(), param.parentNum(), param.parentFunc() );
				}
				return CLIP_PROC_SUB_END;
			} else {
				ClipProcVal value = ClipProcVal( _this, param );

				_this._curLine.token()!.unlock( lock );
				if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
					_this.setWarnFlag( MATH_INT( value.mat().mat(0).toFloat() ).toInt() );
					return CLIP_PROC_SUB_END;
				}
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandParam( ClipProc _this, ClipParam param, int code, dynamic token ){
		List<ClipProcVal> value = newProcValArray( 2, _this, param );

		if( _this._const( param, code, token, value[0] ) == CLIP_NO_ERR ){
			if( _this._const( param, code, token, value[1] ) == CLIP_NO_ERR ){
				int tmp = MATH_UNSIGNED( value[0].mat().mat(0).toFloat(), MATH_UMAX_8 ).toInt();
				if( tmp < 10 ){
					param.setUpdateParam( tmp, MATH_INT( value[1].mat().mat(0).toFloat() ) != 0 );
					return CLIP_PROC_SUB_END;
				}
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandParams( ClipProc _this, ClipParam param, int code, dynamic token ){
		int i;
		ClipTokenData? lock;
		int newCode;
		dynamic newToken;
		String label;

		lock = _this._curLine.token()!.lock();
		if( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();

			// &かどうかをチェックする
			if( (newCode == CLIP_CODE_PARAM_ANS) || ((newCode == CLIP_CODE_OPERATOR) && (newToken >= CLIP_OP_AND)) ){
				if( !(_this._curLine.token()!.getTokenParam( param )) ){
					return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
				}
				newCode  = getCode();
				newToken = getToken();
				param.setUpdateParam( 0, true );
			} else {
				param.setUpdateParam( 0, false );
			}

			if( (newCode == CLIP_CODE_LABEL) || (newCode == CLIP_CODE_GLOBAL_VAR) || (newCode == CLIP_CODE_GLOBAL_ARRAY) ){
				label = newToken;

				// ラベルを設定する
				lock = _this._curLine.token()!.lock();
				if( _this._curLine.token()!.getToken() ){
					newCode  = getCode();
					newToken = getToken();
					if( newCode == CLIP_CODE_PARAM_ARRAY ){
						param.array().label().setLabel( MATH_CHAR_CODE_0, label, true );
					} else {
						_this._curLine.token()!.unlock( lock );
						param.variable().label().setLabel( MATH_CHAR_CODE_0, label, true );
					}
				} else {
					_this._curLine.token()!.unlock( lock );
					param.variable().label().setLabel( MATH_CHAR_CODE_0, label, true );
				}

				i = 1;
				while( _this._curLine.token()!.getTokenParam( param ) ){
					newCode  = getCode();
					newToken = getToken();

					if( i > 9 ){
						return _this._retError( CLIP_PROC_ERR_COMMAND_PARAMS, code, token );
					}

					// &かどうかをチェックする
					if( (newCode == CLIP_CODE_PARAM_ANS) || ((newCode == CLIP_CODE_OPERATOR) && (newToken >= CLIP_OP_AND)) ){
						if( !(_this._curLine.token()!.getTokenParam( param )) ){
							return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
						}
						newCode  = getCode();
						newToken = getToken();
						param.setUpdateParam( i, true );
					} else {
						param.setUpdateParam( i, false );
					}

					switch( newCode ){
					case CLIP_CODE_AUTO_VAR:
					case CLIP_CODE_AUTO_ARRAY:
						return _this._retError( CLIP_PROC_ERR_COMMAND_DEFINE, newCode, newToken );
					case CLIP_CODE_LABEL:
					case CLIP_CODE_GLOBAL_VAR:
					case CLIP_CODE_GLOBAL_ARRAY:
						label = newToken;

						// ラベルを設定する
						lock = _this._curLine.token()!.lock();
						if( _this._curLine.token()!.getToken() ){
							newCode  = getCode();
							newToken = getToken();
							if( newCode == CLIP_CODE_PARAM_ARRAY ){
								param.array().label().setLabel( MATH_CHAR_CODE_0 + i, label, true );
							} else {
								_this._curLine.token()!.unlock( lock );
								param.variable().label().setLabel( MATH_CHAR_CODE_0 + i, label, true );
							}
						} else {
							_this._curLine.token()!.unlock( lock );
							param.variable().label().setLabel( MATH_CHAR_CODE_0 + i, label, true );
						}

						i++;

						break;
					default:
						return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
					}
				}
				return CLIP_PROC_SUB_END;
			}
		}

		ClipProcVal value = ClipProcVal( _this, param );

		_this._curLine.token()!.unlock( lock );
		i = 0;
		while( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			if( i > 9 ){
				return _this._retError( CLIP_PROC_ERR_COMMAND_PARAMS, code, token );
			}
			param.setUpdateParam( i, MATH_INT( value.mat().mat(0).toFloat() ) != 0 );
			i++;
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandDefine( ClipProc _this, ClipParam param, int code, dynamic token ){
		int newCode;
		dynamic newToken;

		if( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();
			switch( newCode ){
			case CLIP_CODE_AUTO_VAR:
			case CLIP_CODE_AUTO_ARRAY:
				return _this._retError( CLIP_PROC_ERR_COMMAND_DEFINE, newCode, newToken );
			case CLIP_CODE_LABEL:
			case CLIP_CODE_GLOBAL_VAR:
			case CLIP_CODE_GLOBAL_ARRAY:
				ClipProcVal value = ClipProcVal( _this, param );
				if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
					param.variable().define( newToken, value.mat().mat(0), true );
				} else {
					param.variable().define( newToken, 1.0, true );
				}
				return CLIP_PROC_SUB_END;
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandEnum( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );
		int newCode;
		dynamic newToken;
		ClipTokenData? lock;
		int tmpCode;
		dynamic tmpToken;

		value.matAss( 0.0 );
		while( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();
			switch( newCode ){
			case CLIP_CODE_AUTO_VAR:
			case CLIP_CODE_AUTO_ARRAY:
				return _this._retError( CLIP_PROC_ERR_COMMAND_DEFINE, newCode, newToken );
			case CLIP_CODE_LABEL:
			case CLIP_CODE_GLOBAL_VAR:
			case CLIP_CODE_GLOBAL_ARRAY:
				lock = _this._curLine.token()!.lock();
				if( _this._curLine.token()!.getTokenParam( param ) ){
					tmpCode  = getCode();
					tmpToken = getToken();
					if( (tmpCode == CLIP_CODE_LABEL) || (tmpCode == CLIP_CODE_GLOBAL_VAR) || (tmpCode == CLIP_CODE_GLOBAL_ARRAY) ){
						_this._curLine.token()!.unlock( lock );
					} else {
						_this._curLine.token()!.unlock( lock );
						if( _this._const( param, tmpCode, tmpToken, value ) != CLIP_NO_ERR ){
							return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
						}
					}
				} else {
					_this._curLine.token()!.unlock( lock );
				}
				param.variable().define( newToken, MATH_INT( value.mat().mat(0).toFloat() ), true );
				value.mat().addAndAss( 1.0 );
				break;
			default:
				return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
			}
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandUnDef( ClipProc _this, ClipParam param, int code, dynamic token ){
		int newCode;
		dynamic newToken;

		if( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();
			if( newCode == CLIP_CODE_LABEL ){
				return _this._retError( CLIP_PROC_ERR_COMMAND_UNDEF, newCode, newToken );
			} else if( (newCode & CLIP_CODE_VAR_MASK) != 0 ){
				if( newCode == CLIP_CODE_GLOBAL_VAR ){
					param = globalParam();
				}
				param.variable().undef( param.variable().label().label(_this.varIndexIndirect( param, newCode, newToken )) );
				return CLIP_PROC_SUB_END;
			} else if( (newCode & CLIP_CODE_ARRAY_MASK) != 0 ){
				if( newCode == CLIP_CODE_GLOBAL_ARRAY ){
					param = globalParam();
				}
				param.array().undef( param.array().label().label(_this.arrayIndexIndirect( param, newCode, newToken )) );
				return CLIP_PROC_SUB_END;
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandVar( ClipProc _this, ClipParam param, int code, dynamic token ){
		int newCode;
		dynamic newToken;

		while( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();
			switch( newCode ){
			case CLIP_CODE_AUTO_VAR:
			case CLIP_CODE_AUTO_ARRAY:
				return _this._retError( CLIP_PROC_ERR_COMMAND_DEFINE, newCode, newToken );
			case CLIP_CODE_LABEL:
			case CLIP_CODE_GLOBAL_VAR:
			case CLIP_CODE_GLOBAL_ARRAY:
				param.variable().define( newToken, 0.0, false );
				break;
			default:
				return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
			}
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandArray( ClipProc _this, ClipParam param, int code, dynamic token ){
		int newCode;
		dynamic newToken;

		while( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();
			switch( newCode ){
			case CLIP_CODE_AUTO_VAR:
			case CLIP_CODE_AUTO_ARRAY:
				return _this._retError( CLIP_PROC_ERR_COMMAND_DEFINE, newCode, newToken );
			case CLIP_CODE_LABEL:
			case CLIP_CODE_GLOBAL_VAR:
			case CLIP_CODE_GLOBAL_ARRAY:
				param.array().define( newToken );
				break;
			default:
				return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
			}
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandLocal( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipTokenData? lock;
		int newCode;
		dynamic newToken;
		String label;

		while( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();
			switch( newCode ){
			case CLIP_CODE_AUTO_VAR:
			case CLIP_CODE_AUTO_ARRAY:
				return _this._retError( CLIP_PROC_ERR_COMMAND_DEFINE, newCode, newToken );
			case CLIP_CODE_LABEL:
			case CLIP_CODE_GLOBAL_VAR:
			case CLIP_CODE_GLOBAL_ARRAY:
				label = newToken;

				lock = _this._curLine.token()!.lock();
				if( _this._curLine.token()!.getToken() ){
					newCode  = getCode();
					newToken = getToken();
					if( newCode == CLIP_CODE_PARAM_ARRAY ){
						param.array().define( label );
					} else {
						_this._curLine.token()!.unlock( lock );
						param.variable().define( label, 0.0, false );
					}
				} else {
					_this._curLine.token()!.unlock( lock );
					param.variable().define( label, 0.0, false );
				}

				break;
			default:
				return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
			}
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandGlobal( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipTokenData? lock;
		int newCode;
		dynamic newToken;
		String label;

		while( _this._curLine.token()!.getTokenParam( globalParam() ) ){
			newCode  = getCode();
			newToken = getToken();
			if( newCode == CLIP_CODE_LABEL ){
				label = newToken;

				lock = _this._curLine.token()!.lock();
				if( _this._curLine.token()!.getToken() ){
					newCode  = getCode();
					newToken = getToken();
					if( newCode == CLIP_CODE_PARAM_ARRAY ){
						globalParam().array().define( label );
					} else {
						_this._curLine.token()!.unlock( lock );
						globalParam().variable().define( label, 0.0, false );
					}
				} else {
					_this._curLine.token()!.unlock( lock );
					globalParam().variable().define( label, 0.0, false );
				}
			} else {
				lock = _this._curLine.token()!.lock();
				if( _this._curLine.token()!.getToken() ){
					if( getCode() == CLIP_CODE_PARAM_ARRAY ){
						if( (newCode & CLIP_CODE_ARRAY_MASK) == 0 ){
							return _this._retError( CLIP_PROC_ERR_COMMAND_DEFINE, newCode, newToken );
						}
					} else {
						_this._curLine.token()!.unlock( lock );
					}
				} else {
					_this._curLine.token()!.unlock( lock );
					if( (newCode & CLIP_CODE_VAR_MASK) == 0 ){
						return _this._retError( CLIP_PROC_ERR_COMMAND_DEFINE, newCode, newToken );
					}
				}
			}
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandLabel( ClipProc _this, ClipParam param, int code, dynamic token ){
		int newCode;
		dynamic newToken;
		String label;

		if( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();
			switch( newCode ){
			case CLIP_CODE_AUTO_VAR:
			case CLIP_CODE_AUTO_ARRAY:
				return _this._retError( CLIP_PROC_ERR_COMMAND_DEFINE, newCode, newToken );
			case CLIP_CODE_LABEL:
			case CLIP_CODE_GLOBAL_VAR:
			case CLIP_CODE_GLOBAL_ARRAY:
				label = newToken;
				if( _this._curLine.token()!.getTokenParam( param ) ){
					newCode  = getCode();
					newToken = getToken();
					if( newCode == CLIP_CODE_VARIABLE ){
						param.variable().label().setLabel( _this.varIndexParam( param, newToken ), label, true );
						return CLIP_PROC_SUB_END;
					} else if( newCode == CLIP_CODE_ARRAY ){
						param.array().label().setLabel( _this.arrayIndexParam( param, newToken ), label, true );
						return CLIP_PROC_SUB_END;
					}
				}
				break;
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandParent( ClipProc _this, ClipParam param, int code, dynamic token ){
		int newCode;
		dynamic newToken;
		int index;

		if( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();
			if( newCode == CLIP_CODE_VARIABLE ){
				index = _this.varIndexParam( param, newToken );

				if( param.parent() != null ){
					// 親プロセスの変数を取り込む
					param.setVal( index, param.parent()!.variable().val( index ), true );
					if( index == 0 ){
						_this._updateMatrix( param.parent()!, param.array().matrix(index) );
					} else {
						_this._updateValue( param.parent()!, param.variable().val( index ) );
					}

					param.updateParentVarArray().add( index );
				}

				if( _this._curLine.token()!.getTokenParam( param ) ){
					newCode  = getCode();
					newToken = getToken();
					switch( newCode ){
					case CLIP_CODE_AUTO_VAR:
					case CLIP_CODE_AUTO_ARRAY:
						return _this._retError( CLIP_PROC_ERR_COMMAND_DEFINE, newCode, newToken );
					case CLIP_CODE_LABEL:
					case CLIP_CODE_GLOBAL_VAR:
					case CLIP_CODE_GLOBAL_ARRAY:
						param.variable().label().setLabel( index, newToken, true );
						break;
					default:
						return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
					}
				}

				return CLIP_PROC_SUB_END;
			} else if( newCode == CLIP_CODE_ARRAY ){
				index = _this.arrayIndexParam( param, newToken );

				if( param.parent() != null ){
					// 親プロセスの配列を取り込む
					param.parent()!.array().dup( param.array(), index, index, true );

					param.updateParentArrayArray().add( index );
				}

				if( _this._curLine.token()!.getTokenParam( param ) ){
					newCode  = getCode();
					newToken = getToken();
					switch( newCode ){
					case CLIP_CODE_AUTO_VAR:
					case CLIP_CODE_AUTO_ARRAY:
						return _this._retError( CLIP_PROC_ERR_COMMAND_DEFINE, newCode, newToken );
					case CLIP_CODE_LABEL:
					case CLIP_CODE_GLOBAL_VAR:
					case CLIP_CODE_GLOBAL_ARRAY:
						param.array().label().setLabel( index, newToken, true );
						break;
					default:
						return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
					}
				}

				return CLIP_PROC_SUB_END;
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandReal( ClipProc _this, ClipParam param, int code, dynamic token ){
		int newCode;
		dynamic newToken;

		if( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();

			ClipProcVal value = ClipProcVal( _this, param );

			if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
				if( (newCode & CLIP_CODE_VAR_MASK) != 0 ){
					if( newCode == CLIP_CODE_GLOBAL_VAR ){
						param = globalParam();
					}
					ParamBoolean moveFlag = ParamBoolean();
					int index = _this.varIndexIndirectMove( param, newCode, newToken, moveFlag );
					if( !(param.setReal( index, value.mat().mat(0).toFloat(), moveFlag.val() )) ){
						return _this._retError( CLIP_PROC_ERR_ASS, newCode, newToken );
					}
					return CLIP_PROC_SUB_END;
				}
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandImag( ClipProc _this, ClipParam param, int code, dynamic token ){
		int newCode;
		dynamic newToken;

		if( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();

			ClipProcVal value = ClipProcVal( _this, param );

			if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
				if( (newCode & CLIP_CODE_VAR_MASK) != 0 ){
					if( newCode == CLIP_CODE_GLOBAL_VAR ){
						param = globalParam();
					}
					ParamBoolean moveFlag = ParamBoolean();
					int index = _this.varIndexIndirectMove( param, newCode, newToken, moveFlag );
					if( !(param.setImag( index, value.mat().mat(0).toFloat(), moveFlag.val() )) ){
						return _this._retError( CLIP_PROC_ERR_ASS, newCode, newToken );
					}
					return CLIP_PROC_SUB_END;
				}
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandNum( ClipProc _this, ClipParam param, int code, dynamic token ){
		int newCode;
		dynamic newToken;

		if( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();

			ClipProcVal value = ClipProcVal( _this, param );

			if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
				if( (newCode & CLIP_CODE_VAR_MASK) != 0 ){
					if( newCode == CLIP_CODE_GLOBAL_VAR ){
						param = globalParam();
					}
					ParamBoolean moveFlag = ParamBoolean();
					int index = _this.varIndexIndirectMove( param, newCode, newToken, moveFlag );
					if( !(param.setNum( index, MATH_UNSIGNED( value.mat().mat(0).toFloat(), MATH_UMAX_32 ), moveFlag.val() )) ){
						return _this._retError( CLIP_PROC_ERR_ASS, newCode, newToken );
					}
					return CLIP_PROC_SUB_END;
				}
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandDenom( ClipProc _this, ClipParam param, int code, dynamic token ){
		int newCode;
		dynamic newToken;

		if( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();

			ClipProcVal value = ClipProcVal( _this, param );

			if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
				if( (newCode & CLIP_CODE_VAR_MASK) != 0 ){
					if( newCode == CLIP_CODE_GLOBAL_VAR ){
						param = globalParam();
					}
					ParamBoolean moveFlag = ParamBoolean();
					int index = _this.varIndexIndirectMove( param, newCode, newToken, moveFlag );
					if( !(param.setDenom( index, MATH_UNSIGNED( value.mat().mat(0).toFloat(), MATH_UMAX_32 ), moveFlag.val() )) ){
						return _this._retError( CLIP_PROC_ERR_ASS, newCode, newToken );
					}
					return CLIP_PROC_SUB_END;
				}
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandMat( ClipProc _this, ClipParam param, int code, dynamic token ){
		List<ClipProcVal> value = newProcValArray( 2, _this, param );
		int newCode;
		dynamic newToken;

		if( _this._const( param, code, token, value[0] ) == CLIP_NO_ERR ){
			if( _this._const( param, code, token, value[1] ) == CLIP_NO_ERR ){
				if( _this._curLine.token()!.getTokenParam( param ) ){
					newCode  = getCode();
					newToken = getToken();
					if( (newCode & CLIP_CODE_ARRAY_MASK) != 0 ){
						if( newCode == CLIP_CODE_GLOBAL_ARRAY ){
							param = globalParam();
						}
						int index = _this.arrayIndexIndirect( param, newCode, newToken );
						param.array().matrix(index).resize( MATH_INT( value[0].mat().mat(0).toFloat() ).toInt(), MATH_INT( value[1].mat().mat(0).toFloat() ).toInt() );
						return CLIP_PROC_SUB_END;
					} else if( (newCode == CLIP_CODE_LABEL) || (newCode == CLIP_CODE_GLOBAL_VAR) ){
						int index = param.array().define( newToken );
						param.array().matrix(index).resize( MATH_INT( value[0].mat().mat(0).toFloat() ).toInt(), MATH_INT( value[1].mat().mat(0).toFloat() ).toInt() );
						return CLIP_PROC_SUB_END;
					}
				}
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandTrans( ClipProc _this, ClipParam param, int code, dynamic token ){
		int newCode;
		dynamic newToken;

		if( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();
			if( (newCode & CLIP_CODE_ARRAY_MASK) != 0 ){
				if( newCode == CLIP_CODE_GLOBAL_ARRAY ){
					param = globalParam();
				}
				int index = _this.arrayIndexIndirect( param, newCode, newToken );
				param.array().setMatrix( index, param.array().matrix(index).trans(), false );
				return CLIP_PROC_SUB_END;
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandSRand( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			MATH_SRAND( MATH_INT( value.mat().mat(0).toFloat() ).toInt() );
			return CLIP_PROC_SUB_END;
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandLocalTime( ClipProc _this, ClipParam param, int code, dynamic token ){
		int i;
		ClipProcVal value = ClipProcVal( _this, param );
		int newCode;
		dynamic newToken;
		ParamString format = ParamString();
		bool errFlag;
		int curIndex = 0;
		ParamBoolean moveFlag = ParamBoolean();

		if( _this._const( param, code, token, value ) != CLIP_NO_ERR ){
			return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
		}

		// 書式制御文字列の取得
		_this._getString( param, format );
		if( format.isNull() ){
			return _this._retError( CLIP_PROC_ERR_STRING, code, token );
		}

		int t = MATH_INT( value.mat().mat(0).toFloat() ).toInt();
		Tm tm = Tm();
		tm.localtime( t );

		errFlag = false;
		for( i = 0; i < format.str().length; i++ ){
			if( charAt( format.str(), i ) == '%' ){
				i++;
				if( i >= format.str().length ){
					errFlag = true;
					break;
				}
				if( _this._curLine.token()!.getTokenParam( param ) ){
					newCode  = getCode();
					newToken = getToken();
					if( (newCode & CLIP_CODE_VAR_MASK) != 0 ){
						if( newCode == CLIP_CODE_GLOBAL_VAR ){
							curIndex = _this.varIndexIndirectMove( globalParam(), newCode, newToken, moveFlag );
						} else {
							curIndex = _this.varIndexIndirectMove( param, newCode, newToken, moveFlag );
						}
					} else {
						errFlag = true;
						break;
					}
				}
				switch( charAt( format.str(), i ) ){
				case 's': param.variable().set( curIndex, tm.sec , moveFlag.val() ); break;
				case 'm': param.variable().set( curIndex, tm.min , moveFlag.val() ); break;
				case 'h': param.variable().set( curIndex, tm.hour, moveFlag.val() ); break;
				case 'D': param.variable().set( curIndex, tm.mday, moveFlag.val() ); break;
				case 'M': param.variable().set( curIndex, tm.mon , moveFlag.val() ); break;
				case 'Y': param.variable().set( curIndex, tm.year, moveFlag.val() ); break;
				case 'w': param.variable().set( curIndex, tm.wday, moveFlag.val() ); break;
				case 'y': param.variable().set( curIndex, tm.yday, moveFlag.val() ); break;
				default:
					errFlag = true;
					break;
				}
				if( errFlag ){
					break;
				}
			}
		}

		// 書式制御文字列の解放
//		format = null;

		if( errFlag ){
			return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
		}

		return CLIP_PROC_SUB_END;
	}
	static int _commandArrayCopy( ClipProc _this, ClipParam param, int code, dynamic token ){
		int i;
		ClipTokenData? lock;
		int newCode;
		dynamic newToken;
		ClipProcVal value = ClipProcVal( _this, param );
		int srcCode;
		dynamic srcToken;
		List<int> srcIndex = [];
		int dstCode;
		dynamic dstToken;
		List<int> dstIndex = [];

		if( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();
			if( (newCode & CLIP_CODE_ARRAY_MASK) != 0 ){
				srcCode  = newCode;
				srcToken = newToken;
			} else {
				return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
			}
		} else {
			return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
		}

		i = 0;
		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			srcIndex[i] = MATH_INT( value.mat().mat(0).toFloat() ).toInt();
			i++;
		} else {
			return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
		}

		while( true ){
			lock = _this._curLine.token()!.lock();
			if( _this._curLine.token()!.getTokenParam( param ) ){
				newCode  = getCode();
				newToken = getToken();
				if( (newCode & CLIP_CODE_ARRAY_MASK) != 0 ){
					dstCode  = newCode;
					dstToken = newToken;
					break;
				}
			}
			_this._curLine.token()!.unlock( lock );
			if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
				srcIndex[i] = MATH_INT( value.mat().mat(0).toFloat() ).toInt();
				i++;
			} else {
				return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
			}
		}

		i = 0;
		while( true ){
			if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
				dstIndex[i] = MATH_INT( value.mat().mat(0).toFloat() ).toInt();
				i++;
			} else {
				if( i == 0 ){
					return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
				}
				break;
			}
		}

		int dstIndexSize = dstIndex.length - 1;
		int len = dstIndex[dstIndexSize];
		if( len > 0 ){
			int srcIndexSize = srcIndex.length;
			ClipParam srcParam;
			List<MathValue> srcValue = newValueArray( len );

			for( i = 0; i < srcIndexSize; i++ ){
				srcIndex[i] -= param.base();
				if( srcIndex[i] < 0 ){
					return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
				}
			}
			srcIndex[srcIndexSize] = -1;

			for( i = 0; i < dstIndexSize; i++ ){
				dstIndex[i] -= param.base();
				if( dstIndex[i] < 0 ){
					return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
				}
			}
			dstIndex[dstIndexSize] = -1;

			srcIndex[srcIndexSize - 1] += len;
			for( i = 0; i < len; i++ ){
				srcIndex[srcIndexSize - 1]--;
				srcParam = (srcCode == CLIP_CODE_GLOBAL_ARRAY) ? globalParam() : param;
				copyValue( srcValue[i], srcParam.array().val( _this.arrayIndexIndirect( srcParam, srcCode, srcToken ), srcIndex, srcIndexSize ) );
			}

			dstIndex[dstIndexSize - 1] += len;
			for( i = 0; i < len; i++ ){
				dstIndex[dstIndexSize - 1]--;
				switch( dstCode ){
				case CLIP_CODE_ARRAY:
					param.array().set( _this._index( param, dstCode, dstToken ), dstIndex, dstIndexSize, srcValue[i], true );
					break;
				case CLIP_CODE_AUTO_ARRAY:
					param.array().set( _this.autoArrayIndex( param, dstToken ), dstIndex, dstIndexSize, srcValue[i], false );
					break;
				case CLIP_CODE_GLOBAL_ARRAY:
					globalParam().array().set( _this.autoArrayIndex( globalParam(), dstToken ), dstIndex, dstIndexSize, srcValue[i], false );
					break;
				}
			}
		}

		return CLIP_PROC_SUB_END;
	}
	static int _commandArrayFill( ClipProc _this, ClipParam param, int code, dynamic token ){
		int i;
		int newCode;
		dynamic newToken;
		ClipProcVal srcValue = ClipProcVal( _this, param );
		ClipProcVal tmpValue = ClipProcVal( _this, param );
		int dstCode;
		dynamic dstToken;
		List<int> dstIndex = [];

		if( _this._const( param, code, token, srcValue ) != CLIP_NO_ERR ){
			return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
		}

		if( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();
			if( (newCode & CLIP_CODE_ARRAY_MASK) != 0 ){
				dstCode  = newCode;
				dstToken = newToken;
			} else {
				return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
			}
		} else {
			return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
		}

		i = 0;
		while( true ){
			if( _this._const( param, code, token, tmpValue ) == CLIP_NO_ERR ){
				dstIndex[i] = MATH_INT( tmpValue.mat().mat(0).toFloat() ).toInt();
				i++;
			} else {
				if( i == 0 ){
					return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
				}
				break;
			}
		}

		int dstIndexSize = dstIndex.length - 1;
		int len = dstIndex[dstIndexSize];
		if( len > 0 ){
			for( i = 0; i < dstIndexSize; i++ ){
				dstIndex[i] -= param.base();
				if( dstIndex[i] < 0 ){
					return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
				}
			}
			dstIndex[dstIndexSize] = -1;

			dstIndex[dstIndexSize - 1] += len;
			for( i = 0; i < len; i++ ){
				dstIndex[dstIndexSize - 1]--;
				switch( dstCode ){
				case CLIP_CODE_ARRAY:
					param.array().set( _this._index( param, dstCode, dstToken ), dstIndex, dstIndexSize, srcValue.mat().mat(0), true );
					break;
				case CLIP_CODE_AUTO_ARRAY:
					param.array().set( _this.autoArrayIndex( param, dstToken ), dstIndex, dstIndexSize, srcValue.mat().mat(0), false );
					break;
				case CLIP_CODE_GLOBAL_ARRAY:
					globalParam().array().set( _this.autoArrayIndex( globalParam(), dstToken ), dstIndex, dstIndexSize, srcValue.mat().mat(0), false );
					break;
				}
			}
		}

		return CLIP_PROC_SUB_END;
	}
	static int _commandStrCpy( ClipProc _this, ClipParam param, int code, dynamic token ){
		int newCode;
		dynamic newToken;

		if( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();
			if( (newCode & CLIP_CODE_ARRAY_MASK) != 0 ){
				ClipParam tmpParam = (newCode == CLIP_CODE_GLOBAL_ARRAY) ? globalParam() : param;
				int _arrayIndex = _this.arrayIndexIndirect( tmpParam, newCode, newToken );

				ParamString string = ParamString();
				_this._getString( param, string );

				switch( token ){
				case CLIP_COMMAND_STRCPY:
					_this.strSet( tmpParam.array(), _arrayIndex, string.str() );
					break;
				case CLIP_COMMAND_STRCAT:
					_this.strCat( tmpParam.array(), _arrayIndex, string.str() );
					break;
				}

				return CLIP_PROC_SUB_END;
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandStrLwr( ClipProc _this, ClipParam param, int code, dynamic token ){
		int newCode;
		dynamic newToken;

		if( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();
			if( (newCode & CLIP_CODE_ARRAY_MASK) != 0 ){
				ClipParam tmpParam = (newCode == CLIP_CODE_GLOBAL_ARRAY) ? globalParam() : param;
				int _arrayIndex = _this.arrayIndexIndirect( tmpParam, newCode, newToken );

				_this.strLwr( tmpParam.array(), _arrayIndex );

				return CLIP_PROC_SUB_END;
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandStrUpr( ClipProc _this, ClipParam param, int code, dynamic token ){
		int newCode;
		dynamic newToken;

		if( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();
			if( (newCode & CLIP_CODE_ARRAY_MASK) != 0 ){
				ClipParam tmpParam = (newCode == CLIP_CODE_GLOBAL_ARRAY) ? globalParam() : param;
				int _arrayIndex = _this.arrayIndexIndirect( tmpParam, newCode, newToken );

				_this.strUpr( tmpParam.array(), _arrayIndex );

				return CLIP_PROC_SUB_END;
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandPrint( ClipProc _this, ClipParam param, int code, dynamic token ){
		int newCode;
		dynamic newToken;
		List<int> _arrayIndex = List.filled( 2, 0 );
		ClipProcPrint? topPrint;
		ClipProcPrint? curPrint;
		ClipProcPrint? tmpPrint;
		bool errFlag;
		ClipTokenData? lock;
		ClipProcVal value = ClipProcVal( _this, param );
		ParamString real = ParamString();
		ParamString imag = ParamString();

		switch( token ){
		case CLIP_COMMAND_SPRINT:
			if( _this._curLine.token()!.getTokenParam( param ) ){
				newCode  = getCode();
				newToken = getToken();
				if( (newCode & CLIP_CODE_ARRAY_MASK) != 0 ){
					if( newCode == CLIP_CODE_GLOBAL_ARRAY ){
						_arrayIndex[0] = _this.arrayIndexIndirect( globalParam(), newCode, newToken );
					} else {
						_arrayIndex[0] = _this.arrayIndexIndirect( param, newCode, newToken );
					}
				} else {
					return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
				}
			} else {
				return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
			}
			break;
		case CLIP_COMMAND_PRINT:
		case CLIP_COMMAND_PRINTLN:
			break;
		case CLIP_COMMAND_LOG:
			if( skipCommandLog() ){
				while( true ){
					if( !(_this._curLine.token()!.getTokenParam( param )) ){
						break;
					}
				}
				return CLIP_PROC_SUB_END;
			}
			break;
		}

		topPrint = null;
		errFlag = false;
		while( true ){
			lock = _this._curLine.token()!.lock();
			if( !(_this._curLine.token()!.getTokenParam( param )) ){
				break;
			}
			newCode  = getCode();
			newToken = getToken();

			if( topPrint == null ){
				topPrint = ClipProcPrint();
				curPrint = topPrint;
			} else {
				tmpPrint = ClipProcPrint();
				curPrint!._next = tmpPrint;
				curPrint = tmpPrint;
			}
			curPrint._string = null;

			if( newCode == CLIP_CODE_STRING ){
				curPrint._string = "";
				curPrint._string = newToken;
			} else if( (newCode & CLIP_CODE_ARRAY_MASK) != 0 ){
				ClipParam tmpParam = (newCode == CLIP_CODE_GLOBAL_ARRAY) ? globalParam() : param;
				_arrayIndex[1] = _this.arrayIndexIndirect( tmpParam, newCode, newToken );
				curPrint._string = _this.strGet( tmpParam.array(), _arrayIndex[1] );
				if( (curPrint._string!.isEmpty) && param.mpFlag() ){
					curPrint._string = _this.mpNum2Str( tmpParam, tmpParam.array().mp(_arrayIndex[1]) );
				}
			} else {
				_this._curLine.token()!.unlock( lock );
				if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
					if( param.mpFlag() ){
						curPrint._string = _this.mpNum2Str( param, value.mp() );
					} else {
						_proc_token.valueToString( param, value.mat().mat(0), real, imag );
						curPrint._string = "";
						curPrint._string = real.str() + imag.str();
					}
				} else {
					errFlag = true;
					break;
				}
			}
		}

		if( !errFlag ){
			switch( token ){
			case CLIP_COMMAND_SPRINT:
				_this.strSet( param.array(), _arrayIndex[0], "" );
				curPrint = topPrint;
				while( curPrint != null ){
					if( curPrint._string != null ){
						_this.strCat( param.array(), _arrayIndex[0], curPrint._string! );
					}
					curPrint = curPrint._next;
				}
				break;
			case CLIP_COMMAND_PRINT:
				doCommandPrint( topPrint, false/*改行なし*/ );
				break;
			case CLIP_COMMAND_PRINTLN:
				doCommandPrint( topPrint, true/*改行付き*/ );
				break;
			case CLIP_COMMAND_LOG:
				doCommandLog( topPrint );
				break;
			}
		}

		curPrint = topPrint;
		while( curPrint != null ){
			tmpPrint = curPrint;
			curPrint = curPrint._next;
			if( tmpPrint._string != null ){
				tmpPrint._string = null;
			}
			tmpPrint = null;
		}

		if( errFlag ){
			return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
		}

		return CLIP_PROC_SUB_END;
	}
	static int _commandScan( ClipProc _this, ClipParam param, int code, dynamic token ){
		int newCode;
		dynamic newToken;
		int ret = CLIP_NO_ERR;

		ClipProcScan topScan;
		ClipProcScan? curScan;
		ClipProcScan? tmpScan;

		topScan = ClipProcScan();
		curScan = topScan;

		while( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();
			if( newCode == CLIP_CODE_STRING ){
				curScan!._title = "";
				curScan._title = newToken;
			} else if( ((newCode & CLIP_CODE_VAR_MASK) != 0) || ((newCode & CLIP_CODE_ARRAY_MASK) != 0) ){
				switch( newCode ){
				case CLIP_CODE_VARIABLE:
					if( param.variable().isLocked( _this.varIndexParam( param, newToken ) ) ){
						ret = _this._retError( CLIP_PROC_ERR_ASS, code, token );
					}
					break;
				case CLIP_CODE_AUTO_VAR:
					if( param.variable().isLocked( _this.autoVarIndex( param, newToken ) ) ){
						ret = _this._retError( CLIP_PROC_ERR_ASS, code, token );
					}
					break;
				case CLIP_CODE_GLOBAL_VAR:
					if( globalParam().variable().isLocked( _this.autoVarIndex( globalParam(), newToken ) ) ){
						ret = _this._retError( CLIP_PROC_ERR_ASS, code, token );
					}
					break;
				}
				_proc_token.delToken( curScan!._code, curScan._token );
				curScan._code = newCode;
				switch( newCode ){
				case CLIP_CODE_VARIABLE:
					curScan._token = _this.varIndexParam( param, newToken );
					break;
				case CLIP_CODE_ARRAY:
					curScan._token = _this.arrayIndexParam( param, newToken );
					break;
				default:
					curScan._token = _proc_token.newToken( newCode, newToken );
					break;
				}

				tmpScan         = ClipProcScan();
				tmpScan._before = curScan;
				curScan._next   = tmpScan;
				curScan         = tmpScan;
			}
		}

		if( curScan!._title != null ){
			curScan._title = null;
		}

		if( curScan._before != null ){
			curScan._before!._next = null;

			if( ret == CLIP_NO_ERR ){
				doCommandScan( topScan, _this, param );
			}

			curScan = topScan;
			while( curScan != null ){
				tmpScan = curScan;
				curScan = curScan._next;
				if( tmpScan._title != null ){
					tmpScan._title = null;
				}
				tmpScan = null;
			}
		}

		if( ret != CLIP_NO_ERR ){
			return ret;
		}
		return CLIP_PROC_SUB_END;
	}
/*
	_commandChar2Esc( ClipProc _this, ClipParam param, int code, dynamic token ){
		var newCode;
		var newToken;

		if( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();
			if( (newCode & CLIP_CODE_ARRAY_MASK) != 0 ){
				if( newCode == CLIP_CODE_GLOBAL_ARRAY ){
					param = globalParam();
				}

				var _arrayIndex = _this.arrayIndexIndirect( param, newCode, newToken );
				var string = new ParamString();

				string.set( _this.strGet( param._array, _arrayIndex ) );
				_this.strSet( param._array, _arrayIndex, string.escape().str() );

				return CLIP_PROC_SUB_END;
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	_commandEsc2Char( ClipProc _this, ClipParam param, int code, dynamic token ){
		var newCode;
		var newToken;

		if( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();
			if( (newCode & CLIP_CODE_ARRAY_MASK) != 0 ){
				if( newCode == CLIP_CODE_GLOBAL_ARRAY ){
					param = globalParam();
				}

				var _arrayIndex = _this.arrayIndexIndirect( param, newCode, newToken );
				var string = new ParamString();

				string.set( _this.strGet( param._array, _arrayIndex ) );
				_this.strSet( param._array, _arrayIndex, string.unescape().str() );

				return CLIP_PROC_SUB_END;
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
*/
	static int _commandClear( ClipProc _this, ClipParam param, int code, dynamic token ){
		doCommandClear();
		return CLIP_PROC_SUB_END;
	}
	static int _commandError( ClipProc _this, ClipParam param, int code, dynamic token ){
		int newCode;
		dynamic newToken;
		ParamString error = ParamString();

		if( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();
			if( newCode == CLIP_CODE_STRING ){
				_this._formatError(
					newToken,
					param.fileFlag() ? param.funcName() : null,
					error
					);
				printError( error.str(), param.parentNum(), param.parentFunc() );
				return CLIP_PROC_SUB_END;
			} else if( (newCode & CLIP_CODE_ARRAY_MASK) != 0 ){
				if( newCode == CLIP_CODE_GLOBAL_ARRAY ){
					param = globalParam();
				}
				_this._formatError(
					_this.strGet( param.array(), _this.arrayIndexIndirect( param, newCode, newToken ) ),
					param.fileFlag() ? param.funcName() : null,
					error
					);
				printError( error.str(), param.parentNum(), param.parentFunc() );
				return CLIP_PROC_SUB_END;
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandGWorld( ClipProc _this, ClipParam param, int code, dynamic token ){
		int ret = CLIP_NO_ERR;
		List<ClipProcVal> value = newProcValArray( 2, _this, param );

		for( int i = 0; i < 2; i++ ){
			ret = _this._const( param, code, token, value[i] );
		}
		if( ret == CLIP_NO_ERR ){
			int width  = MATH_INT( value[0].mat().mat(0).toFloat() ).toInt();
			int height = MATH_INT( value[1].mat().mat(0).toFloat() ).toInt();
			if( token == CLIP_COMMAND_GWORLD ){
				doCommandGWorld( width, height );
				procGWorld().create( width, height, true, false );
			} else {
				doCommandGWorld24( width, height );
				procGWorld().create( width, height, true, true );
			}
			return CLIP_PROC_SUB_END;
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandWindow( ClipProc _this, ClipParam param, int code, dynamic token ){
		int ret = CLIP_NO_ERR;
		List<ClipProcVal> value = newProcValArray( 4, _this, param );

		for( int i = 0; i < 4; i++ ){
			ret = _this._const( param, code, token, value[i] );
		}
		if( ret == CLIP_NO_ERR ){
			double left   = value[0].mat().mat(0).toFloat();
			double bottom = value[1].mat().mat(0).toFloat();
			double right  = value[2].mat().mat(0).toFloat();
			double top    = value[3].mat().mat(0).toFloat();
			doCommandWindow( left, bottom, right, top );
			procGWorld().setWindowIndirect( left, bottom, right, top );
			return CLIP_PROC_SUB_END;
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandGClear( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			procGWorld().clear( MATH_UNSIGNED( value.mat().mat(0).toFloat(), procGWorld().umax().toDouble() ).toInt() );
		} else {
			procGWorld().clear( 0 );
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandGColor( ClipProc _this, ClipParam param, int code, dynamic token ){
		List<ClipProcVal> value = newProcValArray( 2, _this, param );

		if( _this._const( param, code, token, value[0] ) == CLIP_NO_ERR ){
			int color = MATH_UNSIGNED( value[0].mat().mat(0).toFloat(), procGWorld().umax().toDouble() ).toInt();
			if( procGWorld().rgbFlag() ){
				if( _this._const( param, code, token, value[1] ) == CLIP_NO_ERR ){
					return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
				}
			} else {
				if( _this._const( param, code, token, value[1] ) == CLIP_NO_ERR ){
					doCommandGColor( color, MATH_UNSIGNED( value[1].mat().mat(0).toFloat(), MATH_UMAX_24 ).toInt() );
				}
			}
			procGWorld().setColor( color );
			return CLIP_PROC_SUB_END;
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandGFill( ClipProc _this, ClipParam param, int code, dynamic token ){
		int  ret = CLIP_NO_ERR;
		List<ClipProcVal> value = newProcValArray( 5, _this, param );

		for( int i = 0; i < 4; i++ ){
			ret = _this._const( param, code, token, value[i] );
		}
		if( ret == CLIP_NO_ERR ){
			if( _this._const( param, code, token, value[4] ) == CLIP_NO_ERR ){
				procGWorld().setColor( MATH_UNSIGNED( value[4].mat().mat(0).toFloat(), procGWorld().umax().toDouble() ).toInt() );
			}
			procGWorld().fill(
				MATH_INT( value[0].mat().mat(0).toFloat() ).toInt(), MATH_INT( value[1].mat().mat(0).toFloat() ).toInt(),
				MATH_INT( value[2].mat().mat(0).toFloat() ).toInt(), MATH_INT( value[3].mat().mat(0).toFloat() ).toInt()
				);
			return CLIP_PROC_SUB_END;
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandWFill( ClipProc _this, ClipParam param, int code, dynamic token ){
		int ret = CLIP_NO_ERR;
		List<ClipProcVal> value = newProcValArray( 5, _this, param );

		for( int i = 0; i < 4; i++ ){
			ret = _this._const( param, code, token, value[i] );
		}
		if( ret == CLIP_NO_ERR ){
			if( _this._const( param, code, token, value[4] ) == CLIP_NO_ERR ){
				procGWorld().setColor( MATH_UNSIGNED( value[4].mat().mat(0).toFloat(), procGWorld().umax().toDouble() ).toInt() );
			}
			procGWorld().wndFill(
				value[0].mat().mat(0).toFloat(), value[1].mat().mat(0).toFloat(),
				value[2].mat().mat(0).toFloat(), value[3].mat().mat(0).toFloat()
				);
			return CLIP_PROC_SUB_END;
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandGMove( ClipProc _this, ClipParam param, int code, dynamic token ){
		int ret = CLIP_NO_ERR;
		List<ClipProcVal> value = newProcValArray( 2, _this, param );

		for( int i = 0; i < 2; i++ ){
			ret = _this._const( param, code, token, value[i] );
		}
		if( ret == CLIP_NO_ERR ){
			procGWorld().moveTo( MATH_INT( value[0].mat().mat(0).toFloat() ).toInt(), MATH_INT( value[1].mat().mat(0).toFloat() ).toInt() );
			return CLIP_PROC_SUB_END;
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandWMove( ClipProc _this, ClipParam param, int code, dynamic token ){
		int ret = CLIP_NO_ERR;
		List<ClipProcVal> value = newProcValArray( 2, _this, param );

		for( int i = 0; i < 2; i++ ){
			ret = _this._const( param, code, token, value[i] );
		}
		if( ret == CLIP_NO_ERR ){
			procGWorld().wndMoveTo( value[0].mat().mat(0).toFloat(), value[1].mat().mat(0).toFloat() );
			return CLIP_PROC_SUB_END;
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandGText( ClipProc _this, ClipParam param, int code, dynamic token ){
		ParamString text = ParamString();
		int ret = CLIP_NO_ERR;
		List<ClipProcVal> value = newProcValArray( 3, _this, param );

		_this._getString( param, text );
		if( text.isNull() ){
			return _this._retError( CLIP_PROC_ERR_STRING, code, token );
		}

		ret = _this._const( param, code, token, value[0] );
		if( _this._const( param, code, token, value[1] ) == CLIP_NO_ERR ){
			if( _this._const( param, code, token, value[2] ) == CLIP_NO_ERR ){
				procGWorld().setColor( MATH_UNSIGNED( value[2].mat().mat(0).toFloat(), procGWorld().umax().toDouble() ).toInt() );
			}
			procGWorld().drawText( text.str(), MATH_INT( value[0].mat().mat(0).toFloat() ).toInt(), MATH_INT( value[1].mat().mat(0).toFloat() ).toInt(), false );
		} else {
			if( ret == CLIP_NO_ERR ){
				procGWorld().setColor( MATH_UNSIGNED( value[0].mat().mat(0).toFloat(), procGWorld().umax().toDouble() ).toInt() );
			}
			procGWorld().drawTextTo( text.str(), false );
		}

		return CLIP_PROC_SUB_END;
	}
	static int _commandGTextR( ClipProc _this, ClipParam param, int code, dynamic token ){
		ParamString text = ParamString();
		int ret = CLIP_NO_ERR;
		List<ClipProcVal> value = newProcValArray( 3, _this, param );

		_this._getString( param, text );
		if( text.isNull() ){
			return _this._retError( CLIP_PROC_ERR_STRING, code, token );
		}

		ret = _this._const( param, code, token, value[0] );
		if( _this._const( param, code, token, value[1] ) == CLIP_NO_ERR ){
			if( _this._const( param, code, token, value[2] ) == CLIP_NO_ERR ){
				procGWorld().setColor( MATH_UNSIGNED( value[2].mat().mat(0).toFloat(), procGWorld().umax().toDouble() ).toInt() );
			}
			procGWorld().drawText( text.str(), MATH_INT( value[0].mat().mat(0).toFloat() ).toInt(), MATH_INT( value[1].mat().mat(0).toFloat() ).toInt(), true );
		} else {
			if( ret == CLIP_NO_ERR ){
				procGWorld().setColor( MATH_UNSIGNED( value[0].mat().mat(0).toFloat(), procGWorld().umax().toDouble() ).toInt() );
			}
			procGWorld().drawTextTo( text.str(), true );
		}

		return CLIP_PROC_SUB_END;
	}
	static int _commandWText( ClipProc _this, ClipParam param, int code, dynamic token ){
		ParamString text = ParamString();
		int ret = CLIP_NO_ERR;
		List<ClipProcVal> value = newProcValArray( 3, _this, param );

		_this._getString( param, text );
		if( text.isNull() ){
			return _this._retError( CLIP_PROC_ERR_STRING, code, token );
		}

		ret = _this._const( param, code, token, value[0] );
		if( _this._const( param, code, token, value[1] ) == CLIP_NO_ERR ){
			if( _this._const( param, code, token, value[2] ) == CLIP_NO_ERR ){
				procGWorld().setColor( MATH_UNSIGNED( value[2].mat().mat(0).toFloat(), procGWorld().umax().toDouble() ).toInt() );
			}
			procGWorld().wndDrawText( text.str(), value[0].mat().mat(0).toFloat(), value[1].mat().mat(0).toFloat(), false );
		} else {
			if( ret == CLIP_NO_ERR ){
				procGWorld().setColor( MATH_UNSIGNED( value[0].mat().mat(0).toFloat(), procGWorld().umax().toDouble() ).toInt() );
			}
			procGWorld().wndDrawTextTo( text.str(), false );
		}

		return CLIP_PROC_SUB_END;
	}
	static int _commandWTextR( ClipProc _this, ClipParam param, int code, dynamic token ){
		ParamString text = ParamString();
		int ret = CLIP_NO_ERR;
		List<ClipProcVal> value = newProcValArray( 3, _this, param );

		_this._getString( param, text );
		if( text.isNull() ){
			return _this._retError( CLIP_PROC_ERR_STRING, code, token );
		}

		ret = _this._const( param, code, token, value[0] );
		if( _this._const( param, code, token, value[1] ) == CLIP_NO_ERR ){
			if( _this._const( param, code, token, value[2] ) == CLIP_NO_ERR ){
				procGWorld().setColor( MATH_UNSIGNED( value[2].mat().mat(0).toFloat(), procGWorld().umax().toDouble() ).toInt() );
			}
			procGWorld().wndDrawText( text.str(), value[0].mat().mat(0).toFloat(), value[1].mat().mat(0).toFloat(), true );
		} else {
			if( ret == CLIP_NO_ERR ){
				procGWorld().setColor( MATH_UNSIGNED( value[0].mat().mat(0).toFloat(), procGWorld().umax().toDouble() ).toInt() );
			}
			procGWorld().wndDrawTextTo( text.str(), true );
		}

		return CLIP_PROC_SUB_END;
	}
	static int _commandGTextL( ClipProc _this, ClipParam param, int code, dynamic token ){
		procGWorld().selectCharSet( 1 );
		int ret = ClipProc._commandGText( _this, param, code, token );
		procGWorld().selectCharSet( 0 );
		return ret;
	}
	static int _commandGTextRL( ClipProc _this, ClipParam param, int code, dynamic token ){
		procGWorld().selectCharSet( 1 );
		int ret = ClipProc._commandGTextR( _this, param, code, token );
		procGWorld().selectCharSet( 0 );
		return ret;
	}
	static int _commandWTextL( ClipProc _this, ClipParam param, int code, dynamic token ){
		procGWorld().selectCharSet( 1 );
		int ret = ClipProc._commandWText( _this, param, code, token );
		procGWorld().selectCharSet( 0 );
		return ret;
	}
	static int _commandWTextRL( ClipProc _this, ClipParam param, int code, dynamic token ){
		procGWorld().selectCharSet( 1 );
		int ret = ClipProc._commandWTextR( _this, param, code, token );
		procGWorld().selectCharSet( 0 );
		return ret;
	}
	static int _commandGLine( ClipProc _this, ClipParam param, int code, dynamic token ){
		int ret = CLIP_NO_ERR;
		List<ClipProcVal> value = newProcValArray( 5, _this, param );

		for( int i = 0; i < 2; i++ ){
			ret = _this._const( param, code, token, value[i] );
		}
		if( ret == CLIP_NO_ERR ){
			ret = _this._const( param, code, token, value[2] );
			if( _this._const( param, code, token, value[3] ) == CLIP_NO_ERR ){
				if( _this._const( param, code, token, value[4] ) == CLIP_NO_ERR ){
					procGWorld().setColor( MATH_UNSIGNED( value[4].mat().mat(0).toFloat(), procGWorld().umax().toDouble() ).toInt() );
				}
				procGWorld().line(
					MATH_INT( value[0].mat().mat(0).toFloat() ).toInt(), MATH_INT( value[1].mat().mat(0).toFloat() ).toInt(),
					MATH_INT( value[2].mat().mat(0).toFloat() ).toInt(), MATH_INT( value[3].mat().mat(0).toFloat() ).toInt()
					);
				return CLIP_PROC_SUB_END;
			} else {
				if( ret == CLIP_NO_ERR ){
					procGWorld().setColor( MATH_UNSIGNED( value[2].mat().mat(0).toFloat(), procGWorld().umax().toDouble() ).toInt() );
				}
				procGWorld().lineTo(
					MATH_INT( value[0].mat().mat(0).toFloat() ).toInt(), MATH_INT( value[1].mat().mat(0).toFloat() ).toInt()
					);
				return CLIP_PROC_SUB_END;
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandWLine( ClipProc _this, ClipParam param, int code, dynamic token ){
		int ret = CLIP_NO_ERR;
		List<ClipProcVal> value = newProcValArray( 5, _this, param );

		for( int i = 0; i < 2; i++ ){
			ret = _this._const(param, code, token, value[i] );
		}
		if( ret == CLIP_NO_ERR ){
			ret = _this._const( param, code, token, value[2] );
			if( _this._const( param, code, token, value[3] ) == CLIP_NO_ERR ){
				if( _this._const( param, code, token, value[4] ) == CLIP_NO_ERR ){
					procGWorld().setColor( MATH_UNSIGNED( value[4].mat().mat(0).toFloat(), procGWorld().umax().toDouble() ).toInt() );
				}
				procGWorld().wndLine(
					value[0].mat().mat(0).toFloat(), value[1].mat().mat(0).toFloat(),
					value[2].mat().mat(0).toFloat(), value[3].mat().mat(0).toFloat()
					);
				return CLIP_PROC_SUB_END;
			} else {
				if( ret == CLIP_NO_ERR ){
					procGWorld().setColor( MATH_UNSIGNED( value[2].mat().mat(0).toFloat(), procGWorld().umax().toDouble() ).toInt() );
				}
				procGWorld().wndLineTo(
					value[0].mat().mat(0).toFloat(), value[1].mat().mat(0).toFloat()
					);
				return CLIP_PROC_SUB_END;
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandGPut( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipTokenData? lock;
		int newCode;
		dynamic newToken;

		lock = _this._curLine.token()!.lock();
		if( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();
			if( (newCode & CLIP_CODE_ARRAY_MASK) != 0 ){
				if( newCode == CLIP_CODE_GLOBAL_ARRAY ){
					param = globalParam();
				}

				int width  = procGWorld().width();
				int height = procGWorld().height();

				int _arrayIndex = _this.arrayIndexIndirect( param, newCode, newToken );
				List<int> arrayList = List.filled( 3, 0 );
				arrayList[2] = -1;

				int x, y;
				for( y = 0; y < height; y++ ){
					arrayList[0] = y;
					for( x = 0; x < width; x++ ){
						arrayList[1] = x;
						procGWorld().putColor(
							x, y,
							MATH_UNSIGNED( param.array().val( _arrayIndex, arrayList, 2 ).toFloat(), procGWorld().umax().toDouble() ).toInt()
							);
					}
				}

				return CLIP_PROC_SUB_END;
			} else {
				int ret = CLIP_NO_ERR;
				List<ClipProcVal> value = newProcValArray( 3, _this, param );

				_this._curLine.token()!.unlock( lock );
				for( int i = 0; i < 2; i++ ){
					ret = _this._const( param, code, token, value[i] );
				}
				if( ret == CLIP_NO_ERR ){
					if( _this._const( param, code, token, value[2] ) == CLIP_NO_ERR ){
						procGWorld().setColor( MATH_UNSIGNED( value[2].mat().mat(0).toFloat(), procGWorld().umax().toDouble() ).toInt() );
					}
					procGWorld().put( MATH_INT( value[0].mat().mat(0).toFloat() ).toInt(), MATH_INT( value[1].mat().mat(0).toFloat() ).toInt() );
					return CLIP_PROC_SUB_END;
				}
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandGPut24( ClipProc _this, ClipParam param, int code, dynamic token ){
		if( procGWorld().rgbFlag() ){
			return ClipProc._commandGPut( _this, param, code, token );
		}

		int newCode;
		dynamic newToken;

		if( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();
			if( (newCode & CLIP_CODE_ARRAY_MASK) != 0 ){
				if( newCode == CLIP_CODE_GLOBAL_ARRAY ){
					param = globalParam();
				}

				int width  = procGWorld().width();
				int height = procGWorld().height();

				int _arrayIndex = _this.arrayIndexIndirect( param, newCode, newToken );
				List<int> arrayList = List.filled( 3, 0 );
				arrayList[2] = -1;

				int x, y;
				doCommandGPut24Begin();
				for( y = 0; y < height; y++ ){
					arrayList[0] = y;
					for( x = 0; x < width; x++ ){
						arrayList[1] = x;
						doCommandGPut24(
							x, y,
							MATH_UNSIGNED( param.array().val( _arrayIndex, arrayList, 2 ).toFloat(), MATH_UMAX_24 ).toInt()
							);
					}
				}
				doCommandGPut24End();

				return CLIP_PROC_SUB_END;
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandWPut( ClipProc _this, ClipParam param, int code, dynamic token ){
		int i;
		int ret = CLIP_NO_ERR;
		List<ClipProcVal> value = newProcValArray( 3, _this, param );

		for( i = 0; i < 2; i++ ){
			ret = _this._const( param, code, token, value[i] );
		}
		if( ret == CLIP_NO_ERR ){
			if( _this._const( param, code, token, value[2] ) == CLIP_NO_ERR ){
				procGWorld().setColor( MATH_UNSIGNED( value[2].mat().mat(0).toFloat(), procGWorld().umax().toDouble() ).toInt() );
			}
			procGWorld().wndPut( value[0].mat().mat(0).toFloat(), value[1].mat().mat(0).toFloat() );
			return CLIP_PROC_SUB_END;
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandGGet( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipTokenData? lock;
		int newCode;
		dynamic newToken;

		lock = _this._curLine.token()!.lock();
		if( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();
			if( (newCode & CLIP_CODE_ARRAY_MASK) != 0 ){
				if( newCode == CLIP_CODE_GLOBAL_ARRAY ){
					param = globalParam();
				}

				int width  = procGWorld().width();
				int height = procGWorld().height();

				int _arrayIndex = _this.arrayIndexIndirect( param, newCode, newToken );
				List<int> arrayList = List.filled( 3, 0 );
				List<int> resizeList = List.filled( 3, 0 );
				resizeList[0] = height - 1;
				resizeList[1] = width  - 1;
				resizeList[2] = -1;
				arrayList [2] = -1;
				bool moveFlag = (newCode == CLIP_CODE_ARRAY);

				int x, y;
				for( y = 0; y < height; y++ ){
					arrayList[0] = y;
					for( x = 0; x < width; x++ ){
						arrayList[1] = x;
						param.array().resize(
							_arrayIndex, resizeList, arrayList, 2,
							procGWorld().get( x, y ), moveFlag
							);
					}
				}

				return CLIP_PROC_SUB_END;
			} else {
				int ret = CLIP_NO_ERR;
				List<ClipProcVal> value = newProcValArray( 2, _this, param );

				_this._curLine.token()!.unlock( lock );
				for( int i = 0; i < 2; i++ ){
					ret = _this._const( param, code, token, value[i] );
				}
				if( ret == CLIP_NO_ERR ){
					if( _this._curLine.token()!.getTokenParam( param ) ){
						newCode  = getCode();
						newToken = getToken();
						if( (newCode & CLIP_CODE_VAR_MASK) != 0 ){
							if( newCode == CLIP_CODE_GLOBAL_VAR ){
								param = globalParam();
							}
							ParamBoolean moveFlag = ParamBoolean();
							int index = _this.varIndexIndirectMove( param, newCode, newToken, moveFlag );
							if( !(param.setVal(
								index,
								procGWorld().get( MATH_INT( value[0].mat().mat(0).toFloat() ).toInt(), MATH_INT( value[1].mat().mat(0).toFloat() ).toInt() ),
								moveFlag.val()
							)) ){
								return _this._retError( CLIP_PROC_ERR_ASS, code, token );
							}
							return CLIP_PROC_SUB_END;
						}
					}
				}
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandGGet24( ClipProc _this, ClipParam param, int code, dynamic token ){
		if( procGWorld().rgbFlag() ){
			return ClipProc._commandGGet( _this, param, code, token );
		}

		int newCode;
		dynamic newToken;

		if( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();
			if( (newCode & CLIP_CODE_ARRAY_MASK) != 0 ){
				if( newCode == CLIP_CODE_GLOBAL_ARRAY ){
					param = globalParam();
				}

				ParamInteger w = ParamInteger();
				ParamInteger h = ParamInteger();
				List<int>? data = doCommandGGet24Begin( w, h );
				if( data != null ){
					int width  = w.val();
					int height = h.val();

					int _arrayIndex = _this.arrayIndexIndirect( param, newCode, newToken );
					List<int> arrayList = List.filled( 3, 0 );
					List<int> resizeList = List.filled( 3, 0 );
					resizeList[0] = height - 1;
					resizeList[1] = width  - 1;
					resizeList[2] = -1;
					arrayList [2] = -1;
					bool moveFlag = (newCode == CLIP_CODE_ARRAY);

					int x, y, r, g, b;
					int i = 0;
					for( y = 0; y < height; y++ ){
						arrayList[0] = y;
						for( x = 0; x < width; x++ ){
							arrayList[1] = x;
							r = data[i++];
							g = data[i++];
							b = data[i++];
							i++;
							param.array().resize(
								_arrayIndex, resizeList, arrayList, 2,
								(r << 16) + (g << 8) + b, moveFlag
								);
						}
					}

					doCommandGGet24End();
				}

				return CLIP_PROC_SUB_END;
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandWGet( ClipProc _this, ClipParam param, int code, dynamic token ){
		int i;
		int ret = CLIP_NO_ERR;
		List<ClipProcVal> value = newProcValArray( 2, _this, param );

		for( i = 0; i < 2; i++ ){
			ret = _this._const( param, code, token, value[i] );
		}
		if( ret == CLIP_NO_ERR ){
			int newCode;
			dynamic newToken;

			if( _this._curLine.token()!.getTokenParam( param ) ){
				newCode  = getCode();
				newToken = getToken();
				if( (newCode & CLIP_CODE_VAR_MASK) != 0 ){
					if( newCode == CLIP_CODE_GLOBAL_VAR ){
						param = globalParam();
					}
					ParamBoolean moveFlag = ParamBoolean();
					int index = _this.varIndexIndirectMove( param, newCode, newToken, moveFlag );
					if( !(param.setVal(
						index,
						procGWorld().wndGet( value[0].mat().mat(0).toFloat(), value[1].mat().mat(0).toFloat() ),
						moveFlag.val()
					)) ){
						return _this._retError( CLIP_PROC_ERR_ASS, code, token );
					}
					return CLIP_PROC_SUB_END;
				}
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandGUpdate( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			_this.setGUpdateFlag( MATH_INT( value.mat().mat(0).toFloat() ).toInt() );
		} else {
			_this.setGUpdateFlag( 1 );
		}
		if( _this._gUpdateFlag ){
			doCommandGUpdate( procGWorld() );
		}
		return CLIP_PROC_SUB_END;
	}
	static int _commandRectangular( ClipProc _this, ClipParam param, int code, dynamic token ){
		procGraph().setMode( CLIP_GRAPH_MODE_RECT );
		return CLIP_PROC_SUB_END;
	}
	static int _commandParametric( ClipProc _this, ClipParam param, int code, dynamic token ){
		procGraph().setMode( CLIP_GRAPH_MODE_PARAM );
		return CLIP_PROC_SUB_END;
	}
	static int _commandPolar( ClipProc _this, ClipParam param, int code, dynamic token ){
		procGraph().setMode( CLIP_GRAPH_MODE_POLAR );
		return CLIP_PROC_SUB_END;
	}
	static int _commandLogScale( ClipProc _this, ClipParam param, int code, dynamic token ){
		dynamic newToken;

		if( _this._curLine.token()!.getToken() ){
			newToken = getToken();
			if( getCode() == CLIP_CODE_LABEL ){
				ClipProcVal value = ClipProcVal( _this, param );

				if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
					if( value.mat().mat(0).toFloat() <= 1.0 ){
						return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
					}
				} else {
					value.matAss( 10.0 );
				}
				if( newToken == "x" ){
					procGraph().setLogScaleX( value.mat().mat(0).toFloat() );
				} else if( newToken == "y" ){
					procGraph().setLogScaleY( value.mat().mat(0).toFloat() );
				} else if( newToken == "xy" ){
					procGraph().setLogScaleX( value.mat().mat(0).toFloat() );
					procGraph().setLogScaleY( value.mat().mat(0).toFloat() );
				} else {
					return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
				}
				return CLIP_PROC_SUB_END;
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandNoLogScale( ClipProc _this, ClipParam param, int code, dynamic token ){
		dynamic newToken;

		if( _this._curLine.token()!.getToken() ){
			newToken = getToken();
			if( getCode() == CLIP_CODE_LABEL ){
				if( newToken == "x" ){
					procGraph().setLogScaleX( 0.0 );
				} else if( newToken == "y" ){
					procGraph().setLogScaleY( 0.0 );
				} else if( newToken == "xy" ){
					procGraph().setLogScaleX( 0.0 );
					procGraph().setLogScaleY( 0.0 );
				} else {
					return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
				}
				return CLIP_PROC_SUB_END;
			}
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandPlot( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipTokenData? lock;
		int newCode;
		dynamic newToken;
		List<ClipProcVal> value = newProcValArray( 4, _this, param );

		// 計算式の取り込み
		switch( procGraph().mode() ){
		case CLIP_GRAPH_MODE_RECT:
		case CLIP_GRAPH_MODE_POLAR:
			lock = _this._curLine.token()!.lock();
			if( _this._curLine.token()!.getTokenParam( param ) ){
				newCode  = getCode();
				newToken = getToken();
				if( newCode == CLIP_CODE_STRING ){
					procGraph().setExpr( newToken );
				} else if( (newCode & CLIP_CODE_ARRAY_MASK) != 0 ){
					var tmpParam = (newCode == CLIP_CODE_GLOBAL_ARRAY) ? globalParam() : param;
					var _arrayIndex = _this.arrayIndexIndirect( tmpParam, newCode, newToken );
					procGraph().setExpr( _this.strGet( tmpParam.array(), _arrayIndex ) );
				} else {
					_this._curLine.token()!.unlock( lock );
					break;
				}
			}
			break;
		case CLIP_GRAPH_MODE_PARAM:
			lock = _this._curLine.token()!.lock();
			if( _this._curLine.token()!.getTokenParam( param ) ){
				newCode  = getCode();
				newToken = getToken();
				if( newCode == CLIP_CODE_STRING ){
					procGraph().setExpr1( newToken );
				} else if( (newCode & CLIP_CODE_ARRAY_MASK) != 0 ){
					var tmpParam = (newCode == CLIP_CODE_GLOBAL_ARRAY) ? globalParam() : param;
					var _arrayIndex = _this.arrayIndexIndirect( tmpParam, newCode, newToken );
					procGraph().setExpr1( _this.strGet( tmpParam.array(), _arrayIndex ) );
				} else {
					_this._curLine.token()!.unlock( lock );
					break;
				}
			}
			lock = _this._curLine.token()!.lock();
			if( _this._curLine.token()!.getTokenParam( param ) ){
				newCode  = getCode();
				newToken = getToken();
				if( newCode == CLIP_CODE_STRING ){
					procGraph().setExpr2( newToken );
				} else if( (newCode & CLIP_CODE_ARRAY_MASK) != 0 ){
					ClipParam tmpParam = (newCode == CLIP_CODE_GLOBAL_ARRAY) ? globalParam() : param;
					int _arrayIndex = _this.arrayIndexIndirect( tmpParam, newCode, newToken );
					procGraph().setExpr2( _this.strGet( tmpParam.array(), _arrayIndex ) );
				} else {
					return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
				}
			} else {
				return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
			}
			break;
		}

		procGraph().setColor( procGWorld().color() );

		if( _this._const( param, code, token, value[0] ) == CLIP_NO_ERR ){
			if( _this._const( param, code, token, value[1] ) == CLIP_NO_ERR ){
				switch( procGraph().mode() ){
				case CLIP_GRAPH_MODE_RECT:
					if( _this._const( param, code, token, value[2] ) == CLIP_NO_ERR ){
						// パラメータが3個指定されている...
						procGraph().setColor( MATH_UNSIGNED( value[2].mat().mat(0).toFloat(), procGWorld().umax().toDouble() ).toInt() );
					} else {
						// パラメータが2個指定されている...
					}
					break;
				case CLIP_GRAPH_MODE_PARAM:
				case CLIP_GRAPH_MODE_POLAR:
					if( _this._const( param, code, token, value[2] ) == CLIP_NO_ERR ){
						if( _this._const( param, code, token, value[3] ) == CLIP_NO_ERR ){
							// パラメータが4個指定されている...
							procGraph().setColor( MATH_UNSIGNED( value[3].mat().mat(0).toFloat(), procGWorld().umax().toDouble() ).toInt() );
						} else {
							// パラメータが3個指定されている...
						}
					} else {
						// パラメータが2個しか指定されていない...
						return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
					}
					break;
				}
			} else {
				// パラメータが1個指定されている...
				procGraph().setColor( MATH_UNSIGNED( value[0].mat().mat(0).toFloat(), procGWorld().umax().toDouble() ).toInt() );

				switch( procGraph().mode() ){
				case CLIP_GRAPH_MODE_RECT:
					value[0].matAss( procGWorld().wndPosX( 0 ) );
					value[1].matAss( procGWorld().wndPosX( procGWorld().width() - 1 ) );
					break;
				case CLIP_GRAPH_MODE_PARAM:
				case CLIP_GRAPH_MODE_POLAR:
					value[0].matAss(   0.0 ); value[0].mat().mat(0).angToAng( MATH_ANG_TYPE_DEG, complexAngType() );
					value[1].matAss( 360.0 ); value[1].mat().mat(0).angToAng( MATH_ANG_TYPE_DEG, complexAngType() );
					value[2].matAss(   1.0 ); value[2].mat().mat(0).angToAng( MATH_ANG_TYPE_DEG, complexAngType() );
					break;
				}
			}
		} else {
			// パラメータが指定されていない...
			switch( procGraph().mode() ){
			case CLIP_GRAPH_MODE_RECT:
				value[0].matAss( procGWorld().wndPosX( 0 ) );
				value[1].matAss( procGWorld().wndPosX( procGWorld().width() - 1 ) );
				break;
			case CLIP_GRAPH_MODE_PARAM:
			case CLIP_GRAPH_MODE_POLAR:
				value[0].matAss(   0.0 ); value[0].mat().mat(0).angToAng( MATH_ANG_TYPE_DEG, complexAngType() );
				value[1].matAss( 360.0 ); value[1].mat().mat(0).angToAng( MATH_ANG_TYPE_DEG, complexAngType() );
				value[2].matAss(   1.0 ); value[2].mat().mat(0).angToAng( MATH_ANG_TYPE_DEG, complexAngType() );
				break;
			}
		}

		// 親プロセスの環境を受け継いで、子プロセスを実行する
		ClipProc childProc = ClipProc( param.mode(), param.mpPrec(), param.mpRound(), false, _this._printAssert, _this._printWarn, false/*グラフィック画面更新OFF*/ );
		ClipParam childParam = ClipParam( _this._curLine.num(), param, true );
		_this.initEvalProc( childParam, param );
		doCommandPlot( _this, childProc, childParam, procGraph(), value[0].mat().mat(0).toFloat(), value[1].mat().mat(0).toFloat(), value[2].mat().mat(0).toFloat() );
		childProc.end();
		childParam.end();

		return CLIP_PROC_SUB_END;
	}
	static int _commandRePlot( ClipProc _this, ClipParam param, int code, dynamic token ){
		List<ClipProcVal> value = newProcValArray( 4, _this, param );

		procGraph().setColor( procGWorld().color() );

		if( _this._const( param, code, token, value[0] ) == CLIP_NO_ERR ){
			if( _this._const( param, code, token, value[1] ) == CLIP_NO_ERR ){
				switch( procGraph().mode() ){
				case CLIP_GRAPH_MODE_RECT:
					if( _this._const( param, code, token, value[2] ) == CLIP_NO_ERR ){
						// パラメータが3個指定されている...
						procGraph().setColor( MATH_UNSIGNED( value[2].mat().mat(0).toFloat(), procGWorld().umax().toDouble() ).toInt() );
					} else {
						// パラメータが2個指定されている...
					}
					break;
				case CLIP_GRAPH_MODE_PARAM:
				case CLIP_GRAPH_MODE_POLAR:
					if( _this._const( param, code, token, value[2] ) == CLIP_NO_ERR ){
						if( _this._const( param, code, token, value[3] ) == CLIP_NO_ERR ){
							// パラメータが4個指定されている...
							procGraph().setColor( MATH_UNSIGNED( value[3].mat().mat(0).toFloat(), procGWorld().umax().toDouble() ).toInt() );
						} else {
							// パラメータが3個指定されている...
						}
					} else {
						// パラメータが2個しか指定されていない...
						return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
					}
					break;
				}
			} else {
				// パラメータが1個指定されている...
				procGraph().setColor( MATH_UNSIGNED( value[0].mat().mat(0).toFloat(), procGWorld().umax().toDouble() ).toInt() );

				switch( procGraph().mode() ){
				case CLIP_GRAPH_MODE_RECT:
					value[0].matAss( procGWorld().wndPosX( 0 ) );
					value[1].matAss( procGWorld().wndPosX( procGWorld().width() - 1 ) );
					break;
				case CLIP_GRAPH_MODE_PARAM:
				case CLIP_GRAPH_MODE_POLAR:
					value[0].matAss(   0.0 ); value[0].mat().mat(0).angToAng( MATH_ANG_TYPE_DEG, complexAngType() );
					value[1].matAss( 360.0 ); value[1].mat().mat(0).angToAng( MATH_ANG_TYPE_DEG, complexAngType() );
					value[2].matAss(   1.0 ); value[2].mat().mat(0).angToAng( MATH_ANG_TYPE_DEG, complexAngType() );
					break;
				}
			}
		} else {
			// パラメータが指定されていない...
			switch( procGraph().mode() ){
			case CLIP_GRAPH_MODE_RECT:
				value[0].matAss( procGWorld().wndPosX( 0 ) );
				value[1].matAss( procGWorld().wndPosX( procGWorld().width() - 1 ) );
				break;
			case CLIP_GRAPH_MODE_PARAM:
			case CLIP_GRAPH_MODE_POLAR:
				value[0].matAss(   0.0 ); value[0].mat().mat(0).angToAng( MATH_ANG_TYPE_DEG, complexAngType() );
				value[1].matAss( 360.0 ); value[1].mat().mat(0).angToAng( MATH_ANG_TYPE_DEG, complexAngType() );
				value[2].matAss(   1.0 ); value[2].mat().mat(0).angToAng( MATH_ANG_TYPE_DEG, complexAngType() );
				break;
			}
		}

		// 親プロセスの環境を受け継いで、子プロセスを実行する
		ClipProc childProc = ClipProc( param.mode(), param.mpPrec(), param.mpRound(), false, _this._printAssert, _this._printWarn, false/*グラフィック画面更新OFF*/ );
		ClipParam childParam = ClipParam( _this._curLine.num(), param, true );
		_this.initEvalProc( childParam, param );
		doCommandRePlot( _this, childProc, childParam, procGraph(), value[0].mat().mat(0).toFloat(), value[1].mat().mat(0).toFloat(), value[2].mat().mat(0).toFloat() );
		childProc.end();
		childParam.end();

		return CLIP_PROC_SUB_END;
	}
	static int _commandCalculator( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			param.setCalculator( value.mat().notEqual( 0.0 ) );
			return CLIP_PROC_SUB_END;
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandInclude( ClipProc _this, ClipParam param, int code, dynamic token ){
		int ret;

		ClipLineData saveCurLine  = _this._curLine;
		ClipLine? saveProcLine = _this._procLine;
		String? saveFuncName = param.funcName();
		String? saveDefNameSpace = param.defNameSpace();
		String? saveNameSpace = param.nameSpace();

		dynamic newToken;
		if( _this._curLine.token()!.getToken() ){
			newToken = getToken();
			if( getCode() == CLIP_CODE_EXTFUNC ){
				String name = newToken + ".inc";
				ClipFuncData? func;
				if( (func = procFunc().search( name, true, null )) != null ){
					if( _this.mainLoop( func, param, null, null ) == CLIP_PROC_END ){
						ret = CLIP_NO_ERR;
					} else {
						ret = _this._retError( CLIP_PROC_ERR_EXTFUNC, CLIP_CODE_EXTFUNC, name );
					}
				} else if( (func = _this.newFuncCache( name, param, null )) != null ){
					if( _this.mainLoop( func, param, null, null ) == CLIP_PROC_END ){
						ret = CLIP_NO_ERR;
					} else {
						ret = _this._retError( CLIP_PROC_ERR_EXTFUNC, CLIP_CODE_EXTFUNC, name );
					}
				} else if( _this.mainLoop( name, param, null, null ) == CLIP_PROC_END ){
					ret = CLIP_NO_ERR;
				} else {
					ret = _this._retError( CLIP_PROC_ERR_EXTFUNC, CLIP_CODE_EXTFUNC, name );
				}
			} else {
				ret = _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
			}
		} else {
			ret = _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
		}

		_this._curLine  = saveCurLine;
		_this._procLine = saveProcLine;
		param.setFuncName( saveFuncName );
		param.setDefNameSpace( saveDefNameSpace );
		param.setNameSpace( saveNameSpace );

		return (ret == CLIP_NO_ERR) ? CLIP_PROC_SUB_END : ret;
	}
	static int _commandBase( ClipProc _this, ClipParam param, int code, dynamic token ){
		ClipProcVal value = ClipProcVal( _this, param );

		if( _this._const( param, code, token, value ) == CLIP_NO_ERR ){
			param.setBase( value.mat().notEqual( 0.0 ) ? 1 : 0 );
			return CLIP_PROC_SUB_END;
		}
		return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
	}
	static int _commandNameSpace( ClipProc _this, ClipParam param, int code, dynamic token ){
		if( _this._curLine.token()!.getToken() ){
			String nameSpace = _proc_token.tokenString( param, getCode(), getToken() );
			if( nameSpace.isNotEmpty ){
				param.setNameSpace( nameSpace );
				return CLIP_PROC_SUB_END;
			}
			return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
		}
		param.resetNameSpace();
		return CLIP_PROC_SUB_END;
	}
	static int _commandUse( ClipProc _this, ClipParam param, int code, dynamic token ){
		int descCode;
		dynamic descToken;
		int realCode;
		dynamic realToken;
		if( _this._curLine.token()!.getToken() ){
			descCode  = getCode();
			descToken = getToken();
			switch( descCode ){
			case CLIP_CODE_LABEL:
			case CLIP_CODE_FUNCTION:
			case CLIP_CODE_EXTFUNC:
				break;
			default:
				return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
			}
			if( _this._curLine.token()!.getToken() ){
				realCode  = getCode();
				realToken = getToken();
				switch( realCode ){
				case CLIP_CODE_LABEL:
				case CLIP_CODE_FUNCTION:
				case CLIP_CODE_EXTFUNC:
					break;
				default:
					return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
				}
			} else {
				return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
			}
		} else {
			return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
		}
		param.setReplace( descCode, descToken, realCode, realToken );
		return CLIP_PROC_SUB_END;
	}
	static int _commandUnuse( ClipProc _this, ClipParam param, int code, dynamic token ){
		int descCode = 0;
		dynamic descToken;
		if( _this._curLine.token()!.getToken() ){
			descCode  = getCode();
			descToken = getToken();
			switch( descCode ){
			case CLIP_CODE_LABEL:
			case CLIP_CODE_FUNCTION:
			case CLIP_CODE_EXTFUNC:
				break;
			default:
				return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
			}
		}
		param.delReplace( descCode, descToken );
		return CLIP_PROC_SUB_END;
	}
	static int _commandDump( ClipProc _this, ClipParam param, int code, dynamic token ){
		int newCode;
		dynamic newToken;

		if( skipCommandLog() ){
			while( true ){
				if( !(_this._curLine.token()!.getTokenParam( param )) ){
					break;
				}
			}
			return CLIP_PROC_SUB_END;
		}

		while( _this._curLine.token()!.getTokenParam( param ) ){
			newCode  = getCode();
			newToken = getToken();
			if( (newCode & CLIP_CODE_VAR_MASK) != 0 ){
				if( newCode == CLIP_CODE_GLOBAL_VAR ){
					doCommandDumpVar( globalParam(), _this.varIndexIndirect( globalParam(), newCode, newToken ) );
				} else {
					doCommandDumpVar( param, _this.varIndexIndirect( param, newCode, newToken ) );
				}
			} else if( (newCode & CLIP_CODE_ARRAY_MASK) != 0 ){
				if( newCode == CLIP_CODE_GLOBAL_ARRAY ){
					doCommandDumpArray( globalParam(), _this.arrayIndexIndirect( globalParam(), newCode, newToken ) );
				} else {
					doCommandDumpArray( param, _this.arrayIndexIndirect( param, newCode, newToken ) );
				}
			} else {
				return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
			}
		}

		return CLIP_PROC_SUB_END;
	}

	static int _procTop( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;

		param.incSubStep();
		if( !param.seFlag() ){
			value.matAss( param.array().matrix(0) );
		}
		ret = _this._processSub( param, value );
		param.decSubStep();

		return ret;
	}
	int _procVariableFirst( ClipParam param, dynamic token, ClipProcVal value ){
		_curInfo._assToken = varIndexParam( param, token );
		value.matAss( param.val( _curInfo._assToken ) );
		_updateMatrix( param, value.mat() );
		return CLIP_NO_ERR;
	}
	static int _procVariable( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		value.matAss( param.val( _this.varIndexParam( param, token ) ) );
		_this._updateMatrix( param, value.mat() );
		return CLIP_NO_ERR;
	}
	static int _procAutoVar( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		value.matAss( param.val( _this.autoVarIndex( param, token ) ) );
		_this._updateMatrix( param, value.mat() );
		return CLIP_NO_ERR;
	}
	static int _procGlobalVar( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		value.matAss( globalParam().val( _this.autoVarIndex( globalParam(), token ) ) );
		_this._updateMatrix( param, value.mat() );
		return CLIP_NO_ERR;
	}
	int _procArrayFirst( ClipParam param, dynamic token, ClipProcVal value ){
		_curInfo._assToken = arrayIndexParam( param, token );

		if( _curLine.token()!.getTokenLock() ){
			if( getCode() == CLIP_CODE_ARRAY_TOP ){
				_initArrayFlag  = true;
				_initArrayCnt   = 0;
				_initArrayMax   = 0;
				_initArrayIndex = arrayIndexDirectMove( param, _curInfo._assCode, _curInfo._assToken, _initArrayMoveFlag );
				_initArray      = ClipToken();
				return _procInitArray( param );
			}
		}

		_getArrayInfo( param, CLIP_CODE_ARRAY, token );

		if( _curInfo._curArraySize == 0 ){
			if( param.mpFlag() ){
				value._mp.attach( param.array().mp(_curInfo._assToken).clone() );
				value.setMpFlag( true );
			} else {
				value.matAss( param.array().matrix(_curInfo._assToken) );
				_updateMatrix( param, value.mat() );
			}
		} else {
			value.matAss( param.array().val( _curInfo._assToken, _curInfo._curArray, _curInfo._curArraySize ) );
			_updateMatrix( param, value.mat() );
		}
		return CLIP_NO_ERR;
	}
	static int _procArray( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int index = _this.arrayIndexParam( param, token );

		if( _this._curLine.token()!.getTokenLock() ){
			if( getCode() == CLIP_CODE_ARRAY_TOP ){
				_this._initArrayFlag  = true;
				_this._initArrayCnt   = 0;
				_this._initArrayMax   = 0;
				_this._initArrayIndex = _this.arrayIndexDirectMove( param, _this._curInfo._assCode, _this._curInfo._assToken, _this._initArrayMoveFlag );
				_this._initArray      = ClipToken();
				return _this._procInitArray( param );
			}
		}

		_this._getArrayInfo( param, code, token );

		if( _this._curInfo._curArraySize == 0 ){
			if( param.mpFlag() ){
				value._mp.attach( param.array().mp(index).clone() );
				value.setMpFlag( true );
			} else {
				value.matAss( param.array().matrix(index) );
				_this._updateMatrix( param, value.mat() );
			}
		} else {
			value.matAss( param.array().val( index, _this._curInfo._curArray, _this._curInfo._curArraySize ) );
			_this._updateMatrix( param, value.mat() );
		}
		return CLIP_NO_ERR;
	}
	static int _procAutoArray( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		ClipParam curParam = param;
		if( code == CLIP_CODE_GLOBAL_ARRAY ){
			param = globalParam();
		}

		if( _this._curLine.token()!.getTokenLock() ){
			if( getCode() == CLIP_CODE_ARRAY_TOP ){
				_this._initArrayFlag  = true;
				_this._initArrayCnt   = 0;
				_this._initArrayMax   = 0;
				_this._initArrayIndex = _this.arrayIndexDirectMove( param, _this._curInfo._assCode, _this._curInfo._assToken, _this._initArrayMoveFlag );
				_this._initArray      = ClipToken();
				return _this._procInitArray( param );
			}
		}

		_this._getArrayInfo( curParam, code, token );

		if( _this._curInfo._curArraySize == 0 ){
			if( param.mpFlag() ){
				value._mp.attach( param.array().mp(_this.autoArrayIndex( param, token )).clone() );
				value.setMpFlag( true );
			} else {
				value.matAss( param.array().matrix(_this.autoArrayIndex( param, token )) );
				_this._updateMatrix( curParam, value.mat() );
			}
		} else {
			value.matAss( param.array().val( _this.autoArrayIndex( param, token ), _this._curInfo._curArray, _this._curInfo._curArraySize ) );
			_this._updateMatrix( curParam, value.mat() );
		}
		return CLIP_NO_ERR;
	}
	static int _procConst( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		value.matAss( token );
		_this._updateMatrix( param, value.mat() );
		return CLIP_NO_ERR;
	}
	static int _procMultiPrec( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		_proc_mp.fset( value.mp(), token );
		return CLIP_NO_ERR;
	}
	static int _procLabel( ClipProc _this, ClipParam parentParam, int code, dynamic token, ClipProcVal value, bool seFlag ){
		ClipToken funcParam = ClipToken();
		ClipFuncData? func;

		// 関数のパラメータを取得する
		if( !(_this._getParams( parentParam, code, token, funcParam, seFlag )) ){
			return _this._retError( CLIP_PROC_ERR_SE_OPERAND, code, token );
		}

		if( (func = parentParam.func().search( token, false, null )) != null ){
			int ret;

			// 親プロセスの環境を受け継いで、子プロセスを実行する
			ClipProc childProc = ClipProc( parentParam.mode(), parentParam.mpPrec(), parentParam.mpRound(), false, _this._printAssert, _this._printWarn, _this._gUpdateFlag );
			ClipParam childParam = ClipParam( _this._curLine.num(), parentParam, false );
			_this.initInternalProc( childProc, func!, childParam, parentParam );
			if( mainProc( _this, parentParam, func, funcParam, childProc, childParam ) == CLIP_PROC_END ){
				childProc.end();
				_this.getAns( childParam, value, parentParam );
				ret = CLIP_NO_ERR;
			} else {
				childProc.end();
				ret = _this._retError( CLIP_PROC_ERR_USERFUNC, code, token );
			}
			childParam.end();

			return ret;
		} else {
			return _this._retError( CLIP_PROC_ERR_CONSTANT, code, token );
		}
	}
	static int _procCommand( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;

		if( (ret = _procSubCommand[token]( _this, param, code, token )) != CLIP_PROC_SUB_END ){
			return ret;
		}

		ClipProcVal tmpValue = ClipProcVal( _this, param );

		if( _this._const( param, code, token, tmpValue ) == CLIP_NO_ERR ){
			return _this._retError( CLIP_PROC_ERR_COMMAND_PARAM, code, token );
		} else {
			return CLIP_PROC_SUB_END;
		}
	}
	static int _procStat( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		return _procSubStat[token]( _this, param, code, token );
	}
	static int _procUnary( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		if( token < CLIP_OP_UNARY_END ){
			return _procSubOp[token]( _this, param, code, token, value );
		} else {
			return _this._retError( CLIP_PROC_ERR_UNARY, code, token );
		}
	}
	static int _procFunc( ClipProc _this, ClipParam param, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;

		clearValueError();
		clearMatrixError();

		if( (ret = _procSubFunc[token]( _this, param, code, token, value, seFlag )) != CLIP_NO_ERR ){
			return ret;
		}
		if( !(param.mpFlag()) ){
			_this._updateMatrix( param, value.mat() );

			if( valueError() ){
				_this._errorProc( CLIP_PROC_WARN_FUNCTION, _this._curLine.num(), param, code, token );
				clearValueError();
			}
		}

		return CLIP_NO_ERR;
	}
	static int _procExtFunc( ClipProc _this, ClipParam parentParam, int code, dynamic token, ClipProcVal value, bool seFlag ){
		int ret;

		ClipToken funcParam = ClipToken();
		ClipFuncData? func;

		// 関数のパラメータを取得する
		if( !(_this._getParams( parentParam, code, token, funcParam, seFlag )) ){
			return _this._retError( CLIP_PROC_ERR_SE_OPERAND, code, token );
		}

		// 親プロセスの環境を受け継いで、子プロセスを実行する
		ClipProc childProc = ClipProc( parentParam.mode(), parentParam.mpPrec(), parentParam.mpRound(), false, _this._printAssert, _this._printWarn, _this._gUpdateFlag );
		ClipParam childParam = ClipParam( _this._curLine.num(), parentParam, false );

		if( (func = procFunc().search( token, true, parentParam.nameSpace() )) != null ){
			if( mainProc( _this, parentParam, func!, funcParam, childProc, childParam ) == CLIP_PROC_END ){
				childProc.end();
				_this.getAns( childParam, value, parentParam );
				ret = CLIP_NO_ERR;
			} else {
				childProc.end();
				ret = _this._retError( CLIP_PROC_ERR_EXTFUNC, code, token );
			}
		} else if( (func = _this.newFuncCache( token, childParam, parentParam.nameSpace() )) != null ){
			if( mainProc( _this, parentParam, func!, funcParam, childProc, childParam ) == CLIP_PROC_END ){
				childProc.end();
				_this.getAns( childParam, value, parentParam );
				ret = CLIP_NO_ERR;
			} else {
				childProc.end();
				ret = _this._retError( CLIP_PROC_ERR_EXTFUNC, code, token );
			}
		} else if( mainProc( _this, parentParam, token, funcParam, childProc, childParam ) == CLIP_PROC_END ){
			childProc.end();
			_this.getAns( childParam, value, parentParam );
			ret = CLIP_NO_ERR;
		} else {
			childProc.end();
			ret = _this._retError( CLIP_PROC_ERR_EXTFUNC, code, token );
		}

		childParam.end();

		return ret;
	}

	static bool _procMain1( ClipProc _this, String func, ClipParam childParam, ParamInteger step, ParamInteger err, ParamInteger ret ){
		if( childParam.fileDataGet() >= childParam.fileDataArray()!.length ){
			ret.set( CLIP_PROC_END );
			return false;
		}
		step.set( _this.beginProcess( childParam.fileData( childParam.fileDataGet() ), childParam, err ) ? 1 : 2 );
		childParam.incFileDataGet();
		return true;
	}
	static bool _procMain2( ClipProc _this, String func, ClipParam childParam, ParamInteger step, ParamInteger err, ParamInteger ret ){
		if( !_this.process( childParam, err ) ){
			step.set( 2 );
		}
		return true;
	}
	static bool _procMain3( ClipProc _this, String func, ClipParam childParam, ParamInteger step, ParamInteger err, ParamInteger ret ){
		if( ret.set( _this.termProcess( childParam, err ) ).val() != CLIP_LOOP_CONT ){
			return false;
		}
		step.set( 0 );

		childParam.incLineNum();
		return true;
	}

	static bool _procMain1Cache( ClipProc _this, ClipFuncData func, ClipParam childParam, ParamInteger step, ParamInteger err, ParamInteger ret ){
		step.set( _this.beginProcess( func.line(), childParam, err ) ? 1 : 2 );
		return true;
	}
	static bool _procMain2Cache( ClipProc _this, ClipFuncData func, ClipParam childParam, ParamInteger step, ParamInteger err, ParamInteger ret ){
		if( !_this.process( childParam, err ) ){
			step.set( 2 );
		}
		return true;
	}
	static bool _procMain3Cache( ClipProc _this, ClipFuncData func, ClipParam childParam, ParamInteger step, ParamInteger err, ParamInteger ret ){
		if( ret.set( _this.termProcess( childParam, err ) ).val() != CLIP_LOOP_CONT ){
			return false;
		}
		step.set( 0 );

		ret.set( CLIP_PROC_END );
		return false;
	}

	static bool _procTest1( ClipProc _this, String func, ClipParam childParam, ParamInteger step, ParamInteger err, ParamInteger ret ){
		if( childParam.fileDataGet() >= childParam.fileDataArray()!.length ){
			ret.set( CLIP_PROC_END );
			return false;
		}
		step.set( _this.beginTestProcess( childParam.fileData( childParam.fileDataGet() ), childParam, err ) ? 1 : 2 );
		childParam.incFileDataGet();
		return true;
	}
	static bool _procTest2( ClipProc _this, String func, ClipParam childParam, ParamInteger step, ParamInteger err, ParamInteger ret ){
		if( !_this.testProcess( childParam, err ) ){
			step.set( 2 );
		}
		return true;
	}
	static bool _procTest3( ClipProc _this, String func, ClipParam childParam, ParamInteger step, ParamInteger err, ParamInteger ret ){
		if( ret.set( _this.termTestProcess( childParam, err ) ).val() != CLIP_LOOP_CONT ){
			return false;
		}
		step.set( 0 );

		childParam.incLineNum();
		return true;
	}

	static final List<int Function( ClipProc, ClipParam, int, dynamic, ClipProcVal, bool )> _procSubFunc = [
		_funcDefined,
		_funcIndexOf,

		_funcIsInf,
		_funcIsNaN,

		_funcRand,
		_funcTime,
		_funcMkTime,
		_funcTmSec,
		_funcTmMin,
		_funcTmHour,
		_funcTmMDay,
		_funcTmMon,
		_funcTmYear,
		_funcTmWDay,
		_funcTmYDay,
		_funcTmXMon,
		_funcTmXYear,

		_funcA2D,
		_funcA2G,
		_funcA2R,
		_funcD2A,
		_funcD2G,
		_funcD2R,
		_funcG2A,
		_funcG2D,
		_funcG2R,
		_funcR2A,
		_funcR2D,
		_funcR2G,

		_funcSin,
		_funcCos,
		_funcTan,
		_funcASin,
		_funcACos,
		_funcATan,
		_funcATan2,
		_funcSinH,
		_funcCosH,
		_funcTanH,
		_funcASinH,
		_funcACosH,
		_funcATanH,
		_funcExp,
		_funcExp10,
		_funcLn,
		_funcLog,
		_funcLog10,
		_funcPow,
		_funcSqr,
		_funcSqrt,
		_funcCeil,
		_funcFloor,
		_funcAbs,
		_funcLdexp,
		_funcFrexp,
		_funcModf,
		_funcFact,

		_funcInt,
		_funcReal,
		_funcImag,
		_funcArg,
		_funcNorm,
		_funcConjg,
		_funcPolar,

		_funcNum,
		_funcDenom,

		_funcRow,
		_funcCol,
		_funcTrans,

		_funcStrCmp,
		_funcStrCmp,
		_funcStrLen,

		_funcGWidth,
		_funcGHeight,
		_funcGColor,
		_funcGColor,
		_funcGCX,
		_funcGCY,
		_funcWCX,
		_funcWCY,
		_funcGGet,
		_funcWGet,
		_funcGX,
		_funcGY,
		_funcWX,
		_funcWY,
		_funcMkColor,
		_funcMkColorS,
		_funcColGetR,
		_funcColGetG,
		_funcColGetB,

		_funcCall,
		_funcEval,

		_funcMp,
		_funcMRound
	];

	static final List<int Function( ClipProc, ClipParam, int, dynamic, ClipProcVal )> _procSubOp = [
		_unaryIncrement,
		_unaryDecrement,
		_unaryComplement,
		_unaryNot,
		_unaryMinus,
		_unaryPlus,

		_opPostfixInc,
		_opPostfixDec,

		_opMul,
		_opDiv,
		_opMod,

		_opAdd,
		_opSub,

		_opShiftL,
		_opShiftR,

		_opLess,
		_opLessOrEq,
		_opGreat,
		_opGreatOrEq,

		_opEqual,
		_opNotEqual,

		_opAND,

		_opXOR,

		_opOR,

		_opLogAND,

		_opLogOR,

		_opConditional,

		_opAss,
		_opMulAndAss,
		_opDivAndAss,
		_opModAndAss,
		_opAddAndAss,
		_opSubAndAss,
		_opShiftLAndAss,
		_opShiftRAndAss,
		_opANDAndAss,
		_opORAndAss,
		_opXORAndAss,

		_opComma,

		_opPow,
		_opPowAndAss,

		_opFact
	];

	static final List<int Function( ClipProc )> _procSubLoop = [
		_loopBegin,
		_loopEnd,
		_loopEnd,
		_loopEnd,
		_loopEnd,
		_loopEnd,
		_loopEnd,
		_loopCont,

		_loopBegin,
		_loopUntil,

		_loopWhile,
		_loopEndWhile,

		_loopFor,
		_loopFor,
		_loopNext,

		_loopFunc,
		_loopEndFunc,

		_loopMultiEnd,

		_loopIf,
		_loopElIf,
		_loopElse,
		_loopEndIf,

		_loopSwitch,
		_loopCase,
		_loopDefault,
		_loopEndSwi,
		_loopBreakSwi,

		_loopContinue,
		_loopBreak,
		_loopContinue,
		_loopBreak,

		_loopAssert,
		_loopReturn,
		_loopReturn,
		_loopReturn
	];

	static final List<int Function( ClipProc, ClipParam, int, dynamic )> _procSubStat = [
		_statStart,
		_statEnd,
		_statEndInc,
		_statEndDec,
		_statEndEq,
		_statEndEqInc,
		_statEndEqDec,
		_statCont,

		_statDo,
		_statUntil,

		_statWhile,
		_statEndWhile,

		_statFor,
		_statFor2,
		_statNext,

		_statFunc,
		_statEndFunc,

		_statMultiEnd,

		_statIf,
		_statElIf,
		_statElse,
		_statEndIf,

		_statSwitch,
		_statCase,
		_statDefault,
		_statEndSwi,
		_statBreakSwi,

		_statContinue,
		_statBreak,
		_statContinue2,
		_statBreak2,

		_statAssert,
		_statReturn,
		_statReturn2,
		_statReturn3
	];

	static final List<int Function( ClipProc, ClipParam, int, dynamic )> _procSubCommand = [
		_commandNull,

		_commandEFloat,
		_commandFFloat,
		_commandGFloat,
		_commandEComplex,
		_commandFComplex,
		_commandGComplex,
		_commandPrec,

		_commandIFract,
		_commandMFract,

		_commandHTime,
		_commandMTime,
		_commandSTime,
		_commandFTime,
		_commandFps,

		_commandSChar,
		_commandUChar,
		_commandSShort,
		_commandUShort,
		_commandSLong,
		_commandULong,
		_commandSInt,
		_commandUInt,
		_commandRadix,

		_commandFMultiPrec,
		_commandIMultiPrec,

		_commandPType,

		_commandRad,
		_commandDeg,
		_commandGrad,

		_commandAngle,

		_commandAns,
		_commandAssert,
		_commandWarn,

		_commandParam,
		_commandParams,

		_commandDefine,
		_commandEnum,
		_commandUnDef,
		_commandVar,
		_commandArray,
		_commandLocal,
		_commandGlobal,
		_commandLabel,
		_commandParent,

		_commandReal,
		_commandImag,

		_commandNum,
		_commandDenom,

		_commandMat,
		_commandTrans,

		_commandSRand,
		_commandLocalTime,
		_commandArrayCopy,
		_commandArrayFill,

		_commandStrCpy,
		_commandStrCpy,
		_commandStrLwr,
		_commandStrUpr,

		_commandClear,
		_commandError,
		_commandPrint,
		_commandPrint,
		_commandPrint,
		_commandScan,

		_commandGWorld,
		_commandGWorld,
		_commandGClear,
		_commandGColor,
		_commandGFill,
		_commandGMove,
		_commandGText,
		_commandGTextR,
		_commandGTextL,
		_commandGTextRL,
		_commandGLine,
		_commandGPut,
		_commandGPut24,
		_commandGGet,
		_commandGGet24,
		_commandGUpdate,

		_commandWindow,
		_commandWFill,
		_commandWMove,
		_commandWText,
		_commandWTextR,
		_commandWTextL,
		_commandWTextRL,
		_commandWLine,
		_commandWPut,
		_commandWGet,

		_commandRectangular,
		_commandParametric,
		_commandPolar,
		_commandLogScale,
		_commandNoLogScale,
		_commandPlot,
		_commandRePlot,

		_commandCalculator,

		_commandInclude,

		_commandBase,

		_commandNameSpace,

		_commandUse,
		_commandUnuse,

		_commandDump,
		_commandPrint
	];
	void addProcSubCommand( List<int Function( ClipProc, ClipParam, int, dynamic )> funcArray ){
		_procSubCommand.addAll( funcArray );
	}

	static final List<int Function( ClipProc, ClipParam, int, dynamic, ClipProcVal )> _procSubSe = [
		_seNull,

		_seIncrement,
		_seDecrement,
		_seNegative,

		_seComplement,
		_seNot,
		_seMinus,

		_seSet,
		_seSetC,
		_seSetF,
		_seSetM,

		_seMul,
		_seDiv,
		_seMod,
		_seAdd,
		_seAddS,
		_seSub,
		_seSubS,
		_sePow,
		_seShiftL,
		_seShiftR,
		_seAND,
		_seOR,
		_seXOR,

		_seLess,
		_seLessOrEq,
		_seGreat,
		_seGreatOrEq,
		_seEqual,
		_seNotEqual,
		_seLogAND,
		_seLogOR,

		_seMulAndAss,
		_seDivAndAss,
		_seModAndAss,
		_seAddAndAss,
		_seAddSAndAss,
		_seSubAndAss,
		_seSubSAndAss,
		_sePowAndAss,
		_seShiftLAndAss,
		_seShiftRAndAss,
		_seANDAndAss,
		_seORAndAss,
		_seXORAndAss,

		_seLessAndAss,
		_seLessOrEqAndAss,
		_seGreatAndAss,
		_seGreatOrEqAndAss,
		_seEqualAndAss,
		_seNotEqualAndAss,
		_seLogANDAndAss,
		_seLogORAndAss,

		_seConditional,

		_seSetFALSE,
		_seSetTRUE,
		_seSetZero,

		_seSaturate,
		_seSetS
	];

	static final List<int Function( ClipProc, ClipParam, int, dynamic, ClipProcVal, bool )> _procSub = [
		_procTop,

		_procVariable,
		_procAutoVar,
		_procGlobalVar,

		_procArray,
		_procAutoArray,
		_procAutoArray,

		_procConst,
		_procMultiPrec,
		_procLabel,
		_procCommand,
		_procStat,
		_procUnary,
		_procFunc,
		_procExtFunc
	];

	static final List<bool Function( ClipProc, String, ClipParam, ParamInteger, ParamInteger, ParamInteger )> _procMain = [
		_procMain1,
		_procMain2,
		_procMain3
	];

	static final List<bool Function( ClipProc, ClipFuncData, ClipParam, ParamInteger, ParamInteger, ParamInteger )> _procMainCache = [
		_procMain1Cache,
		_procMain2Cache,
		_procMain3Cache
	];

	static final List<bool Function( ClipProc, String, ClipParam, ParamInteger, ParamInteger, ParamInteger )> _procTest = [
		_procTest1,
		_procTest2,
		_procTest3
	];
}

List<String>? Function( String ) getExtFuncDataDirect = ( func ){ return null; };
List<String>? Function( String ) getExtFuncDataNameSpace = ( func ){ return null; };

int Function( ClipProc, ClipParam, ClipFuncData, ClipToken, ClipProc, ClipParam ) mainProc = ( parentProc, parentParam, func, funcParam, childProc, childParam ){ return CLIP_PROC_END; };
bool Function( int, String? ) assertProc = ( num, func ){ return false; };
void Function( int, int, String, String ) errorProc = ( err, num, func, token ){};

void Function( ClipParam, ClipToken, int, String?, bool ) printTrace = ( param, line, num, comment, skipFlag ){};
void Function( ClipParam, ClipToken, int, String? ) printTest = ( param, line, num, comment ){};
void Function( String, String ) printAnsComplex = ( real, imag ){};
void Function( String ) printAnsMultiPrec = ( str ){};
void Function( ClipParam, ClipToken ) printAnsMatrix = ( param, array ){};
void Function( String, int, String ) printWarn = ( warn, num, func ){};
void Function( String, int, String ) printError = ( error, num, func ){};

int Function( int ) doFuncGColor = ( rgb ){ return 0; };
int Function( int ) doFuncGColor24 = ( index ){ return 0x000000; };
int Function( ClipProc, ClipProc, ClipParam, String, ClipProcVal ) doFuncEval = ( parentProc, childProc, childParam, string, value ){ return CLIP_NO_ERR; };

void Function() doCommandClear = (){};
void Function( ClipProcPrint?, bool ) doCommandPrint = ( topPrint, flag ){};
void Function( ClipProcScan, ClipProc, ClipParam ) doCommandScan = ( topScan, proc, param ){};
void Function( int, int ) doCommandGWorld = ( width, height ){};
void Function( int, int ) doCommandGWorld24 = ( width, height ){};
void Function( double, double, double, double ) doCommandWindow = ( left, bottom, right, top ){};
void Function( int, int ) doCommandGColor = ( index, rgb ){};
void Function() doCommandGPut24Begin = (){};
void Function( int, int, int ) doCommandGPut24 = ( x, y, rgb ){};
void Function() doCommandGPut24End = (){};
List<int>? Function( ParamInteger, ParamInteger ) doCommandGGet24Begin = ( width, height ){ return null; };
void Function() doCommandGGet24End = (){};
void Function( ClipGWorld ) doCommandGUpdate = ( gWorld ){};
void Function( ClipProc, ClipProc, ClipParam, ClipGraph, double, double, double ) doCommandPlot = ( parentProc, childProc, childParam, graph, start, end, step ){};
void Function( ClipProc, ClipProc, ClipParam, ClipGraph, double, double, double ) doCommandRePlot = ( parentProc, childProc, childParam, graph, start, end, step ){};
void Function( ClipProcUsage? ) doCommandUsage = ( topUsage ){};

bool Function() skipCommandLog = (){ return true; };
void Function( ClipProcPrint? ) doCommandLog = ( topPrint ){};
void Function( ClipParam, int ) doCommandDumpVar = ( param, index ){};
void Function( ClipParam, int ) doCommandDumpArray = ( param, index ){};

void Function() onStartPlot = (){};
void Function() onEndPlot = (){};
void Function() onStartRePlot = (){};
void Function() onEndRePlot = (){};

int doFuncGColorBGR( int rgb, List<int> bgrColorArray ){
	int i, j;
	int r = (rgb & 0xFF0000) >> 16;
	int g = (rgb & 0x00FF00) >> 8;
	int b =  rgb & 0x0000FF;
	int rr, gg, bb, tmp;
	int d = 766/*255*3+1*/;
	j = 0;
	for( i = 0; i < 256; i++ ){
		rr =  bgrColorArray[i] & 0x0000FF;
		gg = (bgrColorArray[i] & 0x00FF00) >> 8;
		bb = (bgrColorArray[i] & 0xFF0000) >> 16;
		tmp = (MATH_ABS( (rr - r).toDouble() ) + MATH_ABS( (gg - g).toDouble() ) + MATH_ABS( (bb - b).toDouble() )).toInt();
		if( tmp < d ){
			j = i;
			d = tmp;
		}
	}
	return j;
}

int CLIP_RGB2BGR( int data ){
	return ((data & 0x0000FF) << 16) + (data & 0x00FF00) + ((data & 0xFF0000) >> 16);
}
