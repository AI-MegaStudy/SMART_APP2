from pydantic import BaseModel, ConfigDict, Field


class QualityInspectionCreateRequest(BaseModel):
    procurement_item_id: int = Field(json_schema_extra={"example": 1})
    image_url: str = Field(
        json_schema_extra={
            "example": "https://cheng80.myqnapcloud.com/images/owner_demo/product_9_demo_yanggwang_product.png"
        }
    )
    owner_confirmed_grade: str | None = Field(default=None, json_schema_extra={"example": "A"})
    owner_decision: str | None = Field(default=None, json_schema_extra={"example": "PASS"})
    model_grade: str | None = Field(default=None, json_schema_extra={"example": "A"})
    freshness_score: float | None = Field(default=None, ge=0, le=100)
    color_score: float | None = Field(default=None, ge=0, le=100)
    roundness_score: float | None = Field(default=None, ge=0, le=100)
    bruise_probability: float | None = Field(default=None, ge=0, le=1)
    model_decision: str | None = Field(default=None, json_schema_extra={"example": "PASS"})
    model_version: str | None = Field(default=None)

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "procurement_item_id": 1,
                "image_url": "https://cheng80.myqnapcloud.com/images/owner_demo/product_9_demo_yanggwang_product.png",
                "owner_confirmed_grade": "A",
                "owner_decision": "PASS",
                "model_grade": "A",
                "freshness_score": 91.2,
                "color_score": 88.0,
                "roundness_score": 93.5,
                "bruise_probability": 0.06,
                "model_decision": "PASS",
                "model_version": "apple-single-image-v1",
            }
        }
    )


class QualityInspectionAnalyzeRequest(BaseModel):
    procurement_item_id: int = Field(json_schema_extra={"example": 1})
    image_url: str | None = Field(default=None, json_schema_extra={"example": "https://cdn.example.com/quality/apple_001.jpg"})
    persist_image: bool = Field(default=False, json_schema_extra={"example": False})

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "procurement_item_id": 1,
                "image_url": "https://cdn.example.com/quality/apple_001.jpg",
                "persist_image": False,
            }
        }
    )
