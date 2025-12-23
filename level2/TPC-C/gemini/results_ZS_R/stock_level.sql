CREATE OR REPLACE FUNCTION stock_level (
    w_id_in integer,
    d_id_in integer,
    threshold_in integer
) RETURNS integer AS $$
DECLARE
    v_next_o_id integer;
    v_low_stock integer;
BEGIN
    -- Get the next available order ID for the district
    SELECT d.d_next_o_id
    INTO v_next_o_id
    FROM bmsql_district AS d
    WHERE d.d_w_id = w_id_in AND d.d_id = d_id_in;

    -- Count the number of distinct items from the last 20 orders
    -- that have a stock quantity below the specified threshold.
    SELECT count(DISTINCT s.s_i_id)
    INTO v_low_stock
    FROM bmsql_order_line AS ol
    JOIN bmsql_stock AS s ON s.s_i_id = ol.ol_i_id AND s.s_w_id = ol.ol_w_id
    WHERE ol.ol_w_id = w_id_in
      AND ol.ol_d_id = d_id_in
      AND ol.ol_o_id >= (v_next_o_id - 20)
      AND ol.ol_o_id < v_next_o_id
      AND s.s_quantity < threshold_in;

    RETURN v_low_stock;
END;
$$ LANGUAGE plpgsql;