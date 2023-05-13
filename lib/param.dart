/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import 'array.dart';
import 'func.dart';
import 'global.dart';
import 'line.dart';
import 'math/math.dart';
import 'math/multiprec.dart';
import 'math/value.dart';
import 'proc.dart';
import 'token.dart';
import 'variable.dart';

// 置き換え
class _ClipReplace {
	late int _descCode;
	late dynamic _descToken;
	late int _realCode;
	late dynamic _realToken;
	_ClipReplace( int descCode, dynamic descToken, int realCode, dynamic realToken ){
		_descCode  = descCode;
		_descToken = descToken;
		_realCode  = realCode;
		_realToken = realToken;
	}
}

// 計算パラメータ
class ClipParam {
	// 呼び出し元情報
	late int _parentNum;
	late String _parentFunc;

	late bool _calculator;
	late int _base;
	late int _mode;
	late double _fps;
	late int _prec;
	late int _radix;
	late int _mpPrec;
	late int _mpRound;

	late int? _saveMode;
	late double? _saveFps;

	late int _saveRadix;

	late ClipVariable _var; // 変数
	late ClipArray _array; // 配列
	late ClipFunc _func; // ユーザー定義関数

	// 外部関数関連
	late String? _funcName; // 外部関数名
	late List<String>? _fileData; // 計算対象のファイル内容
	late int _fileDataGet;
	late ClipLine? _fileLine; // 計算対象の行管理クラス
	late bool _fileFlag; // ファイルか標準入力かのフラグ
	late int _topNum;
	late int _lineNum; // 行番号

	// 各種フラグ
	late bool _enableCommand; // コマンドが使用できるかどうかのフラグ
	late bool _enableOpPow; // 累乗演算子"^"が使用できるかどうかのフラグ
	late bool _enableStat; // ステートメントが使用できるかどうかのフラグ
	late bool _printAns; // 一行の計算が終了した時に計算結果を表示するかどうかのフラグ
	late bool _assFlag; // 最後の計算が代入かどうかのフラグ
	late int _subStep; // 括弧内の計算中かどうかのフラグ

	late ClipParam? _parent; // 親プロセスの計算パラメータ

	// 親プロセスのパラメータ値を更新するかどうかのフラグ
	late List<bool> _updateParam;
	late List<int> _updateParamCode;
	late List<int> _updateParamIndex;

	// 親プロセスの変数・配列を更新するかどうかのフラグ
	late List<int> _updateParentVar;
	late List<int> _updateParentArray;

	late String? _defNameSpace;
	late String? _nameSpace;

	late bool _seFlag;
	late int _seToken;

	late bool _mpFlag;

	late List<_ClipReplace> _replace;

	ClipParam( [int num = 0, ClipParam? parentParam, bool inherit = false] ){
		// 呼び出し元情報
		_parentNum = (parentParam == null) ? 0 : (
			parentParam._fileFlag ? ((parentParam._topNum > 0) ? num - parentParam._topNum + 1 : num) : 0
			);
		_parentFunc = (parentParam == null) ? "" : (
			(parentParam._funcName == null) ? "" : parentParam._funcName!
			);

		if( parentParam == null ){
			inherit = false;
		}
		_calculator = inherit ? parentParam!._calculator : false;
		_base       = inherit ? parentParam!._base       : 0;
		_mode       = inherit ? parentParam!._mode       : ClipGlobal.defMode;
		_fps        = inherit ? parentParam!._fps        : ClipGlobal.defFps;
		_prec       = inherit ? parentParam!._prec       : ClipGlobal.defPrec;
		_radix      = inherit ? parentParam!._radix      : ClipGlobal.defRadix;
		_mpPrec     = inherit ? parentParam!._mpPrec     : ClipGlobal.defMPPrec;
		_mpRound    = inherit ? parentParam!._mpRound    : ClipGlobal.defMPRound;

		if( parentParam != null ){
			_saveMode = parentParam._mode;
			_saveFps  = parentParam._fps;
		}
		updateMode();
		updateFps();

		_saveRadix = _radix;

		_var   = ClipVariable();
		_array = ClipArray();
		_func  = ClipFunc();

		// 外部関数関連
		_funcName    = null;
		_fileData    = null;
		_fileDataGet = 0;
		_fileLine    = null;
		_fileFlag    = false;
		_topNum      = 0;
		_lineNum     = 1;

		// 各種フラグ
		_enableCommand = true;
		_enableOpPow   = false;
		_enableStat    = true;
		_printAns      = true;
		_assFlag       = false;
		_subStep       = 0;

		_parent = null;

		// 親プロセスのパラメータ値を更新するかどうかのフラグ
		_updateParam      = List.filled( 10, false );
		_updateParamCode  = [];
		_updateParamIndex = [];

		// 親プロセスの変数・配列を更新するかどうかのフラグ
		_updateParentVar   = [];
		_updateParentArray = [];

		_defNameSpace = null;
		_nameSpace    = null;

		_seFlag  = false;
		_seToken = ClipGlobal.seNull;

		_mpFlag = false;

		_replace = [];
		if( parentParam != null ){
			for( int i = 0; i < parentParam._replace.length; i++ ){
				_replace.add( _ClipReplace(
					parentParam._replace[i]._descCode,
					parentParam._replace[i]._descToken,
					parentParam._replace[i]._realCode,
					parentParam._replace[i]._realToken
					) );
			}
		}
	}

	void end(){
		if( _saveMode != null ){
			ClipProc.globalParam().setMode( _saveMode! );
		}
		if( _saveFps != null ){
			ClipProc.globalParam().setFps( _saveFps! );
		}
	}

	int parentNum(){
		return _parentNum;
	}
	String parentFunc(){
		return _parentFunc;
	}

	ClipVariable variable(){ return _var; }
	ClipArray array(){ return _array; }
	ClipFunc func(){ return _func; }

	void setEnableCommand( bool flag ){
		_enableCommand = flag;
	}
//	setEnableOpPow( flag ){
//		_enableOpPow = flag;
//	}
	void setEnableStat( bool flag ){
		_enableStat = flag;
	}
	bool enableCommand(){
		return _enableCommand;
	}
	bool enableOpPow(){
		return _enableOpPow;
	}
	bool enableStat(){
		return _enableStat;
	}

	void setCalculator( bool flag ){
		_calculator = flag;
	}
	isCalculator(){
		return _calculator;
	}

	void setBase( int base ){
		_base = base;
	}
	int base(){
		return _base;
	}

	void updateMode(){
		ClipMath.setComplexIsReal( (_mode & ClipGlobal.modeComplex) == 0 );
		if( (_mode & ClipGlobal.modeFract) != 0 ){
			ClipMath.setValueType( ClipMath.valueTypeFract );
		} else if( (_mode & ClipGlobal.modeTime) != 0 ){
			ClipMath.setValueType( ClipMath.valueTypeTime );
		} else {
			ClipMath.setValueType( ClipMath.valueTypeComplex );
		}
	}
	void setMode( int mode ){
		if( _mode == ClipGlobal.modeIMultiPrec ){
			_radix = _saveRadix;
		}
		_mode = mode;
		if( _mode == ClipGlobal.modeIMultiPrec ){
			_saveRadix = _radix;
			_radix = 10;
		}
		updateMode();
	}
	int mode(){
		return _mode;
	}

	bool isMultiPrec(){
		return ((_mode & ClipGlobal.modeMultiPrec) != 0);
	}

	void updateFps(){
		ClipMath.setTimeFps( _fps );
	}
	void setFps( double fps ){
		if( fps < 0.0 ){
			_fps = ClipGlobal.defFps;
		} else {
			_fps = fps;
		}
		updateFps();
	}
//	fps(){
//		return _fps;
//	}

	void setPrec( int prec ){
		if( prec < ClipGlobal.minPrec ){
			_prec = ClipGlobal.defPrec;
		} else {
			_prec = prec;
		}
	}
	int prec(){
		return _prec;
	}

	void setRadix( int radix ){
		if( radix < ClipGlobal.minRadix ){
			_radix = ClipGlobal.defRadix;
		} else if( radix > ClipGlobal.maxRadix ){
			_radix = ClipGlobal.maxRadix;
		} else {
			_radix = radix;
		}
	}
	int radix(){
		return _radix;
	}

	void mpSetPrec( int prec ){
		if( prec < ClipGlobal.minMPPrec ){
			_mpPrec = ClipGlobal.defMPPrec;
		} else {
			_mpPrec = prec;
		}
	}
	int mpPrec(){
		return _mpPrec;
	}

	bool mpSetRoundStr( String mode ){
		if( mode == "up" ){
			_mpRound = MultiPrec.froundUp;
		} else if( mode == "down" ){
			_mpRound = MultiPrec.froundDown;
		} else if( mode == "ceiling" ){
			_mpRound = MultiPrec.froundCeiling;
		} else if( mode == "floor" ){
			_mpRound = MultiPrec.froundFloor;
		} else if( mode == "h_up" ){
			_mpRound = MultiPrec.froundHalfUp;
		} else if( mode == "h_down" ){
			_mpRound = MultiPrec.froundHalfDown;
		} else if( mode == "h_even" ){
			_mpRound = MultiPrec.froundHalfEven;
		} else if( mode == "h_down2" ){
			_mpRound = MultiPrec.froundHalfDown2;
		} else if( mode == "h_even2" ){
			_mpRound = MultiPrec.froundHalfEven2;
		} else {
			return false;
		}
		return true;
	}
	void mpSetRound( int mode ){
		_mpRound = mode;
	}
	int mpRound(){
		return _mpRound;
	}

	void setAnsFlag( int flag ){
		_printAns = (flag != 0);
	}
	bool ansFlag(){
		return _printAns;
	}
	void setAssFlag( bool flag ){
		_assFlag = flag;
	}
	bool assFlag(){
		return _assFlag;
	}
	void setSubStep( int step ){
		_subStep = step;
	}
	void incSubStep(){
		_subStep++;
	}
	void decSubStep(){
		_subStep--;
	}
	int subStep(){
		return _subStep;
	}

	bool setVal( int index, dynamic value, bool moveFlag ){
		if( index == 0 ){
			_array.matrix(index).mat(0).ass( value );
			return true;
		} else {
			return _var.set( index, value, moveFlag );
		}
	}
	bool setReal( int index, double value, bool moveFlag ){
		if( index == 0 ){
			_array.matrix(index).mat(0).setReal( value );
			return true;
		} else {
			return _var.setReal( index, value, moveFlag );
		}
	}
	bool setImag( int index, double value, bool moveFlag ){
		if( index == 0 ){
			_array.matrix(index).mat(0).setImag( value );
			return true;
		} else {
			return _var.setImag( index, value, moveFlag );
		}
	}
	bool fractSetMinus( int index, bool isMinus, bool moveFlag ){
		if( index == 0 ){
			_array.matrix(index).mat(0).fractSetMinus( isMinus );
			return true;
		} else {
			return _var.fractSetMinus( index, isMinus, moveFlag );
		}
	}
	bool setNum( int index, double value, bool moveFlag ){
		if( index == 0 ){
			_array.matrix(index).mat(0).setNum( value );
			return true;
		} else {
			return _var.setNum( index, value, moveFlag );
		}
	}
	bool setDenom( int index, double value, bool moveFlag ){
		if( index == 0 ){
			_array.matrix(index).mat(0).setDenom( value );
			return true;
		} else {
			return _var.setDenom( index, value, moveFlag );
		}
	}
	bool fractReduce( int index, bool moveFlag ){
		if( index == 0 ){
			_array.matrix(index).mat(0).fractReduce();
			return true;
		} else {
			return _var.fractReduce( index, moveFlag );
		}
	}

	// 値を確認する
	MathValue val( int index ){
		return (index == 0) ? _array.matrix(index).mat(0) : _var.val( index );
	}
	bool isZero( int index ){
		return ClipMath.isZero( val( index ).real() ) && ClipMath.isZero( val( index ).imag() );
	}

	// 置き換え
	bool repVal( int index, MathValue value, bool moveFlag ){
		if( index == 0 ){
			_array.matrix(index).setMat( 0, value );
			return true;
		} else {
			return _var.rep( index, value, moveFlag );
		}
	}

	// 外部関数情報を登録する
	void setFunc( String? funcName, int topNum ){
		if( _funcName != null ){
			_funcName = null;
		}
		if( funcName != null ){
			_funcName = funcName;

			int end = _funcName!.indexOf( ":" );
			if( end > 0 ){
				setDefNameSpace( _funcName!.substring( 0, end ) );
			}
		}
		_topNum = topNum;
	}
	void setFuncName( String? funcName ){
		_funcName = funcName;
	}
	void setFileData( List<String>? data ){
		_fileData = data;
	}
	void setFileDataGet( int get ){
		_fileDataGet = get;
	}
	void incFileDataGet(){
		_fileDataGet++;
	}
	void setFileLine( ClipLine? line ){
		_fileLine = line;
	}
	void setFileFlag( bool flag ){
		_fileFlag = flag;
	}
	void setLineNum( int num ){
		_lineNum = num;
	}
	void incLineNum(){
		_lineNum++;
	}

	// 外部関数情報を確認する
	String? funcName(){ return _funcName; }
	List<String>? fileDataArray(){ return _fileData; }
	String fileData( int index ){
		return _fileData![index];
	}
	int fileDataGet(){
		return _fileDataGet;
	}
	bool fileFlag(){ return _fileFlag; }
	int topNum(){ return _topNum; }
	int lineNum(){ return _lineNum; }

	void setParent( ClipParam parent ){
		_parent = parent;
	}
	ClipParam? parent(){
		return _parent;
	}

	// 定義定数をコピーする
	void dupDefine( ClipParam dst ){
		for( int i = 1; i < 256; i++ ){	// 0は計算結果用に予約されている...
			if( _var.isLocked( i ) ){
				dst._var.define( _var.label().label(i)!, _var.val( i ), true );
			}
		}
	}

	// 関数の引数用変数にラベルを設定する
	void setLabel( ClipToken label ){
		int i;
		int code;
		dynamic token;
		String strLabel = "";
		ClipTokenData? lock;

		i = 0;
		label.beginGetToken();
		while( label.getToken() ){
			code  = ClipToken.curCode();
			token = ClipToken.curToken();
			// &かどうかをチェックする
			if( (code == ClipGlobal.codeParamAns) || ((code == ClipGlobal.codeOperator) && (token >= ClipGlobal.opAnd)) ){
				if( !(label.getToken()) ){
					break;
				}
				code  = ClipToken.curCode();
				token = ClipToken.curToken();
				_updateParam[i] = true;
			} else {
				_updateParam[i] = false;
			}

			if( code == ClipGlobal.codeLabel ){
				strLabel = token;

				// ラベルを設定する
				lock = label.lock();
				if( label.getToken() ){
					code  = ClipToken.curCode();
					token = ClipToken.curToken();
					if( code == ClipGlobal.codeParamArray ){
						_array.label().setLabel( ClipMath.charCode0 + i, strLabel, true );
					} else {
						label.unlock( lock );
						_var.label().setLabel( ClipMath.charCode0 + i, strLabel, true );
					}
				} else {
					label.unlock( lock );
					_var.label().setLabel( ClipMath.charCode0 + i, strLabel, true );
				}

				i++;
			}
		}
	}

	void setUpdateParam( int i, bool flag ){
		_updateParam[i] = flag;
	}
	void initUpdateParam(){
		_updateParamCode  = [];
		_updateParamIndex = [];
	}
	void setUpdateParamIndex( int i, int index ){
		_updateParamIndex[i] = index;
	}
	bool updateParam( int index ){
		return _updateParam[index];
	}
	List<int> updateParamCodeArray(){
		return _updateParamCode;
	}
	List<int> updateParamIndexArray(){
		return _updateParamIndex;
	}
	int updateParamCode( int index ){
		return _updateParamCode[index];
	}
	int updateParamIndex( int index ){
		return _updateParamIndex[index];
	}

	List<int> updateParentVarArray(){
		return _updateParentVar;
	}
	List<int> updateParentArrayArray(){
		return _updateParentArray;
	}
	int updateParentVar( int index ){
		return _updateParentVar[index];
	}
	int updateParentArray( int index ){
		return _updateParentArray[index];
	}

	void setDefNameSpace( String? defNameSpace ){
		_defNameSpace = defNameSpace;
		_nameSpace = _defNameSpace;
	}
	String? defNameSpace(){
		return _defNameSpace;
	}
	void setNameSpace( String? nameSpace ){
		_nameSpace = nameSpace;
	}
	String? nameSpace(){
		return _nameSpace;
	}
	void resetNameSpace(){
		_nameSpace = _defNameSpace;
	}

	void setSeFlag( bool flag ){
		_seFlag = flag;
	}
	bool seFlag(){
		return _seFlag;
	}
	void setSeToken( int token ){
		_seToken = token;
	}
	int seToken(){
		return _seToken;
	}

	void setMpFlag( bool flag ){
		_mpFlag = flag;
	}
	bool mpFlag(){
		return _mpFlag;
	}

	void setReplace( int descCode, dynamic descToken, int realCode, dynamic realToken ){
		int i;
		_ClipReplace tmp;
		for( i = 0; i < _replace.length; i++ ){
			tmp = _replace[i];
			if( descCode == tmp._descCode && descToken == tmp._descToken ){
				tmp._realCode  = realCode;
				tmp._realToken = realToken;
				return;
			}
		}
		_replace.add( _ClipReplace( descCode, descToken, realCode, realToken ) );
	}
	void delReplace( descCode, descToken ){
		List<_ClipReplace> replace = [];
		_ClipReplace tmp;
		for( int i = 0; i < _replace.length; i++ ){
			tmp = _replace[i];
			if( descCode != tmp._descCode || descToken != tmp._descToken ){
				replace.add( tmp );
			}
		}
		_replace = replace;
	}
	void replace( ClipTokenData cur ){
		_ClipReplace tmp;
		for( int i = 0; i < _replace.length; i++ ){
			tmp = _replace[i];
			if( cur.code() == tmp._descCode && cur.token() == tmp._descToken ){
				cur.setCode( tmp._realCode );
				cur.setToken( tmp._realToken );
				break;
			}
		}
	}
}
