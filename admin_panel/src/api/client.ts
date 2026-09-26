const RAW_BASE = import.meta.env.VITE_API_BASE_URL as string | undefined;

if (!RAW_BASE) {
  // Fail loudly at build/dev time rather than silently hitting the
  // wrong host — better than a confusing runtime network error.
  // eslint-disable-next-line no-console
  console.error(
    "VITE_API_BASE_URL is not set. Copy .env.example to .env and set it."
  );
}

const API_BASE = (RAW_BASE || "").replace(/\/$/, "");
const TOKEN_KEY = "local_saathi_admin_token";

export function getToken(): string | null {
  return localStorage.getItem(TOKEN_KEY);
}

export function setToken(token: string): void {
  localStorage.setItem(TOKEN_KEY, token);
}

export function clearToken(): void {
  localStorage.removeItem(TOKEN_KEY);
}

/**
 * Thrown for any non-2xx response. `status` lets callers distinguish
 * "not found" (404) from "not allowed" (403) from "session expired" (401)
 * without re-parsing the message.
 */
export class ApiRequestError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.status = status;
    this.name = "ApiRequestError";
  }
}

// A single place other modules can subscribe to "the session just
// expired" so the app can redirect to /login without every single
// page needing to know about it.
type SessionExpiredHandler = () => void;
let sessionExpiredHandler: SessionExpiredHandler | null = null;
export function onSessionExpired(handler: SessionExpiredHandler) {
  sessionExpiredHandler = handler;
}

interface RequestOptions {
  method?: "GET" | "POST" | "PUT" | "PATCH" | "DELETE";
  body?: unknown;
  query?: Record<string, string | number | boolean | undefined | null>;
}

function buildQuery(query?: RequestOptions["query"]): string {
  if (!query) return "";
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(query)) {
    if (value === undefined || value === null || value === "") continue;
    params.set(key, String(value));
  }
  const qs = params.toString();
  return qs ? `?${qs}` : "";
}

async function request<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const token = getToken();
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (token) headers.Authorization = `Bearer ${token}`;

  let response: Response;
  try {
    response = await fetch(`${API_BASE}/api/v1${path}${buildQuery(options.query)}`, {
      method: options.method || "GET",
      headers,
      body: options.body !== undefined ? JSON.stringify(options.body) : undefined,
    });
  } catch {
    throw new ApiRequestError(0, "Backend से connect नहीं हो पाया। Server चल रहा है या नहीं जांचें।");
  }

  if (response.status === 401) {
    clearToken();
    if (sessionExpiredHandler) sessionExpiredHandler();
    throw new ApiRequestError(401, "Session expire हो गया, फिर से login करें।");
  }

  if (!response.ok) {
    let detail = `Error ${response.status}`;
    try {
      const data = await response.json();
      if (data?.detail) {
        detail = typeof data.detail === "string" ? data.detail : JSON.stringify(data.detail);
      }
    } catch {
      // response wasn't JSON — keep the generic message
    }
    throw new ApiRequestError(response.status, detail);
  }

  if (response.status === 204) {
    return undefined as T;
  }
  return (await response.json()) as T;
}

export const api = {
  get: <T>(path: string, query?: RequestOptions["query"]) => request<T>(path, { method: "GET", query }),
  post: <T>(path: string, body?: unknown, query?: RequestOptions["query"]) =>
    request<T>(path, { method: "POST", body, query }),
  put: <T>(path: string, body?: unknown) => request<T>(path, { method: "PUT", body }),
  patch: <T>(path: string, body?: unknown) => request<T>(path, { method: "PATCH", body }),
  del: <T>(path: string) => request<T>(path, { method: "DELETE" }),
};

export { API_BASE };
