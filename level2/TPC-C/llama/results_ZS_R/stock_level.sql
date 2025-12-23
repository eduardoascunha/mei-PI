CREATE OR REPLACE FUNCTION stock_level(p_w_id integer, p_d_id integer, p_threshold integer)
RETURNS TABLE(low_stock integer) AS $$
DECLARE
    v_d_next_o_id integer;
BEGIN
    SELECT d.d_next_o_id INTO v_d_next_o_id
    FROM bmsql_district d
    WHERE d.d_w_id = p_w_id AND d.d_id = p_d_id;

    RETURN QUERY
    SELECT COUNT(DISTINCT CASE WHEN s.s_quantity < p_threshold THEN ol.ol_i_id END)::integer
    FROM bmsql_order_line ol
    JOIN bmsql_stock s ON ol.ol_i_id = s.s_i_id AND s.s_w_id = p_w_id
    WHERE ol.ol_w_id = p_w_id AND ol.ol_d_id = p_d_id
    AND ol.ol_o_id < v_d_next_o_id AND ol.ol_o_id >= v_d_next_o_id - 20;
END;
$$ LANGUAGE plpgsql;