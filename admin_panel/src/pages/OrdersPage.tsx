import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api, ApiRequestError } from "../api/client";
import type { AdminOrderListItem, OrderStatus, Paginated } from "../types";
import { EmptyState, ErrorBlock, LoadingBlock, PageHeader, Pagination, StatusBadge } from "../components/Common";

const ORDER_STATUSES: OrderStatus[] = [
  "placed",
  "accepted",
  "preparing",
  "delivery_assigned",
  "picked_up",
  "out_for_delivery",
  "delivered",
  "cancelled",
  "rejected",
];

function toCsv(rows: AdminOrderListItem[]): string {
  const header = [
    "Order ID",
    "Status",
    "Payment Method",
    "Payment Status",
    "Grand Total",
    "Items",
    "Customer",
    "Phone",
    "Seller",
    "Delivery Partner",
    "Created At",
  ];
  const lines = rows.map((o) =>
    [
      o.id,
      o.status,
      o.payment_method,
      o.payment_status,
      o.grand_total,
      o.item_count,
      o.customer_name || "",
      o.customer_phone || "",
      o.seller_shop_name || "",
      o.delivery_partner_name || "",
      o.created_at,
    ]
      .map((v) => `"${String(v).replace(/"/g, '""')}"`)
      .join(",")
  );
  return [header.join(","), ...lines].join("\n");
}

function downloadCsv(rows: AdminOrderListItem[]) {
  const csv = toCsv(rows);
  const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `local-saathi-orders-${new Date().toISOString().slice(0, 10)}.csv`;
  a.click();
  URL.revokeObjectURL(url);
}

export function OrdersPage() {
  const [orderId, setOrderId] = useState("");
  const [debouncedOrderId, setDebouncedOrderId] = useState("");
  const [status, setStatus] = useState<OrderStatus | "">("");
  const [customerPhone, setCustomerPhone] = useState("");
  const [debouncedPhone, setDebouncedPhone] = useState("");
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");
  const [page, setPage] = useState(1);
  const pageSize = 20;

  const [data, setData] = useState<Paginated<AdminOrderListItem> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const t = setTimeout(() => setDebouncedOrderId(orderId), 350);
    return () => clearTimeout(t);
  }, [orderId]);
  useEffect(() => {
    const t = setTimeout(() => setDebouncedPhone(customerPhone), 350);
    return () => clearTimeout(t);
  }, [customerPhone]);

  useEffect(() => {
    setPage(1);
  }, [debouncedOrderId, status, debouncedPhone, dateFrom, dateTo]);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const result = await api.get<Paginated<AdminOrderListItem>>("/admin/orders", {
        order_id: debouncedOrderId ? Number(debouncedOrderId) : undefined,
        status: status || undefined,
        customer_phone: debouncedPhone || undefined,
        date_from: dateFrom || undefined,
        date_to: dateTo || undefined,
        page,
        page_size: pageSize,
      });
      setData(result);
    } catch (e) {
      setError(e instanceof ApiRequestError ? e.message : "Orders load नहीं हो पाए।");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [debouncedOrderId, status, debouncedPhone, dateFrom, dateTo, page]);

  return (
    <div>
      <PageHeader
        title="Order Management"
        actions={
          <button className="btn btn-ghost btn-sm" disabled={!data || data.items.length === 0} onClick={() => data && downloadCsv(data.items)}>
            ⬇ Export visible page as CSV
          </button>
        }
      />

      <div className="toolbar">
        <input
          className="search-input"
          style={{ maxWidth: 140 }}
          placeholder="Order ID"
          value={orderId}
          onChange={(e) => setOrderId(e.target.value.replace(/[^0-9]/g, ""))}
        />
        <select value={status} onChange={(e) => setStatus(e.target.value as OrderStatus | "")}>
          <option value="">सभी Status</option>
          {ORDER_STATUSES.map((s) => (
            <option key={s} value={s}>
              {s}
            </option>
          ))}
        </select>
        <input
          className="search-input"
          placeholder="Customer phone"
          value={customerPhone}
          onChange={(e) => setCustomerPhone(e.target.value)}
        />
        <label className="date-label">
          From <input type="date" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} />
        </label>
        <label className="date-label">
          To <input type="date" value={dateTo} onChange={(e) => setDateTo(e.target.value)} />
        </label>
      </div>

      {loading ? (
        <LoadingBlock />
      ) : error ? (
        <ErrorBlock text={error} />
      ) : !data || data.items.length === 0 ? (
        <EmptyState text="कोई order नहीं मिला।" />
      ) : (
        <>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Customer</th>
                  <th>Seller</th>
                  <th>Status</th>
                  <th>Payment</th>
                  <th>Total</th>
                  <th>Items</th>
                  <th>Delivery Partner</th>
                  <th>Placed</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {data.items.map((o) => (
                  <tr key={o.id}>
                    <td>#{o.id}</td>
                    <td>
                      {o.customer_name || "—"}
                      <div className="cell-sub">{o.customer_phone}</div>
                    </td>
                    <td>{o.seller_shop_name || "—"}</td>
                    <td>
                      <StatusBadge status={o.status} />
                    </td>
                    <td>
                      <StatusBadge status={o.payment_status} />
                      <div className="cell-sub">{o.payment_method.toUpperCase()}</div>
                    </td>
                    <td>₹{o.grand_total}</td>
                    <td>{o.item_count}</td>
                    <td>{o.delivery_partner_name || "—"}</td>
                    <td>{new Date(o.created_at).toLocaleString("en-IN")}</td>
                    <td>
                      <Link className="btn btn-ghost btn-sm" to={`/orders/${o.id}`}>
                        View →
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <Pagination page={data.page} pageSize={data.page_size} total={data.total} onChange={setPage} />
        </>
      )}
    </div>
  );
}
