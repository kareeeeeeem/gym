import 'package:flutter/material.dart';
import 'package:fitnessapp/const/utils/app_colors.dart';

class RoundTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final String icon;
  final TextInputType textInputType;
  final bool isPassword;
  final bool readOnly; // 🔥 خاصية جديدة: للقراءة فقط
  final VoidCallback? onTap; // 🔥 خاصية جديدة: للاستجابة للنقر (للتاريخ)

  const RoundTextField({
    Key? key,
    this.controller,
    required this.hintText,
    required this.icon,
    required this.textInputType,
    this.isPassword = false,
    this.readOnly = false, // القيمة الافتراضية
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGrayColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
              alignment: Alignment.center,
              width: 50,
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Image.asset(
                icon,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
                color: AppColors.grayColor,
                 errorBuilder: (context, error, stackTrace) => const Icon(Icons.info, size: 20, color: AppColors.grayColor),
              )),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: textInputType,
              obscureText: isPassword,
              readOnly: readOnly, // 🔥 استخدام خاصية readOnly
              onTap: onTap, // 🔥 استخدام خاصية onTap
              style: const TextStyle(
                color: AppColors.blackColor,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                hintText: hintText,
                hintStyle: const TextStyle(
                    color: AppColors.grayColor, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 8)
        ],
      ),
    );
  }
}
