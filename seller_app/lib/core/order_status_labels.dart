/// Maps the backend's exact status strings (see docs/API_CONTRACT.md) to
/// Hindi/English display labels. Kept separate from AppStrings since these
/// are keyed by a fixed backend enum, not free-form UI copy.
String orderStatusLabel(String status, String lang) {
  const hi = {
    'placed': 'नया ऑर्डर',
    'accepted': 'स्वीकार किया गया',
    'preparing': 'तैयार हो रहा है',
    'delivery_assigned': 'Delivery को सौंपा गया',
    'picked_up': 'Pickup हो गया',
    'out_for_delivery': 'Delivery के लिए निकला',
    'delivered': 'डिलीवर हो गया',
    'cancelled': 'रद्द',
    'rejected': 'अस्वीकार किया गया',
  };
  const en = {
    'placed': 'New Order',
    'accepted': 'Accepted',
    'preparing': 'Preparing',
    'delivery_assigned': 'Assigned for Delivery',
    'picked_up': 'Picked Up',
    'out_for_delivery': 'Out for Delivery',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
    'rejected': 'Rejected',
  };
  final map = lang == 'hi' ? hi : en;
  return map[status] ?? status;
}

String paymentStatusLabel(String status, String lang) {
  const hi = {
    'pending': 'भुगतान बाकी',
    'initiated': 'शुरू हुआ',
    'paid': 'भुगतान हो गया',
    'cash_received': 'नकद मिल गया',
    'failed': 'असफल',
    'unverified': 'अपुष्ट',
  };
  const en = {
    'pending': 'Pending',
    'initiated': 'Initiated',
    'paid': 'Paid',
    'cash_received': 'Cash Received',
    'failed': 'Failed',
    'unverified': 'Unverified',
  };
  final map = lang == 'hi' ? hi : en;
  return map[status] ?? status;
}
