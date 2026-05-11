from datetime import date

from pydantic import BaseModel, Field


class MLPredictionFeatures(BaseModel):
    past_yield_kg: float = Field(gt=0)
    market_price: float = Field(gt=0)
    variety: str = Field(min_length=1)
    mar_avg_temp: float = Field(ge=-5, le=25)
    aug_sunshine: float = Field(ge=50, le=400)
    oct_rainfall: float = Field(ge=0, le=600)
    aug_humidity: float = Field(ge=30, le=100)


class MLPredictionCreateRequest(BaseModel):
    farm_id: int
    product_id: int
    features: MLPredictionFeatures


class MLPredictionResponse(BaseModel):
    prediction_id: int
    predicted_harvest_start: date
    predicted_harvest_end: date
    estimated_yield_kg: float
    suggested_reservable_min_kg: float
    suggested_reservable_max_kg: float
    recommended_price: int
    confidence: float
    safety_factor: float
    warning_message: str
