/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import 'global.dart';
import 'label.dart';
import 'math/matrix.dart';
import 'math/multiprec.dart';
import 'math/value.dart';
import 'token.dart';

// ノード・クラス
class ClipArrayNode {
	late List<ClipArrayNode>? _node; // 子ノード
	late int _nodeNum; // 子ノードの数

	late List<MathValue> _vector; // このノードの要素
	late int _vectorNum; // このノードの要素数

	ClipArrayNode(){
		_node    = null;
		_nodeNum = 0;

		_vector    = newValueArray( 1 );
		_vectorNum = 0;
	}

	ClipArrayNode node( index ){ return _node![index]; }
	int nodeNum(){ return _nodeNum; }

	MathValue vector( index ){ return _vector[index]; }
	int vectorNum(){ return _vectorNum; }

	// ノードをコピーする
	void dup( ClipArrayNode dst ){
		int i;

		if( _nodeNum > 0 ){
			dst._node    = _newArrayNodeArray( _nodeNum );
			dst._nodeNum = _nodeNum;
			for( i = 0; i < _nodeNum; i++ ){
				_node![i].dup( dst._node![i] );
			}
		} else {
			dst._node    = null;
			dst._nodeNum = 0;
		}

		if( _vectorNum > 0 ){
			dst._vector = newValueArray( _vectorNum + 1 );
			for( i = _vectorNum; i >= dst._vectorNum; i-- ){
				dst._vector[i] = MathValue();
			}
			dst._vectorNum = _vectorNum;
			for( i = 0; i < _vectorNum; i++ ){
				copyValue( dst._vector[i], _vector[i] );
			}
		} else {
			dst._vector    = newValueArray( 1 );
			dst._vectorNum = 0;
		}
	}

	// ノード構造からトークンを構築する
	void makeToken( ClipToken dst, bool flag ){
		int i;

		if( _nodeNum > 0 ){
			dst.addCode( CLIP_CODE_ARRAY_TOP, null );
			for( i = 0; i < _nodeNum; i++ ){
				_node![i].makeToken( dst, true );
			}
			dst.addCode( CLIP_CODE_ARRAY_END, null );
		}

		if( _vectorNum > 0 ){
			dst.addCode( CLIP_CODE_ARRAY_TOP, null );
			for( i = 0; i < _vectorNum; i++ ){
				dst.addValue( _vector[i] );
			}
			dst.addCode( CLIP_CODE_ARRAY_END, null );
		}

		if( flag && (_nodeNum == 0) && (_vectorNum == 0) ){
			dst.addCode( CLIP_CODE_ARRAY_TOP, null );
			dst.addCode( CLIP_CODE_ARRAY_END, null );
		}
	}

	// 値を代入する
	void _newVector( int index ){
		if( _vectorNum == 0 ){
			_vector = newValueArray( index + 2 );
		} else {
			int i;
			List<MathValue> tmp = newValueArray( index + 2 );

			// 既存の配列をコピーする
			for( i = 0; i < _vectorNum; i++ ){
//				copyValue( tmp[i], _vector[i] );
				tmp[i] = _vector[i];
			}

			_vector = tmp;
			for( i = index + 1; i >= _vectorNum; i-- ){
				_vector[i] = MathValue();
			}
		}

		_vectorNum = index + 1;
	}
	void _resizeVector( int index ){
		// 番人
//		copyValue( _vector[index + 1], _vector[_vectorNum] );
		_vector[index + 1] = MathValue();

		_vectorNum = index + 1;
	}
	void _newNode( int index ){
		if( _nodeNum == 0 ){
			_node = _newArrayNodeArray( index + 1 );
		} else {
			int i;
			List<ClipArrayNode> tmp = _newArrayNodeArray( index + 1 );

			// 既存の配列をコピーする
			for( i = 0; i < _nodeNum; i++ ){
//				_node[i].dup( tmp[i] );
				tmp[i] = _node![i];
			}

			_node = tmp;
			for( i = index; i >= _nodeNum; i-- ){
				_node![i] = ClipArrayNode();
			}
		}

		_nodeNum = index + 1;
	}
	void _resizeNode( int index ){
		_nodeNum = index + 1;
	}
	List<int> _copyArray( List<int> src, int i ){
		List<int> dst = List.filled( src.length - i, 0 );
		for( int j = 0; j < dst.length; j++ ){
			dst[j] = src[i + j];
		}
		return dst;
	}
	void set( dynamic index, dynamic value ){
		if( index is List<int> ){
			if( index[1] < 0 ){ // 負数でターミネートされた要素番号配列
				set( index[0], value );
			} else if( (index[0] >= 0) && (index[0] != CLIP_INVALID_ARRAY_INDEX) ){
				if( index[0] >= _nodeNum ){
					_newNode( index[0] );
				}
				_node![index[0]].set( _copyArray( index, 1 ), value );
			}
		} else if( (index >= 0) && (index != CLIP_INVALID_ARRAY_INDEX) ){
			if( index >= _vectorNum ){
				_newVector( index );
			}
			_vector[index].ass( value );
		}
	}
	void resize( dynamic index, dynamic value ){
		if( index is List<int> ){
			if( index[1] < 0 ){ // 負数でターミネートされた要素番号配列
				resize( index[0], value );
			} else if( (index[0] >= 0) && (index[0] != CLIP_INVALID_ARRAY_INDEX) ){
				if( index[0] >= _nodeNum ){
					_newNode( index[0] );
				} else {
					_resizeNode( index[0] );
				}
				_node![index[0]].set( _copyArray( index, 1 ), value );
			}
		} else if( (index >= 0) && (index != CLIP_INVALID_ARRAY_INDEX) ){
			if( index >= _vectorNum ){
				_newVector( index );
			} else {
				_resizeVector( index );
			}
			_vector[index].ass( value );
		}
	}
	void setVector( List<dynamic> value, int num ){
		if( num > _vectorNum ){
			_newVector( num - 1 );
		} else {
			_resizeVector( num - 1 );
		}

		for( var i = 0; i < num; i++ ){
			_vector[i].ass( value[i] );
		}
	}
	void setComplexVector( List<double> real, List<double> imag, int num ){
		if( num > _vectorNum ){
			_newVector( num - 1 );
		} else {
			_resizeVector( num - 1 );
		}

		for( int i = 0; i < num; i++ ){
			_vector[i].setReal( real[i] );
			_vector[i].setImag( imag[i] );
		}
	}
	void setFractVector( List<double> value, List<double> denom, int num ){
		if( num > _vectorNum ){
			_newVector( num - 1 );
		} else {
			_resizeVector( num - 1 );
		}

		double nu;
		for( int i = 0; i < num; i++ ){
			nu = value[i];
			if( nu < 0 ){
				_vector[i].fractSetMinus( true );
				nu = -nu;
			} else {
				_vector[i].fractSetMinus( false );
			}
			_vector[i].setNum( nu );
			_vector[i].setDenom( denom[i] );
		}
	}

	// 値を確認する
	MathValue val( dynamic index ){
		if( index is List<int> ){
			if( index[1] < 0 ){ // 負数でターミネートされた要素番号配列
				return val( index[0] );
			}
			if( index[0] < _nodeNum ){
				return _node![index[0]].val( _copyArray( index, 1 ) );
			}
			return _vector[_vectorNum]; // 番人
		}
		return _vector[(index < _vectorNum) ? index : _vectorNum/*番人*/];
	}
}

List<ClipArrayNode> _newArrayNodeArray( int len ){
	List<ClipArrayNode> a = List.filled( len, ClipArrayNode() );
	for( int i = 0; i < len; i++ ){
		a[i] = ClipArrayNode();
	}
	return a;
}

// 配列管理クラス
class ClipArray {
	late ClipLabel _label;

	late List<ClipArrayNode> _node;
	late List<MathMatrix> _mat;

	late List<MPData> _mp;

	ClipArray(){
		_label = ClipLabel( this );

		_node = _newArrayNodeArray( 256 );
		_mat  = newMatrixArray    ( 256 );

		_mp = List.filled( 256, MPData() );
		for( int i = 0; i < 256; i++ ){
			_mp[i] = MPData();
		}
	}

	ClipLabel label(){ return _label; }

	ClipArrayNode node( index ){ return _node[index]; }
	MathMatrix matrix( int index ){ return _mat[index]; }
	MPData mp( int index ){ return _mp[index]; }

	// 未使用インデックスを検索し、使用状態にする
	int define( String? label ){
		int index;
		if( (index = _label.define( label )) >= 0 ){
			// 値を初期化する
			_node[index] = ClipArrayNode();
			_mat [index] = MathMatrix();
			_mp  [index] = MPData();
		}
		return index;
	}

	// 定義を削除する
	int undef( String? label ){
		int index;
		if( (index = _label.undef( label )) >= 0 ){
			// 値を初期化する
			_node[index] = ClipArrayNode();
			_mat [index] = MathMatrix();
			_mp  [index] = MPData();
		}
		return index;
	}

	void _moveData( int index ){
		int newIndex;

		// 動的配列の実体を移す
		if( (newIndex = _label.define( _label.label( index ) )) >= 0 ){
			dup( this, index, newIndex, false );
		}
	}
	void move( int index ){
		if( _label.flag( index ) == CLIP_LABEL_MOVABLE ){
			_moveData( index );
			_label.setLabel( index, null, false );
		}
		_label.setFlag( index, CLIP_LABEL_USED );
	}

	// 値を代入する
	void set( int index, dynamic subIndex, int dim, dynamic value, [bool moveFlag = false] ){
		if( moveFlag ){
			move( index );
		}
		if( dim == 1 ){
			_node[index].set( subIndex[0], value );
		} else if( dim == 2 ){
			if(
				(subIndex[0] < 0) || (subIndex[0] == CLIP_INVALID_ARRAY_INDEX) ||
				(subIndex[1] < 0) || (subIndex[1] == CLIP_INVALID_ARRAY_INDEX)
			){
				return;
			}
			_mat[index].set( subIndex[0], subIndex[1], value );
		} else {
			_node[index].set( subIndex, value );
		}
	}
	void setVector( int index, List<dynamic> value, int num, [bool moveFlag = false] ){
		if( moveFlag ){
			move( index );
		}
		_node[index].setVector( value, num );
	}
	void setComplexVector( int index, List<double> real, List<double> imag, int num, [bool moveFlag = false] ){
		if( moveFlag ){
			move( index );
		}
		_node[index].setComplexVector( real, imag, num );
	}
	void setFractVector( int index, List<double> value, List<double> denom, int num, [bool moveFlag = false] ){
		if( moveFlag ){
			move( index );
		}
		_node[index].setFractVector( value, denom, num );
	}
	void setMatrix( int index, dynamic src, [bool moveFlag = false] ){
		if( moveFlag ){
			move( index );
		}
		_mat[index].ass( src );
	}
	void setComplexMatrix( int index, MathMatrix real, MathMatrix imag, [bool moveFlag = false] ){
		if( real.len() == imag.len() ){
			MathMatrix src = MathMatrix( real.row(), real.col() );
			for( int i = 0; i < real.len(); i++ ){
				src.mat(i).setReal( real.mat(i).toFloat() );
				src.mat(i).setImag( imag.mat(i).toFloat() );
			}
			if( moveFlag ){
				move( index );
			}
			_mat[index].ass( src );
		}
	}
	void setFractMatrix( int index, MathMatrix value, MathMatrix denom, [bool moveFlag = false] ){
		if( value.len() == denom.len() ){
			MathMatrix src = MathMatrix( value.row(), value.col() );
			double nu;
			for( int i = 0; i < value.len(); i++ ){
				nu = value.mat(i).toFloat();
				if( nu < 0 ){
					src.mat(i).fractSetMinus( true );
					nu = -nu;
				} else {
					src.mat(i).fractSetMinus( false );
				}
				src.mat(i).setNum( nu );
				src.mat(i).setDenom( denom.mat(i).toFloat() );
			}
			if( moveFlag ){
				move( index );
			}
			_mat[index].ass( src );
		}
	}
	void resize( int index, List<int> resIndex, List<int> subIndex, int dim, dynamic value, [bool moveFlag = false] ){
		if( moveFlag ){
			move( index );
		}
		if( dim == 1 ){
			_node[index].resize( subIndex[0], value );
		} else if( dim == 2 ){
			_mat[index].resize( resIndex[0] + 1, resIndex[1] + 1 );
			_mat[index].set( subIndex[0], subIndex[1], value );
		} else {
			_node[index].resize( subIndex, value );
		}
	}
	void resizeVector( int index, dynamic subIndex, dynamic value, [bool moveFlag = false] ){
		if( moveFlag ){
			move( index );
		}
		_node[index].resize( subIndex, value );
	}

	// 値を確認する
	MathValue val( int index, dynamic subIndex, [int? dim] ){
		if( dim != null ){
			if( dim == 1 ){
				return _node[index].val( subIndex[0] );
			} else if( dim == 2 ){
				return _mat[index].val(
					((subIndex[0] < 0) || (subIndex[0] == CLIP_INVALID_ARRAY_INDEX)) ? _mat[index].row() : subIndex[0],
					((subIndex[1] < 0) || (subIndex[1] == CLIP_INVALID_ARRAY_INDEX)) ? _mat[index].col() : subIndex[1]
					);
			}
		}
		return _node[index].val( subIndex );
	}

	// 配列をコピーする
	void dup( ClipArray dst, int srcIndex, int dstIndex, [bool moveFlag = false] ){
		if( moveFlag ){
			dst.move( dstIndex );
		}
		_node[srcIndex].dup( dst._node[dstIndex] );
		dst._mat[dstIndex].ass( _mat[srcIndex] );
		dst._mp[dstIndex] = _mp[srcIndex].clone();
	}

	// 配列を置き換える
	void rep( ClipArray dst, int srcIndex, int dstIndex, [bool moveFlag = false] ){
		if( moveFlag ){
			dst.move( dstIndex );
		}
		dst._node[dstIndex] = _node[srcIndex];
		dst._mat[dstIndex] = _mat[srcIndex];
		dst._mp[dstIndex] = _mp[srcIndex];
	}

	// 配列からトークンを構築する
	ClipToken makeToken( ClipToken dst, int srcIndex ){
		int row, col;

		dst.delAll();

		if( (_mat[srcIndex].len() > 1) || _mat[srcIndex].mat(0).notEqual( 0.0 ) ){
			dst.addCode( CLIP_CODE_ARRAY_TOP, null );
			for( row = 0; row < _mat[srcIndex].row(); row++ ){
				dst.addCode( CLIP_CODE_ARRAY_TOP, null );
				for( col = 0; col < _mat[srcIndex].col(); col++ ){
					dst.addValue( _mat[srcIndex].val( row, col ) );
				}
				dst.addCode( CLIP_CODE_ARRAY_END, null );
			}
			dst.addCode( CLIP_CODE_ARRAY_END, null );

			_node[srcIndex].makeToken( dst, false );
		} else {
			_node[srcIndex].makeToken( dst, true );
		}

		return dst;
	}
}
