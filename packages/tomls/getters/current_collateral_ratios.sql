-- Here are two SQL queries for:
-- 1. querying the ratio of rUSD of the passive pool with respect to the current TVL.
-- 2. querying the ratios of the other collateral assets of the passive pool with respect to the current TVL, excluding rUSD.
WITH 
ab AS (
    SELECT * FROM account_balances WHERE account_id = 2
),
total_tvl AS (
    SELECT 
        SUM(ab.balance * ap.price / 1e8 / 10 ^ asset.decimals) AS amount FROM ab
    JOIN "Asset" asset on ab.collateral = asset.address
    JOIN asset_price ap ON asset.asset_price_contract_id = ap.contract_id
),
individual_tvl AS (
    SELECT 
        ab.balance * ap.price / 1e8 / 10 ^ asset.decimals AS amount, 
        ab.balance / 10 ^ asset.decimals AS amount_collateral,
        asset.name AS asset_name 
    FROM ab
    JOIN "Asset" asset on ab.collateral = asset.address
    JOIN asset_price ap ON asset.asset_price_contract_id = ap.contract_id
)
SELECT 
asset_name,
amount,
(SELECT * FROM total_tvl) AS total_tvl,
amount / (SELECT * FROM total_tvl) AS current_rusd_ratio
FROM individual_tvl
WHERE asset_name = 'rUSD';

WITH 
ab AS (
    SELECT * FROM account_balances WHERE account_id = 2
),
total_tvl AS (
    SELECT 
        SUM(ab.balance * ap.price / 1e8 / 10 ^ asset.decimals) AS amount FROM ab
    JOIN "Asset" asset on ab.collateral = asset.address
    JOIN asset_price ap ON asset.asset_price_contract_id = ap.contract_id
),
individual_tvl AS (
    SELECT 
        ab.balance * ap.price / 1e8 / 10 ^ asset.decimals AS amount, 
        ab.balance / 10 ^ asset.decimals AS amount_collateral,
        asset.name AS asset_name 
    FROM ab
    JOIN "Asset" asset on ab.collateral = asset.address
    JOIN asset_price ap ON asset.asset_price_contract_id = ap.contract_id
)
SELECT 
asset_name,
amount_collateral,
amount,
(SELECT * FROM total_tvl) - (SELECT amount FROM individual_tvl WHERE asset_name = 'rUSD') AS total_tvl_post_rusd,
amount / ((SELECT * FROM total_tvl) - (SELECT amount FROM individual_tvl WHERE asset_name = 'rUSD')) AS current_ratio_post_rusd
FROM individual_tvl
WHERE not asset_name = 'rUSD'
ORDER BY current_ratio_post_rusd DESC;
