import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api, ApiRequestError } from "../api/client";
import type { Dashboard } from "../types";
import { ErrorBlock, LoadingBlock, PageHeader, StatCard } from "../components/Common";

export function DashboardPage() {
  const [data, setData] = useState<Dashboard | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    api
      .get<Dashboard>("/admin/dashboard")
      .then((d) => !cancelled && setData(d))
      .catch((e) => !cancelled && setError(e instanceof ApiRequestError ? e.message : "Dashboard load नहीं हो पाया।"))
      .finally(() => !cancelled && setLoading(false));
    return () => {
      cancelled = true;
    };
  }, []);

  if (loading) return <LoadingBlock />;
  if (error || !data) return <ErrorBlock text={error || "Data नहीं मिला।"} />;

  return (
    <div>
      <PageHeader title="Dashboard" />

      <h2 className="section-title">Orders</h2>
      <div className="stat-grid">
        <StatCard label="Total Orders" value={data.orders.total} />
        <StatCard label="नया (Placed)" value={data.orders.new} />
        <StatCard label="Processing" value={data.orders.processing} />
        <StatCard label="Out for Delivery" value={data.orders.out_for_delivery} />
        <StatCard label="Delivered" value={data.orders.delivered} />
        <StatCard label="Cancelled / Rejected" value={data.orders.cancelled} />
      </div>

      <h2 className="section-title">Approvals Pending</h2>
      <div className="stat-grid">
        <StatCard
          label="Pending Seller Approvals"
          value={data.users.pending_seller_approvals}
          hint={data.users.pending_seller_approvals > 0 ? "देखें →" : undefined}
        />
        <StatCard
          label="Pending Delivery Partner Approvals"
          value={data.users.pending_delivery_approvals}
          hint={data.users.pending_delivery_approvals > 0 ? "देखें →" : undefined}
        />
      </div>
      {(data.users.pending_seller_approvals > 0 || data.users.pending_delivery_approvals > 0) && (
        <p className="quick-links">
          <Link to="/sellers?status=pending">Pending Sellers →</Link>{" "}
          <Link to="/delivery?tab=partners&status=pending">Pending Delivery Partners →</Link>
        </p>
      )}

      <h2 className="section-title">Products &amp; Users</h2>
      <div className="stat-grid">
        <StatCard label="Active Products" value={data.products.active} />
        <StatCard label="Total Products" value={data.products.total} />
        <StatCard label="Categories" value={data.products.categories} />
        <StatCard label="'Other' Products" value={data.products.other_products} />
        <StatCard label="Out of Stock" value={data.products.out_of_stock} />
        <StatCard label="Customers" value={data.users.customers} />
        <StatCard label="Sellers" value={data.users.sellers} />
        <StatCard label="Delivery Partners" value={data.users.delivery_partners} />
      </div>

      <h2 className="section-title">Payments</h2>
      <div className="stat-grid">
        <StatCard label="Paid" value={data.payments.paid} />
        <StatCard label="Cash Received" value={data.payments.cash_received} />
        <StatCard label="Pending" value={data.payments.pending} />
        <StatCard label="Unverified" value={data.payments.unverified} />
        <StatCard
          label="Confirmed Sales (₹)"
          value={`₹${data.sales.confirmed_total.toLocaleString("en-IN")}`}
          hint={`${data.sales.confirmed_order_count} orders — paid/cash-received only`}
        />
      </div>
    </div>
  );
}
