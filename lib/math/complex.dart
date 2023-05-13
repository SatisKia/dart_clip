/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import '../param/float.dart';
import 'math.dart';

// 複素数型
class MathComplex {
	static const double _eps5 = 0.001; // dblEpsilonの1/5乗程度
	static const double _sqrt05 = 0.7071067811865475244008444; // √0.5

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
			case ClipMath.angTypeRad:
				mulAndAss( (newType == ClipMath.angTypeDeg) ? 180.0 : 200.0 );
				divAndAss( ClipMath.pi );
				break;
			case ClipMath.angTypeDeg:
				mulAndAss( (newType == ClipMath.angTypeRad) ? ClipMath.pi : 200.0 );
				divAndAss( 180.0 );
				break;
			case ClipMath.angTypeGrad:
				mulAndAss( (newType == ClipMath.angTypeRad) ? ClipMath.pi : 180.0 );
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
		_re = rho * ClipMath.cos( theta );
		_im = rho * ClipMath.sin( theta );
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
			_re = ClipMath.toDouble(r);
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
		return MathComplex( _re + ClipMath.toDouble(r), _im );
	}
	MathComplex addAndAss( dynamic r ){
		if( r is MathComplex ){
			_re += r._re;
			_im += r._im;
		} else {
			_re += ClipMath.toDouble(r);
		}
		return this;
	}

	// 減算
	MathComplex sub( dynamic r ){
		if( r is MathComplex ){
			return MathComplex( _re - r._re, _im - r._im );
		}
		return MathComplex( _re - ClipMath.toDouble(r), _im );
	}
	MathComplex subAndAss( dynamic r ){
		if( r is MathComplex ){
			_re -= r._re;
			_im -= r._im;
		} else {
			_re -= ClipMath.toDouble(r);
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
		double rr = ClipMath.toDouble(r);
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
			double rr = ClipMath.toDouble(r);
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
			if( ClipMath.abs( r._re ) < ClipMath.abs( r._im ) ){
				double w = r._re / r._im;
				double d = r._re * w + r._im;
				return MathComplex( (_re * w + _im) / d, (_im * w - _re) / d );
			}
			double w = r._im / r._re;
			double d = r._re + r._im * w;
			return MathComplex( (_re + _im * w) / d, (_im - _re * w) / d );
		}
		double rr = ClipMath.toDouble(r);
		return MathComplex( _re / rr, _im / rr );
	}
	MathComplex divAndAss( dynamic r ){
		if( r is MathComplex ){
			if( r._im == 0.0 ){
				_re /= r._re;
				_im /= r._re;
			} else if( ClipMath.abs( r._re ) < ClipMath.abs( r._im ) ){
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
			double rr = ClipMath.toDouble(r);
			_re /= rr;
			_im /= rr;
		}
		return this;
	}

	// 剰余
	MathComplex mod( dynamic r ){
		if( r is MathComplex ){
			if( r._im == 0.0 ){
				return MathComplex( ClipMath.fmod( _re, r._re ), ClipMath.fmod( _im, r._re ) );
			}
			MathComplex z = dup( this );
			z.divAndAss( r );
			z._re = ClipMath.toInt( z._re );
			z._im = ClipMath.toInt( z._im );
			z.mulAndAss( r );
			return sub( z );
		}
		double rr = ClipMath.toDouble(r);
		return MathComplex( ClipMath.fmod( _re, rr ), ClipMath.fmod( _im, rr ) );
	}
	MathComplex modAndAss( dynamic r ){
		if( r is MathComplex ){
			if( r._im == 0.0 ){
				_re = ClipMath.fmod( _re, r._re );
				_im = ClipMath.fmod( _im, r._re );
			} else {
				MathComplex z = dup( this );
				z.divAndAss( r );
				z._re = ClipMath.toInt( z._re );
				z._im = ClipMath.toInt( z._im );
				z.mulAndAss( r );
				subAndAss( z );
			}
		} else {
			double rr = ClipMath.toDouble(r);
			_re = ClipMath.fmod( _re, rr );
			_im = ClipMath.fmod( _im, rr );
		}
		return this;
	}

	// 等値
	bool equal( dynamic r ){
		if( r is MathComplex ){
			return (_re == r._re) && (_im == r._im);
		}
		return (_re == ClipMath.toDouble(r)) && (_im == 0.0);
	}
	bool notEqual( dynamic r ){
		if( r is MathComplex ){
			return (_re != r._re) || (_im != r._im);
		}
		return (_re != ClipMath.toDouble(r)) || (_im != 0.0);
	}

	// 絶対値
	double fabs(){
		if( _re == 0.0 ){
			return ClipMath.abs( _im );
		}
		if( _im == 0.0 ){
			return ClipMath.abs( _re );
		}
		if( ClipMath.abs( _re ) < ClipMath.abs( _im ) ){
			double t = _re / _im;
			return ClipMath.abs( _im ) * ClipMath.sqrt( 1.0 + t * t );
		}
		double t = _im / _re;
		return ClipMath.abs( _re ) * ClipMath.sqrt( 1.0 + t * t );
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
			ClipMath.sin( re ) * fcosh( im ),
			ClipMath.cos( re ) * fsinh( im )
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
			 ClipMath.cos( re ) * fcosh( im ),
			-ClipMath.sin( re ) * fsinh( im )
			);
	}

	// 正接
	MathComplex tan(){
		if( _im == 0.0 ){
			return floatToComplex( ftan( _re ) );
		}
		double re2 = _angToRad( _re ) * 2.0;
		double im2 = _angToRad( _im ) * 2.0;
		double d = ClipMath.cos( re2 ) + fcosh( im2 );
		if( d == 0.0 ){
			ClipMath.setComplexError();
		}
		return MathComplex(
			ClipMath.sin( re2 ) / d,
			fsinh( im2 ) / d
			);
	}

	// 逆正弦
	MathComplex asin(){
		if( _im == 0.0 ){
			if( (_re < -1.0) || (_re > 1.0) ){
				if( ClipMath.complexIsReal() ){
					ClipMath.setComplexError();
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
				if( ClipMath.complexIsReal() ){
					ClipMath.setComplexError();
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
			ClipMath.setComplexError();
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
			fsinh( _re ) * ClipMath.cos( _im ),
			fcosh( _re ) * ClipMath.sin( _im )
			);
	}

	// 双曲線余弦
	MathComplex cosh(){
		if( _im == 0.0 ){
			return floatToComplex( fcosh( _re ) );
		}
		return MathComplex(
			fcosh( _re ) * ClipMath.cos( _im ),
			fsinh( _re ) * ClipMath.sin( _im )
			);
	}

	// 双曲線正接
	MathComplex tanh(){
		if( _im == 0.0 ){
			return floatToComplex( ftanh( _re ) );
		}
		double re2 = _re * 2.0;
		double im2 = _im * 2.0;
		double d = fcosh( re2 ) + ClipMath.cos( im2 );
		if( d == 0.0 ){
			ClipMath.setComplexError();
		}
		return MathComplex(
			fsinh( re2 ) / d,
			ClipMath.sin( im2 ) / d
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
				if( ClipMath.complexIsReal() ){
					ClipMath.setComplexError();
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
				if( ClipMath.complexIsReal() ){
					ClipMath.setComplexError();
					return floatToComplex( fatanh( _re ) );
				}
			} else {
				return floatToComplex( fatanh( _re ) );
			}
		}
		MathComplex d = MathComplex( 1.0 - _re, -_im );
		if( d.equal( 0.0 ) ){
			ClipMath.setComplexError();
		}
		// log( (this + 1.0) / d ) * 0.5
		return add( 1.0 ).div( d ).log().mul( 0.5 );
	}

	// 切り上げ
	MathComplex ceil(){
		return MathComplex(
			ClipMath.ceil( _re ),
			ClipMath.ceil( _im )
			);
	}

	// 切り捨て
	MathComplex floor(){
		return MathComplex(
			ClipMath.floor( _re ),
			ClipMath.floor( _im )
			);
	}

	// 指数
	MathComplex exp(){
		if( _im == 0.0 ){
			return floatToComplex( ClipMath.exp( _re ) );
		}
		double e = ClipMath.exp( _re );
		return MathComplex(
			e * ClipMath.cos( _im ),
			e * ClipMath.sin( _im )
			);
	}
	MathComplex exp10(){
		if( _im == 0.0 ){
			return floatToComplex( ClipMath.exp( _re / ClipMath.normalize ) );
		}
		double im = _im / ClipMath.normalize;
		double e = ClipMath.exp( _re / ClipMath.normalize );
		return MathComplex(
			e * ClipMath.cos( im ),
			e * ClipMath.sin( im )
			);
	}

	// 対数
	MathComplex log(){
		if( _im == 0.0 ){
			if( _re <= 0.0 ){
				if( ClipMath.complexIsReal() ){
					ClipMath.setComplexError();
					return floatToComplex( ClipMath.log( _re ) );
				}
			} else {
				return floatToComplex( ClipMath.log( _re ) );
			}
		}
		return MathComplex(
			ClipMath.log( fabs() ),
			ClipMath.atan2( _im, _re )
			);
	}
	MathComplex log10(){
		if( _im == 0.0 ){
			if( _re <= 0.0 ){
				if( ClipMath.complexIsReal() ){
					ClipMath.setComplexError();
					return floatToComplex( ClipMath.log( _re ) * ClipMath.normalize );
				}
			} else {
				return floatToComplex( ClipMath.log( _re ) * ClipMath.normalize );
			}
		}
		return MathComplex(
			ClipMath.log( fabs() ) * ClipMath.normalize,
			ClipMath.atan2( _im, _re ) * ClipMath.normalize
			);
	}

	// べき乗
	MathComplex pow( dynamic y ){
		if( y is MathComplex ){
			if( y._im == 0.0 ){
				if( _im == 0.0 ){
					return floatToComplex( ClipMath.pow( _re, y._re ) );
				}
				// exp( log( this ) * y._re )
				return log().mul( y._re ).exp();
			}
			if( _im == 0.0 ){
				// exp( y * _LOG( _re ) )
				return y.mul( ClipMath.log( _re ) ).exp();
			}
			// exp( log( this ) * y )
			return log().mul( y ).exp();
		}
		if( _im == 0.0 ){
			return floatToComplex( ClipMath.pow( _re, ClipMath.toDouble(y) ) );
		}
		// exp( log( this ) * y )
		return log().mul( ClipMath.toDouble(y) ).exp();
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
				if( ClipMath.complexIsReal() ){
					ClipMath.setComplexError();
					return floatToComplex( ClipMath.sqrt( _re ) );
				}
			} else {
				return floatToComplex( ClipMath.sqrt( _re ) );
			}
		}
		if( _re >= 0.0 ){
			double r = ClipMath.sqrt( fabs() + _re );
			return MathComplex(
				_sqrt05 * r,
				_sqrt05 * _im / r
				);
		}
		if( _im >= 0.0 ){
			double r = ClipMath.sqrt( fabs() - _re );
			return MathComplex(
				_sqrt05 * _im / r,
				_sqrt05 * r
				);
		}
		double r = ClipMath.sqrt( fabs() - _re );
		return MathComplex(
			-_sqrt05 * _im / r,
			-_sqrt05 * r
			);
	}

	static void getComplex( MathComplex c, ParamFloat re, ParamFloat im ){
		re.set( c._re );
		im.set( c._im );
	}
	static MathComplex setComplex( MathComplex c, double re, double im ){
		c._re = re;
		c._im = im;
		return c;
	}

	static MathComplex dup( MathComplex x ){
		return MathComplex( x._re, x._im );
	}

	static MathComplex floatToComplex( double x ){
		return MathComplex( x, 0.0 );
	}

	static List<MathComplex> newArray( int len ){
		List<MathComplex> a = List.filled( len, MathComplex() );
		for( int i = 0; i < len; i++ ){
			a[i] = MathComplex();
		}
		return a;
	}

	// ラジアンを現在の角度の単位に変換する
	static double _radToAng( double rad ){
		return ClipMath.complexIsRad() ? rad : rad * ClipMath.complexAngCoef() / ClipMath.pi;
	}

	// 現在の角度の単位をラジアンに変換する
	static double _angToRad( double ang ){
		return ClipMath.complexIsRad() ? ang : ang * ClipMath.pi / ClipMath.complexAngCoef();
	}

	// 各種関数
	static double fsin( double x ){
		return ClipMath.sin( _angToRad( x ) );
	}
	static double fcos( double x ){
		return ClipMath.cos( _angToRad( x ) );
	}
	static double ftan( double x ){
		return ClipMath.tan( _angToRad( x ) );
	}
	static double fasin( double x ){
		return _radToAng( ClipMath.asin( x ) );
	}
	static double facos( double x ){
		return _radToAng( ClipMath.acos( x ) );
	}
	static double fatan( double x ){
		return _radToAng( ClipMath.atan( x ) );
	}
	static double fatan2( double y, double x ){
		return _radToAng( ClipMath.atan2( y, x ) );
	}
	static double fsinh( double x ){
		if( ClipMath.abs( x ) > _eps5 ){
			double t = ClipMath.exp( x );
			return (t - 1.0 / t) / 2.0;
		}
		return x * (1.0 + x * x / 6.0);
	}
	static double fcosh( double x ){
		double t = ClipMath.exp( x );
		return (t + 1.0 / t) / 2.0;
	}
	static double ftanh( double x ){
		if( x > _eps5 ){
			return 2.0 / (1.0 + ClipMath.exp( -2.0 * x )) - 1.0;
		}
		if( x < -_eps5 ){
			return 1.0 - 2.0 / (ClipMath.exp( 2.0 * x ) + 1.0);
		}
		return x * (1.0 - x * x / 3.0);
	}
	static double fasinh( double x ){
		if( x > _eps5 ){
			return ClipMath.log( ClipMath.sqrt( x * x + 1.0 ) + x );
		}
		if( x < -_eps5 ){
			return -ClipMath.log( ClipMath.sqrt( x * x + 1.0 ) - x );
		}
		return x * (1.0 - x * x / 6.0);
	}
	static double facosh( double x ){
		return ClipMath.log( x + ClipMath.sqrt( x * x - 1.0 ) );
	}
	static double fatanh( double x ){
		if( ClipMath.abs( x ) > _eps5 ){
			return ClipMath.log( (1.0 + x) / (1.0 - x) ) * 0.5;
		}
		return x * (1.0 + x * x / 3.0);
	}
}
