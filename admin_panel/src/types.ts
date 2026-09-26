// Every type here matches a real response shape read directly from the
// backend source (see docs/ADMIN_PANEL_API_AUDIT.md) — nothing here is
// speculative or "nice to have".

export type UserRole = "customer" | "seller" | "delivery" | "admin";

export interface LoginResponse {
  access_token: string;
  token_type: string;
  role: UserRole;
}

export interface Me {
  id: number;
  phone: string;
  name: string;
  role: UserRole;
  is_active: boolean;
}

export interface Dashboard {
  orders: {
    new: number;
    processing: number;
    out_for_delivery: number;
    delivered: number;
    cancelled: number;
    total: number;
  };
  products: {
    total: number;
    active: number;
    categories: number;
    other_products: number;
    out_of_stock: number;
  };
  users: {
    customers: number;
    sellers: number;
    delivery_partners: number;
    pending_seller_approvals: number;
    pending_delivery_approvals: number;
  };
  payments: {
    paid: number;
    cash_received: number;
    pending: number;
    unverified: number;
  };
  sales: {
    confirmed_total: number;
    confirmed_order_count: number;
  };
}

export interface Seller {
  id: number;
  user_id: number;
  shop_name: string;
  owner_name: string;
  area: string;
  upi_id: string | null;
  is_approved: boolean;
  phone: string;
  is_account_active: boolean;
  product_count: number;
}

export interface DeliveryPartner {
  id: number;
  user_id: number;
  name: string;
  phone: string;
  vehicle_type: string | null;
  area: string;
  is_approved: boolean;
  is_available: boolean;
  is_account_active: boolean;
}

export interface Category {
  id: number;
  name_hi: string;
  name_en: string;
  icon_url: string | null;
  sort_order: number;
  is_active: boolean;
}

export interface AdminProduct {
  id: number;
  seller_id: number;
  seller_shop_name: string;
  category_id: number | null;
  category_name: string | null;
  is_other: boolean;
  name: string;
  description: string | null;
  price: number;
  unit: string;
  available_qty: number;
  min_order_qty: number;
  stock_status: "in_stock" | "low_stock" | "out_of_stock";
  image_url: string | null;
  is_active: boolean;
}

export interface Paginated<T> {
  total: number;
  page: number;
  page_size: number;
  items: T[];
}

export interface AdminOrderListItem {
  id: number;
  status: OrderStatus;
  payment_method: "upi" | "cod";
  payment_status: PaymentStatus;
  grand_total: number;
  created_at: string;
  item_count: number;
  customer_name: string | null;
  customer_phone: string | null;
  seller_shop_name: string | null;
  delivery_partner_name: string | null;
}

export type OrderStatus =
  | "placed"
  | "accepted"
  | "preparing"
  | "delivery_assigned"
  | "picked_up"
  | "out_for_delivery"
  | "delivered"
  | "cancelled"
  | "rejected";

export type PaymentStatus =
  | "pending"
  | "initiated"
  | "paid"
  | "cash_received"
  | "failed"
  | "unverified";

export interface OrderDetail {
  id: number;
  status: OrderStatus;
  payment_method: "upi" | "cod";
  payment_status: PaymentStatus;
  subtotal: number;
  delivery_charge: number;
  discount: number;
  grand_total: number;
  items: Array<{
    product_id: number;
    name: string;
    quantity: number;
    unit_price: number;
    amount: number;
  }>;
  status_history: Array<{ status: OrderStatus; timestamp: string }>;
  customer: { name: string | null; phone: string | null };
  address: {
    village_town: string;
    house: string | null;
    landmark: string | null;
    pincode: string;
    mobile: string;
  } | null;
}

export interface AdminDelivery {
  delivery_id: number;
  order_id: number;
  order_status: OrderStatus;
  delivery_status: "assigned" | "picked_up" | "out_for_delivery" | "delivered";
  delivery_partner_id: number;
  delivery_partner_name: string | null;
  delivery_partner_phone: string | null;
  customer_name: string | null;
  village_town: string | null;
  pincode: string | null;
  assigned_at: string;
  picked_up_at: string | null;
  delivered_at: string | null;
}

export interface AuditLogEntry {
  admin_user_id: number;
  action: string;
  entity_type: string;
  entity_id: number;
  old_value: string | null;
  new_value: string | null;
  timestamp: string;
}

export interface ApiError {
  detail: string;
}
