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

// 制御構造管理クラスの種類
const int CLIP_LOOP_TYPE_BASE = 0;
const int CLIP_LOOP_TYPE_SE = 1;
const int CLIP_LOOP_TYPE_DO = 2;
const int CLIP_LOOP_TYPE_WHILE = 3;
const int CLIP_LOOP_TYPE_FOR = 4;
const int CLIP_LOOP_TYPE_FUNC = 5;

const int CLIP_LOOP_END_TYPE_WHILE = 0;
const int CLIP_LOOP_END_TYPE_FOR = 1;
const int CLIP_LOOP_END_TYPE_FUNC = 2;
const int CLIP_LOOP_END_TYPE_IF = 3;
const int CLIP_LOOP_END_TYPE_SWITCH = 4;

// ループ制御構造管理クラス
class ClipLoop {
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
		_loopType   = CLIP_LOOP_TYPE_BASE;

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
			tmp._line._token = null;
			if( tmp._line._comment != null ){
				tmp._line._comment = null;
			}
			tmp._line = null;
		}

		return cur;
	}

	int _loopStart( ClipLoop _this, ParamVoid line, ParamBoolean beforeFlag ){
		if( _this._curLoop._loopType != CLIP_LOOP_TYPE_FUNC ){
			_ClipLoop _obj = line.obj() as _ClipLoop;
			_obj._subFlag = true;
			_obj._line = ClipLoop();
			_obj._line._loopType   = CLIP_LOOP_TYPE_SE;
			_obj._line._beforeLoop = _this._curLoop;
			_this._curLoop = _obj._line;

			line.set( _this._curLoop._newLine() );
		}
		return CLIP_NO_ERR;
	}
	int _loopDo( ClipLoop _this, ParamVoid line, ParamBoolean beforeFlag ){
		if( _this._curLoop._loopType != CLIP_LOOP_TYPE_FUNC ){
			_ClipLoop _obj = line.obj() as _ClipLoop;
			_obj._subFlag = true;
			_obj._line = ClipLoop();
			_obj._line._loopType   = CLIP_LOOP_TYPE_DO;
			_obj._line._beforeLoop = _this._curLoop;
			_this._curLoop = _obj._line;

			line.set( _this._curLoop._newLine() );
		}
		return CLIP_NO_ERR;
	}
	int _loopWhile( ClipLoop _this, ParamVoid line, ParamBoolean beforeFlag ){
		if( _this._curLoop._loopType != CLIP_LOOP_TYPE_FUNC ){
			_ClipLoop _obj = line.obj() as _ClipLoop;
			_obj._subFlag = true;
			_obj._line = ClipLoop();
			_obj._line._loopType   = CLIP_LOOP_TYPE_WHILE;
			_obj._line._beforeLoop = _this._curLoop;
			_this._curLoop = _obj._line;

			_this._curLoop._endType[_this._curLoop._endCnt] = CLIP_LOOP_END_TYPE_WHILE;
			_this._curLoop._endCnt++;

			line.set( _this._curLoop._newLine() );
		} else {
			_this._curLoop._endType[_this._curLoop._endCnt] = CLIP_LOOP_END_TYPE_WHILE;
			_this._curLoop._endCnt++;
		}
		return CLIP_NO_ERR;
	}
	int _loopFor( ClipLoop _this, ParamVoid line, ParamBoolean beforeFlag ){
		if( _this._curLoop._loopType != CLIP_LOOP_TYPE_FUNC ){
			_ClipLoop _obj = line.obj() as _ClipLoop;
			_obj._subFlag = true;
			_obj._line = ClipLoop();
			_obj._line._loopType   = CLIP_LOOP_TYPE_FOR;
			_obj._line._beforeLoop = _this._curLoop;
			_this._curLoop = _obj._line;

			_this._curLoop._endType[_this._curLoop._endCnt] = CLIP_LOOP_END_TYPE_FOR;
			_this._curLoop._endCnt++;

			line.set( _this._curLoop._newLine() );
		} else {
			_this._curLoop._endType[_this._curLoop._endCnt] = CLIP_LOOP_END_TYPE_FOR;
			_this._curLoop._endCnt++;
		}
		return CLIP_NO_ERR;
	}
	int _loopFunc( ClipLoop _this, ParamVoid line, ParamBoolean beforeFlag ){
		if( _this._curLoop._loopType == CLIP_LOOP_TYPE_FUNC ){
			return CLIP_PROC_ERR_STAT_FUNC_NEST;
		}

		_ClipLoop _obj = line.obj() as _ClipLoop;
		_obj._subFlag = true;
		_obj._line = ClipLoop();
		_obj._line._loopType   = CLIP_LOOP_TYPE_FUNC;
		_obj._line._beforeLoop = _this._curLoop;
		_this._curLoop = _obj._line;

		_this._curLoop._endType[_this._curLoop._endCnt] = CLIP_LOOP_END_TYPE_FUNC;
		_this._curLoop._endCnt++;

		line.set( _this._curLoop._newLine() );

		return CLIP_NO_ERR;
	}
	int _loopEnd( ClipLoop _this, ParamVoid line, ParamBoolean beforeFlag ){
		if( _this._curLoop._loopType == CLIP_LOOP_TYPE_SE ){
			beforeFlag.set( true );
		}
		return CLIP_NO_ERR;
	}
	int _loopCont( ClipLoop _this, ParamVoid line, ParamBoolean beforeFlag ){
		if( _this._curLoop._loopType == CLIP_LOOP_TYPE_SE ){
			beforeFlag.set( true );
		}
		return CLIP_NO_ERR;
	}
	int _loopUntil( ClipLoop _this, ParamVoid line, ParamBoolean beforeFlag ){
		if( _this._curLoop._loopType == CLIP_LOOP_TYPE_DO ){
			beforeFlag.set( true );
		}
		return CLIP_NO_ERR;
	}
	int _loopEndWhile( ClipLoop _this, ParamVoid line, ParamBoolean beforeFlag ){
		if( _this._curLoop._endCnt > 0 ){
			_this._curLoop._endCnt--;
		}

		if( _this._curLoop._loopType == CLIP_LOOP_TYPE_WHILE ){
			beforeFlag.set( true );
		}
		return CLIP_NO_ERR;
	}
	int _loopNext( ClipLoop _this, ParamVoid line, ParamBoolean beforeFlag ){
		ClipToken tmp;
		int ret;

		if( _this._curLoop._loopType == CLIP_LOOP_TYPE_FOR ){
			// for(<初期設定文>)を<初期設定文>に加工する
			tmp = _this._curLoop._top!._line._token;
			tmp.del(  0 );	// "for"
			tmp.del(  0 );	// "("
			tmp.del( -1 );	// ")"

			// <条件部>をfor(<条件部>)に加工する
			if( _this._curLoop._top!._next == _this._curLoop._end ){
				return CLIP_PROC_ERR_STAT_FOR_CON;
			} else if( _this._curLoop._top!._next!._subFlag ){
				return CLIP_PROC_ERR_STAT_FOR_CON;
			}
			tmp = _this._curLoop._top!._next!._line._token;
			if( tmp.count() > 0 ){
				tmp.insCode( 0, CLIP_CODE_STATEMENT, CLIP_STAT_FOR );	// "for"
				tmp.insCode( 1, CLIP_CODE_TOP,       null          );	// "("
				tmp.addCode(    CLIP_CODE_END,       null          );	// ")"
			} else {
				tmp.insCode( 0, CLIP_CODE_STATEMENT, CLIP_STAT_FOR2 );
			}

			// <更新式>行を最後尾に移す
			if( _this._curLoop._top!._next!._next == _this._curLoop._end ){
				return CLIP_PROC_ERR_STAT_FOR_EXP;
			} else if( _this._curLoop._top!._next!._next!._subFlag ){
				return CLIP_PROC_ERR_STAT_FOR_EXP;
			}
			if( (ret = _this._curLoop.regLine( _this._curLoop._top!._next!._next!._line! )) != CLIP_LOOP_CONT ){
				return ret;
			}
			_this._curLoop._top!._next!._next = _this._curLoop._del( _this._curLoop._top!._next!._next, _this._curLoop._top!._next );

			beforeFlag.set( true );
		}
		return CLIP_NO_ERR;
	}
	int _loopEndFunc( ClipLoop _this, ParamVoid line, ParamBoolean beforeFlag ){
		if( _this._curLoop._endCnt > 0 ){
			_this._curLoop._endCnt--;
		}

		if( _this._curLoop._loopType == CLIP_LOOP_TYPE_FUNC ){
			beforeFlag.set( true );
		}
		return CLIP_NO_ERR;
	}
	int _loopMultiEnd( ClipLoop _this, ParamVoid line, ParamBoolean beforeFlag ){
		if( _this._curLoop._endCnt > 0 ){
			switch( _this._curLoop._endType[_this._curLoop._endCnt - 1] ){
			case CLIP_LOOP_END_TYPE_WHILE:
				return _this._loopEndWhile( _this, line, beforeFlag );
			case CLIP_LOOP_END_TYPE_FOR:
				return _this._loopNext( _this, line, beforeFlag );
			case CLIP_LOOP_END_TYPE_FUNC:
				return _this._loopEndFunc( _this, line, beforeFlag );
			}
			_this._curLoop._endCnt--;
		}
		return CLIP_NO_ERR;
	}

	int regLine( ClipLineData line ){
		int code;
		dynamic token;
		int ret;

		ParamVoid tmp = ParamVoid( _curLoop._newLine() );
		ParamBoolean beforeFlag = ParamBoolean( false );

		line.token().beginGetToken();
		if( line.token().getToken() ){
			code  = getCode();
			token = getToken();

			if( code == CLIP_CODE_STATEMENT ){
				switch( token ){
				case CLIP_STAT_IF:
					_curLoop._endType[_curLoop._endCnt] = CLIP_LOOP_END_TYPE_IF;
					_curLoop._endCnt++;
					break;
				case CLIP_STAT_ENDIF:
					if( _curLoop._endCnt > 0 ){
						_curLoop._endCnt--;
					}
					break;
				case CLIP_STAT_SWITCH:
					_curLoop._endType[_curLoop._endCnt] = CLIP_LOOP_END_TYPE_SWITCH;
					_curLoop._endCnt++;
					break;
				case CLIP_STAT_ENDSWI:
					if( _curLoop._endCnt > 0 ){
						_curLoop._endCnt--;
					}
					break;
				}
			}

			if( (code == CLIP_CODE_STATEMENT) && (token < CLIP_STAT_LOOP_END) ){
				if( (ret = _loopSub[token]( this, tmp, beforeFlag )) != CLIP_NO_ERR ){
					return ret;
				}
			}
		}

		_ClipLoop _obj = tmp.obj() as _ClipLoop;
		_obj._line = ClipLineData();
		_obj._line._token = ClipToken();
		line.token().dup( _obj._line._token );
		_obj._line._num = line.num();
		if( line.comment() != null ){
			_obj._line._comment = "";
			_obj._line._comment = line.comment();
		}
		_obj._line._next = line.next();
		_obj._subFlag = false;

		if( beforeFlag.val() ){
			_curLoop._getFlag = false;
			_curLoop = _curLoop._beforeLoop!;
			if( _curLoop._loopType == CLIP_LOOP_TYPE_BASE ){
				return CLIP_PROC_END;
			}
		}

		return CLIP_LOOP_CONT;
	}

	bool _getNextLine(){
		if( _curLoop._loopType == CLIP_LOOP_TYPE_SE ){
			_curLoop._cur = _curLoop._cur!._next;
			return true;
		} else if( _curLoop._loopType == CLIP_LOOP_TYPE_DO ){
			_curLoop._cur = _curLoop._cur!._next;
			return true;
		} else if( _curLoop._loopType == CLIP_LOOP_TYPE_WHILE ){
			_curLoop._cur = _curLoop._cur!._next;
			return true;
		} else if( _curLoop._loopType == CLIP_LOOP_TYPE_FOR ){
			_curLoop._cur = (_curLoop._cur == _curLoop._end) ?
				_curLoop._top!._next/*初期設定行を飛ばして次の行に行く*/ :
				_curLoop._cur!._next;
			return true;
		} else if( _curLoop._loopType == CLIP_LOOP_TYPE_FUNC ){
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
