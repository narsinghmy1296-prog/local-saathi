import { createContext, useCallback, useContext, useState } from "react";
import type { ReactNode } from "react";

interface ToastMessage {
  id: number;
  kind: "success" | "error";
  text: string;
}

interface ToastState {
  showSuccess: (text: string) => void;
  showError: (text: string) => void;
}

const ToastContext = createContext<ToastState | null>(null);

export function ToastProvider({ children }: { children: ReactNode }) {
  const [messages, setMessages] = useState<ToastMessage[]>([]);

  const push = useCallback((kind: ToastMessage["kind"], text: string) => {
    const id = Date.now() + Math.random();
    setMessages((prev) => [...prev, { id, kind, text }]);
    setTimeout(() => {
      setMessages((prev) => prev.filter((m) => m.id !== id));
    }, 4500);
  }, []);

  const value: ToastState = {
    showSuccess: (text) => push("success", text),
    showError: (text) => push("error", text),
  };

  return (
    <ToastContext.Provider value={value}>
      {children}
      <div className="toast-stack">
        {messages.map((m) => (
          <div key={m.id} className={`toast toast-${m.kind}`}>
            {m.text}
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export function useToast(): ToastState {
  const ctx = useContext(ToastContext);
  if (!ctx) throw new Error("useToast must be used within ToastProvider");
  return ctx;
}
