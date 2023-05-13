/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

// 整数値の受け渡し用
class ParamInteger {
	late int _val;

	ParamInteger( [int val = 0] ){
		_val = val;
	}

	ParamInteger set( int val ){
		_val = val;
		return this;
	}
	ParamInteger add( int val ){
		_val += val;
		return this;
	}
	int val(){
		return _val;
	}

	static List newArray( int len ){
		List<ParamInteger> a = List.filled( len, ParamInteger() );
		for( int i = 0; i < len; i++ ){
			a[i] = ParamInteger();
		}
		return a;
	}
}
