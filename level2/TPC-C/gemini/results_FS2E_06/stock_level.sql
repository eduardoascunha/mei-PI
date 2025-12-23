CREATE OR REPLACE FUNCTION bmsql_proc_stock_level(
    in_w_id integer,
    in_d_id integer,
    in_threshold integer
) RETURNS integer AS $$
DECLARE
    v_next_o_id integer;
    v_low_stock integer;
BEGIN
    SELECT d.d_next_o_id
    INTO v_next_o_id
    FROM bmsql_district AS d
    WHERE d.d_w_id = in_w_id AND d.d_id = in_d_id;

    SELECT count(DISTINCT s.s_i_id)
    INTO v_low_stock
    FROM bmsql_order_line AS ol
    JOIN bmsql_stock AS s ON s.s_w_id = ol.ol_w_id AND s.s_i_id = ol.ol_i_id
    WHERE ol.ol_w_id = in_w_id
      AND ol.ol_d_id = in_d_id
      AND ol.ol_o_id >= (v_next_o_id - 20)
      AND ol.ol_o_id < v_next_o_id
      AND s.s_quantity < in_threshold;

    RETURN v_low_stock;
END;
$$ LANGUAGE plpgsql;