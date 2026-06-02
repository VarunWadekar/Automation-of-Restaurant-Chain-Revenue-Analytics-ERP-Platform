
SET NOCOUNT ON;
WITH RankedData AS (
    SELECT  
        BillNo,
        ItemCode,
        POSDescription,
        ItemDescription,
        IncomeHeadDescription,
        MenuGroupDescription,
        PaymentDescription,
        PAX,
        tableNo,
        ROW_NUMBER() OVER (
            PARTITION BY BillNo, ItemCode
            ORDER BY PaymentDescription
        ) AS rn
    FROM dbo.Tblposrevenue
)

SELECT 
    'PUNE' AS POSDescription,
    TBD.BillNo,

'PUN'
+ FORMAT(TBD.CreatedDate,'yyyyMMdd')
+ FORMAT(TBD.CreatedDate,'HHmmss')
+ ISNULL(CAST(RD.tableNo AS VARCHAR),'') AS BillCode,


    CONVERT(DATE, TBD.CreatedDate) AS [Created Date],
    CONVERT(TIME, TBD.CreatedDate) AS [Created Time],
    TBD.MenuItemCode,
    RD.ItemDescription,

    CASE 
        WHEN UPPER(RD.IncomeHeadDescription) LIKE '%FOOD%' THEN 'FOOD'
        WHEN UPPER(RD.IncomeHeadDescription) LIKE '%BEVERAGES%' THEN 'BEVERAGES'
        WHEN UPPER(RD.IncomeHeadDescription) LIKE '%BEER%' THEN 'BEER'
        WHEN UPPER(RD.IncomeHeadDescription) LIKE '%LIQUOR%' THEN 'LIQUOR'
        WHEN UPPER(RD.IncomeHeadDescription) LIKE '%OTHER%' THEN 'FOOD'
        WHEN UPPER(RD.IncomeHeadDescription) LIKE '%TOBACCO%' THEN 'TOBACCO'
        WHEN UPPER(RD.IncomeHeadDescription) LIKE '%WINES%' THEN 'LIQUOR'
        WHEN UPPER(RD.IncomeHeadDescription) LIKE '%BREWERY%' THEN 'BEER'
        ELSE RD.IncomeHeadDescription
    END AS IncomeHeadDescription,

    RD.MenuGroupDescription,
    TBD.Quantity,
    TBD.Rate,
    TBD.Cost,
    TBD.Discount,
    TBH.DiscountRemark,
    TBD.NetAmount,
    TBD.ItemTotalTax,
    (TBD.NetAmount + TBD.ItemTotalTax) AS Gross_Amount,
    RD.PaymentDescription,
    RD.PAX,
    RD.tableNo,
    TBH.CustMobileNoForBill,
    TBH.CustNameForBill

FROM dbo.TblBillDetail_29 AS TBD

JOIN RankedData AS RD 
    ON TBD.BillNo = RD.BillNo
    AND TBD.MenuItemCode = RD.ItemCode

LEFT JOIN dbo.TblBillHead_29 AS TBH
    ON TBD.BillNo = TBH.BillNo

WHERE 
  TBD.CreatedDate between '2026-06-01' AND '2026-07-01' OR TBD.CreatedDate between '2025-06-01' AND '2025-07-01'
    AND RD.rn = 1

ORDER BY 
    TBD.CreatedDate ASC,
    TBD.BillNo,
    RD.ItemCode;