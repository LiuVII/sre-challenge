# src/tests/test_app.py
import pytest
from app.main import app

# src/tests/test_app.py
import pytest
from app.main import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_app_creates():
    """Basic test that app can be created"""
    assert app is not None

def test_health_check_live(client):
    """Test health check endpoint - should always work"""
    response = client.get('/health/live')
    assert response.status_code == 200
