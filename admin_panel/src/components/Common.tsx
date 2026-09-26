import { useState } from "react";
import type { ReactNode } from "react";

export function StatCard({ label, value, hint }: { label: string; value: string | number; hint?: string }) {
  return (
    <div className="stat-card">
      <div className="stat-value">{value}</div>
      <div className="stat-label">{label}</div>
      {hint && <div className="stat-hint">{hint}</div>}
    </div>
  );
}

const STATUS_LABELS_HI: Record<string, string> = {
  placed: "नया / Placed",
  accepted: "Accepted",
  preparing: "Preparing",
  delivery_assigned: "Delivery Assigned",
  picked_up: "Picked Up",
  out_for_delivery: "Out for Delivery",
  delivered: "Delivered",
  cancelled: "Cancelled",
  rejected: "Rejected",
  pending: "Pending",
  initiated: "Initiated",
  paid: "Paid",
  cash_received: "Cash Received",
  failed: "Failed",
  unverified: "Unverified",
  assigned: "Assigned",
  in_stock: "In Stock",
  low_stock: "Low Stock",
  out_of_stock: "Out of Stock",
};

const STATUS_TONE: Record<string, "good" | "warn" | "bad" | "neutral"> = {
  delivered: "good",
  paid: "good",
  cash_received: "good",
  in_stock: "good",
  placed: "neutral",
  accepted: "neutral",
  preparing: "warn",
  delivery_assigned: "warn",
  picked_up: "warn",
  out_for_delivery: "warn",
  low_stock: "warn",
  pending: "warn",
  initiated: "warn",
  unverified: "warn",
  assigned: "neutral",
  cancelled: "bad",
  rejected: "bad",
  failed: "bad",
  out_of_stock: "bad",
};

export function StatusBadge({ status }: { status: string }) {
  const tone = STATUS_TONE[status] || "neutral";
  return <span className={`badge badge-${tone}`}>{STATUS_LABELS_HI[status] || status}</span>;
}

export function EmptyState({ text }: { text: string }) {
  return <div className="empty-state">{text}</div>;
}

export function LoadingBlock() {
  return <div className="loading-block">Loading…</div>;
}

export function ErrorBlock({ text }: { text: string }) {
  return <div className="error-block">{text}</div>;
}

export function Pagination({
  page,
  pageSize,
  total,
  onChange,
}: {
  page: number;
  pageSize: number;
  total: number;
  onChange: (page: number) => void;
}) {
  const totalPages = Math.max(1, Math.ceil(total / pageSize));
  if (totalPages <= 1) return null;
  return (
    <div className="pagination">
      <button disabled={page <= 1} onClick={() => onChange(page - 1)}>
        ← पीछे
      </button>
      <span>
        Page {page} / {totalPages} ({total} total)
      </span>
      <button disabled={page >= totalPages} onClick={() => onChange(page + 1)}>
        आगे →
      </button>
    </div>
  );
}

export function ConfirmButton({
  label,
  confirmText,
  onConfirm,
  className,
  disabled,
}: {
  label: string;
  confirmText: string;
  onConfirm: () => void | Promise<void>;
  className?: string;
  disabled?: boolean;
}) {
  const [confirming, setConfirming] = useState(false);
  const [busy, setBusy] = useState(false);

  if (confirming) {
    return (
      <span className="confirm-inline">
        <span>{confirmText}</span>
        <button
          className="btn btn-danger btn-sm"
          disabled={busy}
          onClick={async () => {
            setBusy(true);
            try {
              await onConfirm();
            } finally {
              setBusy(false);
              setConfirming(false);
            }
          }}
        >
          हाँ
        </button>
        <button className="btn btn-ghost btn-sm" disabled={busy} onClick={() => setConfirming(false)}>
          नहीं
        </button>
      </span>
    );
  }

  return (
    <button className={className || "btn btn-sm"} disabled={disabled} onClick={() => setConfirming(true)}>
      {label}
    </button>
  );
}

export function PageHeader({ title, actions }: { title: string; actions?: ReactNode }) {
  return (
    <div className="page-header">
      <h1>{title}</h1>
      {actions && <div className="page-header-actions">{actions}</div>}
    </div>
  );
}
