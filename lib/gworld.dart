/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import 'math/math.dart';
import 'param/float.dart';
import 'param/integer.dart';

// 文字情報クラス
//
// +---------+-+-------
// |         | |     ↑
// +---------+-+---  ｜
// | ■■■  | | ↑ ascent
// |■   ■  | | ｜  ｜
// |■   ■  | |sizeY｜
// | ■■  ■| | ↓  ↓
// +---------+-+------- baseline
// |         | |    descent
// +---------+-+-------
// |←sizeX→| |     ↑
// |← width →|
//
// +-----+-+-------
// +-----+-+---  ↑
// |   ■| | ↑  ｜
// |     | | ｜ ascent
// |   ■| |sizeY｜
// |   ■| | ｜  ｜
// |   ■| | ↓  ↓
// +---■+-+------- baseline
// |■■ | |    descent
// +-----+-+-------
// |sizeX| |     ↑
// | width |
class ClipCharInfo {
	late int _width; //
	late int _ascent; //
	late int _descent; //
	late int _sizeX; // データのメモリ幅
	late int _sizeY; // データのbaselineからのオフセット
	late String? _data; // データ
	ClipCharInfo(){
		_width   = 0;
		_ascent  = 0;
		_descent = 0;
		_sizeX   = 0;
		_sizeY   = 0;
		_data    = null;
	}
}

List<List<ClipCharInfo>> _gworld_char_info = List.filled( 10, [] ); // 文字情報

void newGWorldCharInfo( int charSet ){
	_gworld_char_info[charSet] = List.filled( 256, ClipCharInfo() );
	for( int i = 0; i < 256; i++ ){
		_gworld_char_info[charSet][i] = ClipCharInfo();
	}
}

// 文字情報を登録する
void regGWorldCharInfo( int charSet, int chr, int width, int ascent, int descent, int sizeX, int sizeY, String data ){
	_gworld_char_info[charSet][chr]._width   = width;
	_gworld_char_info[charSet][chr]._ascent  = ascent;
	_gworld_char_info[charSet][chr]._descent = descent;
	_gworld_char_info[charSet][chr]._sizeX   = sizeX;
	_gworld_char_info[charSet][chr]._sizeY   = sizeY;
	_gworld_char_info[charSet][chr]._data    = data;
}

// システムの背景色
int _gworld_bg_color = 0;
void regGWorldBgColor( int rgbColor ){
	_gworld_bg_color = rgbColor;
}
int gWorldBgColor(){
	return _gworld_bg_color;
}

// テキスト描画情報
class ClipTextInfo {
	late int _width;
	late int _ascent;
	late int _descent;
	ClipTextInfo(){
		_width   = 0;
		_ascent  = 0;
		_descent = 0;
	}
	int width(){ return _width; }
	int ascent(){ return _ascent; }
	int descent(){ return _descent; }
}

// イメージ・メモリ管理クラス
class ClipGWorld {
	// イメージ情報
	late List<int>? _image; // イメージ・メモリ
	late int _offset; // イメージ・メモリの幅
	late int _width; // イメージの論理幅
	late int _height; // イメージの高さ
	late bool _createFlag; // イメージが新規作成か登録されたかのフラグ
	late bool _rgbFlag; // RGBカラーモードかどうかのフラグ

	// ウィンドウ情報
	late double _offsetX; // Ｘ方向オフセット
	late double _offsetY; // Ｙ方向オフセット
	late double _ratioX; // Ｘ方向比率
	late double _ratioY; // Ｙ方向比率
	late double _ratioX2; // Ｘ方向比率の絶対値
	late double _ratioY2; // Ｙ方向比率の絶対値

	// スクロール情報
	late bool _beginScroll;
	late double _scrollPosX;
	late double _scrollPosY;
	late double _scrollOffX;
	late double _scrollOffY;

	// 現在点
	late int _imgMoveX; // 現在のＸ座標（イメージ用）
	late int _imgMoveY; // 現在のＹ座標（イメージ用）
	late double _wndMoveX; // 現在のＸ座標（ウィンドウ用）
	late double _wndMoveY; // 現在のＹ座標（ウィンドウ用）

	// カレントカラー
	late int _color;

	// 文字セット
	late int _charSet;

	late bool _gWorldLine;
	late bool _gWorldPut;

	ClipGWorld(){
		// イメージ情報
		_image      = null;
		_offset     = 0;
		_width      = 0;
		_height     = 0;
		_createFlag = false;
		_rgbFlag    = false;

		// ウィンドウ情報
		_offsetX = 0.0;
		_offsetY = 0.0;
		_ratioX  = 1.0;
		_ratioY  = 1.0;
		_ratioX2 = 1.0;
		_ratioY2 = 1.0;

		// スクロール情報
		_beginScroll = false;
		_scrollPosX  = 0.0;
		_scrollPosY  = 0.0;
		_scrollOffX  = 0.0;
		_scrollOffY  = 0.0;

		// 現在点
		_imgMoveX = 0;
		_imgMoveY = 0;
		_wndMoveX = 0.0;
		_wndMoveY = 0.0;

		// カレントカラー
		_color = 0;

		// 文字セット
		_charSet = 0;

		_gWorldLine = true;
		_gWorldPut = true;
	}

	// イメージを確保する
	bool create( int width, int height, bool initWindow, [bool rgbFlag = false] ){
		// イメージを開放する
		_dispose();

		if( (width <= 0) || (height <= 0) ){
			return false;
		}

		// イメージを確保する
		_image      = List.filled( width * height, 0 );
		_offset     = width;
		_width      = width;
		_height     = height;
		_createFlag = true;
		_rgbFlag    = rgbFlag;

		// ウィンドウ情報
		if( initWindow ){
			setWindow( 0.0, 0.0, 1.0, 1.0 );
		} else {
			// 現在点を更新する
			_wndMoveX = wndPosX( _imgMoveX );
			_wndMoveY = wndPosY( _imgMoveY );
		}

		// イメージをクリアする
		clear( 0 );

		return true;
	}

	// イメージを登録する
	bool open( List<int> image, int offset, int width, int height, bool initWindow, [bool rgbFlag = false] ){
		// イメージを開放する
		_dispose();

		if( (width <= 0) || (height <= 0) ){
			return false;
		}

		// イメージを登録する
		_image      = image;
		_offset     = offset;
		_width      = width;
		_height     = height;
		_createFlag = false;
		_rgbFlag    = rgbFlag;

		// ウィンドウ情報
		if( initWindow ){
			setWindow( 0.0, 0.0, 1.0, 1.0 );
		} else {
			// 現在点を更新する
			_wndMoveX = wndPosX( _imgMoveX );
			_wndMoveY = wndPosY( _imgMoveY );
		}

		// イメージをクリアする
		clear( 0 );

		return true;
	}

	// イメージを開放する
	void _dispose(){
		// イメージ情報
		_image      = null;
		_offset     = 0;
		_width      = 0;
		_height     = 0;
		_createFlag = false;
	}

	// ウィンドウを設定する
	void setWindow( double offsetX, double offsetY, double ratioX, double ratioY ){
		_offsetX = offsetX;
		_offsetY = offsetY;
		_ratioX  = ratioX;
		_ratioY  = ratioY;
		_ratioX2 = (_ratioX >= 0.0) ? _ratioX : -_ratioX;
		_ratioY2 = (_ratioY >= 0.0) ? _ratioY : -_ratioY;

		// 現在点を更新する
		_wndMoveX = wndPosX( _imgMoveX );
		_wndMoveY = wndPosY( _imgMoveY );
	}
	bool setWindowIndirect( double left, double bottom, double right, double top ){
		double sizeX, sizeY;

		if( ((sizeX = right - left) == 0.0) || ((sizeY = bottom - top) == 0.0) ){
			return false;
		}

		_ratioX  = (_width  - 1) / sizeX;
		_ratioY  = (_height - 1) / sizeY;
		_ratioX2 = (_ratioX >= 0.0) ? _ratioX : -_ratioX;
		_ratioY2 = (_ratioY >= 0.0) ? _ratioY : -_ratioY;
		_offsetX = 0.5 - left * _ratioX;
		_offsetY = 0.5 - top  * _ratioY;

		// 現在点を更新する
		_wndMoveX = wndPosX( _imgMoveX );
		_wndMoveY = wndPosY( _imgMoveY );

		return true;
	}

	// ウィンドウ位置をスクロールさせる
	void scroll( double scrollX, double scrollY ){
		if( _beginScroll ){
			_offsetX = _scrollOffX + (scrollX - _scrollPosX);
			_offsetY = _scrollOffY + (scrollY - _scrollPosY);
		} else {
			_offsetX += scrollX;
			_offsetY += scrollY;
		}
	}
	void beginScroll( double scrollX, double scrollY ){
		_beginScroll = true;
		_scrollPosX = scrollX;
		_scrollPosY = scrollY;
		_scrollOffX = _offsetX;
		_scrollOffY = _offsetY;
	}
	void endScroll(){
		_beginScroll = false;
	}

	// ウィンドウ情報を確認する
	void getWindow( [ParamFloat? offsetX, ParamFloat? offsetY, ParamFloat? ratioX, ParamFloat? ratioY] ){
		if( offsetX != null ) offsetX.set( _offsetX );
		if( offsetY != null ) offsetY.set( _offsetY );
		if( ratioX  != null ) ratioX .set( _ratioX  );
		if( ratioY  != null ) ratioY .set( _ratioY  );
	}

	// 論理座標から実座標を求める
	int imgPosX( double x ){
		return (x * _ratioX + _offsetX).toInt();
	}
	int imgPosY( double y ){
		return (y * _ratioY + _offsetY).toInt();
	}
	int imgSizX( double x ){
		x *= _ratioX2;
		if( MATH_ISINF( x ) || MATH_ISNAN( x ) ){
			return -1;
		}
		return x.toInt();
	}
	int imgSizY( double y ){
		y *= _ratioY2;
		if( MATH_ISINF( y ) || MATH_ISNAN( y ) ){
			return -1;
		}
		return y.toInt();
	}

	// 実座標から論理座標を求める
	double wndPosX( int x ){
		return (x - _offsetX) / _ratioX;
	}
	double wndPosY( int y ){
		return (y - _offsetY) / _ratioY;
	}
	double wndSizX( int x ){
		return x / _ratioX2;
	}
	double wndSizY( int y ){
		return y / _ratioY2;
	}

	// カレントカラーを設定する
	void setColor( int color ){
		_color = color;
		gWorldSetColor( this, _color );
	}

	// カレントカラーを確認する
	int color(){
		return _color;
	}

	// ドットを描画する
	bool putColor( int x, int y, int color ){
		if( (x < 0) || (x >= _width) || (y < 0) || (y >= _height) ){
			return false;
		}
		_image![y * _offset + x] = color;
		if( _gWorldPut ){
			if( color == _color ){
				gWorldPut( this, x, y );
			} else {
				gWorldPutColor( this, x, y, color );
			}
		}
		return true;
	}
	bool put( int x, int y ){
		return putColor( x, y, _color );
	}
	bool wndPut( double x, double y ){
		// 論理座標から実座標に変換
		return put( imgPosX( x ), imgPosY( y ) );
	}
	bool putXOR( int x, int y ){
		if( (x < 0) || (x >= _width) || (y < 0) || (y >= _height) ){
			return false;
		}
		int color;
		if( _rgbFlag ){
			int rgb = _image![y * _offset + x];
			int r = (rgb & 0xFF0000) >> 16;
			int g = (rgb & 0x00FF00) >> 8;
			int b =  rgb & 0x0000FF;
			color = ((255 - r) << 16) + ((255 - g) << 8) + (255 - b);
		} else {
			color = 255 - _image![y * _offset + x];
		}
		_image![y * _offset + x] = color;
		if( _gWorldPut ){
			gWorldPutColor( this, x, y, color );
		}
		return true;
	}

	// ドット値を確認する
	int get( int x, int y ){
		if( (x < 0) || (x >= _width) || (y < 0) || (y >= _height) ){
			return 0;
		}
		return _image![y * _offset + x];
	}
	int wndGet( double x, double y ){
		// 論理座標から実座標に変換
		return get( imgPosX( x ), imgPosY( y ) );
	}

	// イメージをクリアする
	void clear( int color ){
		int ix, iy, yy;
		for( iy = 0; iy < _height; iy++ ){
			yy = iy * _offset;
			for( ix = 0; ix < _width; ix++ ){
				_image![yy + ix] = color;
			}
		}
		gWorldClear( this, color );
	}

	// イメージを塗りつぶす
	void fill( int x, int y, int w, int h ){
		int ix, iy, yy;

		// クリッピング
		if( x < 0 ){
			w += x;
			x = 0;
		}
		if( y < 0 ){
			h += y;
			y = 0;
		}
		if( (x + w) > _width ){
			w = _width - x;
		}
		if( (y + h) > _height ){
			h = _height - y;
		}

		for( iy = y; iy < y + h; iy++ ){
			yy = iy * _offset;
			for( ix = x; ix < x + w; ix++ ){
				_image![yy + ix] = _color;
			}
		}

		gWorldFill( this, x, y, w, h );
	}
	void wndFill( double x, double y, double w, double h ){
		// 論理座標から実座標に変換
		int gx = imgPosX( x );
		int gy = imgPosY( y );
		int gw = imgPosX( x + w ) - gx;
		int gh = imgPosY( y + h ) - gy;
		if( gw < 0 ){
			gx += (gw + 1);
			gw = -gw;
		}
		if( gh < 0 ){
			gy += (gh + 1);
			gh = -gh;
		}

		fill( gx, gy, gw, gh );
	}

	// ラインを描画する
	void _clipLine( int x1, int y1, int x2, int y2, ParamInteger x, ParamInteger y ){
		double a, b;

		if( x.val() < 0 ){
			if( y1 == y2 ){
				x.set( 0 );
			} else {
				a = (y1 - y2) / (x1 - x2);
				b = y1 - a * x1;
				x.set( 0 );
				y.set( b.toInt() );
			}
		} else if( x.val() > _width ){
			if( y1 == y2 ){
				x.set( _width );
			} else {
				a = (y1 - y2) / (x1 - x2);
				b = y1 - a * x1;
				x.set( _width );
				y.set( (a * _width + b).toInt() );
			}
		}
		if( y.val() < 0 ){
			if( x1 == x2 ){
				y.set( 0 );
			} else {
				a = (y1 - y2) / (x1 - x2);
				b = y1 - a * x1;
				x.set( -b ~/ a );
				y.set( 0 );
			}
		} else if( y.val() > _height ){
			if( x1 == x2 ){
				y.set( _height );
			} else {
				a = (y1 - y2) / (x1 - x2);
				b = y1 - a * x1;
				x.set( (_height - b) ~/ a );
				y.set( _height );
			}
		}
	}
	int clipLine( ParamInteger x1, ParamInteger y1, ParamInteger x2, ParamInteger y2 ){
		int ret;

		if(
			(x1.val() >= 0) && (x1.val() <= _width ) &&
			(y1.val() >= 0) && (y1.val() <= _height) &&
			(x2.val() >= 0) && (x2.val() <= _width ) &&
			(y2.val() >= 0) && (y2.val() <= _height)
		){
			return 1;
		} else {
			if(
				(x1.val() >= 0) && (x1.val() <= _width ) &&
				(y1.val() >= 0) && (y1.val() <= _height)
			){
				// (x2,y2)を修正
				_clipLine( x1.val(), y1.val(), x2.val(), y2.val(), x2, y2 );
				ret = 1;
			} else if(
				(x2.val() >= 0) && (x2.val() <= _width ) &&
				(y2.val() >= 0) && (y2.val() <= _height)
			){
				// (x1,y1)を修正
				_clipLine( x1.val(), y1.val(), x2.val(), y2.val(), x1, y1 );
				ret = 1;
			} else {
				// (x1,y1),(x2,y2)を修正
				_clipLine( x1.val(), y1.val(), x2.val(), y2.val(), x1, y1 );
				_clipLine( x1.val(), y1.val(), x2.val(), y2.val(), x2, y2 );
				ret = 2;
			}
			if(
				((x1.val() <  0      ) && (x2.val() <  0      )) ||
				((y1.val() <  0      ) && (y2.val() <  0      )) ||
				((x1.val() >= _width ) && (x2.val() >= _width )) ||
				((y1.val() >= _height) && (y2.val() >= _height))
			){
				return 0;
			}
		}
		return ret;
	}
	void drawLine( int x1, int y1, int x2, int y2 ){
		gWorldLine( this, x1, y1, x2, y2 );
		_gWorldPut = false;

		int dx, dy;
		int step;
		int temp;
		int s;

		dx = MATH_ABS( (x2 - x1).toDouble() ).toInt();
		dy = MATH_ABS( (y2 - y1).toDouble() ).toInt();
		if( dx > dy ){
			if( x1 > x2 ){
				step = (y1 > y2) ? 1 : -1;
				temp = x1; x1 = x2; x2 = temp;
				y1 = y2;
			} else {
				step = (y1 < y2) ? 1 : -1;
			}
			put( x1.toInt(), y1.toInt() );
			s = dx ~/ 2;
			while( ++x1 <= x2 ){
				if( (s -= dy) < 0 ){
					s += dx;
					y1 += step;
				}
				put( x1, y1 );
			}
		} else {
			if( y1 > y2 ){
				step = (x1 > x2) ? 1 : -1;
				temp = y1; y1 = y2; y2 = temp;
				x1 = x2;
			} else {
				step = (x1 < x2) ? 1 : -1;
			}
			put( x1, y1 );
			s = dy ~/ 2;
			while( ++y1 <= y2 ){
				if( (s -= dx) < 0 ){
					s += dy;
					x1 += step;
				}
				put( x1, y1 );
			}
		}

		_gWorldPut = true;
	}
	void drawLineXOR( int x1, int y1, int x2, int y2 ){
		int dx, dy;
		int step;
		int temp;
		int s;

		dx = MATH_ABS( (x2 - x1).toDouble() ).toInt();
		dy = MATH_ABS( (y2 - y1).toDouble() ).toInt();
		if( dx > dy ){
			if( x1 > x2 ){
				step = (y1 > y2) ? 1 : -1;
				temp = x1; x1 = x2; x2 = temp;
				y1 = y2;
			} else {
				step = (y1 < y2) ? 1 : -1;
			}
			putXOR( x1, y1 );
			s = dx ~/ 2;
			while( ++x1 <= x2 ){
				if( (s -= dy) < 0 ){
					s += dx;
					y1 += step;
				}
				putXOR( x1, y1 );
			}
		} else {
			if( y1 > y2 ){
				step = (x1 > x2) ? 1 : -1;
				temp = y1; y1 = y2; y2 = temp;
				x1 = x2;
			} else {
				step = (x1 < x2) ? 1 : -1;
			}
			putXOR( x1, y1 );
			s = dy ~/ 2;
			while( ++y1 <= y2 ){
				if( (s -= dx) < 0 ){
					s += dy;
					x1 += step;
				}
				putXOR( x1, y1 );
			}
		}
	}
	bool line( int x1, int y1, int x2, int y2 ){
		ParamInteger xx1 = ParamInteger( x1 );
		ParamInteger yy1 = ParamInteger( y1 );
		ParamInteger xx2 = ParamInteger( x2 );
		ParamInteger yy2 = ParamInteger( y2 );
		if( clipLine( xx1, yy1, xx2, yy2 ) == 0 ){
			return false;
		}
		drawLine( xx1.val(), yy1.val(), xx2.val(), yy2.val() );
		moveTo( x2, y2 );
		return true;
	}
	bool lineXOR( int x1, int y1, int x2, int y2 ){
		ParamInteger xx1 = ParamInteger( x1 );
		ParamInteger yy1 = ParamInteger( y1 );
		ParamInteger xx2 = ParamInteger( x2 );
		ParamInteger yy2 = ParamInteger( y2 );
		if( clipLine( xx1, yy1, xx2, yy2 ) == 0 ){
			return false;
		}
		drawLineXOR( xx1.val(), yy1.val(), xx2.val(), yy2.val() );
		moveTo( x2, y2 );
		return true;
	}
	bool wndLine( double x1, double y1, double x2, double y2 ){
		// 論理座標から実座標に変換
		ParamInteger gx1 = ParamInteger( imgPosX( x1 ) );
		ParamInteger gy1 = ParamInteger( imgPosY( y1 ) );
		ParamInteger gx2 = ParamInteger( imgPosX( x2 ) );
		ParamInteger gy2 = ParamInteger( imgPosY( y2 ) );

		if( clipLine( gx1, gy1, gx2, gy2 ) == 0 ){
			return false;
		}
		drawLine( gx1.val(), gy1.val(), gx2.val(), gy2.val() );
		wndMoveTo( x2, y2 );
		return true;
	}
	void moveTo( int x, int y ){
		_imgMoveX = x;
		_imgMoveY = y;
		_wndMoveX = wndPosX( _imgMoveX );
		_wndMoveY = wndPosY( _imgMoveY );
	}
	void wndMoveTo( double x, double y ){
		_wndMoveX = x;
		_wndMoveY = y;
		_imgMoveX = imgPosX( _wndMoveX );
		_imgMoveY = imgPosY( _wndMoveY );
	}
	bool lineTo( int x, int y ){
		return line( _imgMoveX, _imgMoveY, x, y );
	}
	bool wndLineTo( double x, double y ){
		return wndLine( _wndMoveX, _wndMoveY, x, y );
	}

	// 文字セットを選択する
	void selectCharSet( int charSet ){
		_charSet = charSet;
	}

	// テキストを描画する
	void getTextInfo( String text, ClipTextInfo info ){
		info._width   = 0;
		info._ascent  = 0;
		info._descent = 0;

		int chr;
		for( int i = 0; i < text.length; i++ ){
			chr = charCodeAt( text, i );
			if( _gworld_char_info[_charSet][chr]._data != null ){
				info._width += _gworld_char_info[_charSet][chr]._width;
				if( _gworld_char_info[_charSet][chr]._ascent > info._ascent ){
					info._ascent = _gworld_char_info[_charSet][chr]._ascent;
				}
				if( _gworld_char_info[_charSet][chr]._descent > info._descent ){
					info._descent = _gworld_char_info[_charSet][chr]._descent;
				}
			}
		}
	}
	void drawTextColor( String text, int x, int y, int color, bool right ){
		gWorldTextColor( this, text, x, y, color, right );
		_gWorldPut = false;

		_imgMoveX = x;
		_imgMoveY = y;

		int xx, yy;
		int top;

		int chr;
		for( int i = 0; i < text.length; i++ ){
			chr = charCodeAt( text, right ? text.length - 1 - i : i );
			if( _gworld_char_info[_charSet][chr]._data != null ){
				if( right ){
					// 現在点を移動させる
					_imgMoveX -= _gworld_char_info[_charSet][chr]._width;
				}

				// 文字の描画
				top = 0;
				for( yy = _imgMoveY - _gworld_char_info[_charSet][chr]._sizeY; ; yy++ ){
					for( xx = 0; xx < _gworld_char_info[_charSet][chr]._sizeX; xx++ ){
						if( _gworld_char_info[_charSet][chr]._data!.length == top + xx ){
							break;
						}
						if( charAt( _gworld_char_info[_charSet][chr]._data!, top + xx ) == '1' ){
							putColor( _imgMoveX + xx, yy, color );
						}
					}
					if( _gworld_char_info[_charSet][chr]._data!.length == top + xx ){
						break;
					}
					top += _gworld_char_info[_charSet][chr]._sizeX;
				}

				if( !right ){
					// 現在点を移動させる
					_imgMoveX += _gworld_char_info[_charSet][chr]._width;
				}
			}
		}

		// 現在点の更新に伴う処理
		_wndMoveX = wndPosX( _imgMoveX );

		_gWorldPut = true;
	}
	void drawText( String text, int x, int y, bool right ){
		drawTextColor( text, x, y, _color, right );
	}
	void drawTextTo( String text, bool right ){
		drawTextColor( text, _imgMoveX, _imgMoveY, _color, right );
	}
	void wndDrawTextColor( String text, double x, double y, int color, bool right ){
		// 論理座標から実座標に変換
		int gx = imgPosX( x );
		int gy = imgPosY( y );

		drawTextColor( text, gx, gy, color, right );
	}
	void wndDrawText( String text, double x, double y, bool right ){
		wndDrawTextColor( text, x, y, _color, right );
	}
	void wndDrawTextTo( String text, bool right ){
		wndDrawTextColor( text, _wndMoveX, _wndMoveY, _color, right );
	}

	int imgMoveX(){
		return _imgMoveX;
	}
	int imgMoveY(){
		return _imgMoveY;
	}
	double wndMoveX(){
		return _wndMoveX;
	}
	double wndMoveY(){
		return _wndMoveY;
	}

	// イメージ情報を確認する
	List<int> image(){
		return _image!;
	}
	int offset(){
		return _offset;
	}
	int width(){
		return _width;
	}
	int height(){
		return _height;
	}
	bool rgbFlag(){
		return _rgbFlag;
	}

	int umax(){
		return (_rgbFlag ? MATH_UMAX_24 : MATH_UMAX_8).toInt();
	}

	void setGWorldLine( bool flag ){
		_gWorldLine = flag;
	}
}

void Function( ClipGWorld, int ) gWorldClear = ( gWorld, color ){};
void Function( ClipGWorld, int ) gWorldSetColor = ( gWorld, color ){};
void Function( ClipGWorld, int, int, int ) gWorldPutColor = ( gWorld, x, y, color ){};
void Function( ClipGWorld, int, int ) gWorldPut = ( gWorld, x, y ){};
void Function( ClipGWorld, int, int, int, int ) gWorldFill = ( gWorld, x, y, w, h ){};
void Function( ClipGWorld, int, int, int, int ) gWorldLine = ( gWorld, x1, y1, x2, y2 ){};
void Function( ClipGWorld, String, int, int, int, bool ) gWorldTextColor = ( gWorld, text, x, y, color, right ){};
