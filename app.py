from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import joblib
import numpy as np
import os

# Load ENV variables
from dotenv import load_dotenv
load_dotenv()

# Firebase Imports
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# =========================
# REQUEST MODELS
# =========================
class PredictionRequest(BaseModel):
    total_runs: float
    wickets_fallen: int
    balls_bowled: int
    target_runs: float

class FeedbackRequest(BaseModel):
    doc_id: str
    actual_result: int
    user_feedback: float

# =========================
# LOAD MODEL
# =========================
model = joblib.load("ipl_win_predictor_xgb.pkl")

# =========================
# INIT FASTAPI
# =========================
app = FastAPI()

# =========================
# ENABLE CORS (SECURE)
# =========================
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://your-project.web.app",
        "https://your-project.firebaseapp.com"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =========================
# INIT FIREBASE (SECURE ENV)
# =========================
cred = credentials.Certificate({
    "type": os.getenv("FIREBASE_TYPE"),
    "project_id": os.getenv("FIREBASE_PROJECT_ID"),
    "private_key_id": os.getenv("FIREBASE_PRIVATE_KEY_ID"),
    "private_key": os.getenv("FIREBASE_PRIVATE_KEY").replace("\\n", "\n"),
    "client_email": os.getenv("FIREBASE_CLIENT_EMAIL"),
    "client_id": os.getenv("FIREBASE_CLIENT_ID"),
    "auth_uri": os.getenv("FIREBASE_AUTH_URI"),
    "token_uri": os.getenv("FIREBASE_TOKEN_URI"),
})

firebase_admin.initialize_app(cred)
db = firestore.client()

# =========================
# ROOT API
# =========================
@app.get("/")
def home():
    return {"message": "IPL AI Win Predictor API Running 🚀"}

# =========================
# PREDICTION API
# =========================
@app.post("/predict")
def predict(request: PredictionRequest):
    try:
        total_runs = request.total_runs
        wickets_fallen = request.wickets_fallen
        balls_bowled = request.balls_bowled
        target_runs = request.target_runs

        # ---------------------
        # Derived Calculations
        # ---------------------
        balls_remaining = 120 - balls_bowled

        if balls_bowled == 0:
            current_run_rate = 0
        else:
            current_run_rate = total_runs / (balls_bowled / 6)

        runs_remaining = target_runs - total_runs

        if balls_remaining <= 0:
            required_run_rate = 999
        else:
            required_run_rate = runs_remaining / (balls_remaining / 6)

        if current_run_rate == 0:
            pressure_index = 999
        else:
            pressure_index = required_run_rate / current_run_rate

        # ---------------------
        # Rule-Based Corrections
        # ---------------------
        if wickets_fallen >= 9 and required_run_rate > 10:
            prob = 0.05

        elif balls_remaining < 6 and required_run_rate > 15:
            prob = 0.02

        elif required_run_rate < current_run_rate * 0.8:
            prob = 0.9

        else:
            input_data = np.array([[ 
                total_runs,
                wickets_fallen,
                balls_remaining,
                current_run_rate,
                required_run_rate,
                pressure_index
            ]])

            prob = model.predict_proba(input_data)[0][1]

        # ---------------------
        # SAVE TO FIREBASE
        # ---------------------
        doc_ref = db.collection("predictions").add({
            "total_runs": total_runs,
            "wickets_fallen": wickets_fallen,
            "balls_bowled": balls_bowled,
            "target_runs": target_runs,
            "balls_remaining": balls_remaining,
            "current_run_rate": current_run_rate,
            "required_run_rate": required_run_rate,
            "pressure_index": pressure_index,
            "predicted_probability": float(prob),
            "timestamp": datetime.utcnow()
        })

        doc_id = doc_ref[1].id

        return {
            "win_probability": float(prob),
            "prediction_id": doc_id
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# =========================
# FEEDBACK API
# =========================
@app.post("/feedback")
def feedback(request: FeedbackRequest):
    try:
        db.collection("predictions").document(request.doc_id).update({
            "actual_result": request.actual_result,
            "user_feedback": request.user_feedback,
            "feedback_timestamp": datetime.utcnow()
        })

        return {"message": "Feedback saved successfully"}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# =========================
# RUN SERVER (LOCAL ONLY)
# =========================
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
   
#uvicorn app:app --reload