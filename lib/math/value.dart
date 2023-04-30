/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import '../param/float.dart';
import '../param/integer.dart';
import 'complex.dart';
import 'fract.dart';
import 'math.dart';
import 'math_env.dart';
import 'time.dart';

// 基本型
class MathValue {
	late int _type;
	late MathComplex _c;
	late MathFract _f;
	late MathTime _t;

	MathValue(){
		_type = valueType(); // 型（ローカル）
		_c = MathComplex(); // 複素数型
		_f = MathFract(); // 分数型
		_t = MathTime(); // 時間型
	}

	int type(){
		if( valueType() != _type ){
			switch( valueType() ){
			case MATH_VALUE_TYPE_COMPLEX:
				switch( _type ){
				case MATH_VALUE_TYPE_FRACT: _c.ass( _f.toFloat() ); break;
				case MATH_VALUE_TYPE_TIME : _c.ass( _t.toFloat() ); break;
				}
				break;
			case MATH_VALUE_TYPE_FRACT:
				switch( _type ){
				case MATH_VALUE_TYPE_COMPLEX: _f.ass( _c.toFloat() ); break;
				case MATH_VALUE_TYPE_TIME   : _f.ass( _t.toFloat() ); break;
				}
				break;
			case MATH_VALUE_TYPE_TIME:
				switch( _type ){
				case MATH_VALUE_TYPE_COMPLEX: _t.ass( _c.toFloat() ); break;
				case MATH_VALUE_TYPE_FRACT  : _t.ass( _f.toFloat() ); break;
				}
				break;
			}
			_type = valueType();
		}
		return _type;
	}

	void angToAng( int oldType, int newType ){
		_complex().angToAng( oldType, newType );
	}

	MathComplex _complex(){
		switch( _type ){
		case MATH_VALUE_TYPE_FRACT: _c.ass( _f.toFloat() ); _type = MATH_VALUE_TYPE_COMPLEX; break;
		case MATH_VALUE_TYPE_TIME : _c.ass( _t.toFloat() ); _type = MATH_VALUE_TYPE_COMPLEX; break;
		}
		return _c;
	}
	MathComplex _tmpComplex(){
		if( _type == MATH_VALUE_TYPE_FRACT ) return floatToComplex( _f.toFloat() );
		if( _type == MATH_VALUE_TYPE_TIME  ) return floatToComplex( _t.toFloat() );
		return _c;
	}
	MathFract _fract(){
		switch( _type ){
		case MATH_VALUE_TYPE_COMPLEX: _f.ass( _c.toFloat() ); _type = MATH_VALUE_TYPE_FRACT; break;
		case MATH_VALUE_TYPE_TIME   : _f.ass( _t.toFloat() ); _type = MATH_VALUE_TYPE_FRACT; break;
		}
		return _f;
	}
	MathFract _tmpFract(){
		if( _type == MATH_VALUE_TYPE_COMPLEX ) return floatToFract( _c.toFloat() );
		if( _type == MATH_VALUE_TYPE_TIME    ) return floatToFract( _t.toFloat() );
		return _f;
	}
	MathTime _time(){
		switch( _type ){
		case MATH_VALUE_TYPE_COMPLEX: _t.ass( _c.toFloat() ); _type = MATH_VALUE_TYPE_TIME; break;
		case MATH_VALUE_TYPE_FRACT  : _t.ass( _f.toFloat() ); _type = MATH_VALUE_TYPE_TIME; break;
		}
		return _t;
	}
	MathTime _tmpTime(){
		if( _type == MATH_VALUE_TYPE_COMPLEX ) return floatToTime( _c.toFloat() );
		if( _type == MATH_VALUE_TYPE_FRACT   ) return floatToTime( _f.toFloat() );
		return _t;
	}

	MathValue setFloat( double x ){
		switch( _type ){
		case MATH_VALUE_TYPE_COMPLEX: _c.ass( x ); break;
		case MATH_VALUE_TYPE_FRACT  : _f.ass( x ); break;
		case MATH_VALUE_TYPE_TIME   : _t.ass( x ); break;
		}
		return this;
	}
	MathValue setComplex( MathComplex x ){
		switch( _type ){
		case MATH_VALUE_TYPE_COMPLEX: _c.ass( x           ); break;
		case MATH_VALUE_TYPE_FRACT  : _f.ass( x.toFloat() ); break;
		case MATH_VALUE_TYPE_TIME   : _t.ass( x.toFloat() ); break;
		}
		return this;
	}
	MathValue setFract( MathFract x ){
		switch( _type ){
		case MATH_VALUE_TYPE_COMPLEX: _c.ass( x.toFloat() ); break;
		case MATH_VALUE_TYPE_FRACT  : _f.ass( x           ); break;
		case MATH_VALUE_TYPE_TIME   : _t.ass( x.toFloat() ); break;
		}
		return this;
	}
	MathValue setTime( MathTime x ){
		switch( _type ){
		case MATH_VALUE_TYPE_COMPLEX: _c.ass( x.toFloat() ); break;
		case MATH_VALUE_TYPE_FRACT  : _f.ass( x.toFloat() ); break;
		case MATH_VALUE_TYPE_TIME   : _t.ass( x           ); break;
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
		if( _type == MATH_VALUE_TYPE_COMPLEX ) return _c.toFloat();
		if( _type == MATH_VALUE_TYPE_FRACT   ) return _f.toFloat();
		return _t.toFloat();
	}

	// 代入
	MathValue ass( dynamic r ){
		if( r is MathValue ){
			_type = r._type; // 代入の場合は左辺値の変換は不要なのでtype関数は使わない
			switch( _type ){
			case MATH_VALUE_TYPE_COMPLEX: _c.ass( r._c ); break;
			case MATH_VALUE_TYPE_FRACT  : _f.ass( r._f ); break;
			case MATH_VALUE_TYPE_TIME   : _t.ass( r._t ); break;
			}
		} else {
			_type = valueType(); // 代入の場合は左辺値の変換は不要なのでtype関数は使わない
			switch( _type ){
			case MATH_VALUE_TYPE_COMPLEX: _c.ass( MATH_DOUBLE(r) ); break;
			case MATH_VALUE_TYPE_FRACT  : _f.ass( MATH_DOUBLE(r) ); break;
			case MATH_VALUE_TYPE_TIME   : _t.ass( MATH_DOUBLE(r) ); break;
			}
		}
		return this;
	}

	// 単項マイナス
	MathValue minus(){
		type();
		if( _type == MATH_VALUE_TYPE_COMPLEX ) return complexToValue( _c.minus() );
		if( _type == MATH_VALUE_TYPE_FRACT   ) return fractToValue  ( _f.minus() );
		return timeToValue( _t.minus() );
	}

	// 加算
	MathValue add( r ){
		type();
		if( r is MathValue ){
			if( r._type == MATH_VALUE_TYPE_COMPLEX ){
				if( _type == MATH_VALUE_TYPE_COMPLEX ) return complexToValue( _c.add( r._c           ) );
				if( _type == MATH_VALUE_TYPE_FRACT   ) return fractToValue  ( _f.add( r._c.toFloat() ) );
				return timeToValue( _t.add( r._c.toFloat() ) );
			}
			if( r._type == MATH_VALUE_TYPE_FRACT ){
				if( _type == MATH_VALUE_TYPE_COMPLEX ) return complexToValue( _c.add( r._f.toFloat() ) );
				if( _type == MATH_VALUE_TYPE_FRACT   ) return fractToValue  ( _f.add( r._f           ) );
				return timeToValue( _t.add( r._f.toFloat() ) );
			}
			if( _type == MATH_VALUE_TYPE_COMPLEX ) return complexToValue( _c.add( r._t.toFloat() ) );
			if( _type == MATH_VALUE_TYPE_FRACT   ) return fractToValue  ( _f.add( r._t.toFloat() ) );
			return timeToValue( _t.add( r._t ) );
		}
		if( _type == MATH_VALUE_TYPE_COMPLEX ) return complexToValue( _c.add( MATH_DOUBLE(r) ) );
		if( _type == MATH_VALUE_TYPE_FRACT   ) return fractToValue  ( _f.add( MATH_DOUBLE(r) ) );
		return timeToValue( _t.add( MATH_DOUBLE(r) ) );
	}
	MathValue addAndAss( r ){
		if( r is MathValue ){
			switch( r._type ){
			case MATH_VALUE_TYPE_COMPLEX:
				switch( type() ){
				case MATH_VALUE_TYPE_COMPLEX: _c.addAndAss( r._c           ); break;
				case MATH_VALUE_TYPE_FRACT  : _f.addAndAss( r._c.toFloat() ); break;
				case MATH_VALUE_TYPE_TIME   : _t.addAndAss( r._c.toFloat() ); break;
				}
				break;
			case MATH_VALUE_TYPE_FRACT:
				switch( type() ){
				case MATH_VALUE_TYPE_COMPLEX: _c.addAndAss( r._f.toFloat() ); break;
				case MATH_VALUE_TYPE_FRACT  : _f.addAndAss( r._f           ); break;
				case MATH_VALUE_TYPE_TIME   : _t.addAndAss( r._f.toFloat() ); break;
				}
				break;
			case MATH_VALUE_TYPE_TIME:
				switch( type() ){
				case MATH_VALUE_TYPE_COMPLEX: _c.addAndAss( r._t.toFloat() ); break;
				case MATH_VALUE_TYPE_FRACT  : _f.addAndAss( r._t.toFloat() ); break;
				case MATH_VALUE_TYPE_TIME   : _t.addAndAss( r._t           ); break;
				}
				break;
			}
		} else {
			switch( type() ){
			case MATH_VALUE_TYPE_COMPLEX: _c.addAndAss( MATH_DOUBLE(r) ); break;
			case MATH_VALUE_TYPE_FRACT  : _f.addAndAss( MATH_DOUBLE(r) ); break;
			case MATH_VALUE_TYPE_TIME   : _t.addAndAss( MATH_DOUBLE(r) ); break;
			}
		}
		return this;
	}

	// 減算
	MathValue sub( r ){
		type();
		if( r is MathValue ){
			if( r._type == MATH_VALUE_TYPE_COMPLEX ){
				if( _type == MATH_VALUE_TYPE_COMPLEX ) return complexToValue( _c.sub( r._c           ) );
				if( _type == MATH_VALUE_TYPE_FRACT   ) return fractToValue  ( _f.sub( r._c.toFloat() ) );
				return timeToValue( _t.sub( r._c.toFloat() ) );
			}
			if( r._type == MATH_VALUE_TYPE_FRACT ){
				if( _type == MATH_VALUE_TYPE_COMPLEX ) return complexToValue( _c.sub( r._f.toFloat() ) );
				if( _type == MATH_VALUE_TYPE_FRACT   ) return fractToValue  ( _f.sub( r._f           ) );
				return timeToValue( _t.sub( r._f.toFloat() ) );
			}
			if( _type == MATH_VALUE_TYPE_COMPLEX ) return complexToValue( _c.sub( r._t.toFloat() ) );
			if( _type == MATH_VALUE_TYPE_FRACT   ) return fractToValue  ( _f.sub( r._t.toFloat() ) );
			return timeToValue( _t.sub( r._t ) );
		}
		if( _type == MATH_VALUE_TYPE_COMPLEX ) return complexToValue( _c.sub( MATH_DOUBLE(r) ) );
		if( _type == MATH_VALUE_TYPE_FRACT   ) return fractToValue  ( _f.sub( MATH_DOUBLE(r) ) );
		return timeToValue( _t.sub( MATH_DOUBLE(r) ) );
	}
	MathValue subAndAss( r ){
		if( r is MathValue ){
			switch( r._type ){
			case MATH_VALUE_TYPE_COMPLEX:
				switch( type() ){
				case MATH_VALUE_TYPE_COMPLEX: _c.subAndAss( r._c           ); break;
				case MATH_VALUE_TYPE_FRACT  : _f.subAndAss( r._c.toFloat() ); break;
				case MATH_VALUE_TYPE_TIME   : _t.subAndAss( r._c.toFloat() ); break;
				}
				break;
			case MATH_VALUE_TYPE_FRACT:
				switch( type() ){
				case MATH_VALUE_TYPE_COMPLEX: _c.subAndAss( r._f.toFloat() ); break;
				case MATH_VALUE_TYPE_FRACT  : _f.subAndAss( r._f           ); break;
				case MATH_VALUE_TYPE_TIME   : _t.subAndAss( r._f.toFloat() ); break;
				}
				break;
			case MATH_VALUE_TYPE_TIME:
				switch( type() ){
				case MATH_VALUE_TYPE_COMPLEX: _c.subAndAss( r._t.toFloat() ); break;
				case MATH_VALUE_TYPE_FRACT  : _f.subAndAss( r._t.toFloat() ); break;
				case MATH_VALUE_TYPE_TIME   : _t.subAndAss( r._t           ); break;
				}
				break;
			}
		} else {
			switch( type() ){
			case MATH_VALUE_TYPE_COMPLEX: _c.subAndAss( MATH_DOUBLE(r) ); break;
			case MATH_VALUE_TYPE_FRACT  : _f.subAndAss( MATH_DOUBLE(r) ); break;
			case MATH_VALUE_TYPE_TIME   : _t.subAndAss( MATH_DOUBLE(r) ); break;
			}
		}
		return this;
	}

	// 乗算
	MathValue mul( r ){
		type();
		if( r is MathValue ){
			if( r._type == MATH_VALUE_TYPE_COMPLEX ){
				if( _type == MATH_VALUE_TYPE_COMPLEX ) return complexToValue( _c.mul( r._c           ) );
				if( _type == MATH_VALUE_TYPE_FRACT   ) return fractToValue  ( _f.mul( r._c.toFloat() ) );
				return timeToValue( _t.mul( r._c.toFloat() ) );
			}
			if( r._type == MATH_VALUE_TYPE_FRACT ){
				if( _type == MATH_VALUE_TYPE_COMPLEX ) return complexToValue( _c.mul( r._f.toFloat() ) );
				if( _type == MATH_VALUE_TYPE_FRACT   ) return fractToValue  ( _f.mul( r._f           ) );
				return timeToValue( _t.mul( r._f.toFloat() ) );
			}
			if( _type == MATH_VALUE_TYPE_COMPLEX ) return complexToValue( _c.mul( r._t.toFloat() ) );
			if( _type == MATH_VALUE_TYPE_FRACT   ) return fractToValue  ( _f.mul( r._t.toFloat() ) );
			return timeToValue( _t.mul( r._t ) );
		}
		if( _type == MATH_VALUE_TYPE_COMPLEX ) return complexToValue( _c.mul( MATH_DOUBLE(r) ) );
		if( _type == MATH_VALUE_TYPE_FRACT   ) return fractToValue  ( _f.mul( MATH_DOUBLE(r) ) );
		return timeToValue( _t.mul( MATH_DOUBLE(r) ) );
	}
	MathValue mulAndAss( r ){
		if( r is MathValue ){
			switch( r._type ){
			case MATH_VALUE_TYPE_COMPLEX:
				switch( type() ){
				case MATH_VALUE_TYPE_COMPLEX: _c.mulAndAss( r._c           ); break;
				case MATH_VALUE_TYPE_FRACT  : _f.mulAndAss( r._c.toFloat() ); break;
				case MATH_VALUE_TYPE_TIME   : _t.mulAndAss( r._c.toFloat() ); break;
				}
				break;
			case MATH_VALUE_TYPE_FRACT:
				switch( type() ){
				case MATH_VALUE_TYPE_COMPLEX: _c.mulAndAss( r._f.toFloat() ); break;
				case MATH_VALUE_TYPE_FRACT  : _f.mulAndAss( r._f           ); break;
				case MATH_VALUE_TYPE_TIME   : _t.mulAndAss( r._f.toFloat() ); break;
				}
				break;
			case MATH_VALUE_TYPE_TIME:
				switch( type() ){
				case MATH_VALUE_TYPE_COMPLEX: _c.mulAndAss( r._t.toFloat() ); break;
				case MATH_VALUE_TYPE_FRACT  : _f.mulAndAss( r._t.toFloat() ); break;
				case MATH_VALUE_TYPE_TIME   : _t.mulAndAss( r._t           ); break;
				}
				break;
			}
		} else {
			switch( type() ){
			case MATH_VALUE_TYPE_COMPLEX: _c.mulAndAss( MATH_DOUBLE(r) ); break;
			case MATH_VALUE_TYPE_FRACT  : _f.mulAndAss( MATH_DOUBLE(r) ); break;
			case MATH_VALUE_TYPE_TIME   : _t.mulAndAss( MATH_DOUBLE(r) ); break;
			}
		}
		return this;
	}

	// 除算
	MathValue div( r ){
		type();
		if( r is MathValue ){
			if( r._type == MATH_VALUE_TYPE_COMPLEX ){
				if( _type == MATH_VALUE_TYPE_COMPLEX ) return complexToValue( _c.div( r._c           ) );
				if( _type == MATH_VALUE_TYPE_FRACT   ) return fractToValue  ( _f.div( r._c.toFloat() ) );
				return timeToValue( _t.div( r._c.toFloat() ) );
			}
			if( r._type == MATH_VALUE_TYPE_FRACT ){
				if( _type == MATH_VALUE_TYPE_COMPLEX ) return complexToValue( _c.div( r._f.toFloat() ) );
				if( _type == MATH_VALUE_TYPE_FRACT   ) return fractToValue  ( _f.div( r._f           ) );
				return timeToValue( _t.div( r._f.toFloat() ) );
			}
			if( _type == MATH_VALUE_TYPE_COMPLEX ) return complexToValue( _c.div( r._t.toFloat() ) );
			if( _type == MATH_VALUE_TYPE_FRACT   ) return fractToValue  ( _f.div( r._t.toFloat() ) );
			return timeToValue( _t.div( r._t ) );
		}
		if( _type == MATH_VALUE_TYPE_COMPLEX ) return complexToValue( _c.div( MATH_DOUBLE(r) ) );
		if( _type == MATH_VALUE_TYPE_FRACT   ) return fractToValue  ( _f.div( MATH_DOUBLE(r) ) );
		return timeToValue( _t.div( MATH_DOUBLE(r) ) );
	}
	MathValue divAndAss( r ){
		if( r is MathValue ){
			switch( r._type ){
			case MATH_VALUE_TYPE_COMPLEX:
				switch( type() ){
				case MATH_VALUE_TYPE_COMPLEX: _c.divAndAss( r._c           ); break;
				case MATH_VALUE_TYPE_FRACT  : _f.divAndAss( r._c.toFloat() ); break;
				case MATH_VALUE_TYPE_TIME   : _t.divAndAss( r._c.toFloat() ); break;
				}
				break;
			case MATH_VALUE_TYPE_FRACT:
				switch( type() ){
				case MATH_VALUE_TYPE_COMPLEX: _c.divAndAss( r._f.toFloat() ); break;
				case MATH_VALUE_TYPE_FRACT  : _f.divAndAss( r._f           ); break;
				case MATH_VALUE_TYPE_TIME   : _t.divAndAss( r._f.toFloat() ); break;
				}
				break;
			case MATH_VALUE_TYPE_TIME:
				switch( type() ){
				case MATH_VALUE_TYPE_COMPLEX: _c.divAndAss( r._t.toFloat() ); break;
				case MATH_VALUE_TYPE_FRACT  : _f.divAndAss( r._t.toFloat() ); break;
				case MATH_VALUE_TYPE_TIME   : _t.divAndAss( r._t           ); break;
				}
				break;
			}
		} else {
			switch( type() ){
			case MATH_VALUE_TYPE_COMPLEX: _c.divAndAss( MATH_DOUBLE(r) ); break;
			case MATH_VALUE_TYPE_FRACT  : _f.divAndAss( MATH_DOUBLE(r) ); break;
			case MATH_VALUE_TYPE_TIME   : _t.divAndAss( MATH_DOUBLE(r) ); break;
			}
		}
		return this;
	}

	// 剰余
	MathValue mod( r ){
		type();
		if( r is MathValue ){
			if( r._type == MATH_VALUE_TYPE_COMPLEX ){
				if( _type == MATH_VALUE_TYPE_COMPLEX ) return complexToValue( _c.mod( r._c           ) );
				if( _type == MATH_VALUE_TYPE_FRACT   ) return fractToValue  ( _f.mod( r._c.toFloat() ) );
				return timeToValue( _t.mod( r._c.toFloat() ) );
			}
			if( r._type == MATH_VALUE_TYPE_FRACT ){
				if( _type == MATH_VALUE_TYPE_COMPLEX ) return complexToValue( _c.mod( r._f.toFloat() ) );
				if( _type == MATH_VALUE_TYPE_FRACT   ) return fractToValue  ( _f.mod( r._f           ) );
				return timeToValue( _t.mod( r._f.toFloat() ) );
			}
			if( _type == MATH_VALUE_TYPE_COMPLEX ) return complexToValue( _c.mod( r._t.toFloat() ) );
			if( _type == MATH_VALUE_TYPE_FRACT   ) return fractToValue  ( _f.mod( r._t.toFloat() ) );
			return timeToValue( _t.mod( r._t ) );
		}
		if( _type == MATH_VALUE_TYPE_COMPLEX ) return complexToValue( _c.mod( MATH_DOUBLE(r) ) );
		if( _type == MATH_VALUE_TYPE_FRACT   ) return fractToValue  ( _f.mod( MATH_DOUBLE(r) ) );
		return timeToValue( _t.mod( MATH_DOUBLE(r) ) );
	}
	MathValue modAndAss( r ){
		if( r is MathValue ){
			switch( r._type ){
			case MATH_VALUE_TYPE_COMPLEX:
				switch( type() ){
				case MATH_VALUE_TYPE_COMPLEX: _c.modAndAss( r._c           ); break;
				case MATH_VALUE_TYPE_FRACT  : _f.modAndAss( r._c.toFloat() ); break;
				case MATH_VALUE_TYPE_TIME   : _t.modAndAss( r._c.toFloat() ); break;
				}
				break;
			case MATH_VALUE_TYPE_FRACT:
				switch( type() ){
				case MATH_VALUE_TYPE_COMPLEX: _c.modAndAss( r._f.toFloat() ); break;
				case MATH_VALUE_TYPE_FRACT  : _f.modAndAss( r._f           ); break;
				case MATH_VALUE_TYPE_TIME   : _t.modAndAss( r._f.toFloat() ); break;
				}
				break;
			case MATH_VALUE_TYPE_TIME:
				switch( type() ){
				case MATH_VALUE_TYPE_COMPLEX: _c.modAndAss( r._t.toFloat() ); break;
				case MATH_VALUE_TYPE_FRACT  : _f.modAndAss( r._t.toFloat() ); break;
				case MATH_VALUE_TYPE_TIME   : _t.modAndAss( r._t           ); break;
				}
				break;
			}
		} else {
			switch( type() ){
			case MATH_VALUE_TYPE_COMPLEX: _c.modAndAss( MATH_DOUBLE(r) ); break;
			case MATH_VALUE_TYPE_FRACT  : _f.modAndAss( MATH_DOUBLE(r) ); break;
			case MATH_VALUE_TYPE_TIME   : _t.modAndAss( MATH_DOUBLE(r) ); break;
			}
		}
		return this;
	}

	// 等値
	bool equal( r ){
		type();
		if( r is MathValue ){
			if( r._type == MATH_VALUE_TYPE_COMPLEX ){
				if( _type == MATH_VALUE_TYPE_COMPLEX ) return _c.equal( r._c           );
				if( _type == MATH_VALUE_TYPE_FRACT   ) return _f.equal( r._c.toFloat() );
				return _t.equal( r._c.toFloat() );
			}
			if( r._type == MATH_VALUE_TYPE_FRACT ){
				if( _type == MATH_VALUE_TYPE_COMPLEX ) return _c.equal( r._f.toFloat() );
				if( _type == MATH_VALUE_TYPE_FRACT   ) return _f.equal( r._f           );
				return _t.equal( r._f.toFloat() );
			}
			if( _type == MATH_VALUE_TYPE_COMPLEX ) return _c.equal( r._t.toFloat() );
			if( _type == MATH_VALUE_TYPE_FRACT   ) return _f.equal( r._t.toFloat() );
			return _t.equal( r._t );
		}
		if( _type == MATH_VALUE_TYPE_COMPLEX ) return _c.equal( MATH_DOUBLE(r) );
		if( _type == MATH_VALUE_TYPE_FRACT   ) return _f.equal( MATH_DOUBLE(r) );
		return _t.equal( MATH_DOUBLE(r) );
	}
	bool notEqual( r ){
		type();
		if( r is MathValue ){
			if( r._type == MATH_VALUE_TYPE_COMPLEX ){
				if( _type == MATH_VALUE_TYPE_COMPLEX ) return _c.notEqual( r._c           );
				if( _type == MATH_VALUE_TYPE_FRACT   ) return _f.notEqual( r._c.toFloat() );
				return _t.notEqual( r._c.toFloat() );
			}
			if( r._type == MATH_VALUE_TYPE_FRACT ){
				if( _type == MATH_VALUE_TYPE_COMPLEX ) return _c.notEqual( r._f.toFloat() );
				if( _type == MATH_VALUE_TYPE_FRACT   ) return _f.notEqual( r._f           );
				return _t.notEqual( r._f.toFloat() );
			}
			if( _type == MATH_VALUE_TYPE_COMPLEX ) return _c.notEqual( r._t.toFloat() );
			if( _type == MATH_VALUE_TYPE_FRACT   ) return _f.notEqual( r._t.toFloat() );
			return _t.notEqual( r._t );
		}
		if( _type == MATH_VALUE_TYPE_COMPLEX ) return _c.notEqual( MATH_DOUBLE(r) );
		if( _type == MATH_VALUE_TYPE_FRACT   ) return _f.notEqual( MATH_DOUBLE(r) );
		return _t.notEqual( MATH_DOUBLE(r) );
	}

	// 各種関数
	MathValue abs(){
		type();
		if( _type == MATH_VALUE_TYPE_COMPLEX ) return floatToValue( _c.fabs() );
		if( _type == MATH_VALUE_TYPE_FRACT   ) return fractToValue( _f.abs () );
		return fractToValue( _tmpFract().abs() );
	}
	MathValue pow( y ){
		type();
		if( y is MathValue ){
			if( _type == MATH_VALUE_TYPE_COMPLEX ) return complexToValue( _c.pow( y._tmpComplex() ) );
			if( _type == MATH_VALUE_TYPE_FRACT   ) return fractToValue  ( _f.pow( y._tmpFract  () ) );
			return fractToValue( _tmpFract().pow( y._tmpFract() ) );
		}
		double yy = y;
		if( _type == MATH_VALUE_TYPE_COMPLEX ) return complexToValue( _c.pow( yy ) );
		if( _type == MATH_VALUE_TYPE_FRACT   ) return fractToValue  ( _f.pow( yy ) );
		return fractToValue( _tmpFract().pow( yy ) );
	}
	MathValue sqr(){
		type();
		if( _type == MATH_VALUE_TYPE_COMPLEX ) return complexToValue( _c.sqr() );
		if( _type == MATH_VALUE_TYPE_FRACT   ) return fractToValue  ( _f.sqr() );
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
		return floatToValue( MATH_MODF( toFloat(), _int ) );
	}
	MathValue factorial(){
		return floatToValue( MATH_FACTORIAL( toFloat() ) );
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
}

void deleteValue( MathValue x ){
//	x._c = null;
//	x._f = null;
//	x._t = null;
}

void getValue( MathValue v, ParamInteger type, MathComplex c, MathFract f, MathTime t ){
	type.set( v._type );
	setComplex( c, v._c.real(), v._c.imag() );
	setFract( f, v._f.getMinus(), v._f.num(), v._f.denom() );
	setTime( t, v._t.fps(), v._t.getMinus(), v._t.hour(), v._t.min(), v._t.sec(), v._t.frame() );
}
MathValue setValue( MathValue v, int type, MathComplex c, MathFract f, MathTime t ){
	v._type = type;
	setComplex( v._c, c.real(), c.imag() );
	setFract( v._f, f.getMinus(), f.num(), f.denom() );
	setTime( v._t, t.fps(), t.getMinus(), t.hour(), t.min(), t.sec(), t.frame() );
	return v;
}
MathValue copyValue( MathValue v, MathValue x ){
	v._type = x._type;
	switch( v._type ){
	case MATH_VALUE_TYPE_COMPLEX: setComplex( v._c, x._c.real(), x._c.imag() ); break;
	case MATH_VALUE_TYPE_FRACT  : setFract( v._f, x._f.getMinus(), x._f.num(), x._f.denom() ); break;
	case MATH_VALUE_TYPE_TIME   : setTime( v._t, x._t.fps(), x._t.getMinus(), x._t.hour(), x._t.min(), x._t.sec(), x._t.frame() ); break;
	}
	return v;
}
MathValue dupValue( MathValue x ){
//	return setValue( _Value(), x._type, x._c, x._f, x._t );
	return copyValue( MathValue(), x );
}

MathValue floatToValue( double x ){
	return MathValue().setFloat( x );
}
MathValue complexToValue( MathComplex x ){
	return MathValue().setComplex( x );
}
MathValue fractToValue( MathFract x ){
	return MathValue().setFract( x );
}
MathValue timeToValue( MathTime x ){
	return MathValue().setTime( x );
}

List<MathValue> newValueArray( int len ){
	List<MathValue> a = List.filled( len, MathValue() );
	for( int i = 0; i < len; i++ ){
		a[i] = MathValue();
	}
	return a;
}
