import { useState } from "react";
import type { FormEvent } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";

export function LoginPage() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setBusy(true);
    try {
      await login(phone.trim(), password);
      navigate("/", { replace: true });
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login नहीं हो पाया।");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="login-page">
      <form className="login-card" onSubmit={onSubmit}>
        <h1>Local Saathi</h1>
        <p className="login-subtitle">Admin Control Panel</p>

        <label htmlFor="phone">Mobile Number</label>
        <input
          id="phone"
          type="tel"
          inputMode="numeric"
          placeholder="10-digit mobile number"
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
          autoFocus
          required
        />

        <label htmlFor="password">Password</label>
        <input
          id="password"
          type="password"
          placeholder="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
        />

        {error && <div className="error-block">{error}</div>}

        <button className="btn btn-primary" type="submit" disabled={busy}>
          {busy ? "Login हो रहा है…" : "Login"}
        </button>

        <p className="login-note">केवल Admin account से login हो सकता है।</p>
      </form>
    </div>
  );
}
