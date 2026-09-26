import { useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { api, ApiRequestError } from "../api/client";
import type { AdminDelivery, DeliveryPartner } from "../types";
import { ConfirmButton, EmptyState, ErrorBlock, LoadingBlock, PageHeader, StatusBadge } from "../components/Common";
import { useToast } from "../components/Toast";

type Tab = "partners" | "deliveries";
type StatusFilter = "all" | "pending" | "approved";

export function DeliveryPage() {
  const [params, setParams] = useSearchParams();
  const [tab, setTab] = useState<Tab>((params.get("tab") as Tab) || "partners");

  useEffect(() => {
    setParams((prev) => {
      const next = new URLSearchParams(prev);
      next.set("tab", tab);
      return next;
    }, { replace: true });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tab]);

  return (
    <div>
      <PageHeader title="Delivery Management" />
      <div className="filter-tabs">
        <button className={`filter-tab ${tab === "partners" ? "filter-tab-active" : ""}`} onClick={() => setTab("partners")}>
          Delivery Partners
        </button>
        <button className={`filter-tab ${tab === "deliveries" ? "filter-tab-active" : ""}`} onClick={() => setTab("deliveries")}>
          Active Deliveries
        </button>
      </div>
      {tab === "partners" ? <PartnersTab initialStatus={(params.get("status") as StatusFilter) || "all"} /> : <DeliveriesTab />}
    </div>
  );
}

function PartnersTab({ initialStatus }: { initialStatus: StatusFilter }) {
  const [status, setStatus] = useState<StatusFilter>(initialStatus);
  const [partners, setPartners] = useState<DeliveryPartner[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { showSuccess, showError } = useToast();

  async function load(s: StatusFilter) {
    setLoading(true);
    setError(null);
    try {
      const data = await api.get<DeliveryPartner[]>("/admin/delivery-partners", { status: s });
      setPartners(data);
    } catch (e) {
      setError(e instanceof ApiRequestError ? e.message : "Delivery partners load नहीं हो पाए।");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load(status);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [status]);

  async function runAction(dp: DeliveryPartner, action: "approve" | "reject" | "activate" | "deactivate") {
    try {
      await api.post(`/admin/delivery-partners/${dp.id}/${action}`);
      showSuccess(`${dp.name}: ${action} हो गया।`);
      load(status);
    } catch (e) {
      showError(e instanceof ApiRequestError ? e.message : "Action fail हो गया।");
    }
  }

  return (
    <div>
      <div className="toolbar">
        <div className="filter-tabs">
          {(["all", "pending", "approved"] as StatusFilter[]).map((s) => (
            <button key={s} className={`filter-tab ${status === s ? "filter-tab-active" : ""}`} onClick={() => setStatus(s)}>
              {s === "all" ? "सभी" : s === "pending" ? "Pending" : "Approved"}
            </button>
          ))}
        </div>
      </div>
      {loading ? (
        <LoadingBlock />
      ) : error ? (
        <ErrorBlock text={error} />
      ) : partners.length === 0 ? (
        <EmptyState text="कोई delivery partner नहीं मिला।" />
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Phone</th>
                <th>Vehicle</th>
                <th>Area</th>
                <th>Available</th>
                <th>Status</th>
                <th>Login</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {partners.map((dp) => (
                <tr key={dp.id}>
                  <td>{dp.name}</td>
                  <td>{dp.phone}</td>
                  <td>{dp.vehicle_type || "—"}</td>
                  <td>{dp.area}</td>
                  <td>{dp.is_available ? "हाँ" : "नहीं"}</td>
                  <td>
                    <span className={`badge ${dp.is_approved ? "badge-good" : "badge-warn"}`}>
                      {dp.is_approved ? "Approved" : "Pending"}
                    </span>
                  </td>
                  <td>
                    <span className={`badge ${dp.is_account_active ? "badge-good" : "badge-bad"}`}>
                      {dp.is_account_active ? "Active" : "Inactive"}
                    </span>
                  </td>
                  <td className="actions-cell">
                    {!dp.is_approved && (
                      <>
                        <button className="btn btn-primary btn-sm" onClick={() => runAction(dp, "approve")}>
                          Approve
                        </button>
                        <ConfirmButton label="Reject" confirmText="Reject करें?" className="btn btn-danger btn-sm" onConfirm={() => runAction(dp, "reject")} />
                      </>
                    )}
                    {dp.is_approved && dp.is_account_active && (
                      <ConfirmButton label="Deactivate" confirmText="Login बंद करें?" className="btn btn-danger btn-sm" onConfirm={() => runAction(dp, "deactivate")} />
                    )}
                    {dp.is_approved && !dp.is_account_active && (
                      <button className="btn btn-primary btn-sm" onClick={() => runAction(dp, "activate")}>
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

function DeliveriesTab() {
  const [deliveries, setDeliveries] = useState<AdminDelivery[]>([]);
  const [availablePartners, setAvailablePartners] = useState<DeliveryPartner[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [reassignTarget, setReassignTarget] = useState<AdminDelivery | null>(null);
  const [newPartnerId, setNewPartnerId] = useState<number | "">("");
  const { showSuccess, showError } = useToast();

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const [d, p] = await Promise.all([
        api.get<AdminDelivery[]>("/admin/deliveries"),
        api.get<DeliveryPartner[]>("/admin/delivery-partners", { status: "approved" }),
      ]);
      setDeliveries(d);
      setAvailablePartners(p.filter((x) => x.is_account_active));
    } catch (e) {
      setError(e instanceof ApiRequestError ? e.message : "Deliveries load नहीं हो पाईं।");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function submitReassign() {
    if (!reassignTarget || !newPartnerId) return;
    try {
      await api.post(`/admin/deliveries/${reassignTarget.delivery_id}/reassign`, { delivery_partner_id: newPartnerId });
      showSuccess(`Order #${reassignTarget.order_id} reassign हो गया।`);
      setReassignTarget(null);
      load();
    } catch (e) {
      showError(e instanceof ApiRequestError ? e.message : "Reassign fail हो गया।");
    }
  }

  return (
    <div>
      <p className="muted small">
        यहाँ केवल वे orders दिखते हैं जिन्हें कोई delivery partner पहले ही assign हो चुका है — असाइनमेंट हमेशा order status
        को "delivery_assigned" में बदलते समय अपने-आप होता है, इसलिए कोई अलग "unassigned queue" यहाँ मौजूद नहीं है।
      </p>
      {loading ? (
        <LoadingBlock />
      ) : error ? (
        <ErrorBlock text={error} />
      ) : deliveries.length === 0 ? (
        <EmptyState text="अभी कोई delivery assigned नहीं है।" />
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Order</th>
                <th>Customer</th>
                <th>Area</th>
                <th>Partner</th>
                <th>Order Status</th>
                <th>Delivery Status</th>
                <th>Assigned At</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {deliveries.map((d) => (
                <tr key={d.delivery_id}>
                  <td>#{d.order_id}</td>
                  <td>{d.customer_name || "—"}</td>
                  <td>
                    {d.village_town} ({d.pincode})
                  </td>
                  <td>
                    {d.delivery_partner_name}
                    <div className="cell-sub">{d.delivery_partner_phone}</div>
                  </td>
                  <td>
                    <StatusBadge status={d.order_status} />
                  </td>
                  <td>
                    <StatusBadge status={d.delivery_status} />
                  </td>
                  <td>{new Date(d.assigned_at).toLocaleString("en-IN")}</td>
                  <td>
                    <button
                      className="btn btn-ghost btn-sm"
                      disabled={d.delivery_status === "delivered"}
                      onClick={() => {
                        setReassignTarget(d);
                        setNewPartnerId("");
                      }}
                    >
                      Reassign
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {reassignTarget && (
        <div className="modal-backdrop" onClick={() => setReassignTarget(null)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <h3>Reassign Order #{reassignTarget.order_id}</h3>
            <select value={newPartnerId} onChange={(e) => setNewPartnerId(Number(e.target.value))}>
              <option value="">Delivery Partner चुनें</option>
              {availablePartners
                .filter((p) => p.id !== reassignTarget.delivery_partner_id)
                .map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name} — {p.area} ({p.phone})
                  </option>
                ))}
            </select>
            <div className="modal-actions">
              <button className="btn btn-ghost" onClick={() => setReassignTarget(null)}>
                Cancel
              </button>
              <button className="btn btn-primary" disabled={!newPartnerId} onClick={submitReassign}>
                Reassign
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
