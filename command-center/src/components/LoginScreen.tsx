import { useState } from "react";
import { signInWithGoogle } from "../firebase";

export function LoginScreen() {
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function handleSignIn() {
    setBusy(true);
    setError(null);
    try {
      await signInWithGoogle();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Sign-in failed");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="login-screen">
      <div className="login-card">
        <p className="login-eyebrow">GuardianRoute</p>
        <h1>Road Safety Command Centre</h1>
        <p className="login-sub">
          Live hazards, Guardian Pulse™, and road risk — same Firebase project as
          the rider app. Sign in with Google to view operational data.
        </p>
        <button type="button" className="btn-primary" onClick={handleSignIn} disabled={busy}>
          {busy ? "Signing in…" : "Sign in with Google"}
        </button>
        {error && <p className="login-error">{error}</p>}
      </div>
    </div>
  );
}
