/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import 'global.dart';
import 'math/math.dart';
import 'param.dart';
import 'token.dart';

// 行データ
class ClipLineData {
	late ClipToken? _token; // トークン・リスト
	late int _num; // 行番号
	late String? _comment; // コメント
	late ClipLineData? _next; // 次の行データ
	ClipLineData(){
		_token   = null;
		_num     = 0;
		_comment = null;
		_next    = null;
	}
	void setToken( ClipToken? token ){
		_token = token;
	}
	ClipToken? token(){
		return _token;
	}
	void setNum( int num ){
		_num = num;
	}
	int num(){
		return _num;
	}
	void setComment( String? comment ){
		_comment = comment;
	}
	String? comment(){
		return _comment;
	}
	void setNext( ClipLineData? next ){
		_next = next;
	}
	ClipLineData? next(){
		return _next;
	}
}

// 行管理クラス
class ClipLine {
	// 行リスト
	late ClipLineData? _top;
	late ClipLineData? _end;
	late ClipLineData? _get;

	late int _nextNum;

	ClipLine( [int num = 1] ){
		_top = null;
		_end = null;
		_get = null;

		_nextNum = (num > 0) ? num : 1;
	}

	int nextNum(){
		return _nextNum;
	}

	// 行を確保する
	ClipLineData _newLine(){
		ClipLineData tmp = ClipLineData();

		if( _top == null ){
			// 先頭に登録する
			_top = tmp;
			_end = tmp;
		} else {
			// 最後尾に追加する
			_end!._next = tmp;
			_end        = tmp;
		}

		tmp._num = _nextNum;

		return tmp;
	}

	ClipLine dup(){
		ClipLine dst = ClipLine();

		_get = _top;
		while( _get != null ){
			dst.regLine( _get! );
			_get = _get!._next;
		}

		dst._nextNum = _nextNum;

		return dst;
	}

	// 行を登録する
	bool _checkEscape( String line, int top, int cur ){
		cur--;
		if( cur < top ){
			return false;
		}

		bool check = false;
		while( ClipGlobal.isCharEscape( line, top + cur ) ){
			check = check ? false : true;
			cur--;
			if( cur < top ){
				break;
			}
		}
		return check;
	}
	int regString( ClipParam param, String line, bool strToVal ){
		int i;
		int ret;
		int len;
		String curLine = "";

		ClipLineData tmp = _newLine();
		tmp._token = ClipToken();

		int top = 0;
		int cur = 0;

		while( top + cur < line.length ){
			if( ClipMath.charAt( line, top + cur ) == ';' ){
				if( !_checkEscape( line, top, cur ) ){
					curLine = line.substring( top, top + cur );

					if( (ret = tmp._token!.regString( param, curLine, strToVal )) != ClipGlobal.noErr ){
						return ret;
					}

					tmp        = _newLine();
					tmp._token = ClipToken();

					top = top + cur + 1;
					cur = 0;

					continue;
				}
			} else if( ClipMath.charAt( line, top + cur ) == '#' ){
				if( !_checkEscape( line, top, cur ) ){
					// コメントを登録する
					len = line.length - (top + cur + 1);
					tmp._comment = "";
					for( i = 0; i < len; i++ ){
						int tmp2 = top + cur + 1 + i;
						if( ClipGlobal.isCharEnter( line, tmp2 ) ){
							break;
						}
						tmp._comment = tmp._comment! + ClipMath.charAt( line, tmp2 );
					}

					line = line.substring( top, top + cur );
					curLine = line;
					continue;
				}
			}
			cur++;
			curLine = line.substring( top, top + cur );
		}

		_nextNum++;

		return tmp._token!.regString( param, curLine, strToVal );
	}
	int regLine( ClipLineData line ){
		int ret;

		ClipLineData tmp = _newLine();

		tmp._token = ClipToken();
		if( (ret = line._token!.dup( tmp._token! )) != ClipGlobal.noErr ){
			return ret;
		}

		if( line._num > 0 ){
			tmp._num = line._num;
			_nextNum = tmp._num + 1;
		} else {
			_nextNum++;
		}

		if( line._comment != null ){
			tmp._comment = line._comment;
		}

		return ClipGlobal.noErr;
	}

	// 行を確認する
	void beginGetLine(){
		_get = _top;
	}
	ClipLineData? getLine(){
		if( _get == null ){
			return null;
		}
		ClipLineData line = _get!;
		_get = _get!._next;
		return line;
	}
}
