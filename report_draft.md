# Traffic Sources & Ad ROI Analysis — 分析見解報告

**專案：** 03_Traffic_Sources_Ad_ROI_Analysis | **分析期間：** 2024 全年（Jan–Dec）| **資料來源：** BigQuery + Power BI Dashboard

***

## 執行摘要

本分析橫跨五大流量渠道（Google Ads、Facebook Ads、Email、Organic、Direct），覆蓋全年超過 511,797 個 Sessions 及 18,288 筆訂單，總收益達 **$1,754,573 USD**。核心結論：**Email 渠道以極低投放成本取得全年最高 ROI（平均 ROAS 30.8x）；Google Ads 是訂單量主力，佔比逾 64%；Google Display Remarketing（C004）是唯一錄得負 ROI 的廣告活動，需立即檢討預算分配。**

***

## 一、各渠道整體表現

### 1.1 流量貢獻與轉換能力

五大渠道在訂單量、收益及轉換效率上呈現明顯分層：

| 渠道 | Sessions | 訂單數 | 總收益 (USD) | CVR | CPA (USD) | ROAS |
|------|----------|--------|-------------|-----|-----------|------|
| Google Ads | 331,749 | 11,732 | $1,118,727 | 3.54% | $44.45 | 2.15x |
| Facebook Ads | 105,427 | 2,797 | $246,650 | 2.65% | $64.08 | 1.38x |
| Direct | 28,975 | 1,979 | $215,525 | 6.83% | $0 | N/A |
| Email | 16,350 | 1,215 | $125,891 | 7.43% | $3.36 | 30.8x |
| Organic | 29,296 | 565 | $47,781 | 1.93% | $0 | N/A |

Google Ads 以 331,749 個 Sessions 和 11,732 筆訂單主導整體流量貢獻，但轉換效率（CVR 3.54%）僅位列中游。相反，Email 渠道雖然 Sessions 最少（16,350），卻錄得最高 CVR（7.43%），比 Google Ads 高出整整兩倍，顯示電郵用戶意圖明確、互動質素最高。

**Direct 流量（CVR 6.83%，平均客單價 $108.91）** 是無廣告成本渠道中表現最突出的，說明品牌知名度與回訪用戶具備強烈消費意圖。Organic 的 CVR 僅 1.93% 是五渠道最低，雖然毋需投放成本，但流量品質偏弱，具備優化空間。

### 1.2 付費渠道的廣告效益對比

付費渠道（Google Ads、Facebook Ads、Email）在廣告支出回報率（ROAS）上差距懸殊：

- **Email ROAS = 30.8x**：以僅 $4,087 USD 廣告支出，帶動 $125,891 收益，是付費渠道中效率最高者
- **Google Ads ROAS = 2.15x**：規模龐大，總投放 $521,497，但邊際回報相對有限
- **Facebook Ads ROAS = 1.38x**：廣告支出 $179,218，回報僅 $246,650，效率偏低，且 CPA $64.08 是付費渠道中最高

這一差距反映出 Email 渠道的天然優勢——觸及已有品牌認知的高意圖受眾，成本極低但轉化力強。

***

## 二、廣告活動 ROI 排名與效益分析

### 2.1 最優秀與最差廣告活動

各 Campaign 的 ROI 排名揭示了明確的預算分配優先級：

| 排名 | 廣告活動 | 渠道 | 類型 | ROAS | ROI% | CPA (USD) |
|------|---------|------|------|------|------|-----------|
| 🥇 1 | Email_Abandoned_Cart (C010) | Email | Automation | 45.12x | 4,412% | $2.27 |
| 🥈 2 | Email_Newsletter_Monthly (C008) | Email | Newsletter | 27.86x | 2,686% | $3.74 |
| 🥉 3 | Email_Promo_Flash_Sale (C009) | Email | Promotion | 26.95x | 2,595% | $3.85 |
| 4 | Google_Shopping_Q1 (C003) | Google Ads | Shopping | 3.54x | 254% | $26.98 |
| 5 | Facebook_Retargeting (C007) | Facebook Ads | Retargeting | 2.63x | 163% | $33.77 |
| 6 | Google_Nonbrand_Search (C002) | Google Ads | Search | 2.17x | 117% | $43.98 |
| 7 | Google_Brand_Search (C001) | Google Ads | Search | 2.12x | 112% | $45.01 |
| 8 | Facebook_Awareness (C005) | Facebook Ads | Awareness | 1.08x | 8% | $78.13 |
| 9 | Facebook_Conversion (C006) | Facebook Ads | Conversion | 1.04x | 4% | $84.84 |
| 🚨 10 | Google_Display_Remarketing (C004) | Google Ads | Display | 0.70x | **-30%** | $132.36 |

**Email Abandoned Cart（C010）以 4,412% ROI 排名第一**，以每日 $30 預算產出 $35,906 全年收益，CPA 僅 $2.27，是整個廣告組合中效率最高的活動。三支 Email 活動合計佔全部廣告支出不足 0.6%，卻貢獻約 17% 的付費渠道訂單量。

**Google Display Remarketing（C004）是唯一負 ROI 廣告活動**（ROI -30%），全年投入 $32,561，僅換回 $22,755 收益，虧損約 $9,806 USD。該活動 CVR 僅 0.51%，遠低於同樣為 Google Ads 的 Search（4.0%）和 Shopping（4.2%）類型，而 CPA $132.36 更是所有付費活動中最高。

### 2.2 Facebook 廣告的效益問題

Facebook 三支廣告活動整體表現欠佳：

- **Facebook_Conversion（C006）** 顧名思義為轉換目標，但 ROI 僅 4%（ROAS 1.04x），幾乎收支平衡，CPA 高達 $84.84
- **Facebook_Awareness（C005）** 作為品牌認知活動，CTR 2.21% 和 CVR 1.33% 均偏低，ROI 僅 8%
- 唯有 **Facebook_Retargeting（C007）** 有較理想表現（ROI 163%，CPA $33.77），說明 Facebook 渠道在 Retargeting 場景下仍具一定效益

這一規律反映出 Facebook 廣告受眾匹配精準度不足，或廣告素材需要優化，建議縮減 Conversion 活動預算，將資源集中於 Retargeting。

***

## 三、CTR 與 CVR 的關聯性分析

### 3.1 「高 CTR 未必高 CVR」的反直覺發現

CTR 分桶分析揭示了一個重要洞察：CTR 與 CVR 之間**並不呈線性正相關**：

| CTR 區間 | 平均 CTR | 平均 Session CVR | 總訂單數 |
|---------|---------|----------------|---------|
| CTR < 1% | 0.64% | **5.47%** | 112 |
| CTR 1–2% | 1.57% | 4.81% | 925 |
| CTR 2–3% | 2.50% | 4.95% | 2,769 |
| CTR 3–4% | **3.46%** | **5.22%** | 2,995 |
| CTR 4–5% | 4.45% | 4.40% | 3,263 |
| CTR ≥ 5% | 6.01% | **3.47%（最低）** | 5,680 |

CVR 最高點出現在 **CTR 3–4% 區間（CVR 5.22%）**，而 CTR ≥ 5% 的群組 CVR 卻跌至 3.47%，為各桶最低。這說明 CTR 極高的廣告素材可能吸引了大量「好奇點擊」但購買意圖偏低的用戶，廣告吸引力與產品匹配度之間存在落差。

### 3.2 渠道層面的 CTR vs CVR 差異

從各渠道的 CTR 和 CVR 比較來看：

- **Google Ads**：CTR 4.4–4.6%（最高）；CVR 4.0–4.2%（Search/Shopping）—— 兩者均衡，顯示關鍵字定向精準
- **Email**：CTR 2.7%（中等）；CVR 6.5–10.1%（最高）—— 低 CTR 卻極高 CVR，說明電郵清單質量優秀
- **Facebook**：CTR 2.1–2.2%（最低）；CVR 1.3–4.5%（差異大）—— Retargeting 效果顯著優於 Awareness/Conversion

Email Abandoned Cart 的 CVR 高達 10.1%，是 Google Search 的兩倍以上，印證了「行為觸發式」自動化電郵的轉換效力遠超傳統廣告。

***

## 四、月度趨勢與季節性規律

### 4.1 Google Ads ROI 的年度波動

Google Ads 全年 ROI 呈現「雙峰」型態，反映出明顯的季節性效應：

- **年初高峰**（2024-01）：ROI 146%，ROAS 2.46x，為全年最高點
- **年中低谷**（2024-06）：ROI 跌至 74.8%，ROAS 僅 1.75x，競爭成本上升或需求疲軟
- **年末回升**（2024-12）：ROI 130.9%，ROAS 2.31x，假期消費季帶動回暖

年中（5–6月）ROI 下滑顯著，建議在此期間壓縮競價或調整出價策略，將節省預算集中於 Q4 年末旺季。

### 4.2 Email 的全年穩定性

Email 渠道全年 ROAS 維持在 22–40x 之間，無明顯季節性波動，是五大渠道中最穩定的 ROI 來源。相比之下，Facebook Ads 的 ROI 在 3–57% 之間劇烈波動，可預測性最差。

### 4.3 年末旺季訂單格局

從全年月度訂單走勢來看，11–12 月（年末旺季）各渠道訂單量均有提升。Google Ads 11月訂單達 1,172 筆，Email 11 月亦創全年次高。Direct 渠道全年保持穩定（每月 130–190 筆），反映品牌基礎流量健康。

***

## 五、裝置行為分析

### 5.1 裝置偏好與客單價

各渠道的裝置訂單分布顯示：

| 渠道 | Desktop 訂單 | Mobile 訂單 | Tablet 訂單 | Mobile AOV |
|------|------------|------------|------------|------------|
| Google Ads | 5,316 | 5,258 | 1,158 | $95.07 |
| Direct | 881 | 895 | 203 | **$109.84** |
| Email | 540 | 546 | 129 | $103.07 |
| Facebook Ads | 1,233 | 1,286 | 278 | $88.97 |
| Organic | 266 | 250 | 49 | $86.47 |

Google Ads 在 Desktop 與 Mobile 之間幾乎均等分布（5,316 vs 5,258），說明廣告素材跨裝置表現一致，無明顯優化空間偏差。Direct 渠道 Mobile 用戶擁有全部渠道中最高的 Mobile AOV（$109.84），說明直接訪問的手機用戶消費力最強，值得針對性優化手機結帳流程。

***

## 六、策略建議

### 優先投資（Invest More）
- **Email 自動化流程（特別是 Abandoned Cart）**：以最低成本取得最高 ROI，建議擴增電郵訂閱清單規模及觸發式電郵類型
- **Facebook Retargeting（C007）**：唯一 ROI 正向且健康的 Facebook 活動，建議增加預算
- **Google Search（Nonbrand + Brand）**：穩定的 ROI 100%+ 主力渠道，適合維持或小幅增加預算

### 需要優化（Optimize）
- **Google Ads — 年中低谷期**（5–6 月）：考慮降低出價或縮減預算，避免高成本低回報期浪費資源
- **CTR 3–4% 區間**：應針對此區間廣告素材進行 A/B 測試，該段 CVR 最高，有助提升整體投放效率

### 立即削減（Cut / Review）
- **Google Display Remarketing（C004）**：全年 ROI -30%，CPA $132.36 難以持續，建議暫停或徹底重設受眾及素材
- **Facebook Awareness + Conversion**：ROI 分別僅 8% 和 4%，幾近收支平衡，在目前策略下缺乏效益，需重新評估定向設定
- 將 Google Display 的預算轉移至 Email Automation 擴充或 Facebook Retargeting，預計可顯著提升整體組合 ROI。

***

*數據來源：BigQuery cache（`traffic_ad_roi_clean` dataset）；2024 全年模擬資料，各渠道參數參考 data_dictionary.md 中的 Simulation Parameters*