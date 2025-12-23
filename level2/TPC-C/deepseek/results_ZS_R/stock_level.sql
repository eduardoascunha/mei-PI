CREATE OR REPLACE FUNCTION stock_level_transaction(
    p_w_id INTEGER,
    p_d_id INTEGER,
    p_threshold INTEGER
)
RETURNS TABLE(low_stock INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    v_next_o_id INTEGER;
BEGIN
    -- Get the next available order number for the district
    SELECT d.d_next_o_id INTO v_next_o_id
    FROM bmsql_district d
    WHERE d.d_w_id = p_w_id AND d.d_id = p_d_id;

    -- Count distinct items with stock below threshold from last 20 orders
    RETURN QUERY
    SELECT COUNT(DISTINCT s.s_i_id)::INTEGER AS low_stock
    FROM bmsql_order_line ol
    JOIN bmsql_stock s ON s.s_i_id = ol.ol_i_id AND s.s_w_id = p_w_id
    WHERE ol.ol_w_id = p_w_id 
      AND ol.ol_d_id = p_d_id 
      AND ol.ol_o_id >= (v_next_o_id - 20) 
      AND ol.ol_o_id < v_next_o_id
      AND s.s_quantity < p_threshold;
END;
$$;