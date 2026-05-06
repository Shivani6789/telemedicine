import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  String _locale = 'en'; // default english
  bool _hasSelectedLanguage = false;

  String get locale => _locale;
  bool get hasSelectedLanguage => _hasSelectedLanguage;

  void setLocale(String localeCode) {
    _locale = localeCode;
    _hasSelectedLanguage = true;
    notifyListeners();
  }

  // A basic dictionary for EN, HI, TE
  final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'app_title': 'Rural Telemedicine',
      'app_subtitle': 'Bridging healthcare gaps',
      'welcome': 'Welcome',
      'welcome_back': 'Welcome back',
      'sign_in_msg': 'Sign in to continue',
      'email_hint': 'Email address',
      'password_hint': 'Password',
      'sign_in_btn': 'Sign In',
      'no_account': "Don't have an account? ",
      'sign_up': 'Sign up',
      'quick_access': 'Quick Access',
      'video_consult': 'Video Consult Now',
      'video_consult_sub': 'Connect with a doctor online instantly',
      'book_apt': 'Book Appointment',
      'book_apt_sub': 'Schedule a clinic visit',
      'symptom_checker': 'Symptom Checker',
      'symptom_checker_sub': 'Smart doctor matching',
      'med_records': 'Medical Records',
      'med_records_sub': 'View prescriptions & visits',
      'find_meds': 'Find Medicines',
      'find_meds_sub': 'Nearby pharmacies',
      'health_tips': 'Health Tips',
      'tip_1': 'Drink 8 glasses of water daily',
      'tip_2': '30 minutes of daily walking improves heart health',
      'tip_3': 'Sleep 7–8 hours per night for immunity',
      'tip_4': 'Chest pain or sudden breathlessness → call emergency services',
      'offline_banner': 'OFFLINE MODE - Actions queued for sync',
    },
    'hi': {
      'app_title': 'ग्रामीण टेलीमेडिसिन',
      'app_subtitle': 'स्वास्थ्य सेवा की खाई को पाटना',
      'welcome': 'स्वागत है',
      'welcome_back': 'वापसी पर स्वागत है',
      'sign_in_msg': 'जारी रखने के लिए साइन इन करें',
      'email_hint': 'ईमेल पता',
      'password_hint': 'पासवर्ड',
      'sign_in_btn': 'साइन इन करें',
      'no_account': "खाता नहीं है? ",
      'sign_up': 'साइन अप करें',
      'quick_access': 'त्वरित पहुँच',
      'video_consult': 'वीडियो परामर्श लें',
      'video_consult_sub': 'डॉक्टर से तुरंत ऑनलाइन जुड़ें',
      'book_apt': 'नियुक्ति बुक करें',
      'book_apt_sub': 'क्लिनिक विज़िट शेड्यूल करें',
      'symptom_checker': 'लक्षण जांच',
      'symptom_checker_sub': 'स्मार्ट डॉक्टर मैचिंग',
      'med_records': 'चिकित्सा रिकॉर्ड',
      'med_records_sub': 'नुस्खे और विज़िट देखें',
      'find_meds': 'दवाएं खोजें',
      'find_meds_sub': 'आसपास की फ़ार्मेसी',
      'health_tips': 'स्वास्थ्य सुझाव',
      'tip_1': 'रोजाना 8 गिलास पानी पिएं',
      'tip_2': 'रोज 30 मिनट चलना दिल के लिए अच्छा है',
      'tip_3': 'रोग प्रतिरोधक क्षमता के लिए 7-8 घंटे सोएं',
      'tip_4': 'सीने में दर्द होने पर → अस्पताल कॉल करें',
      'offline_banner': 'ऑफ़लाइन मोड - कार्रवाइयां कतार में हैं',
    },
    'te': {
      'app_title': 'గ్రామీణ టెలిమెడిసిన్',
      'app_subtitle': 'ఆరోగ్య సంరక్షణ అంతరాలను తగ్గించడం',
      'welcome': 'స్వాగతం',
      'welcome_back': 'తిరిగి స్వాగతం',
      'sign_in_msg': 'కొనసాగించడానికి సైన్ ఇన్ చేయండి',
      'email_hint': 'ఈమెయిల్ చిరునామా',
      'password_hint': 'పాస్‌వర్డ్',
      'sign_in_btn': 'సైన్ ఇన్',
      'no_account': "ఖాతా లేదా? ",
      'sign_up': 'సైన్ అప్',
      'quick_access': 'త్వరిత యాక్సెస్',
      'video_consult': 'వీడియో సంప్రదింపులు',
      'video_consult_sub': 'ఆన్‌లైన్‌లో వైద్యునితో కనెక్ట్ అవ్వండి',
      'book_apt': 'అపాయింట్‌మెంట్ బుక్ చేయండి',
      'book_apt_sub': 'క్లినిక్ సందర్శన షెడ్యూల్ చేయండి',
      'symptom_checker': 'లక్షణ చెకర్',
      'symptom_checker_sub': 'స్మార్ట్ డాక్టర్ మ్యాచింగ్',
      'med_records': 'వైద్య రికార్డులు',
      'med_records_sub': 'ప్రిస్క్రిప్షన్లు & సందర్శనలు',
      'find_meds': 'మందులు కనుగొనండి',
      'find_meds_sub': 'సమీప ఫార్మసీలు',
      'health_tips': 'ఆరోగ్య చిట్కాలు',
      'tip_1': 'రోజూ 8 గ్లాసుల నీరు త్రాగాలి',
      'tip_2': 'రోజుకు 30 నిమిషాలు నడవడం గుండెకు మంచిది',
      'tip_3': 'రోగనిరోధక శక్తి కోసం 7-8 గంటలు నిద్రపోండి',
      'tip_4': 'ఛాతీ నొప్పి ఉంటే → ఆసుపత్రికి కాల్ చేయండి',
      'offline_banner': 'ఆఫ్‌లైన్ మోడ్ - చర్యలు సమకాలీకరణలో ఉన్నాయి',
    }
  };

  String translate(String key) {
    return _localizedStrings[_locale]?[key] ?? _localizedStrings['en']?[key] ?? key;
  }
}
