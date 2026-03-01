from flask import Flask, jsonify
from flask_cors import CORS
import pickle
import pandas as pd
import datetime

# ---------------------------------
# Initialize App
# ---------------------------------
app = Flask(__name__)
CORS(app)

# ---------------------------------
# Load Trained Model
# ---------------------------------
model = pickle.load(open("voicesewa_model.pkl", "rb"))

# ---------------------------------
# Static Config
# ---------------------------------
DISTRICTS = [
    "Mumbai - Andheri",
    "Mumbai - Borivali",
    "Thane - Ghodbunder",
    "Thane - Kalyan",
    "Navi Mumbai - Vashi",
    "Panvel"
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

    results = []

    for district in DISTRICTS:
        for job in JOBS:

            input_data = {
                "district": district,
                "season": season,
                "primarySkill": job,
                "experienceYears": 8,
                "jobsCompleted": 500,
                "isMultiTalented": 1
            }

            df = pd.DataFrame([input_data])
            df = pd.get_dummies(df)

            # Align with training features
            df = df.reindex(columns=model.feature_names_in_, fill_value=0)

            probability = model.predict_proba(df)[0][1]

            results.append({
                "district": district,
                "job": job,
                "demandProbability": round(float(probability), 3)
            })

    # Sort by highest demand
    results = sorted(results, key=lambda x: x["demandProbability"], reverse=True)

    return results

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