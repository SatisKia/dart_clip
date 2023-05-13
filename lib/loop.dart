/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import 'global.dart';
import 'line.dart';
import 'param/boolean.dart';
import 'param/void.dart';
import 'token.dart';

// 行データ
class _ClipLoop {
	late dynamic _line;
	late bool _subFlag;
	late _ClipLoop? _next; // 次の行データ
	_ClipLoop(){
		_line    = null;
		_subFlag = false;
		_next    = null;
	}
}

// ループ制御構造管理クラス
class ClipLoop {
	// 制御構造管理クラスの種類
	static const int typeBase = 0;
	static const int typeSe = 1;
	static const int typeDo = 2;
	static const int typeWhile = 3;
	static const int typeFor = 4;
	static const int typeFunc = 5;

	static const int endTypeWhile = 0;
	static const int endTypeFor = 1;
	static const int endTypeFunc = 2;
	static const int endTypeIf = 3;
	static const int endTypeSwitch = 4;

	late ClipLoop? _beforeLoop;
	late ClipLoop _curLoop;
	late int _loopType;

	// 行リスト
	late _ClipLoop? _top;
	late _ClipLoop? _end;
	late _ClipLoop? _cur;

	late bool _getFlag;

	late bool _breakFlag;
	late bool _contFlag;

	late List<int> _endType;
	late int _endCnt;

	ClipLoop(){
		_beforeLoop = null;
		_curLoop    = this;
		_loopType   = typeBase;

		_top = null;
		_end = null;
		_cur = null;

		_getFlag = false;

		_breakFlag = false;
		_contFlag = false;

		_endType = List.filled( 16, 0 );
		_endCnt  = 0;
	}

	// 行を確保する
	_ClipLoop _newLine(){
		_ClipLoop tmp = _ClipLoop();

		if( _top == null ){
			// 先頭に登録する
			_top = tmp;
		} else {
			// 最後尾に追加する
			_end!._next = tmp;
		}
		_end        = tmp;
		_end!._next = _top;

		tmp._line = null;

		return tmp;
	}

	// 行を削除する
	_ClipLoop? _del( _ClipLoop? cur, _ClipLoop? before ){
		if( cur == null ){
			return null;
		}

		_ClipLoop tmp = cur;
		if( before != null ){
			before._next = tmp._next;
			cur          = tmp._next;
		} else if( tmp == _end ){
			_top = null;
			cur  = null;
		} else {
			_top        = tmp._next;
			_end!._next = _top;
			cur         = tmp._next;
		}

		if( tmp._subFlag ){
			tmp._line = null;
		} else {
			tmp._line.setToken( null );
			if( tmp._line.comment() != null ){
				tmp._line.setComment( null );
			}
			tmp._line = null;
		}

		return cur;
	}

	int _loopStart( ClipLoop _this, ParamVoid line, ParamBoolean beforeFlag ){
		if( _this._curLoop._loopType != typeFunc ){
			_ClipLoop _obj = line.obj() as _ClipLoop;
			_obj._subFlag = true;
			_obj._line = ClipLoop();
			_obj._line._loopType   = typeSe;
			_obj._line._beforeLoop = _this._curLoop;
			_this._curLoop = _obj._line;

			line.set( _this._curLoop._newLine() );
		}
		return ClipGlobal.noErr;
	}
	int _loopDo( ClipLoop _this, ParamVoid line, ParamBoolean beforeFlag ){
		if( _this._curLoop._loopType != typeFunc ){
			_ClipLoop _obj = line.obj() as _ClipLoop;
			_obj._subFlag = true;
			_obj._line = ClipLoop();
			_obj._line._loopType   = typeDo;
			_obj._line._beforeLoop = _this._curLoop;
			_this._curLoop = _obj._line;

			line.set( _this._curLoop._newLine() );
		}
		return ClipGlobal.noErr;
	}
	int _loopWhile( ClipLoop _this, ParamVoid line, ParamBoolean beforeFlag ){
		if( _this._curLoop._loopType != typeFunc ){
			_ClipLoop _obj = line.obj() as _ClipLoop;
			_obj._subFlag = true;
			_obj._line = ClipLoop();
			_obj._line._loopType   = typeWhile;
			_obj._line._beforeLoop = _this._curLoop;
			_this._curLoop = _obj._line;

			_this._curLoop._endType[_this._curLoop._endCnt] = endTypeWhile;
			_this._curLoop._endCnt++;

			line.set( _this._curLoop._newLine() );
		} else {
			_this._curLoop._endType[_this._curLoop._endCnt] = endTypeWhile;
			_this._curLoop._endCnt++;
		}
		return ClipGlobal.noErr;
	}
	int _loopFor( ClipLoop _this, ParamVoid line, ParamBoolean beforeFlag ){
		if( _this._curLoop._loopType != typeFunc ){
			_ClipLoop _obj = line.obj() as _ClipLoop;
			_obj._subFlag = true;
			_obj._line = ClipLoop();
			_obj._line._loopType   = typeFor;
			_obj._line._beforeLoop = _this._curLoop;
			_this._curLoop = _obj._line;

			_this._curLoop._endType[_this._curLoop._endCnt] = endTypeFor;
			_this._curLoop._endCnt++;

			line.set( _this._curLoop._newLine() );
		} else {
			_this._curLoop._endType[_this._curLoop._endCnt] = endTypeFor;
			_this._curLoop._endCnt++;
		}
		return ClipGlobal.noErr;
	}
	int _loopFunc( ClipLoop _this, ParamVoid line, ParamBoolean beforeFlag ){
		if( _this._curLoop._loopType == typeFunc ){
			return ClipGlobal.procErrStatFuncNest;
		}

		_ClipLoop _obj = line.obj() as _ClipLoop;
		_obj._subFlag = true;
		_obj._line = ClipLoop();
		_obj._line._loopType   = typeFunc;
		_obj._line._beforeLoop = _this._curLoop;
		_this._curLoop = _obj._line;

		_this._curLoop._endType[_this._curLoop._endCnt] = endTypeFunc;
		_this._curLoop._endCnt++;

		line.set( _this._curLoop._newLine() );

		return ClipGlobal.noErr;
	}
	int _loopEnd( ClipLoop _this, ParamVoid line, ParamBoolean beforeFlag ){
		if( _this._curLoop._loopType == typeSe ){
			beforeFlag.set( true );
		}
		return ClipGlobal.noErr;
	}
	int _loopCont( ClipLoop _this, ParamVoid line, ParamBoolean beforeFlag ){
		if( _this._curLoop._loopType == typeSe ){
			beforeFlag.set( true );
		}
		return ClipGlobal.noErr;
	}
	int _loopUntil( ClipLoop _this, ParamVoid line, ParamBoolean beforeFlag ){
		if( _this._curLoop._loopType == typeDo ){
			beforeFlag.set( true );
		}
		return ClipGlobal.noErr;
	}
	int _loopEndWhile( ClipLoop _this, ParamVoid line, ParamBoolean beforeFlag ){
		if( _this._curLoop._endCnt > 0 ){
			_this._curLoop._endCnt--;
		}

		if( _this._curLoop._loopType == typeWhile ){
			beforeFlag.set( true );
		}
		return ClipGlobal.noErr;
	}
	int _loopNext( ClipLoop _this, ParamVoid line, ParamBoolean beforeFlag ){
		if( _this._curLoop._endCnt > 0 ){
			_this._curLoop._endCnt--;
		}

		ClipToken tmp;
		int ret;

		if( _this._curLoop._loopType == typeFor ){
			// for(<初期設定文>)を<初期設定文>に加工する
			tmp = _this._curLoop._top!._line.token();
			tmp.del(  0 );	// "for"
			tmp.del(  0 );	// "("
			tmp.del( -1 );	// ")"

			// <条件部>をfor(<条件部>)に加工する
			if( _this._curLoop._top!._next == _this._curLoop._end ){
				return ClipGlobal.procErrStatForCon;
			} else if( _this._curLoop._top!._next!._subFlag ){
				return ClipGlobal.procErrStatForCon;
			}
			tmp = _this._curLoop._top!._next!._line.token();
			if( tmp.count() > 0 ){
				tmp.insCode( 0, ClipGlobal.codeStatement, ClipGlobal.statFor );	// "for"
				tmp.insCode( 1, ClipGlobal.codeTop,       null               );	// "("
				tmp.addCode(    ClipGlobal.codeEnd,       null               );	// ")"
			} else {
				tmp.insCode( 0, ClipGlobal.codeStatement, ClipGlobal.statFor2 );
			}

			// <更新式>行を最後尾に移す
			if( _this._curLoop._top!._next!._next == _this._curLoop._end ){
				return ClipGlobal.procErrStatForExp;
			} else if( _this._curLoop._top!._next!._next!._subFlag ){
				return ClipGlobal.procErrStatForExp;
			}
			if( (ret = _this._curLoop.regLine( _this._curLoop._top!._next!._next!._line! )) != ClipGlobal.loopCont ){
				return ret;
			}
			_this._curLoop._top!._next!._next = _this._curLoop._del( _this._curLoop._top!._next!._next, _this._curLoop._top!._next );

			beforeFlag.set( true );
		}
		return ClipGlobal.noErr;
	}
	int _loopEndFunc( ClipLoop _this, ParamVoid line, ParamBoolean beforeFlag ){
		if( _this._curLoop._endCnt > 0 ){
			_this._curLoop._endCnt--;
		}

		if( _this._curLoop._loopType == typeFunc ){
			beforeFlag.set( true );
		}
		return ClipGlobal.noErr;
	}
	int _loopMultiEnd( ClipLoop _this, ParamVoid line, ParamBoolean beforeFlag ){
		if( _this._curLoop._endCnt > 0 ){
			switch( _this._curLoop._endType[_this._curLoop._endCnt - 1] ){
			case endTypeWhile:
				return _this._loopEndWhile( _this, line, beforeFlag );
			case endTypeFor:
				return _this._loopNext( _this, line, beforeFlag );
			case endTypeFunc:
				return _this._loopEndFunc( _this, line, beforeFlag );
			}
			_this._curLoop._endCnt--;
		}
		return ClipGlobal.noErr;
	}

	int regLine( ClipLineData line ){
		int code;
		dynamic token;
		int ret;

		ParamVoid tmp = ParamVoid( _curLoop._newLine() );
		ParamBoolean beforeFlag = ParamBoolean( false );

		line.token()!.beginGetToken();
		if( line.token()!.getToken() ){
			code  = ClipToken.curCode();
			token = ClipToken.curToken();

			if( code == ClipGlobal.codeStatement ){
				switch( token ){
				case ClipGlobal.statIf:
					_curLoop._endType[_curLoop._endCnt] = endTypeIf;
					_curLoop._endCnt++;
					break;
				case ClipGlobal.statEndIf:
					if( _curLoop._endCnt > 0 ){
						_curLoop._endCnt--;
					}
					break;
				case ClipGlobal.statSwitch:
					_curLoop._endType[_curLoop._endCnt] = endTypeSwitch;
					_curLoop._endCnt++;
					break;
				case ClipGlobal.statEndSwi:
					if( _curLoop._endCnt > 0 ){
						_curLoop._endCnt--;
					}
					break;
				}
			}

			if( (code == ClipGlobal.codeStatement) && (token < ClipGlobal.statLoopEnd) ){
				if( (ret = _loopSub[token]( this, tmp, beforeFlag )) != ClipGlobal.noErr ){
					return ret;
				}
			}
		}

		_ClipLoop _obj = tmp.obj() as _ClipLoop;
		_obj._line = ClipLineData();
		_obj._line.setToken( ClipToken() );
		line.token()!.dup( _obj._line.token() );
		_obj._line.setNum( line.num() );
		if( line.comment() != null ){
			_obj._line.setComment( line.comment() );
		}
		_obj._line.setNext( line.next() );
		_obj._subFlag = false;

		if( beforeFlag.val() ){
			_curLoop._getFlag = false;
			_curLoop = _curLoop._beforeLoop!;
			if( _curLoop._loopType == typeBase ){
				return ClipGlobal.procEnd;
			}
		}

		return ClipGlobal.loopCont;
	}

	bool _getNextLine(){
		if( _curLoop._loopType == typeSe ){
			_curLoop._cur = _curLoop._cur!._next;
			return true;
		} else if( _curLoop._loopType == typeDo ){
			_curLoop._cur = _curLoop._cur!._next;
			return true;
		} else if( _curLoop._loopType == typeWhile ){
			_curLoop._cur = _curLoop._cur!._next;
			return true;
		} else if( _curLoop._loopType == typeFor ){
			_curLoop._cur = (_curLoop._cur == _curLoop._end) ?
				_curLoop._top!._next/*初期設定行を飛ばして次の行に行く*/ :
				_curLoop._cur!._next;
			return true;
		} else if( _curLoop._loopType == typeFunc ){
			if( _curLoop._cur == _curLoop._end ){
				return false;
			} else {
				_curLoop._cur = _curLoop._cur!._next;
				return true;
			}
		}
		_curLoop._cur = (_curLoop._cur == _curLoop._end) ?
			null :
			_curLoop._cur!._next;
		return true;
	}
	ClipLineData? getLine(){
		if( !(_curLoop._getFlag) ){
			_curLoop._getFlag = true;
			_curLoop._cur = _curLoop._top;
		}

		if( _curLoop._cur == null ){
			return null;
		} else if( _curLoop._cur!._subFlag ){
			var nextLoop = _curLoop._cur!._line;
			nextLoop._breakFlag = _curLoop._breakFlag;
			_curLoop = nextLoop;
			return _curLoop.getLine();
		}
		ClipLineData line = _curLoop._cur!._line;
		if( _curLoop._getNextLine() ){
			return line;
		}
		return null;
	}

	void doEnd(){
		if( _curLoop._contFlag ){
			_curLoop._breakFlag = false;
			_curLoop._contFlag = false;
		} else if( _curLoop._breakFlag ){
			_curLoop._breakFlag = false;

			_curLoop._getFlag = false;
			_curLoop = _curLoop._beforeLoop!;

			_curLoop._getNextLine();
		}
	}
	void doBreak(){
		if( !(_curLoop._contFlag) ){
			_curLoop._breakFlag = true;
		}
	}
	void doContinue(){
		if( !(_curLoop._breakFlag) ){
			_curLoop._breakFlag = true;
			_curLoop._contFlag = true;
		}
	}

	bool checkBreak(){
		return _curLoop._breakFlag;
	}
	bool checkContinue(){
		return _curLoop._contFlag;
	}

	late final List<int Function( ClipLoop, ParamVoid, ParamBoolean )> _loopSub = [
		_loopStart,
		_loopEnd,
		_loopEnd,
		_loopEnd,
		_loopEnd,
		_loopEnd,
		_loopEnd,
		_loopCont,

		_loopDo,
		_loopUntil,

		_loopWhile,
		_loopEndWhile,

		_loopFor,
		_loopFor,
		_loopNext,

		_loopFunc,
		_loopEndFunc,

		_loopMultiEnd
	];
}
