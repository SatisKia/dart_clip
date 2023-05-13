/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import '../param/float.dart';
import '../param/integer.dart';
import 'complex.dart';
import 'fract.dart';
import 'math.dart';
import 'time.dart';

// 基本型
class MathValue {
	late int _type;
	late MathComplex _c;
	late MathFract _f;
	late MathTime _t;

	MathValue(){
		_type = ClipMath.valueType(); // 型（ローカル）
		_c = MathComplex(); // 複素数型
		_f = MathFract(); // 分数型
		_t = MathTime(); // 時間型
	}

	int type(){
		if( ClipMath.valueType() != _type ){
			switch( ClipMath.valueType() ){
			case ClipMath.valueTypeComplex:
				switch( _type ){
				case ClipMath.valueTypeFract: _c.ass( _f.toFloat() ); break;
				case ClipMath.valueTypeTime : _c.ass( _t.toFloat() ); break;
				}
				break;
			case ClipMath.valueTypeFract:
				switch( _type ){
				case ClipMath.valueTypeComplex: _f.ass( _c.toFloat() ); break;
				case ClipMath.valueTypeTime   : _f.ass( _t.toFloat() ); break;
				}
				break;
			case ClipMath.valueTypeTime:
				switch( _type ){
				case ClipMath.valueTypeComplex: _t.ass( _c.toFloat() ); break;
				case ClipMath.valueTypeFract  : _t.ass( _f.toFloat() ); break;
				}
				break;
			}
			_type = ClipMath.valueType();
		}
		return _type;
	}

	void angToAng( int oldType, int newType ){
		_complex().angToAng( oldType, newType );
	}

	MathComplex _complex(){
		switch( _type ){
		case ClipMath.valueTypeFract: _c.ass( _f.toFloat() ); _type = ClipMath.valueTypeComplex; break;
		case ClipMath.valueTypeTime : _c.ass( _t.toFloat() ); _type = ClipMath.valueTypeComplex; break;
		}
		return _c;
	}
	MathComplex _tmpComplex(){
		if( _type == ClipMath.valueTypeFract ) return MathComplex.floatToComplex( _f.toFloat() );
		if( _type == ClipMath.valueTypeTime  ) return MathComplex.floatToComplex( _t.toFloat() );
		return _c;
	}
	MathFract _fract(){
		switch( _type ){
		case ClipMath.valueTypeComplex: _f.ass( _c.toFloat() ); _type = ClipMath.valueTypeFract; break;
		case ClipMath.valueTypeTime   : _f.ass( _t.toFloat() ); _type = ClipMath.valueTypeFract; break;
		}
		return _f;
	}
	MathFract _tmpFract(){
		if( _type == ClipMath.valueTypeComplex ) return MathFract.floatToFract( _c.toFloat() );
		if( _type == ClipMath.valueTypeTime    ) return MathFract.floatToFract( _t.toFloat() );
		return _f;
	}
	MathTime _time(){
		switch( _type ){
		case ClipMath.valueTypeComplex: _t.ass( _c.toFloat() ); _type = ClipMath.valueTypeTime; break;
		case ClipMath.valueTypeFract  : _t.ass( _f.toFloat() ); _type = ClipMath.valueTypeTime; break;
		}
		return _t;
	}
	MathTime _tmpTime(){
		if( _type == ClipMath.valueTypeComplex ) return MathTime.floatToTime( _c.toFloat() );
		if( _type == ClipMath.valueTypeFract   ) return MathTime.floatToTime( _f.toFloat() );
		return _t;
	}

	MathValue setFloat( double x ){
		switch( _type ){
		case ClipMath.valueTypeComplex: _c.ass( x ); break;
		case ClipMath.valueTypeFract  : _f.ass( x ); break;
		case ClipMath.valueTypeTime   : _t.ass( x ); break;
		}
		return this;
	}
	MathValue setComplex( MathComplex x ){
		switch( _type ){
		case ClipMath.valueTypeComplex: _c.ass( x           ); break;
		case ClipMath.valueTypeFract  : _f.ass( x.toFloat() ); break;
		case ClipMath.valueTypeTime   : _t.ass( x.toFloat() ); break;
		}
		return this;
	}
	MathValue setFract( MathFract x ){
		switch( _type ){
		case ClipMath.valueTypeComplex: _c.ass( x.toFloat() ); break;
		case ClipMath.valueTypeFract  : _f.ass( x           ); break;
		case ClipMath.valueTypeTime   : _t.ass( x.toFloat() ); break;
		}
		return this;
	}
	MathValue setTime( MathTime x ){
		switch( _type ){
		case ClipMath.valueTypeComplex: _c.ass( x.toFloat() ); break;
		case ClipMath.valueTypeFract  : _f.ass( x.toFloat() ); break;
		case ClipMath.valueTypeTime   : _t.ass( x           ); break;
		}
		return this;
	}

	// 設定
	void setReal( double re ){
		_complex().setReal( re );
	}
	void setImag( double im ){
		_complex().setImag( im );
	}
	void polar( double rho, double theta ){
		_complex().polar( rho, theta );
	}
	void fractSetMinus( bool mi ){
		_fract().setMinus( mi );
	}
	void setNum( double nu ){
		_fract().setNum( nu );
	}
	void setDenom( double de ){
		_fract().setDenom( de );
	}
	void fractReduce(){
		_fract().reduce();
	}
	void timeSetMinus( bool i ){
		_time().setMinus( i );
	}
	void setHour( double h ){
		_time().setHour( h );
	}
	void setMin( double m ){
		_time().setMin( m );
	}
	void setSec( double s ){
		_time().setSec( s );
	}
	void setFrame( double f ){
		_time().setFrame( f );
	}
	void timeReduce(){
		_time().reduce();
	}

	// 確認
	double real(){
		return _tmpComplex().real();
	}
	double imag(){
		return _tmpComplex().imag();
	}
	bool fractMinus(){
		return _tmpFract().getMinus();
	}
	double num(){
		return _tmpFract().num();
	}
	double denom(){
		return _tmpFract().denom();
	}
	bool timeMinus(){
		return _tmpTime().getMinus();
	}
	double hour(){
		return _tmpTime().calcHour();
	}
	double min(){
		return _tmpTime().calcMin();
	}
	double sec(){
		return _tmpTime().calcSec();
	}
	double frame(){
		return _tmpTime().frame();
	}

	// 型変換
	double toFloat(){
		if( _type == ClipMath.valueTypeComplex ) return _c.toFloat();
		if( _type == ClipMath.valueTypeFract   ) return _f.toFloat();
		return _t.toFloat();
	}

	// 代入
	MathValue ass( dynamic r ){
		if( r is MathValue ){
			_type = r._type; // 代入の場合は左辺値の変換は不要なのでtype関数は使わない
			switch( _type ){
			case ClipMath.valueTypeComplex: _c.ass( r._c ); break;
			case ClipMath.valueTypeFract  : _f.ass( r._f ); break;
			case ClipMath.valueTypeTime   : _t.ass( r._t ); break;
			}
		} else {
			_type = ClipMath.valueType(); // 代入の場合は左辺値の変換は不要なのでtype関数は使わない
			switch( _type ){
			case ClipMath.valueTypeComplex: _c.ass( ClipMath.toDouble(r) ); break;
			case ClipMath.valueTypeFract  : _f.ass( ClipMath.toDouble(r) ); break;
			case ClipMath.valueTypeTime   : _t.ass( ClipMath.toDouble(r) ); break;
			}
		}
		return this;
	}

	// 単項マイナス
	MathValue minus(){
		type();
		if( _type == ClipMath.valueTypeComplex ) return complexToValue( _c.minus() );
		if( _type == ClipMath.valueTypeFract   ) return fractToValue  ( _f.minus() );
		return timeToValue( _t.minus() );
	}

	// 加算
	MathValue add( r ){
		type();
		if( r is MathValue ){
			if( r._type == ClipMath.valueTypeComplex ){
				if( _type == ClipMath.valueTypeComplex ) return complexToValue( _c.add( r._c           ) );
				if( _type == ClipMath.valueTypeFract   ) return fractToValue  ( _f.add( r._c.toFloat() ) );
				return timeToValue( _t.add( r._c.toFloat() ) );
			}
			if( r._type == ClipMath.valueTypeFract ){
				if( _type == ClipMath.valueTypeComplex ) return complexToValue( _c.add( r._f.toFloat() ) );
				if( _type == ClipMath.valueTypeFract   ) return fractToValue  ( _f.add( r._f           ) );
				return timeToValue( _t.add( r._f.toFloat() ) );
			}
			if( _type == ClipMath.valueTypeComplex ) return complexToValue( _c.add( r._t.toFloat() ) );
			if( _type == ClipMath.valueTypeFract   ) return fractToValue  ( _f.add( r._t.toFloat() ) );
			return timeToValue( _t.add( r._t ) );
		}
		if( _type == ClipMath.valueTypeComplex ) return complexToValue( _c.add( ClipMath.toDouble(r) ) );
		if( _type == ClipMath.valueTypeFract   ) return fractToValue  ( _f.add( ClipMath.toDouble(r) ) );
		return timeToValue( _t.add( ClipMath.toDouble(r) ) );
	}
	MathValue addAndAss( r ){
		if( r is MathValue ){
			switch( r._type ){
			case ClipMath.valueTypeComplex:
				switch( type() ){
				case ClipMath.valueTypeComplex: _c.addAndAss( r._c           ); break;
				case ClipMath.valueTypeFract  : _f.addAndAss( r._c.toFloat() ); break;
				case ClipMath.valueTypeTime   : _t.addAndAss( r._c.toFloat() ); break;
				}
				break;
			case ClipMath.valueTypeFract:
				switch( type() ){
				case ClipMath.valueTypeComplex: _c.addAndAss( r._f.toFloat() ); break;
				case ClipMath.valueTypeFract  : _f.addAndAss( r._f           ); break;
				case ClipMath.valueTypeTime   : _t.addAndAss( r._f.toFloat() ); break;
				}
				break;
			case ClipMath.valueTypeTime:
				switch( type() ){
				case ClipMath.valueTypeComplex: _c.addAndAss( r._t.toFloat() ); break;
				case ClipMath.valueTypeFract  : _f.addAndAss( r._t.toFloat() ); break;
				case ClipMath.valueTypeTime   : _t.addAndAss( r._t           ); break;
				}
				break;
			}
		} else {
			switch( type() ){
			case ClipMath.valueTypeComplex: _c.addAndAss( ClipMath.toDouble(r) ); break;
			case ClipMath.valueTypeFract  : _f.addAndAss( ClipMath.toDouble(r) ); break;
			case ClipMath.valueTypeTime   : _t.addAndAss( ClipMath.toDouble(r) ); break;
			}
		}
		return this;
	}

	// 減算
	MathValue sub( r ){
		type();
		if( r is MathValue ){
			if( r._type == ClipMath.valueTypeComplex ){
				if( _type == ClipMath.valueTypeComplex ) return complexToValue( _c.sub( r._c           ) );
				if( _type == ClipMath.valueTypeFract   ) return fractToValue  ( _f.sub( r._c.toFloat() ) );
				return timeToValue( _t.sub( r._c.toFloat() ) );
			}
			if( r._type == ClipMath.valueTypeFract ){
				if( _type == ClipMath.valueTypeComplex ) return complexToValue( _c.sub( r._f.toFloat() ) );
				if( _type == ClipMath.valueTypeFract   ) return fractToValue  ( _f.sub( r._f           ) );
				return timeToValue( _t.sub( r._f.toFloat() ) );
			}
			if( _type == ClipMath.valueTypeComplex ) return complexToValue( _c.sub( r._t.toFloat() ) );
			if( _type == ClipMath.valueTypeFract   ) return fractToValue  ( _f.sub( r._t.toFloat() ) );
			return timeToValue( _t.sub( r._t ) );
		}
		if( _type == ClipMath.valueTypeComplex ) return complexToValue( _c.sub( ClipMath.toDouble(r) ) );
		if( _type == ClipMath.valueTypeFract   ) return fractToValue  ( _f.sub( ClipMath.toDouble(r) ) );
		return timeToValue( _t.sub( ClipMath.toDouble(r) ) );
	}
	MathValue subAndAss( r ){
		if( r is MathValue ){
			switch( r._type ){
			case ClipMath.valueTypeComplex:
				switch( type() ){
				case ClipMath.valueTypeComplex: _c.subAndAss( r._c           ); break;
				case ClipMath.valueTypeFract  : _f.subAndAss( r._c.toFloat() ); break;
				case ClipMath.valueTypeTime   : _t.subAndAss( r._c.toFloat() ); break;
				}
				break;
			case ClipMath.valueTypeFract:
				switch( type() ){
				case ClipMath.valueTypeComplex: _c.subAndAss( r._f.toFloat() ); break;
				case ClipMath.valueTypeFract  : _f.subAndAss( r._f           ); break;
				case ClipMath.valueTypeTime   : _t.subAndAss( r._f.toFloat() ); break;
				}
				break;
			case ClipMath.valueTypeTime:
				switch( type() ){
				case ClipMath.valueTypeComplex: _c.subAndAss( r._t.toFloat() ); break;
				case ClipMath.valueTypeFract  : _f.subAndAss( r._t.toFloat() ); break;
				case ClipMath.valueTypeTime   : _t.subAndAss( r._t           ); break;
				}
				break;
			}
		} else {
			switch( type() ){
			case ClipMath.valueTypeComplex: _c.subAndAss( ClipMath.toDouble(r) ); break;
			case ClipMath.valueTypeFract  : _f.subAndAss( ClipMath.toDouble(r) ); break;
			case ClipMath.valueTypeTime   : _t.subAndAss( ClipMath.toDouble(r) ); break;
			}
		}
		return this;
	}

	// 乗算
	MathValue mul( r ){
		type();
		if( r is MathValue ){
			if( r._type == ClipMath.valueTypeComplex ){
				if( _type == ClipMath.valueTypeComplex ) return complexToValue( _c.mul( r._c           ) );
				if( _type == ClipMath.valueTypeFract   ) return fractToValue  ( _f.mul( r._c.toFloat() ) );
				return timeToValue( _t.mul( r._c.toFloat() ) );
			}
			if( r._type == ClipMath.valueTypeFract ){
				if( _type == ClipMath.valueTypeComplex ) return complexToValue( _c.mul( r._f.toFloat() ) );
				if( _type == ClipMath.valueTypeFract   ) return fractToValue  ( _f.mul( r._f           ) );
				return timeToValue( _t.mul( r._f.toFloat() ) );
			}
			if( _type == ClipMath.valueTypeComplex ) return complexToValue( _c.mul( r._t.toFloat() ) );
			if( _type == ClipMath.valueTypeFract   ) return fractToValue  ( _f.mul( r._t.toFloat() ) );
			return timeToValue( _t.mul( r._t ) );
		}
		if( _type == ClipMath.valueTypeComplex ) return complexToValue( _c.mul( ClipMath.toDouble(r) ) );
		if( _type == ClipMath.valueTypeFract   ) return fractToValue  ( _f.mul( ClipMath.toDouble(r) ) );
		return timeToValue( _t.mul( ClipMath.toDouble(r) ) );
	}
	MathValue mulAndAss( r ){
		if( r is MathValue ){
			switch( r._type ){
			case ClipMath.valueTypeComplex:
				switch( type() ){
				case ClipMath.valueTypeComplex: _c.mulAndAss( r._c           ); break;
				case ClipMath.valueTypeFract  : _f.mulAndAss( r._c.toFloat() ); break;
				case ClipMath.valueTypeTime   : _t.mulAndAss( r._c.toFloat() ); break;
				}
				break;
			case ClipMath.valueTypeFract:
				switch( type() ){
				case ClipMath.valueTypeComplex: _c.mulAndAss( r._f.toFloat() ); break;
				case ClipMath.valueTypeFract  : _f.mulAndAss( r._f           ); break;
				case ClipMath.valueTypeTime   : _t.mulAndAss( r._f.toFloat() ); break;
				}
				break;
			case ClipMath.valueTypeTime:
				switch( type() ){
				case ClipMath.valueTypeComplex: _c.mulAndAss( r._t.toFloat() ); break;
				case ClipMath.valueTypeFract  : _f.mulAndAss( r._t.toFloat() ); break;
				case ClipMath.valueTypeTime   : _t.mulAndAss( r._t           ); break;
				}
				break;
			}
		} else {
			switch( type() ){
			case ClipMath.valueTypeComplex: _c.mulAndAss( ClipMath.toDouble(r) ); break;
			case ClipMath.valueTypeFract  : _f.mulAndAss( ClipMath.toDouble(r) ); break;
			case ClipMath.valueTypeTime   : _t.mulAndAss( ClipMath.toDouble(r) ); break;
			}
		}
		return this;
	}

	// 除算
	MathValue div( r ){
		type();
		if( r is MathValue ){
			if( r._type == ClipMath.valueTypeComplex ){
				if( _type == ClipMath.valueTypeComplex ) return complexToValue( _c.div( r._c           ) );
				if( _type == ClipMath.valueTypeFract   ) return fractToValue  ( _f.div( r._c.toFloat() ) );
				return timeToValue( _t.div( r._c.toFloat() ) );
			}
			if( r._type == ClipMath.valueTypeFract ){
				if( _type == ClipMath.valueTypeComplex ) return complexToValue( _c.div( r._f.toFloat() ) );
				if( _type == ClipMath.valueTypeFract   ) return fractToValue  ( _f.div( r._f           ) );
				return timeToValue( _t.div( r._f.toFloat() ) );
			}
			if( _type == ClipMath.valueTypeComplex ) return complexToValue( _c.div( r._t.toFloat() ) );
			if( _type == ClipMath.valueTypeFract   ) return fractToValue  ( _f.div( r._t.toFloat() ) );
			return timeToValue( _t.div( r._t ) );
		}
		if( _type == ClipMath.valueTypeComplex ) return complexToValue( _c.div( ClipMath.toDouble(r) ) );
		if( _type == ClipMath.valueTypeFract   ) return fractToValue  ( _f.div( ClipMath.toDouble(r) ) );
		return timeToValue( _t.div( ClipMath.toDouble(r) ) );
	}
	MathValue divAndAss( r ){
		if( r is MathValue ){
			switch( r._type ){
			case ClipMath.valueTypeComplex:
				switch( type() ){
				case ClipMath.valueTypeComplex: _c.divAndAss( r._c           ); break;
				case ClipMath.valueTypeFract  : _f.divAndAss( r._c.toFloat() ); break;
				case ClipMath.valueTypeTime   : _t.divAndAss( r._c.toFloat() ); break;
				}
				break;
			case ClipMath.valueTypeFract:
				switch( type() ){
				case ClipMath.valueTypeComplex: _c.divAndAss( r._f.toFloat() ); break;
				case ClipMath.valueTypeFract  : _f.divAndAss( r._f           ); break;
				case ClipMath.valueTypeTime   : _t.divAndAss( r._f.toFloat() ); break;
				}
				break;
			case ClipMath.valueTypeTime:
				switch( type() ){
				case ClipMath.valueTypeComplex: _c.divAndAss( r._t.toFloat() ); break;
				case ClipMath.valueTypeFract  : _f.divAndAss( r._t.toFloat() ); break;
				case ClipMath.valueTypeTime   : _t.divAndAss( r._t           ); break;
				}
				break;
			}
		} else {
			switch( type() ){
			case ClipMath.valueTypeComplex: _c.divAndAss( ClipMath.toDouble(r) ); break;
			case ClipMath.valueTypeFract  : _f.divAndAss( ClipMath.toDouble(r) ); break;
			case ClipMath.valueTypeTime   : _t.divAndAss( ClipMath.toDouble(r) ); break;
			}
		}
		return this;
	}

	// 剰余
	MathValue mod( r ){
		type();
		if( r is MathValue ){
			if( r._type == ClipMath.valueTypeComplex ){
				if( _type == ClipMath.valueTypeComplex ) return complexToValue( _c.mod( r._c           ) );
				if( _type == ClipMath.valueTypeFract   ) return fractToValue  ( _f.mod( r._c.toFloat() ) );
				return timeToValue( _t.mod( r._c.toFloat() ) );
			}
			if( r._type == ClipMath.valueTypeFract ){
				if( _type == ClipMath.valueTypeComplex ) return complexToValue( _c.mod( r._f.toFloat() ) );
				if( _type == ClipMath.valueTypeFract   ) return fractToValue  ( _f.mod( r._f           ) );
				return timeToValue( _t.mod( r._f.toFloat() ) );
			}
			if( _type == ClipMath.valueTypeComplex ) return complexToValue( _c.mod( r._t.toFloat() ) );
			if( _type == ClipMath.valueTypeFract   ) return fractToValue  ( _f.mod( r._t.toFloat() ) );
			return timeToValue( _t.mod( r._t ) );
		}
		if( _type == ClipMath.valueTypeComplex ) return complexToValue( _c.mod( ClipMath.toDouble(r) ) );
		if( _type == ClipMath.valueTypeFract   ) return fractToValue  ( _f.mod( ClipMath.toDouble(r) ) );
		return timeToValue( _t.mod( ClipMath.toDouble(r) ) );
	}
	MathValue modAndAss( r ){
		if( r is MathValue ){
			switch( r._type ){
			case ClipMath.valueTypeComplex:
				switch( type() ){
				case ClipMath.valueTypeComplex: _c.modAndAss( r._c           ); break;
				case ClipMath.valueTypeFract  : _f.modAndAss( r._c.toFloat() ); break;
				case ClipMath.valueTypeTime   : _t.modAndAss( r._c.toFloat() ); break;
				}
				break;
			case ClipMath.valueTypeFract:
				switch( type() ){
				case ClipMath.valueTypeComplex: _c.modAndAss( r._f.toFloat() ); break;
				case ClipMath.valueTypeFract  : _f.modAndAss( r._f           ); break;
				case ClipMath.valueTypeTime   : _t.modAndAss( r._f.toFloat() ); break;
				}
				break;
			case ClipMath.valueTypeTime:
				switch( type() ){
				case ClipMath.valueTypeComplex: _c.modAndAss( r._t.toFloat() ); break;
				case ClipMath.valueTypeFract  : _f.modAndAss( r._t.toFloat() ); break;
				case ClipMath.valueTypeTime   : _t.modAndAss( r._t           ); break;
				}
				break;
			}
		} else {
			switch( type() ){
			case ClipMath.valueTypeComplex: _c.modAndAss( ClipMath.toDouble(r) ); break;
			case ClipMath.valueTypeFract  : _f.modAndAss( ClipMath.toDouble(r) ); break;
			case ClipMath.valueTypeTime   : _t.modAndAss( ClipMath.toDouble(r) ); break;
			}
		}
		return this;
	}

	// 等値
	bool equal( r ){
		type();
		if( r is MathValue ){
			if( r._type == ClipMath.valueTypeComplex ){
				if( _type == ClipMath.valueTypeComplex ) return _c.equal( r._c           );
				if( _type == ClipMath.valueTypeFract   ) return _f.equal( r._c.toFloat() );
				return _t.equal( r._c.toFloat() );
			}
			if( r._type == ClipMath.valueTypeFract ){
				if( _type == ClipMath.valueTypeComplex ) return _c.equal( r._f.toFloat() );
				if( _type == ClipMath.valueTypeFract   ) return _f.equal( r._f           );
				return _t.equal( r._f.toFloat() );
			}
			if( _type == ClipMath.valueTypeComplex ) return _c.equal( r._t.toFloat() );
			if( _type == ClipMath.valueTypeFract   ) return _f.equal( r._t.toFloat() );
			return _t.equal( r._t );
		}
		if( _type == ClipMath.valueTypeComplex ) return _c.equal( ClipMath.toDouble(r) );
		if( _type == ClipMath.valueTypeFract   ) return _f.equal( ClipMath.toDouble(r) );
		return _t.equal( ClipMath.toDouble(r) );
	}
	bool notEqual( r ){
		type();
		if( r is MathValue ){
			if( r._type == ClipMath.valueTypeComplex ){
				if( _type == ClipMath.valueTypeComplex ) return _c.notEqual( r._c           );
				if( _type == ClipMath.valueTypeFract   ) return _f.notEqual( r._c.toFloat() );
				return _t.notEqual( r._c.toFloat() );
			}
			if( r._type == ClipMath.valueTypeFract ){
				if( _type == ClipMath.valueTypeComplex ) return _c.notEqual( r._f.toFloat() );
				if( _type == ClipMath.valueTypeFract   ) return _f.notEqual( r._f           );
				return _t.notEqual( r._f.toFloat() );
			}
			if( _type == ClipMath.valueTypeComplex ) return _c.notEqual( r._t.toFloat() );
			if( _type == ClipMath.valueTypeFract   ) return _f.notEqual( r._t.toFloat() );
			return _t.notEqual( r._t );
		}
		if( _type == ClipMath.valueTypeComplex ) return _c.notEqual( ClipMath.toDouble(r) );
		if( _type == ClipMath.valueTypeFract   ) return _f.notEqual( ClipMath.toDouble(r) );
		return _t.notEqual( ClipMath.toDouble(r) );
	}

	// 各種関数
	MathValue abs(){
		type();
		if( _type == ClipMath.valueTypeComplex ) return floatToValue( _c.fabs() );
		if( _type == ClipMath.valueTypeFract   ) return fractToValue( _f.abs () );
		return fractToValue( _tmpFract().abs() );
	}
	MathValue pow( y ){
		type();
		if( y is MathValue ){
			if( _type == ClipMath.valueTypeComplex ) return complexToValue( _c.pow( y._tmpComplex() ) );
			if( _type == ClipMath.valueTypeFract   ) return fractToValue  ( _f.pow( y._tmpFract  () ) );
			return fractToValue( _tmpFract().pow( y._tmpFract() ) );
		}
		double yy = y;
		if( _type == ClipMath.valueTypeComplex ) return complexToValue( _c.pow( yy ) );
		if( _type == ClipMath.valueTypeFract   ) return fractToValue  ( _f.pow( yy ) );
		return fractToValue( _tmpFract().pow( yy ) );
	}
	MathValue sqr(){
		type();
		if( _type == ClipMath.valueTypeComplex ) return complexToValue( _c.sqr() );
		if( _type == ClipMath.valueTypeFract   ) return fractToValue  ( _f.sqr() );
		return fractToValue( _tmpFract().sqr() );
	}
	MathValue ldexp( int exp ){ // load exponent
		double x = toFloat();
		double w = (exp >= 0) ? 2.0 : 0.5;
		if( exp < 0 ) exp = -exp;
		while( exp != 0 ){
			if( (exp & 1) != 0 ) x *= w;
			w *= w;
			exp = exp ~/ 2;
		}
		return floatToValue( x );
	}
	MathValue frexp( ParamInteger exp ){ // fraction and exponent
		double x = toFloat();
		bool m = (x < 0.0) ? true : false;
		if( m ) x = -x;
		int e = 0;
		if( x >= 1.0 ){
			while( x >= 1.0 ){
				x /= 2.0;
				e++;
			}
		} else if( x != 0.0 ){
			while( x < 0.5 ){
				x *= 2.0;
				e--;
			}
		}
		if( m ) x = -x;
		exp.set( e );
		return floatToValue( x );
	}
	MathValue modf( ParamFloat _int ){
		return floatToValue( ClipMath.modf( toFloat(), _int ) );
	}
	MathValue factorial(){
		return floatToValue( ClipMath.factorial( toFloat() ) );
	}
	double farg(){
		return _complex().farg();
	}
	double fnorm(){
		return _complex().fnorm();
	}
	MathValue conjg(){
		return complexToValue( _complex().conjg() );
	}
	MathValue sin(){
		return complexToValue( _complex().sin() );
	}
	MathValue cos(){
		return complexToValue( _complex().cos() );
	}
	MathValue tan(){
		return complexToValue( _complex().tan() );
	}
	MathValue asin(){
		return complexToValue( _complex().asin() );
	}
	MathValue acos(){
		return complexToValue( _complex().acos() );
	}
	MathValue atan(){
		return complexToValue( _complex().atan() );
	}
	MathValue sinh(){
		return complexToValue( _complex().sinh() );
	}
	MathValue cosh(){
		return complexToValue( _complex().cosh() );
	}
	MathValue tanh(){
		return complexToValue( _complex().tanh() );
	}
	MathValue asinh(){
		return complexToValue( _complex().asinh() );
	}
	MathValue acosh(){
		return complexToValue( _complex().acosh() );
	}
	MathValue atanh(){
		return complexToValue( _complex().atanh() );
	}
	MathValue ceil(){
		return complexToValue( _complex().ceil() );
	}
	MathValue floor(){
		return complexToValue( _complex().floor() );
	}
	MathValue exp(){
		return complexToValue( _complex().exp() );
	}
	MathValue exp10(){
		return complexToValue( _complex().exp10() );
	}
	MathValue log(){
		return complexToValue( _complex().log() );
	}
	MathValue log10(){
		return complexToValue( _complex().log10() );
	}
	MathValue sqrt(){
		return complexToValue( _complex().sqrt() );
	}

	static void deleteValue( MathValue x ){
//		x._c = null;
//		x._f = null;
//		x._t = null;
	}

	static void getValue( MathValue v, ParamInteger type, MathComplex c, MathFract f, MathTime t ){
		type.set( v._type );
		MathComplex.setComplex( c, v._c.real(), v._c.imag() );
		MathFract.setFract( f, v._f.getMinus(), v._f.num(), v._f.denom() );
		MathTime.setTime( t, v._t.fps(), v._t.getMinus(), v._t.hour(), v._t.min(), v._t.sec(), v._t.frame() );
	}
	static MathValue setValue( MathValue v, int type, MathComplex c, MathFract f, MathTime t ){
		v._type = type;
		MathComplex.setComplex( v._c, c.real(), c.imag() );
		MathFract.setFract( v._f, f.getMinus(), f.num(), f.denom() );
		MathTime.setTime( v._t, t.fps(), t.getMinus(), t.hour(), t.min(), t.sec(), t.frame() );
		return v;
	}
	static MathValue copy( MathValue v, MathValue x ){
		v._type = x._type;
		switch( v._type ){
		case ClipMath.valueTypeComplex: MathComplex.setComplex( v._c, x._c.real(), x._c.imag() ); break;
		case ClipMath.valueTypeFract  : MathFract.setFract( v._f, x._f.getMinus(), x._f.num(), x._f.denom() ); break;
		case ClipMath.valueTypeTime   : MathTime.setTime( v._t, x._t.fps(), x._t.getMinus(), x._t.hour(), x._t.min(), x._t.sec(), x._t.frame() ); break;
		}
		return v;
	}
	static MathValue dup( MathValue x ){
//		return setValue( _Value(), x._type, x._c, x._f, x._t );
		return copy( MathValue(), x );
	}

	static MathValue floatToValue( double x ){
		return MathValue().setFloat( x );
	}
	static MathValue complexToValue( MathComplex x ){
		return MathValue().setComplex( x );
	}
	static MathValue fractToValue( MathFract x ){
		return MathValue().setFract( x );
	}
	static MathValue timeToValue( MathTime x ){
		return MathValue().setTime( x );
	}

	static List<MathValue> newArray( int len ){
		List<MathValue> a = List.filled( len, MathValue() );
		for( int i = 0; i < len; i++ ){
			a[i] = MathValue();
		}
		return a;
	}
}
