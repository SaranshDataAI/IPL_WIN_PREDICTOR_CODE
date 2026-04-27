[README_IPL_AI_Win_Predictor.md](https://github.com/user-attachments/files/27115079/README_IPL_AI_Win_Predictor.md)
# 🏏 IPL AI Win Predictor

An advanced real-time cricket match win probability prediction system built using Machine Learning, FastAPI, and Firebase.

🌐 **Live Demo:** https://regal-kitsune-23c584.netlify.app

---

## 🚀 Overview

This project predicts the winning probability of a chasing team during an IPL T20 cricket match using live match conditions.

The system analyzes match pressure in real time using:

- Current Runs
- Wickets Fallen
- Balls Bowled
- Target Score
- Required Run Rate
- Current Run Rate
- Pressure Index

---

## 🧠 Machine Learning Model

Model Used:

- XGBoost Classifier

The model predicts:

```python
Win Probability (0 to 1)
```

Example:

- 0.82 = 82% chance to win
- 0.17 = 17% chance to win

---

## ⚡ Smart Rule Engine

To improve realism, rule-based corrections are added before ML prediction.

Examples:

- 9 wickets down + high RRR → Low chance
- Last over + huge runs needed → Near impossible
- Required RR below current RR → Strong winning chance

---

## 🛠️ Tech Stack

### Backend
- FastAPI
- Python
- Uvicorn

### Machine Learning
- XGBoost
- NumPy
- Joblib

### Database
- Firebase Firestore

### Frontend
- Netlify Hosted Web App

---

## 📂 Project Structure

```bash
project/
│── main.py
│── ipl_win_predictor_xgb.pkl
│── requirements.txt
│── .env
```

---

## 🔥 API Endpoints

### Health Check

```http
GET /
```

### Predict Win Probability

```http
POST /predict
```

### Submit Feedback

```http
POST /feedback
```

---

## 📊 Feature Engineering

Derived real-time features:

- Balls Remaining
- Current Run Rate
- Required Run Rate
- Pressure Index

---

## 🔥 Firebase Logging

Stores predictions, timestamps, inputs, feedback, and actual results for future retraining.

---

## 🌐 Live Demo

👉 https://regal-kitsune-23c584.netlify.app

---

## ▶️ Run Locally

```bash
git clone https://github.com/yourusername/ipl-win-predictor.git
cd ipl-win-predictor
pip install -r requirements.txt
uvicorn main:app --reload
```

---

## 🔐 Environment Variables

```env
FIREBASE_TYPE=
FIREBASE_PROJECT_ID=
FIREBASE_PRIVATE_KEY=
FIREBASE_CLIENT_EMAIL=
```

---

## 📈 Future Improvements

- Team-wise historical factors
- Venue impact
- Toss effect
- Player-level live data
- Momentum graphs
- Mobile app version

---

## 👨‍💻 Author

**Saransh Sharma**

Machine Learning Engineer | AI Developer | Full Stack Builder

---

## ⭐ If you like this project

Give it a star on GitHub ⭐
