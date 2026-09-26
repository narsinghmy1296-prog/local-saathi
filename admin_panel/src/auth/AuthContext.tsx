import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import type { ReactNode } from "react";
import { api, clearToken, getToken, onSessionExpired, setToken } from "../api/client";
import type { LoginResponse, Me } from "../types";

interface AuthState {
  me: Me | null;
  loading: boolean;
  error: string | null;
  login: (phone: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthState | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [me, setMe] = useState<Me | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const logout = useCallback(() => {
    clearToken();
    setMe(null);
  }, []);

  useEffect(() => {
    onSessionExpired(() => setMe(null));
  }, []);

  // On first load, if a token is already stored, re-validate it against
  // the real backend (GET /auth/me) rather than trusting whatever was
  // last decoded client-side — the token could have expired or the
  // account could have been deactivated since.
  useEffect(() => {
    const token = getToken();
    if (!token) {
      setLoading(false);
      return;
    }
    api
      .get<Me>("/auth/me")
      .then((user) => {
        if (user.role !== "admin") {
          clearToken();
          setMe(null);
        } else {
          setMe(user);
        }
      })
      .catch(() => {
        clearToken();
        setMe(null);
      })
      .finally(() => setLoading(false));
  }, []);

  const login = useCallback(async (phone: string, password: string) => {
    setError(null);
    const result = await api.post<LoginResponse>("/auth/login", { phone, password });
    if (result.role !== "admin") {
      throw new Error("यह account Admin नहीं है। केवल Admin login कर सकते हैं।");
    }
    setToken(result.access_token);
    const user = await api.get<Me>("/auth/me");
    setMe(user);
  }, []);

  const value = useMemo(() => ({ me, loading, error, login, logout }), [me, loading, error, login, logout]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
