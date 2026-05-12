from datetime import date, timedelta
from functools import lru_cache
from pathlib import Path

from fastapi import HTTPException
import joblib
import pandas as pd
from sqlalchemy.orm import Session

from backend.app.models.ml_prediction import MLPrediction
from backend.app.repositories.farm_repo import FarmRepository
from backend.app.repositories.product_repo import ProductRepository
from backend.app.services.weather_feature_service import WeatherFeatureService

MODEL_PATH = Path(__file__).resolve().parents[1] / "ml_models" / "model.joblib"
MODEL_VERSION = "rf-apple-harvest-v1"
MODEL_FEATURES = ["mar_avg_temp", "aug_sunshine", "oct_rainfall", "aug_humidity"]


@lru_cache(maxsize=1)
def _load_model():
    return joblib.load(MODEL_PATH)


def serialize_prediction(prediction: MLPrediction) -> dict:
    snapshot = prediction.open_api_snapshot_json or {}
    data = {
        "prediction_id": prediction.prediction_id,
        "farm_id": prediction.farm_id,
        "product_id": prediction.product_id,
        "unit_yield_kg_10a": snapshot.get("unit_yield_kg_10a"),
        "predicted_harvest_start": prediction.predicted_harvest_start,
        "predicted_harvest_end": prediction.predicted_harvest_end,
        "estimated_yield_kg": float(prediction.estimated_yield_kg),
        "suggested_reservable_min_kg": float(prediction.suggested_reservable_min_kg),
        "suggested_reservable_max_kg": float(prediction.suggested_reservable_max_kg),
        "recommended_price": prediction.recommended_price,
        "confidence": float(prediction.confidence),
        "safety_factor": float(prediction.safety_factor),
        "warning_message": prediction.warning_message,
        "model_version": prediction.model_version,
    }
    weather_bundle = snapshot.get("weather_feature_snapshot")
    if isinstance(weather_bundle, dict):
        data["weather_features"] = {
            "mar_avg_temp": weather_bundle.get("mar_avg_temp"),
            "aug_sunshine": weather_bundle.get("aug_sunshine"),
            "oct_rainfall": weather_bundle.get("oct_rainfall"),
            "aug_humidity": weather_bundle.get("aug_humidity"),
        }
        data["weather_source"] = {
            "source": weather_bundle.get("source"),
            "fallback_used": weather_bundle.get("fallback_used"),
            "fallback_year": weather_bundle.get("fallback_year"),
            "fallback_reason": weather_bundle.get("fallback_reason"),
            "feature_source_years": weather_bundle.get("feature_source_years"),
        }
    return data


class MLService:
    def __init__(self, session: Session):
        self.session = session
        self.farm_repo = FarmRepository(session)
        self.product_repo = ProductRepository(session)
        self.weather_feature_service = WeatherFeatureService()

    def create_prediction(self, owner_id: int, payload: dict) -> dict:
        features, weather_bundle = self.weather_feature_service.merge_weather_features(payload["features"])
        prediction = self._create_prediction_record(
            owner_id=owner_id,
            farm_id=payload["farm_id"],
            product_id=payload["product_id"],
            features=features,
            weather_bundle=weather_bundle,
        )
        return serialize_prediction(prediction)

    def create_prediction_with_auto_weather(self, owner_id: int, payload: dict) -> dict:
        weather_bundle = self.weather_feature_service.get_weather_features(
            target_year=payload["target_year"],
            stn_id=payload.get("stn_id"),
        )
        features = {
            "past_yield_kg": payload["past_yield_kg"],
            "market_price": payload["market_price"],
            "variety": payload["variety"],
            "target_year": payload["target_year"],
            "stn_id": weather_bundle["stn_id"],
            "mar_avg_temp": weather_bundle["mar_avg_temp"],
            "aug_sunshine": weather_bundle["aug_sunshine"],
            "oct_rainfall": weather_bundle["oct_rainfall"],
            "aug_humidity": weather_bundle["aug_humidity"],
        }
        prediction = self._create_prediction_record(
            owner_id=owner_id,
            farm_id=payload["farm_id"],
            product_id=payload["product_id"],
            features=features,
            weather_bundle=weather_bundle,
        )
        return serialize_prediction(prediction)

    def _create_prediction_record(
        self,
        *,
        owner_id: int,
        farm_id: int,
        product_id: int,
        features: dict,
        weather_bundle: dict | None,
    ) -> MLPrediction:
        farm = self.farm_repo.get(farm_id)
        product = self.product_repo.get(product_id)
        if not farm or farm.owner_id != owner_id:
            raise HTTPException(status_code=404, detail="farm not found")
        if not product or product.farm_id != farm.farm_id:
            raise HTTPException(status_code=404, detail="product not found")

        unit_yield_kg_10a = self._predict_unit_yield(features)
        variety_weight = 1.1 if str(features["variety"]) == "부사" else 1.0
        estimated_yield_kg = round(
            (unit_yield_kg_10a / 1500.0)
            * float(features["past_yield_kg"])
            * variety_weight,
            2,
        )
        safety_factor = 0.8 if float(features["oct_rainfall"]) < 200 else 0.6
        start = self._harvest_start(float(features["mar_avg_temp"]))
        end = start + timedelta(days=14)

        prediction = MLPrediction(
            farm_id=farm.farm_id,
            product_id=product.product_id,
            created_by_owner_id=owner_id,
            input_feature_json=features,
            open_api_snapshot_json={
                "source": weather_bundle["source"] if weather_bundle else "manual_input",
                "unit_yield_kg_10a": round(unit_yield_kg_10a, 2),
                "model_path": str(MODEL_PATH),
                "weather_feature_snapshot": weather_bundle,
            },
            predicted_harvest_start=start,
            predicted_harvest_end=end,
            estimated_yield_kg=estimated_yield_kg,
            suggested_reservable_min_kg=round(estimated_yield_kg * 0.4, 2),
            suggested_reservable_max_kg=round(estimated_yield_kg * safety_factor, 2),
            recommended_price=int(float(features["market_price"]) * variety_weight),
            confidence=0.78,
            safety_factor=safety_factor,
            warning_message="정상"
            if float(features["oct_rainfall"]) < 200
            else "수확기 강수량 주의 필요",
            model_version=MODEL_VERSION,
        )
        self.session.add(prediction)
        self.session.commit()
        self.session.refresh(prediction)
        return prediction

    def _predict_unit_yield(self, features: dict) -> float:
        if not MODEL_PATH.exists():
            raise HTTPException(status_code=500, detail="ml model file not found")
        model = _load_model()
        input_data = pd.DataFrame(
            [[float(features[name]) for name in MODEL_FEATURES]],
            columns=MODEL_FEATURES,
        )
        return float(model.predict(input_data)[0])

    def _harvest_start(self, mar_avg_temp: float) -> date:
        today = date.today()
        harvest_year = today.year if today.month < 11 else today.year + 1
        base = date(harvest_year, 10, 20)
        return base - timedelta(days=int((mar_avg_temp - 10) * 2))

    def list_predictions(self, owner_id: int) -> list[dict]:
        rows = (
            self.session.query(MLPrediction)
            .filter(MLPrediction.created_by_owner_id == owner_id)
            .order_by(MLPrediction.created_at.desc())
            .all()
        )
        return [serialize_prediction(row) for row in rows]

    def get_prediction(self, owner_id: int, prediction_id: int) -> dict:
        prediction = self.session.get(MLPrediction, prediction_id)
        if not prediction or prediction.created_by_owner_id != owner_id:
            raise HTTPException(status_code=404, detail="prediction not found")
        return serialize_prediction(prediction)
