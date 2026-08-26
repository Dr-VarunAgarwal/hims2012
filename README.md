# 🏥 HIMS MBBS 2012 — 15th Reunion Financial Ledger & Audit Trail

A fully transparent, open-ledger financial dashboard and self-service attendee portal designed for the **MBBS Batch of 2012 (15th Anniversary Reunion)** at the **Himalayan Institute of Medical Sciences (HIMS), Dehradun**, taking place on **March 26–27, 2027**.

Hosted 100% free with zero backend infrastructure on **GitHub Pages**.

---

## 🌟 Key Capabilities

1. **👑 Organizer Admin Panel:**
   - **Executive Treasury KPIs:** Total Inflow Collected, Actual Outflow Spent, Liquid Treasury Balance, and Forecast Reserve Margin.
   - **Diagnostic Health Status:** Automated surplus/deficit detection with budget runway indicators.
   - **Interactive Headcount Simulator:** Test attendance permutations (Batchmates, Spouses, Kids) and calculate exact breakeven attendance.
   - **Open Expense Ledger:** Comprehensive tracking of resort booking, catering, customized batch hoodies, DJ & stage audio, photography/drone coverage, and decor.
   - **Attendee Reconciliation:** Verify payments, track balance dues, and record hoodie sizing & food preferences.

2. **🎟️ Doctor Attendee Self-Service Portal:**
   - **Live Event Countdown:** Real-time clock ticking down to **March 26, 2027**.
   - **Digital Reunion Pass:** Personalized VIP ticket badge with Pass ID, Package Tier, confirmed attendance status, and check-in QR.
   - **Payment & Dues Account:** Clear view of tier fee, amount paid, balance due, and UPI payment details (`hims2012reunion@okaxis`).
   - **Campus Nostalgia Schedule:** Day-by-day itinerary including HIMS campus nostalgia walk, 15th gala banquet, batch group portrait, and foothills bonfire.

3. **👤 Contributor Attribution ("Who Added What"):**
   - Simple dropdown picker on all expense and payment logging forms (e.g. *Dr. Varun Agarwal*, *Dr. Rohan Sharma*, *Dr. Pooja Verma*, etc.).
   - No complex authentication required—simple choose-and-add attribution.

4. **🛡️ Transparent Change & Audit Log:**
   - Chronological change log recording every single action, author name, timestamp, and modification details.
   - Fully searchable, filterable by doctor, and exportable to CSV.

---

## 📁 Repository Structure

```text
├── index.html              # Main interactive single-page app (Tailwind + Chart.js)
├── data.json               # Central event data store (Config, Projections, Ledger, Roster, Change Log)
├── expenses_template.csv   # Spreadsheet template for offline expense logging
├── roster_template.csv     # Spreadsheet template for attendee registrations
├── changelog_template.csv  # Spreadsheet template for audit logs
└── README.md               # Documentation and governance guide
```

---

## 🚀 Quick Deployment to GitHub Pages

1. Create a public repository on GitHub (e.g. `hims-mbbs-2012-reunion`).
2. Upload `index.html` and `data.json` to the root folder.
3. In GitHub, go to **Settings** -> **Pages**, select branch `main` and folder `/ (root)`, then click **Save**.
4. The dashboard is live at `https://<your-username>.github.io/<repo-name>/`!