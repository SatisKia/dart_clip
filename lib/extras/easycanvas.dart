/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import '../gworld.dart';
import 'canvas.dart';
import 'easyclip.dart';

class EasyCanvas {
	EasyCanvas(){
		ClipGWorld.gWorldClear = ( gWorld, color ){
			Canvas canvas = EasyClip.curCanvas();
			canvas.setColorRGB( ClipGWorld.bgColor() );
			canvas.fill( 0, 0, canvas.width().toDouble(), canvas.height().toDouble() );
			canvas.setColorBGR( EasyClip.curPaletteColor( color ) );
			canvas.fill( 0, 0, gWorld.width().toDouble(), gWorld.height().toDouble() );
			canvas.setColorBGR( EasyClip.curPaletteColor( gWorld.color() ) );
		};
		ClipGWorld.gWorldSetColor = ( gWorld, color ){
			EasyClip.curCanvas().setColorBGR( EasyClip.curPaletteColor( color ) );
		};
		ClipGWorld.gWorldPutColor = ( gWorld, x, y, color ){
			Canvas canvas = EasyClip.curCanvas();
			canvas.setColorBGR( EasyClip.curPaletteColor( color ) );
			canvas.put( x, y );
			canvas.setColorBGR( EasyClip.curPaletteColor( gWorld.color() ) );
		};
		ClipGWorld.gWorldPut = ( gWorld, x, y ){
			EasyClip.curCanvas().put( x, y );
		};
		ClipGWorld.gWorldFill = ( gWorld, x, y, w, h ){
			EasyClip.curCanvas().fill( x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble() );
		};
		ClipGWorld.gWorldLine = ( gWorld, x1, y1, x2, y2 ){
			EasyClip.curCanvas().line( x1.toDouble(), y1.toDouble(), x2.toDouble(), y2.toDouble() );
		};
		ClipGWorld.gWorldTextColor = ( gWorld, text, x, y, color, right ){
			if( right ){
				x -= EasyClip.curCanvas().stringWidth( text ).toInt();
			}
			Canvas canvas = EasyClip.curCanvas();
			canvas.setColorBGR( EasyClip.curPaletteColor( color ) );
			canvas.drawString( text, x.toDouble(), y.toDouble() + 2 );
			canvas.setColorBGR( EasyClip.curPaletteColor( gWorld.color() ) );
		};
	}

	void setFont( double size, [String? family] ){
		EasyClip.curCanvas().setFont( size, family );
	}
}
