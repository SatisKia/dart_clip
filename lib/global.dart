/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

/*
 * パラメータ関連
 */

import 'math/math.dart';
import 'math/multiprec.dart';

class ClipGlobal {
	static const int modeFloat = 0x0010;
	static const int modeComplex = 0x0020;
	static const int modeFract = 0x0040;
	static const int modeTime = 0x0080;
	static const int modeInt = 0x0100;
	static const int modeEFloat = (modeFloat | 0);
	static const int modeFFloat = (modeFloat | 1);
	static const int modeGFloat = (modeFloat | 2);
	static const int modeEComplex = (modeComplex | 0);
	static const int modeFComplex = (modeComplex | 1);
	static const int modeGComplex = (modeComplex | 2);
	static const int modeIFract = (modeFract | 0); // Improper FRACTion
	static const int modeMFract = (modeFract | 1); // Mixed FRACTion
	static const int modeHTime = (modeTime | 0);
	static const int modeMTime = (modeTime | 1);
	static const int modeSTime = (modeTime | 2);
	static const int modeFTime = (modeTime | 3);
	static const int modeSChar = (modeInt | 0); // Signed
	static const int modeUChar = (modeInt | 1); // Unsigned
	static const int modeSShort = (modeInt | 2); // Signed
	static const int modeUShort = (modeInt | 3); // Unsigned
	static const int modeSLong = (modeInt | 4); // Signed
	static const int modeULong = (modeInt | 5); // Unsigned
	static const int modeMask = 0x0FFF;
	static const int modeMultiPrec = 0x1000;
	static const int modeFMultiPrec = (modeMultiPrec | modeFFloat);
	static const int modeIMultiPrec = (modeMultiPrec | modeSLong);

	static const int defMode = modeGFloat;

	static const double defFps = 30.0;

	static const int minPrec = 0;
	static const int defPrec = 6;

	static const int minRadix = 2;
	static const int maxRadix = 36;
	static const int defRadix = 10;

	static const int minMPPrec = 0;
	static const int defMPPrec = 0;

	static const int defMPRound = MultiPrec.froundHalfEven;

	/*
	 * 識別コード
	 */

	static const int codeMask = 0x1F;
	static const int codeVarMask = 0x20;
	static const int codeArrayMask = 0x40;

	static const int codeTop = 0; // (

	static const int codeVariable = (1 | codeVarMask); // 変数
	static const int codeAutoVar = (2 | codeVarMask); // 動的変数
	static const int codeGlobalVar = (3 | codeVarMask); // グローバル変数

	static const int codeArray = (4 | codeArrayMask); // 配列
	static const int codeAutoArray = (5 | codeArrayMask); // 動的配列
	static const int codeGlobalArray = (6 | codeArrayMask); // グローバル配列

	static const int codeConstant = 7; // 定数
	static const int codeMultiPrec = 8; // 多倍長数
	static const int codeLabel = 9; // ラベル
	static const int codeCommand = 10; // コマンド
	static const int codeStatement = 11; // 文
	static const int codeOperator = 12; // 演算子
	static const int codeFunction = 13; // 関数
	static const int codeExtFunc = 14; // 外部関数

	static const int codeProcEnd = 15;

	static const int codeNull = codeProcEnd;

	static const int codeEnd = 16; // )

	static const int codeArrayTop = 17; // {
	static const int codeArrayEnd = 18; // }

	static const int codeMatrix = 19; // 行列
	static const int codeString = 20; // 文字列

	static const int codeParamAns = 21; // &
	static const int codeParamArray = 22; // []

	static const int codeSe = 23; // 単一式

	/*
	 * 演算子の種類
	 */

	static const int opIncrement = 0; // [++]
	static const int opDecrement = 1; // [--]
	static const int opComplement = 2; // [~]
	static const int opNot = 3; // [!]
	static const int opMinus = 4; // [-]
	static const int opPlus = 5; // [+]

	static const int opUnaryEnd = 6;

	static const int opPostfixInc = opUnaryEnd; // ++
	static const int opPostfixDec = 7; // --

	static const int opMul = 8; // *
	static const int opDiv = 9; // /
	static const int opMod = 10; // %

	static const int opAdd = 11; // +
	static const int opSub = 12; // -

	static const int opShiftL = 13; // <<
	static const int opShiftR = 14; // >>

	static const int opLess = 15; // <
	static const int opLessOrEq = 16; // <=
	static const int opGreat = 17; // >
	static const int opGreatOrEq = 18; // >=

	static const int opEqual = 19; // ==
	static const int opNotEqual = 20; // !=

	static const int opAnd = 21; // &

	static const int opXor = 22; // ^

	static const int opOr = 23; // |

	static const int opLogAnd = 24; // &&

	static const int opLogOr = 25; // ||

	static const int opConditional = 26; // ?

	static const int opAss = 27; // =
	static const int opMulAndAss = 28; // *=
	static const int opDivAndAss = 29; // /=
	static const int opModAndAss = 30; // %=
	static const int opAddAndAss = 31; // +=
	static const int opSubAndAss = 32; // -=
	static const int opShiftLAndAss = 33; // <<=
	static const int opShiftRAndAss = 34; // >>=
	static const int opAndAndAss = 35; // &=
	static const int opOrAndAss = 36; // |=
	static const int opXorAndAss = 37; // ^=

	static const int opComma = 38; // ,

	static const int opPow = 39; // **
	static const int opPowAndAss = 40; // **=

	static const int opFact = 41; // !

	/*
	 * 関数の種類
	 */

	static const int funcDefined = 0;
	static const int funcIndexOf = 1;

	static const int funcIsInf = 2;
	static const int funcIsNan = 3;

	static const int funcRand = 4;
	static const int funcTime = 5;
	static const int funcMkTime = 6;
	static const int funcTmSec = 7;
	static const int funcTmMin = 8;
	static const int funcTmHour = 9;
	static const int funcTmMDay = 10;
	static const int funcTmMon = 11;
	static const int funcTmYear = 12;
	static const int funcTmWDay = 13;
	static const int funcTmYDay = 14;
	static const int funcTmXMon = 15;
	static const int funcTmXYear = 16;

	static const int funcA2D = 17;
	static const int funcA2G = 18;
	static const int funcA2R = 19;
	static const int funcD2A = 20;
	static const int funcD2G = 21;
	static const int funcD2R = 22;
	static const int funcG2A = 23;
	static const int funcG2D = 24;
	static const int funcG2R = 25;
	static const int funcR2A = 26;
	static const int funcR2D = 27;
	static const int funcR2G = 28;

	static const int funcSin = 29;
	static const int funcCos = 30;
	static const int funcTan = 31;
	static const int funcAsin = 32;
	static const int funcAcos = 33;
	static const int funcAtan = 34;
	static const int funcAtan2 = 35;
	static const int funcSinh = 36;
	static const int funcCosh = 37;
	static const int funcTanh = 38;
	static const int funcAsinh = 39;
	static const int funcAcosh = 40;
	static const int funcAtanh = 41;
	static const int funcExp = 42;
	static const int funcExp10 = 43;
	static const int funcLn = 44;
	static const int funcLog = 45;
	static const int funcLog10 = 46;
	static const int funcPow = 47;
	static const int funcSqr = 48;
	static const int funcSqrt = 49;
	static const int funcCeil = 50;
	static const int funcFloor = 51;
	static const int funcAbs = 52;
	static const int funcLdexp = 53;
	static const int funcFrexp = 54;
	static const int funcModf = 55;
	static const int funcFact = 56;

	static const int funcInt = 57;
	static const int funcReal = 58;
	static const int funcImag = 59;
	static const int funcArg = 60;
	static const int funcNorm = 61;
	static const int funcConjg = 62;
	static const int funcPolar = 63;

	static const int funcNum = 64;
	static const int funcDenom = 65;

	static const int funcRow = 66;
	static const int funcCol = 67;
	static const int funcTrans = 68;

	static const int funcStrCmp = 69;
	static const int funcStrICmp = 70;
	static const int funcStrLen = 71;

	static const int funcGWidth = 72;
	static const int funcGHeight = 73;
	static const int funcGColor = 74;
	static const int funcGColor24 = 75;
	static const int funcGCX = 76;
	static const int funcGCY = 77;
	static const int funcWCX = 78;
	static const int funcWCY = 79;
	static const int funcGGet = 80;
	static const int funcWGet = 81;
	static const int funcGX = 82;
	static const int funcGY = 83;
	static const int funcWX = 84;
	static const int funcWY = 85;
	static const int funcMkColor = 86;
	static const int funcMkColors = 87;
	static const int funcColGetR = 88;
	static const int funcColGetG = 89;
	static const int funcColGetB = 90;

	static const int funcCall = 91;
	static const int funcEval = 92;

	static const int funcMP = 93;
	static const int funcMRound = 94;

	/*
	 * 文の種類
	 */

	static const int statStart = 0;
	static const int statEnd = 1;
	static const int statEndInc = 2;
	static const int statEndDec = 3;
	static const int statEndEq = 4;
	static const int statEndEqInc = 5;
	static const int statEndEqDec = 6;
	static const int statCont = 7;

	static const int statDo = 8;
	static const int statUntil = 9;

	static const int statWhile = 10;
	static const int statEndWhile = 11;

	static const int statFor = 12;
	static const int statFor2 = 13;
	static const int statNext = 14;

	static const int statFunc = 15;
	static const int statEndFunc = 16;

	static const int statMultiEnd = 17;

	static const int statLoopEnd = 18;

	static const int statIf = statLoopEnd;
	static const int statElIf = 19;
	static const int statElse = 20;
	static const int statEndIf = 21;

	static const int statSwitch = 22;
	static const int statCase = 23;
	static const int statDefault = 24;
	static const int statEndSwi = 25;
	static const int statBreakSwi = 26;

	static const int statContinue = 27;
	static const int statBreak = 28;
	static const int statContinue2 = 29;
	static const int statBreak2 = 30;

	static const int statAssert = 31;
	static const int statReturn = 32;
	static const int statReturn2 = 33;
	static const int statReturn3 = 34;

	/*
	 * コマンドの種類
	 */

	static const int commandNull = 0;

	static const int commandEFloat = 1;
	static const int commandFFloat = 2;
	static const int commandGFloat = 3;
	static const int commandEComplex = 4;
	static const int commandFComplex = 5;
	static const int commandGComplex = 6;
	static const int commandPrec = 7;

	static const int commandIFract = 8;
	static const int commandMFract = 9;

	static const int commandHTime = 10;
	static const int commandMTime = 11;
	static const int commandSTime = 12;
	static const int commandFTime = 13;
	static const int commandFps = 14;

	static const int commandSChar = 15;
	static const int commandUChar = 16;
	static const int commandSShort = 17;
	static const int commandUShort = 18;
	static const int commandSLong = 19;
	static const int commandULong = 20;
	static const int commandSInt = 21;
	static const int commandUInt = 22;
	static const int commandRadix = 23;

	static const int commandFMultiPrec = 24;
	static const int commandIMultiPrec = 25;

	static const int commandPType = 26;

	static const int commandRad = 27;
	static const int commandDeg = 28;
	static const int commandGrad = 29;

	static const int commandAngle = 30;

	static const int commandAns = 31;
	static const int commandAssert = 32;
	static const int commandWarn = 33;

	static const int commandParam = 34;
	static const int commandParams = 35;

	static const int commandDefine = 36;
	static const int commandEnum = 37;
	static const int commandUndef = 38;
	static const int commandVar = 39;
	static const int commandArray = 40;
	static const int commandLocal = 41;
	static const int commandGlobal = 42;
	static const int commandLabel = 43;
	static const int commandParent = 44;

	static const int commandReal = 45;
	static const int commandImag = 46;

	static const int commandNum = 47;
	static const int commandDenom = 48;

	static const int commandMat = 49;
	static const int commandTrans = 50;

	static const int commandSrand = 51;
	static const int commandLocaltime = 52;
	static const int commandArrayCopy = 53;
	static const int commandArrayFill = 54;

	static const int commandStrCpy = 55;
	static const int commandStrCat = 56;
	static const int commandStrLwr = 57;
	static const int commandStrUpr = 58;

	static const int commandClear = 59;
	static const int commandError = 60;
	static const int commandPrint = 61;
	static const int commandPrintLn = 62;
	static const int commandSprint = 63;
	static const int commandScan = 64;

	static const int commandGWorld = 65;
	static const int commandGWorld24 = 66;
	static const int commandGClear = 67;
	static const int commandGColor = 68;
	static const int commandGFill = 69;
	static const int commandGMove = 70;
	static const int commandGText = 71;
	static const int commandGTextR = 72;
	static const int commandGTextL = 73;
	static const int commandGTextLR = 74;
	static const int commandGLine = 75;
	static const int commandGPut = 76;
	static const int commandGPut24 = 77;
	static const int commandGGet = 78;
	static const int commandGGet24 = 79;
	static const int commandGUpdate = 80;

	static const int commandWindow = 81;
	static const int commandWFill = 82;
	static const int commandWMove = 83;
	static const int commandWText = 84;
	static const int commandWTextR = 85;
	static const int commandWTextL = 86;
	static const int commandWTextLR = 87;
	static const int commandWLine = 88;
	static const int commandWPut = 89;
	static const int commandWGet = 90;

	static const int commandRectangular = 91;
	static const int commandParametric = 92;
	static const int commandPolar = 93;
	static const int commandLogscale = 94;
	static const int commandNoLogscale = 95;
	static const int commandPlot = 96;
	static const int commandReplot = 97;

	static const int commandCalculator = 98;

	static const int commandInclude = 99;

	static const int commandBase = 100;

	static const int commandNamespace = 101;

	static const int commandUse = 102;
	static const int commandUnuse = 103;

	static const int commandDump = 104;
	static const int commandLog = 105;

	/*
	 * 単一式の種類
	 */

	static const int seNull = 0;

	static const int seIncrement = 1;
	static const int seDecrement = 2;
	static const int seNegative = 3;

	static const int seComplement = 4;
	static const int seNot = 5;
	static const int seMinus = 6;

	static const int seSet = 7;
	static const int seSetC = 8;
	static const int seSetF = 9;
	static const int seSetM = 10;

	static const int seMul = 11;
	static const int seDiv = 12;
	static const int seMod = 13;
	static const int seAdd = 14;
	static const int seAddS = 15;
	static const int seSub = 16;
	static const int seSubS = 17;
	static const int sePow = 18;
	static const int seShiftL = 19;
	static const int seShiftR = 20;
	static const int seAnd = 21;
	static const int seOr = 22;
	static const int seXor = 23;

	static const int seLess = 24;
	static const int seLessOrEq = 25;
	static const int seGreat = 26;
	static const int seGreatOrEq = 27;
	static const int seEqual = 28;
	static const int seNotEqual = 29;
	static const int seLogAnd = 30;
	static const int seLogOr = 31;

	static const int seMulA = 32;
	static const int seDivA = 33;
	static const int seModA = 34;
	static const int seAddA = 35;
	static const int seAddSA = 36;
	static const int seSubA = 37;
	static const int seSubSA = 38;
	static const int sePowA = 39;
	static const int seShiftLA = 40;
	static const int seShiftRA = 41;
	static const int seAndA = 42;
	static const int seOrA = 43;
	static const int seXorA = 44;

	static const int seLessA = 45;
	static const int seLessOrEqA = 46;
	static const int seGreatA = 47;
	static const int seGreatOrEqA = 48;
	static const int seEqualA = 49;
	static const int seNotEqualA = 50;
	static const int seLogAndA = 51;
	static const int seLogOrA = 52;

	static const int seConditional = 53;

	static const int seSetFalse = 54;
	static const int seSetTrue = 55;
	static const int seSetZero = 56;

	static const int seSaturate = 57;
	static const int seSetS = 58;

	static const int seLoopStart = 59;
	static const int seLoopEnd = 60;
	static const int seLoopEndInc = 61;
	static const int seLoopEndDec = 62;
	static const int seLoopEndEq = 63;
	static const int seLoopEndEqInc = 64;
	static const int seLoopEndEqDec = 65;
	static const int seLoopCont = 66;
	static const int seContinue = 67;
	static const int seBreak = 68;
	static const int seReturn = 69;
	static const int seReturnAns = 70;

	static const int seFunc = 71;

	/*
	 * エラー・コード
	 */

	static const int noErr = 0x00; // 正常終了
	static const int loopStop = 0x01; //
	static const int loopCont = 0x02; //
	static const int procSubEnd = 0x03; //
	static const int procEnd = 0x04; //

	static const int errStart = 0x100;

	static const int loopErr = errStart;

	static const int loopErrNull = (loopErr | 0x00); // トークンがありません
	static const int loopErrCommand = (loopErr | 0x01); // コマンドはサポートされていません
	static const int loopErrStat = (loopErr | 0x02); // 制御構造はサポートされていません

	static const int procWarn = 0x1000;

	static const int procWarnArray = (procWarn | 0x00); // 配列の要素番号が負の値です
	static const int procWarnDiv = (procWarn | 0x01); // ゼロで除算しました
	static const int procWarnUnderflow = (procWarn | 0x02); // アンダーフローしました
	static const int procWarnOverflow = (procWarn | 0x03); // オーバーフローしました
	static const int procWarnAsin = (procWarn | 0x04); // 関数asinの引数が-1から1の範囲外になりました
	static const int procWarnAcos = (procWarn | 0x05); // 関数acosの引数が-1から1の範囲外になりました
	static const int procWarnAcosh = (procWarn | 0x06); // 関数acoshの引数が1未満の値になりました
	static const int procWarnAtanh = (procWarn | 0x07); // 関数atanhの引数が-1以下または1以上の値になりました
	static const int procWarnLog = (procWarn | 0x08); // 関数logの引数が0または負の値になりました
	static const int procWarnLog10 = (procWarn | 0x09); // 関数log10の引数が0または負の値になりました
	static const int procWarnSqrt = (procWarn | 0x0A); // 関数sqrtの引数が負の値になりました
	static const int procWarnFunction = (procWarn | 0x0B); // 関数の引数が無効です
	static const int procWarnReturn = (procWarn | 0x0C); // returnで値を返すことができません
	static const int procWarnDeadToken = (procWarn | 0x0D); // 実行されないトークンです
	static const int procWarnSeReturn = (procWarn | 0x0E); // $RETURN_Aで値を返すことができません

	static const int error = 0x2000;

	static const int errToken = (error | 0x00); // 指定番号のトークンがありません
	static const int errAssert = (error | 0x01); // アサートに失敗しました

	static const int procErr = (error | 0x100);

	static const int procErrUnary = (procErr | 0x00); // 単項演算子表現が間違っています
	static const int procErrOperator = (procErr | 0x01); // 演算子表現が間違っています
	static const int procErrArray = (procErr | 0x02); // 配列表現が間違っています
	static const int procErrFunction = (procErr | 0x03); // 関数の引数が間違っています
	static const int procErrLValue = (procErr | 0x04); // 左辺は変数または配列でなければなりません
	static const int procErrRValue = (procErr | 0x05); // 右辺は変数または配列でなければなりません
	static const int procErrRValueNull = (procErr | 0x06); // 右辺がありません
	static const int procErrConditional = (procErr | 0x07); // 三項演算子の右辺に定数または変数が2個指定されていません
	static const int procErrExtFunc = (procErr | 0x08); // 外部関数の実行が中断されました
	static const int procErrUserFunc = (procErr | 0x09); // ユーザー定義関数の実行が中断されました
	static const int procErrConstant = (procErr | 0x0A); // 定数表現が間違っています
	static const int procErrString = (procErr | 0x0B); // 文字列表現が間違っています
	static const int procErrComplex = (procErr | 0x0C); // 複素数表現が間違っています
	static const int procErrFract = (procErr | 0x0D); // 分数表現が間違っています
	static const int procErrAss = (procErr | 0x0E); // 定数への代入は無効です
	static const int procErrCall = (procErr | 0x0F); // 関数呼び出しに失敗しました
	static const int procErrEval = (procErr | 0x10); // evalの実行が中断されました
	static const int procErrMultiPrec = (procErr | 0x11); // 多倍長数表現が間違っています

	static const int procErrStatIf = (procErr | 0x20); // ifのネスト数が多すぎます
	static const int procErrStatEndIf = (procErr | 0x21); // endifに対応するifがありません
	static const int procErrStatSwitch = (procErr | 0x22); // switchのネスト数が多すぎます
	static const int procErrStatEndSwi = (procErr | 0x23); // endswiに対応するswitchがありません
	static const int procErrStatUntil = (procErr | 0x24); // untilに対応するdoがありません
	static const int procErrStatEndWhile = (procErr | 0x25); // endwhileに対応するwhileがありません
	static const int procErrStatForCon = (procErr | 0x26); // forにおける条件部がありません
	static const int procErrStatForExp = (procErr | 0x27); // forにおける更新式がありません
	static const int procErrStatNext = (procErr | 0x28); // nextに対応するforがありません
	static const int procErrStatContinue = (procErr | 0x29); // continueは無効です
	static const int procErrStatBreak = (procErr | 0x2A); // breakは無効です
	static const int procErrStatFunc = (procErr | 0x2B); // 関数の数が多すぎます
	static const int procErrStatFuncNest = (procErr | 0x2C); // 関数内で関数は定義できません
	static const int procErrStatEndFunc = (procErr | 0x2D); // endfuncに対応するfuncがありません
	static const int procErrStatFuncName = (procErr | 0x2E); // 関数名は無効です
	static const int procErrStatFuncParam = (procErr | 0x2F); // 関数の引数にラベル設定できません
	static const int procErrStatLoop = (procErr | 0x30); // ループ回数オーバーしました
	static const int procErrStatEnd = (procErr | 0x31); // endは無効です

	static const int procErrCommandNull = (procErr | 0x40); // コマンドが間違っています
	static const int procErrCommandParam = (procErr | 0x41); // コマンドの引数が間違っています
	static const int procErrCommandDefine = (procErr | 0x42); // ラベルは既に定義されています
	static const int procErrCommandUndef = (procErr | 0x43); // ラベルは定義されていません
	static const int procErrCommandParams = (procErr | 0x44); // コマンドの引数は10個までしか指定できません
	static const int procErrCommandRadix = (procErr | 0x45); // コマンドradixは無効です

	static const int procErrFuncOpen = (procErr | 0x60); // 外部関数がオープンできません
	static const int procErrFuncParaNum = (procErr | 0x61); // 外部関数の引数は10個までしか指定できません
	static const int procErrFuncParaCode = (procErr | 0x62); // 外部関数の引数は定数、変数または配列名でなければなりません

	static const int procErrSeNull = (procErr | 0x80); // 単一式が間違っています
	static const int procErrSeOperand = (procErr | 0x81); // 単一式のオペランドが間違っています
	static const int procErrSeLoopEnd = (procErr | 0x82); // $LOOPENDに対応する$LOOPSTARTがありません
	static const int procErrSeContinue = (procErr | 0x83); // $CONTINUEは無効です
	static const int procErrSeBreak = (procErr | 0x84); // $BREAKは無効です
	static const int procErrSeLoopCont = (procErr | 0x85); // $LOOPCONTに対応する$LOOPSTARTがありません

	// グラフの種類
	static const int graphModeRect = 0; // 直交座標モード
	static const int graphModeParam = 1; // 媒介変数モード
	static const int graphModePolar = 2; // 極座標モード

	// ラベルの状態
	static const int labelUnused = 0; // 未使用状態
	static const int labelUsed = 1; // 使用状態
	static const int labelMovable = 2; // 動的変数・配列

	// 計算クラス用
	static const int procDefParentMode = defMode;
	static const int procDefParentMPPrec = defMPPrec;
	static const int procDefParentMPRound = defMPRound;
	static const bool procDefPrintAssert = false;
	static const bool procDefPrintWarn = true;
	static const bool procDefGUpdateFlag = true;

	// 空白文字
	static const int charCodeSpace = 0xA0;

	// エスケープ文字
	static const String charUtf8Yen = '¥'/*0xC2A5*/;

	// 分数表現で使う文字
	static const String charFract = '⏌'/*0x23CC*/;

	// 不正な配列の要素番号
	static const int invalidArrayIndex = 0xFFFFFFFF/*ULONG_MAX*/;

	// 空白文字かどうかチェック
	static bool isCharSpace( String str, int index ){
		return ((ClipMath.charAt( str, index ) == ' ') || (ClipMath.charCodeAt( str, index ) == charCodeSpace));
	}

	// 改行文字かどうかチェック
	static bool isCharEnter( String str, int index ){
		String chr = ClipMath.charAt( str, index );
		return ((chr == '\r') || (chr == '\n'));
	}

	// エスケープ文字かどうかチェック
	static bool isCharEscape( String str, int index ){
		String chr = ClipMath.charAt( str, index );
		return ((chr == '\\') || (chr == charUtf8Yen));
	}
}
