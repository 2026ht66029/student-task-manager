"""Automated tests executed locally and by Jenkins."""

import pytest

from app import create_app


@pytest.fixture()
def client():
    test_app = create_app({"TESTING": True})
    return test_app.test_client()


def test_home_page(client):
    response = client.get("/")
    assert response.status_code == 200
    assert b"Student Task Manager" in response.data


def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.get_json() == {"status": "UP"}


def test_add_task(client):
    response = client.post(
        "/add",
        data={"title": "Jenkins Lab"},
        follow_redirects=True,
    )
    assert response.status_code == 200
    assert b"Jenkins Lab" in response.data


def test_blank_task_is_ignored(client):
    response = client.post("/add", data={"title": "   "}, follow_redirects=True)
    assert response.status_code == 200
    assert response.data.count(b'<li class="task') == 2


def test_complete_task(client):
    response = client.post("/complete/2", follow_redirects=True)
    assert response.status_code == 200
    assert b"Configure Jenkins pipeline" in response.data
    assert b"Completed" in response.data


def test_unknown_task_returns_404(client):
    response = client.post("/complete/999")
    assert response.status_code == 404

