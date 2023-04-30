/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import 'dart:ui' as ui;

class CanvasEnv {
	// setColor用
	late int _colorR;
	late int _colorG;
	late int _colorB;
	late int _colorA;

	// setFont用
	late double _fontSize;
	late String _font;

	// setStrokeWidth用
	late double _strokeWidth;

	CanvasEnv() {
		_colorR = 0;
		_colorG = 0;
		_colorB = 0;
		_colorA = 255;

		_fontSize = 0.0;
		_font = "";

		_strokeWidth = 1.0;
	}
}

CanvasEnv _canvasEnv = CanvasEnv();
void setCanvasEnv( CanvasEnv env ){
	_canvasEnv = env;
}

// キャンバス
class Canvas {
	late int _width;
	late int _height;
	late ui.Canvas _c;
	late ui.Paint _p;

	Canvas( int width, int height ){
		_width  = width;
		_height = height;
	}

	void setSize( int width, int height ) {
		_width  = width;
		_height = height;
	}
	int width(){
		return _width;
	}
	int height(){
		return _height;
	}

	void setColor( int r, int g, int b, [int a = 255] ){
		if( (r != _canvasEnv._colorR) || (g != _canvasEnv._colorG) || (b != _canvasEnv._colorB) || (a != _canvasEnv._colorA) ){
			_canvasEnv._colorR = r;
			_canvasEnv._colorG = g;
			_canvasEnv._colorB = b;
			_canvasEnv._colorA = a;
		}
	}
	void setColorRGB( int rgb ){
		setColor( (rgb & 0xFF0000) >> 16, (rgb & 0x00FF00) >> 8, rgb & 0x0000FF );
	}
	void setColorBGR( int bgr ){
		setColor( bgr & 0x0000FF, (bgr & 0x00FF00) >> 8, (bgr & 0xFF0000) >> 16 );
	}

	void setFont( double size, String family ){
		_canvasEnv._fontSize = size;
		_canvasEnv._font = family;
	}

	void setStrokeWidth( double width ){
		_canvasEnv._strokeWidth = width;
	}

	void lock( ui.Canvas c, ui.Paint p ){
		_c = c;
		_p = p;
	}
	void unlock(){
	}

	void clear( [int? x, int? y, int? w, int? h] ){
		_p.style = ui.PaintingStyle.fill;
		_p.color = ui.Color.fromARGB( _canvasEnv._colorA, _canvasEnv._colorR, _canvasEnv._colorG, _canvasEnv._colorB );
		if( (x == null) && (y == null) && (w == null) && (h == null) ){
			_c.drawRect( ui.Rect.fromLTWH( 0, 0, _width + 1, _height + 1 ), _p );
		} else if( (w == null) && (h == null) ){
			_c.drawRect( ui.Rect.fromLTWH( x!.toDouble(), y!.toDouble(), 1, 1 ), _p );
		} else {
			_c.drawRect( ui.Rect.fromLTWH( x!.toDouble(), y!.toDouble(), w!.toDouble(), h!.toDouble() ), _p );
		}
	}
	void put( int x, int y ){
		_p.style = ui.PaintingStyle.fill;
		_p.color = ui.Color.fromARGB( _canvasEnv._colorA, _canvasEnv._colorR, _canvasEnv._colorG, _canvasEnv._colorB );
		_c.drawRect( ui.Rect.fromLTWH( x.toDouble(), y.toDouble(), 1, 1 ), _p );
	}
	void fill( double x, double y, double w, double h ){
		_p.style = ui.PaintingStyle.fill;
		_p.color = ui.Color.fromARGB( _canvasEnv._colorA, _canvasEnv._colorR, _canvasEnv._colorG, _canvasEnv._colorB );
		_c.drawRect( ui.Rect.fromLTWH( x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble() ), _p );
	}
	void line( double x1, double y1, double x2, double y2, [double? scale] ){
		_p.style = ui.PaintingStyle.stroke;
		_p.strokeWidth = _canvasEnv._strokeWidth;
		_p.color = ui.Color.fromARGB( _canvasEnv._colorA, _canvasEnv._colorR, _canvasEnv._colorG, _canvasEnv._colorB );
		if( scale == null ){
			_c.drawLine( ui.Offset( x1 + 0.5, y1 + 0.5 ), ui.Offset( x2 + 0.5, y2 + 0.5 ), _p );
		} else {
			_c.drawLine( ui.Offset( (x1 + 0.5) * scale, (y1 + 0.5) * scale ), ui.Offset( (x2 + 0.5) * scale, (y2 + 0.5) * scale ), _p );
		}
	}
	void rect( double x, double y, double w, double h, [double? scale] ){
		_p.style = ui.PaintingStyle.stroke;
		_p.strokeWidth = _canvasEnv._strokeWidth;
		_p.color = ui.Color.fromARGB( _canvasEnv._colorA, _canvasEnv._colorR, _canvasEnv._colorG, _canvasEnv._colorB );
		if( scale == null ){
			_c.drawRect( ui.Rect.fromLTWH( x + 0.5, y + 0.5, w, h ), _p );
		} else {
			_c.drawRect( ui.Rect.fromLTWH( (x + 0.5) * scale, (y + 0.5) * scale, w * scale, h * scale ), _p );
		}
	}
	void circle( double cx, double cy, double r ){
		_p.style = ui.PaintingStyle.stroke;
		_p.strokeWidth = _canvasEnv._strokeWidth;
		_p.color = ui.Color.fromARGB( _canvasEnv._colorA, _canvasEnv._colorR, _canvasEnv._colorG, _canvasEnv._colorB );
		_c.drawCircle( ui.Offset( cx, cy ), r, _p );
	}
	void drawString( String str, double x, double y ){
		ui.ParagraphBuilder builder = ui.ParagraphBuilder(
			ui.ParagraphStyle( textDirection: ui.TextDirection.ltr )
		);
		builder.pushStyle( ui.TextStyle(
				fontSize: _canvasEnv._fontSize,
				fontFamily: _canvasEnv._font,
				color: ui.Color.fromARGB( _canvasEnv._colorA, _canvasEnv._colorR, _canvasEnv._colorG, _canvasEnv._colorB )
		) );
		builder.addText( str );
		ui.Paragraph paragraph = builder.build();
		y -= _canvasEnv._fontSize;
		_c.drawParagraph( paragraph, ui.Offset( x, y ) );
	}

	int stringWidth( String str ){
		ui.ParagraphBuilder builder = ui.ParagraphBuilder(
				ui.ParagraphStyle( textDirection: ui.TextDirection.ltr )
		);
		builder.pushStyle( ui.TextStyle(
				fontSize: _canvasEnv._fontSize,
				fontFamily: _canvasEnv._font
		) );
		builder.addText( str );
		ui.Paragraph paragraph = builder.build();
		paragraph.layout( const ui.ParagraphConstraints( width: 0 ) );
		double width = paragraph.maxIntrinsicWidth;
		return width.toInt();
	}
}
