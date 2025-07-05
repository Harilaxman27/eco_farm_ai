# 🌱 Eco Farm AI – Smart Assistant for Farmers

**Eco Farm AI** is a Flutter-based smart farming app designed to assist farmers across three categories: **Crop Farmers**, **Dairy Farmers**, and **Poultry Farmers**. It integrates AI tools, Firebase services, and financial tracking features to make farming smarter, more efficient, and data-driven.

---

## 🚜 Farmer Categories Supported

### 1. 🌾 Crop Farmers
- ✅ **AI-Based Crop Recommendation**
- ✅ **Crop Disease Detection using Image & AI**
- ✅ Income & Expense Financial Tracker

### 2. 🐄 Dairy Farmers
- ✅ Livestock Reminders:
  - Milking schedules
  - Heat cycles
  - Calving dates
  - Vaccinations
  - Health checks
- ✅ Dairy-Specific Financial Tracker

### 3. 🐔 Poultry Farmers
- 🔬 In Development:
  - Hen Disease Detection (AI-based)
  - Suggest Remedies & Treatments (via AI)
  - Poultry productivity tools

---

## 🧠 AI Features

- **Crop Recommendation** using environmental input (coming soon)
- **Image-Based Crop Disease Detection** via custom-trained models
- **Poultry Disease Identification** (planned using image/symptom input)
- AI models to be integrated using **TensorFlow Lite** or **Firebase ML**

---

## 🔧 Tech Stack

| Layer       | Tech Used                        |
|-------------|----------------------------------|
| Frontend    | Flutter + Dart                   |
| Backend     | Firebase Firestore, Auth, Storage|
| AI Models   | TensorFlow / PyTorch (trained separately) |
| Image Upload | Flutter `image_picker`, Camera |
| Auth        | Firebase Email/Password + Google Sign-In |

---

## 📁 Firebase Collections Structure

```bash
farmers/{uid}/cows               # Dairy cow data
remainder                        # Livestock reminders
farmers/{uid}/expenses           # Financial records
farmers/{uid}/poultry            # (Upcoming) Poultry records
