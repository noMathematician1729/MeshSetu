import 'package:flutter/widgets.dart';

/// Small app-owned localization layer for the four languages supported by the
/// profile and offline voice input. Unmapped dynamic content (names, SOS text,
/// room names, and server messages) is deliberately left untouched.
class MeshLocalizations {
  const MeshLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
    Locale('gu'),
  ];

  static const delegate = _MeshLocalizationsDelegate();

  static MeshLocalizations of(BuildContext context) =>
      Localizations.of<MeshLocalizations>(context, MeshLocalizations) ??
      const MeshLocalizations(Locale('en'));

  String text(String value) =>
      _translations[locale.languageCode]?[value] ?? value;

  String languageName(String code) => switch (code) {
    'hi' => text('Hindi'),
    'mr' => text('Marathi'),
    'gu' => text('Gujarati'),
    _ => text('English'),
  };

  String holdToActivate(int seconds) => switch (locale.languageCode) {
    'hi' => 'आपातकालीन प्रोटोकॉल सक्रिय करने के लिए $seconds सेकंड दबाकर रखें',
    'mr' => 'आपत्कालीन प्रक्रिया सुरू करण्यासाठी $seconds सेकंद दाबून ठेवा',
    'gu' => 'કટોકટી પ્રોટોકોલ સક્રિય કરવા માટે $seconds સેકન્ડ દબાવી રાખો',
    _ => 'Press and hold for $seconds seconds to activate emergency protocol',
  };
}

extension MeshLocalizationsContext on BuildContext {
  MeshLocalizations get meshL10n => MeshLocalizations.of(this);
}

class _MeshLocalizationsDelegate
    extends LocalizationsDelegate<MeshLocalizations> {
  const _MeshLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => MeshLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<MeshLocalizations> load(Locale locale) async =>
      MeshLocalizations(locale);

  @override
  bool shouldReload(_MeshLocalizationsDelegate old) => false;
}

const _translations = <String, Map<String, String>>{
  'hi': {
    'Home': 'होम',
    'Rooms': 'कमरे',
    'Activity': 'गतिविधि',
    'You': 'आप',
    'Profile': 'प्रोफ़ाइल',
    'Settings': 'सेटिंग्स',
    'Language': 'भाषा',
    'Preferred language': 'पसंदीदा भाषा',
    'English': 'अंग्रेज़ी',
    'Hindi': 'हिन्दी',
    'Marathi': 'मराठी',
    'Gujarati': 'गुजराती',
    'Emergency Aid': 'आपातकालीन सहायता',
    'One tap away from help': 'मदद बस एक टैप दूर',
    'Open profile': 'प्रोफ़ाइल खोलें',
    'Emergency type': 'आपातकाल का प्रकार',
    'Voice input': 'आवाज़ से जानकारी',
    'Speak details': 'विवरण बोलें',
    'Tap to record again': 'फिर से रिकॉर्ड करने के लिए टैप करें',
    'Describe SOS': 'SOS का विवरण दें',
    'Add context': 'जानकारी जोड़ें',
    'Create': 'बनाएँ',
    'Join': 'जुड़ें',
    'Coordinate securely with people nearby':
        'पास के लोगों के साथ सुरक्षित रूप से समन्वय करें',
    'Medical information': 'चिकित्सा जानकारी',
    'Trusted contacts': 'विश्वसनीय संपर्क',
    'Reporter ID': 'रिपोर्टर आईडी',
    'Blood type': 'रक्त समूह',
    'Allergies': 'एलर्जी',
    'Medical conditions': 'चिकित्सीय स्थितियाँ',
    'Not provided': 'नहीं दिया गया',
    'Edit emergency profile': 'आपातकालीन प्रोफ़ाइल संपादित करें',
    'Edit profile': 'प्रोफ़ाइल संपादित करें',
    'Accessibility': 'सुलभता',
    'High contrast mode': 'उच्च कॉन्ट्रास्ट मोड',
    'Dark mode': 'डार्क मोड',
    'Emergency settings': 'आपातकालीन सेटिंग्स',
    'Attach location to SOS': 'SOS के साथ स्थान जोड़ें',
    'Location details': 'स्थान विवरण',
    'Reprogram gestures': 'जेस्चर बदलें',
    'Emergency gateway': 'आपातकालीन गेटवे',
    'Save emergency profile': 'आपातकालीन प्रोफ़ाइल सहेजें',
    'Your details': 'आपकी जानकारी',
    'Emergency contacts': 'आपातकालीन संपर्क',
    'Medical details': 'चिकित्सा विवरण',
    'Try again': 'फिर से प्रयास करें',
    'Create profile': 'प्रोफ़ाइल बनाएँ',
    'Profile unavailable': 'प्रोफ़ाइल उपलब्ध नहीं है',
    'Connectivity': 'कनेक्टिविटी',
  },
  'mr': {
    'Home': 'मुख्यपृष्ठ',
    'Rooms': 'रूम्स',
    'Activity': 'क्रियाकलाप',
    'You': 'तुम्ही',
    'Profile': 'प्रोफाइल',
    'Settings': 'सेटिंग्ज',
    'Language': 'भाषा',
    'Preferred language': 'पसंतीची भाषा',
    'English': 'इंग्रजी',
    'Hindi': 'हिंदी',
    'Marathi': 'मराठी',
    'Gujarati': 'गुजराती',
    'Emergency Aid': 'आपत्कालीन मदत',
    'One tap away from help': 'मदत फक्त एका टॅपवर',
    'Open profile': 'प्रोफाइल उघडा',
    'Emergency type': 'आपत्कालाचा प्रकार',
    'Voice input': 'आवाजाने माहिती',
    'Speak details': 'तपशील सांगा',
    'Tap to record again': 'पुन्हा रेकॉर्ड करण्यासाठी टॅप करा',
    'Describe SOS': 'SOS चे वर्णन करा',
    'Add context': 'माहिती जोडा',
    'Create': 'तयार करा',
    'Join': 'सामील व्हा',
    'Coordinate securely with people nearby':
        'जवळच्या लोकांशी सुरक्षितपणे समन्वय साधा',
    'Medical information': 'वैद्यकीय माहिती',
    'Trusted contacts': 'विश्वासू संपर्क',
    'Reporter ID': 'रिपोर्टर आयडी',
    'Blood type': 'रक्तगट',
    'Allergies': 'अॅलर्जी',
    'Medical conditions': 'वैद्यकीय स्थिती',
    'Not provided': 'दिलेली नाही',
    'Edit emergency profile': 'आपत्कालीन प्रोफाइल संपादित करा',
    'Edit profile': 'प्रोफाइल संपादित करा',
    'Accessibility': 'सुलभता',
    'High contrast mode': 'उच्च कॉन्ट्रास्ट मोड',
    'Dark mode': 'डार्क मोड',
    'Emergency settings': 'आपत्कालीन सेटिंग्ज',
    'Attach location to SOS': 'SOS सह स्थान जोडा',
    'Location details': 'स्थान तपशील',
    'Reprogram gestures': 'जेस्चर बदला',
    'Emergency gateway': 'आपत्कालीन गेटवे',
    'Save emergency profile': 'आपत्कालीन प्रोफाइल जतन करा',
    'Your details': 'तुमची माहिती',
    'Emergency contacts': 'आपत्कालीन संपर्क',
    'Medical details': 'वैद्यकीय तपशील',
    'Try again': 'पुन्हा प्रयत्न करा',
    'Create profile': 'प्रोफाइल तयार करा',
    'Profile unavailable': 'प्रोफाइल उपलब्ध नाही',
    'Connectivity': 'कनेक्टिव्हिटी',
  },
  'gu': {
    'Home': 'હોમ',
    'Rooms': 'રૂમ્સ',
    'Activity': 'પ્રવૃત્તિ',
    'You': 'તમે',
    'Profile': 'પ્રોફાઇલ',
    'Settings': 'સેટિંગ્સ',
    'Language': 'ભાષા',
    'Preferred language': 'પસંદગીની ભાષા',
    'English': 'અંગ્રેજી',
    'Hindi': 'હિન્દી',
    'Marathi': 'મરાઠી',
    'Gujarati': 'ગુજરાતી',
    'Emergency Aid': 'કટોકટી સહાય',
    'One tap away from help': 'મદદ એક ટેપ દૂર છે',
    'Open profile': 'પ્રોફાઇલ ખોલો',
    'Emergency type': 'કટોકટીનો પ્રકાર',
    'Voice input': 'અવાજ ઇનપુટ',
    'Speak details': 'વિગતો બોલો',
    'Tap to record again': 'ફરી રેકોર્ડ કરવા ટેપ કરો',
    'Describe SOS': 'SOS નું વર્ણન કરો',
    'Add context': 'માહિતી ઉમેરો',
    'Create': 'બનાવો',
    'Join': 'જોડાઓ',
    'Coordinate securely with people nearby':
        'નજીકના લોકો સાથે સુરક્ષિત રીતે સંકલન કરો',
    'Medical information': 'તબીબી માહિતી',
    'Trusted contacts': 'વિશ્વસનીય સંપર્કો',
    'Reporter ID': 'રિપોર્ટર આઈડી',
    'Blood type': 'રક્ત પ્રકાર',
    'Allergies': 'એલર્જી',
    'Medical conditions': 'તબીબી સ્થિતિઓ',
    'Not provided': 'આપેલ નથી',
    'Edit emergency profile': 'કટોકટી પ્રોફાઇલ સંપાદિત કરો',
    'Edit profile': 'પ્રોફાઇલ સંપાદિત કરો',
    'Accessibility': 'સુગમતા',
    'High contrast mode': 'ઉચ્ચ કોન્ટ્રાસ્ટ મોડ',
    'Dark mode': 'ડાર્ક મોડ',
    'Emergency settings': 'કટોકટી સેટિંગ્સ',
    'Attach location to SOS': 'SOS સાથે સ્થાન જોડો',
    'Location details': 'સ્થાન વિગતો',
    'Reprogram gestures': 'જેશ્ચર બદલો',
    'Emergency gateway': 'કટોકટી ગેટવે',
    'Save emergency profile': 'કટોકટી પ્રોફાઇલ સાચવો',
    'Your details': 'તમારી વિગતો',
    'Emergency contacts': 'કટોકટી સંપર્કો',
    'Medical details': 'તબીબી વિગતો',
    'Try again': 'ફરી પ્રયાસ કરો',
    'Create profile': 'પ્રોફાઇલ બનાવો',
    'Profile unavailable': 'પ્રોફાઇલ ઉપલબ્ધ નથી',
    'Connectivity': 'કનેક્ટિવિટી',
  },
};
