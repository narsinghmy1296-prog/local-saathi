import { Navigate, Route, Routes } from "react-router-dom";
import type { ReactNode } from "react";
import { useAuth } from "./auth/AuthContext";
import { Layout } from "./components/Layout";
import { LoginPage } from "./pages/LoginPage";
import { DashboardPage } from "./pages/DashboardPage";
import { SellersPage } from "./pages/SellersPage";
import { ProductsPage } from "./pages/ProductsPage";
import { CategoriesPage } from "./pages/CategoriesPage";
import { OrdersPage } from "./pages/OrdersPage";
import { OrderDetailPage } from "./pages/OrderDetailPage";
import { DeliveryPage } from "./pages/DeliveryPage";
import { ReportsPage } from "./pages/ReportsPage";
import { AuditLogPage } from "./pages/AuditLogPage";
import { SettingsPage } from "./pages/SettingsPage";

function RequireAdmin({ children }: { children: ReactNode }) {
  const { me, loading } = useAuth();
  if (loading) return <div className="loading-block">Loading…</div>;
  // The real enforcement is server-side (require_role(["admin"]) on every
  // admin endpoint) — this guard only keeps a non-admin from ever seeing
  // the panel's UI at all; it is not itself the security boundary.
  if (!me || me.role !== "admin") return <Navigate to="/login" replace />;
  return <>{children}</>;
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route
        path="/"
        element={
          <RequireAdmin>
            <Layout />
          </RequireAdmin>
        }
      >
        <Route index element={<DashboardPage />} />
        <Route path="sellers" element={<SellersPage />} />
        <Route path="products" element={<ProductsPage />} />
        <Route path="categories" element={<CategoriesPage />} />
        <Route path="orders" element={<OrdersPage />} />
        <Route path="orders/:orderId" element={<OrderDetailPage />} />
        <Route path="delivery" element={<DeliveryPage />} />
        <Route path="reports" element={<ReportsPage />} />
        <Route path="audit-log" element={<AuditLogPage />} />
        <Route path="settings" element={<SettingsPage />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
