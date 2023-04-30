/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

// ブール値の受け渡し用
class ParamBoolean {
	late bool _val;

	ParamBoolean( [bool val = false] ){
		_val = (val == true);
	}

	ParamBoolean set( bool val ){
		_val = (val == true);
		return this;
	}
	bool val(){
		return _val;
	}
}

List newBooleanArray( int len ){
	List<ParamBoolean> a = List.filled( len, ParamBoolean() );
	for( int i = 0; i < len; i++ ){
		a[i] = ParamBoolean();
	}
	return a;
}
