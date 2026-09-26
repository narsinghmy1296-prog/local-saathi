import { useEffect, useState } from "react";
import type { FormEvent } from "react";
import { api, ApiRequestError } from "../api/client";
import type { Category } from "../types";
import { ConfirmButton, EmptyState, ErrorBlock, LoadingBlock, PageHeader } from "../components/Common";
import { useToast } from "../components/Toast";

interface FormState {
  id: number | null;
  name_hi: string;
  name_en: string;
  icon_url: string;
  sort_order: number;
}

const EMPTY_FORM: FormState = { id: null, name_hi: "", name_en: "", icon_url: "", sort_order: 0 };

export function CategoriesPage() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [form, setForm] = useState<FormState>(EMPTY_FORM);
  const [formError, setFormError] = useState<string | null>(null);
  const { showSuccess, showError } = useToast();

  async function load() {
    setLoading(true);
    setError(null);
    try {
      // The public /categories endpoint only returns active ones — that's
      // deliberate for the customer/seller apps, but the admin panel needs
      // to see (and reactivate) deactivated categories too, so it merges
      // with anything already known locally that isn't in the fresh list.
      const active = await api.get<Category[]>("/categories");
      setCategories((prev) => {
        const inactiveStillTracked = prev.filter((p) => !p.is_active && !active.some((a) => a.id === p.id));
        return [...active, ...inactiveStillTracked].sort((a, b) => a.sort_order - b.sort_order);
      });
    } catch (e) {
      setError(e instanceof ApiRequestError ? e.message : "Categories load नहीं हो पाईं।");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, []);

  function isDuplicate(nameEn: string, nameHi: string, excludeId: number | null): boolean {
    const en = nameEn.trim().toLowerCase();
    const hi = nameHi.trim().toLowerCase();
    return categories.some(
      (c) => c.id !== excludeId && (c.name_en.trim().toLowerCase() === en || c.name_hi.trim().toLowerCase() === hi)
    );
  }

  async function submitForm(e: FormEvent) {
    e.preventDefault();
    setFormError(null);
    if (!form.name_en.trim() || !form.name_hi.trim()) {
      setFormError("दोनों नाम (Hindi और English) ज़रूरी हैं।");
      return;
    }
    if (isDuplicate(form.name_en, form.name_hi, form.id)) {
      setFormError("इस नाम की category पहले से मौजूद है।");
      return;
    }
    const payload = {
      name_hi: form.name_hi.trim(),
      name_en: form.name_en.trim(),
      icon_url: form.icon_url.trim() || null,
      sort_order: form.sort_order,
    };
    try {
      if (form.id) {
        await api.put(`/categories/${form.id}`, payload);
        showSuccess("Category update हो गई।");
      } else {
        await api.post("/categories", payload);
        showSuccess("Category बन गई।");
      }
      setForm(EMPTY_FORM);
      load();
    } catch (e) {
      showError(e instanceof ApiRequestError ? e.message : "Save नहीं हो पाया।");
    }
  }

  async function deactivate(c: Category) {
    try {
      await api.del(`/categories/${c.id}`);
      showSuccess(`${c.name_en} निष्क्रिय कर दी गई।`);
      load();
    } catch (e) {
      showError(e instanceof ApiRequestError ? e.message : "Deactivate नहीं हो पाया।");
    }
  }

  return (
    <div>
      <PageHeader title="Category Management" />

      <div className="two-col">
        <div>
          {loading ? (
            <LoadingBlock />
          ) : error ? (
            <ErrorBlock text={error} />
          ) : categories.length === 0 ? (
            <EmptyState text="कोई category नहीं है।" />
          ) : (
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>Name (EN / HI)</th>
                    <th>Sort</th>
                    <th>Status</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {categories.map((c) => (
                    <tr key={c.id}>
                      <td>
                        {c.name_en} / {c.name_hi}
                      </td>
                      <td>{c.sort_order}</td>
                      <td>
                        <span className={`badge ${c.is_active ? "badge-good" : "badge-bad"}`}>
                          {c.is_active ? "Active" : "Inactive"}
                        </span>
                      </td>
                      <td className="actions-cell">
                        <button
                          className="btn btn-ghost btn-sm"
                          onClick={() =>
                            setForm({
                              id: c.id,
                              name_hi: c.name_hi,
                              name_en: c.name_en,
                              icon_url: c.icon_url || "",
                              sort_order: c.sort_order,
                            })
                          }
                        >
                          Edit
                        </button>
                        {c.is_active && (
                          <ConfirmButton
                            label="Deactivate"
                            confirmText="Deactivate करें?"
                            className="btn btn-danger btn-sm"
                            onConfirm={() => deactivate(c)}
                          />
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        <form className="side-form" onSubmit={submitForm}>
          <h3>{form.id ? "Edit Category" : "Add New Category"}</h3>
          <label>Name (English)</label>
          <input value={form.name_en} onChange={(e) => setForm({ ...form, name_en: e.target.value })} required />
          <label>नाम (Hindi)</label>
          <input value={form.name_hi} onChange={(e) => setForm({ ...form, name_hi: e.target.value })} required />
          <label>Icon URL (optional)</label>
          <input value={form.icon_url} onChange={(e) => setForm({ ...form, icon_url: e.target.value })} />
          <label>Sort Order</label>
          <input
            type="number"
            value={form.sort_order}
            onChange={(e) => setForm({ ...form, sort_order: Number(e.target.value) })}
          />
          {formError && <div className="error-block">{formError}</div>}
          <div className="modal-actions">
            {form.id && (
              <button type="button" className="btn btn-ghost" onClick={() => setForm(EMPTY_FORM)}>
                Cancel
              </button>
            )}
            <button className="btn btn-primary" type="submit">
              {form.id ? "Update" : "Add"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
