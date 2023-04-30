/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import 'math.dart';

double MATH_PI = 3.14159265358979323846264; // 円周率

class MathEnv {
	// _Complex用
	int _complexAngType = MATH_ANG_TYPE_RAD; // 角度の単位の種類
	bool _complexIsRad = true; // 角度の単位の種類がラジアンかどうかのフラグ
	double _complexAngCoef = MATH_PI; // ラジアンから現在の単位への変換用係数
	bool _complexIsReal = false; // 実数計算を行うかどうかのフラグ
	bool _complexErr = false; // エラーが起こったかどうかのフラグ

	// _Fract用
	bool _fractErr = false; // エラーが起こったかどうかのフラグ

	// _Matrix用
	bool _matrixErr = false; // エラーが起こったかどうかのフラグ

	// _Time用
	double _timeFps = 30.0; // 秒間フレーム数（グローバル）
	bool _timeErr = false; // エラーが起こったかどうかのフラグ

	// _Value用
	int _valueType = MATH_VALUE_TYPE_COMPLEX; // 型（グローバル）
}

MathEnv _mathEnv = MathEnv();
void setMathEnv( MathEnv env ){
	_mathEnv = env;
}

/*
 * _Complex用
 */

void setComplexAngType( int angType ){
	_mathEnv._complexAngType = angType;
	_mathEnv._complexIsRad = (_mathEnv._complexAngType == MATH_ANG_TYPE_RAD);
	_mathEnv._complexAngCoef = (_mathEnv._complexAngType == MATH_ANG_TYPE_DEG) ? 180.0 : 200.0;
}
int complexAngType(){
	return _mathEnv._complexAngType;
}
bool complexIsRad(){
	return _mathEnv._complexIsRad;
}
double complexAngCoef(){
	return _mathEnv._complexAngCoef;
}

void setComplexIsReal( bool isReal ){
	_mathEnv._complexIsReal = isReal;
}
bool complexIsReal(){
	return _mathEnv._complexIsReal;
}

void clearComplexError(){
	_mathEnv._complexErr = false;
}
void setComplexError(){
	_mathEnv._complexErr = true;
}
bool complexError(){
	return _mathEnv._complexErr;
}

/*
 * _Fract用
 */

void clearFractError(){
	_mathEnv._fractErr = false;
}
void setFractError(){
	_mathEnv._fractErr = true;
}
bool fractError(){
	return _mathEnv._fractErr;
}

/*
 * _Matrix用
 */

void clearMatrixError(){
	_mathEnv._matrixErr = false;
}
void setMatrixError(){
	_mathEnv._matrixErr = true;
}
bool matrixError(){
	return _mathEnv._matrixErr;
}

/*
 * _Time用
 */

void setTimeFps( double fps ){
	_mathEnv._timeFps = fps;
}
double timeFps(){
	return _mathEnv._timeFps;
}

void clearTimeError(){
	_mathEnv._timeErr = false;
}
void setTimeError(){
	_mathEnv._timeErr = true;
}
bool timeError(){
	return _mathEnv._timeErr;
}

/*
 * _Value用
 */

void setValueType( int type ){
	_mathEnv._valueType = type;
}
int valueType(){
	return _mathEnv._valueType;
}

void clearValueError(){
	clearComplexError();
	clearFractError();
	clearTimeError();
}
bool valueError(){
	return complexError() || fractError() || timeError();
}
