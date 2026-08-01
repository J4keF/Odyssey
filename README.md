<p align="center">
  <img src="assets/odyssey_logo_orange_rounded.png" alt="Odyssey Logo" width="80" />
  <h1 align="center">Odyssey</h1>
  <p align="center"><em>Goal Tracking Made Intuitive</em></p>
</p>

---

Odyssey is a mobile app designed to help users achieve their goals. Instead of flat to-do lists, Odyssey creates hierarchy of progress: goals break into milestones, milestones into stepping stones and daily habits, and daily habits into streaks. Whether you're learning a language, finishing a research paper, or writing a short story, Odyssey gives you a clear map and keeps you moving towards your goal.

---

## Features

### Dashboard — *All your goals in one place.*
Each task streams live from Firestore. Progress bars, step counts, and completion percentages update in real time across devices.

### Task Page — *Break it down.*
Goals broken into milestones, each with target completion dates, stepping stones, and dailies. Completion state and streaks persist to Firestore.

### Routine — *Daily habits.*
Dailies are grouped from the Firestore task tree, and split into done and pending. Streak state resets automatically at midnight.

### Mentor ✦ — *Help charting your course.*
Specialized AI powered by the Gemini API. Full conversation history maintained across sessions.

### Account — *Personalization and settings.*
Firebase Auth supports email/password and Google OAuth. Theme color preference is applied app-wide. Dangerous actions are guarded by confirmation windows.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| AI | Google Gemini API |
| State | Provider (`ChangeNotifier`) |
| Platform | iOS |

---

## Author

**Jake Fogel**  
MS Computer Science — NYU Tandon

[linkedin.com/in/jakefogel/](https://linkedin.com/in/jakefogel/) | jakefogel@rogers.com
