# Security Policy

## Supported Versions

Security updates are applied to the latest release on the `main` branch.

| Version | Supported          |
| ------- | ------------------ |
| v0.3.x  | :white_check_mark: |
| v0.2.x  | :x:                |
| v0.1.x  | :x:                |

## Reporting a Vulnerability

We take the security of OMNI seriously. If you discover a vulnerability, please do not report it publicly. Instead, follow these steps:

1. **Email us**: Send a detailed report to [security@fajarhide.dev](mailto:security@fajarhide.dev).
2. **Details**: Include a description of the issue, steps to reproduce, and potential impact.
3. **Response**: We will acknowledge your report within 48 hours and provide a timeline for a fix.

## Security Considerations

- **Local-only processing**: OMNI processes all data locally. No data is sent to external servers during distillation.
- **Local Metrics data**: Usage stats stored in `~/.omni/metrics.csv` contain only aggregate metrics (timestamps, byte counts, latency), never the actual content. **No data ever leaves your machine.**
- **MCP Server**: The MCP server runs locally via `stdio` transport and does not expose any network ports.
- **`omni update`**: Only reads the public GitHub Releases API (no authentication required). No data is uploaded.

Thank you for helping keep OMNI secure!
