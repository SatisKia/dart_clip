/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import 'global.dart';
import 'label.dart';
import 'math/value.dart';

// 変数管理クラス
class ClipVariable {
	late ClipLabel _label;

	late List<MathValue> _var;
	late List<bool> _lock;

	ClipVariable(){
		_label = ClipLabel( this );

		_var  = MathValue.newArray( 256 );
		_lock = List.filled( 256, false );
	}

	ClipLabel label(){ return _label; }

	// 動的変数を定義する
	int define( String? label, dynamic value, bool lockFlag ){
		int index;
		if( (index = _label.define( label )) >= 0 ){
			// 値を代入する
			set( index, value, false );
			if( lockFlag ){
				lock( index );
			}
		}
		return index;
	}

	// 定義を削除する
	int undef( String? label ){
		int index;
		if( (index = _label.undef( label )) >= 0 ){
			// 値を初期化する
			unlock( index );
			set( index, 0.0, false );
		}
		return index;
	}

	void move( int index ){
		if( _label.flag(index) == ClipGlobal.labelMovable ){
			// 動的変数の実体を移す
			define( _label.label( index )!, val( index ), isLocked( index ) );
			unlock( index );

			_label.setLabel( index, null, false );
		}
		_label.setFlag( index, ClipGlobal.labelUsed );
	}

	// 値を代入する
	bool set( int index, dynamic value, bool moveFlag ){
		if( isLocked( index ) ){
			return false;
		}
		if( moveFlag ){
			move( index );
		}
		_var[index].ass( value );
		return true;
	}
	bool setReal( int index, double value, bool moveFlag ){
		if( isLocked( index ) ){
			return false;
		}
		if( moveFlag ){
			move( index );
		}
		_var[index].setReal( value );
		return true;
	}
	bool setImag( int index, double value, bool moveFlag ){
		if( isLocked( index ) ){
			return false;
		}
		if( moveFlag ){
			move( index );
		}
		_var[index].setImag( value );
		return true;
	}
	bool fractSetMinus( int index, bool isMinus, bool moveFlag ){
		if( isLocked( index ) ){
			return false;
		}
		if( moveFlag ){
			move( index );
		}
		_var[index].fractSetMinus( isMinus );
		return true;
	}
	bool setNum( int index, double value, bool moveFlag ){
		if( isLocked( index ) ){
			return false;
		}
		if( moveFlag ){
			move( index );
		}
		_var[index].setNum( value );
		return true;
	}
	bool setDenom( int index, double value, bool moveFlag ){
		if( isLocked( index ) ){
			return false;
		}
		if( moveFlag ){
			move( index );
		}
		_var[index].setDenom( value );
		return true;
	}
	bool fractReduce( int index, bool moveFlag ){
		if( isLocked( index ) ){
			return false;
		}
		if( moveFlag ){
			move( index );
		}
		_var[index].fractReduce();
		return true;
	}

	// 値を確認する
	MathValue val( int index ){
		return _var[index];
	}

	// 置き換え
	bool rep( int index, MathValue value, bool moveFlag ){
		if( isLocked( index ) ){
			return false;
		}
		if( moveFlag ){
			move( index );
		}
		_var[index] = value;
		return true;
	}

	// ロックする
	void lock( int index ){
		_lock[index] = true;
	}
	void unlock( int index ){
		_lock[index] = false;
	}

	// ロックされているかどうか確認する
	bool isLocked( int index ){
		return _lock[index];
	}
}
