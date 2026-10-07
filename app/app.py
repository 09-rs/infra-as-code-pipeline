from http.server import BaseHTTPRequestHandler, HTTPServer
import json


class ApplicationHandler(BaseHTTPRequestHandler):
    def send_json(self, status_code, payload):
        response = json.dumps(payload).encode("utf-8")

        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(response)))
        self.end_headers()
        self.wfile.write(response)

    def do_GET(self):
        if self.path == "/health":
            self.send_json(
                200,
                {
                    "status": "healthy",
		    "version": "v2",
                    "service": "infra-as-code-pipeline"
                }
            )
            return

        self.send_json(
            200,
            {
                "service": "infra-as-code-pipeline",
                "status": "running"
            }
        )

    def log_message(self, format, *args):
        return


if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", 5000), ApplicationHandler)
    print("Application listening on port 5000", flush=True)
    server.serve_forever()