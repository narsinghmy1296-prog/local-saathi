import { useEffect, useState } from "react";
import { api, ApiRequestError } from "../api/client";
import type { AuditLogEntry } from "../types";
import { EmptyState, ErrorBlock, LoadingBlock, PageHeader } from "../components/Common";

export function AuditLogPage() {
  const [logs, setLogs] = useState<AuditLogEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState("");

  useEffect(() => {
    api
      .get<AuditLogEntry[]>("/admin/audit-logs")
      .then(setLogs)
      .catch((e) => setError(e instanceof ApiRequestError ? e.message : "Audit log load नहीं हो पाया।"))
      .finally(() => setLoading(false));
  }, []);

  const filtered = logs.filter((l) => {
    if (!query.trim()) return true;
    const q = query.toLowerCase();
    return l.action.toLowerCase().includes(q) || l.entity_type.toLowerCase().includes(q) || String(l.entity_id).includes(q);
  });

  return (
    <div>
      <PageHeader title="Audit Log" />
      <p className="muted small">
        हर seller/product/category/delivery-partner change और हर admin action यहाँ record होता है — यह सिर्फ पिछले 200
        actions दिखाता है (backend endpoint की सीमा)।
      </p>
      <div className="toolbar">
        <input className="search-input" placeholder="Action या entity type से search करें" value={query} onChange={(e) => setQuery(e.target.value)} />
      </div>
      {loading ? (
        <LoadingBlock />
      ) : error ? (
        <ErrorBlock text={error} />
      ) : filtered.length === 0 ? (
        <EmptyState text="कोई audit log entry नहीं मिली।" />
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Time</th>
                <th>Admin User ID</th>
                <th>Action</th>
                <th>Entity</th>
                <th>Old → New</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((l, i) => (
                <tr key={i}>
                  <td>{new Date(l.timestamp).toLocaleString("en-IN")}</td>
                  <td>#{l.admin_user_id}</td>
                  <td>{l.action}</td>
                  <td>
                    {l.entity_type} #{l.entity_id}
                  </td>
                  <td>
                    {l.old_value || "—"} → {l.new_value || "—"}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
