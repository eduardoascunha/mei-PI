CREATE OR REPLACE FUNCTION stock_level(p_w_id integer, p_d_id integer, p_threshold integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
v_d_next_o_id integer;
v_min_o_id integer;
v_low_stock integer := 0;
BEGIN
-- Retrieve next order id for the district
SELECT d_next_o_id
INTO v_d_next_o_id
FROM bmsql_district
WHERE d_w_id = p_w_id
AND d_id   = p_d_id
FOR SHARE; -- read committed / stable view of the row

IF NOT FOUND THEN
    RAISE EXCEPTION 'District not found for warehouse % and district %', p_w_id, p_d_id;
END IF;

IF v_d_next_o_id IS NULL THEN
    RAISE EXCEPTION 'd_next_o_id is NULL for warehouse % and district %', p_w_id, p_d_id;
END IF;

-- Compute lower bound for last 20 orders
v_min_o_id := v_d_next_o_id - 20;
IF v_min_o_id < 1 THEN
    v_min_o_id := 1;
END IF;

-- Count distinct items from the last 20 orders whose stock at home warehouse is below threshold
WITH items AS (
    SELECT DISTINCT ol_i_id
    FROM bmsql_order_line
    WHERE ol_w_id = p_w_id
      AND ol_d_id = p_d_id
      AND ol_o_id >= v_min_o_id
      AND ol_o_id <  v_d_next_o_id
)
SELECT COUNT(*)
INTO v_low_stock
FROM bmsql_stock s
WHERE s.s_w_id = p_w_id
  AND s.s_quantity < p_threshold
  AND s.s_i_id IN (SELECT ol_i_id FROM items);

RETURN v_low_stock;

END;
$$;
