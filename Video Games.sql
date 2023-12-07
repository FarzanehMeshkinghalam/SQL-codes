---------------------------------------Query 1 -------------------------------------
SELECT
CASE WHEN GROUPING(DateDim.DateYear) = 1 THEN 'All' ELSE CAST(DateDim.DateYear AS varchar(4)) END AS DateYear,
CASE WHEN GROUPING(DateDim.DateMonth) = 1 THEN 'All' ELSE CAST(DateDim.DateMonth AS varchar(2)) END AS DateMonth,
CASE WHEN GROUPING(EventDim.EventName) = 1 THEN 'All' ELSE EventDim.EventName END AS EventName,
SUM(EventFact.SpectatorsNumber) AS TotalSpectators,
SUM(EventFact.VIPSpectatorsNumber) AS TotalVIPSpectators,
SUM(EventFact.MerchandiseSold) AS TotalMerchandiseSold,
SUM(EventFact.TicketsSold) AS TotalTicketsSold,
SUM(EventFact.PromotionRevenue) AS TotalPromotionRevenue,
SUM(EventFact.PromotionCost) AS TotalPromotionCost,
(SUM(EventFact.PromotionRevenue) - SUM(EventFact.PromotionCost)) AS PromotionProfit,
SUM(SUM(EventFact.SpectatorsNumber)) OVER (PARTITION BY DateDim.DateYear ORDER BY DateDim.DateMonth) AS CumulativeSpectators,
SUM(SUM(EventFact.VIPSpectatorsNumber)) OVER (PARTITION BY DateDim.DateYear ORDER BY DateDim.DateMonth) AS CumulativeVIPSpectators,
SUM(SUM(EventFact.TicketsSold)) OVER (PARTITION BY DateDim.DateYear ORDER BY DateDim.DateMonth) AS CumulativeTicketsSold
FROM
EventFact
INNER JOIN
DateDim ON EventFact.DateID = DateDim.DateID
INNER JOIN
EventDim ON EventFact.EventID = EventDim.EventID
GROUP BY
ROLLUP(DateDim.DateYear, DateDim.DateMonth, EventDim.EventName);

------------------------------------------------------------- Query 2--------------------------------------
SELECT *
FROM (
  SELECT 
    ClubName, 
    ChampionItemName, 
    PlayerInGamePositionInGame, 
    SUM(PRKills) AS TotalKills
  FROM ClubDim cd
  INNER JOIN PlayerInGameDim pgd ON cd.ClubID = pgd.ClubID
  INNER JOIN ChampionInGameSpecDim cigsd ON pgd.PlayerInGameID = cigsd.PlayerInGameID
  INNER JOIN PersonalRecordDim prd ON pgd.PRID = prd.PRID
  INNER JOIN ChampionItemDim cid ON cigsd.ChampionItemID = cid.ChampionItemID
  GROUP BY ClubName, ChampionItemName, PlayerInGamePositionInGame
) AS SourceTable
PIVOT (
  MAX(TotalKills) FOR PlayerInGamePositionInGame IN ([Top Laner], [Jungler], [Mid Laner], [Bot Laner], [Support])
) AS PivotTable;

------------------------------------------------Query 3----------------------------------------
SELECT  md.MerchandiseType , * FROM OnlineSalesFact osf
JOIN MerchandiseDim md ON osf.MerchandiseID = md.MerchandiseID
WHERE osf.MerchandiseSoldPND >= (
    SELECT AVG(MerchandiseSoldPND) as AverageMerchandiseSoldPND
    FROM (
        SELECT TOP (25) MerchandiseSoldPND
        FROM OnlineSalesFact 
        ORDER BY MerchandiseSoldPND DESC
    ) as Top25MerchandiseSoldPND
) 
-------------------------------------------------Query 4----------------------------
SELECT 
    td.TicketEvent,
    td.TicketType,
    md.MerchandiseType,
    ROW_NUMBER() OVER (ORDER BY rf.RefundID) AS row_num,
    dd.DateYear,
    DENSE_RANK() OVER (ORDER BY rf.TicketsRefunded DESC) AS dense_rank,
    rf.TicketsRefunded,
    rf.TicketsRefundedPND,
    rf.MerchandiseRefunded,
    rf.MerchandiseRefundedPND
FROM 
    RefundFact rf
    JOIN TicketDim td ON rf.TicketID = td.TicketID
    JOIN MerchandiseDim md ON rf.MerchandiseID = md.MerchandiseID
    JOIN DateDim dd ON rf.DateID = dd.DateID
WHERE 
    dd.DateYear BETWEEN 2020 AND 2021
ORDER BY 
    dense_rank,
    row_num;
SELECT 
    dd.DateYear,
    SUM(rf.TicketsRefunded) AS TotalTicketsRefunded,
    SUM(rf.TicketsRefundedPND) AS TotalTicketsRefundedPND,
    SUM(rf.MerchandiseRefunded) AS TotalMerchandiseRefunded,
    SUM(rf.MerchandiseRefundedPND) AS TotalMerchandiseRefundedPND
FROM 
    RefundFact rf
    JOIN DateDim dd ON rf.DateID = dd.DateID
WHERE 
    dd.DateYear BETWEEN 2020 AND 2021
GROUP BY 
    dd.DateYear;
-----------------------------------------------------Query 5 -----------------------------------
WITH TeamStats AS (
  SELECT 
    s.StadiumName, r.RefereeName, d.DateValue, 
    COUNT(*) AS TotalGames, 
    SUM(f.GameDuration) AS TotalDuration, SUM(f.GameNumberOfPause) AS TotalPauses, 
    SUM(f.GameInterruption) AS TotalInterruptions, SUM(f.GameMinuteOfPause) AS TotalPauseMinutes, 
    SUM(f.GameDurationOfPause) AS TotalPauseDuration, COUNT(DISTINCT f.GameID) AS TotalUniqueGames
  FROM GameFact f
  INNER JOIN StadiumDim s ON f.StadiumID = s.StadiumID
  INNER JOIN RefereeDim r ON f.RefereeID = r.RefereeID
  INNER JOIN DateDim d ON f.DateID = d.DateID
  GROUP BY s.StadiumName, r.RefereeName, d.DateValue
)
SELECT 
  ts.StadiumName, ts.RefereeName, YEAR(ts.DateValue) AS Year, ts.TotalGames, ts.TotalDuration, ts.TotalPauses,
  ts.TotalInterruptions, ts.TotalPauseMinutes, ts.TotalPauseDuration, ts.TotalUniqueGames,
  ROUND(PERCENT_RANK() OVER (PARTITION BY ts.StadiumName ORDER BY ts.TotalDuration DESC), 2) AS RankByGames,
  'Games' AS RankType
FROM TeamStats ts
UNION ALL
SELECT 
  ts.StadiumName, ts.RefereeName, YEAR(ts.DateValue) AS Year, ts.TotalGames, ts.TotalDuration, ts.TotalPauses,
  ts.TotalInterruptions, ts.TotalPauseMinutes, ts.TotalPauseDuration, ts.TotalUniqueGames,
  ROUND(PERCENT_RANK() OVER (PARTITION BY ts.StadiumName ORDER BY ts.TotalDuration DESC), 2) AS RankByDuration,
  'Duration' AS RankType
FROM TeamStats ts
ORDER BY YEAR(ts.DateValue) DESC;
