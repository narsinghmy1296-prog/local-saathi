/// Centralized Hindi/English copy for the Seller App — kept in one file
/// (same pattern as the Customer App's app_strings.dart) so wording stays
/// consistent and easy to review/translate.
class AppStrings {
  final String lang; // 'hi' or 'en'
  const AppStrings(this.lang);

  String _t(String hi, String en) => lang == 'hi' ? hi : en;

  String get appName => _t('लोकल साथी — विक्रेता', 'Local Saathi — Seller');

  // Auth
  String get login => _t('लॉगिन', 'Login');
  String get register => _t('नया खाता बनाएँ', 'Register');
  String get phone => _t('मोबाइल नंबर', 'Mobile Number');
  String get password => _t('पासवर्ड', 'Password');
  String get shopName => _t('दुकान का नाम', 'Shop Name');
  String get ownerName => _t('मालिक का नाम', 'Owner Name');
  String get area => _t('क्षेत्र / गाँव', 'Area / Village');
  String get upiId => _t('UPI ID (वैकल्पिक)', 'UPI ID (optional)');
  String get logout => _t('लॉगआउट', 'Logout');
  String get dontHaveAccount => _t('खाता नहीं है? नया बनाएँ', "Don't have an account? Register");
  String get alreadyHaveAccount => _t('पहले से खाता है? लॉगिन करें', 'Already have an account? Login');

  // Approval status
  String get pendingApprovalTitle => _t('Approval की प्रतीक्षा में', 'Waiting for Approval');
  String get pendingApprovalBody => _t(
      'आपका खाता बन गया है। Admin द्वारा approve होने के बाद ही आप products जोड़ सकेंगे और orders देख सकेंगे। कृपया थोड़ी देर बाद फिर से लॉगिन करें।',
      'Your account is created. Once an admin approves your shop, you can add products and see orders. Please check back later.');
  String get refresh => _t('फिर से जाँचें', 'Refresh');
  String get accountDeactivated => _t(
      'आपका खाता निष्क्रिय कर दिया गया है। कृपया Admin से संपर्क करें।',
      'Your account has been deactivated. Please contact the admin.');

  // Dashboard
  String get dashboard => _t('डैशबोर्ड', 'Dashboard');
  String get totalProducts => _t('कुल उत्पाद', 'Total Products');
  String get activeProducts => _t('सक्रिय', 'Active');
  String get outOfStock => _t('स्टॉक खत्म', 'Out of Stock');
  String get newOrders => _t('नए ऑर्डर', 'New Orders');
  String get pendingOrders => _t('चल रहे ऑर्डर', 'In Progress');
  String get completedOrders => _t('पूरे हुए ऑर्डर', 'Completed');
  String get recentOrders => _t('हाल के ऑर्डर', 'Recent Orders');

  // Products
  String get products => _t('उत्पाद', 'Products');
  String get addProduct => _t('नया उत्पाद जोड़ें', 'Add Product');
  String get editProduct => _t('उत्पाद बदलें', 'Edit Product');
  String get productName => _t('उत्पाद का नाम', 'Product Name');
  String get category => _t('श्रेणी', 'Category');
  String get otherCategory => _t('अन्य / Other (यहाँ न मिले तो)', 'Other (not listed above)');
  String get description => _t('विवरण', 'Description');
  String get price => _t('कीमत (₹)', 'Price (₹)');
  String get unit => _t('इकाई (जैसे: kg, litre, piece)', 'Unit (e.g. kg, litre, piece)');
  String get availableQty => _t('उपलब्ध मात्रा', 'Available Quantity');
  String get minOrderQty => _t('न्यूनतम order मात्रा', 'Minimum Order Quantity');
  String get keywords => _t('खोज शब्द (comma से अलग करें)', 'Search Keywords (comma separated)');
  String get addPhoto => _t('फोटो जोड़ें', 'Add Photo');
  String get changePhoto => _t('फोटो बदलें', 'Change Photo');
  String get save => _t('सेव करें', 'Save');
  String get deactivate => _t('निष्क्रिय करें', 'Deactivate');
  String get noProductsYet => _t('अभी कोई उत्पाद नहीं है। नया उत्पाद जोड़ें।', 'No products yet. Add your first product.');
  String get inStock => _t('उपलब्ध', 'In Stock');
  String get lowStock => _t('कम स्टॉक', 'Low Stock');

  // Orders
  String get orders => _t('ऑर्डर', 'Orders');
  String get orderDetail => _t('ऑर्डर विवरण', 'Order Detail');
  String get customerDetails => _t('ग्राहक विवरण', 'Customer Details');
  String get deliveryAddress => _t('डिलीवरी पता', 'Delivery Address');
  String get items => _t('सामान', 'Items');
  String get accept => _t('स्वीकार करें', 'Accept');
  String get reject => _t('अस्वीकार करें', 'Reject');
  String get markPreparing => _t('तैयार हो रहा है', 'Mark Preparing');
  String get markReadyForPickup => _t('पिकअप के लिए तैयार', 'Ready for Pickup');
  String get cancelOrder => _t('ऑर्डर रद्द करें', 'Cancel Order');
  String get markPaymentReceived => _t('भुगतान मिल गया', 'Mark Payment Received');
  String get noOrdersYet => _t('अभी कोई ऑर्डर नहीं है।', 'No orders yet.');

  // Profile
  String get profile => _t('प्रोफाइल', 'Profile');
  String get editProfile => _t('प्रोफाइल बदलें', 'Edit Profile');
  String get approved => _t('Approved ✓', 'Approved ✓');
  String get notApproved => _t('Approval बाकी है', 'Approval Pending');

  // Common
  String get retry => _t('फिर कोशिश करें', 'Retry');
  String get cancel => _t('रद्द करें', 'Cancel');
  String get confirm => _t('पुष्टि करें', 'Confirm');
  String get somethingWentWrong => _t('कुछ गलत हो गया।', 'Something went wrong.');
  String get noInternet => _t('Internet connection जाँचें।', 'Please check your internet connection.');
  String get requiredField => _t('यह जरूरी है।', 'This field is required.');
}
