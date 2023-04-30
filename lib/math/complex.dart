/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import '../param/float.dart';
import 'math.dart';
import 'math_env.dart';

const double _EPS5 = 0.001; // _DBL_EPSILONの1/5乗程度
const double _SQRT05 = 0.7071067811865475244008444; // √0.5

// 複素数型
class MathComplex {
	late double _re;
	late double _im;

	MathComplex( [double re = 0.0, double im = 0.0] ){
		_re = re; // 実数部 real
		_im = im; // 虚数部 imaginary
	}

	// 角度の単位を指定の単位に変換する
	void angToAng( int oldType, int newType ){
		if( oldType != newType ){
			switch( oldType ){
			case MATH_ANG_TYPE_RAD:
				mulAndAss( (newType == MATH_ANG_TYPE_DEG) ? 180.0 : 200.0 );
				divAndAss( MATH_PI );
				break;
			case MATH_ANG_TYPE_DEG:
				mulAndAss( (newType == MATH_ANG_TYPE_RAD) ? MATH_PI : 200.0 );
				divAndAss( 180.0 );
				break;
			case MATH_ANG_TYPE_GRAD:
				mulAndAss( (newType == MATH_ANG_TYPE_RAD) ? MATH_PI : 180.0 );
				divAndAss( 200.0 );
				break;
			}
		}
	}

	// 設定
	void setReal( double re ){
		_re = re;
	}
	void setImag( double im ){
		_im = im;
	}
	void polar( double rho, double theta ){
		theta = _angToRad( theta );
		_re = rho * MATH_COS( theta );
		_im = rho * MATH_SIN( theta );
	}

	// 確認
	double real(){
		return _re;
	}
	double imag(){
		return _im;
	}

	// 型変換
	double toFloat(){
		return _re;
	}

	// 代入
	MathComplex ass( dynamic r ){
		if( r is MathComplex ){
			_re = r._re;
			_im = r._im;
		} else {
			_re = MATH_DOUBLE(r);
			_im = 0.0;
		}
		return this;
	}

	// 単項マイナス
	MathComplex minus(){
		return MathComplex( -_re, -_im );
	}

	// 加算
	MathComplex add( dynamic r ){
		if( r is MathComplex ){
			return MathComplex( _re + r._re, _im + r._im );
		}
		return MathComplex( _re + MATH_DOUBLE(r), _im );
	}
	MathComplex addAndAss( dynamic r ){
		if( r is MathComplex ){
			_re += r._re;
			_im += r._im;
		} else {
			_re += MATH_DOUBLE(r);
		}
		return this;
	}

	// 減算
	MathComplex sub( dynamic r ){
		if( r is MathComplex ){
			return MathComplex( _re - r._re, _im - r._im );
		}
		return MathComplex( _re - MATH_DOUBLE(r), _im );
	}
	MathComplex subAndAss( dynamic r ){
		if( r is MathComplex ){
			_re -= r._re;
			_im -= r._im;
		} else {
			_re -= MATH_DOUBLE(r);
		}
		return this;
	}

	// 乗算
	MathComplex mul( dynamic r ){
		if( r is MathComplex ){
			if( r._im == 0.0 ){
				return MathComplex( _re * r._re, _im * r._re );
			}
			return MathComplex( _re * r._re - _im * r._im, _re * r._im + _im * r._re );
		}
		double rr = MATH_DOUBLE(r);
		return MathComplex( _re * rr, _im * rr );
	}
	MathComplex mulAndAss( dynamic r ){
		if( r is MathComplex ){
			if( r._im == 0.0 ){
				_re *= r._re;
				_im *= r._re;
			} else {
				double t = _re * r._re - _im * r._im;
				_im = _re * r._im + _im * r._re;
				_re = t;
			}
		} else {
			double rr = MATH_DOUBLE(r);
			_re *= rr;
			_im *= rr;
		}
		return this;
	}

	// 除算
	MathComplex div( dynamic r ){
		if( r is MathComplex ){
			if( r._im == 0.0 ){
				return MathComplex( _re / r._re, _im / r._re );
			}
			if( MATH_ABS( r._re ) < MATH_ABS( r._im ) ){
				double w = r._re / r._im;
				double d = r._re * w + r._im;
				return MathComplex( (_re * w + _im) / d, (_im * w - _re) / d );
			}
			double w = r._im / r._re;
			double d = r._re + r._im * w;
			return MathComplex( (_re + _im * w) / d, (_im - _re * w) / d );
		}
		double rr = MATH_DOUBLE(r);
		return MathComplex( _re / rr, _im / rr );
	}
	MathComplex divAndAss( dynamic r ){
		if( r is MathComplex ){
			if( r._im == 0.0 ){
				_re /= r._re;
				_im /= r._re;
			} else if( MATH_ABS( r._re ) < MATH_ABS( r._im ) ){
				double w = r._re / r._im;
				double d = r._re * w + r._im;
				double t = (_re * w + _im) / d;
				_im = (_im * w - _re) / d;
				_re = t;
			} else {
				double w = r._im / r._re;
				double d = r._re + r._im * w;
				double t = (_re + _im * w) / d;
				_im = (_im - _re * w) / d;
				_re = t;
			}
		} else {
			double rr = MATH_DOUBLE(r);
			_re /= rr;
			_im /= rr;
		}
		return this;
	}

	// 剰余
	MathComplex mod( dynamic r ){
		if( r is MathComplex ){
			if( r._im == 0.0 ){
				return MathComplex( MATH_FMOD( _re, r._re ), MATH_FMOD( _im, r._re ) );
			}
			MathComplex z = dupComplex( this );
			z.divAndAss( r );
			z._re = MATH_INT( z._re );
			z._im = MATH_INT( z._im );
			z.mulAndAss( r );
			return sub( z );
		}
		double rr = MATH_DOUBLE(r);
		return MathComplex( MATH_FMOD( _re, rr ), MATH_FMOD( _im, rr ) );
	}
	MathComplex modAndAss( dynamic r ){
		if( r is MathComplex ){
			if( r._im == 0.0 ){
				_re = MATH_FMOD( _re, r._re );
				_im = MATH_FMOD( _im, r._re );
			} else {
				MathComplex z = dupComplex( this );
				z.divAndAss( r );
				z._re = MATH_INT( z._re );
				z._im = MATH_INT( z._im );
				z.mulAndAss( r );
				subAndAss( z );
			}
		} else {
			double rr = MATH_DOUBLE(r);
			_re = MATH_FMOD( _re, rr );
			_im = MATH_FMOD( _im, rr );
		}
		return this;
	}

	// 等値
	bool equal( dynamic r ){
		if( r is MathComplex ){
			return (_re == r._re) && (_im == r._im);
		}
		return (_re == MATH_DOUBLE(r)) && (_im == 0.0);
	}
	bool notEqual( dynamic r ){
		if( r is MathComplex ){
			return (_re != r._re) || (_im != r._im);
		}
		return (_re != MATH_DOUBLE(r)) || (_im != 0.0);
	}

	// 絶対値
	double fabs(){
		if( _re == 0.0 ){
			return MATH_ABS( _im );
		}
		if( _im == 0.0 ){
			return MATH_ABS( _re );
		}
		if( MATH_ABS( _re ) < MATH_ABS( _im ) ){
			double t = _re / _im;
			return MATH_ABS( _im ) * MATH_SQRT( 1.0 + t * t );
		}
		double t = _im / _re;
		return MATH_ABS( _re ) * MATH_SQRT( 1.0 + t * t );
	}

	// 位相角度
	double farg(){
		return fatan2( _im, _re );
	}

	// 絶対値の自乗
	double fnorm(){
		return _re * _re + _im * _im;
	}

	// 共役複素数
	MathComplex conjg(){
		return MathComplex( _re, -_im );
	}

	// 正弦
	MathComplex sin(){
		if( _im == 0.0 ){
			return floatToComplex( fsin( _re ) );
		}
		double re = _angToRad( _re );
		double im = _angToRad( _im );
		return MathComplex(
			MATH_SIN( re ) * fcosh( im ),
			MATH_COS( re ) * fsinh( im )
			);
	}

	// 余弦
	MathComplex cos(){
		if( _im == 0.0 ){
			return floatToComplex( fcos( _re ) );
		}
		double re = _angToRad( _re );
		double im = _angToRad( _im );
		return MathComplex(
			 MATH_COS( re ) * fcosh( im ),
			-MATH_SIN( re ) * fsinh( im )
			);
	}

	// 正接
	MathComplex tan(){
		if( _im == 0.0 ){
			return floatToComplex( ftan( _re ) );
		}
		double re2 = _angToRad( _re ) * 2.0;
		double im2 = _angToRad( _im ) * 2.0;
		double d = MATH_COS( re2 ) + fcosh( im2 );
		if( d == 0.0 ){
			setComplexError();
		}
		return MathComplex(
			MATH_SIN( re2 ) / d,
			fsinh( im2 ) / d
			);
	}

	// 逆正弦
	MathComplex asin(){
		if( _im == 0.0 ){
			if( (_re < -1.0) || (_re > 1.0) ){
				if( complexIsReal() ){
					setComplexError();
					return floatToComplex( fasin( _re ) );
				}
			} else {
				return floatToComplex( fasin( _re ) );
			}
		}
		// -i * log( i * this + sqrt( -sqr() + 1.0 ) )
		MathComplex i = MathComplex( 0.0, 1.0 );
		MathComplex c = i.minus().mul( i.mul( this ).add( sqr().minus().add( 1.0 ).sqrt() ).log() );
		c._re = _radToAng( c._re );
		c._im = _radToAng( c._im );
		return c;
	}

	// 逆余弦
	MathComplex acos(){
		if( _im == 0.0 ){
			if( (_re < -1.0) || (_re > 1.0) ){
				if( complexIsReal() ){
					setComplexError();
					return floatToComplex( facos( _re ) );
				}
			} else {
				return floatToComplex( facos( _re ) );
			}
		}
/*
		// -i * log( this + sqrt( sqr() - 1.0 ) )
		MathComplex c = MathComplex( 0.0, 1.0 ).minus().mul( add( sqr().sub( 1.0 ).sqrt() ).log() );
*/
		// i * log( this - i * sqrt( -sqr() + 1.0 ) )
		MathComplex i = MathComplex( 0.0, 1.0 );
		MathComplex c = i.mul( sub( i.mul( sqr().minus().add( 1.0 ).sqrt() ) ).log() );
		c._re = _radToAng( c._re );
		c._im = _radToAng( c._im );
		return c;
	}

	// 逆正接
	MathComplex atan(){
		if( _im == 0.0 ){
			return floatToComplex( fatan( _re ) );
		}
		MathComplex d = MathComplex( -_re, 1.0 - _im );
		if( d.equal( 0.0 ) ){
			setComplexError();
		}
		// i * log( (i + this) / d ) * 0.5
		MathComplex i = MathComplex( 0.0, 1.0 );
		MathComplex c = i.mul( i.add( this ).div( d ).log() ).mul( 0.5 );
		c._re = _radToAng( c._re );
		c._im = _radToAng( c._im );
		return c;
	}

	// 双曲線正弦
	MathComplex sinh(){
		if( _im == 0.0 ){
			return floatToComplex( fsinh( _re ) );
		}
		return MathComplex(
			fsinh( _re ) * MATH_COS( _im ),
			fcosh( _re ) * MATH_SIN( _im )
			);
	}

	// 双曲線余弦
	MathComplex cosh(){
		if( _im == 0.0 ){
			return floatToComplex( fcosh( _re ) );
		}
		return MathComplex(
			fcosh( _re ) * MATH_COS( _im ),
			fsinh( _re ) * MATH_SIN( _im )
			);
	}

	// 双曲線正接
	MathComplex tanh(){
		if( _im == 0.0 ){
			return floatToComplex( ftanh( _re ) );
		}
		double re2 = _re * 2.0;
		double im2 = _im * 2.0;
		double d = fcosh( re2 ) + MATH_COS( im2 );
		if( d == 0.0 ){
			setComplexError();
		}
		return MathComplex(
			fsinh( re2 ) / d,
			MATH_SIN( im2 ) / d
			);
	}

	// 逆双曲線正弦
	MathComplex asinh(){
		if( _im == 0.0 ){
			return floatToComplex( fasinh( _re ) );
		}
		// log( this + sqrt( sqr() + 1.0 ) )
		return add( sqr().add( 1.0 ).sqrt() ).log();
	}

	// 逆双曲線余弦
	MathComplex acosh(){
		if( _im == 0.0 ){
			if( _re < 1.0 ){
				if( complexIsReal() ){
					setComplexError();
					return floatToComplex( facosh( _re ) );
				}
			} else {
				return floatToComplex( facosh( _re ) );
			}
		}
		// log( this + sqrt( sqr() - 1.0 ) )
		return add( sqr().sub( 1.0 ).sqrt() ).log();
	}

	// 逆双曲線正接
	MathComplex atanh(){
		if( _im == 0.0 ){
			if( (_re <= -1.0) || (_re >= 1.0) ){
				if( complexIsReal() ){
					setComplexError();
					return floatToComplex( fatanh( _re ) );
				}
			} else {
				return floatToComplex( fatanh( _re ) );
			}
		}
		MathComplex d = MathComplex( 1.0 - _re, -_im );
		if( d.equal( 0.0 ) ){
			setComplexError();
		}
		// log( (this + 1.0) / d ) * 0.5
		return add( 1.0 ).div( d ).log().mul( 0.5 );
	}

	// 切り上げ
	MathComplex ceil(){
		return MathComplex(
			MATH_CEIL( _re ),
			MATH_CEIL( _im )
			);
	}

	// 切り捨て
	MathComplex floor(){
		return MathComplex(
			MATH_FLOOR( _re ),
			MATH_FLOOR( _im )
			);
	}

	// 指数
	MathComplex exp(){
		if( _im == 0.0 ){
			return floatToComplex( MATH_EXP( _re ) );
		}
		double e = MATH_EXP( _re );
		return MathComplex(
			e * MATH_COS( _im ),
			e * MATH_SIN( _im )
			);
	}
	MathComplex exp10(){
		if( _im == 0.0 ){
			return floatToComplex( MATH_EXP( _re / MATH_NORMALIZE ) );
		}
		double im = _im / MATH_NORMALIZE;
		double e = MATH_EXP( _re / MATH_NORMALIZE );
		return MathComplex(
			e * MATH_COS( im ),
			e * MATH_SIN( im )
			);
	}

	// 対数
	MathComplex log(){
		if( _im == 0.0 ){
			if( _re <= 0.0 ){
				if( complexIsReal() ){
					setComplexError();
					return floatToComplex( MATH_LOG( _re ) );
				}
			} else {
				return floatToComplex( MATH_LOG( _re ) );
			}
		}
		return MathComplex(
			MATH_LOG( fabs() ),
			MATH_ATAN2( _im, _re )
			);
	}
	MathComplex log10(){
		if( _im == 0.0 ){
			if( _re <= 0.0 ){
				if( complexIsReal() ){
					setComplexError();
					return floatToComplex( MATH_LOG( _re ) * MATH_NORMALIZE );
				}
			} else {
				return floatToComplex( MATH_LOG( _re ) * MATH_NORMALIZE );
			}
		}
		return MathComplex(
			MATH_LOG( fabs() ) * MATH_NORMALIZE,
			MATH_ATAN2( _im, _re ) * MATH_NORMALIZE
			);
	}

	// べき乗
	MathComplex pow( dynamic y ){
		if( y is MathComplex ){
			if( y._im == 0.0 ){
				if( _im == 0.0 ){
					return floatToComplex( MATH_POW( _re, y._re ) );
				}
				// exp( log( this ) * y._re )
				return log().mul( y._re ).exp();
			}
			if( _im == 0.0 ){
				// exp( y * _LOG( _re ) )
				return y.mul( MATH_LOG( _re ) ).exp();
			}
			// exp( log( this ) * y )
			return log().mul( y ).exp();
		}
		if( _im == 0.0 ){
			return floatToComplex( MATH_POW( _re, MATH_DOUBLE(y) ) );
		}
		// exp( log( this ) * y )
		return log().mul( MATH_DOUBLE(y) ).exp();
	}

	// 自乗
	MathComplex sqr(){
		if( _im == 0.0 ){
			return floatToComplex( _re * _re );
		}
		return MathComplex( _re * _re - _im * _im, _re * _im + _im * _re );
	}

	// 平方根
	MathComplex sqrt(){
		if( _im == 0.0 ){
			if( _re < 0.0 ){
				if( complexIsReal() ){
					setComplexError();
					return floatToComplex( MATH_SQRT( _re ) );
				}
			} else {
				return floatToComplex( MATH_SQRT( _re ) );
			}
		}
		if( _re >= 0.0 ){
			double r = MATH_SQRT( fabs() + _re );
			return MathComplex(
				_SQRT05 * r,
				_SQRT05 * _im / r
				);
		}
		if( _im >= 0.0 ){
			double r = MATH_SQRT( fabs() - _re );
			return MathComplex(
				_SQRT05 * _im / r,
				_SQRT05 * r
				);
		}
		double r = MATH_SQRT( fabs() - _re );
		return MathComplex(
			-_SQRT05 * _im / r,
			-_SQRT05 * r
			);
	}
}

void getComplex( MathComplex c, ParamFloat re, ParamFloat im ){
	re.set( c._re );
	im.set( c._im );
}
MathComplex setComplex( MathComplex c, double re, double im ){
	c._re = re;
	c._im = im;
	return c;
}

MathComplex dupComplex( MathComplex x ){
	return MathComplex( x._re, x._im );
}

MathComplex floatToComplex( double x ){
	return MathComplex( x, 0.0 );
}

List<MathComplex> newComplexArray( int len ){
	List<MathComplex> a = List.filled( len, MathComplex() );
	for( int i = 0; i < len; i++ ){
		a[i] = MathComplex();
	}
	return a;
}

// ラジアンを現在の角度の単位に変換する
double _radToAng( double rad ){
	return complexIsRad() ? rad : rad * complexAngCoef() / MATH_PI;
}

// 現在の角度の単位をラジアンに変換する
double _angToRad( double ang ){
	return complexIsRad() ? ang : ang * MATH_PI / complexAngCoef();
}

// 各種関数
double fsin( double x ){
	return MATH_SIN( _angToRad( x ) );
}
double fcos( double x ){
	return MATH_COS( _angToRad( x ) );
}
double ftan( double x ){
	return MATH_TAN( _angToRad( x ) );
}
double fasin( double x ){
	return _radToAng( MATH_ASIN( x ) );
}
double facos( double x ){
	return _radToAng( MATH_ACOS( x ) );
}
double fatan( double x ){
	return _radToAng( MATH_ATAN( x ) );
}
double fatan2( double y, double x ){
	return _radToAng( MATH_ATAN2( y, x ) );
}
double fsinh( double x ){
	if( MATH_ABS( x ) > _EPS5 ){
		double t = MATH_EXP( x );
		return (t - 1.0 / t) / 2.0;
	}
	return x * (1.0 + x * x / 6.0);
}
double fcosh( double x ){
	double t = MATH_EXP( x );
	return (t + 1.0 / t) / 2.0;
}
double ftanh( double x ){
	if( x > _EPS5 ){
		return 2.0 / (1.0 + MATH_EXP( -2.0 * x )) - 1.0;
	}
	if( x < -_EPS5 ){
		return 1.0 - 2.0 / (MATH_EXP( 2.0 * x ) + 1.0);
	}
	return x * (1.0 - x * x / 3.0);
}
double fasinh( double x ){
	if( x > _EPS5 ){
		return MATH_LOG( MATH_SQRT( x * x + 1.0 ) + x );
	}
	if( x < -_EPS5 ){
		return -MATH_LOG( MATH_SQRT( x * x + 1.0 ) - x );
	}
	return x * (1.0 - x * x / 6.0);
}
double facosh( double x ){
	return MATH_LOG( x + MATH_SQRT( x * x - 1.0 ) );
}
double fatanh( double x ){
	if( MATH_ABS( x ) > _EPS5 ){
		return MATH_LOG( (1.0 + x) / (1.0 - x) ) * 0.5;
	}
	return x * (1.0 + x * x / 3.0);
}
