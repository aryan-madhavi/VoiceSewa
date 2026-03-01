from flask import Flask, jsonify
from flask_cors import CORS
import pickle
import random
import pandas as pd
import datetime
import os

# ---------------------------------
# Initialize App
# ---------------------------------
app = Flask(__name__)
CORS(app)

# ---------------------------------
# Load Model & Feature List Safely
# ---------------------------------
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

model = pickle.load(open(os.path.join(BASE_DIR, "voicesewa_model.pkl"), "rb"))
model_features = pickle.load(open(os.path.join(BASE_DIR, "model_features.pkl"), "rb"))

# ---------------------------------
# Static Config
# ---------------------------------
DISTRICTS = [
    "Andheri",
    "Panvel",
    "Thane",
    "Virar"
]

JOBS = [
    "Electrician",
    "Plumber",
    "Carpenter",
    "Painter",
    "Appliance Technician",
    "House Cleaner",
    "Driver",
    "Cook",
    "Mechanic",
    "Masonry"
]

# ---------------------------------
# Month → Season Mapping
# ---------------------------------
def get_season(month):
    if month in [3,4,5]:
        return "Summer"
    elif month in [6,7,8,9]:
        return "Monsoon"
    elif month in [10,11]:
        return "Festival"
    else:
        return "Winter"

# ---------------------------------
# Core Forecast Logic
# ---------------------------------
def generate_forecast(season):

    final_results = []

    for district in DISTRICTS:

        job_scores = []

        for job in JOBS:

          

            input_data = {
                "jobsCompleted": random.randint(100, 400),
                "experienceYears": random.randint(3, 15),
                "isMultiTalented": random.choice([0, 1])
            }

            # Create dataframe
            df_test = pd.DataFrame([input_data])

            # One-hot encode
            df_test = pd.get_dummies(df_test)

            # Add missing columns from training
            for col in model_features:
                if col not in df_test.columns:
                    df_test[col] = 0

            # Ensure exact column order
            df_test = df_test[model_features]

            # Predict RAW regression score
            score = model.predict(df_test)[0]

            job_scores.append({
                "job": job,
                "rawScore": float(score)
            })

        # Normalize to 100%
        total_score = sum(j["rawScore"] for j in job_scores)

        for j in job_scores:
            percentage = (j["rawScore"] / total_score) * 100 if total_score > 0 else 0

            final_results.append({
                "district": district,
                "job": j["job"],
                "demandPercentage": round(percentage, 2)
            })

    # Sort by highest demand
    final_results = sorted(final_results, key=lambda x: x["demandPercentage"], reverse=True)

    return final_results

# ---------------------------------
# Health Check
# ---------------------------------
@app.route("/")
def home():
    return jsonify({
        "message": "VoiceSewa Forecast API Running 🚀"
    })

# ---------------------------------
# Current Month Forecast
# ---------------------------------
@app.route("/current-forecast", methods=["GET"])
def current_forecast():

    month = datetime.datetime.now().month
    season = get_season(month)

    forecast = generate_forecast(season)

    return jsonify({
        "season": season,
        "month": month,
        "top5": forecast[:5],
        "fullForecast": forecast
    })

# ---------------------------------
# Next Month Forecast
# ---------------------------------
@app.route("/next-forecast", methods=["GET"])
def next_forecast():

    current_month = datetime.datetime.now().month
    next_month = (current_month % 12) + 1
    season = get_season(next_month)

    forecast = generate_forecast(season)

    return jsonify({
        "season": season,
        "month": next_month,
        "top5": forecast[:5],
        "fullForecast": forecast
    })

# ---------------------------------
# Run Server
# ---------------------------------
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)