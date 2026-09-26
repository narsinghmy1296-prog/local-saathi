import { useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { api, ApiRequestError } from "../api/client";
import type { Seller } from "../types";
import { ConfirmButton, EmptyState, ErrorBlock, LoadingBlock, PageHeader } from "../components/Common";
import { useToast } from "../components/Toast";

type StatusFilter = "all" | "pending" | "approved";

export function SellersPage() {
  const [params, setParams] = useSearchParams();
  const statusParam = (params.get("status") as StatusFilter) || "all";
  const [status, setStatus] = useState<StatusFilter>(statusParam);
  const [sellers, setSellers] = useState<Seller[]>([]);
  const [query, setQuery] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { showSuccess, showError } = useToast();

  async function load(s: StatusFilter) {
    setLoading(true);
    setError(null);
    try {
      const data = await api.get<Seller[]>("/admin/sellers", { status: s });
      setSellers(data);
    } catch (e) {
      setError(e instanceof ApiRequestError ? e.message : "Sellers load नहीं हो पाए।");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load(status);
    setParams(status === "all" ? {} : { status }, { replace: true });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [status]);

  async function runAction(seller: Seller, action: "approve" | "reject" | "activate" | "deactivate") {
    try {
      await api.post(`/admin/sellers/${seller.id}/${action}`);
      showSuccess(`${seller.shop_name}: ${action} हो गया।`);
      load(status);
    } catch (e) {
      showError(e instanceof ApiRequestError ? e.message : "Action fail हो गया।");
    }
  }

  const filtered = sellers.filter((s) => {
    if (!query.trim()) return true;
    const q = query.toLowerCase();
    return (
      s.shop_name.toLowerCase().includes(q) ||
      s.owner_name.toLowerCase().includes(q) ||
      s.phone.includes(q) ||
      s.area.toLowerCase().includes(q)
    );
  });

  return (
    <div>
      <PageHeader title="Seller Management" />

      <div className="toolbar">
        <div className="filter-tabs">
          {(["all", "pending", "approved"] as StatusFilter[]).map((s) => (
            <button
              key={s}
              className={`filter-tab ${status === s ? "filter-tab-active" : ""}`}
              onClick={() => setStatus(s)}
            >
              {s === "all" ? "सभी" : s === "pending" ? "Pending" : "Approved"}
            </button>
          ))}
        </div>
        <input
          className="search-input"
          placeholder="Shop, owner, phone या area से search करें"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
      </div>

      {loading ? (
        <LoadingBlock />
      ) : error ? (
        <ErrorBlock text={error} />
      ) : filtered.length === 0 ? (
        <EmptyState text="कोई seller नहीं मिला।" />
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Shop</th>
                <th>Owner</th>
                <th>Area</th>
                <th>Phone</th>
                <th>UPI</th>
                <th>Products</th>
                <th>Status</th>
                <th>Login</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((s) => (
                <tr key={s.id}>
                  <td>{s.shop_name}</td>
                  <td>{s.owner_name}</td>
                  <td>{s.area}</td>
                  <td>{s.phone}</td>
                  <td>{s.upi_id || "—"}</td>
                  <td>{s.product_count}</td>
                  <td>
                    <span className={`badge ${s.is_approved ? "badge-good" : "badge-warn"}`}>
                      {s.is_approved ? "Approved" : "Pending"}
                    </span>
                  </td>
                  <td>
                    <span className={`badge ${s.is_account_active ? "badge-good" : "badge-bad"}`}>
                      {s.is_account_active ? "Active" : "Inactive"}
                    </span>
                  </td>
                  <td className="actions-cell">
                    {!s.is_approved && (
                      <>
                        <button className="btn btn-primary btn-sm" onClick={() => runAction(s, "approve")}>
                          Approve
                        </button>
                        <ConfirmButton
                          label="Reject"
                          confirmText="Reject करें?"
                          className="btn btn-danger btn-sm"
                          onConfirm={() => runAction(s, "reject")}
                        />
                      </>
                    )}
                    {s.is_approved && s.is_account_active && (
                      <ConfirmButton
                        label="Deactivate"
                        confirmText="Login बंद करें?"
                        className="btn btn-danger btn-sm"
                        onConfirm={() => runAction(s, "deactivate")}
                      />
                    )}
                    {s.is_approved && !s.is_account_active && (
                      <button className="btn btn-primary btn-sm" onClick={() => runAction(s, "activate")}>
                        Activate
                      </button>
                    )}
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
