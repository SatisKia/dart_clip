/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import 'global.dart';
import 'gworld.dart';
import 'math/complex.dart';
import 'math/math.dart';
import 'param.dart';
import 'param/float.dart';
import 'param/integer.dart';
import 'proc.dart';

// 計算結果保持バッファ
class ClipGraphAns {
	late double _x;
	late double _y1;
	late double _y2;
	ClipGraphAns(){
		_x  = 0.0;
		_y1 = 0.0;
		_y2 = 0.0;
	}
	void set( ClipGraphAns src ){
		_x  = src._x;
		_y1 = src._y1;
		_y2 = src._y2;
	}

	static List<ClipGraphAns> newArray( int len ){
		List<ClipGraphAns> a = List.filled( len, ClipGraphAns() );
		for( int i = 0; i < len; i++ ){
			a[i] = ClipGraphAns();
		}
		return a;
	}
}

// グラフ情報
class _ClipGraphInfo {
	late bool _draw; // 描画するかどうかのフラグ

	late int _color; // グラフの色

	late int _mode; // グラフの種類

	late String _expr1; // 計算式
	late String _expr2; // 計算式
	late int _index; // X座標に対応する変数のインデックス

	late double _start;
	late double _end;
	late double _step;

	late List<ClipGraphAns> _ans; // 計算結果保持バッファ
	late ParamInteger _ansNum; // 計算結果保持バッファのサイズ

	late double _baseX; // 底
	late double _baseY; // 底
	late double _logBaseX; // 1.0/log(底)をあらかじめ計算した値
	late double _logBaseY; // 1.0/log(底)をあらかじめ計算した値

	// 各種フラグ
	late bool _isLogScaleX; // 対数座標系かどうかのフラグ
	late bool _isLogScaleY; // 対数座標系かどうかのフラグ

	_ClipGraphInfo(){
		_draw = true;

		_color = 0;

		_mode = ClipGlobal.graphModeRect;

		_expr1 = "";
		_expr2 = "";
		_index = 0;

		_start = 0.0;
		_end   = 0.0;
		_step  = 0.0;

		_ans = [];
		_ansNum = ParamInteger();

		_baseX    = 0.0;
		_baseY    = 0.0;
		_logBaseX = 0.0;
		_logBaseY = 0.0;

		// 各種フラグ
		_isLogScaleX = false;
		_isLogScaleY = false;
	}
}

// グラフ描画クラス
class ClipGraph {
	late ClipGWorld _gWorld;

	late List<_ClipGraphInfo> _info;
	late int _infoNum;
	late int _curIndex;

	ClipGraph(){
		_gWorld = ClipGWorld();

		_info = [];
		_infoNum = 0;
		_curIndex = 0;

		// グラフ情報1個は常に存在させる
		addGraph();
	}

	ClipGWorld gWorld(){
		return _gWorld;
	}

//	graphIndex(){
//		return _curIndex;
//	}

	bool addGraph(){
		_curIndex = _infoNum;
		_infoNum++;

		if( _info.length <= _curIndex ){
			_info.add( _ClipGraphInfo() );
		} else {
			_info[_curIndex] = _ClipGraphInfo();
		}

		_info[_curIndex]._draw = true;

		_info[_curIndex]._mode = ClipGlobal.graphModeRect;

		_info[_curIndex]._expr1 = "";
		_info[_curIndex]._expr2 = "";

		_info[_curIndex]._ans = [];
		_info[_curIndex]._ansNum.set( 0 );

		setLogScaleX( 10.0 );
		setLogScaleY( 10.0 );

		// 各種フラグ
		_info[_curIndex]._isLogScaleX = false;
		_info[_curIndex]._isLogScaleY = false;

		return true;
	}

	void delGraph(){
		_info[_curIndex]._expr1 = "";
		_info[_curIndex]._expr2 = "";

		// 計算結果保持バッファを解放
		_info[_curIndex]._ans = [];
		_info[_curIndex]._ansNum.set( 0 );

		// 後ろのグラフ情報を前に詰める
		for( int i = _curIndex + 1; i < _infoNum; i++ ){
			_info[i - 1] = _info[i];
		}

		_infoNum--;
		if( _curIndex == _infoNum ){
			selGraph( _infoNum - 1 );
		}
		if( _infoNum == 0 ){
			// グラフ情報1個は常に存在させる
			addGraph();
		}
	}

	bool selGraph( int index ){
		if( (index < 0) || (index >= _infoNum) ){
			return false;
		}
		_curIndex = index;
		return true;
	}

	void setDrawFlag( bool draw ){
		_info[_curIndex]._draw = draw;
	}
	bool drawFlag(){
		return _info[_curIndex]._draw;
	}

	// グラフの色を設定する
	void setColor( int color ){
		_info[_curIndex]._color = color;
	}

	// グラフの色を確認する
	int color(){
		return _info[_curIndex]._color;
	}

	// グラフの種類を設定する
	void setMode( int mode ){
		_info[_curIndex]._mode = mode;
	}

	// グラフの種類を確認する
	int mode(){
		return _info[_curIndex]._mode;
	}

	void setExpr( String expr ){
		// 計算式を取り込む
		_info[_curIndex]._expr1 = expr;
		_info[_curIndex]._expr2 = "";
	}
	void setExpr1( String expr1 ){
		// 計算式を取り込む
		_info[_curIndex]._expr1 = expr1;
	}
	void setExpr2( String expr2 ){
		// 計算式を取り込む
		_info[_curIndex]._expr2 = expr2;
	}

	// 計算式を確認する
	String expr(){
		return _info[_curIndex]._expr1;
	}
	String expr1(){
		return _info[_curIndex]._expr1;
	}
	String expr2(){
		return _info[_curIndex]._expr2;
	}

	// 指定関数が計算式に含まれているかチェックする
	bool _checkExpr( String expr, String func ){
		int pos = expr.toLowerCase().indexOf( func.toLowerCase() );
		if( pos >= 0 ){
			if( expr.length > pos + func.length ){
				String chr = ClipMath.charAt( expr.toLowerCase(), pos + func.length );
				String chrs = "0123456789_abcdefghijklmnopqrstuvwxyz";
				if( !chrs.contains( chr ) ){
					return true;
				}
			} else {
				return true;
			}
		}
		return false;
	}
	void checkExpr( String func ){
		if(
			_checkExpr( _info[_curIndex]._expr1, func ) ||
			_checkExpr( _info[_curIndex]._expr2, func )
		){
			// 計算結果保持バッファを解放
			delAns();
		}
	}

	void setIndex( int index ){
		// X座標に対応する変数のインデックスを保持
		_info[_curIndex]._index = index;
	}

	// X座標に対応する変数のインデックスを確認する
	int index(){
		return _info[_curIndex]._index;
	}

	void setStart( double start ){
		_info[_curIndex]._start = start;
	}
	void setEnd( double end ){
		_info[_curIndex]._end = end;
	}
	void setStep( double step ){
		_info[_curIndex]._step = step;
	}

	//
	double start(){
		return _info[_curIndex]._start;
	}
	double end(){
		return _info[_curIndex]._end;
	}
	double step(){
		return _info[_curIndex]._step;
	}

	// 対数座標系に設定する
	void setLogScaleX( double base ){
		if( base <= 1.0 ){
			_info[_curIndex]._isLogScaleX = false;
		} else {
			_info[_curIndex]._isLogScaleX = true;
			_info[_curIndex]._baseX       = base;
			_info[_curIndex]._logBaseX    = 1.0 / ClipMath.log( base );
		}
	}
	void setLogScaleY( double base ){
		if( base <= 1.0 ){
			_info[_curIndex]._isLogScaleY = false;
		} else {
			_info[_curIndex]._isLogScaleY = true;
			_info[_curIndex]._baseY       = base;
			_info[_curIndex]._logBaseY    = 1.0 / ClipMath.log( base );
		}
	}

	// 対数座標系かどうか確認する
	bool isLogScaleX(){
		return _info[_curIndex]._isLogScaleX;
	}
	bool isLogScaleY(){
		return _info[_curIndex]._isLogScaleY;
	}

	// 底を確認する
	double logBaseX(){
		return _info[_curIndex]._baseX;
	}
	double logBaseY(){
		return _info[_curIndex]._baseY;
	}

	double logX( double x ){
		return _info[_curIndex]._isLogScaleX ? ClipMath.log( x ) * _info[_curIndex]._logBaseX : x;
	}
	double logY( double y ){
		return _info[_curIndex]._isLogScaleY ? ClipMath.log( y ) * _info[_curIndex]._logBaseY : y;
	}
	double expX( double x ){
		return _info[_curIndex]._isLogScaleX ? ClipMath.exp( x / _info[_curIndex]._logBaseX ) : x;
	}
	double expY( double y ){
		return _info[_curIndex]._isLogScaleY ? ClipMath.exp( y / _info[_curIndex]._logBaseY ) : y;
	}

	// 計算結果を消去する
	void delAns(){
		// 計算結果保持バッファを解放
		_info[_curIndex]._ans = [];
		_info[_curIndex]._ansNum.set( 0 );
	}

	// グラフイメージを確保する
	bool create( width, height ){
		_gWorld.scroll(
			(width  - _gWorld.width ()) / 2.0,
			(height - _gWorld.height()) / 2.0
			);
		return _gWorld.create( width, height, false );
	}

	// グラフイメージを登録する
	bool open( List<int> image, int offset, int width, int height ){
		_gWorld.scroll(
			(width  - _gWorld.width ()) / 2.0,
			(height - _gWorld.height()) / 2.0
			);
		return _gWorld.open( image, offset, width, height, false );
	}

	// グラフイメージをクリアする
	void _drawHLine( double y ){
		int yy = _gWorld.imgPosY( y );
		ClipGWorld.gWorldLine( _gWorld, 0, yy, _gWorld.width() - 1, yy );
		_gWorld.setGWorldLine( true );
		for( int i = 0; i < _gWorld.width(); i++ ){
			_gWorld.put( i, yy );
		}
		_gWorld.setGWorldLine( false );
	}
	void _drawVLine( double x ){
		int xx = _gWorld.imgPosX( x );
		ClipGWorld.gWorldLine( _gWorld, xx, 0, xx, _gWorld.height() - 1 );
		_gWorld.setGWorldLine( true );
		for( int i = 0; i < _gWorld.height(); i++ ){
			_gWorld.put( xx, i );
		}
		_gWorld.setGWorldLine( false );
	}
	void _drawXText( double x, double y ){
		int yy;

		String text = ClipMath.floatToString( x, 15 );
		ClipTextInfo tmp = ClipTextInfo();
		_gWorld.getTextInfo( text, tmp );
		int width   = tmp.width();
		int ascent  = tmp.ascent();
		int descent = tmp.descent();

		if( _gWorld.imgPosY( y ) < 0 ){
			yy = ascent + 1;
		} else if( (_gWorld.imgPosY( y ) + (ascent + descent + 1)) >= _gWorld.height() ){
			yy = _gWorld.height() - descent;
		} else {
			yy = _gWorld.imgPosY( y ) + ascent + 2;
		}
		_gWorld.drawText(
			text,
			_gWorld.imgPosX( x ) + 2,
			yy,
			false
			);
	}
	void _drawYText( double x, double y ){
		String text = ClipMath.floatToString( y, 15 );
		ClipTextInfo tmp = ClipTextInfo();
		_gWorld.getTextInfo( text, tmp );
		int width   = tmp.width();
		int ascent  = tmp.ascent();
		int descent = tmp.descent();

		if( (_gWorld.imgPosX( x ) - (width + 1)) < 0 ){
			_gWorld.drawText(
				text,
				1,
				_gWorld.imgPosY( y ) - descent,
				false
				);
		} else if( _gWorld.imgPosX( x ) >= _gWorld.width() ){
			_gWorld.drawText(
				text,
				_gWorld.width(),
				_gWorld.imgPosY( y ) - descent,
				true
				);
		} else {
			_gWorld.drawText(
				text,
				_gWorld.imgPosX( x ),
				_gWorld.imgPosY( y ) - descent,
				true
				);
		}
	}
	void clear( int backColor, int scaleColor, int unitColor, double unitX, double unitY, int textColor, double textX, double textY ){
		int i;
		int tmp;
		double pos, end;

		if( unitX > 0.0 ){
			while( true ){
				tmp = _gWorld.imgSizX( unitX );
				if( (tmp < 0) || (tmp >= 2) ){
					break;
				}
				unitX *= 10.0;
			}
		}
		if( unitY > 0.0 ){
			while( true ){
				tmp = _gWorld.imgSizY( unitY );
				if( (tmp < 0) || (tmp >= 2) ){
					break;
				}
				unitY *= 10.0;
			}
		}

		// グラフ画面の背景塗りつぶし
		_gWorld.clear( backColor );

		int saveColor = _gWorld.color();
		_gWorld.setColor( unitColor );

		// 水平方向目盛り線の描画
		if( unitX > 0.0 ){
			pos = _gWorld.wndPosX( 0 );
			end = _gWorld.wndPosX( _gWorld.width() - 1 );
			i = pos ~/ unitX;
			if( (_gWorld.wndPosX( 1 ) - pos) > 0.0 ){
				while( (pos = i * unitX) <= end ){
					_drawVLine( pos );
					i++;
				}
			} else {
				while( (pos = i * unitX) >= end ){
					_drawVLine( pos );
					i--;
				}
			}
		}

		// 垂直方向目盛り線の描画
		if( unitY > 0.0 ){
			pos = _gWorld.wndPosY( 0 );
			end = _gWorld.wndPosY( _gWorld.height() - 1 );
			i = pos ~/ unitY;
			if( (_gWorld.wndPosY( 1 ) - pos) > 0.0 ){
				while( (pos = i * unitY) <= end ){
					_drawHLine( pos );
					i++;
				}
			} else {
				while( (pos = i * unitY) >= end ){
					_drawHLine( pos );
					i--;
				}
			}
		}

		_gWorld.setColor( scaleColor );

		// X軸の描画
		_drawHLine( 0.0 );

		// Y軸の描画
		_drawVLine( 0.0 );

		_gWorld.setColor( textColor );

		// 水平方向目盛り文字の描画
		unitX *= textX;
		if( unitX > 0.0 ){
			pos = _gWorld.wndPosX( 0 );
			end = _gWorld.wndPosX( _gWorld.width() - 1 );
			i = pos ~/ unitX;
			if( (_gWorld.wndPosX( 1 ) - pos) > 0.0 ){
				while( (pos = i * unitX) <= end ){
					_drawXText( pos, 0.0 );
					i++;
				}
			} else {
				while( (pos = i * unitX) >= end ){
					_drawXText( pos, 0.0 );
					i--;
				}
			}
		}

		// 垂直方向目盛り文字の描画
		unitY *= textY;
		if( unitY > 0.0 ){
			pos = _gWorld.wndPosY( 0 );
			end = _gWorld.wndPosY( _gWorld.height() - 1 );
			i = pos ~/ unitY;
			if( (_gWorld.wndPosY( 1 ) - pos) > 0.0 ){
				while( (pos = i * unitY) <= end ){
					_drawYText( 0.0, pos );
					i++;
				}
			} else {
				while( (pos = i * unitY) >= end ){
					_drawYText( 0.0, pos );
					i--;
				}
			}
		}

		_gWorld.setColor( saveColor );
	}

	// グラフを描画する
	bool _process( ClipProc proc, ClipParam param, String expr, double x, ParamFloat y ){
		bool ret = false;

		// X座標をセット
		param.variable().set( _info[_curIndex]._index, x, false );

		// Y座標を計算する
		bool saveAnsFlag = proc.ansFlag();
		proc.setAnsFlag( false );
		if( proc.processLoop( expr, param ) == ClipGlobal.procEnd ){
			// Y座標をセット
			if( param.val( 0 ).imag() == 0.0 ){
				y.set( param.val( 0 ).toFloat() );
			} else {
				y.set( double.nan );
			}
			ret = true;
		}
		proc.setAnsFlag( saveAnsFlag );

		return ret;
	}
	bool _drawLine( int x1, int y1, int x2, int y2 ){
		ParamInteger xx1 = ParamInteger( x1 );
		ParamInteger yy1 = ParamInteger( y1 );
		ParamInteger xx2 = ParamInteger( x2 );
		ParamInteger yy2 = ParamInteger( y2 );
		if( _gWorld.clipLine( xx1, yy1, xx2, yy2 ) == 1 ){
			_gWorld.drawLine( xx1.val(), yy1.val(), xx2.val(), yy2.val() );
			return true;
		}
		return false;
	}
	void _plot( ClipProc proc, ClipParam param, int start, int end, List<ClipGraphAns> ans, ParamInteger ansNum, List<ClipGraphAns>? startAns, int startIndex ){
		int i;
		bool drawFlag = false;
		int posX = 0, posY = 0;
		int oldX, oldY;
		ParamFloat yy = ParamFloat();

		if( start > end ){
			int tmp = start; start = end; end = tmp;
		}
		ansNum.set( end - start + 1 );
		if( ansNum.val() <= 0 ){
			ansNum.set( 0 );
		} else {
			bool saveFlag = param.fileFlag();
			param.setFileFlag( false );

			// 計算結果保持バッファを確保
			for( i = 0; i < ansNum.val(); i++ ){
				ans[i] = ClipGraphAns();
			}

			_gWorld.setColor( _info[_curIndex]._color );

			if( startIndex > 0 ){
				drawFlag = true;
				posX = _gWorld.imgPosX( logX( startAns![startIndex]._x  ) );
				posY = _gWorld.imgPosY( logY( startAns[startIndex]._y1 ) );
			}
			for( i = 0; i < ansNum.val(); i++ ){
				ans[i]._x = expX( _gWorld.wndPosX( start + i ) );
				if( _process( proc, param, _info[_curIndex]._expr1, ans[i]._x, yy ) ){
					ans[i]._y1 = yy.val();
					double tmp = logY( ans[i]._y1 );
					if( ClipMath.isInf( tmp ) || ClipMath.isNan( tmp ) ){
						drawFlag = false;
					} else {
						// 計算結果をプロット
						if( drawFlag ){
							oldX = posX;
							oldY = posY;
							posX = _gWorld.imgPosX( logX( ans[i]._x  ) );
							posY = _gWorld.imgPosY( logY( ans[i]._y1 ) );
							_drawLine( oldX, oldY, posX, posY );
						} else {
							drawFlag = true;
							posX = _gWorld.imgPosX( logX( ans[i]._x  ) );
							posY = _gWorld.imgPosY( logY( ans[i]._y1 ) );
						}
					}
				} else {
					ansNum.set( i );
					break;
				}
			}
			if( startIndex == 0 ){
				if( drawFlag ){
					oldX = posX;
					oldY = posY;
					posX = _gWorld.imgPosX( logX( startAns![startIndex]._x  ) );
					posY = _gWorld.imgPosY( logY( startAns[startIndex]._y1 ) );
					_drawLine( oldX, oldY, posX, posY );
				}
			}

			param.setFileFlag( saveFlag );
		}
	}
	void _plotStep( ClipProc proc, ClipParam param, double start, double end, double step, List<ClipGraphAns> ans, ParamInteger ansNum, List<ClipGraphAns>? startAns, int startIndex ){
		int i;
		bool drawFlag = false;
		int posX = 0, posY = 0;
		int oldX, oldY;
		ParamFloat yy = ParamFloat();

		if( start > end ){
			double tmp = start; start = end; end = tmp;
		}
		if( step < 0.0 ){
			step = -step;
		}
		if( step == 0.0 ){
			ansNum.set( 0 );
		} else {
			ansNum.set( (end - start) ~/ step + 1 );
		}
		if( ansNum.val() <= 0 ){
			ansNum.set( 0 );
		} else {
			bool saveFlag = param.fileFlag();
			param.setFileFlag( false );

			// 計算結果保持バッファを確保
			for( i = 0; i < ansNum.val(); i++ ){
				ans[i] = ClipGraphAns();
			}

			_gWorld.setColor( _info[_curIndex]._color );

			switch( _info[_curIndex]._mode ){
			case ClipGlobal.graphModeParam:
				if( startIndex > 0 ){
					drawFlag = true;
					posX = _gWorld.imgPosX( startAns![startIndex]._y1 );
					posY = _gWorld.imgPosY( startAns[startIndex]._y2 );
				}
				for( i = 0; i < ansNum.val(); i++ ){
					ans[i]._x = start + step * i;
					if( _process( proc, param, _info[_curIndex]._expr1, ans[i]._x, yy ) ){
						ans[i]._y1 = yy.val();
						if( _process( proc, param, _info[_curIndex]._expr2, ans[i]._x, yy ) ){
							ans[i]._y2 = yy.val();
							// 計算結果をプロット
							if( drawFlag ){
								oldX = posX;
								oldY = posY;
								posX = _gWorld.imgPosX( ans[i]._y1 );
								posY = _gWorld.imgPosY( ans[i]._y2 );
								_drawLine( oldX, oldY, posX, posY );
							} else {
								drawFlag = true;
								posX = _gWorld.imgPosX( ans[i]._y1 );
								posY = _gWorld.imgPosY( ans[i]._y2 );
							}
						} else {
							ansNum.set( i );
							break;
						}
					} else {
						ansNum.set( i );
						break;
					}
				}
				if( startIndex == 0 ){
					if( drawFlag ){
						oldX = posX;
						oldY = posY;
						posX = _gWorld.imgPosX( startAns![startIndex]._y1 );
						posY = _gWorld.imgPosY( startAns[startIndex]._y2 );
						_drawLine( oldX, oldY, posX, posY );
					}
				}
				break;
			case ClipGlobal.graphModePolar:
				if( startIndex > 0 ){
					drawFlag = true;
					posX = _gWorld.imgPosX( startAns![startIndex]._y1 * MathComplex.fcos( startAns[startIndex]._x ) );
					posY = _gWorld.imgPosY( startAns[startIndex]._y1 * MathComplex.fsin( startAns[startIndex]._x ) );
				}
				for( i = 0; i < ansNum.val(); i++ ){
					ans[i]._x = start + step * i;
					if( _process( proc, param, _info[_curIndex]._expr1, ans[i]._x, yy ) ){
						ans[i]._y1 = yy.val();
						double tmp = ans[i]._y1;
						if( ClipMath.isInf( tmp ) || ClipMath.isNan( tmp ) ){
							drawFlag = false;
						} else {
							// 計算結果をプロット
							if( drawFlag ){
								oldX = posX;
								oldY = posY;
								posX = _gWorld.imgPosX( ans[i]._y1 * MathComplex.fcos( ans[i]._x ) );
								posY = _gWorld.imgPosY( ans[i]._y1 * MathComplex.fsin( ans[i]._x ) );
								_drawLine( oldX, oldY, posX, posY );
							} else {
								drawFlag = true;
								posX = _gWorld.imgPosX( ans[i]._y1 * MathComplex.fcos( ans[i]._x ) );
								posY = _gWorld.imgPosY( ans[i]._y1 * MathComplex.fsin( ans[i]._x ) );
							}
						}
					} else {
						ansNum.set( i );
						break;
					}
				}
				if( startIndex == 0 ){
					if( drawFlag ){
						oldX = posX;
						oldY = posY;
						posX = _gWorld.imgPosX( startAns![startIndex]._y1 * MathComplex.fcos( startAns[startIndex]._x ) );
						posY = _gWorld.imgPosY( startAns[startIndex]._y1 * MathComplex.fsin( startAns[startIndex]._x ) );
						_drawLine( oldX, oldY, posX, posY );
					}
				}
				break;
			}

			param.setFileFlag( saveFlag );
		}
	}
	bool plot( ClipProc proc, ClipParam param ){
		// 計算結果保持バッファを解放
		delAns();

		switch( _info[_curIndex]._mode ){
		case ClipGlobal.graphModeRect:
			_plot(
				proc, param,
				_gWorld.imgPosX( _info[_curIndex]._start ),
				_gWorld.imgPosX( _info[_curIndex]._end   ),
				_info[_curIndex]._ans, _info[_curIndex]._ansNum,
				null, -1
				);
			break;
		case ClipGlobal.graphModeParam:
		case ClipGlobal.graphModePolar:
			_plotStep(
				proc, param,
				_info[_curIndex]._start,
				_info[_curIndex]._end,
				_info[_curIndex]._step,
				_info[_curIndex]._ans, _info[_curIndex]._ansNum,
				null, -1
				);
			break;
		}

		return (_info[_curIndex]._ansNum.val() != 0);
	}
	bool _plotPos( ClipProc proc, ClipParam param, double pos ){
		int i;
		bool beforeFlag = false;
		List<ClipGraphAns> tmpAns = [];
		ParamInteger tmpAnsNum = ParamInteger();

		if( _info[_curIndex]._ansNum.val() <= 0 ){
			return false;
		}

		switch( _info[_curIndex]._mode ){
		case ClipGlobal.graphModeRect:
			int start, end, step;

			// 既存データの前・後どちらに追加するのかを調べる
			if( _info[_curIndex]._ans[0]._x < _info[_curIndex]._ans[_info[_curIndex]._ansNum.val() - 1]._x ){
				if( pos < logX( _info[_curIndex]._ans[0]._x ) ){
					start = _gWorld.imgPosX( pos );
					end   = _gWorld.imgPosX( logX( _info[_curIndex]._ans[0]._x ) ) - 1;
					beforeFlag = true;
				} else if( pos > logX( _info[_curIndex]._ans[_info[_curIndex]._ansNum.val() - 1]._x ) ){
					start = _gWorld.imgPosX( logX( _info[_curIndex]._ans[_info[_curIndex]._ansNum.val() - 1]._x ) ) + 1;
					end   = _gWorld.imgPosX( pos );
					beforeFlag = false;
				} else {
					return false;
				}
			} else {
				if( pos > logX( _info[_curIndex]._ans[0]._x ) ){
					start = _gWorld.imgPosX( pos );
					end   = _gWorld.imgPosX( logX( _info[_curIndex]._ans[0]._x ) ) - 1;
					beforeFlag = true;
				} else if( pos < logX( _info[_curIndex]._ans[_info[_curIndex]._ansNum.val() - 1]._x ) ){
					start = _gWorld.imgPosX( logX( _info[_curIndex]._ans[_info[_curIndex]._ansNum.val() - 1]._x ) ) + 1;
					end   = _gWorld.imgPosX( pos );
					beforeFlag = false;
				} else {
					return false;
				}
			}

			_plot(
				proc, param,
				start, end,
				tmpAns, tmpAnsNum,
				_info[_curIndex]._ans, beforeFlag ? 0 : _info[_curIndex]._ansNum.val() - 1
				);

			break;
		case ClipGlobal.graphModeParam:
		case ClipGlobal.graphModePolar:
			double start, end, step;

			step = _info[_curIndex]._step;

			// 既存データの前・後どちらに追加するのかを調べる
			if( step < 0.0 ){
				step = -step;
			}
			if( _info[_curIndex]._ans[0]._x < _info[_curIndex]._ans[_info[_curIndex]._ansNum.val() - 1]._x ){
				if( pos < _info[_curIndex]._ans[0]._x ){
					start = pos;
					end   = _info[_curIndex]._ans[0]._x - step;
					beforeFlag = true;
				} else if( pos > _info[_curIndex]._ans[_info[_curIndex]._ansNum.val() - 1]._x ){
					start = _info[_curIndex]._ans[_info[_curIndex]._ansNum.val() - 1]._x + step;
					end   = pos;
					beforeFlag = false;
				} else {
					return false;
				}
			} else {
				if( pos > _info[_curIndex]._ans[0]._x ){
					start = pos;
					end   = _info[_curIndex]._ans[0]._x - step;
					beforeFlag = true;
				} else if( pos < _info[_curIndex]._ans[_info[_curIndex]._ansNum.val() - 1]._x ){
					start = _info[_curIndex]._ans[_info[_curIndex]._ansNum.val() - 1]._x + step;
					end   = pos;
					beforeFlag = false;
				} else {
					return false;
				}
			}

			_plotStep(
				proc, param,
				start, end, step,
				tmpAns, tmpAnsNum,
				_info[_curIndex]._ans, beforeFlag ? 0 : _info[_curIndex]._ansNum.val() - 1
				);

			break;
		}

		if( tmpAnsNum.val() == 0 ){
			return false;
		}

		int newAnsNum = _info[_curIndex]._ansNum.val() + tmpAnsNum.val();
		List<ClipGraphAns> newAns = ClipGraphAns.newArray( newAnsNum );
		if( beforeFlag ){
			// 既存データの前に追加
			for( i = 0; i < tmpAnsNum.val(); i++ ){
				newAns[i].set( tmpAns[i] );
			}
			for( ; i < newAnsNum; i++ ){
				newAns[i].set( _info[_curIndex]._ans[i - tmpAnsNum.val()] );
			}
		} else {
			// 既存データの後ろに追加
			for( i = 0; i < _info[_curIndex]._ansNum.val(); i++ ){
				newAns[i].set( _info[_curIndex]._ans[i] );
			}
			for( ; i < newAnsNum; i++ ){
				newAns[i].set( tmpAns[i - _info[_curIndex]._ansNum.val()] );
			}
		}

		_info[_curIndex]._ans = newAns;
		_info[_curIndex]._ansNum.set( newAnsNum );

		return true;
	}
	bool _rePlot(){
		int i;
		bool drawFlag = false;
		int posX = 0, posY = 0;
		int oldX, oldY;

		_gWorld.setColor( _info[_curIndex]._color );

		if( _info[_curIndex]._ansNum.val() > 0 ){
			switch( _info[_curIndex]._mode ){
			case ClipGlobal.graphModeRect:
				for( i = 0; i < _info[_curIndex]._ansNum.val(); i++ ){
					double tmp = logY( _info[_curIndex]._ans[i]._y1 );
					if( ClipMath.isInf( tmp ) || ClipMath.isNan( tmp ) ){
						drawFlag = false;
					} else {
						// 計算結果をプロット
						if( drawFlag ){
							oldX = posX;
							oldY = posY;
							posX = _gWorld.imgPosX( logX( _info[_curIndex]._ans[i]._x  ) );
							posY = _gWorld.imgPosY( logY( _info[_curIndex]._ans[i]._y1 ) );
							_drawLine( oldX, oldY, posX, posY );
						} else {
							drawFlag = true;
							posX = _gWorld.imgPosX( logX( _info[_curIndex]._ans[i]._x  ) );
							posY = _gWorld.imgPosY( logY( _info[_curIndex]._ans[i]._y1 ) );
						}
					}
				}
				break;
			case ClipGlobal.graphModeParam:
				for( i = 0; i < _info[_curIndex]._ansNum.val(); i++ ){
					// 計算結果をプロット
					if( drawFlag ){
						oldX = posX;
						oldY = posY;
						posX = _gWorld.imgPosX( _info[_curIndex]._ans[i]._y1 );
						posY = _gWorld.imgPosY( _info[_curIndex]._ans[i]._y2 );
						_drawLine( oldX, oldY, posX, posY );
					} else {
						drawFlag = true;
						posX = _gWorld.imgPosX( _info[_curIndex]._ans[i]._y1 );
						posY = _gWorld.imgPosY( _info[_curIndex]._ans[i]._y2 );
					}
				}
				break;
			case ClipGlobal.graphModePolar:
				for( i = 0; i < _info[_curIndex]._ansNum.val(); i++ ){
					double tmp = _info[_curIndex]._ans[i]._y1;
					if( ClipMath.isInf( tmp ) || ClipMath.isNan( tmp ) ){
						drawFlag = false;
					} else {
						// 計算結果をプロット
						if( drawFlag ){
							oldX = posX;
							oldY = posY;
							posX = _gWorld.imgPosX( _info[_curIndex]._ans[i]._y1 * MathComplex.fcos( _info[_curIndex]._ans[i]._x ) );
							posY = _gWorld.imgPosY( _info[_curIndex]._ans[i]._y1 * MathComplex.fsin( _info[_curIndex]._ans[i]._x ) );
							_drawLine( oldX, oldY, posX, posY );
						} else {
							drawFlag = true;
							posX = _gWorld.imgPosX( _info[_curIndex]._ans[i]._y1 * MathComplex.fcos( _info[_curIndex]._ans[i]._x ) );
							posY = _gWorld.imgPosY( _info[_curIndex]._ans[i]._y1 * MathComplex.fsin( _info[_curIndex]._ans[i]._x ) );
						}
					}
				}
				break;
			}
			return true;
		}
		return false;
	}
	bool rePlot( [ClipProc? proc, ClipParam? param] ){
		if( proc == null ){
			return _rePlot();
		} else if( _info[_curIndex]._ansNum.val() <= 0 ){
			return plot( proc, param! );
		} else {
			List<bool> ret = List.filled( 3, false );
			ret[0] = _rePlot();
			ret[1] = _plotPos( proc, param!, _info[_curIndex]._start );
			ret[2] = _plotPos( proc, param , _info[_curIndex]._end   );
			return ret[0] || ret[1] || ret[2];
		}
	}

	// 目印を描画する
	void mark( double x, double y1, double y2 ){
		int i;
		int posX, posY;

		switch( _info[_curIndex]._mode ){
		case ClipGlobal.graphModeRect:
			// 垂直方向の線の描画
			posX = _gWorld.imgPosX( logX( x ) );
			for( i = 0; i < _gWorld.height(); i++ ){
				_gWorld.putXOR( posX, i );
			}

			// 水平方向の線の描画
			posY = _gWorld.imgPosY( logY( y1 ) );
			for( i = 0; i < _gWorld.width(); i++ ){
				_gWorld.putXOR( i, posY );
			}

			break;
		case ClipGlobal.graphModeParam:
			// 垂直方向の線の描画
			posX = _gWorld.imgPosX( y1 );
			for( i = 0; i < _gWorld.height(); i++ ){
				_gWorld.putXOR( posX, i );
			}

			// 水平方向の線の描画
			posY = _gWorld.imgPosY( y2 );
			for( i = 0; i < _gWorld.width(); i++ ){
				_gWorld.putXOR( i, posY );
			}

			break;
		case ClipGlobal.graphModePolar:
			// 垂直方向の線の描画
			posX = _gWorld.imgPosX( y1 * MathComplex.fcos( x ) );
			for( i = 0; i < _gWorld.height(); i++ ){
				_gWorld.putXOR( posX, i );
			}

			// 水平方向の線の描画
			posY = _gWorld.imgPosY( y1 * MathComplex.fsin( x ) );
			for( i = 0; i < _gWorld.width(); i++ ){
				_gWorld.putXOR( i, posY );
			}

			break;
		}
	}
	void markRect( double sx, double sy, double ex, double ey ){
		int i;
		int tmp;

		int posX = _gWorld.imgPosX( sx );
		int posY = _gWorld.imgPosY( sy );
		int endX = _gWorld.imgPosX( ex );
		int endY = _gWorld.imgPosY( ey );
		if( posX > endX ){
			tmp = posX; posX = endX; endX = tmp;
		}
		if( posY > endY ){
			tmp = posY; posY = endY; endY = tmp;
		}

		for( i = posX; i <= endX; i++ ){
			_gWorld.putXOR( i, posY );
			_gWorld.putXOR( i, endY );
		}
		for( i = posY + 1; i < endY; i++ ){
			_gWorld.putXOR( posX, i );
			_gWorld.putXOR( endX, i );
		}
	}

	// 計算結果を確認する
	int _search( double x, ParamFloat ratio ){
		int i;

		if( _info[_curIndex]._ansNum.val() > 0 ){
			int num = _info[_curIndex]._ansNum.val() - 1;
			if( _info[_curIndex]._ans[0]._x < _info[_curIndex]._ans[1]._x ){
				if( x < _info[_curIndex]._ans[0]._x ){
					return -1;
				} else if( x > _info[_curIndex]._ans[num]._x ){
					return _info[_curIndex]._ansNum.val();
				} else if( x == _info[_curIndex]._ans[num]._x ){
					ratio.set( 0.0 );
					return num;
				}
				for( i = 1; i <= num; i++ ){
					if( (x >= _info[_curIndex]._ans[i - 1]._x) && (x < _info[_curIndex]._ans[i]._x) ){
						ratio.set( (x - _info[_curIndex]._ans[i - 1]._x) / (_info[_curIndex]._ans[i]._x - _info[_curIndex]._ans[i - 1]._x) );
						return i - 1;
					}
				}
			} else {
				if( x > _info[_curIndex]._ans[0]._x ){
					return -1;
				} else if( x < _info[_curIndex]._ans[num]._x ){
					return _info[_curIndex]._ansNum.val();
				} else if( x == _info[_curIndex]._ans[num]._x ){
					ratio.set( 0.0 );
					return num;
				}
				for( i = 1; i <= num; i++ ){
					if( (x <= _info[_curIndex]._ans[i - 1]._x) && (x > _info[_curIndex]._ans[i]._x) ){
						ratio.set( (x - _info[_curIndex]._ans[i - 1]._x) / (_info[_curIndex]._ans[i]._x - _info[_curIndex]._ans[i - 1]._x) );
						return i - 1;
					}
				}
			}
		}
		return -2;
	}
	double _dist( double x1, double y1, double x2, double y2 ){
		if( ClipMath.isInf( x2 ) || ClipMath.isNan( x2 ) || ClipMath.isInf( y2 ) || ClipMath.isNan( y2 ) ){
			return -1.0;
		}
		return (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2);
	}
	int _searchParam( double x, double y ){
		int i;
		double tmp;

		if( _info[_curIndex]._ansNum.val() > 0 ){
			// 最も距離の短いデータを検索する
			int num  = 0;
			double dist = _dist( x, y, _info[_curIndex]._ans[0]._y1, _info[_curIndex]._ans[0]._y2 );
			for( i = 1; i < _info[_curIndex]._ansNum.val(); i++ ){
				tmp = _dist( x, y, _info[_curIndex]._ans[i]._y1, _info[_curIndex]._ans[i]._y2 );
				if( (tmp >= 0.0) && ((dist < 0.0) || (tmp < dist)) ){
					num  = i;
					dist = tmp;
				}
			}

			return num;
		}
		return -2;
	}
	int _searchPolar( double x, double y, ParamFloat ratio ){
		double tmp;

		if( _info[_curIndex]._ansNum.val() > 0 ){
			// 最も距離の短いデータを検索する
			int num  = 0;
			double dist = _dist(
				x, y,
				_info[_curIndex]._ans[0]._y1 * MathComplex.fcos( _info[_curIndex]._ans[0]._x ),
				_info[_curIndex]._ans[0]._y1 * MathComplex.fsin( _info[_curIndex]._ans[0]._x )
				);
			for( int i = 1; i < _info[_curIndex]._ansNum.val(); i++ ){
				tmp = _dist(
					x, y,
					_info[_curIndex]._ans[i]._y1 * MathComplex.fcos( _info[_curIndex]._ans[i]._x ),
					_info[_curIndex]._ans[i]._y1 * MathComplex.fsin( _info[_curIndex]._ans[i]._x )
					);
				if( (tmp >= 0.0) && ((dist < 0.0) || (tmp < dist)) ){
					num  = i;
					dist = tmp;
				}
			}

//			var c = new MathComplex();
//			c.ass( 360.0 );
//			c.angToAng( MATH_ANG_TYPE_DEG, complexAngType() );
//			var t1 = fatan2( y, x );
//				:

//			ratio.set( MATH_ABS( (t1 - t2) / (t3 - t2) ) );
			ratio.set( 0.0 );
			return num;
		}
		return -2;
	}
	bool getAns( int x, int y, ClipGraphAns ans ){
		int num;
		ParamFloat ratio = ParamFloat();

		switch( _info[_curIndex]._mode ){
		case ClipGlobal.graphModeRect:
			ans._x = expX( _gWorld.wndPosX( x ) );
			if( (num = _search( ans._x, ratio )) < -1 ){
				return false;
			}
			if( num == -1 ){
				return false;
			} else if( num == _info[_curIndex]._ansNum.val() ){
				return false;
			} else if( ratio.val() == 0.0 ){
				ans._y1 = _info[_curIndex]._ans[num]._y1;
				ans._y2 = _info[_curIndex]._ans[num]._y2;
			} else {
				ans._y1 = _info[_curIndex]._ans[num]._y1 + (_info[_curIndex]._ans[num + 1]._y1 - _info[_curIndex]._ans[num]._y1) * ratio.val();
				ans._y2 = _info[_curIndex]._ans[num]._y2 + (_info[_curIndex]._ans[num + 1]._y2 - _info[_curIndex]._ans[num]._y2) * ratio.val();
			}
			break;
		case ClipGlobal.graphModeParam:
			if( (num = _searchParam( _gWorld.wndPosX( x ), _gWorld.wndPosY( y ) )) < -1 ){
				return false;
			}
			if( num == -1 ){
				return false;
			} else if( num == _info[_curIndex]._ansNum.val() ){
				return false;
			} else {
				ans._x  = _info[_curIndex]._ans[num]._x ;
				ans._y1 = _info[_curIndex]._ans[num]._y1;
				ans._y2 = _info[_curIndex]._ans[num]._y2;
			}
			break;
		case ClipGlobal.graphModePolar:
			if( (num = _searchPolar( _gWorld.wndPosX( x ), _gWorld.wndPosY( y ), ratio )) < -1 ){
				return false;
			}
			if( num == -1 ){
				return false;
			} else if( num == _info[_curIndex]._ansNum.val() ){
				return false;
			} else if( ratio.val() == 0.0 ){
				ans._x  = _info[_curIndex]._ans[num]._x ;
				ans._y1 = _info[_curIndex]._ans[num]._y1;
			} else {
				ans._x  = _info[_curIndex]._ans[num]._x  + (_info[_curIndex]._ans[num + 1]._x  - _info[_curIndex]._ans[num]._x ) * ratio.val();
				ans._y1 = _info[_curIndex]._ans[num]._y1 + (_info[_curIndex]._ans[num + 1]._y1 - _info[_curIndex]._ans[num]._y1) * ratio.val();
			}
			break;
		}

		return true;
	}
	bool get( ClipProc proc, ClipParam param, double x, ParamFloat y1, ParamFloat y2 ){
		int i;
		int num;
		ParamFloat ratio = ParamFloat();
		List<ClipGraphAns> tmp;

		if( (num = _search( x, ratio )) < -1 ){
			return false;
		}
		if( num == -1 ){
			if( !_process( proc, param, _info[_curIndex]._expr1, x, y1 ) ){
				return false;
			}
			if( _info[_curIndex]._mode == ClipGlobal.graphModeParam ){
				if( !_process( proc, param, _info[_curIndex]._expr2, x, y2 ) ){
					return false;
				}
			}

			// 既存のデータをコピー
			tmp = ClipGraphAns.newArray( _info[_curIndex]._ansNum.val() + 1 );
			for( i = 0; i < _info[_curIndex]._ansNum.val(); i++ ){
//				tmp[i + 1].set( _info[_curIndex]._ans[i] );
				tmp[i + 1] = _info[_curIndex]._ans[i];
			}

			num = 0;
		} else if( num == _info[_curIndex]._ansNum.val() ){
			if( !_process( proc, param, _info[_curIndex]._expr1, x, y1 ) ){
				return false;
			}
			if( _info[_curIndex]._mode == ClipGlobal.graphModeParam ){
				if( !_process( proc, param, _info[_curIndex]._expr2, x, y2 ) ){
					return false;
				}
			}

			// 既存のデータをコピー
			tmp = ClipGraphAns.newArray( _info[_curIndex]._ansNum.val() + 1 );
			for( i = 0; i < _info[_curIndex]._ansNum.val(); i++ ){
//				tmp[i].set( _info[_curIndex]._ans[i] );
				tmp[i] = _info[_curIndex]._ans[i];
			}

			num = _info[_curIndex]._ansNum.val();
		} else if( ratio.val() == 0.0 ){
			y1.set( _info[_curIndex]._ans[num]._y1 );
			y2.set( _info[_curIndex]._ans[num]._y2 );
			return true;
		} else {
			if( !_process( proc, param, _info[_curIndex]._expr1, x, y1 ) ){
				return false;
			}
			if( _info[_curIndex]._mode == ClipGlobal.graphModeParam ){
				if( !_process( proc, param, _info[_curIndex]._expr2, x, y2 ) ){
					return false;
				}
			}

			// 既存のデータをコピー
			tmp = ClipGraphAns.newArray( _info[_curIndex]._ansNum.val() + 1 );
			for( i = 0; i <= num; i++ ){
//				tmp[i].set( _info[_curIndex]._ans[i] );
				tmp[i] = _info[_curIndex]._ans[i];
			}
			for( ; i < _info[_curIndex]._ansNum.val(); i++ ){
//				tmp[i + 1].set( _info[_curIndex]._ans[i] );
				tmp[i + 1] = _info[_curIndex]._ans[i];
			}

			num++;
		}

		// 新規データをセット
		tmp[num]._x  = x;
		tmp[num]._y1 = y1.val();
		tmp[num]._y2 = y2.val();
		_info[_curIndex]._ansNum.set( _info[_curIndex]._ansNum.val() + 1 );
		_info[_curIndex]._ans = tmp;

		return true;
	}
}
