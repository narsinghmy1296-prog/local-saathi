import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { api, ApiRequestError, API_BASE } from "../api/client";
import type { DeliveryPartner, OrderDetail, PaymentStatus } from "../types";
import { ErrorBlock, LoadingBlock, PageHeader, StatusBadge } from "../components/Common";
import { useToast } from "../components/Toast";

// Mirrors app/core/state_machine.py::ORDER_ALLOWED_TRANSITIONS combined
// with ORDER_TRANSITION_ROLES, filtered to what the *admin* role is
// actually allowed to push (only "delivery_assigned" and "cancelled" —
// every other transition belongs to seller/delivery/customer). Showing
// only these avoids ever presenting a button the backend will 400 on.
const ADMIN_ALLOWED_NEXT: Record<string, string[]> = {
  placed: ["cancelled"],
  accepted: ["cancelled"],
  preparing: ["delivery_assigned", "cancelled"],
  delivery_assigned: ["cancelled"],
};

const PAYMENT_STATUSES: PaymentStatus[] = ["pending", "initiated", "paid", "cash_received", "failed", "unverified"];

export function OrderDetailPage() {
  const { orderId } = useParams();
  const [order, setOrder] = useState<OrderDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [partners, setPartners] = useState<DeliveryPartner[]>([]);
  const [chosenPartner, setChosenPartner] = useState<number | "">("");
  const [paymentTarget, setPaymentTarget] = useState<PaymentStatus | "">("");
  const { showSuccess, showError } = useToast();

  async function load() {
    if (!orderId) return;
    setLoading(true);
    setError(null);
    try {
      const data = await api.get<OrderDetail>(`/orders/${orderId}`);
      setOrder(data);
    } catch (e) {
      setError(e instanceof ApiRequestError ? e.message : "Order load नहीं हो पाया।");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
    api
      .get<DeliveryPartner[]>("/admin/delivery-partners", { status: "approved" })
      .then((p) => setPartners(p.filter((x) => x.is_available && x.is_account_active)))
      .catch(() => undefined);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [orderId]);

  async function pushStatus(target: string) {
    try {
      const body: Record<string, unknown> = { status: target };
      if (target === "delivery_assigned") {
        if (!chosenPartner) {
          showError("पहले एक delivery partner चुनें।");
          return;
        }
        body.delivery_partner_id = chosenPartner;
      }
      await api.post(`/orders/${orderId}/status`, body);
      showSuccess("Order status update हो गया।");
      load();
    } catch (e) {
      showError(e instanceof ApiRequestError ? e.message : "Status update fail हो गया।");
    }
  }

  async function updatePayment() {
    if (!paymentTarget) return;
    try {
      await api.post(`/orders/${orderId}/payment/mark-received`, { new_status: paymentTarget });
      showSuccess("Payment status update हो गया।");
      setPaymentTarget("");
      load();
    } catch (e) {
      showError(e instanceof ApiRequestError ? e.message : "Payment update fail हो गया।");
    }
  }

  if (loading) return <LoadingBlock />;
  if (error || !order) return <ErrorBlock text={error || "Order नहीं मिला।"} />;

  const allowedNext = ADMIN_ALLOWED_NEXT[order.status] || [];

  return (
    <div>
      <PageHeader title={`Order #${order.id}`} actions={<Link to="/orders">← सभी Orders</Link>} />

      <div className="two-col">
        <div className="card">
          <h3>Status</h3>
          <p>
            <StatusBadge status={order.status} />
          </p>

          {allowedNext.length === 0 ? (
            <p className="muted">इस order पर admin से कोई और status change नहीं हो सकता — यह seller/delivery partner की ज़िम्मेदारी है, या order पहले ही final state में है।</p>
          ) : (
            <div className="action-row">
              {allowedNext.includes("delivery_assigned") && (
                <div className="inline-form">
                  <select value={chosenPartner} onChange={(e) => setChosenPartner(Number(e.target.value))}>
                    <option value="">Delivery Partner चुनें</option>
                    {partners.map((p) => (
                      <option key={p.id} value={p.id}>
                        {p.name} — {p.area} ({p.phone})
                      </option>
                    ))}
                  </select>
                  <button className="btn btn-primary btn-sm" onClick={() => pushStatus("delivery_assigned")}>
                    Assign Delivery
                  </button>
                </div>
              )}
              {allowedNext.includes("cancelled") && (
                <button className="btn btn-danger btn-sm" onClick={() => pushStatus("cancelled")}>
                  Cancel Order
                </button>
              )}
            </div>
          )}

          <h3>Status History</h3>
          <ul className="history-list">
            {order.status_history.map((h, i) => (
              <li key={i}>
                <StatusBadge status={h.status} /> — {new Date(h.timestamp).toLocaleString("en-IN")}
              </li>
            ))}
          </ul>
        </div>

        <div className="card">
          <h3>Payment</h3>
          <p>
            {order.payment_method.toUpperCase()} — <StatusBadge status={order.payment_status} />
          </p>
          <div className="inline-form">
            <select value={paymentTarget} onChange={(e) => setPaymentTarget(e.target.value as PaymentStatus)}>
              <option value="">नया Payment Status चुनें</option>
              {PAYMENT_STATUSES.filter((s) => s !== order.payment_status).map((s) => (
                <option key={s} value={s}>
                  {s}
                </option>
              ))}
            </select>
            <button className="btn btn-primary btn-sm" disabled={!paymentTarget} onClick={updatePayment}>
              Update
            </button>
          </div>
          <p className="muted small">
            Admin किसी भी payment status में override कर सकता है (हर change audit log में दर्ज होता है) — लेकिन
            असली payment verify हुए बिना कभी "Paid" न चुनें।
          </p>
          <a className="btn btn-ghost btn-sm" href={`${API_BASE}/api/v1/orders/${order.id}/invoice`} target="_blank" rel="noreferrer">
            Invoice देखें (JSON) →
          </a>
        </div>
      </div>

      <div className="card">
        <h3>Items</h3>
        <table>
          <thead>
            <tr>
              <th>Product</th>
              <th>Qty</th>
              <th>Unit Price</th>
              <th>Amount</th>
            </tr>
          </thead>
          <tbody>
            {order.items.map((i) => (
              <tr key={i.product_id}>
                <td>{i.name}</td>
                <td>{i.quantity}</td>
                <td>₹{i.unit_price}</td>
                <td>₹{i.amount}</td>
              </tr>
            ))}
          </tbody>
        </table>
        <p className="totals">
          Subtotal: ₹{order.subtotal} · Delivery: ₹{order.delivery_charge} · Discount: ₹{order.discount} ·{" "}
          <strong>Grand Total: ₹{order.grand_total}</strong>
        </p>
      </div>

      <div className="card">
        <h3>Customer &amp; Delivery Address</h3>
        <p>
          {order.customer.name} — {order.customer.phone}
        </p>
        {order.address && (
          <p>
            {order.address.house ? `${order.address.house}, ` : ""}
            {order.address.village_town}
            {order.address.landmark ? `, ${order.address.landmark}` : ""} — {order.address.pincode}
            <br />
            Mobile: {order.address.mobile}
          </p>
        )}
      </div>
    </div>
  );
}
