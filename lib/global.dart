/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

/*
 * パラメータ関連
 */

import 'math/math.dart';
import 'math/multiprec.dart';

const int CLIP_MODE_FLOAT = 0x0010;
const int CLIP_MODE_COMPLEX = 0x0020;
const int CLIP_MODE_FRACT = 0x0040;
const int CLIP_MODE_TIME = 0x0080;
const int CLIP_MODE_INT = 0x0100;
const int CLIP_MODE_E_FLOAT = (CLIP_MODE_FLOAT | 0);
const int CLIP_MODE_F_FLOAT = (CLIP_MODE_FLOAT | 1);
const int CLIP_MODE_G_FLOAT = (CLIP_MODE_FLOAT | 2);
const int CLIP_MODE_E_COMPLEX = (CLIP_MODE_COMPLEX | 0);
const int CLIP_MODE_F_COMPLEX = (CLIP_MODE_COMPLEX | 1);
const int CLIP_MODE_G_COMPLEX = (CLIP_MODE_COMPLEX | 2);
const int CLIP_MODE_I_FRACT = (CLIP_MODE_FRACT | 0); // Improper FRACTion
const int CLIP_MODE_M_FRACT = (CLIP_MODE_FRACT | 1); // Mixed FRACTion
const int CLIP_MODE_H_TIME = (CLIP_MODE_TIME | 0);
const int CLIP_MODE_M_TIME = (CLIP_MODE_TIME | 1);
const int CLIP_MODE_S_TIME = (CLIP_MODE_TIME | 2);
const int CLIP_MODE_F_TIME = (CLIP_MODE_TIME | 3);
const int CLIP_MODE_S_CHAR = (CLIP_MODE_INT | 0); // Signed
const int CLIP_MODE_U_CHAR = (CLIP_MODE_INT | 1); // Unsigned
const int CLIP_MODE_S_SHORT = (CLIP_MODE_INT | 2); // Signed
const int CLIP_MODE_U_SHORT = (CLIP_MODE_INT | 3); // Unsigned
const int CLIP_MODE_S_LONG = (CLIP_MODE_INT | 4); // Signed
const int CLIP_MODE_U_LONG = (CLIP_MODE_INT | 5); // Unsigned
const int CLIP_MODE_MASK = 0x0FFF;
const int CLIP_MODE_MULTIPREC = 0x1000;
const int CLIP_MODE_F_MULTIPREC = (CLIP_MODE_MULTIPREC | CLIP_MODE_F_FLOAT);
const int CLIP_MODE_I_MULTIPREC = (CLIP_MODE_MULTIPREC | CLIP_MODE_S_LONG);

const int CLIP_DEFMODE = CLIP_MODE_G_FLOAT;

const double CLIP_DEFFPS = 30.0;

const int CLIP_MINPREC = 0;
const int CLIP_DEFPREC = 6;

const int CLIP_MINRADIX = 2;
const int CLIP_MAXRADIX = 36;
const int CLIP_DEFRADIX = 10;

const int CLIP_MINMPPREC = 0;
const int CLIP_DEFMPPREC = 0;

const int CLIP_DEFMPROUND = MultiPrec.FROUND_HALF_EVEN;

/*
 * 識別コード
 */

const int CLIP_CODE_MASK = 0x1F;
const int CLIP_CODE_VAR_MASK = 0x20;
const int CLIP_CODE_ARRAY_MASK = 0x40;

const int CLIP_CODE_TOP = 0; // (

const int CLIP_CODE_VARIABLE = (1 | CLIP_CODE_VAR_MASK); // 変数
const int CLIP_CODE_AUTO_VAR = (2 | CLIP_CODE_VAR_MASK); // 動的変数
const int CLIP_CODE_GLOBAL_VAR = (3 | CLIP_CODE_VAR_MASK); // グローバル変数

const int CLIP_CODE_ARRAY = (4 | CLIP_CODE_ARRAY_MASK); // 配列
const int CLIP_CODE_AUTO_ARRAY = (5 | CLIP_CODE_ARRAY_MASK); // 動的配列
const int CLIP_CODE_GLOBAL_ARRAY = (6 | CLIP_CODE_ARRAY_MASK); // グローバル配列

const int CLIP_CODE_CONSTANT = 7; // 定数
const int CLIP_CODE_MULTIPREC = 8; // 多倍長数
const int CLIP_CODE_LABEL = 9; // ラベル
const int CLIP_CODE_COMMAND = 10; // コマンド
const int CLIP_CODE_STATEMENT = 11; // 文
const int CLIP_CODE_OPERATOR = 12; // 演算子
const int CLIP_CODE_FUNCTION = 13; // 関数
const int CLIP_CODE_EXTFUNC = 14; // 外部関数

const int CLIP_CODE_PROC_END = 15;

const int CLIP_CODE_NULL = CLIP_CODE_PROC_END;

const int CLIP_CODE_END = 16; // )

const int CLIP_CODE_ARRAY_TOP = 17; // {
const int CLIP_CODE_ARRAY_END = 18; // }

const int CLIP_CODE_MATRIX = 19; // 行列
const int CLIP_CODE_STRING = 20; // 文字列

const int CLIP_CODE_PARAM_ANS = 21; // &
const int CLIP_CODE_PARAM_ARRAY = 22; // []

const int CLIP_CODE_SE = 23; // 単一式

/*
 * 演算子の種類
 */

const int CLIP_OP_INCREMENT = 0; // [++]
const int CLIP_OP_DECREMENT = 1; // [--]
const int CLIP_OP_COMPLEMENT = 2; // [~]
const int CLIP_OP_NOT = 3; // [!]
const int CLIP_OP_MINUS = 4; // [-]
const int CLIP_OP_PLUS = 5; // [+]

const int CLIP_OP_UNARY_END = 6;

const int CLIP_OP_POSTFIXINC = CLIP_OP_UNARY_END; // ++
const int CLIP_OP_POSTFIXDEC = 7; // --

const int CLIP_OP_MUL = 8; // *
const int CLIP_OP_DIV = 9; // /
const int CLIP_OP_MOD = 10; // %

const int CLIP_OP_ADD = 11; // +
const int CLIP_OP_SUB = 12; // -

const int CLIP_OP_SHIFTL = 13; // <<
const int CLIP_OP_SHIFTR = 14; // >>

const int CLIP_OP_LESS = 15; // <
const int CLIP_OP_LESSOREQ = 16; // <=
const int CLIP_OP_GREAT = 17; // >
const int CLIP_OP_GREATOREQ = 18; // >=

const int CLIP_OP_EQUAL = 19; // ==
const int CLIP_OP_NOTEQUAL = 20; // !=

const int CLIP_OP_AND = 21; // &

const int CLIP_OP_XOR = 22; // ^

const int CLIP_OP_OR = 23; // |

const int CLIP_OP_LOGAND = 24; // &&

const int CLIP_OP_LOGOR = 25; // ||

const int CLIP_OP_CONDITIONAL = 26; // ?

const int CLIP_OP_ASS = 27; // =
const int CLIP_OP_MULANDASS = 28; // *=
const int CLIP_OP_DIVANDASS = 29; // /=
const int CLIP_OP_MODANDASS = 30; // %=
const int CLIP_OP_ADDANDASS = 31; // +=
const int CLIP_OP_SUBANDASS = 32; // -=
const int CLIP_OP_SHIFTLANDASS = 33; // <<=
const int CLIP_OP_SHIFTRANDASS = 34; // >>=
const int CLIP_OP_ANDANDASS = 35; // &=
const int CLIP_OP_ORANDASS = 36; // |=
const int CLIP_OP_XORANDASS = 37; // ^=

const int CLIP_OP_COMMA = 38; // ,

const int CLIP_OP_POW = 39; // **
const int CLIP_OP_POWANDASS = 40; // **=

const int CLIP_OP_FACT = 41; // !

/*
 * 関数の種類
 */

const int CLIP_FUNC_DEFINED = 0;
const int CLIP_FUNC_INDEXOF = 1;

const int CLIP_FUNC_ISINF = 2;
const int CLIP_FUNC_ISNAN = 3;

const int CLIP_FUNC_RAND = 4;
const int CLIP_FUNC_TIME = 5;
const int CLIP_FUNC_MKTIME = 6;
const int CLIP_FUNC_TM_SEC = 7;
const int CLIP_FUNC_TM_MIN = 8;
const int CLIP_FUNC_TM_HOUR = 9;
const int CLIP_FUNC_TM_MDAY = 10;
const int CLIP_FUNC_TM_MON = 11;
const int CLIP_FUNC_TM_YEAR = 12;
const int CLIP_FUNC_TM_WDAY = 13;
const int CLIP_FUNC_TM_YDAY = 14;
const int CLIP_FUNC_TM_XMON = 15;
const int CLIP_FUNC_TM_XYEAR = 16;

const int CLIP_FUNC_A2D = 17;
const int CLIP_FUNC_A2G = 18;
const int CLIP_FUNC_A2R = 19;
const int CLIP_FUNC_D2A = 20;
const int CLIP_FUNC_D2G = 21;
const int CLIP_FUNC_D2R = 22;
const int CLIP_FUNC_G2A = 23;
const int CLIP_FUNC_G2D = 24;
const int CLIP_FUNC_G2R = 25;
const int CLIP_FUNC_R2A = 26;
const int CLIP_FUNC_R2D = 27;
const int CLIP_FUNC_R2G = 28;

const int CLIP_FUNC_SIN = 29;
const int CLIP_FUNC_COS = 30;
const int CLIP_FUNC_TAN = 31;
const int CLIP_FUNC_ASIN = 32;
const int CLIP_FUNC_ACOS = 33;
const int CLIP_FUNC_ATAN = 34;
const int CLIP_FUNC_ATAN2 = 35;
const int CLIP_FUNC_SINH = 36;
const int CLIP_FUNC_COSH = 37;
const int CLIP_FUNC_TANH = 38;
const int CLIP_FUNC_ASINH = 39;
const int CLIP_FUNC_ACOSH = 40;
const int CLIP_FUNC_ATANH = 41;
const int CLIP_FUNC_EXP = 42;
const int CLIP_FUNC_EXP10 = 43;
const int CLIP_FUNC_LN = 44;
const int CLIP_FUNC_LOG = 45;
const int CLIP_FUNC_LOG10 = 46;
const int CLIP_FUNC_POW = 47;
const int CLIP_FUNC_SQR = 48;
const int CLIP_FUNC_SQRT = 49;
const int CLIP_FUNC_CEIL = 50;
const int CLIP_FUNC_FLOOR = 51;
const int CLIP_FUNC_ABS = 52;
const int CLIP_FUNC_LDEXP = 53;
const int CLIP_FUNC_FREXP = 54;
const int CLIP_FUNC_MODF = 55;
const int CLIP_FUNC_FACT = 56;

const int CLIP_FUNC_INT = 57;
const int CLIP_FUNC_REAL = 58;
const int CLIP_FUNC_IMAG = 59;
const int CLIP_FUNC_ARG = 60;
const int CLIP_FUNC_NORM = 61;
const int CLIP_FUNC_CONJG = 62;
const int CLIP_FUNC_POLAR = 63;

const int CLIP_FUNC_NUM = 64;
const int CLIP_FUNC_DENOM = 65;

const int CLIP_FUNC_ROW = 66;
const int CLIP_FUNC_COL = 67;
const int CLIP_FUNC_TRANS = 68;

const int CLIP_FUNC_STRCMP = 69;
const int CLIP_FUNC_STRICMP = 70;
const int CLIP_FUNC_STRLEN = 71;

const int CLIP_FUNC_GWIDTH = 72;
const int CLIP_FUNC_GHEIGHT = 73;
const int CLIP_FUNC_GCOLOR = 74;
const int CLIP_FUNC_GCOLOR24 = 75;
const int CLIP_FUNC_GCX = 76;
const int CLIP_FUNC_GCY = 77;
const int CLIP_FUNC_WCX = 78;
const int CLIP_FUNC_WCY = 79;
const int CLIP_FUNC_GGET = 80;
const int CLIP_FUNC_WGET = 81;
const int CLIP_FUNC_GX = 82;
const int CLIP_FUNC_GY = 83;
const int CLIP_FUNC_WX = 84;
const int CLIP_FUNC_WY = 85;
const int CLIP_FUNC_MKCOLOR = 86;
const int CLIP_FUNC_MKCOLORS = 87;
const int CLIP_FUNC_COL_GETR = 88;
const int CLIP_FUNC_COL_GETG = 89;
const int CLIP_FUNC_COL_GETB = 90;

const int CLIP_FUNC_CALL = 91;
const int CLIP_FUNC_EVAL = 92;

const int CLIP_FUNC_MP = 93;
const int CLIP_FUNC_MROUND = 94;

/*
 * 文の種類
 */

const int CLIP_STAT_START = 0;
const int CLIP_STAT_END = 1;
const int CLIP_STAT_END_INC = 2;
const int CLIP_STAT_END_DEC = 3;
const int CLIP_STAT_ENDEQ = 4;
const int CLIP_STAT_ENDEQ_INC = 5;
const int CLIP_STAT_ENDEQ_DEC = 6;
const int CLIP_STAT_CONT = 7;

const int CLIP_STAT_DO = 8;
const int CLIP_STAT_UNTIL = 9;

const int CLIP_STAT_WHILE = 10;
const int CLIP_STAT_ENDWHILE = 11;

const int CLIP_STAT_FOR = 12;
const int CLIP_STAT_FOR2 = 13;
const int CLIP_STAT_NEXT = 14;

const int CLIP_STAT_FUNC = 15;
const int CLIP_STAT_ENDFUNC = 16;

const int CLIP_STAT_MULTIEND = 17;

const int CLIP_STAT_LOOP_END = 18;

const int CLIP_STAT_IF = CLIP_STAT_LOOP_END;
const int CLIP_STAT_ELIF = 19;
const int CLIP_STAT_ELSE = 20;
const int CLIP_STAT_ENDIF = 21;

const int CLIP_STAT_SWITCH = 22;
const int CLIP_STAT_CASE = 23;
const int CLIP_STAT_DEFAULT = 24;
const int CLIP_STAT_ENDSWI = 25;
const int CLIP_STAT_BREAKSWI = 26;

const int CLIP_STAT_CONTINUE = 27;
const int CLIP_STAT_BREAK = 28;
const int CLIP_STAT_CONTINUE2 = 29;
const int CLIP_STAT_BREAK2 = 30;

const int CLIP_STAT_ASSERT = 31;
const int CLIP_STAT_RETURN = 32;
const int CLIP_STAT_RETURN2 = 33;
const int CLIP_STAT_RETURN3 = 34;

/*
 * コマンドの種類
 */

const int CLIP_COMMAND_NULL = 0;

const int CLIP_COMMAND_EFLOAT = 1;
const int CLIP_COMMAND_FFLOAT = 2;
const int CLIP_COMMAND_GFLOAT = 3;
const int CLIP_COMMAND_ECOMPLEX = 4;
const int CLIP_COMMAND_FCOMPLEX = 5;
const int CLIP_COMMAND_GCOMPLEX = 6;
const int CLIP_COMMAND_PREC = 7;

const int CLIP_COMMAND_IFRACT = 8;
const int CLIP_COMMAND_MFRACT = 9;

const int CLIP_COMMAND_HTIME = 10;
const int CLIP_COMMAND_MTIME = 11;
const int CLIP_COMMAND_STIME = 12;
const int CLIP_COMMAND_FTIME = 13;
const int CLIP_COMMAND_FPS = 14;

const int CLIP_COMMAND_SCHAR = 15;
const int CLIP_COMMAND_UCHAR = 16;
const int CLIP_COMMAND_SSHORT = 17;
const int CLIP_COMMAND_USHORT = 18;
const int CLIP_COMMAND_SLONG = 19;
const int CLIP_COMMAND_ULONG = 20;
const int CLIP_COMMAND_SINT = 21;
const int CLIP_COMMAND_UINT = 22;
const int CLIP_COMMAND_RADIX = 23;

const int CLIP_COMMAND_FMULTIPREC = 24;
const int CLIP_COMMAND_IMULTIPREC = 25;

const int CLIP_COMMAND_PTYPE = 26;

const int CLIP_COMMAND_RAD = 27;
const int CLIP_COMMAND_DEG = 28;
const int CLIP_COMMAND_GRAD = 29;

const int CLIP_COMMAND_ANGLE = 30;

const int CLIP_COMMAND_ANS = 31;
const int CLIP_COMMAND_ASSERT = 32;
const int CLIP_COMMAND_WARN = 33;

const int CLIP_COMMAND_PARAM = 34;
const int CLIP_COMMAND_PARAMS = 35;

const int CLIP_COMMAND_DEFINE = 36;
const int CLIP_COMMAND_ENUM = 37;
const int CLIP_COMMAND_UNDEF = 38;
const int CLIP_COMMAND_VAR = 39;
const int CLIP_COMMAND_ARRAY = 40;
const int CLIP_COMMAND_LOCAL = 41;
const int CLIP_COMMAND_GLOBAL = 42;
const int CLIP_COMMAND_LABEL = 43;
const int CLIP_COMMAND_PARENT = 44;

const int CLIP_COMMAND_REAL = 45;
const int CLIP_COMMAND_IMAG = 46;

const int CLIP_COMMAND_NUM = 47;
const int CLIP_COMMAND_DENOM = 48;

const int CLIP_COMMAND_MAT = 49;
const int CLIP_COMMAND_TRANS = 50;

const int CLIP_COMMAND_SRAND = 51;
const int CLIP_COMMAND_LOCALTIME = 52;
const int CLIP_COMMAND_ARRAYCOPY = 53;
const int CLIP_COMMAND_ARRAYFILL = 54;

const int CLIP_COMMAND_STRCPY = 55;
const int CLIP_COMMAND_STRCAT = 56;
const int CLIP_COMMAND_STRLWR = 57;
const int CLIP_COMMAND_STRUPR = 58;

const int CLIP_COMMAND_CLEAR = 59;
const int CLIP_COMMAND_ERROR = 60;
const int CLIP_COMMAND_PRINT = 61;
const int CLIP_COMMAND_PRINTLN = 62;
const int CLIP_COMMAND_SPRINT = 63;
const int CLIP_COMMAND_SCAN = 64;

const int CLIP_COMMAND_GWORLD = 65;
const int CLIP_COMMAND_GWORLD24 = 66;
const int CLIP_COMMAND_GCLEAR = 67;
const int CLIP_COMMAND_GCOLOR = 68;
const int CLIP_COMMAND_GFILL = 69;
const int CLIP_COMMAND_GMOVE = 70;
const int CLIP_COMMAND_GTEXT = 71;
const int CLIP_COMMAND_GTEXTR = 72;
const int CLIP_COMMAND_GTEXTL = 73;
const int CLIP_COMMAND_GTEXTLR = 74;
const int CLIP_COMMAND_GLINE = 75;
const int CLIP_COMMAND_GPUT = 76;
const int CLIP_COMMAND_GPUT24 = 77;
const int CLIP_COMMAND_GGET = 78;
const int CLIP_COMMAND_GGET24 = 79;
const int CLIP_COMMAND_GUPDATE = 80;

const int CLIP_COMMAND_WINDOW = 81;
const int CLIP_COMMAND_WFILL = 82;
const int CLIP_COMMAND_WMOVE = 83;
const int CLIP_COMMAND_WTEXT = 84;
const int CLIP_COMMAND_WTEXTR = 85;
const int CLIP_COMMAND_WTEXTL = 86;
const int CLIP_COMMAND_WTEXTLR = 87;
const int CLIP_COMMAND_WLINE = 88;
const int CLIP_COMMAND_WPUT = 89;
const int CLIP_COMMAND_WGET = 90;

const int CLIP_COMMAND_RECTANGULAR = 91;
const int CLIP_COMMAND_PARAMETRIC = 92;
const int CLIP_COMMAND_POLAR = 93;
const int CLIP_COMMAND_LOGSCALE = 94;
const int CLIP_COMMAND_NOLOGSCALE = 95;
const int CLIP_COMMAND_PLOT = 96;
const int CLIP_COMMAND_REPLOT = 97;

const int CLIP_COMMAND_CALCULATOR = 98;

const int CLIP_COMMAND_INCLUDE = 99;

const int CLIP_COMMAND_BASE = 100;

const int CLIP_COMMAND_NAMESPACE = 101;

const int CLIP_COMMAND_USE = 102;
const int CLIP_COMMAND_UNUSE = 103;

const int CLIP_COMMAND_DUMP = 104;
const int CLIP_COMMAND_LOG = 105;

/*
 * 単一式の種類
 */

const int CLIP_SE_NULL = 0;

const int CLIP_SE_INCREMENT = 1;
const int CLIP_SE_DECREMENT = 2;
const int CLIP_SE_NEGATIVE = 3;

const int CLIP_SE_COMPLEMENT = 4;
const int CLIP_SE_NOT = 5;
const int CLIP_SE_MINUS = 6;

const int CLIP_SE_SET = 7;
const int CLIP_SE_SETC = 8;
const int CLIP_SE_SETF = 9;
const int CLIP_SE_SETM = 10;

const int CLIP_SE_MUL = 11;
const int CLIP_SE_DIV = 12;
const int CLIP_SE_MOD = 13;
const int CLIP_SE_ADD = 14;
const int CLIP_SE_ADDS = 15;
const int CLIP_SE_SUB = 16;
const int CLIP_SE_SUBS = 17;
const int CLIP_SE_POW = 18;
const int CLIP_SE_SHIFTL = 19;
const int CLIP_SE_SHIFTR = 20;
const int CLIP_SE_AND = 21;
const int CLIP_SE_OR = 22;
const int CLIP_SE_XOR = 23;

const int CLIP_SE_LESS = 24;
const int CLIP_SE_LESSOREQ = 25;
const int CLIP_SE_GREAT = 26;
const int CLIP_SE_GREATOREQ = 27;
const int CLIP_SE_EQUAL = 28;
const int CLIP_SE_NOTEQUAL = 29;
const int CLIP_SE_LOGAND = 30;
const int CLIP_SE_LOGOR = 31;

const int CLIP_SE_MUL_A = 32;
const int CLIP_SE_DIV_A = 33;
const int CLIP_SE_MOD_A = 34;
const int CLIP_SE_ADD_A = 35;
const int CLIP_SE_ADDS_A = 36;
const int CLIP_SE_SUB_A = 37;
const int CLIP_SE_SUBS_A = 38;
const int CLIP_SE_POW_A = 39;
const int CLIP_SE_SHIFTL_A = 40;
const int CLIP_SE_SHIFTR_A = 41;
const int CLIP_SE_AND_A = 42;
const int CLIP_SE_OR_A = 43;
const int CLIP_SE_XOR_A = 44;

const int CLIP_SE_LESS_A = 45;
const int CLIP_SE_LESSOREQ_A = 46;
const int CLIP_SE_GREAT_A = 47;
const int CLIP_SE_GREATOREQ_A = 48;
const int CLIP_SE_EQUAL_A = 49;
const int CLIP_SE_NOTEQUAL_A = 50;
const int CLIP_SE_LOGAND_A = 51;
const int CLIP_SE_LOGOR_A = 52;

const int CLIP_SE_CONDITIONAL = 53;

const int CLIP_SE_SET_FALSE = 54;
const int CLIP_SE_SET_TRUE = 55;
const int CLIP_SE_SET_ZERO = 56;

const int CLIP_SE_SATURATE = 57;
const int CLIP_SE_SETS = 58;

const int CLIP_SE_LOOPSTART = 59;
const int CLIP_SE_LOOPEND = 60;
const int CLIP_SE_LOOPEND_INC = 61;
const int CLIP_SE_LOOPEND_DEC = 62;
const int CLIP_SE_LOOPENDEQ = 63;
const int CLIP_SE_LOOPENDEQ_INC = 64;
const int CLIP_SE_LOOPENDEQ_DEC = 65;
const int CLIP_SE_LOOPCONT = 66;
const int CLIP_SE_CONTINUE = 67;
const int CLIP_SE_BREAK = 68;
const int CLIP_SE_RETURN = 69;
const int CLIP_SE_RETURN_ANS = 70;

const int CLIP_SE_FUNC = 71;

/*
 * エラー・コード
 */

const int CLIP_NO_ERR = 0x00; // 正常終了
const int CLIP_LOOP_STOP = 0x01; //
const int CLIP_LOOP_CONT = 0x02; //
const int CLIP_PROC_SUB_END = 0x03; //
const int CLIP_PROC_END = 0x04; //

const int CLIP_ERR_START = 0x100;

const int CLIP_LOOP_ERR = CLIP_ERR_START;

const int CLIP_LOOP_ERR_NULL = (CLIP_LOOP_ERR | 0x00); // トークンがありません
const int CLIP_LOOP_ERR_COMMAND = (CLIP_LOOP_ERR | 0x01); // コマンドはサポートされていません
const int CLIP_LOOP_ERR_STAT = (CLIP_LOOP_ERR | 0x02); // 制御構造はサポートされていません

const int CLIP_PROC_WARN = 0x1000;

const int CLIP_PROC_WARN_ARRAY = (CLIP_PROC_WARN | 0x00); // 配列の要素番号が負の値です
const int CLIP_PROC_WARN_DIV = (CLIP_PROC_WARN | 0x01); // ゼロで除算しました
const int CLIP_PROC_WARN_UNDERFLOW = (CLIP_PROC_WARN | 0x02); // アンダーフローしました
const int CLIP_PROC_WARN_OVERFLOW = (CLIP_PROC_WARN | 0x03); // オーバーフローしました
const int CLIP_PROC_WARN_ASIN = (CLIP_PROC_WARN | 0x04); // 関数asinの引数が-1から1の範囲外になりました
const int CLIP_PROC_WARN_ACOS = (CLIP_PROC_WARN | 0x05); // 関数acosの引数が-1から1の範囲外になりました
const int CLIP_PROC_WARN_ACOSH = (CLIP_PROC_WARN | 0x06); // 関数acoshの引数が1未満の値になりました
const int CLIP_PROC_WARN_ATANH = (CLIP_PROC_WARN | 0x07); // 関数atanhの引数が-1以下または1以上の値になりました
const int CLIP_PROC_WARN_LOG = (CLIP_PROC_WARN | 0x08); // 関数logの引数が0または負の値になりました
const int CLIP_PROC_WARN_LOG10 = (CLIP_PROC_WARN | 0x09); // 関数log10の引数が0または負の値になりました
const int CLIP_PROC_WARN_SQRT = (CLIP_PROC_WARN | 0x0A); // 関数sqrtの引数が負の値になりました
const int CLIP_PROC_WARN_FUNCTION = (CLIP_PROC_WARN | 0x0B); // 関数の引数が無効です
const int CLIP_PROC_WARN_RETURN = (CLIP_PROC_WARN | 0x0C); // returnで値を返すことができません
const int CLIP_PROC_WARN_DEAD_TOKEN = (CLIP_PROC_WARN | 0x0D); // 実行されないトークンです
const int CLIP_PROC_WARN_SE_RETURN = (CLIP_PROC_WARN | 0x0E); // $RETURN_Aで値を返すことができません

const int CLIP_ERROR = 0x2000;

const int CLIP_ERR_TOKEN = (CLIP_ERROR | 0x00); // 指定番号のトークンがありません
const int CLIP_ERR_ASSERT = (CLIP_ERROR | 0x01); // アサートに失敗しました

const int CLIP_PROC_ERR = (CLIP_ERROR | 0x100);

const int CLIP_PROC_ERR_UNARY = (CLIP_PROC_ERR | 0x00); // 単項演算子表現が間違っています
const int CLIP_PROC_ERR_OPERATOR = (CLIP_PROC_ERR | 0x01); // 演算子表現が間違っています
const int CLIP_PROC_ERR_ARRAY = (CLIP_PROC_ERR | 0x02); // 配列表現が間違っています
const int CLIP_PROC_ERR_FUNCTION = (CLIP_PROC_ERR | 0x03); // 関数の引数が間違っています
const int CLIP_PROC_ERR_LVALUE = (CLIP_PROC_ERR | 0x04); // 左辺は変数または配列でなければなりません
const int CLIP_PROC_ERR_RVALUE = (CLIP_PROC_ERR | 0x05); // 右辺は変数または配列でなければなりません
const int CLIP_PROC_ERR_RVALUE_NULL = (CLIP_PROC_ERR | 0x06); // 右辺がありません
const int CLIP_PROC_ERR_CONDITIONAL = (CLIP_PROC_ERR | 0x07); // 三項演算子の右辺に定数または変数が2個指定されていません
const int CLIP_PROC_ERR_EXTFUNC = (CLIP_PROC_ERR | 0x08); // 外部関数の実行が中断されました
const int CLIP_PROC_ERR_USERFUNC = (CLIP_PROC_ERR | 0x09); // ユーザー定義関数の実行が中断されました
const int CLIP_PROC_ERR_CONSTANT = (CLIP_PROC_ERR | 0x0A); // 定数表現が間違っています
const int CLIP_PROC_ERR_STRING = (CLIP_PROC_ERR | 0x0B); // 文字列表現が間違っています
const int CLIP_PROC_ERR_COMPLEX = (CLIP_PROC_ERR | 0x0C); // 複素数表現が間違っています
const int CLIP_PROC_ERR_FRACT = (CLIP_PROC_ERR | 0x0D); // 分数表現が間違っています
const int CLIP_PROC_ERR_ASS = (CLIP_PROC_ERR | 0x0E); // 定数への代入は無効です
const int CLIP_PROC_ERR_CALL = (CLIP_PROC_ERR | 0x0F); // 関数呼び出しに失敗しました
const int CLIP_PROC_ERR_EVAL = (CLIP_PROC_ERR | 0x10); // evalの実行が中断されました
const int CLIP_PROC_ERR_MULTIPREC = (CLIP_PROC_ERR | 0x11); // 多倍長数表現が間違っています

const int CLIP_PROC_ERR_STAT_IF = (CLIP_PROC_ERR | 0x20); // ifのネスト数が多すぎます
const int CLIP_PROC_ERR_STAT_ENDIF = (CLIP_PROC_ERR | 0x21); // endifに対応するifがありません
const int CLIP_PROC_ERR_STAT_SWITCH = (CLIP_PROC_ERR | 0x22); // switchのネスト数が多すぎます
const int CLIP_PROC_ERR_STAT_ENDSWI = (CLIP_PROC_ERR | 0x23); // endswiに対応するswitchがありません
const int CLIP_PROC_ERR_STAT_UNTIL = (CLIP_PROC_ERR | 0x24); // untilに対応するdoがありません
const int CLIP_PROC_ERR_STAT_ENDWHILE = (CLIP_PROC_ERR | 0x25); // endwhileに対応するwhileがありません
const int CLIP_PROC_ERR_STAT_FOR_CON = (CLIP_PROC_ERR | 0x26); // forにおける条件部がありません
const int CLIP_PROC_ERR_STAT_FOR_EXP = (CLIP_PROC_ERR | 0x27); // forにおける更新式がありません
const int CLIP_PROC_ERR_STAT_NEXT = (CLIP_PROC_ERR | 0x28); // nextに対応するforがありません
const int CLIP_PROC_ERR_STAT_CONTINUE = (CLIP_PROC_ERR | 0x29); // continueは無効です
const int CLIP_PROC_ERR_STAT_BREAK = (CLIP_PROC_ERR | 0x2A); // breakは無効です
const int CLIP_PROC_ERR_STAT_FUNC = (CLIP_PROC_ERR | 0x2B); // 関数の数が多すぎます
const int CLIP_PROC_ERR_STAT_FUNC_NEST = (CLIP_PROC_ERR | 0x2C); // 関数内で関数は定義できません
const int CLIP_PROC_ERR_STAT_ENDFUNC = (CLIP_PROC_ERR | 0x2D); // endfuncに対応するfuncがありません
const int CLIP_PROC_ERR_STAT_FUNCNAME = (CLIP_PROC_ERR | 0x2E); // 関数名は無効です
const int CLIP_PROC_ERR_STAT_FUNCPARAM = (CLIP_PROC_ERR | 0x2F); // 関数の引数にラベル設定できません
const int CLIP_PROC_ERR_STAT_LOOP = (CLIP_PROC_ERR | 0x30); // ループ回数オーバーしました
const int CLIP_PROC_ERR_STAT_END = (CLIP_PROC_ERR | 0x31); // endは無効です

const int CLIP_PROC_ERR_COMMAND_NULL = (CLIP_PROC_ERR | 0x40); // コマンドが間違っています
const int CLIP_PROC_ERR_COMMAND_PARAM = (CLIP_PROC_ERR | 0x41); // コマンドの引数が間違っています
const int CLIP_PROC_ERR_COMMAND_DEFINE = (CLIP_PROC_ERR | 0x42); // ラベルは既に定義されています
const int CLIP_PROC_ERR_COMMAND_UNDEF = (CLIP_PROC_ERR | 0x43); // ラベルは定義されていません
const int CLIP_PROC_ERR_COMMAND_PARAMS = (CLIP_PROC_ERR | 0x44); // コマンドの引数は10個までしか指定できません
const int CLIP_PROC_ERR_COMMAND_RADIX = (CLIP_PROC_ERR | 0x45); // コマンドradixは無効です

const int CLIP_PROC_ERR_FUNC_OPEN = (CLIP_PROC_ERR | 0x60); // 外部関数がオープンできません
const int CLIP_PROC_ERR_FUNC_PARANUM = (CLIP_PROC_ERR | 0x61); // 外部関数の引数は10個までしか指定できません
const int CLIP_PROC_ERR_FUNC_PARACODE = (CLIP_PROC_ERR | 0x62); // 外部関数の引数は定数、変数または配列名でなければなりません

const int CLIP_PROC_ERR_SE_NULL = (CLIP_PROC_ERR | 0x80); // 単一式が間違っています
const int CLIP_PROC_ERR_SE_OPERAND = (CLIP_PROC_ERR | 0x81); // 単一式のオペランドが間違っています
const int CLIP_PROC_ERR_SE_LOOPEND = (CLIP_PROC_ERR | 0x82); // $LOOPENDに対応する$LOOPSTARTがありません
const int CLIP_PROC_ERR_SE_CONTINUE = (CLIP_PROC_ERR | 0x83); // $CONTINUEは無効です
const int CLIP_PROC_ERR_SE_BREAK = (CLIP_PROC_ERR | 0x84); // $BREAKは無効です
const int CLIP_PROC_ERR_SE_LOOPCONT = (CLIP_PROC_ERR | 0x85); // $LOOPCONTに対応する$LOOPSTARTがありません

// グラフの種類
const int CLIP_GRAPH_MODE_RECT = 0; // 直交座標モード
const int CLIP_GRAPH_MODE_PARAM = 1; // 媒介変数モード
const int CLIP_GRAPH_MODE_POLAR = 2; // 極座標モード

// ラベルの状態
const int CLIP_LABEL_UNUSED = 0; // 未使用状態
const int CLIP_LABEL_USED = 1; // 使用状態
const int CLIP_LABEL_MOVABLE = 2; // 動的変数・配列

// 計算クラス用
const int CLIP_PROC_DEF_PARENT_MODE = CLIP_DEFMODE;
const int CLIP_PROC_DEF_PARENT_MP_PREC = CLIP_DEFMPPREC;
const int CLIP_PROC_DEF_PARENT_MP_ROUND = CLIP_DEFMPROUND;
const bool CLIP_PROC_DEF_PRINT_ASSERT = false;
const bool CLIP_PROC_DEF_PRINT_WARN = true;
const bool CLIP_PROC_DEF_GUPDATE_FLAG = true;

// 空白文字
const int CLIP_CHAR_CODE_SPACE = 0xA0;

// エスケープ文字
const String CLIP_CHAR_UTF8_YEN = '¥'/*0xC2A5*/;

// 分数表現で使う文字
const String CLIP_CHAR_FRACT = '⏌'/*0x23CC*/;

// 不正な配列の要素番号
const int CLIP_INVALID_ARRAY_INDEX = 0xFFFFFFFF/*ULONG_MAX*/;

// 空白文字かどうかチェック
bool isCharSpace( String str, int index ){
	return ((charAt( str, index ) == ' ') || (charCodeAt( str, index ) == CLIP_CHAR_CODE_SPACE));
}

// 改行文字かどうかチェック
bool isCharEnter( String str, int index ){
	String chr = charAt( str, index );
	return ((chr == '\r') || (chr == '\n'));
}

// エスケープ文字かどうかチェック
bool isCharEscape( String str, int index ){
	String chr = charAt( str, index );
	return ((chr == '\\') || (chr == CLIP_CHAR_UTF8_YEN));
}
