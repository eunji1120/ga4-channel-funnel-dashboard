# Release checklist

Run this before every share (link in an email, screen share, new screenshot).
Tick each item against the live report in an incognito window, not in edit mode.

## Content

- [ ] Page names and navigation are final (no default or non-English names)
- [ ] Every number in the talking points / email appears on screen, with the same definition and date range
- [ ] Date range and reporting time zone are stated in the data status bar
- [ ] Default filter values are "all" (no leftover selection from editing)
- [ ] Each filter affects the charts it should, and the ones it does not are labelled
- [ ] KPI names match the definitions on the Data Quality & Definitions page
- [ ] Attribution scope is labelled everywhere: "First-user channel", never just "channel"
- [ ] Event counts and session counts are named as such ("Sessions with add-to-cart" vs "add-to-cart events")
- [ ] Data refresh status is stated (this report: static sample, no refresh)
- [ ] Known issues list the affected dates, affected metrics, and what still holds
- [ ] Alerts separate what is confirmed from what is not (no unconfirmed root cause)

## Technical

- [ ] Public link opens without sign-in (incognito)
- [ ] Link with `?hl=en` shows English dates
- [ ] No blank charts, "data set configuration error" or loading errors on any page
- [ ] Layout checked on a laptop screen and a narrower window
- [ ] Sharing settings: viewers only, editing restricted
- [ ] BigQuery sandbox expiry: views were last created on 2026-10-23, so they expire around 2026-12-22. Re-run the `CREATE OR REPLACE VIEW` statements before 2026-12-15
- [ ] README, `sql/`, Looker report and talking points describe the same version; change log updated
