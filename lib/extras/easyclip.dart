/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import '../global.dart';
import '../gworld.dart';
import '../math/math.dart';
import '../math/matrix.dart';
import '../math/multiprec.dart';
import '../math/value.dart';
import '../param.dart';
import '../param/integer.dart';
import '../proc.dart';
import '../system/tm.dart';
import '../token.dart';
import 'canvas.dart';

late EasyClip _cur_clip;
void setClip( EasyClip clip ){
	_cur_clip = clip;
}
EasyClip curClip(){
	return _cur_clip;
}
int curPaletteColor( int index ){
	return _cur_clip._palette![index];
}
Canvas curCanvas(){
	return _cur_clip._canvas!;
}

class EasyClip {
	static int loopMax = 65536;
	static String arrayTokenStringSpace = " ";
	static String arrayTokenStringBreak = "\n";

	late ClipProcEnv _procEnv;
	late ClipProc _proc;
	late ClipParam _param;
	late List<int>? _palette;
	late CanvasEnv? _canvasEnv;
	late Canvas? _canvas;

	EasyClip(){
		mainProc = ( parentProc, parentParam, func, funcParam, childProc, childParam ){
			int ret = childProc.mainLoop( func, childParam, funcParam, parentParam );
			resetProcLoopCount();
			return ret;
		};
		doFuncGColor = ( rgb ){
			return doFuncGColorBGR( rgb, curClip()._palette! );
		};
		doFuncGColor24 = ( index ){
			return CLIP_RGB2BGR( curClip()._palette![index] );
		};
		doFuncEval = ( parentProc, childProc, childParam, string, value ){
			return parentProc.doFuncEvalSub( childProc, childParam, string, value );
		};
		doCommandGColor = ( index, rgb ){
			curClip()._palette![index] = CLIP_RGB2BGR( rgb );
		};
		doCommandGPut24 = ( x, y, rgb ){
      curCanvas().setColorRGB( rgb );
      curCanvas().put( x, y );
		};
		doCommandGPut24End = (){
			// キャンバスの現在色を戻す
      curCanvas().setColorBGR( curClip()._palette![procGWorld().color()] );
		};
		doCommandGGet24Begin = ( w, h ){
			int width  = procGWorld().width();
			int height = procGWorld().height();
			if( (width > 0) && (height > 0) ){
				w.set( width  );
				h.set( height );
//        return curCanvas().imageData( width, height ).data;
			}
			return null;
		};
		doCommandPlot = ( parentProc, childProc, childParam, graph, start, end, step ){
			parentProc.doCommandPlotSub( childProc, childParam, graph, start, end, step );
		};
		doCommandRePlot = ( parentProc, childProc, childParam, graph, start, end, step ){
			parentProc.doCommandRePlotSub( childProc, childParam, graph, start, end, step );
		};

		// 定義定数の値
		setDefineValue();

		// 計算処理メイン・クラスを生成する
		_procEnv = ClipProcEnv();
		setProcEnv( _procEnv );
		_proc = ClipProc( CLIP_PROC_DEF_PARENT_MODE, CLIP_PROC_DEF_PARENT_MP_PREC, CLIP_PROC_DEF_PARENT_MP_ROUND, false, CLIP_PROC_DEF_PRINT_ASSERT, CLIP_PROC_DEF_PRINT_WARN, false/*CLIP_PROC_DEF_GUPDATE_FLAG*/ );
		setProcWarnFlowFlag( true );
		setProcTraceFlag( false );
		setProcLoopMax( loopMax );

		// 計算パラメータ・クラスを生成する
		_param = ClipParam();
		setGlobalParam( _param );

		initProc();	// setProcEnvより後に実行

		// 乱数を初期化する
		MATH_SRAND( Tm().time() );
		MATH_RAND();

		// カラー・パレット
		_palette = null;

		// キャンバス
		_canvasEnv = null;
		_canvas = null;
	}

	void _setEnv(){
		setClip( this );
		setProcEnv( _procEnv );
		if( _canvasEnv != null ){
			setCanvasEnv( _canvasEnv! );
		}
	}

	ClipProc proc(){
		_setEnv();
		return _proc;
	}
	ClipParam param(){
		_setEnv();
		return _param;
	}
	Canvas canvas(){
		_setEnv();
		return _canvas!;
	}
	ClipGWorld gWorld(){
		_setEnv();
		return procGWorld();
	}

	// 変数・配列に値を設定する
	EasyClip setValue( String chr, dynamic value ){
		_setEnv();
		_param.setVal( MATH_CHAR( chr ), value, false );
		return this;
	}
	EasyClip setComplex( String chr, double real, double imag ){
		_setEnv();
		int index = MATH_CHAR( chr );
		_param.setReal( index, real, false );
		_param.setImag( index, imag, false );
		return this;
	}
	EasyClip setFract( String chr, int num, int denom ){
		_setEnv();
		int index = MATH_CHAR( chr );
		bool isMinus = ((num < 0) && (denom >= 0)) || ((num >= 0) && (denom < 0));
		_param.fractSetMinus( index, isMinus, false );
		_param.setNum       ( index, MATH_ABS( num  .toDouble() ), false );
		_param.setDenom     ( index, MATH_ABS( denom.toDouble() ), false );
		_param.fractReduce  ( index, false );
		return this;
	}
	EasyClip setMultiPrec( String chr, MPData n ){
		_setEnv();
		_param.array().mp(MATH_CHAR( chr )).attach( n.clone() );
		return this;
	}
	EasyClip setVector( String chr, List<dynamic> value ){
		_setEnv();
		_param.array().setVector( MATH_CHAR( chr ), value, value.length );
		return this;
	}
	EasyClip setComplexVector( String chr, List<double> real, List<double> imag ){
		_setEnv();
		_param.array().setComplexVector( MATH_CHAR( chr ), real, imag, (real.length < imag.length) ? real.length : imag.length );
		return this;
	}
	EasyClip setFractVector( chr, List<double> value, List<double> denom ){
		_setEnv();
		_param.array().setFractVector( MATH_CHAR( chr ), value, denom, (value.length < denom.length) ? value.length : denom.length );
		return this;
	}
	EasyClip setMatrix( String chr, dynamic value ){
		_setEnv();
		if( value is! MathMatrix ){
			value = arrayToMatrix( value );
		}
		_param.array().setMatrix( MATH_CHAR( chr ), value, false );
		return this;
	}
	EasyClip setComplexMatrix( String chr, List<List<double>> real, List<List<double>> imag ){
		_setEnv();
		_param.array().setComplexMatrix( MATH_CHAR( chr ), arrayToMatrix( real ), arrayToMatrix( imag ), false );
		return this;
	}
	EasyClip setFractMatrix( String chr, List<List<double>> value, List<List<double>> denom ){
		_setEnv();
		_param.array().setFractMatrix( MATH_CHAR( chr ), arrayToMatrix( value ), arrayToMatrix( denom ), false );
		return this;
	}
	EasyClip setArrayValue( String chr, dynamic subIndex, dynamic value ){
		_setEnv();
		for( int i = 0; i < subIndex.length; i++ ){
			subIndex[i] -= _param.base();
		}
		subIndex.add( -1 );
		_param.array().set( MATH_CHAR( chr ), subIndex, subIndex.length - 1, value, false );
		return this;
	}
	EasyClip setArrayComplex( String chr, dynamic subIndex, double real, double imag ){
		_setEnv();
		MathValue value = MathValue();
		value.setReal( real );
		value.setImag( imag );
		setArrayValue( chr, subIndex, value );
		return this;
	}
	EasyClip setArrayFract( String chr, dynamic subIndex, double num, double denom ){
		_setEnv();
		MathValue value = MathValue();
		bool isMinus = ((num < 0) && (denom >= 0)) || ((num >= 0) && (denom < 0));
		value.fractSetMinus( isMinus );
		value.setNum  ( MATH_ABS( num   ) );
		value.setDenom( MATH_ABS( denom ) );
		value.fractReduce();
		_param.fractReduce( MATH_CHAR( chr ), false );
		setArrayValue( chr, subIndex, value );
		return this;
	}
	EasyClip setString( String chr, String string ){
		_setEnv();
		_proc.strSet( _param.array(), MATH_CHAR( chr ), string );
		return this;
	}

	// 変数・配列の値を確認する
	MathValue getAnsValue(){
		_setEnv();
		return _param.val( 0 );
	}
	MPData getAnsMultiPrec(){
		_setEnv();
		return _param.array().mp(0);
	}
	MathMatrix getAnsMatrix(){
		_setEnv();
		return _param.array().matrix(0);
	}
	String getAnsMatrixString( int indent ){
		_setEnv();
		return getArrayTokenString( _param, _param.array().makeToken( ClipToken(), 0 ), indent );
	}
	String getAnsMultiPrecString(){
		MPData array = getAnsMultiPrec();
		MultiPrec mp = procMultiPrec();
		if( mp.getPrec( array ) == 0 ){
			return mp.num2str( array );
		}
		return mp.fnum2str( array, _param.mpPrec() );
	}
	MathValue getValue( String chr ){
		_setEnv();
		return _param.val( MATH_CHAR( chr ) );
	}
	MPData getMultiPrec( String chr ){
		_setEnv();
		return _param.array().mp(MATH_CHAR( chr ));
	}
	String getComplexString( String chr ){
		String string = "";
		MathValue value = getValue( chr );
		if( MATH_ISZERO( value.imag() ) ){
			string = "${value.real()}";
		} else if( MATH_ISZERO( value.real() ) ){
			string = "${value.imag()}i";
		} else if( value.imag() > 0.0 ){
			string = "${value.real()}+${value.imag()}i";
		} else {
			string = "${value.real()}${value.imag()}i";
		}
		return string;
	}
	String getFractString( String chr, bool mixed ){
		String string = "";
		MathValue value = getValue( chr );
		if( mixed && (value.denom() != 0) && (MATH_DIV( value.num(), value.denom() ) != 0) ){
			if( MATH_MOD( value.num(), value.denom() ) != 0 ){
				string = value.fractMinus() ? "-" : "";
				string += "${MATH_DIV( value.num(), value.denom() ).toInt()}";
				string += "$CLIP_CHAR_FRACT${MATH_MOD( value.num(), value.denom() ).toInt()}";
				string += "$CLIP_CHAR_FRACT${value.denom().toInt()}";
			} else {
				string = value.fractMinus() ? "-" : "";
				string += "${MATH_DIV( value.num(), value.denom() ).toInt()}";
			}
		} else {
			if( value.denom() == 0 ){
				string = "${value.toFloat()}";
			} else if( value.denom() == 1 ){
				string = value.fractMinus() ? "-" : "";
				string += "${value.num().toInt()}";
			} else {
				string = value.fractMinus() ? "-" : "";
				string += "${value.num().toInt()}$CLIP_CHAR_FRACT${value.denom().toInt()}";
			}
		}
		return string;
	}
	String getMultiPrecString( String chr ){
		MPData array = getMultiPrec( chr );
		MultiPrec mp = procMultiPrec();
		if( mp.getPrec( array ) == 0 ){
			return mp.num2str( array );
		}
		return mp.fnum2str( array, _param.mpPrec() );
	}
	getArray( String chr, [int? dim] ){
		_setEnv();

		List<dynamic> _array = [];
		int _dim = -1;
		List<int> _index = [];

		int code;
		dynamic token;

		int i;
		ClipToken array = _param.array().makeToken( ClipToken(), MATH_CHAR( chr ) );
		array.beginGetToken();
		while( array.getToken() ){
			code  = getCode();
			token = getToken();
			if( code == CLIP_CODE_ARRAY_TOP ){
				_dim++;
				if( _index.length <= _dim ){
					_index.add( 0 );
				}
			} else if( code == CLIP_CODE_ARRAY_END ){
				_index[_dim] = 0;
				_dim--;
				if( _dim >= 0 ) {
					_index[_dim]++;
				}
			} else if( code == CLIP_CODE_CONSTANT ){
				if( (dim == null) || (dim == _dim + 1) ){
					if( _dim > 0 ){
						if( _array.length <= _index[0] ){
							for( i = _array.length; i <= _index[0]; i++ ) {
								_array.add( [] );
							}
						}
						if( _array[_index[0]] is! List ){
							_array[_index[0]] = [];
						}
					}
					if( _dim > 1 ){
						if( _array[_index[0]].length <= _index[1] ){
							for( i = _array[_index[0]].length; i <= _index[1]; i++ ) {
								_array[_index[0]].add( [] );
							}
						}
						if( _array[_index[0]][_index[1]] is! List ){
							_array[_index[0]][_index[1]] = [];
						}
					}
					if( _dim > 2 ){
						if( _array[_index[0]][_index[1]].length <= _index[2] ){
							for( i = _array[_index[0]][_index[1]].length; i <= _index[2]; i++ ) {
								_array[_index[0]][_index[1]].add( [] );
							}
						}
						if( _array[_index[0]][_index[1]][_index[2]] is! List ){
							_array[_index[0]][_index[1]][_index[2]] = [];
						}
					}
					switch( _dim ){
						case 0:
							if( _array.length <= _index[0] ){
								for( i = _array.length; i <= _index[0]; i++ ) {
									_array.add( 0.0 );
								}
							}
							if( _array[_index[0]] is! List ){
								_array[_index[0]] = token.toFloat();
							}
							break;
						case 1:
							if( _array[_index[0]].length <= _index[1] ){
								for( i = _array[_index[0]].length; i <= _index[1]; i++ ) {
									_array[_index[0]].add( 0.0 );
								}
							}
							if( _array[_index[0]][_index[1]] is! List ){
								_array[_index[0]][_index[1]] = token.toFloat();
							}
							break;
						case 2:
							if( _array[_index[0]][_index[1]].length <= _index[2] ){
								for( i = _array[_index[0]][_index[1]].length; i <= _index[2]; i++ ) {
									_array[_index[0]][_index[1]].add( 0.0 );
								}
							}
							if( _array[_index[0]][_index[1]][_index[2]] is! List ){
								_array[_index[0]][_index[1]][_index[2]] = token.toFloat();
							}
							break;
						case 3:
							if( _array[_index[0]][_index[1]][_index[2]].length <= _index[3] ){
								for( i = _array[_index[0]][_index[1]][_index[2]].length; i <= _index[3]; i++ ) {
									_array[_index[0]][_index[1]][_index[2]].add( 0.0 );
								}
							}
							if( _array[_index[0]][_index[1]][_index[2]][_index[3]] is! List ){
								_array[_index[0]][_index[1]][_index[2]][_index[3]] = token.toFloat();
							}
							break;
					}
				}
				_index[_dim]++;
			}
		}

		return _array;
	}
	String getArrayTokenString( ClipParam param, ClipToken array, int indent ){
		_setEnv();

		int i;
		int code;
		dynamic token;
		String string = "";
		bool enter = false;

		array.beginGetToken();
		while( array.getToken() ){
			code  = getCode();
			token = getToken();
			if( enter ){
				if( code == CLIP_CODE_ARRAY_TOP ){
					string += arrayTokenStringBreak;
					for( i = 0; i < indent; i++ ){
						string += arrayTokenStringSpace;
					}
				}
				enter = false;
			}
			string += procToken().tokenString( param, code, token );
			string += arrayTokenStringSpace;
			if( code == CLIP_CODE_ARRAY_TOP ){
				indent += 2;
			}
			if( code == CLIP_CODE_ARRAY_END ){
				indent -= 2;
				enter = true;
			}
		}

		return string;
	}
	String getArrayString( String chr, int indent ){
		_setEnv();
		return getArrayTokenString( _param, _param.array().makeToken( ClipToken(), MATH_CHAR( chr ) ), indent );
	}
	String getString( String chr ){
		_setEnv();
		return _proc.strGet( _param.array(), MATH_CHAR( chr ) );
	}

	// 各種設定
	EasyClip setMode( int mode, [dynamic param1, dynamic param2] ){
		_setEnv();
		_param.setMode( mode );
		if( (mode & CLIP_MODE_MULTIPREC) != 0 ){
			if( param1 != null ){
				if( param2 != null ){
					_param.mpSetPrec( param1 );
					param1 = param2;
				}
				if( param1 is String ){
					_param.mpSetRoundStr( param1 );
				} else {
					_param.mpSetPrec( param1 );
				}
			}
		} else if( ((mode & CLIP_MODE_FLOAT) != 0) || ((mode & CLIP_MODE_COMPLEX) != 0) ){
			if( param1 != null ){
				_param.setPrec( param1 );
			}
		} else if( (mode & CLIP_MODE_TIME) != 0 ){
			if( param1 != null ){
				_param.setFps( param1 );
			}
		} else if( (mode & CLIP_MODE_INT) != 0 ){
			if( param1 != null ){
				_param.setRadix( param1 );
			}
		}
		return this;
	}
	EasyClip setPrec( int prec ){
		_setEnv();
		_param.setPrec( prec );
		return this;
	}
	EasyClip setFps( double fps ){
		_setEnv();
		_param.setFps( fps );
		return this;
	}
	EasyClip setRadix( int radix ){
		_setEnv();
		_param.setRadix( radix );
		return this;
	}
	EasyClip setAngType( int type ){
		_setEnv();
		_proc.setAngType( type, false );
		return this;
	}
	EasyClip setCalculator( bool flag ){
		_setEnv();
		_param.setCalculator( flag );
		return this;
	}
	EasyClip setBase( int base ){
		_setEnv();
		_param.setBase( (base != 0) ? 1 : 0 );
		return this;
	}
	EasyClip setAnsFlag( bool flag ){
		_setEnv();
		_proc.setAnsFlag( flag );
		return this;
	}
	EasyClip setAssertFlag( int flag ){
		_setEnv();
		_proc.setAssertFlag( flag );
		return this;
	}
	EasyClip setWarnFlag( int flag ){
		_setEnv();
		_proc.setWarnFlag( flag );
		return this;
	}

	// コマンド
	EasyClip commandGWorld( int width, int height ){
		_setEnv();
		doCommandGWorld( width, height );
		procGWorld().create( width, height, true, false );
		return this;
	}
	EasyClip commandGWorld24( int width, int height ){
		_setEnv();
		doCommandGWorld24( width, height );
		procGWorld().create( width, height, true, true );
		return this;
	}
	EasyClip commandWindow( double left, double bottom, double right, double top ){
		_setEnv();
		doCommandWindow( left, bottom, right, top );
		procGWorld().setWindowIndirect( left, bottom, right, top );
		return this;
	}
	EasyClip commandGClear( int index ){
		_setEnv();
		procGWorld().clear( index );
		return this;
	}
	EasyClip commandGColor( int index ){
		_setEnv();
		procGWorld().setColor( index );
		return this;
	}
	EasyClip commandGPut( List<List<int>> array ){
		_setEnv();
		ClipGWorld gWorld = procGWorld();
		int x, y;
		for( y = 0; y < gWorld.height(); y++ ){
			for( x = 0; x < gWorld.width(); x++ ){
				gWorld.putColor(
						x, y,
						(y < array.length) ? ((x < array[y].length) ? array[y][x] : 0) : 0
				);
			}
		}
		return this;
	}
	EasyClip commandGPut24( List<List<int>> array ){
		_setEnv();
		ClipGWorld gWorld = procGWorld();
		int x, y;
		doCommandGPut24Begin();
		for( y = 0; y < gWorld.height(); y++ ){
			for( x = 0; x < gWorld.width(); x++ ){
				doCommandGPut24(
						x, y,
						(y < array.length) ? ((x < array[y].length) ? array[y][x] : 0) : 0
				);
			}
		}
		doCommandGPut24End();
		return this;
	}
	List<List<int>>? commandGGet(){
		_setEnv();
		ClipGWorld gWorld = procGWorld();
		int width  = gWorld.width();
		int height = gWorld.height();
		if( (width > 0) && (height > 0) ){
			int x, y;
			List<List<int>> array = List.filled( height, [] );
			for( y = 0; y < height; y++ ){
				array[y] = List.filled( width, 0 );
				for( x = 0; x < width; x++ ){
					array[y][x] = gWorld.get( x, y );
				}
			}
			return array;
		}
		return null;
	}
	List<List<int>>? commandGGet24(){
		_setEnv();
		ParamInteger w = ParamInteger();
		ParamInteger h = ParamInteger();
		List<int>? data = doCommandGGet24Begin( w, h );
		if( data != null ){
			int width  = w.val();
			int height = h.val();
			if( (width > 0) && (height > 0) ){
				int x, y, r, g, b;
				int i = 0;
				List<List<int>> array = List.filled( height, [] );
				for( y = 0; y < height; y++ ){
					array[y] = List.filled( width, 0 );
					for( x = 0; x < width; x++ ){
						r = data[i++];
						g = data[i++];
						b = data[i++];
						i++;
						array[y][x] = (r << 16) + (g << 8) + b;
					}
				}
				doCommandGGet24End();
				return array;
			}
		}
		return null;
	}

	// 計算
	int procLine( String line ){
		_setEnv();
		initProcLoopCount();
		return _proc.processLoop( line, _param );
	}
	int procScript( List<String> script ){
		_setEnv();
		List<String>? Function( String ) saveFunc = getExtFuncDataDirect;
		getExtFuncDataDirect = ( func ){
			return script;
		};
		initProcLoopCount();
		int ret = _proc.mainLoop( "", _param, null, null );
		getExtFuncDataDirect = saveFunc;
		return ret;
	}

	// カラー・パレット
	EasyClip newPalette(){
		_palette ??= List.filled( 256, 0 );
		return this;
	}
	EasyClip setPalette( List<int> bgrColorArray ){
		newPalette();
		for( int i = 0; i < 256; i++ ){
			_palette![i] = bgrColorArray[i];
		}
		return this;
	}
	EasyClip setPaletteColor( int index, int bgrColor ){
		_palette![index] = bgrColor;
		return this;
	}
	int paletteColor( int index ){
		return _palette![index];
	}

	// キャンバス
	void _useCanvas(){
		_canvasEnv ??= CanvasEnv();
		setCanvasEnv( _canvasEnv! );
	}
	Canvas createCanvas( int width, int height ){
		_useCanvas();
		_canvas = Canvas( width, height );
		return _canvas!;
	}
	Canvas resizeCanvas( int width, int height ){
		setCanvasEnv( _canvasEnv! );
		_canvas!.setSize( width, height );
		return _canvas!;
	}
	Canvas updateCanvas( [double scale = 1.0] ){
		_setEnv();

		_canvas!.setColorRGB( gWorldBgColor() );
		_canvas!.fill( 0, 0, _canvas!.width().toDouble(), _canvas!.height().toDouble() );

		ClipGWorld gWorld = procGWorld();
		List<int> image  = gWorld.image();
		int offset = gWorld.offset();
		int width  = gWorld.width();
		int height = gWorld.height();
		int x, y, yy;
		double sy;
		for( y = 0; y < height; y++ ){
			yy = y * offset;
			sy = y * scale;
			for( x = 0; x < width; x++ ){
				_canvas!.setColorBGR( gWorld.rgbFlag() ? CLIP_RGB2BGR( image[yy + x] ) : _palette![image[yy + x]] );
				_canvas!.fill( x * scale, sy, scale + 0.2, scale + 0.2 );
			}
		}

		return _canvas!;
	}
}
