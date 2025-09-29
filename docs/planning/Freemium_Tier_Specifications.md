# 📊 Bookshelf Scanner - Freemium Tier Specifications

## 🎯 Overview

The Bookshelf Scanner adopts a freemium business model to balance user acquisition with sustainable revenue generation. This document outlines the tier specifications, cost estimates, revenue projections, and strategic considerations.

This freemium model builds upon the core functionality outlined in the [MVP Plan and User Journey](MVP_Plan_and_User_Journey.md), which details the 90% complete bookshelf scanning and library management features.

## 🆓 Free Tier Specifications

### Core Features (Always Free)
- ✅ Ad-free experience
- ✅ Basic bookshelf scanning
- ✅ Manual book addition with ISBN lookup
- ✅ Reading progress tracking
- ✅ Offline functionality
- ✅ Cross-device synchronization
- ✅ Books metadata (sub-genre, page count, reading time etc)
- ✅ Book author bio, teaser/summary (AI based)

### Usage Limits
- **AI Scans**: 20 per month
- **Books in Library**: 25 books
- **AI Recommendations**: 5 live recommendations per month
- **Storage**: Unlimited reading progress data

### Upgrade Triggers
Users are prompted to upgrade when they:
- Reach 20 AI scans in a month
- Attempt to add their 26th book
- Request their 6th AI recommendation in a month

## 💎 Premium Tier Specifications

### Pricing
- **Monthly**: $2.99 USD monthly (region-dependent)
- **Annual**: $29.99 (17% savings)

**Note**: Pricing is region-dependent and may vary by currency and local market conditions.

### Unlimited Features
- **AI Scans**: Unlimited bookshelf scanning
- **Books in Library**: Unlimited books
- **AI Recommendations**: Unlimited personalized recommendations
- **Advanced Analytics**: Detailed reading statistics and insights
- **Priority Support**: Direct customer support access
- **Export Features**: Full library export capabilities

### Exclusive Features
- **Bulk Operations**: Import/export multiple books
- **Advanced Filtering**: Complex search and organization
- **Reading Streaks**: Gamification and streak tracking
- **Custom Categories**: Personalized book categorization
- **Reading Goals**: Advanced goal setting and tracking
- ✅ Books metadata (sub-genre, page count, reading time etc)
- ✅ Book author bio, teaser/summary (AI based)

## 💰 Cost Analysis

### AI Service Costs (Per User/Month)

#### Free Tier Usage
- **Gemini Vision API**: 20 scans × $0.0025 = $0.05
- **Grok AI API**: 5 recommendations × $0.001 = $0.005
- **Total Free Tier Cost**: $0.055

#### Premium Tier Usage (Estimated)
- **Gemini Vision API**: 100 scans × $0.0025 = $0.25
- **Grok AI API**: 50 recommendations × $0.001 = $0.05
- **Total Premium Tier Cost**: $0.30

### Infrastructure Costs
- **Firebase Hosting**: $0.02/user/month
- **Firebase Database**: $0.05/user/month
- **CDN & Bandwidth**: $0.03/user/month
- **Total Infrastructure**: $0.10/user/month

## 📈 Revenue Projections

### User Acquisition Assumptions
- **Monthly Active Users (MAU)**: 10,000 (Year 1 target)
- **Free/Premium Split**: 70% free, 30% premium
- **Conversion Rate**: 15% of free users convert to premium
- **Churn Rate**: 5% monthly for premium users

### Revenue Calculations

#### Monthly Recurring Revenue (MRR)
```
Free Users: 10,000 × 70% = 7,000
Premium Users: 10,000 × 30% = 3,000
MRR = 3,000 × $2.99 = $8,970
```

#### Annual Recurring Revenue (ARR)
```
ARR = MRR × 12 = $8,970 × 12 = $107,640
```

#### Customer Acquisition Cost (CAC)
- **Marketing Spend**: $50,000/year
- **CAC**: $50,000 ÷ 10,000 users = $5/user

#### Lifetime Value (LTV)
```
Average Premium Tenure: 12 months
LTV = $2.99 × 12 = $35.88
LTV/CAC Ratio: $35.88 ÷ $5 = 7.18
```

## 🎯 Strategic Impact Assessment

### Cost Control Benefits
- **Free Tier Limits**: Prevent abuse while providing value
- **Progressive Disclosure**: Users discover premium value gradually
- **Usage-Based Conversion**: Natural upgrade triggers based on engagement

### Upgrade Incentive Optimization
- **Value Anchoring**: Free tier establishes perceived value
- **Feature Gating**: Premium features solve real user pain points
- **Social Proof**: Premium users demonstrate advanced capabilities
- **Urgency Creation**: Monthly limits create natural upgrade timing

### Risk Mitigation
- **Cost Monitoring**: Real-time usage tracking prevents budget overruns
- **A/B Testing**: Test different limits and pricing
- **Competitive Analysis**: Monitor similar app monetization strategies
- **User Feedback**: Regular surveys on pricing and feature value

## 📊 Key Metrics to Monitor

### Business Metrics
- **Conversion Rate**: Free to premium conversion
- **ARPU**: Average revenue per user
- **LTV/CAC Ratio**: Customer economics health
- **Churn Rate**: Premium user retention

### Product Metrics
- **Feature Usage**: Which premium features drive conversions
- **Limit Hit Rate**: How often users reach free tier limits
- **Time to Convert**: Average time from signup to premium
- **Engagement Correlation**: Premium vs free user engagement

## 🔄 Implementation Roadmap

### Phase 1: Foundation (Month 1)
- Implement usage tracking and limits
- Add upgrade prompts and paywall
- Set up subscription infrastructure
- Update signup page to display tier options (free and pro) and allow users to select a tier during signup - UI updates to signup flow and backend integration for tier selection

### Phase 2: Optimization (Month 2-3)
- A/B test pricing and limits
- Optimize upgrade flow
- Implement advanced analytics

### Phase 3: Scale (Month 4+)
- Expand premium features
- Optimize conversion funnel
- Implement referral programs

## 📋 Success Criteria

### Financial Targets
- **MRR**: $15,000 by end of Year 1
- **Profitability**: Positive unit economics within 6 months
- **LTV/CAC**: >3:1 ratio maintained

### Product Targets
- **User Satisfaction**: >4.5 star rating maintained
- **Conversion Rate**: >10% free to premium
- **Retention**: >80% premium user retention at 6 months
## 📋 Comprehensive Implementation Plan

### 1. Step-by-Step Feature Additions

#### Backend User Tiers
1. Define `UserTier` enum in Swift with cases: `free`, `premium`.
2. Extend the `User` model struct to include `tier: UserTier` and `subscriptionId: String?`.
3. Update `AuthService` to fetch user tier from Firestore on login.
4. Add Firestore security rules to allow users to read/write their own tier.
5. Create API functions for updating user tier based on subscription status.

#### UI Limits Implementation
1. Create a `UsageTracker` singleton class to track monthly scans, books count, recommendations.
2. Implement limit checking functions: `canPerformScan()`, `canAddBook()`, `canGetRecommendation()`.
3. Modify `CameraView` to check limits before scanning and show upgrade prompt if exceeded.
4. Update `AddBookView` to enforce book limit.
5. Add usage display in `ProfileView` showing current vs limits.
6. Implement upgrade prompt dialogs with navigation to subscription screen.
7. Update signup page to display tier options (free and premium) and allow users to select a tier during signup - include UI updates to signup flow for tier selection and backend integration to set initial user tier based on selection.

#### Payment Integration
1. Integrate RevenueCat SDK for iOS subscription management.
2. Configure products in App Store Connect: monthly ($2.99) and annual ($29.99) subscriptions.
3. Create `SubscriptionView` for purchasing and managing subscriptions.
4. Handle purchase flow: initiate purchase, validate receipt, update user tier.
5. Implement subscription status listener to update tier on renew/cancel.
6. Add restore purchases functionality.

### 2. Testing Plan

#### Unit Tests
- Test `UserTier` enum and model extensions.
- Test `UsageTracker` calculations and limit checks.
- Test `AuthService` tier fetching and updating.
- Test payment status parsing and tier updates.

#### Integration Tests
- Test end-to-end scan flow with limit enforcement.
- Test subscription purchase and tier upgrade.
- Test API calls for user data with tier restrictions.
- Test offline functionality with cached limits.

#### User Acceptance Testing
- Recruit 50-100 beta users for testing.
- Provide test scenarios: reaching limits, upgrading, downgrading.
- Collect feedback via in-app surveys and bug reports.
- Iterate on UI/UX based on feedback before full release.

### 3. Migration Strategy

#### Existing Users
- Run a one-time migration script via Firebase Admin SDK to add `'tier': 'free'` to all user documents.
- Send push notification or in-app message announcing the freemium model.
- Update onboarding to explain tiers.

#### Data Handling
- Ensure existing user data remains intact; no deletions or modifications.
- Verify offline cache works with new limit logic.
- Test data export/import for premium features.

### 4. Rollout Phases

#### Phase 1: Core Development (Weeks 1-3)
- Implement backend user tiers and database schema.
- Add UI limit checks and upgrade prompts.
- Develop basic subscription UI.

#### Phase 2: Payment Integration (Week 4)
- Integrate RevenueCat and configure App Store products.
- Implement full purchase and management flow.
- Test payment edge cases (refunds, cancellations).

#### Phase 3: Testing and QA (Weeks 5-6)
- Complete unit and integration tests.
- Perform security audit for payment data.
- Conduct internal QA testing.

#### Phase 4: Beta Release (Weeks 7-8)
- Release to beta testers via TestFlight.
- Monitor crash reports and user feedback.
- Fix critical issues.

#### Phase 5: Full Rollout (Week 9)
- Submit to App Store for review.
- Go live with monitoring in place.
- Prepare rollback plan if needed.

### 5. Monitoring and Analytics Setup

#### Firebase Analytics Implementation
- Enable Firebase Analytics in the app.
- Log custom events: `scan_performed`, `limit_reached`, `upgrade_prompt_shown`, `subscription_purchased`, `subscription_cancelled`.
- Track user properties: `user_tier`, `subscription_status`.

#### Key Metrics Dashboard
- Set up Firebase Console dashboards for real-time metrics.
- Monitor conversion funnel: free users -> upgrade prompt -> purchase.
- Track usage patterns: scans per user, books added, recommendations requested.
- Monitor costs: API usage vs revenue.

#### Alerts and Monitoring
- Set up alerts for high churn rates or low conversion.
- Monitor app crashes related to new features.
- Track revenue metrics: MRR, ARR, LTV.

#### Post-Launch Analysis
- A/B test different pricing or limits.
- Analyze user segments: power users vs casual.
- Use insights to optimize features and pricing.

---

*This document will be updated quarterly based on user data and market conditions.*