import pytest
from unittest.mock import patch, MagicMock
import sys
import os
import json

# Add the current directory to sys.path so we can import server
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from server import app
import server

@pytest.fixture
def client():
    app.testing = True
    with app.test_client() as client:
        yield client

@patch('requests.get')
def test_get_tba_team_data_success(mock_get, client):
    # Set the key for this test
    with patch('server.TBA_API_KEY', 'test_key'):
        # Mock response
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"nickname": "The FEDS", "team_number": 201}
        mock_get.return_value = mock_response

        # Call endpoint
        response = client.get('/api/tba/team/201')

        # Verify requests.get was called correctly
        mock_get.assert_called_with(
            "https://www.thebluealliance.com/api/v3/team/frc201",
            headers={"X-TBA-Auth-Key": 'test_key'}
        )

        # Verify response
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['nickname'] == "The FEDS"
        assert data['team_number'] == 201

        # Verify CORS header
        assert response.headers['Access-Control-Allow-Origin'] == '*'

@patch('requests.get')
def test_get_tba_team_data_failure(mock_get, client):
    with patch('server.TBA_API_KEY', 'test_key'):
        # Mock response failure
        mock_response = MagicMock()
        mock_response.status_code = 404
        mock_get.return_value = mock_response

        # Call endpoint
        response = client.get('/api/tba/team/999999')

        # Verify response
        assert response.status_code == 404
        data = json.loads(response.data)
        assert "error" in data

@patch('requests.get')
def test_get_tba_team_data_exception(mock_get, client):
    with patch('server.TBA_API_KEY', 'test_key'):
        # Mock exception
        mock_get.side_effect = Exception("Network error")

        # Call endpoint
        response = client.get('/api/tba/team/201')

        # Verify response
        assert response.status_code == 500
        data = json.loads(response.data)
        assert data['error'] == "Network error"

def test_get_tba_team_data_missing_key(client):
    # Set key to None
    with patch('server.TBA_API_KEY', None):
        # Call endpoint
        response = client.get('/api/tba/team/201')

        # Verify response
        assert response.status_code == 500
        data = json.loads(response.data)
        assert "TBA_API_KEY environment variable is not set" in data['error']


def test_event_page_and_api(client):
    # ensure event page renders empty list by default
    response = client.get('/event')
    assert response.status_code == 200
    assert b'No matches uploaded yet' in response.data or b'Event matches' in response.data

    # api should return json even if empty
    resp2 = client.get('/get_event_file')
    assert resp2.status_code == 200
    data = json.loads(resp2.data)
    assert isinstance(data, list)


def test_qr_generation_empty(client):
    # create empty db and call qr endpoint
    response = client.post('/generate_qrcode/1')
    assert response.status_code == 200
    assert response.content_type == 'image/png'


def test_logs_page(client):
    r = client.get('/logs')
    assert r.status_code == 200
    assert b'log' in r.data.lower() or b'no log' in r.data.lower()
kk