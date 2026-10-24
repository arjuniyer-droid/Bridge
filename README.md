# Bridge

**A clearer picture for your prescriber.**

Bridge is an iPhone app that helps people keep an accurate record of the medication they actually took and how much pain they were in, then turns it into a plain-language summary they can share with their doctor.

Website: [https://bridgehealthglobal.com/](https://bridgehealthglobal.com/)

> **Bridge gives no medical advice.** It makes no dosage recommendations, safety determinations, diagnoses, or risk scores. It does not replace your doctor's instructions or records. Your prescriber is the sole authority.

---

## Why Bridge exists

At an appointment, patients on prescription pain medication are often asked how much they have been taking over the past few weeks. Almost nobody can answer that accurately from memory. Bridge is a simple, truthful record that belongs to the patient and helps them answer that question.

Bridge is deliberately limited. It records what happened and shows it clearly. It never judges whether a dose was right. Every decision stays with the prescriber.

## Features

| Tab | What it does |
| --- | --- |
| **Today** | Log a dose in two taps: medication, amount, time, and a pain score from 0 to 10. Doses can be edited or deleted. |
| **My Plan** | Enter the prescriber's plan once: medication, amount per dose, and doses per day. When you log a dose, Bridge suggests medications and amounts from the plan. |
| **Patterns** | Charts of doses per day and average pain over the last 14 days, alongside the prescribed plan. Tap a day to edit its doses. Longer histories are grouped by week. |
| **Summary for my doctor** | A plain-language summary of the last 30 days: doses taken compared with the plan, average pain, and days with no doses logged. It opens the iOS share sheet so *you* choose where it goes. |
| **Support** | One-tap calls to the SAMHSA National Helpline and the Veterans Crisis Line (dial 988, then press 1). An "I'm a veteran" switch adds VA Palo Alto Health Care System resources. |
| **Settings** | Language (English, Español, 中文), text size, light or dark appearance, and a choice of calm accent colors. |

Also included:

- A short welcome on first launch that explains what Bridge does, that data stays on the phone, and that Bridge gives no medical advice.
- Friendly empty screens that explain what to do when there is no data yet.
- A reminder at the bottom of every screen: *"Bridge does not give medical advice. Your prescriber is the only authority."*
- Large, easy-to-tap controls and support for bigger text sizes.

## Privacy

- **No account.** You never sign up or log in. Bridge doesn't know who you are.
- **Your data stays on your phone.** Doses, pain scores, and the plan are saved on the device with SwiftData, Apple's built-in storage.
- **No server, no tracking.** Bridge has no server to send anything to, and no analytics or ads.
- **You decide what's shared.** The only way anything leaves the phone is when you tap Share on your doctor summary and choose where it goes.

## Built with

- **Swift and SwiftUI** for the interface
- **SwiftData** for on-device storage
- **Swift Charts** for the Patterns charts
- **String Catalogs** for English, Spanish, and Simplified Chinese

Requires **iOS 26.5 or later** and **Xcode 26**.

## Running the app

1. Clone the repository:
   ```
   git clone https://github.com/arjuniyer-droid/Bridge.git
   ```
2. Open `Bridge.xcodeproj` in Xcode.
3. At the top of the Xcode window, choose an **iPhone simulator** (not "My Mac").
4. Press **Run** (⌘R).

## Project structure

```
Bridge/
├── BridgeApp.swift            App entry point and on-device database
├── ContentView.swift          The tab bar
├── Localizable.xcstrings      English, Spanish, and Chinese text
├── Models/
│   ├── Dose.swift             One dose that was taken
│   ├── Plan.swift             The prescriber's plan
│   └── DoctorSummary.swift    Builds the 30-day summary
└── Views/
    ├── TodayView.swift        Today tab
    ├── MyPlanView.swift       My Plan tab
    ├── PatternsView.swift     Charts
    ├── SummaryPreviewSheet.swift   Summary preview and Share
    ├── SupportView.swift      Help lines and Privacy
    ├── SettingsView.swift     Language, text size, appearance
    ├── OnboardingView.swift   First-launch welcome
    ├── DesignSystem.swift     Colors, type, and spacing
    └── ...                    Forms, rows, and shared components
```

## About

Built by **Arjun Iyer**, a 9th grader, with **Sidharth Iyer** a 12th grader, advising on the science, on what clinicians want in a summary, and on keeping the app clear of medical advice. Both students are from Palo Alto High School, California.

### Use of AI

I built Bridge in SwiftUI using Claude as a coding assistant. I wrote the feature specifications, tested every build, debugged with the AI, and can explain every file in the project. I also got user feedback by working with seniors on the app and iterated over the product development to make it user friendly.

## If you need help now

- **Emergency:** call 911.
- **SAMHSA National Helpline:** 1-800-662-4357. Free, confidential, 24/7 treatment referral and information, in English and Spanish.
- **Veterans Crisis Line:** dial 988, then press 1, or text 838255.
