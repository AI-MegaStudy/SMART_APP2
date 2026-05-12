import unittest
from unittest.mock import patch

from fastapi import HTTPException

from backend.app.services.weather_feature_service import WeatherFeatureService


class WeatherFeatureServiceConfigTest(unittest.TestCase):
    def test_missing_kma_service_key_returns_503(self):
        service = WeatherFeatureService()

        with patch(
            "backend.app.services.weather_feature_service.settings.kma_asos_service_key",
            "",
        ):
            with self.assertRaises(HTTPException) as context:
                service.get_weather_features(target_year=2026, stn_id="136")

        self.assertEqual(context.exception.status_code, 503)
        self.assertEqual(
            context.exception.detail,
            "weather feature service is not configured",
        )

    def test_missing_kma_base_url_returns_503(self):
        service = WeatherFeatureService()

        with patch(
            "backend.app.services.weather_feature_service.settings.kma_asos_service_key",
            "test-service-key",
        ), patch(
            "backend.app.services.weather_feature_service.settings.kma_asos_base_url",
            "",
        ):
            with self.assertRaises(HTTPException) as context:
                service.get_weather_features(target_year=2026, stn_id="136")

        self.assertEqual(context.exception.status_code, 503)
        self.assertEqual(
            context.exception.detail,
            "weather feature service is not configured",
        )


if __name__ == "__main__":
    unittest.main()
