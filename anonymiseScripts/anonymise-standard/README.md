# Anonymisation SQL Scripts

These SQL scripts are designed to **mask or anonymise sensitive data** across different Bahmni modules — **OpenMRS**, **OpenELIS**, and **Odoo 16** — primarily for creating safe, privacy-compliant staging or demo environments.

## 📌 Overview

| Script Name | Application | Purpose |
|--------------|--------------|----------|
| `mask_openmrs_sensitive_data.sql` | **OpenMRS** | Masks patient identifiers, names, addresses, phone numbers, and other personally identifiable information (PII) in the OpenMRS database. |
| `mask_openelis_sensitive_data.sql` | **OpenELIS** | Masks patient-related data in the laboratory information system, such as names and identifiers, ensuring test results remain linked but anonymised. |
| `mask_odoo16_sensitive_data.sql` | **Odoo 16** | Masks customer, supplier, and employee details (like names, emails, contact numbers, and addresses) in the Odoo 16 ERP system used in Bahmni. |

---

## 🧠 Purpose

These scripts help organisations using Bahmni to:
- Use **realistic datasets** from production for testing or training.
- Ensure **no personally identifiable data (PII)** is exposed in staging, demo, or shared environments.
- Comply with **data protection and privacy regulations**.

---

