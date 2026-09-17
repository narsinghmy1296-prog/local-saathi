/// Lightweight bilingual string table. Kept as a simple Dart map instead of
/// full flutter_localizations/.arb tooling so the whole app stays easy to
/// scan and edit for a small MVP. Default is Hindi (per spec: "Hindi-first").
class AppStrings {
  AppStrings._();

  static String lang = 'hi'; // 'hi' | 'en' — set by LocaleProvider at startup

  static const Map<String, Map<String, String>> _t = {
    'appName': {'hi': 'लोकल साथी', 'en': 'Local Saathi'},
    'login': {'hi': 'लॉग इन करें', 'en': 'Log in'},
    'register': {'hi': 'नया खाता बनाएं', 'en': 'Register'},
    'phone': {'hi': 'मोबाइल नंबर', 'en': 'Mobile number'},
    'password': {'hi': 'पासवर्ड', 'en': 'Password'},
    'name': {'hi': 'नाम', 'en': 'Name'},
    'logout': {'hi': 'लॉग आउट', 'en': 'Log out'},
    'search_hint': {'hi': 'क्या चाहिए? जैसे दूध, आटा...', 'en': 'What do you need? e.g. milk, atta...'},
    'listening': {'hi': 'सुन रहे हैं...', 'en': 'Listening...'},
    'tap_mic_to_speak': {'hi': 'बोलने के लिए माइक दबाएं', 'en': 'Tap mic to speak'},
    'you_said': {'hi': 'आपने कहा:', 'en': 'You said:'},
    'retry': {'hi': 'फिर से बोलें', 'en': 'Retry'},
    'edit': {'hi': 'बदलें', 'en': 'Edit'},
    'search': {'hi': 'खोजें', 'en': 'Search'},
    'categories': {'hi': 'श्रेणियाँ', 'en': 'Categories'},
    'products': {'hi': 'उत्पाद', 'en': 'Products'},
    'add_to_cart': {'hi': 'कार्ट में डालें', 'en': 'Add to cart'},
    'cart': {'hi': 'कार्ट', 'en': 'Cart'},
    'my_orders': {'hi': 'मेरे ऑर्डर', 'en': 'My Orders'},
    'checkout': {'hi': 'ऑर्डर करें', 'en': 'Checkout'},
    'subtotal': {'hi': 'उप-योग', 'en': 'Subtotal'},
    'delivery_charge': {'hi': 'डिलीवरी शुल्क', 'en': 'Delivery charge'},
    'discount': {'hi': 'छूट', 'en': 'Discount'},
    'grand_total': {'hi': 'कुल राशि', 'en': 'Grand total'},
    'addresses': {'hi': 'पते', 'en': 'Addresses'},
    'add_address': {'hi': 'नया पता जोड़ें', 'en': 'Add address'},
    'select_address': {'hi': 'पता चुनें', 'en': 'Select address'},
    'place_order': {'hi': 'ऑर्डर पक्का करें', 'en': 'Place order'},
    'payment_method': {'hi': 'भुगतान का तरीका', 'en': 'Payment method'},
    'cod': {'hi': 'डिलीवरी पर नकद (COD)', 'en': 'Cash on delivery (COD)'},
    'upi': {'hi': 'UPI', 'en': 'UPI'},
    'order_placed': {'hi': 'ऑर्डर हो गया!', 'en': 'Order placed!'},
    'invoice': {'hi': 'बिल', 'en': 'Invoice'},
    'payment_status': {'hi': 'भुगतान की स्थिति', 'en': 'Payment status'},
    'empty_cart': {'hi': 'आपका कार्ट खाली है', 'en': 'Your cart is empty'},
    'empty_orders': {'hi': 'अभी कोई ऑर्डर नहीं है', 'en': 'No orders yet'},
    'empty_search': {'hi': 'कुछ नहीं मिला', 'en': 'Nothing found'},
    'try_again': {'hi': 'फिर कोशिश करें', 'en': 'Try again'},
    'loading': {'hi': 'लोड हो रहा है...', 'en': 'Loading...'},
    'quantity': {'hi': 'मात्रा', 'en': 'Quantity'},
    'price': {'hi': 'कीमत', 'en': 'Price'},
    'unit': {'hi': 'इकाई', 'en': 'Unit'},
    'available': {'hi': 'उपलब्ध', 'en': 'Available'},
    'min_order': {'hi': 'न्यूनतम ऑर्डर', 'en': 'Min. order'},
    'session_expired': {'hi': 'सेशन समाप्त हो गया, कृपया फिर लॉगिन करें', 'en': 'Session expired, please log in again'},
    'network_error': {'hi': 'सर्वर से संपर्क नहीं हो पा रहा', 'en': 'Could not reach the server'},
    'village_town': {'hi': 'गाँव/कस्बा', 'en': 'Village/Town'},
    'house': {'hi': 'घर/दुकान नंबर', 'en': 'House/Shop no.'},
    'landmark': {'hi': 'पहचान चिन्ह', 'en': 'Landmark'},
    'pincode': {'hi': 'पिन कोड', 'en': 'PIN code'},
    'save': {'hi': 'सेव करें', 'en': 'Save'},
    'all_role_customer': {'hi': 'ग्राहक के रूप में', 'en': 'As a Customer'},
    'confirm_add_to_cart': {'hi': 'क्या इसे कार्ट में डालें?', 'en': 'Add this to your cart?'},
    'yes': {'hi': 'हाँ', 'en': 'Yes'},
    'no': {'hi': 'नहीं', 'en': 'No'},
    'seller': {'hi': 'दुकानदार', 'en': 'Seller'},
    'other_product_note': {
      'hi': 'यह उत्पाद अभी किसी श्रेणी में नहीं है',
      'en': 'This product isn\'t in a category yet'
    },
    'profile': {'hi': 'प्रोफ़ाइल', 'en': 'Profile'},
    'my_addresses': {'hi': 'मेरे पते', 'en': 'My Addresses'},
    'help': {'hi': 'सहायता', 'en': 'Help'},
    'help_text': {
      'hi': 'किसी भी समस्या के लिए दुकानदार या डिलीवरी पार्टनर से संपर्क करें, या ऐप से लॉग आउट करके दोबारा लॉगिन करें।',
      'en': 'For any issue, contact the seller or delivery partner, or log out and log back in.',
    },
    'confirm_logout': {'hi': 'क्या आप लॉग आउट करना चाहते हैं?', 'en': 'Do you want to log out?'},
  };

  static String t(String key) => _t[key]?[lang] ?? _t[key]?['en'] ?? key;
}
