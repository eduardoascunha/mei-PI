CREATE OR REPLACE FUNCTION stock_level_transaction(p_w_id integer, p_d_id integer, p_threshold integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
v_d_next_o_id integer;
v_low_stock integer := 0;
v_lower_o_id integer;
BEGIN
-- Retrieve D_NEXT_O_ID for the given district
SELECT d.d_next_o_id
INTO v_d_next_o_id
FROM bmsql_district d
WHERE d.d_w_id = p_w_id
AND d.d_id   = p_d_id;


IF NOT FOUND THEN
    RAISE EXCEPTION 'District not found for w_id=% d_id=%', p_w_id, p_d_id;
END IF;

-- Compute lower bound for the last 20 orders
v_lower_o_id := v_d_next_o_id - 20;
IF v_lower_o_id < 1 THEN
    v_lower_o_id := 1;
END IF;

-- Count distinct items from the last 20 orders whose stock at the home warehouse is below threshold
SELECT COUNT(*) INTO v_low_stock
FROM (
    SELECT s.s_i_id
    FROM bmsql_stock s
    JOIN (
        SELECT DISTINCT ol.ol_i_id AS i_id
        FROM bmsql_order_line ol
        WHERE ol.ol_w_id = p_w_id
          AND ol.ol_d_id = p_d_id
          AND ol.ol_o_id >= v_lower_o_id
          AND ol.ol_o_id < v_d_next_o_id
    ) items ON items.i_id = s.s_i_id
    WHERE s.s_w_id = p_w_id
      AND s.s_quantity < p_threshold
) sub;

RETURN v_low_stock;


END;
$$;
