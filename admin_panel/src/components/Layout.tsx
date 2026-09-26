import { NavLink, Outlet } from "react-router-dom";
import { useState } from "react";
import { useAuth } from "../auth/AuthContext";

const NAV_ITEMS = [
  { to: "/", label: "Dashboard", icon: "📊", end: true },
  { to: "/sellers", label: "Sellers / विक्रेता", icon: "🏪" },
  { to: "/products", label: "Products / उत्पाद", icon: "📦" },
  { to: "/categories", label: "Categories / श्रेणियाँ", icon: "🗂️" },
  { to: "/orders", label: "Orders / ऑर्डर", icon: "🧾" },
  { to: "/delivery", label: "Delivery / डिलीवरी", icon: "🚚" },
  { to: "/reports", label: "Reports / रिपोर्ट", icon: "📈" },
  { to: "/audit-log", label: "Audit Log", icon: "🕘" },
  { to: "/settings", label: "Settings / सेटिंग्स", icon: "⚙️" },
];

export function Layout() {
  const { me, logout } = useAuth();
  const [navOpen, setNavOpen] = useState(false);

  return (
    <div className="app-shell">
      <header className="topbar">
        <button className="nav-toggle" onClick={() => setNavOpen((v) => !v)} aria-label="Menu">
          ☰
        </button>
        <div className="brand">Local Saathi <span>Admin</span></div>
        <div className="topbar-right">
          <span className="admin-name">{me?.name}</span>
          <button className="btn btn-ghost btn-sm" onClick={logout}>
            Logout
          </button>
        </div>
      </header>
      <div className="app-body">
        <nav className={`sidebar ${navOpen ? "sidebar-open" : ""}`}>
          {NAV_ITEMS.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.end}
              className={({ isActive }) => `nav-item ${isActive ? "nav-item-active" : ""}`}
              onClick={() => setNavOpen(false)}
            >
              <span className="nav-icon">{item.icon}</span>
              <span>{item.label}</span>
            </NavLink>
          ))}
        </nav>
        <main className="content">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
