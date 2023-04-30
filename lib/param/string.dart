/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

// 文字列の受け渡し用
class ParamString {
	String? _str;

	ParamString( [String? str] ){
		_str = str;
	}

	ParamString set( [String? str] ){
		_str = str;
		return this;
	}
	ParamString add( [String? str] ){
		if( str != null ){
			if( _str == null ){
				set( str );
			} else {
				_str = ((_str == null) ? "" : _str!) + str;
			}
		}
		return this;
	}
	String str(){
		return (_str == null) ? "" : _str!;
	}
	bool isNull(){
		return (_str == null);
	}
	ParamString replace( String word, String replacement ){
		int end = word.length;
		if( end > 0 ){
			int top = 0;
			while( top < str().length ){
				if( str().substring( top, end ) == word ){
					String forward = (top > 0) ? str().substring( 0, top ) : "";
					String after   = (end < str().length) ? str().substring( end ) : "";
					set( forward + replacement + after );
					top += replacement.length;
					end += replacement.length;
				} else {
					top++;
					end++;
				}
			}
		}
		return this;
	}
	ParamString replaceMulti( String word, String replacement ){
		while( true ){
			String tmp = str();
			replace( word, replacement );
			if( tmp == str() ){
				break;
			}
		}
		return this;
	}
	ParamString replaceNewLine( [String? replacement] ){
		replace( "\r\n", "\n" );
		replace( "\r"  , "\n" );
		if( replacement != null ){
			replace( "\n", replacement );
		}
		return this;
	}
	ParamString escape(){
		replace( "&" , "&amp;"  );	// 重要：一番最初に行うこと！
		replace( "<" , "&lt;"   );
		replace( ">" , "&gt;"   );
		replace( "\"", "&quot;" );
		replace( " " , "&nbsp;" );
		return this;
	}
	ParamString unescape(){
		replace( "&lt;"  , "<"  );
		replace( "&gt;"  , ">"  );
		replace( "&quot;", "\"" );
		replace( "&nbsp;", " "  );
		replace( "&amp;" , "&"  );	// 重要：一番最後に行うこと！
		return this;
	}
}

List newStringArray( int len ){
	List<ParamString> a = List.filled( len, ParamString() );
	for( int i = 0; i < len; i++ ){
		a[i] = ParamString();
	}
	return a;
}
