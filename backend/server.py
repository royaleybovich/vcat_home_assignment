from flask import Flask, jsonify
import os
from datetime import datetime

app = Flask(__name__)


@app.route("/")
def root():
    return jsonify(
        status="ok",
        service="user-management-placeholder",
        env=os.getenv("APP_ENV", "local"),
        timestamp=datetime.utcnow().isoformat() + "Z",
    )


@app.route("/health")
def health():
    # ALB health check endpoint
    return "OK", 200


if __name__ == "__main__":
    port = int(os.getenv("PORT", "3000"))
    app.run(host="0.0.0.0", port=port)