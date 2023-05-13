/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import '../param/boolean.dart';
import '../param/float.dart';
import 'math.dart';

// 分数
class MathFract {
	static const double _fractMax = 4294967295;

	late bool _mi;
	late double _nu;
	late double _de;

	MathFract( [bool mi = false, double nu = 0.0, double de = 1.0] ){
		_mi = mi; // 負かどうかのフラグ
		_nu = nu; // 分子 numerator
		_de = de; // 分母 denominator
	}

	// 約分する
	void reduce(){
		double g = ClipMath.gcd( _nu, _de );
		if( g != 0 ){
			_nu = ClipMath.div( _nu, g );
			_de = ClipMath.div( _de, g );
		}
	}

	// 循環小数を分数に変換する
	double _pure( double x, int keta ){
		if( x == 0 ){
			return -1;
		}

		int k = -1;
		do {
			k++;
			x *= 10;
		} while( x < 1 );

		String strX = ClipMath.floatToFixed( x, 20 );
		List arrayY = List.filled( keta, 0 );
		int i, j = 0;
		for( i = 0; i <= keta; i++ ){
			if( i >= strX.length ){
				break;
			} else if( ClipMath.charAt( strX, i ) != '.' ){
				arrayY[j++] = ClipMath.charCodeAt( strX, i ) - ClipMath.charCode0;
			}
		}
		if( j < keta ){
			return -1;
		}

		int p;
		bool b;
		for( p = keta ~/ 2; p > 0; p-- ){
			for( i = 0; i < p; i++ ){
				b = false;
				for( j = 1; ; j++ ){
					if( i + p * j >= keta ){
						break;
					} else if( arrayY[i] != arrayY[i + p * j] ){
						b = true;
						break;
					}
				}
				if( b ){
					break;
				}
			}
			if( i >= p ){
				break;
			}
		}
		if( p > 0 ){
			_nu = 0;
			for( i = 0; i < p; i++ ){
				_nu = _nu * 10 + arrayY[i];
			}
			_de = (ClipMath.pow( 10.0, p.toDouble() ) - 1) * ClipMath.pow( 10.0, k.toDouble() );
			return 1;
		}
		return 0;
	}
	bool _recurring( double x ){
		double xx = x;

		double k = 1;
		int i;
		for( i = 0; ; i++ ){
			if( xx / ClipMath.pow( 10.0, i.toDouble() ) < 10 ){
				k = ClipMath.pow( 10.0, i.toDouble() );
				xx /= k;
				break;
			}
		}

		double ii;
		double ret;
		for( i = 0; ; i++ ){
			ii = ClipMath.toInt( xx );
			if( (ret = _pure( xx - ii, 14 )) < 0 ){
				break;
			}
			if( ret > 0 ){
				_nu = (ii * _de + _nu) * k;
				_de *= ClipMath.pow( 10.0, i.toDouble() );
				if( !ClipMath.approx( x, _nu / _de ) ){
					return false;
				}
				reduce();
				return true;
			}
			xx *= 10;
		}
		return false;
	}

	void _set( double n, double d ){
		if( n > d ){
			if( n > _fractMax ){
				_nu = _fractMax;
				_de = ClipMath.toInt( _fractMax * d / n );
			} else {
				_nu = ClipMath.toInt( n );
				_de = ClipMath.toInt( d );
			}
		} else {
			if( d > _fractMax ){
				_nu = ClipMath.toInt( _fractMax * n / d );
				_de = _fractMax;
			} else {
				_nu = ClipMath.toInt( n );
				_de = ClipMath.toInt( d );
			}
		}
		reduce();
	}
	void _setFloat( double x ){
		if( !_recurring( x ) ){
			double de = ClipMath.pow( 10.0, ClipMath.fprec( x ) );
			_set( x * de, de );
		}
	}

	// 設定
	void setMinus( bool mi ){
		_mi = mi;
	}
	void setNum( double nu ){
		_nu = nu;
	}
	void setDenom( double de ){
		_de = de;
	}

	// 確認
	bool getMinus(){
		return _mi && (_nu != 0);
	}
	double num(){
		return _nu;
	}
	double denom(){
		return _de;
	}

	// 型変換
	double toFloat(){
		if( _de == 0 ){
			return double.infinity;
		}
		return (_mi ? -_nu : _nu) / _de;
	}

	// 代入
	MathFract ass( dynamic r ){
		if( r is MathFract ){
			_mi = r._mi;
			_nu = r._nu;
			_de = r._de;
		} else {
			double rr = ClipMath.toDouble(r);
			if( rr < 0.0 ){
				_mi = true;
				rr = -rr;
			} else {
				_mi = false;
			}
			if( rr == ClipMath.toInt( rr ) ){
				_nu = rr;
				_de = 1;
			} else {
				_setFloat( rr );
			}
		}
		return this;
	}

	// 単項マイナス
	MathFract minus(){
		return MathFract( _mi ? false : true, _nu, _de );
	}

	// 加算
	MathFract add( dynamic r ){
		if( r is MathFract ){
			if( _mi != r._mi ){
				// this - -r;
				return sub( r.minus() );
			}
			if( _de == 0 ){
				return this;
			}
			if( r._de == 0 ){
				return r;
			}
			double de = ClipMath.lcm( _de, r._de );
			return MathFract(
				_mi,
				_nu * de / _de + r._nu * de / r._de,
				de
				);
		}
		double rr = ClipMath.toDouble(r);
		if( _mi != (rr < 0.0) ){
			// this - -r
			return sub( -rr );
		}
		double t = (rr < 0.0) ? -rr : rr;
		if( t == ClipMath.toInt( t ) ){
			return MathFract(
				_mi,
				_nu + t * _de,
				_de
				);
		}
		return add( floatToFract( rr ) );
	}
	MathFract addAndAss( dynamic r ){
		if( r is MathFract ){
			if( _mi != r._mi ){
				// this -= -r
				subAndAss( r.minus() );
			} else if( _de == 0 ){
			} else if( r._de == 0 ){
				ass( r );
			} else {
				double de = ClipMath.lcm( _de, r._de );
				_set( _nu * de / _de + r._nu * de / r._de, de );
			}
		} else {
			double rr = ClipMath.toDouble(r);
			if( _mi != (rr < 0.0) ){
				// this -= -rr
				subAndAss( -rr );
			} else {
				double t = (rr < 0.0) ? -rr : rr;
				if( t == ClipMath.toInt( t ) ){
					_set( _nu + t * _de, _de );
				} else {
					addAndAss( floatToFract( rr ) );
				}
			}
		}
		return this;
	}

	// 減算
	MathFract sub( dynamic r ){
		if( r is MathFract ){
			if( _mi != r._mi ){
				// this + -r
				return add( r.minus() );
			}
			if( _de == 0 ){
				return this;
			}
			if( r._de == 0 ){
				return r;
			}
			double de = ClipMath.lcm( _de, r._de );
			double nu = _nu * de / _de - r._nu * de / r._de;
			if( nu < 0.0 ){
				return MathFract( _mi ? false : true, -nu, de );
			}
			return MathFract( _mi, nu, de );
		}
		double rr = ClipMath.toDouble(r);
		if( _mi != (rr < 0.0) ){
			// this + -rr
			return add( -rr );
		}
		double t = (rr < 0.0) ? -rr : rr;
		if( t == ClipMath.toInt( t ) ){
			double nu = _nu - t * _de;
			if( nu < 0.0 ){
				return MathFract( _mi ? false : true, -nu, _de );
			}
			return MathFract( _mi, nu, _de );
		}
		return sub( floatToFract( rr ) );
	}
	MathFract subAndAss( dynamic r ){
		if( r is MathFract ){
			if( _mi != r._mi ){
				// this += -r
				addAndAss( r.minus() );
			} else if( _de == 0 ){
			} else if( r._de == 0 ){
				ass( r );
			} else {
				double de = ClipMath.lcm( _de, r._de );
				double nu = _nu * de / _de - r._nu * de / r._de;
				if( nu < 0.0 ){
					_mi = _mi ? false : true;
					_set( -nu, de );
				} else {
					_set( nu, de );
				}
			}
		} else {
			double rr = ClipMath.toDouble(r);
			if( _mi != (rr < 0.0) ){
				// this += -rr
				addAndAss( -rr );
			} else {
				double t = (rr < 0.0) ? -rr : rr;
				if( t == ClipMath.toInt( t ) ){
					double nu = _nu - t * _de;
					if( nu < 0.0 ){
						_mi = _mi ? false : true;
						_set( -nu, _de );
					} else {
						_set( nu, _de );
					}
				} else {
					subAndAss( floatToFract( rr ) );
				}
			}
		}
		return this;
	}

	// 乗算
	MathFract mul( dynamic r ){
		if( r is MathFract ){
			return MathFract(
				(_mi != r._mi),
				_nu * r._nu,
				_de * r._de
				);
		}
		double rr = ClipMath.toDouble(r);
		double t = (rr < 0.0) ? -rr : rr;
		if( t == ClipMath.toInt( t ) ){
			return MathFract(
				(_mi != (rr < 0.0)),
				_nu * t,
				_de
				);
		}
		return mul( floatToFract( rr ) );
	}
	MathFract mulAndAss( dynamic r ){
		if( r is MathFract ){
			_mi = (_mi != r._mi);
			_set( _nu * r._nu, _de * r._de );
		} else {
			double rr = ClipMath.toDouble(r);
			double t = (rr < 0.0) ? -rr : rr;
			if( t == ClipMath.toInt( t ) ){
				_mi = (_mi != (rr < 0.0));
				_set( _nu * t, _de );
			} else {
				mulAndAss( floatToFract( rr ) );
			}
		}
		return this;
	}

	// 除算
	MathFract div( dynamic r ){
		if( r is MathFract ){
			return MathFract(
				(_mi != r._mi),
				_nu * r._de,
				_de * r._nu
				);
		}
		double rr = ClipMath.toDouble(r);
		double t = (rr < 0.0) ? -rr : rr;
		if( t == ClipMath.toInt( t ) ){
			return MathFract(
				(_mi != (rr < 0.0)),
				_nu,
				_de * t
				);
		}
		return div( floatToFract( rr ) );
	}
	MathFract divAndAss( dynamic r ){
		if( r is MathFract ){
			_mi = (_mi != r._mi);
			_set( _nu * r._de, _de * r._nu );
		} else {
			double rr = ClipMath.toDouble(r);
			double t = (rr < 0.0) ? -rr : rr;
			if( t == ClipMath.toInt( t ) ){
				_mi = (_mi != (rr < 0.0));
				_set( _nu, _de * t );
			} else {
				divAndAss( floatToFract( rr ) );
			}
		}
		return this;
	}

	// 剰余
	MathFract mod( dynamic r ){
		if( r is MathFract ){
			if( _de == 0 ){
				return this;
			}
			if( r._de == 0 ){
				return MathFract( _mi, r._nu, r._de );
			}
			double de = ClipMath.lcm( _de, r._de );
			double d = r._nu * de / r._de;
			if( d == 0.0 ){
				return MathFract( _mi, _nu, 0 );
			}
			return MathFract(
				_mi,
				ClipMath.fmod( _nu * de / _de, d ),
				de
				);
		}
		double rr = ClipMath.toDouble(r);
		double t = (rr < 0.0) ? -rr : rr;
		if( t == ClipMath.toInt( t ) ){
			if( _de == 0 ){
				return this;
			}
			if( t == 0.0 ){
				return MathFract( _mi, 0, 0 );
			}
			return MathFract(
				_mi,
				ClipMath.fmod( _nu, t * _de ),
				_de
				);
		}
		return mod( floatToFract( rr ) );
	}
	MathFract modAndAss( dynamic r ){
		if( r is MathFract ){
			if( _de == 0 ){
			} else if( r._de == 0 ){
				_nu = r._nu;
				_de = r._de;
			} else {
				double de = ClipMath.lcm( _de, r._de );
				double d = r._nu * de / r._de;
				if( d == 0.0 ){
					_de = 0;
				} else {
					_set( ClipMath.fmod( _nu * de / _de, d ), de );
				}
			}
		} else {
			double rr = ClipMath.toDouble(r);
			double t = (rr < 0.0) ? -rr : rr;
			if( t == ClipMath.toInt( t ) ){
				if( _de == 0 ){
				} else if( t == 0.0 ){
					_nu = 0;
					_de = 0;
				} else {
					_set( ClipMath.fmod( _nu, t * _de ), _de );
				}
			} else {
				modAndAss( floatToFract( rr ) );
			}
		}
		return this;
	}

	// 等値
	bool equal( dynamic r ){
		if( r is MathFract ){
			return (getMinus() == r.getMinus()) && ((_nu * r._de) == (_de * r._nu));
		}
		return toFloat() == ClipMath.toDouble(r);
	}
	bool notEqual( dynamic r ){
		if( r is MathFract ){
			return (getMinus() != r.getMinus()) || ((_nu * r._de) != (_de * r._nu));
		}
		return toFloat() != ClipMath.toDouble(r);
	}

	// 絶対値
	MathFract abs(){
		return MathFract( false, _nu, _de );
	}

	// べき乗
	MathFract _powInt( double y ){
		double nu = ClipMath.pow( _nu, y );
		double de = ClipMath.pow( _de, y );
		return MathFract(
			((nu < 0.0) != (de < 0.0)),
			(nu < 0.0) ? -nu : nu,
			(de < 0.0) ? -de : de
			);
	}
	MathFract pow( dynamic y ){
		if( y is MathFract ){
			if( y.toFloat() == ClipMath.toInt( y.toFloat() ) ){
				return _powInt( y.toFloat() );
			}
			return floatToFract( ClipMath.pow( toFloat(), y.toFloat() ) );
		}
		double yy = y;
		if( yy == ClipMath.toInt( yy ) ){
			return _powInt( yy );
		}
		return floatToFract( ClipMath.pow( toFloat(), yy ) );
	}

	// 自乗
	MathFract sqr(){
		return MathFract(
			false,
			_nu * _nu,
			_de * _de
			);
	}

	static void getFract( MathFract f, ParamBoolean mi, ParamFloat nu, ParamFloat de ){
		mi.set( f._mi );
		nu.set( f._nu );
		de.set( f._de );
	}
	static MathFract setFract( MathFract f, bool mi, double nu, double de ){
		f._mi = mi;
		f._nu = nu;
		f._de = de;
		return f;
	}

	static MathFract dupFract( MathFract x ){
		return setFract( MathFract(), x._mi, x._nu, x._de );
	}

	static MathFract floatToFract( double x ){
		return MathFract().ass( x );
	}
}
