# General Information

## Business Context: SmartTech
### The Mission
SmartTech mission is to democratize access to high-quality education, making personalized learning accessible to students across Indonesia. The CEO's core directive for this phase is clear: "Design infrastructure sufficient to prove people want to use this product, not perfect infrastructure. Speed-to-market and cost efficiency are far more important than enterprise-grade resilience".  

This architecture is specifically designed to support the Beta Launch, targeting the first 500 to 1,000 students to validate Product-Market Fit (PMF).  

## ⚠️ The Problem & Business Constraints

This infrastructure is not built to be a flawless enterprise system. It is deliberately engineered to solve a specific problem under strict business constraints:
- 💰 Strict Budget (Max $150/Month): Cloud costs must absolutely remain under Rp 2.25 million/month to avoid draining the product's operational runway.  
- ⏳ Extremely Short Timeline: A hard deadline of 14 days to Go-Live to capture the critical momentum of the new school year.  
- 📈 Extreme Traffic Patterns: Usage is highly predictable, peaking massively during after-school hours (15:00-20:00 WIB) and dropping to near zero late at night.

## 💡 Architecture Rationale

To address these challenges, the AWS architecture in this repository treats simplicity as a business strategy. Key technical decisions include:  
- Speed & Cost over Perfection: Prioritizing fast go-to-market and cost-efficiency over expensive, complex fault-tolerance mechanisms.  
- Calculated SLA (95% Uptime): Sacrificing full High Availability (HA) because occasional 5-10 minute downtimes during the Beta phase are still acceptable to users, saving significant infrastructure costs.  
- Scheduled Scaling: Taking advantage of predictable student schedules to proactively scale server capacity up and down, drastically reducing idle resource costs.  
- Low Operational Overhead: Utilizing straightforward services that are easy to deploy and debug without requiring specialized DevOps resources.


Repositori ini sekarang disusun mengikuti tiga phase utama:

- phase-01-monolithic-ha: proof of concept dengan Terraform flat structure.
- phase-02-modular-infra: refactor ke modul reusable dan environment-based layout.
- phase-03-app-and-pipeline: integrasi aplikasi dan pipeline DevSecOps.

Struktur utamanya:

- [phase-01-monolithic-ha](phase-01-monolithic-ha)
- [phase-02-modular-infra](phase-02-modular-infra)
- [phase-03-app-and-pipeline](phase-03-app-and-pipeline)

Catatan belajar cloud, AWS, dan DevSecOps akan mengikuti perjalanan dari phase 1 sampai phase 3.

## Notes
 
- feat/ or bugfix/ : provisioning resource or new architecture 
- fix/ or bugfix/ : bug fix error or gap security 
- docs/ : new in README.md; architecture diagram; or notes learn 
- chore/ : maintancence or housekeeping not change infrastructure like new version in provider aws or clean .gitignore.
