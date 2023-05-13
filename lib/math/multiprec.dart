/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import 'dart:math' as math;

import '../param/integer.dart';
import 'math.dart';

class MPData {
	late List<int> _val;
	MPData( [int len = 0] ){
		if( len == 0 ) {
			_val = <int>[];
		} else {
			_val = List.filled( len, 0 );
		}
	}
	void attach( MPData src ){
		_val = src._val;
	}
	int val( int i ){
		if( i >= _val.length ){
			return 0;
		}
		return _val[i];
	}
	void set( int i, int value ){
		if( i >= _val.length ){
			List<int> tmp = List.filled( i + 1, 0 );
			for( int j = 0; j < _val.length; j++ ){
				tmp[j] = _val[j];
			}
			_val = tmp;
		}
		_val[i] = value;
	}
	void inc( int i ){
		set( i, val(i) + 1 );
	}
	void dec( int i ){
		set( i, val(i) - 1 );
	}
	void add( int i, int value ){
		set( i, val(i) + value );
	}
	void sub( int i, int value ){
		set( i, val(i) - value );
	}
	bool isEmpty(){
		return _val.isEmpty;
	}
	int length(){
		return _val.length;
	}
	List<int> data(){
		return _val;
	}
	MPData clone(){
		if( _val.isEmpty ){
			// ゼロ値
			MPData a = MPData( 2 );
			a.set( 0, MultiPrec.lenCoef );
			a.set( 1, 0 );
			return a;
		}
		MPData a = MPData( _val.length );
		for( int i = 0; i < _val.length; i++ ){
			a._val[i] = _val[i];
		}
		return a;
	}
}

// 多倍長演算クラス
class MultiPrec {
	static int _abs( int x ){
		return x.abs();
	}
	static int _pow( int x, int y ){
		return math.pow( x.toDouble(), y.toDouble() ).toInt();
	}

	static int digit    = 4;
	static int element  = _pow( 10, digit );
	static int precMask = 0xFFFFFFFF;
	static int lenCoef  = precMask + 1;

	late Map<String, MPData> _constI;
	late Map<String, MPData> _constF;

	late void Function( MPData, [MPData?] ) fabs;
	late void Function( MPData, [MPData?] ) fneg;
	late void Function( MPData, MPData ) fset;

	MultiPrec(){
		_constI = {};
		_constF = {};

		fabs = abs;
		fneg = neg;
		fset = set;
	}

	MPData I( dynamic str ){
		if( _constI["_$str"] == null ){
			_constI["_$str"] = MPData();
			str2num( _constI["_$str"]!, str );
		}
		return _constI["_$str"]!;
	}
	MPData F( dynamic str ){
		if( _constF["_$str"] == null ){
			_constF["_$str"] = MPData();
			fstr2num( _constF["_$str"]!, str );
		}
		return _constF["_$str"]!;
	}

	int getLen( MPData a ){
		return _abs( a.val(0) ~/ lenCoef );
	}
	bool isMinus( MPData a ){
		return a.val(0) < 0 ? true : false;
	}
	void setLen( MPData a, int len, bool isMinus ){
		int p = _abs( a.val(0) ) & precMask;
		if( len == 0 ){
			a.set( 0, lenCoef + p ); a.set( 1, 0 ); // ゼロ値
		} else {
			a.set( 0, (len * lenCoef + p) * (isMinus ? -1 : 1) );
		}
	}
	void _setLen( MPData a, int len ){
		int p = _abs( a.val(0) ) & precMask;
		if( len == 0 ){
			a.set( 0, lenCoef + p ); a.set( 1, 0 ); // ゼロ値
		} else {
			a.set( 0, (_abs( len ) * lenCoef + p) * (len < 0 ? -1 : 1) );
		}
	}

	int getPrec( MPData a ){
		return _abs( a.val(0) ) & precMask;
	}
	void _setPrec( MPData a, int prec ){
		int l = _abs( a.val(0) ~/ lenCoef );
		if( l == 0 ){
			a.set( 0, lenCoef + prec ); a.set( 1, 0 ); // ゼロ値
		} else {
			a.set( 0, (l * lenCoef + prec) * (a.val(0) < 0 ? -1 : 1) );
		}
	}

	// 配列の要素の挿入だけで行える分の乗算を行う
	int _fmul( MPData a, int prec ){
		int n = prec ~/ digit;
		if( n > 0 ){
			int l = _abs( a.val(0) ~/ lenCoef );
			_copy( a, 1, a, n + 1, l );
			_fill( 0, a, 1, n );
			int p = _abs( a.val(0) ) & precMask;
			a.set( 0, ((l + n) * lenCoef + p) * (a.val(0) < 0 ? -1 : 1) );
		}
		return prec - n * digit;
	}

	// 配列の要素の削除だけで行える分の除算を行う
	void _fdiv( MPData a, int len ){
		int l = _abs( a.val(0) ~/ lenCoef );
		_copy( a, len + 1, a, 1, l - len );
		l -= len;
		int p = _abs( a.val(0) ) & precMask;
		if( l == 0 ){
			a.set( 0, lenCoef + p ); a.set( 1, 0 ); // ゼロ値
		} else {
			a.set( 0, (l * lenCoef + p) * (a.val(0) < 0 ? -1 : 1) );
		}
	}

	// 10のprec乗の値の多倍長数データを生成する
	void _fcoef( MPData k, int prec ){
		int n = (prec ~/ digit) + 1;
		k.set( n, _pow( 10, ClipMath.imod( prec, digit ) ) );
		_fill( 0, k, 1, n - 1 );
		k.set( 0, n * lenCoef );
	}

	// 小数点以下の桁数を揃える
	int _matchPrec( MPData a, MPData b ){
		int aa = getPrec( a );
		int bb = getPrec( b );
		int p = aa, t;
		if( aa < bb ){
			if( (t = _fmul( a, bb - aa )) > 0 ){
				MPData k = MPData();
				_fcoef( k, t ); mul( a, a, k );
			}
			_setPrec( a, bb );
			p = bb;
		} else if( bb < aa ){
			if( (t = _fmul( b, aa - bb )) > 0 ){
				MPData k = MPData();
				_fcoef( k, t ); mul( b, b, k );
			}
			_setPrec( b, aa );
		}
		return p;
	}

	MPData clone( MPData a ){
		return a.clone();
	}

	void _copy( MPData src, int srcPos, MPData dst, int dstPos, int len ){
		src = clone( src );
		for( int i = 0; i < len; i++ ){
			dst.set( dstPos + i, src.val(srcPos + i) );
		}
	}

	void _fill( int value, MPData array, int pos, int len ){
		for( int i = 0; i < len; i++ ){
			array.set( pos + i, value );
		}
	}

	int _strlen( MPData array ){
		int len;
		for( len = 0; ; len++ ){
			if( array.val(len) == 0 ){
				break;
			}
		}
		return len;
	}

	MPData _d2cstr( String str ){
		MPData array = MPData( str.length + 1 );
		int i;
		for( i = 0; i < str.length; i++ ){
			array.set( i, ClipMath.charCodeAt( str, i ) );
		}
		array.set( i, 0 );
		return array;
	}

	String _c2dstr( MPData array ){
		String str = "";
		for( int i = 0; ; i++ ){
			if( array.val(i) == 0 ){
				break;
			}
			str += String.fromCharCode( array.val(i) );
		}
		return str;
	}

	// 絶対値
	void abs( MPData rop, [MPData? op] ){
		if( op == null ){ // パラメータが1つの場合
			rop.set( 0, _abs( rop.val(0) ) );
			return;
		}

		_copy( op, 1, rop, 1, getLen( op ) );
		rop.set( 0, _abs( op.val(0) ) );
	}

	// 多倍長整数同士の加算
	void add( MPData ret, MPData a, MPData b ){
		a = clone( a );
		b = clone( b );

		if( a.val(0) < 0 && b.val(0) >= 0 ){
			a.set( 0, -a.val(0) );
			sub( ret, b, a );
			return;
		} else if( a.val(0) >= 0 && b.val(0) < 0 ){
			b.set( 0, -b.val(0) );
			sub( ret, a, b );
			return;
		}
		int k = (a.val(0) < 0 && b.val(0) < 0) ? -1 : 1;

		int la = getLen( a );
		int lb = getLen( b );
		int lr = (la >= lb) ? la : lb;
		ret.set( lr + 1, 0 ); // 配列の確保

		int r = 0, aa = 0, bb = 0, x = 0;
		for( int i = 1; i <= lr; i++ ){
			if( i <= la ){ x += a.val(++aa); }
			if( i <= lb ){ x += b.val(++bb); }
			if( x < element ){
				ret.set( ++r, x );
				x = 0;
			} else {
				ret.set( ++r, x - element );
				x = 1;
			}
		}
		if( x != 0 ){
			ret.set( ++r, x );
			lr++;
		}

		_setLen( ret, lr * k );
	}

	// 多倍長整数同士の大小比較
	// aがbよりも大きい場合は正の値、小さい場合は負の値、等しい場合はゼロの値
	int cmp( MPData a, MPData b ){
		if( a.val(0) < 0 && b.val(0) >= 0 ){ return -1; }
		if( b.val(0) < 0 && a.val(0) >= 0 ){ return  1; }
		int k = (a.val(0) < 0 && b.val(0) < 0) ? -1 : 1;

		int la = getLen( a );
		int lb = getLen( b );

		int aa, bb;
		for( int i = (la > lb) ? la : lb; i > 0; i-- ){
			aa = (i <= la) ? a.val(i) : 0;
			bb = (i <= lb) ? b.val(i) : 0;
			if( aa != bb ){ return (aa - bb) * k; }
		}

		return 0;
	}

	// 多倍長整数同士の除算。商qと余りrを得る。
	// 除数bが0のときはtrueを返す。
	void _mul1( MPData q, MPData a, int b ){
		q.set( a.val(0) + 1, 0 ); // 配列の確保
		int c = 0, aa = 0, qq = 0, i, x;
		for( i = 0; i < a.val(0); i++ ){
			x = a.val(++aa) * b + c;
			q.set( ++qq, ClipMath.imod( x, element ) ); c = x ~/ element;
		}
		q.set( ++qq, c );
		q.set( 0, i ); if( c > 0 ){ q.inc(0); }
	}
	int _div1( MPData q, MPData a, int b ){
		q.set( 0, a.val(0) );
		int c = 0, aa = a.val(0), qq = q.val(0), i, x;
		for( i = a.val(0); i > 0; i-- ){
			x = element * c + a.val(aa--);
			q.set( qq--, x ~/ b ); c = ClipMath.imod( x, b );
		}
		if( q.val(q.val(0)) == 0 ){ q.dec(0); }
		return c;
	}
	void _sub1( MPData a, MPData b, int aa, int bb ){
		int c = 0, t = bb;
		for( bb = 0; bb < t; ){
			a.sub( ++aa, b.val(++bb) + c );
			c = 0;
			if( a.val(aa) < 0 ){ a.add( aa, element); c = 1; }
		}
		while( a.val(aa) == 0 ){ aa--; }
		a.set( 0, aa );
	}
	bool div( MPData q, MPData a, MPData b, [MPData? r] ){
		a = clone( a );
		b = clone( b );

		r ??= MPData();

		int k = 1;
		if( a.val(0) < 0 && b.val(0) >= 0 ){ k = -1; }
		if( b.val(0) < 0 && a.val(0) >= 0 ){ k = -1; }
		int l = (a.val(0) < 0) ? -1 : 1;

		a.set( 0, getLen( a ) );
		b.set( 0, getLen( b ) );
		q.set( 0, 0 ); r.set( 0, 0 );

		int lq, lr;
		int K;
		int Q;	// 仮商

		if( b.val(0) == 0 || (b.val(0) == 1 && b.val(1) == 0) ){ return true ; }
		if( a.val(0) == 0 || (a.val(0) == 1 && a.val(1) == 0) ){ return false; }

		if( a.val(0) < b.val(0) ){
			_copy( a, 0, r, 0, a.val(0) + 1 );
			lr = r.val(0); r.set( 0, 0 ); _setLen( r, lr * l );
			return false;
		}

		if( b.val(0) == 1 ){
			int rr = 0;
			int c = _div1( q, a, b.val(1) );
			if( c > 0 ){
				r.set( rr++, 1 );
				r.set( rr, c );
			} else {
				r.set( rr, 0 );
			}
			lq = q.val(0); q.set( 0, 0 ); _setLen( q, lq * k );
			lr = r.val(0); r.set( 0, 0 ); _setLen( r, lr * l );
			return false;
		}

		// 正規化
		if( (K = element ~/ (b.val(b.val(0)) + 1)) > 1 ){
			_mul1( a, clone( a ), K );
			_mul1( b, clone( b ), K );
		}

		q.set( 0, a.val(0) - b.val(0) + 1 );
		for( int i = q.val(0); i > 0; i-- ){ q.set( i, 0 ); }
		int n = b.val(0);
		int m;
		int aa, bb, rr;
		while( (m = a.val(0)) >= n ){
			// 仮商Qを求める
			if( a.val(a.val(0)) >= b.val(b.val(0)) ){
				aa = a.val(0);
				for( bb = b.val(0); bb > 0; aa--, bb-- ){
					if( a.val(aa) != b.val(bb) ){ break; }
				}
				if( bb == 0 ){
					a.sub( 0, b.val(0) );
					q.inc(m - n + 1);
					continue;
				} else if( a.val(aa) > b.val(bb) ){
					_sub1( a, b, m - n, bb );
					q.inc(m - n + 1);
					continue;
				}
				Q = element - 1;
			} else {
				Q = (element * a.val(a.val(0)) + a.val( a.val(0) - 1 )) ~/ b.val(b.val(0));
			}
			if( m == n ){ break; }

			while( true ){
				if( Q == 1 ){
					// a=a-b
					b.set( b.val(0) + 1, 0 );
					_sub1( a, b, a.val(0) - b.val(0) - 1, b.val(0) );
					break;
				}

				// a=a-仮商(Q)*bを求める
				_mul1( r, b, Q );
				aa = a.val(0);
				for( rr = r.val(0); rr > 0; aa--, rr-- ){
					if( a.val(aa) != r.val(rr) ){ break; }
				}
				if( rr == 0 ){
					a.sub( 0, r.val(0) );
					break;
				} else if( a.val(aa) > r.val(rr) ){
					_sub1( a, r, a.val(0) - r.val(0), rr );
					break;
				} else {
					Q--;
				}
			}
			q.set( m - n, Q );
		}
		if( q.val(q.val(0)) == 0 ){ q.dec(0); }

		if( K > 1 ){
			// 逆正規化
			_div1( r, a, K );
		} else {
			_copy( a, 0, r, 0, a.val(0) + 1 );
		}

		lq = q.val(0); q.set( 0, 0 ); _setLen( q, lq * k );
		lr = r.val(0); r.set( 0, 0 ); _setLen( r, lr * l );
		return false;
	}

	// 多倍長浮動小数点数同士の加算
	void fadd( MPData ret, MPData a, MPData b ){
		a = clone( a );
		b = clone( b );
		int p = _matchPrec( a, b );
		add( ret, a, b );
		_setPrec( ret, p );
	}

	// 多倍長浮動小数点数同士の大小比較
	// aがbよりも大きい場合は正の値、小さい場合は負の値、等しい場合はゼロの値
	int fcmp( MPData a, MPData b ){
		a = clone( a );
		b = clone( b );
		_matchPrec( a, b );
		return cmp( a, b );
	}

	// 整数部の桁数
	int fdigit( MPData a ){
		int l = getLen( a );
		if( l == 0 ){
			return 0;
		}

		int k = 10;
		int i;
		for( i = 1; i <= digit; i++ ){
			if( a.val(l) < k ){ break; }
			k *= 10;
		}
		int d = (l - 1) * digit + i;

		return d - getPrec( a );
	}

	// 多倍長浮動小数点数同士の除算
	// 除数bが0のときはtrueを返す。
	bool fdiv( MPData ret, MPData a, MPData b, int prec ){
		a = clone( a );
		b = clone( b );

		int p = _matchPrec( a, b );
		int k = b.val(0) < 0 ? -1 : 1;
		int l = getLen( b );
		int i;
		for( i = l; i > 0; i-- ){
			if( b.val(i) != 0 ){ break; }
		}
		if( i == 0 ){ return true; }
		if( i != l ){
			p -= (l - i) * digit;
			_setPrec( a, p );
			_setPrec( b, p );
			_setLen( b, i * k );
		}

		MPData q = MPData();
		MPData r = MPData();
		div( q, a, b, r );
		int t = _fmul( q, prec );
		_fmul( r, prec );
		if( t > 0 ){
			MPData k = MPData();
			_fcoef( k, t );
			mul( q, q, k );
			mul( r, r, k );
		}
		div( r, r, b );
		add( ret, q, r );
		_setPrec( ret, prec );
		return false;
	}

	// 多倍長浮動小数点数同士の除算
	// 除数bが0のときはtrueを返す。
	// digitには、被除数aの整数部の桁数が格納される。
	bool fdiv2( MPData ret, MPData a, MPData b, int prec, [ParamInteger? _digit] ){
		a = clone( a );
		b = clone( b );

		_digit ??= ParamInteger();

		int P = getPrec( a );

		/*
		 * 被除数の整数部の桁数を求める
		 */
		int l = getLen( a );
		int k = 10;
		int i;
		for( i = 1; i <= digit; i++ ){
			if( a.val(l) < k ){ break; }
			k *= 10;
		}
		_digit.set( ((l - 1) * digit + i) - P );

		if( prec < _digit.val() ){
			prec = _digit.val();
		}

		/*
		 * bb = 1 / b
		 */
		MPData bb = MPData();
		MPData aa = MPData();
		_setLen( aa, 1 ); aa.set( 1, 1 );
		int p = _matchPrec( aa, b );
		k = b.val(0) < 0 ? -1 : 1;
		l = getLen( b );
		for( i = l; i > 0; i-- ){
			if( b.val(i) != 0 ){ break; }
		}
		if( i == 0 ){ return true; }
		if( i != l ){
			p -= (l - i) * digit;
			_setPrec( aa, p );
			_setPrec( b, p );
			_setLen( b, i * k );
		}
		MPData q = MPData();
		MPData r = MPData();
		div( q, aa, b, r );
		p = prec * 2 + 1; // 精度を保つために桁数を増やす
		int t = _fmul( q, p );
		_fmul( r, p );
		if( t > 0 ){
			MPData k = MPData();
			_fcoef( k, t );
			mul( q, q, k );
			mul( r, r, k );
		}
		div( r, r, b );
		if( getLen( a ) == 1 && a.val(1) == 1 ){
			add( ret, q, r );
			if( a.val(0) < 0 ){ ret.set( 0, -ret.val(0) ); }
			_setPrec( ret, p );
			return false;
		} else {
			add( bb, q, r );
			_setPrec( bb, p );
		}

		/*
		 * ret = a * bb
		 */
		mul( ret, a, bb );
		p += P;
		int n = (p - (prec + digit)) ~/ digit;
		if( n > 0 ){
			p -= n * digit;
			_fdiv( ret, n );
		}
		_setPrec( ret, p );

		return false;
	}

	// 多倍長浮動小数点数同士の乗算
	void fmul( MPData ret, MPData a, MPData b, int prec ){
		a = clone( a );
		b = clone( b );

		mul( ret, a, b );
		int p = getPrec( a ) + getPrec( b );
		int n = (p - (prec + digit)) ~/ digit;
		if( n > 0 ){
			p -= n * digit;
			_fdiv( ret, n );
		}
		_setPrec( ret, p );
	}

	// 多倍長浮動小数点数を文字列に変換する
	void _fnum2str( MPData s, MPData n, [int? prec] ){
		n = clone( n );

		int p = getPrec( n );
		MPData ss = MPData();
		_num2str( ss, n );
		int l = _strlen( ss );
		int i;

		for( i = l - 1; i > 0; i-- ){
			if( ss.val(i) != ClipMath.charCode0 ){
				break;
			}
		}
		p -= l - (i + 1);
		if( p < 0 ){
			i -= p; p = 0;
		}
		l = i + 1;

		int j = 0, k = 0;
		bool pp = false;
		if( ss.val(0) == ClipMath.char( '-' ) ){
			s.set( j++, ss.val(k++) );
			l--;
		}
		if( l <= p ){
			s.set( j++, ClipMath.charCode0 );
		}
		if( l < p ){
			s.set( j++, ClipMath.char( '.' ) );
			pp = true;
			for( i = 0; i < p - l; i++ ){
				if( prec != null ) {
					prec--;
					if (prec < 0) {
						break;
					}
				}
				s.set( j++, ClipMath.charCode0 );
			}
		}
		for( i = 0; i < l; i++ ){
			if( i == l - p ){
				s.set( j++, ClipMath.char( '.' ) );
				pp = true;
			}
			if( pp ){
				if( prec != null ) {
					prec--;
					if (prec < 0) {
						break;
					}
				}
			}
			s.set( j++, ss.val(k++) );
		}
		s.set( j, 0 );
	}
	String fnum2str( MPData n, [int? prec] ){
		MPData array = MPData();
		_fnum2str( array, n, prec );
		return _c2dstr( array );
	}

	// 丸め演算
	// modeを省略すると、froundHalfEvenの動作になる。
	static const int froundUp        = 0; // ゼロから離れるように丸める
	static const int froundDown      = 1; // ゼロに近づくように丸める
	static const int froundCeiling   = 2; // 正の無限大に近づくように丸める
	static const int froundFloor     = 3; // 負の無限大に近づくように丸める
	static const int froundHalfUp    = 4; // 四捨五入する
	static const int froundHalfDown  = 5; // 五捨六入する
	static const int froundHalfEven  = 6; // n桁で丸める場合のn桁目の数値が奇数の場合はfroundHalfUp、偶数の場合はfroundHalfDown
	static const int froundHalfDown2 = 7; // 五捨五超入する
	static const int froundHalfEven2 = 8; // n桁で丸める場合のn桁目の数値が奇数の場合はfroundHalfUp、偶数の場合はfroundHalfDown2
	int _froundGet( MPData a, int n ){
		int l = getLen( a );
		int nn = 1 + (n ~/ digit);
		if( nn > l ){
			return 0;
		}
		return ClipMath.imod( a.val(nn) ~/ _pow( 10, ClipMath.imod( n, digit ) ), 10 );
	}
	void _froundSet( MPData a, int n, int val ){
		int nn = 1 + (n ~/ digit);
		int aa = a.val(nn); int b = 0; int k = 1;
		n = ClipMath.imod( n, digit );
		for( int i = 0; i < digit; i++ ){
			if( i == n ){
				b += val * k;
			} else if( i > n ){
				b += ClipMath.imod( aa, 10 ) * k;
			}
			aa = aa ~/ 10; k *= 10;
		}
		a.set( nn, b );
	}
	void _froundZero( MPData a, int n ){
		_fill( 0, a, 1, n ~/ digit );
	}
	void _froundUp( MPData a, int n ){
		int l = getLen( a );
		int aa;
		while( true ){
			aa = _froundGet( a, n ) + 1;
			_froundSet( a, n, ClipMath.imod( aa, 10 ) );
			if( aa < 10 ){
				break;
			}
			n++;
			if( (1 + (n ~/ digit)) > l ){
				l++;
				_setLen( a, l * (a.val(0) < 0 ? -1 : 1) );
				a.set( l, 0 );
			}
		}
	}
	bool _froundIsNotZero( MPData a, int n ){
		int nn = 1 + (n ~/ digit);
		if( ClipMath.imod( a.val(nn), _pow( 10, ClipMath.imod( n, digit ) ) ) != 0 ){
			return true;
		} else {
			for( nn--; nn > 0; nn-- ){
				if( a.val(nn) != 0 ){ return true; }
			}
		}
		return false;
	}
	void fround( MPData a, int prec, [int? mode] ){
		int n = getPrec( a ) - prec;
		if( n < 1 ){
			return;
		}
		int aa = _froundGet( a, n - 1 );
		bool u = false;
		bool uu = false;

		mode ??= froundHalfEven; // パラメータが2つの場合
		switch( mode ){
		case froundUp:
			uu = true;
			break;
		case froundDown:
			break;
		case froundCeiling:
			if( a.val(0) > 0 ){ uu = true; }
			break;
		case froundFloor:
			if( a.val(0) < 0 ){ uu = true; }
			break;
		case froundHalfUp:
			if( aa > 4 ){ u = true; }
			break;
		case froundHalfDown:
			if( aa > 5 ){ u = true; }
			break;
		case froundHalfEven:
			if( ClipMath.imod( _froundGet( a, n ), 2 ) == 1 ){
				if( aa > 4 ){ u = true; }
			} else {
				if( aa > 5 ){ u = true; }
			}
			break;
		case froundHalfEven2:
			if( mode == froundHalfEven2 && ClipMath.imod( _froundGet( a, n ), 2 ) == 1 && aa > 4 ){
				u = true;
				break;
			}
			// そのまま下に流す
			continue caseFroundHalfDown2;
		caseFroundHalfDown2:
		case froundHalfDown2:
			if( aa > 5 ){
				u = true;
			} else if( aa == 5 && n > 1 ){
				u = _froundIsNotZero( a, n - 2 );
			}
			break;
		}

		if( uu ){
			if( aa > 0 ){
				u = true;
			} else if( n > 1 ){
				u = _froundIsNotZero( a, n - 2 );
			}
		}

		if( u ){
			_froundZero( a, n );
			_froundUp( a, n );
		} else {
			_froundZero( a, n - 1 );
			_froundSet( a, n - 1, 0 );
		}
	}

	// 多倍長浮動小数点数の平方根
	// aが負の値の場合trueを返す。
	bool fsqrt( MPData ret, MPData a, int prec ){
		a = clone( a );
		if( fcmp( a, F( "0" ) ) > 0 ){
			MPData l = MPData();
			MPData s = MPData();
			MPData t = MPData();
			if( fcmp( a, F( "1" ) ) > 0 ){
				set( s, a );
			} else {
				set( s, F( "1" ) );
			}
			do {
				set( l, s );
				fdiv2( t, a, s, prec );
				fadd( t, t, s );
				fmul( t, t, F( "0.5" ), prec );
				set( s, t );
			} while( fcmp( s, l ) < 0 );
			set( ret, l );
			return false;
		}
		set( ret, F( "0" ) );
		return (fcmp( a, F( "0" ) ) != 0);
	}

	// 多倍長浮動小数点数の平方根
	// aが負の値の場合trueを返す。
	bool fsqrt2( MPData ret, MPData a, int prec, int order ){
		a = clone( a );
		if( fcmp( a, F( "0" ) ) > 0 ){
			MPData g = MPData();
			MPData h = MPData();
			MPData m = MPData();
			MPData n = MPData();
			MPData o = MPData();
			MPData p = MPData();
			MPData q = MPData();
			MPData r = MPData();
			MPData s = MPData();
			MPData t = MPData();
			MPData x = MPData();
			if( fcmp( a, F( "1" ) ) > 0 ){
				fdiv( t, F( "1" ), a, prec );
				set( x, t );
			} else {
				set( x, F( "1" ) );
			}
			fmul( t, x, x, prec );
			fmul( t, a, t, prec );
			fsub( h, F( "1" ), t );
			set( g, F( "1" ) );
			fdiv( m, F( "1" ), F( "2" ), prec );
			if( order >= 3 ){ fdiv( n, F( "3"  ), F( "8"   ), prec ); }
			if( order >= 4 ){ fdiv( o, F( "5"  ), F( "16"  ), prec ); }
			if( order >= 5 ){ fdiv( p, F( "35" ), F( "128" ), prec ); }
			if( order == 6 ){ fdiv( q, F( "63" ), F( "256" ), prec ); }
			do {
				switch( order ){
				case 6 : set( t, q ); break;
				case 5 : set( t, p ); break;
				case 4 : set( t, o ); break;
				case 3 : set( t, n ); break;
				default: set( t, m ); break;
				}
				switch( order ){
				case 6:
					fmul( t, h, t, prec );
					fadd( t, p, t );
					// そのまま下に流す
					continue case_5;
				case_5:
				case 5:
					fmul( t, h, t, prec );
					fadd( t, o, t );
					// そのまま下に流す
					continue case_4;
				case_4:
				case 4:
					fmul( t, h, t, prec );
					fadd( t, n, t );
					// そのまま下に流す
					continue case_3;
				case_3:
				case 3:
					fmul( t, h, t, prec );
					fadd( t, m, t );
				}
				fmul( t, h, t, prec );
				fmul( t, x, t, prec );
				fadd( x, x, t );
				set( g, h );
				fmul( t, x, x, prec );
				fmul( t, a, t, prec );
				fsub( h, F( "1" ), t );
				abs( r, h );
				abs( s, g );
			} while( fcmp( r, s ) < 0 );
			fmul( ret, a, x, prec );
			return false;
		}
		set( ret, F( "0" ) );
		return (fcmp( a, F( "0" ) ) != 0);
	}

	// 多倍長浮動小数点数の平方根
	// aが負の値の場合trueを返す。
	bool fsqrt3( MPData ret, MPData a, int prec ){
		a = clone( a );
		int t = prec * 2 - getPrec( a );
		int u;
		if( t > 0 ){
			if( (u = _fmul( a, t )) > 0 ){
				MPData k = MPData();
				_fcoef( k, u ); mul( a, a, k );
			}
		} else if( t < 0 ){
			u = _abs( t );
			int n;
			if( (n = u ~/ digit) > 0 ){
				u -= n * digit;
				_fdiv( a, n );
			}
			MPData k = MPData();
			_fcoef( k, u ); div( a, a, k );
		}
		if( a.val(getLen( a )) == 0 ){
			_setLen( a, getLen( a ) - 1 );
		}
		bool r = sqrt( ret, a );
		_setPrec( ret, prec );
		return r;
	}

	// 文字列を多倍長浮動小数点数に変換する
	bool fstr2num( MPData n, String _s ){
		MPData s = _d2cstr( _s );

		int l = _strlen( s );
		int i, j = 0;
		int p = 0;
		bool m = false;
		MPData ss = MPData();
		for( i = 0; i < l; i++ ){
			if( (s.val(i) == ClipMath.char( 'e' )) || (s.val(i) == ClipMath.char( 'E' )) ){
				if( p != 0 ){
					p -= l - i;
				}
				i++;
				if( s.val(i) == ClipMath.char( '-' ) ){
					m = true;
					i++;
				} else {
					m = false;
					if( s.val(i) == ClipMath.char( '+' ) ){
						i++;
					}
				}
				break;
			} else if( s.val(i) == ClipMath.char( '.' ) ){
				p = l - (i + 1);
			} else {
				ss.set( j++, s.val(i) );
			}
		}
		ss.set( j, 0 ); // 文字列終端を書き込む
		if( !_str2num( n, ss ) ){
			return false;
		}

		int e = 0;
		for( ; i < l; i++ ){
			if( s.val(i) >= ClipMath.charCode0 && s.val(i) <= ClipMath.charCode9 ){
				e = e * 10 + (s.val(i) - ClipMath.charCode0);
			} else {
				return false;
			}
		}
		if( m ){
			p += e; e = 0;
		} else if( p >= e ){
			p -= e; e = 0;
		} else {
			e -= p; p = 0;
		}

		_setPrec( n, p );

		if( e > 0 ){
			MPData k = MPData();
			_fcoef( k, e );
			fmul( n, n, k, p );
		}

		return true;
	}

	// 多倍長浮動小数点数同士の減算
	void fsub( MPData ret, MPData a, MPData b ){
		a = clone( a );
		b = clone( b );
		int p = _matchPrec( a, b );
		sub( ret, a, b );
		_setPrec( ret, p );
	}

	// 小数点以下の切り捨て
	void ftrunc( MPData rop, MPData op ){
		op = clone( op );
		int p = getPrec( op );
		int n = p ~/ digit;
		if( n > 0 ){
			p -= n * digit;
			_fdiv( op, n );
		}
		MPData k = MPData();
		_fcoef( k, p );
		div( rop, op, k );
	}

	// 多倍長整数同士の乗算
	int _mul1n( MPData ret, MPData a, int b, int n ){
		ret.set( n + 1, 0 ); // 配列の確保
		int c = 0, aa = 0, r = 0, i, x;
		for( i = 0; i < n; i++ ){
			x = a.val(++aa) * b + c;
			ret.set( ++r, ClipMath.imod( x, element ) ); c = x ~/ element;
		}
		ret.set( ++r, c );
		return c;
	}
	void mul( MPData ret, MPData a, MPData b ){
		a = clone( a );
		b = clone( b );

		int k = 1;
		if( a.val(0) < 0 && b.val(0) >= 0 ){ k = -1; }
		if( b.val(0) < 0 && a.val(0) >= 0 ){ k = -1; }

		int la = getLen( a );
		int lb = getLen( b );

		if( la == 0 || lb == 0 ){
			ret.set( 0, 0 );
			return;
		}

		int c = 0;
		if( la == 1 ){
			c = _mul1n( ret, b, a.val(1), lb );
		} else if( lb == 1 ){
			c = _mul1n( ret, a, b.val(1), la );
		} else {
			_fill( 0, ret, 1, la + lb );
			int aa, bb = 0;
			int i, j, x;
			for( j = 1; j <= lb; j++ ){
				c = 0;
				bb++;
				aa = 0;
				for( i = 1; i <= la; i++ ){
					x = a.val(++aa) * b.val(bb) + ret.val(i + j - 1) + c;
					ret.set( i + j - 1, ClipMath.imod( x, element ) );
					c = x ~/ element;
				}
				ret.set( i + j - 1, c );
			}
		}

		_setLen( ret, (c != 0 ? la + lb : la + lb - 1) * k );
	}

	// 符号反転
	void neg( MPData rop, [MPData? op] ){
		if( op == null ){ // パラメータが1つの場合
			rop.set( 0, -rop.val(0) );
			return;
		}

		_copy( op, 1, rop, 1, getLen( op ) );
		rop.set( 0, -op.val(0) );
	}

	// 多倍長整数を文字列に変換する
	void _num2str( MPData s, MPData n ){
		n = clone( n );

		bool m = (n.val(0) < 0);

		int n0 = n.val(0);
		n.set( 0, getLen( n ) );
		if( n.val(0) == 0 ){
			s.set( 0, ClipMath.charCode0 );
			s.set( 1, 0 ); // 文字列終端

			n.set( 0, n0 );
			return;
		}

		int ss = -1; int nn = 0;
		int i, j, x;
		for( i = n.val(0); i > 0; i-- ){
			x = n.val(++nn);
			for( j = 0; j < digit; j++ ){
				s.set( ++ss, ClipMath.imod( x, 10 ) + ClipMath.charCode0 ); x = x ~/ 10;
			}
		}
		while( s.val(ss) == ClipMath.charCode0 ){
			if( --ss < 0 ){
				ss = 0;
				break;
			}
		}
		if( m ){ s.set( ++ss, ClipMath.char( '-' ) ); }
		s.set( ss + 1, 0 ); // 文字列終端

		int t = 0;
		while( t < ss ){
			x = s.val(t); s.set( t++, s.val(ss) ); s.set( ss--, x );
		}

		n.set( 0, n0 );
	}
	String num2str( MPData n ){
		MPData array = MPData();
		_num2str( array, n );
		return _c2dstr( array );
	}

	// 代入
	void set( MPData rop, MPData op ){
		_copy( op, 0, rop, 0, getLen( op ) + 1 );
	}

	// 多倍長整数の平方根
	// aが負の値の場合trueを返す。
	bool sqrt( MPData x, MPData a ){
		a = clone( a );

		_setLen( x, 0 );
		if( a.val(0) < 0 ){ return true; }
		int la = getLen( a );
		if( la == 0 ){ return false; }
		if( la == 1 ){
			_setLen( x, 1 );
			x.set( 1, ClipMath.sqrt( a.val(1).toDouble() ).toInt() );
			return false;
		}
		if( la == 2 ){
			_setLen( x, 1 );
			x.set( 1, ClipMath.sqrt( (a.val(2) * element + a.val(1)).toDouble() ).toInt() );
			return false;
		}

		int l = (la + 1) ~/ 2;
		MPData b = MPData();
		b.set( l + 1, 0 ); // 配列の確保
		_fill( 0, x, 1, l );
		_fill( 0, b, 1, l );
		_setLen( x, l );
		_setLen( b, l );

		// 最上位桁の平方数を求める
		int i = (l - 1) * 2 + 1;
		int aa = a.val(i);
		if( ClipMath.imod( la, 2 ) == 0 ){
			aa += a.val(i + 1) * element;
		}
		x.set( l, ClipMath.sqrt( aa.toDouble() ).toInt() );

		// 初回のaとbが求まる
		b.set( l, x.val(l) + x.val(l) );
		if( b.val(l) >= element ){
			b.sub( l, element );
			b.set( l + 1, 1 );
			_setLen( b, l + 1 );
		}
		MPData w = MPData();
		mul( w, x, x );
		sub( a, a, w );
		l--;

		MPData q = MPData();
		MPData r = MPData();
		while( true ){
			div( q, a, b, r ); // 仮値Q
			if( l > 1 ){
				_fill( 0, q, 1, l - 1 );
			}
			if( getLen( q ) > l ){
				q.set( l, element - 1 );
				_setLen( q, l );
			}
			while( true ){
				add( r, b, q );
				mul( w, r, q );
				if( cmp( w, a ) <= 0 ){
					break;
				}
				q.dec(l); // 仮値Qを下げる
			}
			x.set( l, q.val(l) );
			if( l == 1 ){
				break;
			}

			// 次のaとbが求まる
			add( b, r, q );
			sub( a, a, w );
			l--;
		}
		return false;
	}

	// 文字列を多倍長整数に変換する
	bool _str2num( MPData n, MPData s ){
		int m = (s.val(0) == ClipMath.char( '-' )) ? 1 : 0;
		int ss = m;
		while( s.val(ss) >= ClipMath.charCode0 && s.val(ss) <= ClipMath.charCode9 ){ ss++; }
		if( s.val(ss) != 0 ){
			return false;
		}
		if( ss == 0 ){
			n.set( 0, 0 );
			return true;
		}

		int x = 0, k = 1;
		int nn = 0;
		do {
			x += (s.val(--ss) - ClipMath.charCode0) * k; k *= 10;
			if( k == element ){
				n.set( ++nn, x );
				x = 0; k = 1;
			}
		} while( ss > m );
		if( k > 1 ){
			n.set( ++nn, x );
		}

		_setLen( n, (m == 1) ? -nn : nn );

		return true;
	}
	bool str2num( MPData n, String s ){
		return _str2num( n, _d2cstr( s ) );
	}

	// 多倍長整数同士の減算
	void _sub( MPData ret, MPData a, MPData b ){
		int la = getLen( a );
		int lb = getLen( b );
		ret.set( la, 0 ); // 配列の確保

		int r = 0, aa = 0, bb = 0, x = 0;
		int i;
		for( i = 1; i <= la; i++ ){
			x += a.val(++aa);
			if( i <= lb ){
				x -= b.val(++bb);
			}
			if( x >= 0 ){
				ret.set( ++r, x );
				x = 0;
			} else {
				ret.set( ++r, x + element );
				x = -1;
			}
		}
		while( --i > 0 ){
			if( ret.val(r--) != 0 ){
				break;
			}
		}

		_setLen( ret, i );
	}
	void sub( MPData ret, MPData a, MPData b ){
		a = clone( a );
		b = clone( b );

		if( a.val(0) < 0 && b.val(0) >= 0 ){
			b.set( 0, -b.val(0) );
			add( ret, a, b );
			return;
		} else if( a.val(0) >= 0 && b.val(0) < 0 ){
			b.set( 0, -b.val(0) );
			add( ret, a, b );
			return;
		} else if( a.val(0) < 0 && b.val(0) < 0 ){
			a.set( 0, -a.val(0) );
			b.set( 0, -b.val(0) );
			sub( ret, b, a );
			return;
		}

		if( cmp( a, b ) < 0 ){
			_sub( ret, b, a );
			ret.set( 0, -ret.val(0) );
		} else {
			_sub( ret, a, b );
		}
	}
}
