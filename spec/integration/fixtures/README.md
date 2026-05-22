# Integration SSL fixtures

These are throwaway certificates and keys for the Faraday transport integration specs.
They are committed on purpose. Do not reuse them outside the test suite.

- `ca.pem` / `ca.key`: self-signed test CA used to sign the server and client certificates.
- `server.cert` / `server.key`: HTTPS server certificate and key. Includes SANs for `127.0.0.1` and `localhost`.
- `client.cert` / `client.key`: client certificate and unencrypted key for mTLS tests.
- `client_encrypted.key`: the same client key encrypted with `test-password`, used to verify encrypted-key loading.

The certificates are 2048-bit RSA fixtures with fixed validity windows:

- `ca.pem`: valid from May 20, 2026 through May 17, 2036.
- `server.cert`: valid from May 20, 2026 through May 17, 2036.
- `client.cert`: valid from May 20, 2026 through May 17, 2036.

Regenerate these fixtures before May 17, 2036. Tests that need a CA directory
copy `ca.pem` to a temporary directory under its OpenSSL subject-hash filename.

The older SSL fixtures have their own validity windows:

- `client_cert.pem`: valid from October 15, 2010 through October 15, 2011.
  Already expired; tests only pass its bytes through and do not use it for live TLS verification.
- `client_encrypted_key_cert.pem`: valid from January 25, 2013 through January 18, 2043.
