/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import '../gworld.dart';
import 'canvas.dart';
import 'easyclip.dart';

class EasyCanvas {
	EasyCanvas(){
		gWorldClear = ( gWorld, color ){
			Canvas canvas = curCanvas();
			canvas.setColorRGB( gWorldBgColor() );
			canvas.fill( 0, 0, canvas.width().toDouble(), canvas.height().toDouble() );
			canvas.setColorBGR( curPaletteColor( color ) );
			canvas.fill( 0, 0, gWorld.width().toDouble(), gWorld.height().toDouble() );
			canvas.setColorBGR( curPaletteColor( gWorld.color() ) );
		};
		gWorldSetColor = ( gWorld, color ){
			curCanvas().setColorBGR( curPaletteColor( color ) );
		};
		gWorldPutColor = ( gWorld, x, y, color ){
			Canvas canvas = curCanvas();
			canvas.setColorBGR( curPaletteColor( color ) );
			canvas.put( x, y );
			canvas.setColorBGR( curPaletteColor( gWorld.color() ) );
		};
		gWorldPut = ( gWorld, x, y ){
			curCanvas().put( x, y );
		};
		gWorldFill = ( gWorld, x, y, w, h ){
			curCanvas().fill( x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble() );
		};
		gWorldLine = ( gWorld, x1, y1, x2, y2 ){
			curCanvas().line( x1.toDouble(), y1.toDouble(), x2.toDouble(), y2.toDouble() );
		};
		gWorldTextColor = ( gWorld, text, x, y, color, right ){
			if( right ){
				x -= curCanvas().stringWidth( text ).toInt();
			}
			Canvas canvas = curCanvas();
			canvas.setColorBGR( curPaletteColor( color ) );
			canvas.drawString( text, x.toDouble(), y.toDouble() + 2 );
			canvas.setColorBGR( curPaletteColor( gWorld.color() ) );
		};
	}
}
