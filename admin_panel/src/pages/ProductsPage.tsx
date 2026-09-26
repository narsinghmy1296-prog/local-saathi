import { useEffect, useState } from "react";
import { api, ApiRequestError } from "../api/client";
import type { AdminProduct, Category, Paginated } from "../types";
import {
  ConfirmButton,
  EmptyState,
  ErrorBlock,
  LoadingBlock,
  PageHeader,
  Pagination,
  StatusBadge,
} from "../components/Common";
import { useToast } from "../components/Toast";

type StatusFilter = "all" | "active" | "inactive";

export function ProductsPage() {
  const [q, setQ] = useState("");
  const [debouncedQ, setDebouncedQ] = useState("");
  const [status, setStatus] = useState<StatusFilter>("all");
  const [categoryId, setCategoryId] = useState<number | "">("");
  const [otherOnly, setOtherOnly] = useState(false);
  const [page, setPage] = useState(1);
  const pageSize = 20;

  const [data, setData] = useState<Paginated<AdminProduct> | null>(null);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { showSuccess, showError } = useToast();

  const [moveTarget, setMoveTarget] = useState<AdminProduct | null>(null);
  const [moveCategoryId, setMoveCategoryId] = useState<number | "">("");

  useEffect(() => {
    const t = setTimeout(() => setDebouncedQ(q), 350);
    return () => clearTimeout(t);
  }, [q]);

  useEffect(() => {
    api.get<Category[]>("/categories").then(setCategories).catch(() => undefined);
  }, []);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const result = await api.get<Paginated<AdminProduct>>("/admin/products", {
        q: debouncedQ || undefined,
        category_id: categoryId || undefined,
        status,
        is_other: otherOnly ? true : undefined,
        page,
        page_size: pageSize,
      });
      setData(result);
    } catch (e) {
      setError(e instanceof ApiRequestError ? e.message : "Products load नहीं हो पाए।");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [debouncedQ, status, categoryId, otherOnly, page]);

  useEffect(() => {
    setPage(1);
  }, [debouncedQ, status, categoryId, otherOnly]);

  async function toggleActive(p: AdminProduct) {
    try {
      if (p.is_active) {
        await api.del(`/products/${p.id}`);
      } else {
        await api.post(`/products/${p.id}/activate`);
      }
      showSuccess(`${p.name}: ${p.is_active ? "deactivate" : "activate"} हो गया।`);
      load();
    } catch (e) {
      showError(e instanceof ApiRequestError ? e.message : "Action fail हो गया।");
    }
  }

  async function submitMove() {
    if (!moveTarget || !moveCategoryId) return;
    try {
      await api.post(`/products/${moveTarget.id}/move-category`, undefined, { category_id: moveCategoryId });
      showSuccess(`${moveTarget.name} category में move हो गया।`);
      setMoveTarget(null);
      load();
    } catch (e) {
      showError(e instanceof ApiRequestError ? e.message : "Move fail हो गया।");
    }
  }

  return (
    <div>
      <PageHeader title="Product Management" />

      <div className="toolbar">
        <input
          className="search-input"
          placeholder="Product नाम से search करें"
          value={q}
          onChange={(e) => setQ(e.target.value)}
        />
        <select value={status} onChange={(e) => setStatus(e.target.value as StatusFilter)}>
          <option value="all">सभी Status</option>
          <option value="active">Active</option>
          <option value="inactive">Inactive</option>
        </select>
        <select
          value={categoryId}
          onChange={(e) => setCategoryId(e.target.value ? Number(e.target.value) : "")}
        >
          <option value="">सभी Categories</option>
          {categories.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name_en} / {c.name_hi}
            </option>
          ))}
        </select>
        <label className="checkbox-label">
          <input type="checkbox" checked={otherOnly} onChange={(e) => setOtherOnly(e.target.checked)} />
          केवल "Other / अन्य"
        </label>
      </div>

      {loading ? (
        <LoadingBlock />
      ) : error ? (
        <ErrorBlock text={error} />
      ) : !data || data.items.length === 0 ? (
        <EmptyState text="कोई product नहीं मिला।" />
      ) : (
        <>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Seller</th>
                  <th>Category</th>
                  <th>Price</th>
                  <th>Qty</th>
                  <th>Stock</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {data.items.map((p) => (
                  <tr key={p.id}>
                    <td>{p.name}</td>
                    <td>{p.seller_shop_name}</td>
                    <td>
                      {p.is_other ? (
                        <span className="badge badge-warn">Other / अन्य</span>
                      ) : (
                        p.category_name || "—"
                      )}
                    </td>
                    <td>₹{p.price}</td>
                    <td>
                      {p.available_qty} {p.unit}
                    </td>
                    <td>
                      <StatusBadge status={p.stock_status} />
                    </td>
                    <td>
                      <span className={`badge ${p.is_active ? "badge-good" : "badge-bad"}`}>
                        {p.is_active ? "Active" : "Inactive"}
                      </span>
                    </td>
                    <td className="actions-cell">
                      {p.is_active ? (
                        <ConfirmButton
                          label="Deactivate"
                          confirmText="Deactivate करें?"
                          className="btn btn-danger btn-sm"
                          onConfirm={() => toggleActive(p)}
                        />
                      ) : (
                        <button className="btn btn-primary btn-sm" onClick={() => toggleActive(p)}>
                          Activate
                        </button>
                      )}
                      {p.is_other && (
                        <button
                          className="btn btn-ghost btn-sm"
                          onClick={() => {
                            setMoveTarget(p);
                            setMoveCategoryId("");
                          }}
                        >
                          Move to category
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <Pagination page={data.page} pageSize={data.page_size} total={data.total} onChange={setPage} />
        </>
      )}

      {moveTarget && (
        <div className="modal-backdrop" onClick={() => setMoveTarget(null)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <h3>Move "{moveTarget.name}" to a category</h3>
            <select value={moveCategoryId} onChange={(e) => setMoveCategoryId(Number(e.target.value))}>
              <option value="">Category चुनें</option>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name_en} / {c.name_hi}
                </option>
              ))}
            </select>
            <div className="modal-actions">
              <button className="btn btn-ghost" onClick={() => setMoveTarget(null)}>
                Cancel
              </button>
              <button className="btn btn-primary" disabled={!moveCategoryId} onClick={submitMove}>
                Move
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
