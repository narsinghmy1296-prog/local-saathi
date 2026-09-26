import { useEffect, useState } from "react";
import { api, ApiRequestError } from "../api/client";
import type { AdminOrderListItem, Dashboard, OrderStatus, Paginated } from "../types";
import { ErrorBlock, LoadingBlock, PageHeader, StatCard } from "../components/Common";

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
  const header = ["Order ID", "Status", "Payment Method", "Payment Status", "Grand Total", "Seller", "Created At"];
  const lines = rows.map((o) =>
    [o.id, o.status, o.payment_method, o.payment_status, o.grand_total, o.seller_shop_name || "", o.created_at]
      .map((v) => `"${String(v).replace(/"/g, '""')}"`)
      .join(",")
  );
  return [header.join(","), ...lines].join("\n");
}

export function ReportsPage() {
  const [dashboard, setDashboard] = useState<Dashboard | null>(null);
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");
  const [status, setStatus] = useState<OrderStatus | "">("");
  const [rows, setRows] = useState<AdminOrderListItem[] | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [exporting, setExporting] = useState(false);

  useEffect(() => {
    api.get<Dashboard>("/admin/dashboard").then(setDashboard).catch(() => undefined);
  }, []);

  async function runReport() {
    setLoading(true);
    setError(null);
    setRows(null);
    try {
      // Pulls every matching order across pages (page_size capped at 100
      // server-side) so the report/CSV reflects the *whole* filtered set,
      // not just one page — still entirely real data already returned by
      // the real /admin/orders endpoint, nothing invented client-side.
      const collected: AdminOrderListItem[] = [];
      let page = 1;
      // eslint-disable-next-line no-constant-condition
      while (true) {
        const result = await api.get<Paginated<AdminOrderListItem>>("/admin/orders", {
          status: status || undefined,
          date_from: dateFrom || undefined,
          date_to: dateTo || undefined,
          page,
          page_size: 100,
        });
        collected.push(...result.items);
        if (collected.length >= result.total || result.items.length === 0) break;
        page += 1;
        if (page > 50) break; // hard safety cap — 5,000 orders per report
      }
      setRows(collected);
    } catch (e) {
      setError(e instanceof ApiRequestError ? e.message : "Report load नहीं हो पाई।");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    runReport();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const totalGrand = rows ? rows.reduce((sum, o) => sum + o.grand_total, 0) : 0;
  const confirmed = rows ? rows.filter((o) => o.payment_status === "paid" || o.payment_status === "cash_received") : [];
  const confirmedTotal = confirmed.reduce((sum, o) => sum + o.grand_total, 0);

  async function exportCsv() {
    if (!rows) return;
    setExporting(true);
    try {
      const csv = toCsv(rows);
      const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `local-saathi-report-${new Date().toISOString().slice(0, 10)}.csv`;
      a.click();
      URL.revokeObjectURL(url);
    } finally {
      setExporting(false);
    }
  }

  return (
    <div>
      <PageHeader title="Orders &amp; Sales Reports" />

      {dashboard && (
        <div className="stat-grid">
          <StatCard label="All-Time Confirmed Sales" value={`₹${dashboard.sales.confirmed_total.toLocaleString("en-IN")}`} />
          <StatCard label="All-Time Total Orders" value={dashboard.orders.total} />
        </div>
      )}

      <h2 className="section-title">Filtered Report</h2>
      <div className="toolbar">
        <select value={status} onChange={(e) => setStatus(e.target.value as OrderStatus | "")}>
          <option value="">सभी Status</option>
          {ORDER_STATUSES.map((s) => (
            <option key={s} value={s}>
              {s}
            </option>
          ))}
        </select>
        <label className="date-label">
          From <input type="date" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} />
        </label>
        <label className="date-label">
          To <input type="date" value={dateTo} onChange={(e) => setDateTo(e.target.value)} />
        </label>
        <button className="btn btn-primary btn-sm" onClick={runReport}>
          Run Report
        </button>
        <button className="btn btn-ghost btn-sm" disabled={!rows || rows.length === 0 || exporting} onClick={exportCsv}>
          ⬇ Export CSV
        </button>
      </div>

      {loading ? (
        <LoadingBlock />
      ) : error ? (
        <ErrorBlock text={error} />
      ) : (
        rows && (
          <>
            <div className="stat-grid">
              <StatCard label="Orders in Range" value={rows.length} />
              <StatCard label="Grand Total (all statuses)" value={`₹${totalGrand.toLocaleString("en-IN")}`} />
              <StatCard
                label="Confirmed Sales (paid / cash-received)"
                value={`₹${confirmedTotal.toLocaleString("en-IN")}`}
                hint={`${confirmed.length} orders`}
              />
            </div>
            <p className="muted small">
              "Confirmed Sales" कभी भी pending/unverified/initiated payment को count नहीं करता — केवल वही orders count होते
              हैं जिनका payment_status backend में paid या cash_received है।
            </p>
          </>
        )
      )}
    </div>
  );
}
