CREATE OR REPLACE FUNCTION bmsql_proc_stock_level(
IN in_w_id integer,
IN in_d_id integer,
IN in_threshold integer,
OUT out_low_stock integer
) AS
$$
DECLARE
v_next_o_id integer;
v_low_o_id integer;
BEGIN
-- Initialize output
out_low_stock := 0;


-- Get the district next order id
SELECT d.d_next_o_id
INTO v_next_o_id
FROM bmsql_district d
WHERE d.d_w_id = in_w_id AND d.d_id = in_d_id;

-- If district not found or next_o_id is null, return 0
IF NOT FOUND OR v_next_o_id IS NULL THEN
	out_low_stock := 0;
	RETURN;
END IF;

-- Compute lower bound for the last 20 orders
v_low_o_id := v_next_o_id - 20;
IF v_low_o_id < 1 THEN
	v_low_o_id := 1;
END IF;

-- Count distinct items from the last 20 orders whose stock at this warehouse is below threshold
SELECT COUNT(*) INTO out_low_stock
FROM (
	SELECT DISTINCT ol.ol_i_id
	FROM bmsql_order_line ol
	WHERE ol.ol_w_id = in_w_id
	  AND ol.ol_d_id = in_d_id
	  AND ol.ol_o_id >= v_low_o_id
	  AND ol.ol_o_id < v_next_o_id
) AS recent_items
JOIN bmsql_stock s
  ON s.s_i_id = recent_items.ol_i_id
 AND s.s_w_id = in_w_id
WHERE s.s_quantity < in_threshold;

RETURN;


END;
$$
LANGUAGE plpgsql;
