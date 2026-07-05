import 'package:flutter/widgets.dart';
TextDirection detectTextDirection(String? text) => (text != null && RegExp(r'[\u0600-\u06FF]').hasMatch(text)) ? TextDirection.rtl : TextDirection.ltr;
class SmartText extends StatelessWidget {
  final String value; final TextStyle? style; final int? maxLines; final TextOverflow? overflow;
  const SmartText(this.value,{super.key,this.style,this.maxLines,this.overflow});
  @override Widget build(BuildContext context)=>Directionality(textDirection: detectTextDirection(value), child: Text(value,style:style,maxLines:maxLines,overflow:overflow));
}
