CREATE OR REPLACE FUNCTION bmsql_proc_stock_level(
IN in_w_id integer,
IN in_d_id integer,
IN in_threshold integer
) RETURNS integer AS
$$
DECLARE
v_next_o_id integer;
v_lower_o_id integer;
v_low_stock integer := 0;
BEGIN
-- 1) Retrieve D_NEXT_O_ID from the DISTRICT row
SELECT bmsql_district.d_next_o_id
INTO v_next_o_id
FROM bmsql_district
WHERE bmsql_district.d_w_id = in_w_id
AND bmsql_district.d_id = in_d_id;


-- If district not found or next_o_id is null, return 0
IF NOT FOUND OR v_next_o_id IS NULL THEN
    RETURN 0;
END IF;

-- Calculate lower bound (last 20 orders)
v_lower_o_id := v_next_o_id - 20;
IF v_lower_o_id < 1 THEN
    v_lower_o_id := 1;
END IF;

-- 2 & 3) Find distinct item ids from the last 20 orders and count how many have stock < threshold
SELECT count(*) INTO v_low_stock
FROM (
    SELECT DISTINCT ol.ol_i_id
    FROM bmsql_order_line ol
    WHERE ol.ol_w_id = in_w_id
      AND ol.ol_d_id = in_d_id
      AND ol.ol_o_id < v_next_o_id
      AND ol.ol_o_id >= v_lower_o_id
) AS recent_items
JOIN bmsql_stock s
  ON s.s_i_id = recent_items.ol_i_id
 AND s.s_w_id = in_w_id
WHERE s.s_quantity < in_threshold;

RETURN COALESCE(v_low_stock, 0);


END;
$$
LANGUAGE plpgsql;
