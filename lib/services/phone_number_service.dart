import 'package:country_picker/country_picker.dart';

class PhoneNumberService {
  const PhoneNumberService();

  String normalize(String value) {
    return value
        .replaceAll('+', '')
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('(', '')
        .replaceAll(')', '');
  }

  Country? findCountryFromE164Digits(String digits) {
    if (digits.isEmpty) return null;

    final List<Country> countries = CountryService().getAll();
    Country? matchedCountry;

    for (final Country country in countries) {
      final String code = country.phoneCode;
      if (digits.startsWith(code)) {
        if (matchedCountry == null || code.length > matchedCountry.phoneCode.length) {
          matchedCountry = country;
        }
      }
    }

    return matchedCountry;
  }

  ({Country? country, String localNumber}) parseStoredContact(String contactNumber) {
    final String raw = contactNumber.trim();
    if (raw.isEmpty) return (country: null, localNumber: '');

    final String digits = normalize(raw);
    if (digits.isEmpty) return (country: null, localNumber: '');

    if (raw.startsWith('+')) {
      final Country? matchedCountry = findCountryFromE164Digits(digits);
      if (matchedCountry != null) {
        return (
          country: matchedCountry,
          localNumber: digits.substring(matchedCountry.phoneCode.length),
        );
      }
    }

    return (country: null, localNumber: digits);
  }

  String buildE164({
    required String mobileNumber,
    required String countryCode,
  }) {
    final String rawMobile = mobileNumber.trim();
    if (rawMobile.isEmpty) return '';

    final String mobileDigits = normalize(rawMobile);
    if (mobileDigits.isEmpty) return '';

    if (rawMobile.startsWith('+')) {
      return '+$mobileDigits';
    }

    final String normalizedCountryCode = normalize(countryCode);
    if (normalizedCountryCode.isEmpty) return '+$mobileDigits';

    if (mobileDigits.startsWith(normalizedCountryCode)) {
      return '+$mobileDigits';
    }

    return '+$normalizedCountryCode$mobileDigits';
  }
}