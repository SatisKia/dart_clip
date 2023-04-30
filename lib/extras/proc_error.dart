/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import '../global.dart';
import '../param/integer.dart';
import '../param/string.dart';

// 計算エラー情報
class _ProcError {
	late int _err;
	late int _num;
	late String _func;
	late String _token;
	late _ProcError? _before; // 前の計算エラー情報
	late _ProcError? _next; // 次の計算エラー情報
	_ProcError(){
		_err    = 0;
		_num    = 0;
		_func   = "";
		_token  = "";
		_before = null;
		_next   = null;
	}
}

// 計算エラー情報管理クラス
class ProcError {
	late _ProcError? _top; // 計算エラー情報リスト
	late _ProcError? _end; // 計算エラー情報リスト
	late int _num; // 計算エラー情報の個数

	ProcError(){
		_top = null;
		_end = null;
		_num = 0;
	}

	// 計算エラー情報を登録する
	void add( int err, int num, String func, String token ){
		_ProcError? cur = _top;
		while( true ){
			if( cur == null ){
				break;
			}
			if(
				(cur._err   == err  ) &&
				(cur._num   == num  ) &&
				(cur._func  == func ) &&
				(cur._token == token)
			){
				return;
			}
			cur = cur._next;
		}

		_ProcError tmp = _ProcError();

		if( _top == null ){
			// 先頭に登録する
			_top = tmp;
			_end = tmp;
		} else {
			// 最後尾に追加する
			tmp._before = _end;
			_end!._next = tmp;
			_end        = tmp;
		}

		tmp._err   = err;
		tmp._num   = num;
		tmp._func  = func;
		tmp._token = token;

		_num++;
	}

	// 計算エラー情報を全削除する
	void delAll(){
		_top = null;
		_num = 0;
	}

	// 計算エラー情報を確認する
	bool get( int index, ParamInteger err, ParamInteger num, ParamString func, ParamString token ){
		int tmp = 0;
		_ProcError? cur = _top;
		while( true ){
			if( cur == null ){
				return false;
			}
			if( tmp == index ){
				break;
			}
			tmp++;
			cur = cur._next;
		}

		err  .set( cur._err   );
		num  .set( cur._num   );
		func .set( cur._func  );
		token.set( cur._token );
		return true;
	}
	int num(){
		return _num;
	}

	bool isError(){
		_ProcError? cur = _top;
		while( cur != null ){
			if( (cur._err & CLIP_PROC_WARN) == 0 ){
				return true;
			}
			cur = cur._next;
		}
		return false;
	}

}

String getProcErrorDefString( int err, String token, bool isCalculator, bool isEnglish ){
	String error = "";
	switch( err ){
	case CLIP_PROC_WARN_ARRAY:
		if( isEnglish ) error = "Array element number is negative.";
		else            error = "配列の要素番号が負の値です";
		break;
	case CLIP_PROC_WARN_DIV:
		if( isEnglish ) error = "Divide by zero.";
		else            error = "ゼロで除算しました";
		break;
	case CLIP_PROC_WARN_UNDERFLOW:
		if( isEnglish ) error = "Underflowed.";
		else            error = "アンダーフローしました";
		break;
	case CLIP_PROC_WARN_OVERFLOW:
		if( isEnglish ) error = "Overflow occurred.";
		else            error = "オーバーフローしました";
		break;
	case CLIP_PROC_WARN_ASIN:
		if( isEnglish ) error = "Argument of \"asin\" is out of the range of -1 to 1.";
		else            error = "asinの引数が-1から1の範囲外になりました";
		break;
	case CLIP_PROC_WARN_ACOS:
		if( isEnglish ) error = "Argument of \"acos\" is out of the range of -1 to 1.";
		else            error = "acosの引数が-1から1の範囲外になりました";
		break;
	case CLIP_PROC_WARN_ACOSH:
		if( isEnglish ) error = "Argument of \"acosh\" now has value less than 1.";
		else            error = "acoshの引数が1未満の値になりました";
		break;
	case CLIP_PROC_WARN_ATANH:
		if( isEnglish ) error = "The argument of \"atanh\" is less than or equal to -1 or 1 or more.";
		else            error = "atanhの引数が-1以下または1以上の値になりました";
		break;
	case CLIP_PROC_WARN_LOG:
		if( isEnglish ) error = "Argument of \"" + (isCalculator ? "ln" : "log") + "\" is 0 or negative value.";
		else            error = (isCalculator ? "ln" : "log") + "の引数が0または負の値になりました";
		break;
	case CLIP_PROC_WARN_LOG10:
		if( isEnglish ) error = "Argument of \"" + (isCalculator ? "log" : "log10") + "\" has become 0 or negative value.";
		else            error = (isCalculator ? "log" : "log10") + "の引数が0または負の値になりました";
		break;
	case CLIP_PROC_WARN_SQRT:
		if( isEnglish ) error = "Argument of \"sqrt\" has a negative value.";
		else            error = "sqrtの引数が負の値になりました";
		break;
	case CLIP_PROC_WARN_FUNCTION:
		if( isEnglish ) error = "Invalid argument for \"" + token + "\".";
		else            error = token + "の引数が無効です";
		break;
	case CLIP_PROC_WARN_RETURN:
		if( isEnglish ) error = "\"return\" can not return a value.";
		else            error = "returnで値を返すことができません";
		break;
	case CLIP_PROC_WARN_DEAD_TOKEN:
		if( isEnglish ) error = "Token is not executed.";
		else            error = "実行されないトークンです";
		break;
	case CLIP_PROC_WARN_SE_RETURN:
		if( isEnglish ) error = "\"\$RETURN_A\" can not return a value.";
		else            error = "\$RETURN_Aで値を返すことができません";
		break;

	case CLIP_LOOP_ERR_NULL:
		if( isEnglish ) error = "There is no token.";
		else            error = "トークンがありません";
		break;
	case CLIP_LOOP_ERR_COMMAND:
		if( isEnglish ) error = "Command not supported.";
		else            error = "コマンドはサポートされていません";
		break;
	case CLIP_LOOP_ERR_STAT:
		if( isEnglish ) error = "Control structure is not supported.";
		else            error = "制御構造はサポートされていません";
		break;

	case CLIP_PROC_ERR_UNARY:
		if( isEnglish ) error = "\"" + token + "\": Unary operator expression is incorrect.";
		else            error = token + ":単項演算子表現が間違っています";
		break;
	case CLIP_PROC_ERR_OPERATOR:
		if( isEnglish ) error = "\"" + token + "\": Operator expression is wrong.";
		else            error = token + ":演算子表現が間違っています";
		break;
	case CLIP_PROC_ERR_ARRAY:
		if( isEnglish ) error = "\"" + token + "\": Array representation is incorrect.";
		else            error = token + ":配列表現が間違っています";
		break;
	case CLIP_PROC_ERR_FUNCTION:
		if( isEnglish ) error = "Argument of function \"" + token + "\" is wrong.";
		else            error = "関数" + token + "の引数が間違っています";
		break;
	case CLIP_PROC_ERR_LVALUE:
		if( isEnglish ) error = "The left side of \"" + token + "\" must be a variable or an array.";
		else            error = token + "の左辺は変数または配列でなければなりません";
		break;
	case CLIP_PROC_ERR_RVALUE:
		if( isEnglish ) error = "The right side of \"" + token + "\" must be a variable or an array.";
		else            error = token + "の右辺は変数または配列でなければなりません";
		break;
	case CLIP_PROC_ERR_RVALUE_NULL:
		if( isEnglish ) error = "There is no right side of \"" + token + "\".";
		else            error = token + "の右辺がありません";
		break;
	case CLIP_PROC_ERR_CONDITIONAL:
		if( isEnglish ) error = "Two constant or variable are not specified on the right side of the ternary operator \"" + token + "\".";
		else            error = "三項演算子" + token + "の右辺に定数または変数が2個指定されていません";
		break;
	case CLIP_PROC_ERR_EXTFUNC:
		if( isEnglish ) error = "Execution of the external function \"" + token.substring( 1 ) + "\" was interrupted.";
		else            error = "外部関数" + token.substring( 1 ) + "の実行が中断されました";
		break;
	case CLIP_PROC_ERR_USERFUNC:
		if( isEnglish ) error = "Execution of function \"" + token + "\" was interrupted.";
		else            error = "関数" + token + "の実行が中断されました";
		break;
	case CLIP_PROC_ERR_CONSTANT:
		if( isEnglish ) error = "\"" + token + "\": Constant expression is wrong.";
		else            error = token + ":定数表現が間違っています";
		break;
	case CLIP_PROC_ERR_STRING:
		if( isEnglish ) error = "\"" + token + "\": String representation is incorrect.";
		else            error = token + ":文字列表現が間違っています";
		break;
	case CLIP_PROC_ERR_COMPLEX:
		if( isEnglish ) error = "\"" + token + "\": Wrong complex number representation.";
		else            error = token + ":複素数表現が間違っています";
		break;
	case CLIP_PROC_ERR_FRACT:
		if( isEnglish ) error = "\"" + token + "\": Fractional representation is incorrect.";
		else            error = token + ":分数表現が間違っています";
		break;
	case CLIP_PROC_ERR_ASS:
		if( isEnglish ) error = "Assignment to a constant by \"" + token + "\" is invalid.";
		else            error = token + "による定数への代入は無効です";
		break;
	case CLIP_PROC_ERR_CALL:
		if( isEnglish ) error = "Function call failed.";
		else            error = "関数呼び出しに失敗しました";
		break;
	case CLIP_PROC_ERR_EVAL:
		if( isEnglish ) error = "Execution of evaluation was interrupted.";
		else            error = "evalの実行が中断されました";
		break;
	case CLIP_PROC_ERR_MULTIPREC:
		if( isEnglish ) error = "\"" + token + "\": Multi-precision expression is wrong.";
		else            error = token + ":多倍長数表現が間違っています";
		break;
	case CLIP_PROC_ERR_STAT_IF:
		if( isEnglish ) error = "\"" + token + "\" too many nests.";
		else            error = token + "のネスト数が多すぎます";
		break;
	case CLIP_PROC_ERR_STAT_ENDIF:
		if( isEnglish ) error = "There is no \"if\" corresponding to \"" + token + "\".";
		else            error = token + "に対応するifがありません";
		break;
	case CLIP_PROC_ERR_STAT_SWITCH:
		if( isEnglish ) error = "\"" + token + "\" too many nests.";
		else            error = token + "のネスト数が多すぎます";
		break;
	case CLIP_PROC_ERR_STAT_ENDSWI:
		if( isEnglish ) error = "There is no \"switch\" corresponding to \"" + token + "\".";
		else            error = token + "に対応するswitchがありません";
		break;
	case CLIP_PROC_ERR_STAT_UNTIL:
		if( isEnglish ) error = "No \"do\" corresponding to \"" + token + "\".";
		else            error = token + "に対応するdoがありません";
		break;
	case CLIP_PROC_ERR_STAT_ENDWHILE:
		if( isEnglish ) error = "There is no \"while\" corresponding to \"" + token + "\".";
		else            error = token + "に対応するwhileがありません";
		break;
	case CLIP_PROC_ERR_STAT_FOR_CON:
		if( isEnglish ) error = "No condition part in \"" + token + "\".";
		else            error = token + "における条件部がありません";
		break;
	case CLIP_PROC_ERR_STAT_FOR_EXP:
		if( isEnglish ) error = "There is no update expression in \"" + token + "\".";
		else            error = token + "における更新式がありません";
		break;
	case CLIP_PROC_ERR_STAT_NEXT:
		if( isEnglish ) error = "There is no \"for\" corresponding to \"" + token + "\".";
		else            error = token + "に対応するforがありません";
		break;
	case CLIP_PROC_ERR_STAT_CONTINUE:
		if( isEnglish ) error = "\"" + token + "\" is invalid.";
		else            error = token + "は無効です";
		break;
	case CLIP_PROC_ERR_STAT_BREAK:
		if( isEnglish ) error = "\"" + token + "\" is invalid.";
		else            error = token + "は無効です";
		break;
	case CLIP_PROC_ERR_STAT_FUNC:
		if( isEnglish ) error = "Too many functions.";
		else            error = "関数の数が多すぎます";
		break;
	case CLIP_PROC_ERR_STAT_FUNC_NEST:
		if( isEnglish ) error = "Function can not be defined in function.";
		else            error = "関数内で関数は定義できません";
		break;
	case CLIP_PROC_ERR_STAT_ENDFUNC:
		if( isEnglish ) error = "There is no \"func\" corresponding to \"" + token + "\".";
		else            error = token + "に対応するfuncがありません";
		break;
	case CLIP_PROC_ERR_STAT_FUNCNAME:
		if( isEnglish ) error = "\"" + token + "\": Function name is invalid.";
		else            error = token + ":関数名は無効です";
		break;
	case CLIP_PROC_ERR_STAT_FUNCPARAM:
		if( isEnglish ) error = "\"" + token + "\": Label can not be set for function argument.";
		else            error = token + ":関数の引数にラベル設定できません";
		break;
	case CLIP_PROC_ERR_STAT_LOOP:
		if( isEnglish ) error = "Number of loops exceeded the upper limit.";
		else            error = "ループ回数オーバーしました";
		break;
	case CLIP_PROC_ERR_STAT_END:
		if( isEnglish ) error = "\"" + token + "\" is invalid.";
		else            error = token + "は無効です";
		break;
	case CLIP_PROC_ERR_COMMAND_NULL:
		if( isEnglish ) error = "The command is incorrect.";
		else            error = "コマンドが間違っています";
		break;
	case CLIP_PROC_ERR_COMMAND_PARAM:
		if( isEnglish ) error = "The argument of the command \"" + token.substring( 1 ) + "\" is incorrect.";
		else            error = "コマンド" + token.substring( 1 ) + "の引数が間違っています";
		break;
	case CLIP_PROC_ERR_COMMAND_DEFINE:
		if( isEnglish ) error = "\"" + token + "\" has already been defined.";
		else            error = token + "は既に定義されています";
		break;
	case CLIP_PROC_ERR_COMMAND_UNDEF:
		if( isEnglish ) error = "\"" + token + "\" is not defined.";
		else            error = token + "は定義されていません";
		break;
	case CLIP_PROC_ERR_COMMAND_PARAMS:
		if( isEnglish ) error = "You can only specify up to 10 arguments for the command \"" + token.substring( 1 ) + "\".";
		else            error = "コマンド" + token.substring( 1 ) + "の引数は10個までしか指定できません";
		break;
	case CLIP_PROC_ERR_COMMAND_RADIX:
		if( isEnglish ) error = "Command \"" + token.substring( 1 ) + "\" is invalid.";
		else            error = "コマンド" + token.substring( 1 ) + "は無効です";
		break;
	case CLIP_PROC_ERR_FUNC_OPEN:
		if( isEnglish ) error = "The external function \"" + token.substring( 1 ) + "\" can not be opened.";
		else            error = "外部関数" + token.substring( 1 ) + "がオープンできません";
		break;
	case CLIP_PROC_ERR_FUNC_PARANUM:
		if( isEnglish ) error = "Up to 10 arguments of external function can be specified.";
		else            error = "外部関数の引数は10個までしか指定できません";
		break;
	case CLIP_PROC_ERR_FUNC_PARACODE:
		if( isEnglish ) error = "\"token\": The argument of the external function must be a constant, variable or array name.";
		else            error = token + ":外部関数の引数は定数、変数または配列名でなければなりません";
		break;
	case CLIP_PROC_ERR_SE_NULL:
		if( isEnglish ) error = "The single expression is incorrect.";
		else            error = "単一式が間違っています";
		break;
	case CLIP_PROC_ERR_SE_OPERAND:
		if( isEnglish ) error = "Operand of the single expression is incorrect.";
		else            error = "単一式のオペランドが間違っています";
		break;
	case CLIP_PROC_ERR_SE_LOOPEND:
		if( isEnglish ) error = "No \"\$LOOPSTART\" corresponding to \"\$LOOPEND\".";
		else            error = "\$LOOPENDに対応する\$LOOPSTARTがありません";
		break;
	case CLIP_PROC_ERR_SE_LOOPCONT:
		if( isEnglish ) error = "No \"\$LOOPSTART\" corresponding to \"\$LOOPCONT\".";
		else            error = "\$LOOPCONTに対応する\$LOOPSTARTがありません";
		break;
	case CLIP_PROC_ERR_SE_CONTINUE:
		if( isEnglish ) error = "\"\$CONTINUE\" is invalid.";
		else            error = "\$CONTINUEは無効です";
		break;
	case CLIP_PROC_ERR_SE_BREAK:
		if( isEnglish ) error = "\"\$BREAK\" is invalid.";
		else            error = "\$BREAKは無効です";
		break;
	}
	return error;
}
