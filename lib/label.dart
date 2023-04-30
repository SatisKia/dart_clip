/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import 'global.dart';

// ラベル管理クラス
class ClipLabel {
	late dynamic _obj;
	late List<String?> _label;
	late List<int> _flag;
	late Map<String, int> _index;

	ClipLabel( dynamic obj ){
		_obj = obj;

		_label = List.filled( 256, null );
		_flag  = List.filled( 256, CLIP_LABEL_UNUSED );

		_index = {};
	}

	// 未使用インデックスを検索し、使用状態にする
	int define( String? label ){
		if( label != null ){
			for( int i = 255; i >= 0; i-- ){
				if( _flag[i] == CLIP_LABEL_UNUSED ){
					_flag[i] = CLIP_LABEL_MOVABLE;
					setLabel( i, label, false );
					return i;
				}
			}
		}
		return -1;
	}

	// ラベルを検索し、未使用状態にする
	int undef( String? label ){
		int index;
		if( (index = checkLabel( label )) >= 0 ){
			setLabel( index, null, false );
			_flag[index] = CLIP_LABEL_UNUSED;
		}
		return index;
	}

	// ラベルを設定する
	void setLabel( int index, String? label, bool moveFlag ){
		if( moveFlag ){
			_obj.move( index );
		}

		if( _label[index] != null ){
			if( _index[_label[index]] == index ){
				_index.remove( _label[index] );
			}
			_label[index] = null;
		}
		if( label != null ){
			if( label.isNotEmpty ){
				_label[index] = label;
				_index[label] = index;
			}
		}
	}

	// ラベルを確認する
	String? label( index ){ return _label[index]; }

	void setFlag( int index, int flag ){
		_flag[index] = flag;
	}
	int flag( index ){
		return _flag[index];
	}

	// ラベルを検索する
	int checkLabel( String? label ){
//		for( var i = 0; i < 256; i++ ){
//			if( _label[i] != null ){
//				if( _label[i] == label ){
//					return i;
//				}
//			}
//		}
		if( _index.containsKey( label ) ){
			return _index[label]!;
		}
		return -1;
	}
}
