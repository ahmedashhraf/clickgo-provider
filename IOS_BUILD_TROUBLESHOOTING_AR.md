# دليل حل مشاكل بناء تطبيق iOS

## ❌ الخطأ: Provisioning Profile غير صالح

### وصف المشكلة:
```
Invalid Provisioning Profile. The provisioning profile included in the 
com.clickgo.provider bundle is invalid. [Missing code-signing certificate]
```

### الأسباب الرئيسية:
1. **نوع Provisioning Profile خاطئ**: استخدام Development بدلاً من Distribution
2. **شهادة مفقودة**: شهادة Distribution غير موجودة في الـ Provisioning Profile
3. **شهادة منتهية**: الشهادة انتهت صلاحيتها
4. **عدم تطابق Bundle ID**: الـ Bundle ID لا يطابق الـ Provisioning Profile

---

## ✅ الحلول

### الحل 1: إنشاء/تحديث Distribution Provisioning Profile

#### الخطوة 1: الذهاب إلى Apple Developer Portal
1. زيارة: https://developer.apple.com/account
2. الانتقال إلى: **Certificates, Identifiers & Profiles**

#### الخطوة 2: التحقق من/إنشاء شهادة Distribution
1. اذهب إلى **Certificates** → **All**
2. ابحث عن: شهادة **iOS Distribution**
3. إذا كانت مفقودة أو منتهية:
   - اضغط **+** لإنشاء جديدة
   - اختر **iOS Distribution**
   - اتبع الخطوات لإنشاء CSR وتحميل الشهادة

#### الخطوة 3: إنشاء App Store Distribution Provisioning Profile
1. اذهب إلى **Profiles** → **All**
2. اضغط **+** لإنشاء profile جديد
3. اختر: **App Store** (تحت Distribution)
4. اختر App ID: `com.clickgo.provider`
5. اختر شهادة **iOS Distribution** الخاصة بك
6. سمّها: `ClickGo Provider App Store`
7. حمّل الـ profile

---

### الحل 2: إعداد CodeMagic

#### الخطوة 1: إضافة الشهادات إلى CodeMagic
1. اذهب إلى لوحة تحكم CodeMagic
2. انتقل إلى: **Teams** → **Integrations**
3. اضغط على **App Store Connect** integration
4. أضف:
   - **Certificate (ملف .p12)**: شهادة iOS Distribution الخاصة بك
   - **Certificate password**: كلمة المرور التي حددتها عند التصدير
   - **Provisioning Profile**: ملف App Store profile الذي حملته

#### الخطوة 2: تحديث codemagic.yaml
تأكد من أن ملف `codemagic.yaml` يحتوي على:
```yaml
ios_signing:
  distribution_type: app_store
  bundle_identifier: com.clickgo.provider
```

#### الخطوة 3: التحقق من اسم Integration
في `codemagic.yaml`, تأكد من تطابق اسم الـ integration:
```yaml
integrations:
  app_store_connect: CodeMagic  # يجب أن يطابق اسم الـ integration الخاص بك
```

---

### الحل 3: البناء اليدوي (للاختبار المحلي)

إذا أردت الاختبار محلياً:

```bash
# 1. تنظيف البناء
flutter clean
cd ios
pod deintegrate
pod install
cd ..

# 2. البناء بدون توقيع (للاختبار)
flutter build ios --release --no-codesign

# 3. بناء IPA (يتطلب توقيع صحيح)
flutter build ipa --release
```

---

## 🔍 قائمة التحقق

قبل البناء لـ App Store:

- [ ] شهادة iOS Distribution صالحة (غير منتهية)
- [ ] App Store Distribution Provisioning Profile موجود لـ `com.clickgo.provider`
- [ ] Provisioning Profile يتضمن شهادة Distribution
- [ ] Bundle ID في Xcode يطابق: `com.clickgo.provider`
- [ ] الشهادات مضافة إلى CodeMagic Team integrations
- [ ] اسم Integration في `codemagic.yaml` يطابق لوحة تحكم CodeMagic
- [ ] `DEVELOPMENT_TEAM` في مشروع Xcode يطابق Team ID الخاص بك

---

## 📝 ملاحظات مهمة

### Bundle ID
- الحالي: `com.clickgo.provider`
- يجب أن يتطابق تماماً في:
  - مشروع Xcode
  - Apple Developer Portal
  - Provisioning Profile
  - codemagic.yaml

### Team ID
- الحالي في المشروع: `S5P9PXJ4TV`
- تحقق من أن هذا يطابق Apple Developer Team ID الخاص بك

### إصدار Xcode
- CodeMagic يستخدم: Xcode 15.2
- تأكد من أن provisioning profiles متوافقة

---

## 🆘 لا تزال تواجه مشاكل؟

### تحقق من سجلات بناء CodeMagic:
1. ابحث عن: رسائل "Provisioning profile"
2. تحقق من: "Code signing identity" المستخدم
3. تحقق من: تطابق بصمات الشهادات

### المشاكل الشائعة:
1. **اسم integration خاطئ**: تحقق من الإملاء في `codemagic.yaml`
2. **شهادة منتهية**: جدد الشهادة في Apple Developer Portal
3. **صلاحيات مفقودة**: تأكد من أن لديك صلاحيات Admin في حساب Apple Developer
4. **Bundle ID غير مسجل**: سجل التطبيق في App Store Connect أولاً

---

## 📞 معلومات الاتصال

لدعم CodeMagic:
- التوثيق: https://docs.codemagic.io/
- الدعم: support@codemagic.io

لدعم Apple Developer:
- البوابة: https://developer.apple.com/support/
