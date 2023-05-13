/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

// 浮動小数点数値の受け渡し用
class ParamFloat {
	late double _val;

	ParamFloat( [double val = 0.0] ){
		_val = val;
	}

	ParamFloat set( double val ){
		_val = val;
		return this;
	}
	ParamFloat add( double val ){
		_val += val;
		return this;
	}
	double val(){
		return _val;
	}

	static List newArray( int len ){
		List<ParamFloat> a = List.filled( len, ParamFloat() );
		for( int i = 0; i < len; i++ ){
			a[i] = ParamFloat();
		}
		return a;
	}
}
