/*
 * CLIP
 * Copyright (C) SatisKia. All rights reserved.
 */

import '../math/math.dart';

class Tm {
	int sec  = 0; // 秒 0～
	int min  = 0; // 分 0～
	int hour = 0; // 時 0～
	int mday = 1; // 日 1～
	int mon  = 0; // 1月からの月数
	int year = 0; // 1900年からの年数
	int wday = 0; // 日曜日からの日数
	int yday = 0; // 1月1日からの日数
	Tm(){
		localtime( time() );
	}
	static int time(){
		return DateTime.now().millisecondsSinceEpoch ~/ 1000;
	}
	int mktime(){
		DateTime date = DateTime(
				1900 + year,
				1 + mon,
				mday,
				hour,
				min,
				sec
		);
		return date.millisecondsSinceEpoch ~/ 1000;
	}
	Tm localtime( int t ){
		DateTime date = DateTime.fromMillisecondsSinceEpoch( t * 1000 );

		DateTime startDate = DateTime( date.year, 1, 1, 0, 0, 0 );

		sec  = date.second;
		min  = date.minute;
		hour = date.hour;
		mday = date.day;
		mon  = date.month - 1;
		year = date.year - 1900;
		wday = ClipMath.imod( date.weekday, 7 );
		yday = (date.millisecondsSinceEpoch - startDate.millisecondsSinceEpoch) ~/ 86400000;

		return this;
	}
}
