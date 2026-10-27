# TradeSense — Complete SwiftUI Starter

TradeSense is an iOS 16+ SwiftUI market analysis, paper-trading and investing simulator starter project. It uses generated demo data so the app can run without an API key.

**Disclaimer:** Not financial advice. Predictions are estimates and can be wrong. Demo data and heuristic scores are illustrative only.

## Included features

- Dark SwiftUI interface with Markets, Analysis, Simulations, Portfolio and More tabs
- Local generated OHLCV-style price history and demo company metrics
- RSI, MACD, SMA/EMA, Bollinger Bands, ATR, stochastic, volume trend, momentum, support and resistance calculations
- Weighted BUY/HOLD/AVOID heuristic with score-strength percentage and indicator explanations
- Short/long horizon toggle and low/medium/high risk profiles
- Stock detail chart using Swift Charts
- Watchlists and ticker search
- Demo fundamentals and keyword/demo sentiment feed
- Local paper-trade ledger and virtual cash
- Compound growth, DCA, what-if, position sizing and Monte Carlo-style scenario explorer
- Manual portfolio holdings, allocation chart and concentration warning
- Prediction logging and a pending accuracy tracker
- Local notification reminders and morning digest
- Face ID/passcode via LocalAuthentication
- CSV export via iOS share sheet
- XcodeGen project.yml and GitHub Actions unsigned IPA workflow

## Important implementation boundaries

This is a broad functional starter, not a verified production-grade investing terminal. The following items are placeholders or simplified demonstrations:
- Prices, historical bars, fundamentals, news and index moves are generated demo data.
- Finnhub is not yet connected across all screens. No live historical data, company fundamentals, earnings calendar, dividends or news API integration is performed.
- Market and limit order types, stop-loss/take-profit execution, broker integration, robust backtesting, realistic statistical Monte Carlo modelling, and automatic 5/30/90-day accuracy grading are not fully implemented.
- Local notifications schedule reminders; they do not continuously poll live prices while the app is closed. Background app refresh scheduling is not enabled in this starter.
- Confidence represents signal-strength heuristics, not a calibrated probability of profit.
- API key configuration is present but live integration is not wired throughout the app.

## Build prerequisites

- macOS with Xcode and an iOS 16+ SDK
- XcodeGen: `brew install xcodegen`
- GitHub account for the cloud workflow

## Build locally

```bash
brew install xcodegen
xcodegen generate
xcodebuild -project TradeSense.xcodeproj \
  -scheme TradeSense \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Package the unsigned app:

```bash
mkdir -p build/ipa/Payload
cp -R build/DerivedData/Build/Products/Release-iphoneos/TradeSense.app build/ipa/Payload/TradeSense.app
cd build/ipa
zip -qry ../../TradeSense-unsigned.ipa Payload
```

An unsigned IPA must be signed by your sideloading tool before installation. Tool requirements vary.

## GitHub Actions build instructions

1. Download and extract this ZIP.
2. Create an empty repository on GitHub.
3. In Terminal, `cd` into the extracted project folder and run:

   ```bash
   git init
   git add .
   git commit -m "Initial TradeSense app"
   git branch -M main
   git remote add origin https://github.com/YOUR-USERNAME/TradeSense.git
   git push -u origin main
   ```

   Replace `YOUR-USERNAME` with your GitHub username.

4. Open the repository's **Actions** tab and select **Build TradeSense IPA**.
5. The workflow runs on pushes to `main`; you can also manually select **Run workflow**.
6. Open a completed workflow run and download the `TradeSense-unsigned-ipa` artifact.
7. Use your sideloader to sign and install the IPA. The artifact expires after 14 days; rerun the workflow to generate another.

## Project structure

```text
TradeSense/
  TradeSenseApp.swift
  Models/MarketModels.swift
  Services/DemoData.swift
  Services/IndicatorEngine.swift
  Services/PredictionEngine.swift
  Services/NotificationService.swift
  Storage/LocalStore.swift
  ViewModels/TradeSenseStore.swift
  Views/MainTabView.swift
  Views/SharedComponents.swift
  Views/DashboardView.swift
  Views/AnalysisView.swift
  Views/WatchlistDetailView.swift
  Views/SimulationView.swift
  Views/PortfolioView.swift
  Views/ToolsView.swift
.github/workflows/build.yml
project.yml
```
