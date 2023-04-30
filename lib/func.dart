/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import 'line.dart';
import 'token.dart';

// ユーザー定義関数情報
class ClipFuncInfo {
	late String _name; // 関数名
	late int _cnt;
	ClipFuncInfo(){
		_name = "";
		_cnt  = 0;
	}
	String name(){
		return _name;
	}
}

// ユーザー定義関数データ
class ClipFuncData {
	late bool _createFlag;
	late ClipFuncInfo? _info; //
	late ClipToken? _label; // 引数のラベル
	late ClipLine? _line; //
	late int _topNum;
	late ClipFuncData? _before; // 前のユーザー定義関数データ
	late ClipFuncData? _next; // 次のユーザー定義関数データ
	ClipFuncData( bool createFlag ){
		_createFlag = createFlag;
		_info       = null; //
		_label      = null; // 引数のラベル
		_line       = null; //
		_topNum     = 1;
		_before     = null; // 前のユーザー定義関数データ
		_next       = null; // 次のユーザー定義関数データ
	}
	ClipFuncInfo info(){
		return _info!;
	}
	ClipToken label(){
		return _label!;
	}
	ClipLine line(){
		return _line!;
	}
	int topNum(){
		return _topNum;
	}
}

// ユーザー定義関数管理クラス
class ClipFunc {
	// ユーザー定義関数リスト
	late ClipFuncData? _top;
	late ClipFuncData? _end;

	late int _num; // ユーザー定義関数の個数
	late int _max; // ユーザー定義関数の登録可能数

	ClipFunc(){
		_top = null;
		_end = null;

		_num = 0;
		_max = -1;
	}

	void setMaxNum( int max ){
		if( max >= 0 ){
			for( int i = _num - max; i > 0; i-- ){
				// 優先度の最も低いユーザー定義関数を削除する
				_del();
			}
		}

		_max = max;
	}
	int maxNum(){
		return _max;
	}

	bool getInfo( int num, ClipFuncInfo info ){
		int tmp = 0;
		ClipFuncData? cur = _top;
		while( true ){
			if( cur == null ){
				return false;
			}
			if( tmp == num ){
				break;
			}
			tmp++;
			cur = cur._next;
		}
		info._name = cur._info!._name;
		info._cnt  = cur._info!._cnt;
		return true;
	}

	bool canDel(){
		return (_top != null);
	}

	ClipFuncData _add( bool createFlag ){
		ClipFuncData tmp = ClipFuncData( createFlag );

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
	ClipFuncData _ins( bool createFlag ){
		ClipFuncData tmp = ClipFuncData( createFlag );

		if( _top == null ){
			// 先頭に登録する
			_top = tmp;
			_end = tmp;
		} else {
			// 先頭に追加する
			tmp._next     = _top;
			_top!._before = tmp;
			_top          = tmp;
		}

		return tmp;
	}

	ClipFuncData? create( String name, [int topNum = 1] ){
		if( _max == 0 ){
			return null;
		}

		if( _num == _max ){
			// 優先度の最も低いユーザー定義関数を削除する
			_del();
		}

		ClipFuncData tmp = _ins( true );

		tmp._info        = ClipFuncInfo();
		tmp._info!._name = name;
		tmp._info!._cnt  = 0;
		tmp._label       = ClipToken();
		tmp._line        = ClipLine();
		tmp._topNum      = topNum;

		_num++;

		return tmp;
	}

	ClipFuncData? open( ClipFuncData srcFunc ){
		if( _max == 0 ){
			return null;
		}

		if( _num == _max ){
			// 優先度の最も低いユーザー定義関数を削除する
			_del();
		}

		ClipFuncData tmp = _ins( false );

		tmp._info   = srcFunc._info;
		tmp._label  = srcFunc._label;
		tmp._line   = srcFunc._line;
		tmp._topNum = srcFunc._topNum;

		_num++;

		return tmp;
	}
	void openAll( ClipFunc src ){
		ClipFuncData? srcFunc;
		ClipFuncData dstFunc;

		// 全ユーザー定義関数を削除する
		delAll();

		srcFunc = src._top;
		while( srcFunc != null ){
			dstFunc = _add( false );

			dstFunc._info   = srcFunc._info;
			dstFunc._label  = srcFunc._label;
			dstFunc._line   = srcFunc._line;
			dstFunc._topNum = srcFunc._topNum;

			srcFunc = srcFunc._next;
		}

		_num = src._num;
		_max = src._max;
	}

	// ユーザー定義関数を削除する
	void del( ClipFuncData func ){
		// リストから切り離す
		if( func._before != null ){
			func._before!._next = func._next;
		} else {
			_top = func._next;
		}
		if( func._next != null ){
			func._next!._before = func._before;
		} else {
			_end = func._before;
		}

		_num--;
	}

	// 優先度の最も低いユーザー定義関数を削除する
	void _del(){
		if( _top == null ){
			return;
		}

		// 優先度の最も低いユーザー定義関数を検索する
		ClipFuncData tmp = _top!;
		ClipFuncData? cur = _top!._next;
		while( cur != null ){
			if( cur._info!._cnt <= tmp._info!._cnt ){
				tmp = cur;
			}
			cur = cur._next;
		}

		del( tmp );
	}

	// 全ユーザー定義関数を削除する
	void delAll(){
		_top = null;
		_num = 0;
	}

	// 関数を検索する
	ClipFuncData? search( String name, bool updateCnt, [String? nameSpace] ){
		int tmp = name.indexOf( ":" );
		if( tmp == 0 ){
			name = name.substring( 1 );
		} else if( (nameSpace != null) && (tmp < 0) ){
			name = "$nameSpace:$name";
		}
		ClipFuncData? cur = _top;
		while( cur != null ){
			if( name.toLowerCase() == cur._info!._name.toLowerCase() ){
				if( updateCnt ){
					cur._info!._cnt++;
				}
				return cur;
			}
			cur = cur._next;
		}
		return null;
	}
}
