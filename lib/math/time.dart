/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import '../param/boolean.dart';
import '../param/float.dart';
import 'math.dart';

// 時間
class MathTime {
	late double _fps;
	late bool   _minus;
	late double _hour;
	late double _min;
	late double _sec;
	late double _frame;

	MathTime( [bool i = false, double h = 0.0, double m = 0.0, double s = 0.0, double f = 0.0] ){
		_fps   = ClipMath.timeFps(); // 秒間フレーム数（ローカル）
		_minus = i; // 負かどうかのフラグ
		_hour  = h; // 時
		_min   = m; // 分
		_sec   = s; // 秒
		_frame = f; // フレーム数
	}

	void _update(){
		if( ClipMath.timeFps() != _fps ){
			_frame = _frame * ClipMath.timeFps() / _fps;
			_fps = ClipMath.timeFps();
			reduce();
		}
	}

	void _reduce1(){
		double _m, _s, _f;
		ParamFloat _int = ParamFloat();

		// 時の小数部を取り除く
		_m = ClipMath.modf( _hour, _int );
		_hour = _int.val();
		_min += _m * 60.0;

		// 分の小数部を取り除く
		_s = ClipMath.modf( _min, _int );
		_min = _int.val();
		_sec += _s * 60.0;

		// 秒の小数部を取り除く
		_f = ClipMath.modf( _sec, _int );
		_sec = _int.val();
		_frame += _f * _fps;
	}
	void _reduce2(){
		double _s, _m, _h;

		// フレームを秒間フレーム数未満の値にする
		_s = ClipMath.toInt( _frame / _fps );
		if( (_frame < 0.0) && ((_frame - _s * _fps) != 0.0) ){
			_s -= 1.0;
		}
		_sec   += _s;
		_frame -= _s * _fps;

		// 秒を60未満の値にする
		_m = ClipMath.toInt( _sec / 60.0 );
		if( (_sec < 0.0) && (ClipMath.fmod( _sec, 60.0 ) != 0.0) ){
			_m -= 1.0;
		}
		_min += _m;
		_sec -= _m * 60.0;

		// 分を60未満の値にする
		_h = ClipMath.toInt( _min / 60.0 );
		if( (_min < 0.0) && (ClipMath.fmod( _min, 60.0 ) != 0.0) ){
			_h -= 1.0;
		}
		_hour += _h;
		_min  -= _h * 60.0;

		// 時が正の値になるまで繰り返す
		if( _hour < 0.0 ){
			_minus = _minus ? false : true;
			_hour  = -_hour;
			_min   = -_min;
			_sec   = -_sec;
			_frame = -_frame;
			_reduce2();
		}
	}
	void reduce(){
		_reduce1();
		_reduce2();
	}

	void _set( double x ){
		_fps = ClipMath.timeFps();
		if( x < 0.0 ){
			_minus = true;
			x = -x;
		} else {
			_minus = false;
		}
		_hour  = ClipMath.div( x, 3600 ); x -= ClipMath.toInt( _hour ) * 3600;
		_min   = ClipMath.div( x,   60 ); x -= ClipMath.toInt( _min  ) *   60;
		_sec   = ClipMath.toInt( x       );
		_frame = (x - _sec) * _fps;
	}

	// 設定
	void setMinus( bool i ){
		_minus = i;
	}
	void setHour( double h ){
		_hour = h;
	}
	void setMin( double m ){
		_min = m;
	}
	void setSec( double s ){
		_sec = s;
	}
	void setFrame( double f ){
		_frame = f;
	}

	// 確認
	double fps(){
		return _fps;
	}
	bool getMinus(){
		return _minus;
	}
	double hour(){
		return _hour;
	}
	double min(){
		return _min;
	}
	double sec(){
		return _sec;
	}
	double calcHour(){
		return _hour + (_min / 60.0) + ((_sec + _frame / _fps) / 3600.0);
	}
	double calcMin(){
		return _min + ((_sec + _frame / _fps) / 60.0);
	}
	double calcSec(){
		return _sec + _frame / _fps;
	}
	double frame(){
		return _frame;
	}

	// 型変換
	double toFloat(){
		if( _minus ){
			return -(_hour * 3600.0 + _min * 60.0 + _sec + _frame / _fps);
		}
		return _hour * 3600.0 + _min * 60.0 + _sec + _frame / _fps;
	}

	// 代入
	MathTime ass( dynamic r ){
		if( r is MathTime ){
			_fps   = r._fps;
			_minus = r._minus;
			_hour  = r._hour;
			_min   = r._min;
			_sec   = r._sec;
			_frame = r._frame;
			_update();
		} else {
			_set( ClipMath.toDouble(r) );
		}
		return this;
	}

	// 単項マイナス
	MathTime minus(){
		return MathTime( _minus ? false : true, _hour, _min, _sec, _frame );
	}

	// 加算
	MathTime add( dynamic r ){
		if( r is MathTime ){
			if( _minus != r._minus ){
				// this - -r
				return sub( r.minus() );
			}
			MathTime ll = dup( this );
			ll._update();
			MathTime rr = dup( r );
			rr._update();
			MathTime t = MathTime(
				ll._minus,
				ll._hour  + rr._hour,
				ll._min   + rr._min,
				ll._sec   + rr._sec,
				ll._frame + rr._frame
				);
			t.reduce();
			return t;
		}
		double rr = ClipMath.toDouble(r);
		if( _minus != (rr < 0.0) ){
			// this - -rr
			return sub( -rr );
		}
		MathTime ll = dup( this );
		ll._update();
		MathTime rrr = floatToTime( rr );
		MathTime t = MathTime(
			ll._minus,
			ll._hour  + rrr._hour,
			ll._min   + rrr._min,
			ll._sec   + rrr._sec,
			ll._frame + rrr._frame
			);
		t.reduce();
		return t;
	}
	MathTime addAndAss( dynamic r ){
		if( r is MathTime ){
			if( _minus != r._minus ){
				// this -= -r
				subAndAss( r.minus() );
			} else {
				_update();
				MathTime rr = dup( r );
				rr._update();
				_hour  += rr._hour;
				_min   += rr._min;
				_sec   += rr._sec;
				_frame += rr._frame;
				reduce();
			}
		} else {
			double rr = ClipMath.toDouble(r);
			if( _minus != (rr < 0.0) ){
				// this -= -rr
				subAndAss( -rr );
			} else {
				_update();
				MathTime rrr = floatToTime( rr );
				_hour  += rrr._hour;
				_min   += rrr._min;
				_sec   += rrr._sec;
				_frame += rrr._frame;
				reduce();
			}
		}
		return this;
	}

	// 減算
	MathTime sub( dynamic r ){
		if( r is MathTime ){
			if( _minus != r._minus ){
				// this + -r
				return add( r.minus() );
			}
			MathTime ll = dup( this );
			ll._update();
			MathTime rr = dup( r );
			rr._update();
			MathTime t = MathTime(
				ll._minus,
				ll._hour  - rr._hour,
				ll._min   - rr._min,
				ll._sec   - rr._sec,
				ll._frame - rr._frame
				);
			t.reduce();
			return t;
		}
		double rr = ClipMath.toDouble(r);
		if( _minus != (rr < 0.0) ){
			// this + -rr
			return add( -rr );
		}
		MathTime ll = dup( this );
		ll._update();
		MathTime rrr = floatToTime( rr );
		MathTime t = MathTime(
			ll._minus,
			ll._hour  - rrr._hour,
			ll._min   - rrr._min,
			ll._sec   - rrr._sec,
			ll._frame - rrr._frame
			);
		t.reduce();
		return t;
	}
	MathTime subAndAss( dynamic r ){
		if( r is MathTime ){
			if( _minus != r._minus ){
				// this += -r
				addAndAss( r.minus() );
			} else {
				_update();
				MathTime rr = dup( r );
				rr._update();
				_hour  -= rr._hour;
				_min   -= rr._min;
				_sec   -= rr._sec;
				_frame -= rr._frame;
				reduce();
			}
		} else {
			double rr = ClipMath.toDouble(r);
			if( _minus != (rr < 0.0) ){
				// this += -rr
				addAndAss( -rr );
			} else {
				_update();
				MathTime rrr = floatToTime( rr );
				_hour  -= rrr._hour;
				_min   -= rrr._min;
				_sec   -= rrr._sec;
				_frame -= rrr._frame;
				reduce();
			}
		}
		return this;
	}

	// 乗算
	MathTime mul( dynamic r ){
		if( r is MathTime ){
			MathTime ll = dup( this );
			ll._update();
			double rr = r.toFloat();
			MathTime t = MathTime(
				ll._minus,
				ll._hour  * rr,
				ll._min   * rr,
				ll._sec   * rr,
				ll._frame * rr
				);
			t.reduce();
			return t;
		}
		double rr = ClipMath.toDouble(r);
		MathTime ll = dup( this );
		ll._update();
		MathTime t = MathTime(
			ll._minus,
			ll._hour  * rr,
			ll._min   * rr,
			ll._sec   * rr,
			ll._frame * rr
			);
		t.reduce();
		return t;
	}
	MathTime mulAndAss( dynamic r ){
		_update();
		if( r is MathTime ){
			double rr = r.toFloat();
			_hour  *= rr;
			_min   *= rr;
			_sec   *= rr;
			_frame *= rr;
		} else {
			double rr = ClipMath.toDouble(r);
			_hour  *= rr;
			_min   *= rr;
			_sec   *= rr;
			_frame *= rr;
		}
		reduce();
		return this;
	}

	// 除算
	MathTime div( dynamic r ){
		if( r is MathTime ){
			MathTime ll = dup( this );
			ll._update();
			double rr = r.toFloat();
			MathTime t = MathTime(
				ll._minus,
				ll._hour  / rr,
				ll._min   / rr,
				ll._sec   / rr,
				ll._frame / rr
				);
			t.reduce();
			return t;
		}
		double rr = ClipMath.toDouble(r);
		MathTime ll = dup( this );
		ll._update();
		MathTime t = MathTime(
			ll._minus,
			ll._hour  / rr,
			ll._min   / rr,
			ll._sec   / rr,
			ll._frame / rr
			);
		t.reduce();
		return t;
	}
	MathTime divAndAss( dynamic r ){
		_update();
		if( r is MathTime ){
			double rr = r.toFloat();
			_hour  /= rr;
			_min   /= rr;
			_sec   /= rr;
			_frame /= rr;
		} else {
			double rr = ClipMath.toDouble(r);
			_hour  /= rr;
			_min   /= rr;
			_sec   /= rr;
			_frame /= rr;
		}
		reduce();
		return this;
	}

	// 剰余
	MathTime mod( dynamic r ){
		if( r is MathTime ){
			return floatToTime( ClipMath.fmod( toFloat(), r.toFloat() ) );
		}
		return floatToTime( ClipMath.fmod( toFloat(), ClipMath.toDouble(r) ) );
	}
	MathTime modAndAss( dynamic r ){
		if( r is MathTime ){
			_set( ClipMath.fmod( toFloat(), r.toFloat() ) );
		} else {
			_set( ClipMath.fmod( toFloat(), ClipMath.toDouble(r) ) );
		}
		return this;
	}

	// 等値
	bool equal( dynamic r ){
		if( r is MathTime ){
			return toFloat() == r.toFloat();
		}
		return toFloat() == ClipMath.toDouble(r);
	}
	bool notEqual( dynamic r ){
		if( r is MathTime ){
			return toFloat() != r.toFloat();
		}
		return toFloat() != ClipMath.toDouble(r);
	}

	static void getTime( MathTime t, ParamFloat fps, ParamBoolean minus, ParamFloat hour, ParamFloat min, ParamFloat sec, ParamFloat frame ){
		fps  .set( t._fps   );
		minus.set( t._minus );
		hour .set( t._hour  );
		min  .set( t._min   );
		sec  .set( t._sec   );
		frame.set( t._frame );
	}
	static MathTime setTime( MathTime t, double fps, bool minus, double hour, double min, double sec, double frame ){
		t._fps   = fps;
		t._minus = minus;
		t._hour  = hour;
		t._min   = min;
		t._sec   = sec;
		t._frame = frame;
		return t;
	}

	static MathTime dup( MathTime x ){
		return setTime( MathTime(), x._fps, x._minus, x._hour, x._min, x._sec, x._frame );
	}

	static MathTime floatToTime( double x ){
		return MathTime().ass( x );
	}
}
