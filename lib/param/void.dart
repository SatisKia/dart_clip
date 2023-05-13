/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

// 汎用オブジェクトの受け渡し用
class ParamVoid {
	Object? _obj;

	ParamVoid( [Object? obj] ){
		_obj = obj;
	}

	ParamVoid set( obj ){
		_obj = obj;
		return this;
	}
	Object obj(){
		return _obj!;
	}

	static List newArray( int len ){
		List<ParamVoid> a = List.filled( len, ParamVoid() );
		for( int i = 0; i < len; i++ ){
			a[i] = ParamVoid();
		}
		return a;
	}
}
