"""Student Task Manager used by the Jenkins CI/CD laboratory."""

from __future__ import annotations

from typing import Optional

from flask import Flask, abort, jsonify, redirect, render_template, request, url_for


INITIAL_TASKS = [
    {"id": 1, "title": "Create Flask application", "completed": True},
    {"id": 2, "title": "Configure Jenkins pipeline", "completed": False},
]


def create_app(test_config: Optional[dict] = None) -> Flask:
    """Create an isolated application instance for production or tests."""
    app = Flask(__name__)
    app.config.from_mapping(TASKS=[task.copy() for task in INITIAL_TASKS])
    if test_config:
        app.config.update(test_config)

    @app.get("/")
    def index():
        return render_template("index.html", tasks=app.config["TASKS"])

    @app.post("/add")
    def add_task():
        title = request.form.get("title", "").strip()
        if title:
            tasks = app.config["TASKS"]
            next_id = max((task["id"] for task in tasks), default=0) + 1
            tasks.append({"id": next_id, "title": title, "completed": False})
        return redirect(url_for("index"))

    @app.post("/complete/<int:task_id>")
    def complete_task(task_id: int):
        task = next(
            (item for item in app.config["TASKS"] if item["id"] == task_id),
            None,
        )
        if task is None:
            abort(404)
        task["completed"] = True
        return redirect(url_for("index"))

    @app.get("/health")
    def health():
        return jsonify(status="UP")

    return app


app = create_app()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

