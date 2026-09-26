import { useState } from "react";
import type { FormEvent } from "react";
import { API_BASE, api, ApiRequestError } from "../api/client";
import { useAuth } from "../auth/AuthContext";
import { PageHeader } from "../components/Common";
import { useToast } from "../components/Toast";

export function SettingsPage() {
  const { me } = useAuth();
  const { showSuccess, showError } = useToast();
  const [zoneName, setZoneName] = useState("");
  const [pincode, setPincode] = useState("");
  const [busy, setBusy] = useState(false);

  async function addZone(e: FormEvent) {
    e.preventDefault();
    if (!zoneName.trim() || !/^\d{6}$/.test(pincode)) {
      showError("Zone name और 6-digit pincode ज़रूरी है।");
      return;
    }
    setBusy(true);
    try {
      await api.post("/admin/delivery-zones", { name: zoneName.trim(), pincode });
      showSuccess("Delivery zone add/update हो गया।");
      setZoneName("");
      setPincode("");
    } catch (e) {
      showError(e instanceof ApiRequestError ? e.message : "Save नहीं हो पाया।");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div>
      <PageHeader title="Settings" />

      <div className="card">
        <h3>Admin Account</h3>
        <p>
          {me?.name} — {me?.phone}
        </p>
        <p className="muted small">Password बदलने के लिए फिलहाल कोई endpoint उपलब्ध नहीं है — backend team से संपर्क करें।</p>
      </div>

      <div className="card">
        <h3>Backend Connection</h3>
        <p>
          API Base URL: <code>{API_BASE || "(not set)"}</code>
        </p>
        <p className="muted small">
          यह build-time पर <code>VITE_API_BASE_URL</code> से set होता है — किसी secret/API key को यहाँ कभी नहीं दिखाया
          जाता।
        </p>
      </div>

      <div className="card">
        <h3>Add / Reactivate Delivery Zone</h3>
        <form className="inline-form" onSubmit={addZone}>
          <input placeholder="Zone name" value={zoneName} onChange={(e) => setZoneName(e.target.value)} />
          <input placeholder="6-digit pincode" value={pincode} onChange={(e) => setPincode(e.target.value.replace(/[^0-9]/g, ""))} maxLength={6} />
          <button className="btn btn-primary btn-sm" disabled={busy} type="submit">
            Save
          </button>
        </form>
        <p className="muted small">अगर pincode पहले से मौजूद है, तो यह उसे reactivate कर देगा और नाम update कर देगा।</p>
      </div>

      <div className="card">
        <h3>Feature Availability</h3>
        <ul className="feature-list">
          <li>✅ Seller / Delivery Partner approval workflow — fully backed by the API</li>
          <li>✅ Category CRUD (soft-delete only) — fully backed by the API</li>
          <li>✅ Product moderation, activate/deactivate, "Other" → category move</li>
          <li>✅ Order status transitions admin is allowed to make, payment status override</li>
          <li>✅ Delivery partner reassignment, audit log viewer</li>
          <li>⚠️ No PDF invoice generation — JSON invoice only (see order detail)</li>
          <li>⚠️ No payment gateway — COD/UPI status is manually confirmed, never auto-verified</li>
          <li>⚠️ No "unassigned delivery queue" — assignment happens automatically at the point an order moves to delivery_assigned</li>
        </ul>
      </div>
    </div>
  );
}
