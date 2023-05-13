/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import 'math.dart';
import 'value.dart';

// 行列
class MathMatrix {
	late int _row;
	late int _col;
	late int _len;
	late List<MathValue> _mat;

	MathMatrix( [int row = 1, int col = 1] ){
		_row = row; // 行数
		_col = col; // 列数
		_len = _row * _col; // 行×列をあらかじめ計算した値
		_mat = MathValue.newArray( _len + 1/*番人*/ );
	}

	// 行列のサイズ変更
	void resize( int row, int col ){
		// サイズが同じ場合、何もしない
		if( (row == _row) && (col == _col) ){
			return;
		}

		if( (_len = row * col) > 0 ){
			int i, j;

			List<MathValue> mat = MathValue.newArray( _len + 1/*番人*/ );

			// 既存データをコピーする
			int m = (row < _row) ? row : _row;
			int n = (col < _col) ? col : _col;
			for( i = 0; i < m; i++ ){
				for( j = 0; j < n; j++ ){
//					copyValue( mat[i * col + j], _val( i, j ) );
					mat[i * col + j] = _val( i, j );
				}
			}

			_mat = mat;
			_row = row;
			_col = col;
		} else {
			// 元に戻す
			_len = _row * _col;
		}
	}
	void _resize( MathMatrix ini ){
		if( ini._len > _len ){
			_mat = MathValue.newArray( ini._len + 1/*番人*/ );
		} else {
			// 番人
			MathValue.copy( _mat[ini._len], _mat[_len] );
		}
		_row = ini._row;
		_col = ini._col;
		_len = ini._len;
	}
	void _resize1(){
		if( _len > 1 ){
			// 番人
			MathValue.copy( _mat[1], _mat[_len] );

			_row = 1;
			_col = 1;
			_len = 1;
		}
	}

	// 行列の拡張
	MathValue expand( int row, int col ){
		if( (row >= _row) || (col >= _col) ){
			resize(
				(row >= _row) ? row + 1 : _row,
				(col >= _col) ? col + 1 : _col
				);
		}
		return _val( row, col );
	}

	// 値の設定
	void set( int row, int col, dynamic val ){
		expand( row, col ).ass( val );
	}
	void setReal( int row, int col, double val ){
		expand( row, col ).setReal( val );
	}
	void setImag( int row, int col, double val ){
		expand( row, col ).setImag( val );
	}
	void setNum( int row, int col, double val ){
		expand( row, col ).setNum( val );
	}
	void setDenom( int row, int col, double val ){
		expand( row, col ).setDenom( val );
	}
	void setMat( int index, MathValue val ){
		_mat[index] = val;
	}

	// 確認
	int row(){ return _row; }
	int col(){ return _col; }
	int len(){ return _len; }
	MathValue mat( int index ){
		return _mat[(index >= _len) ? _len/*番人*/ : index];
	}
	MathValue val( int row, int col ){
		return _mat[((row >= _row) || (col >= _col)) ? _len/*番人*/ : row * _col + col];
	}
	MathValue _val( int row, int col ){
		return _mat[row * _col + col];
	}

	// 型変換
	double toFloat( int row, int col ){
		return val( row, col ).toFloat();
	}

	// 代入
	MathMatrix ass( dynamic r ){
		if( r is MathMatrix ){
			if( r._len == 1 ){
				_resize1();
				MathValue.copy( _mat[0], r._mat[0] );
			} else {
				_resize( r );
				for( int i = 0; i < _len; i++ ){
					MathValue.copy( _mat[i], r._mat[i] );
				}
			}
		} else if( r is MathValue ){
			_resize1();
			MathValue.copy( _mat[0], r );
		} else {
			_resize1();
			_mat[0].ass( ClipMath.toDouble(r) );
		}
		return this;
	}

	// 単項マイナス
	MathMatrix minus(){
		MathMatrix a = MathMatrix( _row, _col );
		for( int i = 0; i < _len; i++ ){
			MathValue.copy( a._mat[i], _mat[i].minus() );
		}
		return a;
	}

	// 加算
	MathMatrix add( dynamic r ){
		if( r is MathMatrix ){
			if( r._len == 1 ){
				return valueToMatrix( _mat[0].add( r._mat[0] ) );
			}
			int i, j;
			MathMatrix a = MathMatrix(
				(_row > r._row) ? _row : r._row,
				(_col > r._col) ? _col : r._col
				);
			for( i = 0; i < a._row; i++ ){
				for( j = 0; j < a._col; j++ ){
					MathValue.copy( a._val( i, j ), val( i, j ).add( r.val( i, j ) ) );
				}
			}
			return a;
		}
		return valueToMatrix( _mat[0].add( ClipMath.toDouble(r) ) );
	}
	MathMatrix addAndAss( dynamic r ){
		if( r is MathMatrix ){
			if( r._len == 1 ){
				_resize1();
				_mat[0].addAndAss( r._mat[0] );
			} else {
				int i, j;
				resize(
					(_row > r._row) ? _row : r._row,
					(_col > r._col) ? _col : r._col
					);
				for( i = 0; i < _row; i++ ){
					for( j = 0; j < _col; j++ ){
						_val( i, j ).addAndAss( r.val( i, j ) );
					}
				}
			}
		} else {
			_resize1();
			_mat[0].addAndAss( ClipMath.toDouble(r) );
		}
		return this;
	}

	// 減算
	MathMatrix sub( dynamic r ){
		if( r is MathMatrix ){
			if( r._len == 1 ){
				return valueToMatrix( _mat[0].sub( r._mat[0] ) );
			}
			int i, j;
			MathMatrix a = MathMatrix(
				(_row > r._row) ? _row : r._row,
				(_col > r._col) ? _col : r._col
				);
			for( i = 0; i < a._row; i++ ){
				for( j = 0; j < a._col; j++ ){
					MathValue.copy( a._val( i, j ), val( i, j ).sub( r.val( i, j ) ) );
				}
			}
			return a;
		}
		return valueToMatrix( _mat[0].sub( ClipMath.toDouble(r) ) );
	}
	MathMatrix subAndAss( dynamic r ){
		if( r is MathMatrix ){
			if( r._len == 1 ){
				_resize1();
				_mat[0].subAndAss( r._mat[0] );
			} else {
				int i, j;
				resize(
					(_row > r._row) ? _row : r._row,
					(_col > r._col) ? _col : r._col
					);
				for( i = 0; i < _row; i++ ){
					for( j = 0; j < _col; j++ ){
						_val( i, j ).subAndAss( r.val( i, j ) );
					}
				}
			}
		} else {
			_resize1();
			_mat[0].subAndAss( ClipMath.toDouble(r) );
		}
		return this;
	}

	// 乗算
	MathMatrix mul( dynamic r ){
		if( _len == 1 ){
			return dup( this ).mulAndAss( r );
		}
		if( r is MathMatrix ){
			if( r._len == 1 ){
				MathMatrix a = MathMatrix( _row, _col );
				for( int i = 0; i < _len; i++ ){
					MathValue.copy( a._mat[i], _mat[i].mul( r._mat[0] ) );
				}
				return a;
			}
			int i, j, k;
			int l = _row;
			int m = (_col > r._row) ? _col : r._row;
			int n = r._col;
			MathValue t = MathValue();
			MathMatrix a = MathMatrix( l, n );
			for( i = 0; i < a._row; i++ ){
				for( j = 0; j < a._col; j++ ){
					t.ass( 0.0 );
					for( k = 0; k < m; k++ ){
						t.addAndAss( val( i, k ).mul( r.val( k, j ) ) );
					}
					MathValue.copy( a._val( i, j ), t );
				}
			}
			return a;
		}
		double rr = ClipMath.toDouble(r);
		MathMatrix a = MathMatrix( _row, _col );
		for( int i = 0; i < _len; i++ ){
			MathValue.copy( a._mat[i], _mat[i].mul( rr ) );
		}
		return a;
	}
	MathMatrix mulAndAss( dynamic r ){
		if( r is MathMatrix ){
			if( _len == 1 ){
				if( r._len == 1 ){
					_mat[0].mulAndAss( r._mat[0] );
				} else {
					ass( r.mul( _mat[0] ) );
				}
			} else {
				ass( mul( r ) );
			}
		} else {
			if( _len == 1 ){
				_mat[0].mulAndAss( ClipMath.toDouble(r) );
			} else {
				double rr = ClipMath.toDouble(r);
				for( int i = 0; i < _len; i++ ){
					_mat[i].mulAndAss( rr );
				}
			}
		}
		return this;
	}

	// 除算
	MathMatrix div( dynamic r ){
		MathMatrix a = MathMatrix( _row, _col );
		if( r is MathMatrix ){
			for( int i = 0; i < _len; i++ ){
				MathValue.copy( a._mat[i], _mat[i].div( r._mat[0] ) );
			}
		} else {
			double rr = ClipMath.toDouble(r);
			for( int i = 0; i < _len; i++ ){
				MathValue.copy( a._mat[i], _mat[i].div( rr ) );
			}
		}
		return a;
	}
	MathMatrix divAndAss( dynamic r ){
		if( r is MathMatrix ){
			if( _len == 1 ){
				_mat[0].divAndAss( r._mat[0] );
			} else {
				for( int i = 0; i < _len; i++ ){
					_mat[i].divAndAss( r._mat[0] );
				}
			}
		} else {
			if( _len == 1 ){
				_mat[0].divAndAss( ClipMath.toDouble(r) );
			} else {
				double rr = ClipMath.toDouble(r);
				for( int i = 0; i < _len; i++ ){
					_mat[i].divAndAss( rr );
				}
			}
		}
		return this;
	}

	// 剰余
	MathMatrix mod( dynamic r ){
		if( r is MathMatrix ){
			return valueToMatrix( _mat[0].mod( r._mat[0] ) );
		}
		return valueToMatrix( _mat[0].mod( ClipMath.toDouble(r) ) );
	}
	MathMatrix modAndAss( dynamic r ){
		_resize1();
		if( r is MathMatrix ){
			_mat[0].modAndAss( r._mat[0] );
		} else {
			_mat[0].modAndAss( ClipMath.toDouble(r) );
		}
		return this;
	}

	// 等値
	bool equal( dynamic r ){
		if( r is MathMatrix ){
			if( (_row != r._row) || (_col != r._col) ){
				return false;
			}
			for( int i = 0; i < _len; i++ ){
				if( _mat[i].notEqual( r._mat[i] ) ){
					return false;
				}
			}
			return true;
		}
		if( _len != 1 ){
			return false;
		}
		return _mat[0].equal( ClipMath.toDouble(r) );
	}
	bool notEqual( dynamic r ){
		if( r is MathMatrix ){
			if( (_row != r._row) || (_col != r._col) ){
				return true;
			}
			for( int i = 0; i < _len; i++ ){
				if( _mat[i].notEqual( r._mat[i] ) ){
					return true;
				}
			}
			return false;
		}
		if( _len != 1 ){
			return true;
		}
		return _mat[0].notEqual( ClipMath.toDouble(r) );
	}

	// 転置行列
	MathMatrix trans(){
		int i, j;
		MathMatrix a = MathMatrix( _col, _row );
		for( i = 0; i < a._row; i++ ){
			for( j = 0; j < a._col; j++ ){
				MathValue.copy( a._val( i, j ), _val( j, i ) );
			}
		}
		return a;
	}

	static void deleteMatrix( MathMatrix x ){
//		for( int i = 0; i < x._mat.length; i++ ){
//			x._mat[i] = null;
//		}
//		x._mat = null;
	}

	static MathMatrix dup( MathMatrix x ){
		MathMatrix a = MathMatrix( x._row, x._col );
		for( int i = 0; i < x._len; i++ ){
			MathValue.copy( a._mat[i], x._mat[i] );
		}
		return a;
	}

	static MathMatrix arrayToMatrix( List<List<dynamic>> x ){
		int i, j;
		int row = x.length;
		int col = x[0].length;
		for( i = 1; i < row; i++ ){
			if( x[i].length < col ){
				col = x[i].length;
			}
		}
		MathMatrix a = MathMatrix( row, col );
		for( i = 0; i < row; i++ ){
			for( j = 0; j < col; j++ ){
				a._val( i, j ).ass( x[i][j] );
			}
		}
		return a;
	}
	static MathMatrix valueToMatrix( MathValue x ){
		MathMatrix a = MathMatrix();
		MathValue.copy( a._mat[0], x );
		return a;
	}
	static MathMatrix floatToMatrix( double x ){
		MathMatrix a = MathMatrix();
		a._mat[0].setFloat( x );
		return a;
	}

	static List<MathMatrix> newArray( int len ){
		List<MathMatrix> a = List.filled( len, MathMatrix() );
		for( int i = 0; i < len; i++ ){
			a[i] = MathMatrix();
		}
		return a;
	}
}
